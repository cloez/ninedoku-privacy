# K-Puzzles 13게임 튜토리얼 상세 컨텐츠 기획서

> **버전**: v2.0 (2026-06-18)  
> **참고 영상**: KakaoTalk_20260617_084843757.mp4 (스도쿠 "기본 규칙" 화면)  
> **핵심 원칙**: 모든 튜토리얼 페이지는 **정적 화면이 아닌 타임라인 기반 애니메이션**으로 구현  
> **연관 문서**: `docs/tutorial_screen_spec.md`, `docs/tutorial_content_sudoku.md`

---

## 0. 영상 분석 — 핵심 발견

참고 영상(31초)을 프레임 단위로 분석한 결과, 튜토리얼은 **스크립트 애니메이션**이다.

### 0.1 정적 화면과의 차이

| 구분 | 정적 화면 (기존) | 애니메이션 (목표) |
|---|---|---|
| 보드 | MiniBoardIllustration 고정 이미지 | **실제 게임 보드** 위에 하이라이트가 시간차로 등장/소멸 |
| 텍스트 | 한 번에 전체 표시 | **키워드 색상이 보드 하이라이트와 동기화**되어 순차 강조 |
| 손 커서 | 없음 | **위치 A→B로 이동하는 애니메이션**, 탭/클릭 제스처 포함 |
| 툴팁 | 고정 위치 | **손 커서 도착 후 페이드인**, 앵커 위치에 꼬리표 |
| 셀 상태 | 고정 | **순차적으로 값이 채워지거나 메모가 추가되는 모습** |
| UI 반응 | 없음 | 버튼 하이라이트, 모드 토글(ON 뱃지) 등 **상태 변화** |

### 0.2 영상에서 관찰된 타임라인 (스도쿠 "플레이 방법")

```
┌─ 0:00  메뉴 화면: "기본 규칙" → 플레이 방법 / 유일한 해법 / 다음 채울 칸
│
├─ 0:01  [1/4] 완성 보드 등장 + 텍스트 표시
│  0:02  → 행 하이라이트(노랑) 등장, 텍스트 "줄" 키워드 노랑
│  0:03  → 열 하이라이트(분홍) 등장, 텍스트 "열" 키워드 분홍
│  0:04  → 3×3박스 하이라이트(초록) 등장, 텍스트 "3x3박스" 키워드 초록
│  0:05  → 세 가지 동시 표시 유지
│  0:06  → "다음" 버튼 활성
│
├─ 0:07  [2/4] 미완성 보드(실제 게임 화면) 등장
│  0:08  → 손 커서가 화면 밖에서 빈 셀 위치로 이동
│  0:09  → 툴팁 "빈 셀을 클릭하세요." 페이드인
│  0:10  → 손 커서 탭 제스처 (살짝 눌렀다 올림)
│
├─ 0:12  [3/4] 셀 선택됨(파란 하이라이트) + 도구바 등장
│  0:13  → 손 커서가 선택된 셀에서 아래 "연습" 버튼으로 이동
│  0:14  → 손 커서 탭 → "연습" 버튼에 ON 뱃지 활성
│  0:15  → 툴팁 "연필 모드를 켜서 메모를 쉽게 추가하거나 제거해 보세요!" 등장
│  0:16  → 손 커서가 숫자 패드 "1"로 이동 → 탭 → 셀에 메모 "1" 추가
│  0:18  → 손 커서 "2"로 이동 → 탭 → 셀에 메모 "1 2" 표시
│  0:20  → 손 커서 "7"로 이동 → 탭 → 셀에 메모 "1 2 7" 표시
│
├─ 0:23  [4/4] 보드 유지
│  0:24  → 손 커서가 도구바 "힌트" 버튼으로 이동
│  0:25  → 툴팁 "퍼즐에 막혔나요? 힌트를 사용해보세요!" 등장
│  0:26  → 손 커서 탭 제스처
│  0:28  → 힌트 결과 표시 (셀에 정답이 펄스 애니메이션으로 채워짐)
│
└─ 0:31  종료
```

---

## 1. 애니메이션 시스템 설계

### 1.1 타임라인 데이터 모델

각 튜토리얼 페이지는 순차 실행되는 **AnimationEvent** 리스트로 정의:

```dart
/// 튜토리얼 애니메이션 이벤트 유형
sealed class TutorialEvent {
  /// 이벤트 시작까지 대기 시간 (이전 이벤트 완료 후)
  final Duration delay;
  /// 이벤트 자체 지속 시간
  final Duration duration;
}

/// 보드 영역 하이라이트 등장/소멸
class HighlightEvent extends TutorialEvent {
  final HighlightRegion region;  // row(n), column(n), box(r,c), cells([...])
  final Color color;             // 노랑/분홍/초록 등
  final bool show;               // true=등장, false=소멸
}

/// 텍스트 키워드 색상 강조
class TextHighlightEvent extends TutorialEvent {
  final String keyword;          // "3x3박스", "줄", "열" 등
  final Color color;             // 보드 하이라이트와 동일 색상
}

/// 손 커서 이동
class CursorMoveEvent extends TutorialEvent {
  final Offset from;             // 시작 위치 (상대 좌표)
  final Offset to;               // 도착 위치
  final CurveType curve;         // easeInOut, linear 등
}

/// 손 커서 탭 제스처
class CursorTapEvent extends TutorialEvent {
  final Offset position;
}

/// 툴팁 표시/숨김
class TooltipEvent extends TutorialEvent {
  final String textKey;          // 다국어 키
  final Offset anchor;           // 꼬리표 위치
  final TooltipDirection direction;  // up, down, left, right
  final bool show;
}

/// 셀 값 변경 (숫자 입력 또는 메모 추가)
class CellChangeEvent extends TutorialEvent {
  final CellTarget cell;
  final int? value;              // 정답 입력
  final int? memo;               // 메모 추가
  final CellAnimation animation; // pulse, fadeIn, none
}

/// UI 버튼 상태 변경
class ButtonStateEvent extends TutorialEvent {
  final String buttonId;         // "pencil", "hint", "undo", "erase"
  final bool active;             // ON/OFF 토글
  final bool highlight;          // 강조 표시
}

/// 보드 전체 상태 전환 (페이지 전환 시)
class BoardStateEvent extends TutorialEvent {
  final List<List<int?>> board;  // 새 보드 상태
  final bool isComplete;         // 완성 보드 vs 미완성 보드
}
```

