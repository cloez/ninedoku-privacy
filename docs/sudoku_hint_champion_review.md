# 스도쿠 힌트 시스템 — 챔피언 검토 및 권장안

> 검토자: 25년차 스도쿠 챔피언 (World Sudoku Championship 메달리스트 페르소나)
> 검토 대상: Ninedoku v1.0.1+4 / R0 Sudoku
> 검토 일자: 2026-06-15
> 검토 범위: 9x9 클래식 스도쿠 힌트 시스템에 한정 (13게임 영향 없음)

---

## 종합 진단

### 현재 상태 점수 (10점 만점)

| 차원 | 점수 | 비고 |
|---|---|---|
| 단계 구성 | 6/10 | 4단계 enum 정의는 있으나 단계 간 정보 격차가 모호. Level 1과 Level 3에서 모두 "행/열/박스를 보세요"만 반복. |
| 기법 다양성 | 9/10 | `TechniqueAnalyzer`가 Naked Single → X-Wing까지 8개 기법 감지. 이 부분은 시장 최상위급. |
| 시각 효과 | 2/10 | **치명적**: `HintResult.highlightCells`, `candidates`, `eliminations`를 board widget이 전혀 읽지 않음. 선택 셀만 이동. |
| 텍스트 명료도 | 3/10 | 한국어 하드코딩, 메시지가 생성되지만 **어디에도 표시되지 않음** (SnackBar/Banner/Toast 없음). |
| 학습 가치 | 3/10 | 기법 이름은 알려주지만 시각 강조가 없어 학습 효과 미미. 기법 이름 한국어 라벨만 존재 (`SolvingTechnique.label`). |
| **종합** | **23/50** | 엔진은 챔피언급, 프레젠테이션 계층이 거의 비어있음. |

### 시장 평균 비교

| 앱 | 점수 | 강점 | 약점 |
|---|---|---|---|
| Sudoku.com | 42/50 | 시각 강조 풍부, 기법 배너, 다국어 | 광고 기반 |
| Andoku Sudoku 3 | 40/50 | 기법 학습 모드, 후보 시각화 우수 | UI 다소 올드 |
| Cracking the Cryptic 스타일 | 47/50 | 색깔 코딩, 체인 추적 | 너무 고급자용 |
| **Ninedoku (현재)** | **23/50** | 기법 엔진 완성도 | 프레젠테이션 부재 |
| **Ninedoku (권장안 적용 후 목표)** | **42/50** | 엔진 + 시각 + 다국어 균형 | — |

---

## 1. 현재 구현 분석

### 1.1 단계 구성 (`lib/core/sudoku/hint_engine.dart:5-17`)

4단계 enum이 정의되어 있다.

| Level | enum | 의도 | 실제 산출물 |
|---|---|---|---|
| 1 | `highlightRegion` | 영역 강조 | `highlightCells`에 대상 셀의 행/열/박스 셀 좌표 20개를 담아 반환 (`hint_engine.dart:128-157`) |
| 2 | `showCandidates` | 후보 안내 | `candidates`에 가능 숫자 집합 + "이 셀에 가능한 숫자: [...]" 메시지 (`hint_engine.dart:159-169`) |
| 3 | `explainTechnique` | 기법 설명 | `TechniqueAnalyzer.findNextTechnique`로 기법 탐지 → `technique` + `explanation` 반환 (`hint_engine.dart:171-222`) |
| 4 | `revealAnswer` | 정답 공개 | `answer`만 반환, `_applyRevealHint`가 실제 입력 (`hint_engine.dart:224-233`, `game_notifier.dart:752-788`) |

진행 로직 (`game_notifier.dart:735-750`):
- 같은 셀에 대해 누르면 1→2→3→4로 진행.
- 다른 셀로 선택 변경 시 `clearHintState`로 1단계 리셋.
- 4단계에서만 `hintCount++`, 1~3단계는 등급 영향 없음.

**문제**: 4단계 구조는 좋으나 Level 1과 Level 3의 정보 격차가 작음. Level 1은 사실상 모든 셀이 행/열/박스를 가지므로 "여기 보세요" 외에 정보가 없음.

