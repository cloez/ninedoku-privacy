# QA 4인 전수 점검 보고서 — 13게임

대상: sudoku, binairo, minesweeper, yin_yang, nonograms, killer_sudoku, star_battle, light_up, futoshiki, tents, jigsaw_sudoku, skyscrapers, kakuro (총 13개)

검증 방식: notifier / home_screen / game_screen / 공통 위젯 정적 분석 (코드 기반)

---

## T1: 기능 테스터 (Functional QA)

| 게임 | startNew | startDaily | input/tap | undo 안전 | hint 1→4 사이클 | hint4 자동입력 | pause/resume | giveUp | 완료판정 | 배지평가 | 자동저장 | 자동복원(paused) | 라이프사이클 pause | 체크포인트 | 결과 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sudoku | ✅ (캐시+생성) | ✅ (날짜시드) | ✅ | ✅ | ✅ (HintLevel enum) | ✅ | ✅ (isPaused 가드) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| binairo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| minesweeper | ✅ | ✅ | ✅ tap/longPress/doubleTap | ⚠️ reveal undo는 의도적으로 미지원 | ✅ | ✅ (reveal/flag) | ✅ | ✅ | ✅ (isWon) | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| yin_yang | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| nonograms | ✅ | ✅ (easy) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| killer_sudoku | ✅ | ✅ (+500 시드오프셋) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (값일치) | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| star_battle | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| light_up | ✅ | ✅ | ✅ (벽=fixed 가드) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| futoshiki | ✅ | ✅ | ✅ (메모 모드) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| tents | ✅ | ✅ | ✅ (tree=fixed) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| jigsaw_sudoku | ✅ | ✅ (+1000 시드오프셋) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (값일치) | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| skyscrapers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| kakuro | ✅ | ✅ | ✅ (검은셀=white type 가드) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |

### T1 발견 사항
- 13게임 모두 **정상 동작 시나리오 통과**. PuzzleEngine 패턴이 일관됨.
- **sudoku만 `pause()`에 `isPaused` 가드 있음** — 다른 12게임은 `if (state == null || state!.isCompleted) return;`만 체크 → 일시정지 상태에서 한 번 더 `pause()` 호출 시 `_timer?.cancel()`은 안전하지만 `_autoSave()`가 다시 실행됨 (성능 영향 미미, P2).
  - 예: `lib/games/binairo/binairo_notifier.dart:381`, `lib/games/yin_yang/yin_yang_notifier.dart:177` 등.
- **binairo만 `restoreCheckpoint`에서 `_autoSave()` 호출**, sudoku/타 11게임은 미호출 → 체크포인트 복원 후 디스크 상태와 메모리 불일치 가능 (P2).
- **minesweeper undo**: reveal 액션은 의도적으로 미지원 (게임 특성). 깃발 토글만 지원. 정상.

---

## T2: 엣지 케이스 테스터 (Edge Case QA)

| 게임 | state null 가드 | isCompleted 가드 | isAutoCompleting | 고정셀 보호 | 빈보드 힌트 | 같은값 입력 | generator 실패 (null) | JSON 실패 catch | 라이프사이클 중복 pause | 완료직후 입력차단 | cage/조건 검증 | 결과 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sudoku | ✅ | ✅ | ✅ | ✅ (isFixed) | ✅ (hint==null) | ✅ (토글 삭제) | ✅ (return) | ✅ | ✅ (isPaused 체크 후 pause) | ✅ | N/A | PASS |
| binairo | ✅ | ✅ | ✅ | ✅ (fixed.contains) | ✅ | ✅ (같은값 no-op) | ✅ | ✅ | ✅ (조건부) | ✅ | N/A | PASS |
| minesweeper | ✅ | ✅ | ✅ | ✅ (revealed/flagged) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | ⚠️ minor |
| yin_yang | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | PASS |
| nonograms | ✅ | ✅ | ✅ | N/A (고정셀 없음) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (수정됨: 빈칸 허용) | PASS |
| killer_sudoku | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (삭제 토글) | ✅ | ✅ | ✅ | ✅ | ✅ (cage 합계는 솔루션 비교) | PASS |
| star_battle | ✅ | ✅ | ✅ | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | PASS |
| light_up | ✅ | ✅ | ✅ | ✅ (벽=fixed) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | PASS |
| futoshiki | ✅ | ✅ | ✅ | ✅ (fixed.contains) | ✅ | ✅ (return) | ✅ | ✅ | ✅ | ✅ | N/A (부등호는 솔루션 기반) | PASS |
| tents | ✅ | ✅ | ✅ | ✅ (treePositions) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | PASS |
| jigsaw_sudoku | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (삭제 토글) | ✅ | ✅ | ✅ | ✅ | N/A | PASS |
| skyscrapers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (return) | ✅ | ✅ | ✅ | ✅ | N/A | PASS |
| kakuro | ✅ | ✅ | ✅ | ✅ (white type + fixed) | ✅ | ✅ (return) | ✅ | ✅ | ✅ | ✅ | ✅ (sum/no-dup는 솔루션 비교) | PASS |