### 1.2 페이지 정의 구조

```dart
class TutorialPage {
  final String titleKey;                  // "플레이 방법"
  final int pageNumber;                   // 1
  final int totalPages;                   // 4
  final List<List<int?>> initialBoard;    // 페이지 시작 시 보드 상태
  final bool showToolbar;                 // 도구바 표시 여부
  final bool showNumberPad;              // 숫자 패드 표시 여부
  final String? descriptionKey;           // 하단 규칙 텍스트 (1/4 전용)
  final List<TutorialEvent> timeline;     // 애니메이션 타임라인
}
```

### 1.3 공통 섹션 구조

모든 게임은 동일한 "기본 규칙" 메뉴 구조:

```
← 기본 규칙                              (AppBar)
─────────────────────────────────────────
  규칙

  플레이 방법                          >   ← 공통 4페이지 (게임판 기반 애니메이션)
  {게임별 핵심 규칙 A}                 >   ← 게임별 규칙 애니메이션
  {게임별 핵심 규칙 B} (선택)          >   ← 복합 규칙 게임만
─────────────────────────────────────────
```

---

## 2. "플레이 방법" 공통 4페이지 — 게임별 애니메이션 타임라인

### 2.0 공통 패턴

**1/4 — 규칙 요약**: 완성 보드 + 영역 하이라이트 순차 등장 + 텍스트 키워드 색상 동기화  
**2/4 — 셀 선택**: 미완성 보드 + 손 커서가 빈 셀로 이동 + 툴팁  
**3/4 — 보조 기능**: 셀 선택 상태 + 손 커서가 도구 버튼 → 숫자패드 이동 + 실제 동작 시연  
**4/4 — 힌트**: 손 커서가 힌트 버튼 → 탭 → 결과 표시  

---

### 2.1 Sudoku (스도쿠)

#### 1/4 규칙 요약

```yaml
board: 완성 9×9 (영상 원본)
  6 5 8 9 1 3 7 2 4
  4 3 2 6 8 7 5 1 2
  9 1 7 2 5 4 3 8 6
  8 6 5 4 7 9 2 3 1
  3 7 4 1 6 2 8 9 5
  1 2 9 5 3 8 4 6 7
  2 9 6 3 4 5 1 7 8
  7 4 3 8 9 1 6 5 2
  5 8 1 7 2 6 9 4 3

text: |
  클래식 스도쿠 규칙:
  9x9 그리드를 채워서:
  • 각 [3x3박스]는 1부터 9까지의 숫자를 포함해야 합니다
  • 각 [줄]은 1부터 9까지의 숫자를 포함해야 합니다
  • 각 [열]은 1부터 9까지의 숫자를 포함해야 합니다
  어떤 [3x3박스], [줄] 또는 [열]에서도 숫자가 반복되어서는 안 됩니다!

timeline:
  - delay: 0.5s
    event: highlight_row(2, color: yellow)     # 3행 노랑 테두리
    sync: text_highlight("줄", color: yellow)

  - delay: 1.5s
    event: highlight_column(2, color: pink)    # 3열 분홍 배경
    sync: text_highlight("열", color: pink)

  - delay: 1.5s
    event: highlight_box(2,2, color: green)    # 우하단 3×3 초록
    sync: text_highlight("3x3박스", color: green)

  - delay: 2.0s
    event: hold_all                             # 세 하이라이트 동시 유지
```

#### 2/4 셀 선택

```yaml
board: 미완성 9×9 (영상 원본 — 빈 칸 다수)
toolbar: hidden
numberPad: visible

timeline:
  - delay: 0.5s
    event: cursor_appear(offscreen_right)

  - delay: 0.3s
    event: cursor_move(to: cell(2,1), duration: 0.8s, curve: easeInOut)

  - delay: 0.2s
    event: tooltip_show(
      text: "빈 셀을 클릭하세요.",
      anchor: cell(2,1),
      direction: up
    )

  - delay: 0.5s
    event: cursor_tap(cell(2,1))

  - delay: 0.3s
    event: cell_select(2,1, color: blue)       # 셀 파란 하이라이트
```

#### 3/4 메모 기능

```yaml
board: 2/4와 동일 (셀(2,1) 선택 상태 유지)
toolbar: visible (실행취소, 지우기, 연습, 힌트)
numberPad: visible

timeline:
  - delay: 0.5s
    event: cursor_move(from: cell(2,1), to: button("pencil"), duration: 0.6s)

  - delay: 0.2s
    event: cursor_tap(button("pencil"))

  - delay: 0.2s
    event: button_activate("pencil", show_badge: "ON")
    sync: tooltip_show(
      text: "연필 모드를 켜서 메모를 쉽게 추가하거나 제거해 보세요!",
      anchor: button("pencil"),
      direction: up
    )

  - delay: 1.0s
    event: cursor_move(to: numpad(1), duration: 0.4s)

  - delay: 0.2s
    event: cursor_tap(numpad(1))
    sync: cell_add_memo(2,1, value: 1)         # 셀에 메모 "1" 표시

  - delay: 0.8s
    event: cursor_move(to: numpad(2), duration: 0.3s)

  - delay: 0.2s
    event: cursor_tap(numpad(2))
    sync: cell_add_memo(2,1, value: 2)         # 셀에 메모 "1 2" 표시

  - delay: 0.8s
    event: cursor_move(to: numpad(7), duration: 0.3s)

  - delay: 0.2s
    event: cursor_tap(numpad(7))
    sync: cell_add_memo(2,1, value: 7)         # 셀에 메모 "1 2 7" 표시
```

#### 4/4 힌트