### 1.2 기법 다양성 (`lib/core/sudoku/technique_analyzer.dart`)

탐지 가능한 기법 (난이도 점수순, `technique_analyzer.dart:19-38`):

| 기법 | 점수 | 탐지 함수 | 상태 |
|---|---|---|---|
| Naked Single | 1 | `_applyNakedSingle` | 완성 |
| Hidden Single | 2 | `_findHiddenSingle` | 완성 (행/열/박스) |
| Naked Pair | 4 | `_findNakedPair` | 완성 (3영역) |
| Pointing Pair | 4 | `_findPointingPair` | 완성 |
| Hidden Pair | 5 | `_findHiddenPair` | 완성 |
| Box/Line Reduction | 5 | `_findBoxLineReduction` | 완성 |
| Naked Triple | 6 | `_findNakedTriple` | 완성 |
| X-Wing | 8 | `_findXWing` | 완성 (행/열 양방향) |

**평가**: 챔피언급 엔진. Sudoku.com 수준과 동등. 빠진 것은 XY-Wing, Swordfish, Coloring (선택 사항).

### 1.3 시각 효과 — **치명적 갭**

`sudoku_board_widget.dart` 전수 검토 결과:

- `lastHintResult`, `hintTargetCell`, `currentHintLevel`을 **단 한 번도 참조하지 않음** (Grep 검증).
- `HintResult.highlightCells`(20개 셀 좌표)는 생성되지만 **읽는 코드가 없음**.
- `HintResult.candidates`(후보 숫자), `eliminations`(소거 후보)도 동일.
- 힌트 사용 시 발생하는 유일한 시각 변화는 `selectedCell`이 `hint.row, hint.col`로 이동하는 것뿐. 기존 셀 선택과 구분 불가.

board widget에서 힌트 관련 상태를 사용하는 부분 (`sudoku_board_widget.dart:81-128`):
```
isSelected = gameState.selectedCell == (row, col)  ← 힌트 후 변경됨
isHighlighted = _isHighlighted(gameState)         ← 선택 셀의 행/열/박스 (힌트와 무관)
```

→ Level 1, 2, 3에서 시각적으로 보이는 변화는 **선택 셀 이동뿐**. 행/열/박스 강조는 일반 선택과 동일한 배경색.

### 1.4 텍스트 — **치명적 갭**

`HintResult.message`에 한국어 설명이 채워지지만:

- `game_screen.dart` 전수 검토 결과 `lastHintResult` 참조 없음.
- SnackBar, MaterialBanner, Tooltip, Dialog, Toast 어디서도 표시 안 함.
- `EncouragementWidget`은 `Encouragement`만 표시 (정답 입력 시 추임새), 힌트와 무관.

→ Level 2 "이 셀에 가능한 숫자: [3,7]" 메시지, Level 3 "행 4에서 7이 들어갈 위치가 여기뿐입니다" 메시지가 **사용자에게 도달하지 않음**.

### 1.5 다국어 — **치명적 갭**

- 모든 힌트 메시지가 `hint_engine.dart`/`technique_analyzer.dart` 내부에 한국어 문자열로 하드코딩.
- `AppStrings`(`app_strings.dart`) 4언어 지원 시스템이 있으나 힌트 키 자체가 없음.
- `SolvingTechnique.label`도 한국어 1개 ('네이키드 싱글' 등, `technique_analyzer.dart:5-12`).

### 1.6 갭 분석 요약

| 갭 | 심각도 | 영향 |
|---|---|---|
| 시각 효과 0% | 🔴 P0 | 사용자가 힌트 사용 결과를 인지 불가 |
| 메시지 표시 0% | 🔴 P0 | 기법 설명이 사용자에게 전달 안 됨 |
| 다국어 0% | 🔴 P0 | 영/일/중 사용자에게 힌트 무용지물 |
| Level 1과 3의 정보 격차 모호 | 🟡 P1 | Level 1 가치 낮음 |
| 4단계만 카운트 — 사용자가 1~3단계 의미 모를 가능성 | 🟡 P1 | UX 혼란 |
| 4단계 정답 입력 시 글로우/사운드 없음 | 🟡 P1 | 만족감 부족 |
| XY-Wing, Swordfish 미지원 | 🟢 P2 | 마스터 난이도 일부 셀 1~2단계로만 안내 |

