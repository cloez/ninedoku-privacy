# K-Puzzles 공통 "게임 방법" 화면 설계서

> **버전**: v1.0 (2026-06-16)
> **범위**: 13개 퍼즐 게임 공통 튜토리얼 프레임워크
> **작성**: 기획(GD) + UX 합의안 / PM 승인 대기
> **연관 문서**: `docs/tutorial_content_sudoku.md` (스도쿠 상세 컨텐츠 — 다른 12게임 작성 시 참고 템플릿)

---

## 0. 설계 목표

| 목표 | 설명 |
|---|---|
| 일관성 | 13게임 모두 동일한 화면 골격, 동일한 인터랙션 패턴 |
| 한 손 조작 | 모든 컨트롤은 화면 하단 1/3 영역 |
| 4언어 대응 | 텍스트 길이 ±30% 가변, 동적 폰트 스케일 1.3까지 깨지지 않음 |
| 모션 감소 | 모든 전환은 `motionScale` 반영, `0`이면 즉시 전환 |
| 오프라인 | 모든 자산(이미지/일러스트) 로컬 번들 |
| 접근성 | TalkBack 라벨, 색 외 패턴 보조, 최소 터치 44dp |

---

## 1. 사용자 지침 15개 항목 — 일괄 응답

### 항목 1. 게임별 권장 단계 수

원칙: **3단계 = 미니멈 학습 (한 줄 규칙)**, **5단계 = 표준**, **6단계 = 복합 규칙 게임**.
세부 매트릭스는 §3 참조.

| 그룹 | 권장 단계 수 | 예 |
|---|---|---|
| 단일 규칙 / 이진 | 3~4 | Binairo, Yin-Yang |
| 표준 라틴 사각형 계열 | 5 | Sudoku, Jigsaw, Killer, Futoshiki |
| 단서 + 보드 분리형 | 5~6 | Nonograms, Skyscrapers, Kakuro |
| 위상/관계형 | 4~5 | Light Up, Tents, Star Battle, Minesweeper |

### 항목 2. 전체 화면 흐름

```
[진입 트리거]
  ├─ 첫 진입 (자동) ──────────────┐
  ├─ 메인 화면 도움말 (?) 버튼 ───┤
  └─ 게임 중 일시정지 → 도움말 ─┤
                                  ▼
                       [TutorialScreen 모달/풀스크린]
                                  │
                       ┌──────────┼──────────┐
                       ▼          ▼          ▼
                   Step 1  → Step 2 → ... → Step N
                       │ (Next/Skip/Back/점 인디케이터)
                       ▼
                  [완료 화면]
                       │
              ┌────────┼────────┐
              ▼                 ▼
     "지금 플레이" 버튼   "다시 보지 않기" 체크
              │
              ▼
        [게임 화면 진입]
```

### 항목 3. 단계별 제목 — 공통 템플릿

| 단계 슬롯 | 의도 | 제목 템플릿 (한국어) | 영문 키 패턴 |
|---|---|---|---|
| S1 | 목표 한 줄 | "{게임명}이란?" | `tutorial.{game}.step1.title` = `"What is {Game}?"` |
| S2 | 핵심 규칙 1 | "기본 규칙" | `step2.title` = `"Basic Rule"` |
| S3 | 핵심 규칙 2 (보조) | "또 하나의 규칙" | `step3.title` = `"Another Rule"` |
| S4 | 조작 방법 | "조작 방법" | `step4.title` = `"How to Play"` |
| S5 | 보조 기능 | "메모와 힌트" | `step5.title` = `"Notes & Hints"` |
| S6 | 직접 해보기 | "직접 풀어보기" | `step6.title` = `"Try it"` |

> S3, S5, S6은 게임별로 생략 가능. 그러나 **S1·S2·S4는 필수**.

### 항목 4. 단계별 설명 문구 (스도쿠 예시 + 공통 패턴)

| 단계 | 문구 패턴 | 스도쿠 적용 예 |
|---|---|---|
| S1 | "{N}×{N} 판을 {규칙요약}으로 채우는 퍼즐입니다." | "9×9 칸을 1–9 숫자로 채우는 퍼즐입니다." |
| S2 | "{영역}마다 {제약}을 만족해야 합니다." | "가로·세로·3×3 박스마다 1–9가 정확히 한 번씩 들어갑니다." |
| S3 | "{보조 규칙 / 변형 규칙}" | (스도쿠는 생략 가능 — Killer/Futoshiki/Skyscrapers에서 사용) |
| S4 | "칸을 탭하고 아래 숫자 패드로 입력하세요." | 그대로 |
| S5 | "확신이 없으면 메모 모드로 후보를 적어두세요." | 그대로 |
| S6 | "이 빈칸 하나를 직접 채워보세요." | "노란 칸에 들어갈 숫자는 무엇일까요?" |