```yaml
board: 3/4 상태 유지
toolbar: visible
numberPad: visible

timeline:
  - delay: 0.5s
    event: tooltip_hide_all                     # 이전 툴팁 제거

  - delay: 0.3s
    event: cursor_move(to: button("hint"), duration: 0.6s)

  - delay: 0.2s
    event: tooltip_show(
      text: "퍼즐에 막혔나요? 힌트를 사용해보세요!",
      anchor: button("hint"),
      direction: up
    )

  - delay: 0.5s
    event: cursor_tap(button("hint"))

  - delay: 0.3s
    event: cell_fill(2,1, value: 6, animation: pulse_green)  # 힌트 결과
    sync: cell_clear_memo(2,1)
```

---

### 2.2 Binairo (비나이로)

#### 메뉴 구조
```
← 기본 규칙
  플레이 방법          >   (4페이지)
  균형과 연속 제한     >   (3페이지)
```

#### 1/4 규칙 요약

```yaml
board: 완성 6×6
  ● ○ ○ ● ○ ●
  ○ ● ● ○ ● ○
  ● ○ ● ○ ○ ●
  ○ ● ○ ● ● ○
  ● ● ○ ○ ● ○
  ○ ○ ● ● ○ ●

text: |
  비나이로 규칙:
  격자를 ●과 ○로 채워서:
  • 각 [행]과 [열]에 ●과 ○가 같은 수
  • 같은 기호가 [3개 연속] 불가
  • [동일한 행/열] 불가

timeline:
  - delay: 0.5s
    event: highlight_row(0, color: yellow)
    sync: text_highlight("행", color: yellow)
    # 1행 강조: ● ○ ○ ● ○ ● → ● 3개, ○ 3개 = 균형

  - delay: 1.5s
    event: highlight_cells([(1,0),(1,1),(1,2)], color: red)
    sync: text_highlight("3개 연속", color: red)
    # ○ ● ● 에서 만약 ● 3개였다면 에러 — 여기는 2개라 OK
    # 대신 위반 예시를 빨간색으로 깜빡여서 "이러면 안 됨" 표시

  - delay: 1.5s
    event: highlight_row(0, color: blue)
    sync: highlight_row(4, color: blue)
    sync: text_highlight("동일한 행/열", color: blue)
    # 두 행을 동시 강조해서 "이 둘이 같으면 안 됨" 표현

  - delay: 2.0s
    event: hold_all
```

#### 2/4 셀 선택

```yaml
board: 미완성 6×6 (빈 칸 다수)
  ● _  ○ ● _  ●
  ○ ● _  ○ ● ○
  _  ○ ● _  ○ ●
  ○ ● ○ ● _  ○
  ● _  ○ ○ ● _
  ○ ○ ● ● _  ●

timeline:
  - delay: 0.5s
    event: cursor_move(to: cell(0,1), duration: 0.8s)

  - delay: 0.2s
    event: tooltip_show("빈 셀을 탭하세요.", anchor: cell(0,1), direction: down)

  - delay: 0.5s
    event: cursor_tap(cell(0,1))
    sync: cell_select(0,1, color: blue)
```

#### 3/4 토글 조작

```yaml
board: 2/4 상태 유지 (셀(0,1) 선택됨)
toolbar: visible

timeline:
  - delay: 0.5s
    event: tooltip_show(
      "셀을 탭하면 ○ → ● → 빈칸 순으로 전환됩니다.",
      anchor: cell(0,1), direction: down
    )

  - delay: 1.0s
    event: cursor_tap(cell(0,1))
    sync: cell_fill(0,1, display: "○", animation: fadeIn)

  - delay: 1.0s
    event: cursor_tap(cell(0,1))
    sync: cell_fill(0,1, display: "●", animation: fadeIn)

  - delay: 1.0s
    event: cursor_tap(cell(0,1))
    sync: cell_clear(0,1, animation: fadeOut)    # 빈칸으로 복귀

  - delay: 0.5s
    event: cursor_tap(cell(0,1))
    sync: cell_fill(0,1, display: "○", animation: fadeIn)  # 정답 입력
```

#### 4/4 힌트 (공통 패턴)

```yaml
timeline:
  - delay: 0.5s → cursor_move(to: button("hint"))
  - delay: 0.2s → tooltip_show("막혔나요? 힌트를 사용해보세요!")
  - delay: 0.5s → cursor_tap → cell_fill(정답, pulse_green)
```

#### 규칙 섹션: 균형과 연속 제한 (3페이지)

**1/3 — 균형 규칙 (애니메이션)**

```yaml
board: 6×6, 의도적으로 1행 불균형
  ● ● ● ● ○ ○    ← ● 4개 (위반!)
  ○ ● ○ ● ○ ●    ← ● 3개, ○ 3개 (정상)
  ...

timeline:
  - delay: 0.5s
    event: highlight_row(0, color: red)
    sync: counter_show(row: 0, black: 4, white: 2)  # ● 4 ○ 2 빨간 카운터

  - delay: 1.5s
    event: error_shake(row: 0, duration: 0.4s)       # 흔들림 효과

  - delay: 1.0s
    event: highlight_row(0, color: none)              # 에러 하이라이트 제거
    sync: highlight_row(1, color: green)
    sync: counter_show(row: 1, black: 3, white: 3)   # ● 3 ○ 3 초록 카운터

  - delay: 1.5s
    event: checkmark_show(row: 1)                     # ✓ 표시
```

**2/3 — 연속 제한 (애니메이션)**

```yaml
board: 6×6, 1행에 ● 3연속

timeline:
  - delay: 0.5s
    event: highlight_cells([(0,0),(0,1),(0,2)], color: red)
    sync: bracket_show(cells: [(0,0)~(0,2)], label: "3연속!")

  - delay: 1.0s
    event: error_shake(cells: [(0,0),(0,1),(0,2)])
    sync: cross_mark_show(cells: [(0,0),(0,1),(0,2)])  # ✗ 표시

  - delay: 1.5s
    event: transition_board(수정된 보드)               # ●●● → ●●○ 로 수정
    sync: highlight_cells([(0,0),(0,1)], color: green)
    sync: bracket_show(cells: [(0,0)~(0,1)], label: "2개 OK")
    sync: checkmark_show()
```

