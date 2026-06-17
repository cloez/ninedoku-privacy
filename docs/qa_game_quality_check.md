# 게임전문 QA 품질 점검 보고서

> 검증 대상: 유일해 보장 강화 4건 (killer_sudoku / yin_yang / tents / nonograms)
> 검증 방식: 정적 분석 + 단위 테스트(193개) + 성능 측정(시드 1~5) + UI/UX 영향 분석 + 백워드 호환
> 검증일: 2026-06-05
> 검증자: QA 에이전트

---

## A. 코드 품질

| 항목 | killer_sudoku | yin_yang | tents | nonograms |
|------|--------------|----------|-------|-----------|
| 기획서 준수 | ⚠ 부분 | ⚠ 부분 | OK | OK |
| 백워드 호환 | OK | OK (완료기록만) | OK (완료기록만) | OK |
| 일관성(state/gen/UI) | OK | OK (state.gridSize→16 반영) | OK (state.gridSize→12 반영) | OK |

상세:
- **killer_sudoku**: 기획서는 "두 번째 해 발견 즉시 폐기 후 재시도"라고 명시하나, 실제 구현은 5회 시도 후 실패해도 마지막 후보를 그대로 사용(`bestCells fallback`). medium/hard/master는 hintCount=0이라 빈 보드에서 `countSolutions` 호출이 매우 느려 첫 시도만 검증 후 break됨 → 결과적으로 검증 효과 제한.
- **yin_yang**: generator(`size <= 16` 가드)가 `hasUniqueSolution` 대신 `YinYangSolver.solve()`(첫 해)와 원본 비교만 수행 (130~144행). 두 번째 해 존재 여부를 명시 확인하지 않음. 게다가 `hasUniqueSolution` 자체가 `count`를 값 전달로 사용해 재귀 누적이 깨질 가능성이 있음 (yin_yang_solver.dart 161~165).
- **tents**: `TentsSolver.countSolutions(limit:2)` 사용 — 기획서 부합.
- **nonograms**: `NonogramSolver.countSolutions(maxCount:2)` 신규 추가, generator(line 76)에서 == 1만 통과 — 기획서 부합.

호환성:
- yin_yang/tents의 master 크기 축소는 storage_service의 완료기록(`CompletedGameRecord`)만 저장하는 구조라 SharedPreferences 호환에 영향 없음. 진행 중 게임 board state는 저장하지 않으므로 기존 사용자 데이터 손상 없음.

## B. 단위 테스트
- 명령: `flutter test test/games/killer_sudoku test/games/yin_yang test/games/tents test/games/nonograms`
- **결과: 193개 PASS / 0개 FAIL — All tests passed!**
- killer_sudoku에 신규 테스트 "유일해 생성된 beginner 퍼즐은 (힌트+케이지)로 유일해", "countSolutions API 동작" 포함.

## C. 정적 분석
- 명령: `flutter analyze lib/games/killer_sudoku lib/games/yin_yang lib/games/tents lib/games/nonograms`
- 결과: **에러 0건**, info/warning 12건 (모두 기존 코드의 사소한 미사용 변수/스타일 — 이번 변경과 무관).
  - unused_field/element: badge popup 관련 미사용 코드 (nonograms, tents, yin_yang screens)
  - unnecessary_brace_in_string_interp, prefer_final_fields 등 lint info

## D. 생성 성능 (시드 1~5 평균, 환경: 윈도우 dart run)

| 게임 | 난이도(size) | 평균 시간 | 최대 시간 | 3초 이내? | 결과 |
|------|-------------|----------|----------|----------|------|
| killer_sudoku | beginner | 5ms | 24ms | OK | 5/5 |
| killer_sudoku | easy | 5ms | 11ms | OK | 5/5 |
| killer_sudoku | medium | **6,357ms** | **20,235ms** | ❌ | 5/5 |
| killer_sudoku | hard | **5,030ms** | **8,245ms** | ❌ | 5/5 |
| killer_sudoku | **master** | **273,932ms** | **737,529ms** | ❌ 치명적 | 5/5 |
| yin_yang | beginner(5) | 14ms | 45ms | OK | 5/5 |
| yin_yang | easy(7) | 1,383ms | 2,136ms | ⚠ 경계 | 5/5 |
| yin_yang | medium(10)/hard(13)/master(16) | 측정 시 응답 없음 | — | ❌ 추정 미달 | — |
| tents | beginner~hard(12) | 2~39ms | 5~152ms | OK | 20/20 |
| tents | master(12) | 115ms | 295ms | OK | 5/5 |
| nonograms | beginner(5) | 0ms | 4ms | OK | 5/5 |
| nonograms | easy(10) | 2ms | 7ms | OK | 5/5 |
| nonograms | medium(15) | 878ms | 2,498ms | ⚠ 경계 | 5/5 |
| nonograms | hard(20) seed=1 | **956,732ms** | 동일 | ❌ 치명적 | **FAIL(null)** |

> 비고: killer_sudoku master는 평균 **약 274초**(최악 12분) — 사실상 사용 불가. 게임 자체는 `_timeoutMs=3000` 내부 가드가 있어 fallback으로 빠지지만, 그 결과 첫 시도 케이지만 사용되어 유일해 보장 효과가 사라짐.
> yin_yang/tents는 코드상 자체 `timeout=3초` 가드가 있어 실기기에서 3초 내 폴백되지만, 폴백 시 유일해 미검증 케이스가 남을 수 있음.

## E. 유일해 검증 실효성