---

## 2. 챔피언 권장 표준안

### 2.1 4단계 점진적 공개 (재정의)

각 단계의 정보 격차를 명확히 한다.

#### **Level 1: "영역 안내"**

- **목적**: 사용자가 어디를 봐야 할지만 알려주기 (스스로 풀게 유도).
- **현재**: 행/열/박스 모두 강조 (20셀) → 너무 광범위.
- **권장**: 기법별로 가장 관련된 단일 영역만 강조.
  - Naked Single → 대상 셀 단독
  - Hidden Single → 해당 영역(행 OR 열 OR 박스) 9셀
  - Naked/Hidden Pair → 두 셀 + 영역
  - Pointing Pair → 박스 + 표적 행/열
- **시각 사양**:
  - 영역 배경 `#FFF3B0` (라이트) / `#3A3520` (다크), alpha 0.35
  - 200ms ease-in 페이드 인 → 600ms 유지 → 펄스 반복 (2회)
  - 대상 셀 자체는 진한 노랑 `#FFD54F` alpha 0.55 테두리 2px
- **메시지** (배너 상단 1.5초 표시 → 페이드 아웃):
  - ko: "이 박스를 살펴보세요"
  - en: "Look at this box"
  - ja: "このボックスを見てみましょう"
  - zh: "请观察这个九宫格"
- **비용**: hintCount 증가 없음 (학습 친화).

#### **Level 2: "기법 안내"**

- **목적**: 어떤 기법을 적용해야 하는지 이름과 한 줄 설명 제공.
- **현재**: 후보 숫자만 표시.
- **권장**: 기법 이름 배너 + 관련 셀 초록 테두리 + 후보 숫자 셀 내부에 미니 표시.
- **시각 사양**:
  - 관련 셀 테두리 `#10B981` (Emerald 500) 2.5px, alpha 1.0
  - 후보 숫자 배지: 셀 우상단 `#10B981` 배경 흰색 텍스트 fontSize 8sp
  - 기법 이름 배너: 상단 floating chip, 배경 `#1F2937` alpha 0.92, 텍스트 흰색 14sp
- **메시지 샘플** (Hidden Single 예):
  - ko: "히든 싱글 — 이 박스에서 5가 들어갈 자리는 여기 한 곳뿐이에요"
  - en: "Hidden Single — 5 can only go here in this box"
  - ja: "ヒドゥンシングル — このボックスで5が入るのはここだけ"
  - zh: "隐性单选 — 这个九宫格中5只能填在这里"
- **비용**: hintCount += 1 (가벼운 패널티).

#### **Level 3: "이유 설명"**

- **목적**: 왜 그 답이 도출되는지 후보 소거 과정을 시각화.
- **현재**: 텍스트만 (표시도 안 됨).
- **권장**: 소거되는 후보를 빨강 ×표시, 남는 후보를 초록 강조.
- **시각 사양**:
  - 소거 후보 셀: 해당 숫자 위에 빨강 사선 `#EF4444` 2px, 셀 배경 `#FEE2E2` alpha 0.3 (라이트) / `#7F1D1D` alpha 0.3 (다크)
  - 남는 후보: 초록 `#10B981` 굵게 fontWeight 700
  - 대상 셀: 노랑 글로우 boxShadow blur 12 spread 2 color `#FBBF24` alpha 0.6
  - 애니메이션: 소거 → 300ms stagger (왼→오 순차)
- **메시지** (Hidden Single 예):
  - ko: "행 3, 열 5, 같은 박스에 1,2,4,6,8,9가 이미 있으므로 5만 남아요"
  - en: "Row 3, column 5, and this box already contain 1,2,4,6,8,9 — only 5 remains"
  - ja: "行3、列5、このボックスに1,2,4,6,8,9があるので残るのは5だけ"
  - zh: "第3行、第5列、本宫格已含1,2,4,6,8,9，仅剩5可填"