다른 게임 적용 — Binairo S2: "가로·세로마다 0과 1이 같은 수로 들어가고, 셋 이상 연속 금지." / Nonograms S2: "단서 숫자는 한 줄 안에서 연속된 검은 칸의 길이입니다."

### 항목 5. 단계별 게임판 미니예시

원칙: **풀 보드 보이지 않고**, 항상 **3×3 또는 5×5 축약** 미니보드를 사용. 진짜 보드 위젯을 `miniature: true` 모드로 재사용.

| 단계 | 미니예시 컨텐츠 |
|---|---|
| S1 | 정답이 채워진 미니 보드 (성취 이미지) |
| S2 | 규칙 위반 vs 만족 비교 — 빨간 X / 초록 ✓ 오버레이 |
| S3 | 변형 규칙 강조 (예: Killer는 케이지 점선 강조, Futoshiki는 부등호 깜빡임) |
| S4 | 손가락 아이콘이 셀을 탭 → 키패드 강조 애니메이션 (motionScale 반영) |
| S5 | 메모 표시된 셀 + 힌트 전구 아이콘 |
| S6 | 인터랙티브 미니 보드 — 빈칸 1~3개만 비워둠 |

### 항목 6. 각 단계 사용자 행동

| 단계 | 행동 | 강제? |
|---|---|---|
| S1~S5 | 읽기 + Next 탭 (또는 좌우 스와이프) | 비강제 (Skip 가능) |
| S6 (연습) | 정답 셀에 정답 입력 | **약한 강제** — 정답 입력 시에만 "완료" 활성. 단, "건너뛰기" 항상 표시 |

### 항목 7. 성공 시 화면 반응

- 셀 색상이 0.4s 동안 success 토큰 컬러로 펄스 (motionScale=0이면 즉시 정착)
- 햅틱: `HapticFeedback.lightImpact()`
- 사운드: `success.ogg` (음소거 시 생략)
- 짧은 토스트: "정답이에요!"
- 0.6s 후 자동으로 "완료" 버튼 강조 / 또는 다음 단계로 이동

### 항목 8. 잘못 조작 시 화면 반응

- 셀을 좌우 6px 진동 (350ms, motionScale 반영)
- 색상: error 토큰 (단, **색 외에 ⚠ 아이콘**도 함께 표시 — 색맹 대응)
- 햅틱: `HapticFeedback.selectionClick()` (강도 약함)
- 인라인 힌트 노출: "다시 살펴봐요 — {간단한 단서}"
- 3회 연속 오답 시 → "정답 보기" 버튼 등장 (강제 진행 차단 방지)

### 항목 9. 건너뛰기 / 다시 보기 동작

| 동작 | 결과 | 저장 |
|---|---|---|
| Skip (어디서든) | 튜토리얼 종료 → 게임 화면 진입 | `tutorial_seen_{game} = true` |
| Skip 후 메인 화면 ? 버튼 탭 | 동일 튜토리얼 모달 재실행 (1단계부터) | 저장 변화 없음 |
| 마지막 단계 완료 → "지금 플레이" | 게임 진입 | `tutorial_completed_{game} = true` |
| "다시 보지 않기" 체크 + 완료 | 첫 진입 자동 표시 비활성 | `tutorial_autoshow_{game} = false` |
| 설정 화면 → "튜토리얼 초기화" | 모든 게임의 자동 표시 재활성 | 모든 키 초기화 |

### 항목 10. UI 상태 머신 (StatefulWidget)

```dart
enum TutorialPhase {
  reading,           // 텍스트 + 일러스트 표시 중
  practiceWaiting,   // S6: 사용자 입력 대기
  practiceCorrect,   // 정답 입력 직후 (펄스/햅틱 진행)
  practiceWrong,     // 오답 입력 직후 (흔들림/힌트)
  practiceRevealed,  // "정답 보기" 클릭 후 정답 노출
  completed,         // 마지막 단계 + 정답 도달
}

// 전이
reading --(Next)--> reading | practiceWaiting
practiceWaiting --(정답)--> practiceCorrect --(0.6s)--> completed
practiceWaiting --(오답)--> practiceWrong --(0.4s)--> practiceWaiting
practiceWaiting --(오답 3회)--> practiceRevealed --(Next)--> completed
모든 상태 --(Skip)--> 종료
모든 상태 --(Back)--> 이전 단계로
```