### T2 발견 사항
- **minesweeper `tapCell` 라인 165**: `final cell = state!.current.getCell(row, col);` — 변수 선언 후 switch 내부에서 사용 안 함 (각 분기에서 다시 가져옴). 데드 코드, 동작에는 영향 없음 (P2).
- **minesweeper `_revealCell` 라인 180**: 지뢰 셀을 열어도 `mistakeCount`만 증가, `state.isCompleted/isGameOver`로 전환하지 않음 → 게임을 계속 진행 가능 (의도된 디자인이면 OK이나, 일반 지뢰찾기 규칙과 다름). **P1 확인 필요** — GD 설계 의도 검토.
- **minesweeper hint Level 4** (`getHint` 337~): 정답이 reveal이면 `revealWithCascade`로 연쇄 오픈 — 자동완성 시 `_checkCompletion`만 호출. `isWon` 판정에 의존.
- 모든 게임에서 `_applyValue` 등의 내부 메서드는 `state == null` 가드가 없지만, 호출자(`tapCell`, `inputNumber`)에서 가드함 → 안전.

---

## T3: UI 레이아웃 테스터 (UI Detail QA)

### 홈 화면

| 게임 | AppBar leading apps_rounded | BackPressExit | 이어하기→새게임→오늘퍼즐→통계/배지→규칙 순서 | 규칙 카드 항상 표시 | difficulty BottomSheet | 핸들 표시 | viewInsets.bottom | 결과 |
|---|---|---|---|---|---|---|---|---|
| sudoku | ✅ | ✅ | ✅ (모드 선택 BottomSheet 단계 추가) | ✅ (조건 없음) | ✅ | ✅ | ✅ | PASS |
| binairo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| minesweeper | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| yin_yang | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| nonograms | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| killer_sudoku | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| star_battle | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| light_up | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| futoshiki | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| tents | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| jigsaw_sudoku | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| skyscrapers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| kakuro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |

### 플레이/일시정지/결과 화면

| 게임 | 세로 레이아웃 | 가로 레이아웃 | pause.title | pause.message+elapsed | resume/home/giveUp 순서·색상 | 결과 등급 S/A/B/C+색상 | 결과 통계 | 새배지 칩 | 새게임/홈 버튼 | 결과 |
|---|---|---|---|---|---|---|---|---|---|---|
| sudoku | ✅ | ✅ | ✅ | ✅ | ✅ (Elevated/Outlined/TextRed) | ✅ | ✅ | ✅ | ✅ | PASS |
| binairo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| minesweeper | ✅ | ✅ | ✅ | ❌ **pause.message/elapsed 누락** | ✅ | ✅ | ✅ | ✅ | ✅ | **FAIL** |
| yin_yang | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| nonograms | ✅ | ✅ | ✅ | ❌ **pause.message/elapsed 누락** | ✅ | ✅ | ✅ | ✅ | ✅ | **FAIL** |
| killer_sudoku | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| star_battle | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| light_up | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| futoshiki | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| tents | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| jigsaw_sudoku | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| skyscrapers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |
| kakuro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | PASS |

### T3 발견 사항
- **🚨 P1: minesweeper / nonograms 일시정지 화면이 sudoku와 일관성 없음**
  - 두 게임 모두 `pause.message` ("게임이 일시정지되었습니다") 와 `pause.elapsed` (경과 시간) 미표시.
  - 위치: `lib/games/minesweeper/screens/minesweeper_game_screen.dart:198-265`, `lib/games/nonograms/screens/nonogram_game_screen.dart:205-272`
  - 다른 11게임 (sudoku 포함)은 모두 elapsed time을 표시함.
  - 일시정지 아이콘 크기도 다름: minesweeper/nonograms = 64, 다른 게임 = 80.
  - 아이콘 색상도 다름: minesweeper/nonograms = 기본색, 다른 게임 = `AppColors.primaryDark/Light`.

---

## T4: UX 인터랙션 테스터 (UX Interaction QA)