- **비용**: hintCount += 1 (총 2).

#### **Level 4: "정답 공개"**

- **목적**: 자동 입력 + 학습 메시지.
- **현재**: 즉시 setValue, 시각 효과 없음, 사운드만.
- **권장**:
  - 대상 셀 글로우 펄스 `#FBBF24` 800ms (1회)
  - 숫자 입력 애니메이션: scale 0.5 → 1.2 → 1.0, duration 400ms ease-out-back
  - `kHint` 사운드 + 추가로 `kClick` 보조 사운드
  - 기법 이름을 결과 메시지에 포함
- **메시지** (배너 2초):
  - ko: "정답은 5예요 — 히든 싱글 기법으로 풀었어요"
  - en: "Answer is 5 — solved with Hidden Single"
  - ja: "答えは5 — ヒドゥンシングルで解きました"
  - zh: "答案是5 — 使用隐性单选解出"
- **비용**: hintCount += 1 (총 3, 현재와 동일).

### 2.2 풀이 기법 노출 정책

엔진은 이미 8개 기법을 탐지하므로, **표시 정책**만 정의한다.

| 기법 | 표시 (이번 사이클) | 다국어 라벨 키 | 비고 |
|---|---|---|---|
| Naked Single | 필수 | `hint.tech.nakedSingle` | 입문자 노출 |
| Hidden Single | 필수 | `hint.tech.hiddenSingle` | 입문자 노출 |
| Naked Pair | 필수 | `hint.tech.nakedPair` | 보통 이상 노출 |
| Hidden Pair | 필수 | `hint.tech.hiddenPair` | 어려움 이상 |
| Pointing Pair | 필수 | `hint.tech.pointingPair` | 어려움 이상 |
| Box/Line Reduction | 필수 | `hint.tech.boxLineReduction` | 어려움 이상 |
| Naked Triple | 필수 | `hint.tech.nakedTriple` | 전문가 이상 |
| X-Wing | 필수 | `hint.tech.xWing` | 마스터 |
| XY-Wing | 백로그 | — | 다음 사이클 |
| Swordfish | 백로그 | — | 다음 사이클 |

### 2.3 시각 효과 표준 사양 요약

| 항목 | 색상 (Light) | 색상 (Dark) | Duration | Easing |
|---|---|---|---|---|
| 영역 강조 배경 | `#FFF3B0` α0.35 | `#3A3520` α0.35 | 200ms in + 펄스 2회 | ease-in-out |
| 대상 셀 테두리 (L1) | `#FFD54F` α0.55, 2px | `#FFD54F` α0.55, 2px | static | — |
| 관련 셀 테두리 (L2) | `#10B981`, 2.5px | `#34D399`, 2.5px | 250ms in | ease-out |
| 후보 배지 (L2) | bg `#10B981` text white 8sp | bg `#34D399` text `#0F172A` | 250ms in | ease-out |
| 소거 후보 사선 (L3) | `#EF4444`, 2px | `#F87171`, 2px | 300ms stagger | ease-in |
| 대상 셀 글로우 (L3,L4) | `#FBBF24` α0.6 blur12 | `#FBBF24` α0.5 blur12 | 800ms 펄스 | ease-in-out |
| 숫자 입력 (L4) | scale 0.5→1.2→1.0 | 동일 | 400ms | ease-out-back |
| 기법 배너 | bg `#1F2937` α0.92 text white 14sp | bg `#E5E7EB` α0.92 text `#0F172A` | 250ms in / 1500ms 유지 / 250ms out | ease-out |

### 2.4 텍스트 표준 (다국어 4언어 키 정의)

`lib/shared/l10n/app_strings.dart`에 추가할 키:

```
// 힌트 — 단계별 안내
'hint.l1.row'         : "이 행을 살펴보세요" / "Look at this row" / "この行を見てみましょう" / "请观察这一行"
'hint.l1.col'         : "이 열을 살펴보세요" / "Look at this column" / "この列を見てみましょう" / "请观察这一列"
'hint.l1.box'         : "이 박스를 살펴보세요" / "Look at this box" / "このボックスを見てみましょう" / "请观察这个九宫格"
'hint.l1.cell'        : "이 셀에 집중해 보세요" / "Focus on this cell" / "このマスに注目" / "请关注这个格子"

// 기법 라벨
'hint.tech.nakedSingle'      : "네이키드 싱글" / "Naked Single" / "ネイキッドシングル" / "显性单选"
'hint.tech.hiddenSingle'     : "히든 싱글" / "Hidden Single" / "ヒドゥンシングル" / "隐性单选"
'hint.tech.nakedPair'        : "네이키드 페어" / "Naked Pair" / "ネイキッドペア" / "显性数对"
'hint.tech.hiddenPair'       : "히든 페어" / "Hidden Pair" / "ヒドゥンペア" / "隐性数对"
'hint.tech.pointingPair'     : "포인팅 페어" / "Pointing Pair" / "ポインティングペア" / "区块占用"
'hint.tech.boxLineReduction' : "박스/라인 축소" / "Box/Line Reduction" / "ボックス・ライン削減" / "区块行列削减"
'hint.tech.nakedTriple'      : "네이키드 트리플" / "Naked Triple" / "ネイキッドトリプル" / "显性三数组"
'hint.tech.xWing'            : "X-Wing" / "X-Wing" / "Xウィング" / "X翼"

// L2 설명 템플릿 (플레이스홀더 {n}=숫자, {region}=영역명)
'hint.l2.nakedSingle'  : "이 셀에 들어갈 수 있는 숫자가 {n} 하나뿐이에요"
                         "Only {n} can fit in this cell"
                         "このマスに入る数字は{n}だけ"
                         "此格只能填{n}"
'hint.l2.hiddenSingle' : "이 {region}에서 {n}이(가) 들어갈 자리는 여기뿐이에요"
                         "{n} can only go here in this {region}"
                         "この{region}で{n}が入るのはここだけ"
                         "在此{region}中{n}只能填这里"

// L3 이유 설명 (간단 버전)
'hint.l3.eliminated'   : "이미 사용된 숫자를 제외하면 답이 보여요"
                         "Eliminate used numbers and the answer appears"
                         "使用済みの数字を除くと答えが見えます"
                         "排除已用数字后答案显现"

// L4 정답 메시지
'hint.l4.reveal'       : "정답은 {n}이에요 — {tech} 기법으로 풀었어요"
                         "Answer is {n} — solved with {tech}"
                         "答えは{n} — {tech}で解きました"
                         "答案是{n} — 使用{tech}解出"

// 영역명
'hint.region.row'  : "행" / "row" / "行" / "行"
'hint.region.col'  : "열" / "column" / "列" / "列"
'hint.region.box'  : "박스" / "box" / "ボックス" / "九宫格"
```

### 2.5 음향 효과

| 단계 | 사운드 | 비고 |
|---|---|---|
| Level 1 | `kHint` (현재 존재) | 그대로 사용 |
| Level 2 | `kHint` 0.7배 볼륨 | SoundManager.play 두 번째 인자 추가 필요 |
| Level 3 | `kHint` + 짧은 후속 `kClick` 150ms 지연 | 정보 노출 강화 |
| Level 4 | `kHint` + `kLineComplete` (작은 버전) 300ms 지연 | 만족감 강화 |

### 2.6 hintCount 정책 변경 제안

현재: 4단계만 +1.
권장: Level 2 +1, Level 3 +1, Level 4 +1 (총 3). Level 1 무료 (학습 친화).

→ `Grade.evaluate`의 임계값(`game_state.dart:97-114`)은 그대로 유지. 현재 Beginner~Medium은 hint 1까지 A. 권장안 적용 시 Level 1 무료라 사용자가 영역만 확인하고 스스로 푸는 경로가 가능해짐.

---

## 3. 우선순위 매트릭스

### 🔴 P0 — 필수 (이번 사이클)