### 항목 11. 접근성 고려사항

- **TalkBack/VoiceOver**: 각 단계 진입 시 제목 + 설명을 자동 announce. 미니보드 셀은 "행 X, 열 Y, 값 N" 형식 라벨.
- **색맹 (CVD)**: 정답/오답을 색 외 **아이콘**(✓/⚠)과 **패턴**(테두리 굵기/실선·점선)으로도 구분. 빨강-초록 단독 사용 금지.
- **글자 크기**: `MediaQuery.textScaleFactor` 1.0~1.6 지원. 제목은 22sp(기본), 본문은 16sp. 카드 최대 높이 가변, 미니보드는 최소 160dp 보장.
- **터치 타겟**: Next/Skip/Back 모두 최소 48×48dp.
- **모션 감소**: `MediaQuery.disableAnimations`가 true이면 펄스/슬라이드 0ms, 즉시 전환.
- **단축키 (외부 키보드)**: → Next, ← Back, Esc Skip, Enter 완료.

### 항목 12. 텍스트 와이어프레임

```
┌──────────────────────────────────────┐
│  ← Back      게임 방법         × Skip│ ← AppBar (44dp)
├──────────────────────────────────────┤
│                                      │
│           [제목: 22sp Bold]          │
│   "스도쿠란?"                        │
│                                      │
│           [미니 일러스트]            │
│   ┌──┬──┬──┐                         │
│   │ 5│ 3│ 7│                         │
│   ├──┼──┼──┤   ← 3×3 또는 5×5       │
│   │ 6│ 1│ 9│      (220dp 정사각)    │
│   ├──┼──┼──┤                         │
│   │ 2│ 8│ 4│                         │
│   └──┴──┴──┘                         │
│                                      │
│   [본문 설명 16sp]                   │
│   "9×9 칸을 1–9 숫자로…"             │
│                                      │
│                                      │
├──────────────────────────────────────┤
│        ● ● ○ ○ ○ ○      ← 점 인디케이터 (8dp)
│                                      │
│   [Back]              [Next →]       │  ← 56dp 버튼
└──────────────────────────────────────┘
```

S6 (연습 단계)는 미니 일러스트 자리에 **인터랙티브 보드**가 들어가고, Next 버튼이 "완료(비활성→활성)"으로 변함.

### 항목 13. 반드시 게임 시작 전 보여줄 내용

**최소 3가지**: S1(목표), S2(핵심 규칙), S4(조작). 이 3개가 없으면 사용자가 첫 수를 둘 수 없음.

> 단, "다시 보지 않기"가 켜져 있으면 자동 표시 안 함. 그래도 게임 화면 우상단 ? 아이콘은 항상 노출.

### 항목 14. 게임 플레이 중 상황별 노출

| 상황 | 노출 내용 |
|---|---|
| ? 아이콘 탭 | 전체 튜토리얼 (1단계부터) |
| 최초 오답 5회 | "도움말 다시 볼래요?" 1회 토스트 (X 버튼 우선) |
| 일시정지 화면 | "게임 방법 보기" 옵션 |
| 새 게임 메커니즘 등장 (예: Killer의 첫 케이지) | **마이크로 툴팁** — 1줄, 첫 등장 1회만 |
| 힌트 기능 첫 사용 | 힌트 결과 + "힌트는 점수에 영향이 있어요" 1회 노출 |

### 항목 15. 불필요/과도한 설명 (피해야 할 것)

| 안티패턴 | 이유 |
|---|---|
| 모든 규칙을 한 화면에 나열 | 인지부하. 단계 분리 원칙 위반. |
| "스도쿠의 역사는 1979년…" 식 배경 설명 | 게임 시작과 무관. 사용자 이탈. |
| 6단계 초과 | 사용자 90%가 5단계에서 이탈 (UX 리서치 가정값). |
| 강제 완료 (Skip 숨김) | 접근성 위반. 항상 Skip 보장. |
| 텍스트 + 같은 의미의 일러스트가 중복 설명 | "Show, don't tell" — 일러스트 우선, 텍스트는 보조 |
| 키패드까지 똑같이 모방한 풀스크린 모의 UI | 진짜 게임을 가리키는 화살표 한 줄로 충분 |
| 연속 3개 이상의 텍스트만 있는 단계 | 시각 자료 없는 단계 금지 — 항상 미니보드 동반 |
| 다음 단계 자동 이동 (사용자 의도 무시) | 항상 Next는 사용자 액션이어야 함 (S6 정답 후도 0.6s 시각 피드백만, 자동 이동은 옵션) |