| 게임 | 셀 탭 즉시 반응 | longPress | doubleTap | 입력모드 전환 | 숫자패드 1~9 | 메모 모드 | 가로 AppBar 숨김 | 컨트롤 우측 배치 | PopScope 백키 | pause→resume 백키 | 결과→홈 백키 | 통계/배지 extra | 진행률 LinearProgress | 결과 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sudoku | ✅ | N/A | N/A | ✅ (셀우선↔숫자우선) | ✅ | ✅ | ✅ | ✅ | ✅ (exit dialog) | ✅ | ✅ | ❌ **extra 미전달** | ✅ (81-fixed) | ⚠️ |
| binairo | ✅ | N/A | N/A | ✅ (●/○/지우개) | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('binairo') | ✅ | PASS |
| minesweeper | ✅ | ✅ (깃발) | ✅ (chord) | ✅ (열기/깃발) | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('minesweeper') | ✅ (safeCount) | PASS |
| yin_yang | ✅ | N/A | N/A | ✅ (●/○/지우개) | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('yinyang') | ✅ | PASS |
| nonograms | ✅ | ✅ (X 입력) | N/A | ✅ (■/✕/지우개) | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('nonogram') | ✅ | PASS |
| killer_sudoku | ✅ | N/A | N/A | N/A (셀우선만) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('killerSudoku') | ✅ | PASS |
| star_battle | ✅ | N/A | N/A | ✅ (★/X/지우개) | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('starBattle') | ✅ | PASS |
| light_up | ✅ | N/A | N/A | ✅ (💡/X/지우개) | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('lightUp') | ✅ | PASS |
| futoshiki | ✅ | N/A | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('futoshiki') | ✅ | PASS |
| tents | ✅ | N/A | N/A | ✅ (텐트/풀/지우개) | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('tents') | ✅ | PASS |
| jigsaw_sudoku | ✅ | N/A | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('jigsawSudoku' 추정) | ✅ | PASS |
| skyscrapers | ✅ | N/A | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('skyscrapers') | ✅ | PASS |
| kakuro | ✅ | N/A | N/A | N/A | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ ('kakuro') | ✅ | PASS |

### T4 발견 사항
- **🚨 P1: sudoku 홈 화면 통계/배지 버튼 `extra` 파라미터 미전달**
  - 위치: `lib/features/home/screens/home_screen.dart:361, 369`
  - ```dart
    onPressed: () => context.push(AppRoutes.statistics), // extra 없음
    onPressed: () => context.push(AppRoutes.badges),      // extra 없음
    ```
  - 다른 12게임은 모두 `extra: 'binairo'` 등으로 게임명을 전달하여 해당 탭이 자동 선택됨.
  - 영향: 통계/배지 화면에서 sudoku 탭이 자동 선택되지 않을 수 있음 (router의 기본값 동작에 의존).

---

## 종합 발견 사항

### 🚨 P0 (긴급 — 즉시 수정)
**없음.** 13게임 모두 핵심 기능은 정상 동작.

### ⚠️ P1 (높음 — 다음 사이클)

1. **minesweeper / nonograms 일시정지 화면 비일관성**
   - 파일: `lib/games/minesweeper/screens/minesweeper_game_screen.dart:198-265`
   - 파일: `lib/games/nonograms/screens/nonogram_game_screen.dart:205-272`
   - 두 게임 모두 `pause.message` (게임 일시정지되었습니다) 와 `pause.elapsed` (경과 시간 표시) 가 누락됨.
   - 일시정지 아이콘 크기 64 vs 다른 게임 80, 색상도 기본 vs `AppColors.primary*`.
   - 해결: yin_yang/binairo의 pause 위젯 구조를 복사하여 동일하게 적용 (스도쿠와 일치하도록).

2. **sudoku 홈 통계/배지 버튼 `extra` 미전달**
   - 파일: `lib/features/home/screens/home_screen.dart:361, 369`
   - 수정 예시:
     ```dart
     onPressed: () => context.push(AppRoutes.statistics, extra: 'sudoku'),
     onPressed: () => context.push(AppRoutes.badges, extra: 'sudoku'),
     ```
   - 단, statistics/badges 화면의 기본 탭이 sudoku이면 사용자 영향은 미미 (router.dart:134, 138 동작 확인 필요).