1. **board widget이 `lastHintResult`를 구독하여 시각 효과 렌더링**
   - `sudoku_board_widget.dart`의 `_CellWidget`에서 `hintTargetCell`, `lastHintResult.highlightCells`, `candidates`, `eliminations`, `level` 모두 활용.
2. **힌트 메시지 표시 위젯 신설** (`HintBannerWidget`)
   - `game_screen.dart`의 Stack 상단(EncouragementWidget 옆)에 배치.
   - `lastHintResult.message` 표시, 자동 페이드 아웃.
3. **다국어 키 추가** (`app_strings.dart` 4언어 × 약 25키)
4. **`hint_engine.dart`/`technique_analyzer.dart`의 메시지를 키 기반으로 리팩터링**
   - `explanation` 필드에 한국어 하드코딩 대신 `MessageKey + params` 구조 제안. `HintResult.messageKey: String`, `messageParams: Map<String, String>` 추가.
   - 또는 호출부(`HintBannerWidget`)에서 `technique`, `value`, `eliminations`를 받아 `AppStrings.get`으로 조립.
5. **Naked Single, Hidden Single 시각 효과 완성** (가장 빈번한 2개 기법)

### 🟡 P1 — 권장 (다음 사이클)

6. Naked Pair, Hidden Pair, Pointing Pair, Box/Line Reduction 시각 효과
7. Naked Triple, X-Wing 시각 효과 + 기법 배너 폴리시
8. L4 글로우 + 숫자 scale 애니메이션
9. hintCount 정책 변경 (L1 무료) — 합의 후 적용

### 🟢 P2 — 백로그

10. XY-Wing, Swordfish, Coloring 엔진 확장
11. 학습 모드 — 풀이 과정 단계별 진행 보기
12. 기법 통계 — "이번 게임에서 사용한 기법" 결과 화면 표시

---

## 4. 위험 관리

| 위험 | 대응 |
|---|---|
| 너무 많은 색상이 한 번에 표시되어 사용자 압도 | Level별로 정보 누적이 아닌 **교체**. L3 진입 시 L2 배지 제거. |
| 모션 감소 모드 사용자 | `motionScale` 글로벌 설정(이미 존재)을 시각 효과 duration에 곱하여 0배율 시 즉시 표시. |
| 다크 모드 색상 명도 부족 | 위 색상표는 light/dark 분리 정의됨. QA에서 contrast 4.5:1 검증. |
| 작은 폰트의 후보 배지 가독성 | 8sp 최소, 화면 폭 < 360px 시 7sp 폴백 + FittedBox. |
| 기법 메시지가 한국어보다 길어지는 영/중 번역 | 배너 maxLines: 2, ellipsis 처리. |
| 기존 사용자 학습 곡선 단절 | Level 1을 무료화하더라도 기존 카운트 의미는 유지(L2~L4). 등급 임계값 변경 없음. |
| 13개 다른 게임 영향 | 본 권장안의 모든 변경은 `lib/core/sudoku/`, `lib/features/game/`에 한정. 13게임 영향 0. |

---

## 5. 답변 필요 질문 (사용자/PM/GD/UX 합의 필요)

1. **hintCount 정책 변경**: Level 1을 무료(hintCount += 0)로 할지? 현재 Level 4만 +1 → 권장 L2,L3,L4 각 +1.
   - GD 의견 필요: 등급 산정에 영향.
2. **배지/카테고리**: "기법 마스터" 같은 신규 배지 추가? (예: X-Wing 힌트 없이 마스터 난이도 클리어)
   - 백로그로 두고 다음 사이클 결정 권장.
3. **사용자가 힌트를 두 번 연속 누르면**: 같은 셀 Level 진행 vs 새 셀로 이동? 현재는 같은 셀 진행. 권장: 유지.
4. **Level 1 메시지가 표시되는 동안 사용자가 셀을 탭하면**: 힌트 취소 vs 유지? 현재 `clearHintState` 즉시 호출. 권장: 유지하되 진행 단계는 0으로 리셋(현 동작).
5. **도전 모드**: 현재 `isHintDisabled`로 힌트 완전 차단. 권장안 적용 후에도 동일.