---

## 2. 공통 프레임워크 — 컴포넌트 분리

```
TutorialScreen (StatefulWidget)
├── TutorialAppBar (← × 아이콘, 진행 텍스트 "2/5")
├── TutorialPageView (PageView.builder)
│    └── TutorialStepView (각 단계)
│         ├── StepTitle
│         ├── StepIllustration
│         │    ├── StaticMiniBoard      (S1~S5)
│         │    └── InteractiveMiniBoard (S6 — 게임별 보드 위젯 재사용)
│         └── StepDescription
└── TutorialFooter
     ├── DotIndicator
     └── NavigationButtons (Back / Skip / Next | 완료)
```

**핵심 재사용 원칙**: 각 게임의 `*BoardWidget`은 다음 두 가지 모드를 지원해야 함.
- `readonly: bool` — 입력 차단, 시각만 표시
- `forcedTarget: CellTarget?` — 특정 셀만 입력 허용 (S6 연습용)

이 두 파라미터를 추가하기 위해 각 게임 보드 위젯에 약간의 수정이 필요(코드 수정은 본 문서 범위 밖, DEV가 별도 작업).

---

## 3. 13게임 컨텐츠 매트릭스

| # | 게임 | 단계 수 | 핵심 규칙 | 보조 기능 | 연습 단계(S6) |
|---|---|---|---|---|---|
| 1 | Sudoku | 5 | 1–9가 행/열/3×3 박스에 한 번씩 | 메모, 힌트, 실행취소 | ✅ 1칸 채우기 |
| 2 | Binairo | 4 | 행/열에 0·1 동수, 셋 연속 금지, 행 중복 금지 | 토글, 잠금 셀 | ✅ 1칸 토글 |
| 3 | Minesweeper | 5 | 숫자=인접 8칸 지뢰 수 / 우클릭 깃발 | 깃발, 자동 열기 | ✅ 안전 칸 1개 열기 |
| 4 | Yin-Yang | 4 | 모든 검/백 셀이 각각 연결, 2×2 단색 금지 | 토글 (3-state) | ✅ 1칸 색칠 |
| 5 | Nonograms | 6 | 행/열 단서 = 연속 검은 칸 길이 / 단서 사이 1칸 이상 공백 | X 마킹, 자동 슬라시 | ✅ 작은 줄 완성 |
| 6 | Killer Sudoku | 6 | 스도쿠 + 점선 케이지 합 = 표시 숫자, 케이지 내 중복 금지 | 케이지 합 표시, 메모 | ✅ 2-셀 케이지 풀이 |
| 7 | Star Battle | 5 | 행/열/영역마다 별 정확히 N개, 별끼리 인접 금지 | 별/X 토글 | ✅ 작은 영역 별 배치 |
| 8 | Light Up | 5 | 전구를 배치해 모든 흰 칸을 밝힘, 전구끼리 직선상 안 보임, 검은 셀 숫자=인접 전구 수 | 전구/X 토글 | ✅ 1개 전구 배치 |
| 9 | Futoshiki | 5 | 라틴사각형 + 부등호 < > 만족 | 메모 | ✅ 부등호 만족 칸 |
| 10 | Tents | 5 | 각 나무에 텐트 1개 인접, 텐트끼리 인접(8방향) 금지, 행/열 숫자=텐트 수 | 텐트/잔디 토글 | ✅ 나무 옆 텐트 배치 |
| 11 | Jigsaw Sudoku | 5 | 스도쿠 규칙 + 9개 박스가 직사각형 아닌 직소 모양 | 메모, 힌트 | ✅ 직소 박스 인지 |
| 12 | Skyscrapers | 6 | 라틴사각형 + 가장자리 숫자=보이는 빌딩 수 | 메모, 가시성 시각화 | ✅ 1방향 단서 풀이 |
| 13 | Kakuro | 6 | 가로/세로 합 = 단서, 한 합 내 숫자 중복 금지, 1–9 | 메모, 가능 조합 표 | ✅ 2-셀 합 풀이 |

총 단계 수: 5+4+5+4+6+6+5+5+5+5+5+6+6 = **67단계**

---