**3/3 — 행 유일성 (애니메이션)**

```yaml
timeline:
  - delay: 0.5s
    event: highlight_row(0, color: blue)
    sync: highlight_row(2, color: blue)               # 동일한 두 행 강조

  - delay: 1.0s
    event: connect_line(row:0, row:2, label: "같음!")  # 두 행 사이 연결선
    sync: error_shake(rows: [0, 2])

  - delay: 1.5s
    event: transition_board(수정된 보드)               # 행 하나 수정
    sync: highlight_row(2, color: green)
    sync: disconnect_line()
    sync: label_show("모두 고유!")
```

---

### 2.3 Minesweeper (지뢰찾기)

#### 메뉴 구조
```
← 기본 규칙
  플레이 방법              >   (4페이지)
  숫자와 깃발              >   (4페이지)
```

#### 1/4 규칙 요약

```yaml
board: 5×5 부분 공개
  1  1  ■  ■  ■        (■ = 미공개)
  💣 2  ■  ■  ■
  1  2  ■  ■  ■
  ·  1  1  2  ■        (· = 빈 칸/0)
  ·  ·  ·  1  ■

text: |
  지뢰찾기 규칙:
  지뢰를 피해 안전한 칸을 모두 열어야 해요.
  • [숫자]는 주변 8칸의 지뢰 수
  • 지뢰라 확신하면 [깃발]로 표시
  • 모든 [안전한 칸]을 열면 승리!

timeline:
  - delay: 0.5s
    event: highlight_cell(1,1, color: blue)            # 숫자 "2" 강조
    sync: text_highlight("숫자", color: blue)

  - delay: 0.5s
    event: highlight_neighbors(1,1, color: lightBlue)  # 주변 8칸 영역 표시
    sync: pulse_cell(1,0, color: red)                  # 지뢰 위치 깜빡임

  - delay: 1.5s
    event: flag_appear(1,0)                            # 지뢰 위치에 🚩 등장
    sync: text_highlight("깃발", color: orange)

  - delay: 1.5s
    event: open_animation(cells: [(0,0),(2,0),(3,0)~(3,2),(4,0)~(4,3)])
    sync: text_highlight("안전한 칸", color: green)     # 안전 칸 열리는 애니메이션
```

#### 2/4 셀 열기

```yaml
board: 전체 미공개 5×5

timeline:
  - delay: 0.5s → cursor_move(to: cell(3,2))
  - delay: 0.2s → tooltip_show("안전하다고 생각하는 칸을 탭하세요.")
  - delay: 0.5s → cursor_tap(cell(3,2))
  - delay: 0.3s → cell_reveal(3,2, value: 0)          # 빈 칸 공개
  - delay: 0.2s → chain_reveal(from: (3,2))            # 연쇄 열기 애니메이션
    # 빈 칸에서 인접 빈 칸으로 물결처럼 퍼지며 열림
```

#### 3/4 깃발 모드

```yaml
board: 2/4 결과 상태 (일부 열림)
toolbar: visible (깃발 모드 버튼 포함)

timeline:
  - delay: 0.5s → cursor_move(to: button("flag"))
  - delay: 0.2s → cursor_tap → button_activate("flag")
  - delay: 0.3s → tooltip_show("깃발 모드를 켜서 지뢰 위치를 표시하세요.")
  - delay: 0.8s → cursor_move(to: suspected_mine_cell)
  - delay: 0.2s → cursor_tap → flag_place(cell, animation: bounce)  # 🚩 등장
```

#### 4/4 힌트 (공통)

#### 규칙 섹션: 숫자와 깃발 (4페이지)

**1/4 — 숫자가 알려주는 것**

```yaml
board: 3×3 확대 뷰, 중앙에 "2"

timeline:
  - delay: 0.5s
    event: highlight_cell(1,1, color: blue, label: "2")

  - delay: 0.5s
    event: highlight_neighbors(1,1, color: lightGray)   # 주변 8칸 영역 표시
    sync: count_label("8칸 중...")

  - delay: 1.0s
    event: reveal_mine(0,1, animation: fadeIn)           # 지뢰 1 등장
    sync: count_update("1개 발견")

  - delay: 1.0s
    event: reveal_mine(2,2, animation: fadeIn)           # 지뢰 2 등장
    sync: count_update("2개 = 숫자와 일치!")
    sync: checkmark_show()
```

**2/4 — 빈 칸 연쇄 열기**

```yaml
timeline:
  - delay: 0.5s → cursor_tap(빈칸)
  - delay: 0.2s → wave_open(from: 탭 위치, speed: 0.1s/cell)
    # 물결 효과: 중심에서 동심원처럼 인접 빈 칸이 순차적으로 열림
    # 숫자 칸에 도달하면 멈춤
  - delay: wave_complete → tooltip_show("빈 칸을 열면 주변이 자동으로 열려요!")
```

**3/4, 4/4**: 깃발 활용, 추론 예시 (유사 패턴)

---

### 2.4 Yin-Yang (음양)

#### 메뉴 구조
```
← 기본 규칙
  플레이 방법          >   (4페이지)
  연결과 2×2 제한     >   (3페이지)
```

#### 1/4 규칙 요약

```yaml
board: 완성 5×5
  ● ○ ● ○ ●
  ○ ○ ● ● ○
  ● ○ ○ ● ●
  ● ● ○ ○ ●
  ○ ● ● ○ ○

text: |
  음양 규칙:
  격자를 ●과 ○로 채워서:
  • 같은 색은 모두 [연결]되어야 합니다
  • 같은 색 [2×2 블록] 금지

timeline:
  - delay: 0.5s
    event: trace_path(color: black, cells: 모든_●_셀, animation: draw_line)
    sync: text_highlight("연결", color: blue)
    # 검은 셀들을 연결하는 경로가 선으로 그려지며 "하나의 그룹" 시각화

  - delay: 2.0s
    event: trace_path_fade()                            # 경로선 페이드아웃

  - delay: 0.5s
    event: highlight_2x2(row:1, col:2, color: red)      # 2×2 블록 강조
    sync: text_highlight("2×2 블록", color: red)
    sync: cross_mark_show()                             # ✗ 표시

  - delay: 1.5s
    event: fix_2x2(animation: swap)                     # 수정되는 모습
    sync: checkmark_show()
```