- **killer_sudoku**: 신규 테스트 "beginner 퍼즐의 countSolutions==1" 1건 PASS 확인. 그러나 medium/hard/master(hintCount=0)는 빈 보드 검증이 너무 무거워 첫 후보 시도 한 번만 한 뒤 timeout으로 fallback 반환 → **유일해 보장 거의 미동작**.
- **yin_yang**: generator가 `hasUniqueSolution`이 아닌 `solve()` 단일 해 + 원본 비교만 함 — 다른 해 존재 여부 미확인. 동시에 `hasUniqueSolution` 함수 자체가 `count` 값 전달 패턴 결함 가능. **유일해 검증 실효성 미흡**.
- **tents**: solver의 `countSolutions(limit:2) == 1` 정상. **실효성 OK**.
- **nonograms**: `NonogramSolver.countSolutions(maxCount:2)` 신규, generator에서 `== 1` 보장. **실효성 OK** (단, hard 사이즈 20은 3초 미달 가능).

## F. UI/UX 영향

- "20×20" 문자열 grep: yin_yang에는 없음 (badge 문구는 binairo/nonograms 별개). master=16 변경 영향 0건.
- "14×14" 문자열 grep: tents에는 없음 (binairo만 14). master=12 변경 영향 0건.
- 사이즈 표시는 모두 `${state.size}x${state.size}` 동적 출력 (yin_yang_game_screen, yin_yang_home_screen, tents_game_screen, tents_home_screen) — master 축소가 자동 반영됨.
- BottomSheet 난이도 선택은 `difficulty.gridSize` 동적 사용 — 자동 동기화 OK.

## G. 기존 진행 게임 호환

- yin_yang_storage_service / tents_storage_service는 `CompletedGameRecord` 리스트만 SharedPreferences에 저장.
- master 크기 변경(20→16, 14→12)은 신규 게임 생성 시점에만 영향. 과거에 저장된 완료 기록의 `size` 필드는 그대로 유지되므로 통계/배지 화면 정상 표시.
- 진행 중 게임 board state는 저장하지 않는 구조라 호환성 문제 없음.

---

## 종합 판정

판정: **🔴 FAIL**

사유:
1. **killer_sudoku master 평균 274초 / 최악 12분** — 기획서 비기능 요구사항 "3초 이내" 심각 위반, 사용자가 사실상 master 난이도 시작 불가.
2. **killer_sudoku medium/hard도 평균 5~6초** — 3초 초과.
3. **nonograms hard(20) seed=1에서 956초 후 null 반환** — 사용자가 hard 시작 시 약 16분 후 실패. 치명적.
4. **yin_yang generator의 유일해 검증이 단일 해 + 원본 비교**라서 두 번째 해 존재 가능성을 확인하지 않음. 기획서의 "모든 사이즈에서 유일해 검증 활성화" 실효성 미흡.
5. yin_yang `hasUniqueSolution`의 `count` 값 전달 패턴은 재귀 누적이 깨질 수 있어 정상 동작 여부 의심 (해당 함수가 generator에서 미사용이라 즉각 영향은 없으나, 사용 시 오동작 위험).

→ **STEP 3(DEV)로 반려.**

권장 작업:
- killer_sudoku: hintCount=0인 medium/hard/master에서 빈 보드 `countSolutions` 호출 비활성화 또는 제한(예: 케이지 분할 후 일부 셀을 임시 고정으로 노출하여 검증 비용 절감). 또는 master 난이도 자체를 hint 제공 형태로 변경.
- yin_yang: generator의 `solve()` 비교를 `_countSolutions(... limit=2) == 1` 호출로 교체. 동시에 `hasUniqueSolution`의 closure 패턴 수정(전역 카운터 객체 또는 `[count]` 1-원소 리스트 사용).

---

## 발견 사항

| # | 심각도 | 항목 | 위치 | 권고 |
|---|--------|------|------|------|
| 1 | 🔴 P0 | killer_sudoku master 생성 평균 274s | lib/games/killer_sudoku/engine/killer_sudoku_generator.dart 56~103 | hint 없는 난이도에서 빈 보드 검증 비용 폭증. fallback이 발동하지만 그 경우 유일해 미보장. 검증 알고리즘 재설계 필요. |
| 2 | 🔴 P0 | killer_sudoku medium/hard 평균 5~6s | 동상 | 3초 비기능 요구사항 위반 |
| 3 | 🟠 P1 | yin_yang generator의 유일해 검증이 single-solve 비교 | lib/games/yin_yang/engine/yin_yang_generator.dart 131~145 | `_countSolutions` 기반의 `count==1` 체크로 변경 |
| 4 | 🟠 P1 | yin_yang `hasUniqueSolution` closure 누적 결함 가능 | lib/games/yin_yang/engine/yin_yang_solver.dart 161~194 | `int count`를 캡처 가능한 객체로 변경 |
| 5 | 🔴 P0 | nonograms hard(20) seed=1: 956초 후 null 반환 | lib/games/nonograms/engine/nonogram_generator.dart | timeout=3s 가드가 있으나 50 attempts × 검증 비용으로 약 16분 후 max attempts 소진. countSolutions 조기 가지치기 또는 시드 폴백 필요. |
| 6 | 🟡 P2 | nonograms medium(15) 최대 2.5s — 경계 | 동상 | 보드 채움 비율/검증 비용 튜닝 검토 |
| 7 | 🟢 INFO | unused_field/element (badge popup) 12건 | yin_yang/tents/nonograms/killer_sudoku screens | 기존 코드, 이번 변경과 무관. 정리 권고 |