## 4. 데이터 구조 제안

```dart
/// 단일 튜토리얼 단계
class TutorialStep {
  final String titleKey;            // 다국어 키: tutorial.sudoku.step1.title
  final String descriptionKey;
  final TutorialIllustration illustration;
  final InteractivePractice? practice; // null이면 정적 단계
  final List<String>? a11yHintKeys;    // TalkBack 보조 라벨

  const TutorialStep({
    required this.titleKey,
    required this.descriptionKey,
    required this.illustration,
    this.practice,
    this.a11yHintKeys,
  });
}

/// 일러스트 — 정적 또는 미니 보드
sealed class TutorialIllustration {
  const TutorialIllustration();
}

class IconIllustration extends TutorialIllustration {
  final IconData icon;
  const IconIllustration(this.icon);
}

class MiniBoardIllustration extends TutorialIllustration {
  final String gameId;               // 'sudoku', 'binairo', ...
  final List<List<int?>> board;      // 보드 상태
  final List<CellHighlight> highlights;
  final OverlayKind? overlay;        // okMark, errorMark, arrow
  const MiniBoardIllustration({
    required this.gameId,
    required this.board,
    this.highlights = const [],
    this.overlay,
  });
}

/// 인터랙티브 연습 단계
class InteractivePractice {
  final String gameId;
  final List<List<int?>> initialBoard;
  final CellTarget target;           // 사용자가 채워야 할 셀
  final int correctValue;
  final String hintKey;              // 오답 시 노출할 힌트
  final int maxWrongAttempts;        // 기본 3
  const InteractivePractice({
    required this.gameId,
    required this.initialBoard,
    required this.target,
    required this.correctValue,
    required this.hintKey,
    this.maxWrongAttempts = 3,
  });
}

class CellHighlight {
  final int row;
  final int col;
  final HighlightStyle style; // info, success, error, arrow
  const CellHighlight(this.row, this.col, this.style);
}

class CellTarget {
  final int row;
  final int col;
  const CellTarget(this.row, this.col);
}

enum OverlayKind { okMark, errorMark, arrow, pulse }
enum HighlightStyle { info, success, error, arrow }

/// 게임별 튜토리얼 정의
class GameTutorial {
  final String gameId;
  final List<TutorialStep> steps;
  const GameTutorial({required this.gameId, required this.steps});
}

/// 레지스트리 (DI)
abstract class TutorialRegistry {
  GameTutorial? forGame(String gameId);
}
```

---

## 5. 다국어 키 명명 규칙

### 형식

```
tutorial.{game}.step{n}.title         // 단계 제목
tutorial.{game}.step{n}.description   // 단계 본문
tutorial.{game}.step{n}.hint          // 연습 단계 오답 힌트
tutorial.{game}.step{n}.a11y          // TalkBack 보조 라벨
tutorial.{game}.complete.title        // 완료 화면 제목
tutorial.{game}.complete.cta          // 완료 CTA 버튼 라벨
tutorial.common.next                  // 공통 — Next
tutorial.common.back
tutorial.common.skip
tutorial.common.done
tutorial.common.tryAgain
tutorial.common.reveal                // 정답 보기
tutorial.common.doNotShowAgain
```

### 총 키 개수 추정

- 게임별: 67단계 × 평균 2.5키(title/description/hint 가끔) = **약 168개**
- 게임별 complete: 13 × 2 = 26개
- 공통: 약 12개
- **소계: ~206개 키**

4언어 (한/영/일/중): **206 × 4 ≈ 824 문자열**.

> 사용자 추정 520개와 차이: 본 설계는 hint 키와 complete 키, a11y 키를 추가하여 824 도출. 단순 title+description만 계산하면 13 × 5(평균) × 2 × 4 = 520과 일치.

---

## 6. 메인화면 진입점 — 게임별

### 6.1 공통 UI 패턴

각 게임의 `GameScreen` AppBar 우측에 도움말 아이콘 추가:

```
AppBar actions: [
  IconButton(
    icon: Icon(Icons.help_outline_rounded),
    tooltip: AppStrings.get('common.howToPlay'),
    onPressed: () => showTutorialModal(context, gameId),
  ),
  // ... 기존 액션 (일시정지, 설정 등)
]
```

탭 시 `showModalBottomSheet` 또는 `Navigator.push(fullscreenDialog: true)`로 `TutorialScreen`을 모달 표시.

### 6.2 첫 진입 자동 표시 정책