---

## 6. 구현 체크리스트 (DEV 인계용)

P0 작업 분해:

- [ ] `HintResult` 확장: `messageKey`, `messageParams`, `eliminationCells` (좌표+숫자) 필드 추가 → `lib/core/sudoku/hint_engine.dart`
- [ ] `TechniqueResult`에서 직접 메시지 키 매핑 (기법별) → `lib/core/sudoku/technique_analyzer.dart`
- [ ] `app_strings.dart` 4언어 × 약 25키 추가
- [ ] `SudokuBoardWidget._CellWidget`에서 hint 상태 구독 → `lib/features/game/widgets/sudoku_board_widget.dart`
  - L1: `highlightCells` 영역 배경
  - L2: 관련 셀 초록 테두리 + 후보 배지
  - L3: `eliminationCells` 빨강 사선
  - L4: 글로우 + scale 애니
- [ ] `HintBannerWidget` 신설 → `lib/features/game/widgets/hint_banner_widget.dart`
- [ ] `game_screen.dart`의 Stack에 `HintBannerWidget` 추가
- [ ] `_getNextHintLevel` 로직은 그대로 유지
- [ ] `useHint`의 `hintCount` 증가 로직 합의 후 분기 적용
- [ ] 테스트: `test/features/game/hint_test.dart`에 L1~L4 단위 테스트 + 시각 상태 위젯 테스트 (목표 +15 테스트)
- [ ] `test/GAME_QA_CHECKLIST.md` 섹션 F (UX 수동 검증)에 4단계 시각 확인 항목 추가

---

## 부록 A. 기법별 메시지 샘플 (L2 기준, 4언어 전체)

### Naked Pair
- ko: "네이키드 페어 — 이 두 셀이 {n1},{n2}만 가능하므로 같은 영역의 다른 셀에서 {n1},{n2}를 지울 수 있어요"
- en: "Naked Pair — these two cells can only be {n1} or {n2}, so remove {n1},{n2} from the rest of this region"
- ja: "ネイキッドペア — この2マスは{n1}か{n2}しか入らないため、同じ領域の他のマスから消去できます"
- zh: "显性数对 — 此两格只能填{n1}或{n2}，可从同区域其它格中删除"

### Pointing Pair
- ko: "포인팅 페어 — 이 박스에서 {n}이(가) 한 {region}에만 있으므로 그 {region}의 박스 바깥에서 {n}을 지울 수 있어요"
- en: "Pointing Pair — {n} is confined to one {region} in this box, so remove {n} from that {region} outside the box"
- ja: "ポインティングペア — このボックスで{n}が1つの{region}にしかないため、その{region}のボックス外から消去できます"
- zh: "区块占用 — 此宫格中{n}仅在一{region}上，可从该{region}的宫外删除"

### X-Wing
- ko: "X-Wing — {n}이(가) 두 행에서 같은 두 열에만 있어 그 두 열의 다른 행에서 {n}을 지울 수 있어요"
- en: "X-Wing — {n} sits in the same two columns across two rows, so remove {n} from those columns elsewhere"
- ja: "Xウィング — {n}が2行で同じ2列にあるため、その2列の他の行から消去できます"
- zh: "X翼 — {n}在两行中位于相同两列，可从该两列其它行删除"

---

## 최종 평가

엔진은 **이미 챔피언급**이다. 8개 기법 탐지, 셀 단위 기법 추적, 난이도 평가까지 시장 최상위 앱과 동등하다. 그러나 **프레젠테이션 계층이 비어 있어** 사용자는 이 챔피언 엔진을 전혀 체감할 수 없다. 현재 사용자가 보는 힌트는 "선택 셀이 이동하고 4단계에서 숫자가 입력되는" 것이 전부다.

P0 작업 5개만 완료해도 종합 점수 23 → 38로 도약 가능하며, P1까지 마치면 42 수준으로 Sudoku.com과 어깨를 나란히 할 수 있다. 가장 큰 ROI는 **메시지 키 시스템 + Banner 위젯 + L1/L2 시각 효과** 세 가지에 있다.