#### 3/4 토글 조작

```yaml
timeline:
  - delay: 0.5s → tooltip_show("셀을 탭하면 ○ → ● → 빈칸 순으로 전환됩니다.")
  - delay: 0.8s → cursor_tap → cell_show("○", fadeIn)
  - delay: 0.8s → cursor_tap → cell_show("●", fadeIn)
  - delay: 0.8s → cursor_tap → cell_clear(fadeOut)
  - delay: 0.5s → cursor_tap → cell_show("○", fadeIn)   # 정답 확정
```

#### 규칙 섹션: 연결과 2×2 제한 (3페이지)

**1/3 — 연결 실패 예시**

```yaml
board: 5×5 — 검은 셀이 2그룹으로 분리
  ● ● ○ ○ ○
  ○ ○ ○ ○ ○
  ○ ○ ○ ● ●
  ...

timeline:
  - delay: 0.5s
    event: highlight_group(group_A: [(0,0),(0,1)], color: red)
    sync: highlight_group(group_B: [(2,3),(2,4)], color: red)
    sync: label_show("2개 그룹 = 위반!")

  - delay: 1.0s
    event: error_shake(groups: [A, B])
    sync: disconnect_indicator(groupA, groupB)            # 끊어진 표시

  - delay: 2.0s
    event: transition_board(연결된_보드)
    sync: trace_path(모든_●_셀, color: green)             # 하나로 연결
    sync: label_show("1개 그룹 = 정상!")
    sync: checkmark_show()
```

**2/3, 3/3**: 연결 성공, 2×2 금지 (유사 패턴)

---

### 2.5 Nonograms (노노그램)

#### 메뉴 구조
```
← 기본 규칙
  플레이 방법          >   (4페이지)
  단서 읽는 법         >   (4페이지)
  X 마킹 전략          >   (2페이지)
```

#### 1/4 규칙 요약

```yaml
board: 완성 5×5 (하트 모양) + 단서 표시
  행단서: [1,1] [3] [5] [3] [1]
  열단서: [1] [3] [5] [3] [1]

  ○ ■ ○ ■ ○
  ○ ■ ■ ■ ○
  ■ ■ ■ ■ ■
  ○ ■ ■ ■ ○
  ○ ○ ■ ○ ○

text: |
  노노그램 규칙:
  [숫자 단서]에 맞춰 칸을 칠해 그림을 완성하세요!
  • 숫자는 [연속 블록]의 길이
  • 여러 숫자 = 블록 사이 [최소 1칸] 빈칸

timeline:
  - delay: 0.5s
    # 그림이 한 줄씩 드러나는 애니메이션
    event: reveal_row(0, duration: 0.3s)                 # ○ ■ ○ ■ ○
    sync: highlight_clue(row: 0, flash: true)            # 단서 "1 1" 깜빡

  - delay: 0.5s
    event: reveal_row(1, duration: 0.3s)
    sync: highlight_clue(row: 1, flash: true)

  - delay: 0.5s
    event: reveal_row(2, duration: 0.3s)
    sync: highlight_clue(row: 2, flash: true)

  - delay: 0.5s
    event: reveal_row(3, duration: 0.3s)

  - delay: 0.5s
    event: reveal_row(4, duration: 0.3s)

  - delay: 1.0s
    event: flash_complete_picture()                      # 완성 그림 전체 반짝
```

#### 규칙: 단서 읽는 법 1/4 — 단일 숫자

```yaml
board: 1행 5칸 확대 뷰 + 단서 "3"

timeline:
  - delay: 0.5s
    event: highlight_clue("3", color: blue, pulse: true)

  - delay: 0.8s
    event: fill_cell(0,1, animation: stamp)              # ■ 등장
  - delay: 0.3s
    event: fill_cell(0,2, animation: stamp)
  - delay: 0.3s
    event: fill_cell(0,3, animation: stamp)
    # 3칸이 "탁탁탁" 순차적으로 칠해지는 애니메이션

  - delay: 0.5s
    event: bracket_show(cells: [(0,1)~(0,3)], label: "3칸 연속")
    sync: checkmark_show()
```

---

### 2.6 Killer Sudoku (킬러 스도쿠)

#### 1/4 규칙 요약

```yaml
board: 완성 4×4 + 케이지(점선) 오버레이

timeline:
  - delay: 0.5s
    event: highlight_cage(cage_A, color: yellow)         # 첫 번째 케이지
    sync: sum_label_show(cage_A, "합=7")

  - delay: 1.5s
    event: highlight_cage(cage_B, color: blue)
    sync: sum_label_show(cage_B, "합=3")
    sync: text_highlight("케이지", color: yellow)

  - delay: 1.5s
    event: highlight_row(0, color: pink)
    sync: text_highlight("행/열 규칙도 적용", color: pink)
```

#### 규칙: 케이지와 합 1/3

```yaml
timeline:
  - delay: 0.5s
    event: zoom_cage(cage_A)                              # 케이지 확대
    sync: dotted_border_pulse(cage_A)                     # 점선 테두리 깜빡

  - delay: 1.0s
    event: number_fly_in(cell_1, value: 1)               # 숫자가 날아들어감
  - delay: 0.5s
    event: number_fly_in(cell_2, value: 2)
  - delay: 0.3s
    event: sum_animation("1 + 2 = 3 ✓", color: green)   # 합 계산 애니메이션

  - delay: 1.0s
    event: number_try(cell_1: 2, cell_2: 2)              # 잘못된 예시
    sync: sum_animation("2 + 2 = 4 ✗", color: red)
    sync: label_show("중복!")
    sync: error_shake()
```

---

### 2.7 Star Battle (스타 배틀)

#### 1/4 규칙 요약