| 사례 | 자동 표시 |
|---|---|
| 사용자가 해당 게임을 처음 진입 (`tutorial_seen_{game}` 미존재) | ✅ |
| 이전에 Skip만 한 경우 | ❌ (저장된 seen=true) |
| "다시 보지 않기" 체크한 경우 | ❌ |
| 앱 업데이트로 새 게임 추가 | ✅ (해당 게임 첫 진입 시) |
| Hub에서 처음 게임을 탭한 사용자 | ✅ (게임마다 별개로 판정) |

### 6.3 합의된 디폴트 — 자동 표시 vs 사용자 선택

**합의**: 자동 표시 1회 + 항상 ? 아이콘으로 재진입 가능.
근거: 13개 게임을 모두 모른다고 가정해야 사용자가 안전. 단, 사용자가 Skip하면 강제하지 않음.

---

## 7. 인터랙티브 연습 — 게임 엔진 재사용 검토

| 게임 | 보드 위젯 재사용 가능? | 필요한 수정 |
|---|---|---|
| Sudoku | ✅ | `readonly`, `forcedTarget` 파라미터 추가 |
| Binairo | ✅ | 동일 |
| Minesweeper | ⚠ | "안전 칸 보장" 시드 필요 (S6 연습보드는 사전 검증) |
| Yin-Yang | ✅ | 동일 |
| Nonograms | ✅ | 단서 라벨 위젯도 함께 노출 |
| Killer Sudoku | ✅ | 케이지 렌더링 그대로 |
| Star Battle | ✅ | 영역 경계 강조 |
| Light Up | ✅ | 빛 시뮬레이션 그대로 |
| Futoshiki | ✅ | 부등호 깜빡임 추가 |
| Tents | ✅ | 행/열 단서 노출 |
| Jigsaw Sudoku | ✅ | 직소 박스 강조 |
| Skyscrapers | ⚠ | 가시성 시각화 별도 위젯 필요 |
| Kakuro | ✅ | 단서 셀 그대로 |

**결론**: 모든 게임에서 보드 위젯 재사용 가능. Minesweeper만 "사전 보장된 안전 시드"를 별도 보관.

---

## 8. 구현 우선순위 (DEV 가이드)

1. 공통 프레임워크 (`TutorialScreen` 리팩토링, `TutorialStep`/`TutorialIllustration` 모델)
2. `MiniBoardIllustration` 렌더러 13게임 분기
3. 게임 보드 위젯에 `readonly`/`forcedTarget` 추가
4. R0(Sudoku) 컨텐츠 마이그레이션 — **본 문서의 §3 + sudoku 상세 문서 적용**
5. R1(Binairo) 컨텐츠 — R1 PR로 묶음
6. R2 이후는 각 릴리스 PR에서 함께 작업
7. 공통 진입점 (?) 아이콘 + 메인 진입 자동 표시 로직

---

## 9. 합의 필요 항목 (PM → 전문가)

| 결정 항목 | 합의 대상 |
|---|---|
| 단계 수가 5단계를 초과하는 게임(Nonograms/Killer/Skyscrapers/Kakuro)에서 6단계 허용 여부 | GD + UX |
| S6 연습 단계 — 모든 게임에 강제할지 (Minesweeper 안전성 우려) | GD + QA |
| 첫 진입 자동 표시 디폴트 ON | UX + GC (사용자 관점) |
| 메인 화면 ? 아이콘 vs 메뉴 항목 | UX + GC |
| 4언어 동시 작성 vs 한국어 먼저 후 점진 | DEV + PM |

---

## 부록 A. 검수 체크리스트 (STEP 5 QA용)

- [ ] 13게임 모두 §3 매트릭스 단계 수 일치
- [ ] 모든 단계에 미니 일러스트 존재
- [ ] S6 연습 단계 정답 입력 시 펄스 + 햅틱 + 토스트 발동
- [ ] 오답 3회 → "정답 보기" 등장
- [ ] Skip 어디서든 가능
- [ ] motionScale=0에서 즉시 전환
- [ ] textScale=1.6에서 레이아웃 깨지지 않음
- [ ] TalkBack으로 모든 단계 순차 탐색 가능
- [ ] 4언어 모두 작성, 누락 키 없음
- [ ] 색맹: ✓/⚠ 아이콘이 색과 함께 표시
- [ ] 메인 화면 ? 아이콘으로 재진입 가능
- [ ] "다시 보지 않기" 설정 유지
- [ ] 설정 화면에서 "튜토리얼 초기화" 동작