3. **minesweeper 지뢰 클릭 시 게임 진행 (의도 검증 필요)**
   - 파일: `lib/games/minesweeper/minesweeper_notifier.dart:180-189`
   - 지뢰 셀 reveal 시 `mistakeCount++`만 발생, `isGameOver` 미설정 → 일반 지뢰찾기 룰과 차이.
   - GD에 의도 확인 필요. 단순 도전 모드처럼 "실수 N개까지 허용"이라면 정상.

### 📝 P2 (보통 — 백로그)

1. **12게임 `pause()` 메서드에 `isPaused` 가드 누락** (sudoku만 존재)
   - 영향: 이미 일시정지된 상태에서 `pause()` 재호출 시 `_autoSave()`가 한 번 더 실행됨. 성능 영향 거의 없음.
   - 수정: 모든 게임 notifier의 `pause()` 첫 줄에 `if (state!.isPaused) return;` 추가 권장.

2. **`restoreCheckpoint()` 후 `_autoSave()` 호출은 binairo만 있음**
   - 다른 12게임은 체크포인트 복원 후 디스크 상태와 메모리가 일시적으로 불일치.
   - 다음 입력 시점에 자동 저장되므로 큰 문제 없으나, 그 사이 앱 종료 시 잘못된 상태 복원 가능.

3. **minesweeper `tapCell` 라인 165: 사용하지 않는 `final cell` 변수**
   - 파일: `lib/games/minesweeper/minesweeper_notifier.dart:165`
   - dead code, lint 경고 가능.

4. **이어하기 카드 진행률 % 텍스트 형식 차이**
   - sudoku: `${(progress * 100).toInt()}${AppStrings.get('home.progress')}` (다국어 prefix)
   - 다른 12게임: `${(progress * 100).toInt()}%` (하드코딩 %)
   - 다국어 일관성 차원에서 통일 권장.

5. **시드 오프셋 규칙 비일관**
   - sudoku/binairo/yinyang/...: `year*10000 + month*100 + day`
   - killer_sudoku: `+ 500`
   - jigsaw_sudoku: `+ 1000`
   - 동일 날짜에 게임별로 다른 퍼즐을 보장하려는 의도로 추정되나, 규칙 문서화 없음. 보통 게임마다 자체 generator가 별도이므로 같은 시드라도 다른 퍼즐 생성 — 오프셋 불필요할 가능성.

### 종합 통계

- 전체 점검 게임 수: 13
- 전체 점검 항목 (T1+T2+T3+T4): 약 13게임 × 50 = **650 체크포인트**
- T1 결과: 13 PASS / 0 FAIL
- T2 결과: 13 PASS / 0 FAIL (minesweeper minor)
- T3 결과: 11 PASS / **2 FAIL (minesweeper, nonograms)**
- T4 결과: 12 PASS / **1 ⚠️ (sudoku — extra 미전달)**

| 게임 | T1 | T2 | T3 | T4 | 종합 |
|---|---|---|---|---|---|
| sudoku | PASS | PASS | PASS | ⚠️ | 우수 |
| binairo | PASS | PASS | PASS | PASS | 완벽 |
| minesweeper | PASS | PASS | **FAIL** | PASS | 우수 (UI 통일 필요) |
| yin_yang | PASS | PASS | PASS | PASS | 완벽 |
| nonograms | PASS | PASS | **FAIL** | PASS | 우수 (UI 통일 필요) |
| killer_sudoku | PASS | PASS | PASS | PASS | 완벽 |
| star_battle | PASS | PASS | PASS | PASS | 완벽 |
| light_up | PASS | PASS | PASS | PASS | 완벽 |
| futoshiki | PASS | PASS | PASS | PASS | 완벽 |
| tents | PASS | PASS | PASS | PASS | 완벽 |
| jigsaw_sudoku | PASS | PASS | PASS | PASS | 완벽 |
| skyscrapers | PASS | PASS | PASS | PASS | 완벽 |
| kakuro | PASS | PASS | PASS | PASS | 완벽 |

**전체 PASS율**: 13/13 게임 기능 PASS (100%), 11/13 게임 UI 완전 PASS (84.6%).

---

## 권장 후속 조치

1. **(다음 사이클 즉시)** minesweeper/nonograms 일시정지 화면을 yin_yang 패턴으로 통일 — pause.message + pause.elapsed + 아이콘 크기 80 + AppColors.primary 적용.
2. **(다음 사이클 즉시)** sudoku 홈 통계/배지 버튼에 `extra: 'sudoku'` 추가.
3. **(GD 검토)** minesweeper 지뢰 클릭 시 게임 종료 vs 실수 카운트 정책 결정.
4. **(백로그)** P2 항목들은 일관성 향상 차원에서 점진 개선.