```yaml
board: 완성 5×5 (1-star) + 영역 경계

timeline:
  - delay: 0.5s
    event: star_appear(cells: 각_행의_별위치, animation: twinkle)
    # 별이 반짝이며 하나씩 등장

  - delay: 1.5s
    event: highlight_row(0, color: yellow)
    sync: count_stars(row:0, count: 1)                   # "★ × 1"

  - delay: 1.0s
    event: highlight_region(A, color: blue)
    sync: count_stars(region: A, count: 1)

  - delay: 1.0s
    event: highlight_adjacent(star_at(0,2), color: red)  # 인접 8칸 빨강
    sync: text_highlight("인접 금지", color: red)
    sync: cross_marks(adjacent_cells)
```

---

### 2.8 Light Up (라이트 업)

#### 1/4 규칙 요약

```yaml
board: 5×5, 검은 벽 + 전구 배치

timeline:
  - delay: 0.5s
    event: bulb_place(2,2, animation: glow)              # 전구 배치
  - delay: 0.3s
    event: light_spread(from: (2,2), direction: all_4)   # 빛 전파 애니메이션
    # 전구에서 상하좌우로 빛이 물결처럼 퍼짐
    # 검은 벽에 닿으면 멈춤

  - delay: 1.5s
    event: highlight_black_cell(3,0, number: 2)
    sync: highlight_neighbors(3,0, color: blue)
    sync: text_highlight("검은 칸 숫자 = 인접 전구 수", color: blue)

  - delay: 1.5s
    event: bulb_place_error(0,0)                         # 서로 비추는 전구
    sync: conflict_line(from: (0,0), to: (2,0), color: red)  # 빨간 충돌선
    sync: text_highlight("전구끼리 비추면 안 됨!", color: red)
```

---

### 2.9 Futoshiki (부등식)

#### 1/4 규칙 요약

```yaml
board: 완성 4×4 + 부등호 표시

timeline:
  - delay: 0.5s
    event: highlight_row(0, color: yellow)
    sync: text_highlight("행/열에 1~N 한 번씩", color: yellow)

  - delay: 1.5s
    event: inequality_pulse(between: (0,0)-(0,1), sign: ">")
    # 부등호가 커졌다 작아지는 펄스 애니메이션
    sync: compare_animation(left: 3, right: 1, result: "3 > 1 ✓")

  - delay: 1.5s
    event: inequality_error(between: (1,0)-(1,1), sign: "<")
    sync: compare_animation(left: 4, right: 2, result: "4 < 2 ✗")
    sync: error_shake()
```

---

### 2.10 Tents (텐트)

#### 1/4 규칙 요약

```yaml
board: 완성 5×5 + 나무/텐트

timeline:
  - delay: 0.5s
    event: tree_appear(all_trees, animation: grow)       # 나무가 자라남

  - delay: 1.0s
    event: tent_appear(all_tents, animation: drop)       # 텐트가 위에서 떨어짐
    # 각 텐트가 대응 나무 옆에 하나씩

  - delay: 0.5s
    event: pair_connect(tree(0,1), tent(0,0), color: green, line: dashed)
    # 나무-텐트 쌍을 점선으로 연결

  - delay: 0.3s
    event: pair_connect(tree(1,3), tent(1,4), color: green)
    # 나머지 쌍도 순차 연결

  - delay: 1.5s
    event: highlight_adjacent_tents(tent(0,0), tent(1,1), color: red)
    sync: text_highlight("텐트끼리 인접 금지!", color: red)

  - delay: 1.5s
    event: highlight_edge_numbers(color: blue)
    sync: text_highlight("가장자리 숫자 = 텐트 수", color: blue)
```

---

### 2.11 Jigsaw Sudoku (직소 스도쿠)

#### 1/4 규칙 요약

```yaml
board: 완성 6×6 + 불규칙 영역 경계

timeline:
  - delay: 0.5s
    event: region_color_fill(region_A, color: pastelYellow, animation: flood)
    # 영역이 색으로 채워지는 애니메이션

  - delay: 0.3s
    event: region_color_fill(region_B, color: pastelBlue)
  - delay: 0.3s
    event: region_color_fill(region_C, color: pastelGreen)
    # 모든 영역이 순차적으로 색칠됨 → "이것이 직소 영역"

  - delay: 1.5s
    event: highlight_region(region_A, color: yellow, bold_border: true)
    sync: number_label("1~6 한 번씩")

  - delay: 1.5s
    event: highlight_row(0, color: pink)
    sync: text_highlight("행/열 규칙도 동일!", color: pink)
```

---

### 2.12 Skyscrapers (고층 빌딩)

#### 1/4 규칙 요약

```yaml
board: 완성 4×4 + 가장자리 단서 + 3D 빌딩 뷰

timeline:
  - delay: 0.5s
    event: building_rise(row: 0, heights: [1,3,2,4], animation: grow_up)
    # 빌딩이 아래에서 위로 솟아오르는 3D 시각화

  - delay: 1.5s
    event: eye_appear(direction: left, row: 0)           # 👁 아이콘 등장
    sync: sight_line(from: left, through: [1,3,2,4])     # 시야선 애니메이션
    # 높이 1 보임 → 높이 3 보임(1보다 높으니까) → 높이 2 안 보임(3에 가림) → 높이 4 보임
    sync: visible_counter("보이는 빌딩: 1...2...3!")

  - delay: 1.0s
    event: clue_highlight(left, row: 0, value: 3, color: blue)
    sync: text_highlight("단서 3 = 보이는 빌딩 3개", color: blue)

  - delay: 1.5s
    event: eye_move(direction: right, row: 0)
    sync: sight_line(from: right, through: [4,2,3,1])
    sync: visible_counter("보이는 빌딩: 1!")              # 4가 맨 앞 → 1개만
    sync: clue_highlight(right, row: 0, value: 1)
```

---

### 2.13 Kakuro (카쿠로)

#### 1/4 규칙 요약

```yaml
board: 소형 카쿠로 + 단서 셀(대각선 분할)

timeline:
  - delay: 0.5s
    event: zoom_clue_cell(1,0)                           # 단서 셀 확대
    sync: diagonal_split_animation()                     # 대각선 분할 표시

  - delay: 0.5s
    event: arrow_show(from: clue_right, direction: right)
    sync: label("→ 가로 합")

  - delay: 0.5s
    event: arrow_show(from: clue_down, direction: down)
    sync: label("↓ 세로 합")

  - delay: 1.5s
    event: zoom_out()
    sync: highlight_run(horizontal, from: (1,0), cells: [(1,1),(1,2)])
    sync: number_fly_in(1,1, value: 1)
    sync: number_fly_in(1,2, value: 2)
    sync: sum_animation("1 + 2 = 3 ✓")

  - delay: 1.5s
    event: try_wrong(1,1: 2, 1,2: 1)                    # 순서 바꿔도 OK 표시
    sync: sum_animation("2 + 1 = 3 ✓ (순서 무관)")

  - delay: 1.5s
    event: try_wrong(1,1: 2, 1,2: 2)                    # 중복 시도
    sync: sum_animation("2 + 2 = 4 ✗ 합 불일치")
    sync: label("+ 중복!")
    sync: error_shake()
```

---

## 3. 전체 요약 매트릭스 (v2 — 애니메이션 기준)

| # | 게임 | 총 페이지 | 애니메이션 이벤트 수 | 핵심 연출 |
|---|---|---|---|---|
| 1 | Sudoku | 10 | ~35 | 행/열/박스 순차 색상 하이라이트 + 메모 입력 시연 |
| 2 | Binairo | 7 | ~30 | 토글 전환(○→●→빈), 3연속 흔들림, 행 유일성 비교 |
| 3 | Minesweeper | 8 | ~35 | 빈칸 물결 열기, 지뢰 등장, 깃발 배치 |
| 4 | Yin-Yang | 7 | ~25 | 연결 경로 그리기, 분리 그룹 흔들림, 2×2 금지 |
| 5 | Nonograms | 10 | ~40 | 줄별 순차 공개, 블록 스탬프 채우기, X 마킹 |
| 6 | Killer Sudoku | 9 | ~35 | 케이지 점선 펄스, 합 계산 애니메이션, 중복 에러 |
| 7 | Star Battle | 7 | ~25 | 별 반짝임, 인접 금지 영역, 영역별 카운트 |
| 8 | Light Up | 7 | ~30 | 빛 전파 물결, 전구 충돌선, 검은 셀 숫자 카운트 |
| 9 | Futoshiki | 7 | ~25 | 부등호 펄스, 크기 비교 애니메이션, 체인 추론 |
| 10 | Tents | 9 | ~30 | 나무 성장 → 텐트 떨어짐, 쌍 연결선, 인접 금지 |
| 11 | Jigsaw Sudoku | 9 | ~25 | 영역 순차 색칠(flood fill), 불규칙 경계 강조 |
| 12 | Skyscrapers | 10 | ~40 | 빌딩 솟아오름 3D, 시야선 관통, 가시성 카운터 |
| 13 | Kakuro | 10 | ~35 | 대각선 분할 확대, 숫자 날아듦, 합 계산 실시간 |
| **합계** | | **110p** | **~410** | |

---

## 4. 애니메이션 구현 가이드

### 4.1 공통 애니메이션 라이브러리 (필요한 프리미티브)

```
cursor_move(from, to, duration, curve)     — 손 커서 이동
cursor_tap(position)                       — 탭 제스처 (누름 → 올림)
cursor_appear / cursor_disappear           — 등장/퇴장

tooltip_show(text, anchor, direction)      — 말풍선 페이드인
tooltip_hide()                             — 페이드아웃

highlight_row(n, color)                    — 행 전체 하이라이트
highlight_column(n, color)                 — 열 전체 하이라이트
highlight_box(r, c, color)                 — N×N 박스 하이라이트
highlight_cells(list, color)               — 특정 셀 목록 하이라이트
highlight_region(id, color)                — 게임별 영역 (직소, 스타배틀)
highlight_cage(id, color)                  — 킬러 스도쿠 케이지
highlight_neighbors(cell, color)           — 인접 8칸 하이라이트

cell_select(r, c, color)                   — 셀 선택 상태
cell_fill(r, c, value, animation)          — 숫자 입력
cell_add_memo(r, c, value)                 — 메모 추가
cell_clear(r, c)                           — 값/메모 제거
cell_reveal(r, c, value)                   — 지뢰찾기용 공개

error_shake(target, duration)              — 좌우 흔들림
checkmark_show() / cross_mark_show()       — ✓/✗ 표시

button_activate(id, badge)                 — 도구 버튼 상태 변경

text_highlight(keyword, color)             — 텍스트 키워드 색상 동기화

trace_path(cells, color)                   — 경로 선 그리기 (음양 연결)
light_spread(from, directions)             — 빛 전파 (라이트업)
wave_open(from, speed)                     — 연쇄 열기 (지뢰찾기)
building_rise(row, heights)                — 빌딩 솟아오름 (스카이스크래퍼)
sight_line(from, through)                  — 시야선 (스카이스크래퍼)
star_appear(cells, twinkle)                — 별 등장 (스타배틀)
sum_animation(expression, color)           — 합 계산 (킬러/카쿠로)
pair_connect(a, b, line_style)             — 쌍 연결선 (텐트)
```

### 4.2 게임별 전용 애니메이션

| 게임 | 전용 애니메이션 |
|---|---|
| Minesweeper | `wave_open`, `flag_place`, `mine_explode` |
| Yin-Yang | `trace_path` (연결 시각화), `flood_check` |
| Nonograms | `stamp_fill` (탁탁탁 채우기), `clue_strikethrough` |
| Light Up | `light_spread` (빛 전파), `conflict_line` |
| Skyscrapers | `building_rise` (3D), `sight_line`, `visible_counter` |
| Star Battle | `star_twinkle`, `adjacent_zone` |
| Kakuro | `diagonal_split_zoom`, `sum_counter` |
| Tents | `tree_grow`, `tent_drop`, `pair_line` |

### 4.3 모션 감소(Reduce Motion) 대응

```
motionScale == 0 일 때:
- 모든 이동 애니메이션 → 즉시 위치 변경
- 페이드인/아웃 → 즉시 표시/숨김
- 흔들림/펄스 → 색상만 0.2초 전환
- 물결/전파 → 동시 표시
- 손 커서 이동 → 도착 위치에 바로 표시
- 타임라인 delay → 최소 0.3초로 단축 (읽기 시간 보장)
```

### 4.4 구현 접근 — AnimationController 기반

```dart
class TutorialPageAnimator {
  final List<TutorialEvent> timeline;
  late AnimationController _controller;
  
  // 전체 타임라인을 하나의 AnimationController로 관리
  // 각 이벤트의 delay/duration을 기반으로 Interval 계산
  // 사용자가 "다음"을 누르면 현재 애니메이션 완료 → 다음 페이지
  // "이전"을 누르면 현재 페이지 처음부터 재생
  
  void play() { ... }
  void pause() { ... }
  void skipToEnd() { ... }  // 최종 상태로 즉시 전환
}
```

---

## 5. 4개국어 텍스트 (게임별 예시)

> 1/4 규칙 텍스트만 예시. 툴팁/라벨은 공통 키로 처리.

### Sudoku

| 언어 | 규칙 텍스트 |
|---|---|
| 한국어 | 클래식 스도쿠 규칙:\n9x9 그리드를 채워서:\n• 각 [3x3박스]는 1~9를 포함\n• 각 [줄]은 1~9를 포함\n• 각 [열]은 1~9를 포함\n어떤 [3x3박스], [줄], [열]에서도 반복 금지! |
| English | Classic Sudoku Rules:\nFill the 9x9 grid:\n• Each [3x3 box] contains 1-9\n• Each [row] contains 1-9\n• Each [column] contains 1-9\nNo repeats in any [box], [row], or [column]! |
| 日本語 | 数独のルール:\n9x9グリッドを埋めます:\n• 各[3x3ボックス]に1~9\n• 各[行]に1~9\n• 各[列]に1~9\nどの[ボックス]・[行]・[列]でも重複不可！ |
| 中文 | 经典数独规则:\n填满9x9网格:\n• 每个[3x3宫]包含1-9\n• 每[行]包含1-9\n• 每[列]包含1-9\n任何[宫]、[行]、[列]都不能重复！ |

> **[대괄호]** 안의 키워드가 보드 하이라이트와 색상 동기화되는 부분

### 공통 툴팁 (13게임 공유)

| 키 | 한국어 | English | 日本語 | 中文 |
|---|---|---|---|---|
| tutorial.tooltip.tapCell | 빈 셀을 클릭하세요. | Tap an empty cell. | 空マスをタップ。 | 点击空格。 |
| tutorial.tooltip.pencilMode | 연필 모드를 켜서 메모를 쉽게 추가하거나 제거해 보세요! | Turn on pencil mode to easily add or remove notes! | 鉛筆モードでメモを追加・削除！ | 开启铅笔模式轻松添加或删除笔记！ |
| tutorial.tooltip.hint | 퍼즐에 막혔나요? 힌트를 사용해보세요! | Stuck? Try using a hint! | 行き詰まった？ヒントを使おう！ | 卡住了？试试提示！ |
| tutorial.tooltip.toggleCell | 셀을 탭하면 순서대로 전환됩니다. | Tap to cycle through states. | タップで状態を切り替え。 | 点击循环切换状态。 |
| tutorial.tooltip.flagMode | 깃발 모드를 켜서 지뢰 위치를 표시하세요. | Turn on flag mode to mark mines. | フラグモードで地雷をマーク。 | 开启旗帜模式标记地雷。 |

---

## 6. 구현 우선순위

### Phase 1: 애니메이션 프레임워크 (공통)
1. `TutorialEvent` sealed class + 서브타입 정의
2. `TutorialPageAnimator` — 타임라인 재생 엔진
3. 공통 프리미티브: cursor, tooltip, highlight, cell_change, button_state
4. `TutorialAnimatedPage` 위젯 — 실제 게임 보드 + 오버레이 레이어

### Phase 2: 스도쿠 먼저 완성
1. 기존 V1/V2 튜토리얼을 애니메이션 기반으로 교체
2. 영상과 동일한 품질 달성 확인
3. QA: 모션 감소, 4언어, TalkBack, 텍스트 스케일

### Phase 3: 출시 순서대로 확장
1. Binairo (R1 출시 완료 → 튜토리얼 업그레이드)
2. Minesweeper (R2 대기)
3. 이후 R3~R12 순서

### Phase 4: 게임별 전용 애니메이션
- 각 게임 고유 연출 (빛 전파, 빌딩 솟아오름, 연결 경로 등)

---

## 7. QA 체크리스트 (게임별)

- [ ] 1/4: 보드 하이라이트가 텍스트 키워드 색상과 동기화
- [ ] 1/4: 하이라이트가 순차적으로 등장 (동시 아님)
- [ ] 2/4: 손 커서가 부드럽게 이동 (뚝뚝 끊김 없음)
- [ ] 2/4: 툴팁이 커서 도착 후 등장 (선행 등장 안 됨)
- [ ] 3/4: 버튼 탭 → 상태 변경이 동기화
- [ ] 3/4: 메모/값 입력이 실제처럼 셀에 반영
- [ ] 4/4: 힌트 결과가 펄스 애니메이션으로 표시
- [ ] 모션 감소: 모든 애니메이션이 즉시 전환으로 대체
- [ ] 4개국어: 텍스트 전환 시 타임라인 재시작
- [ ] TalkBack: 각 이벤트 시점에 안내 텍스트 announce
- [ ] 텍스트 1.6배: 툴팁/설명 레이아웃 정상
- [ ] "다음" 탭: 현재 애니메이션 스킵 → 최종 상태 → 다음 페이지
- [ ] "이전" 탭: 이전 페이지 처음부터 재생

---

> **v1.0 → v2.0 변경 사항**: 정적 MiniBoardIllustration 기반 → 타임라인 기반 애니메이션 시스템으로 전면 개편. 영상 분석 결과를 반영하여 손 커서 이동, 텍스트-보드 색상 동기화, 순차 하이라이트, 실시간 셀 상태 변경 등 동적 연출 기획 추가.
