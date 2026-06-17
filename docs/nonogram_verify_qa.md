# 노노그램 검증 방식 변경 QA 점검 보고서

> 검증자: QA 에이전트
> 일자: 2026-06-05
> 사양: `docs/nonogram_verify_spec.md`
> 변경 파일 4종 (notifier, state, screen, l10n)

---

## A. 사양 준수

| # | 항목 | 결과 | 비고 |
|---|------|------|------|
| A1 | `_applyValue`에서 mistakeCount 증가 로직 제거 | PASS | notifier.dart L215-241, 카운트 증감 코드 전무. 주석 L212-214에 설계 의도 명시 |
| A2 | `_applyValue`에서 실수 햅틱(heavyImpact) 제거 | PASS | L218 `HapticFeedback.selectionClick()` 단일 호출. heavyImpact는 완료 시(L368)만 사용 |
| A3 | verify() 메서드 추가 | PASS | L248-257, `NonogramSolver.isComplete` 호출 후 `_checkCompletion` 위임. 멱등 동작 보장 |
| A4 | Grade.evaluate가 mistakes 무시 | PASS | state.dart L69-91, mistakes 파라미터 받지만 분기 로직에서 사용 안 함. 주석으로 명시 |
| A5 | 상태 바에서 실수 표시 제거 | PASS | screen.dart `_StatusBar` L615-639, timer + hintCount 2개 칩만 노출. 가로 모드도 동일 `_StatusBar` 재사용(L187) |
| A6 | 컨트롤 바 확인 버튼 추가(check_circle_outline_rounded) | PASS | screen.dart L737-743, 녹색, 항상 활성. 가로/세로 모드 모두 `_ControlBar` 공유 |
| A7 | 결과 화면 통계에서 실수 항목 제거 | PASS | L368-371, 시간/난이도/힌트 3행만 렌더. mistakeCount 참조 없음 |
| A8 | 확인 실패 시 토스트 + 약한 햅틱 | PASS | L482-498, `HapticFeedback.selectionClick()` + 부유 스낵바 2초, `clearSnackBars()`로 중복 방지 |
| A9 | 4개 언어 nonogram.verify, nonogram.verify.fail 정의 | PASS | ko/en/ja/zh 모두 확인 (L521-522, L1529-1530, L2535-2536, L3541-3542) |

## B. 코드 품질

| # | 항목 | 결과 | 비고 |
|---|------|------|------|
| B1 | mistakeCount 필드 보존 | PASS | state.dart L141 필드 유지, L180 기본값 0, toJson/fromJson에서 직렬화 유지 |
| B2 | SharedPreferences 로드 호환성 | PASS | fromJson에서 `mistakeCount: json['mistakeCount'] as int? ?? 0` — 신규/구버전 모두 로드 가능 |
| B3 | 다른 12게임에 영향 없음 | PASS | git diff/status 상 변경 파일은 nonograms 폴더 + l10n만. 다른 게임 폴더 변경 없음 |
| B4 | CompletedGameRecord 호환 | PASS | notifier L386 `mistakeCount: state!.mistakeCount` 전달 (항상 0). 저장 스키마 무손상 |

## C. 테스트 실행

- 명령: `flutter test test/games/nonograms`
- 결과: **47개 PASS / 0개 FAIL** ("All tests passed!")
- 핵심 신규 검증 케이스:
  - "실수가 등급에 영향 없음 (정통 노노그램)" — PASS
  - "힌트 0 + 기준시간 초과 → A 등급" — PASS
  - "힌트 1회 → A 등급" — PASS
  - "힌트 4회 → C 등급" — PASS

## D. 정적 분석

- 명령: `flutter analyze lib/games/nonograms`
- **에러 0건, 경고 3건, info 1건** (모두 사양과 무관)
  - info: `_badgePopupShown could be final` (사양 변경 부수효과)
  - warning: `_badgePopupShown` 미사용 (사양 변경 부수효과 — 결과화면 인라인 칩으로 대체되어 다이얼로그 비활성화됨)
  - warning: `_showBadgePopup` 미참조 (위와 동일 사유)
  - warning: `_showDifficultyPickerForNewGame` 내 `isDark` 미사용 (사양 변경 무관)

## E. 회귀 영향

- 다른 게임 코드 변경: **없음** (lib/games/nonograms와 lib/shared/l10n/app_strings.dart 외 무변경)
- 노노그램 generator/solver 미변경: **확인** (engine/ 하위 변경 없음, 테스트 A2/A3/A4 그룹 30개 모두 PASS)
- 자동 완료 판정(`_checkCompletion`) 정상: **확인** — L361-373 무변경, `NonogramSolver.isComplete` 호출 로직 동일. verify()도 동일 함수 위임으로 일관성 유지

## F. UX 일관성

| # | 항목 | 결과 | 비고 |
|---|------|------|------|
| F1 | 컨트롤 바 배치 | PASS | [채움][크로스] · [되돌리기][힌트] · [체크포인트][✓확인] 6개 버튼 그룹화. 녹색 체크 아이콘으로 시각적 강조 |
| F2 | 가로 모드 가시성 | PASS | `_buildLandscapeLayout` L203-208에서 동일 `_ControlBar` 사용, 우측 컬럼 하단에 확인 버튼 노출 |
| F3 | 토스트 vs BackPressExit 충돌 | PASS | `clearSnackBars()` 선호출(L487)로 기존 스낵바 정리. PopScope의 백키 처리(`_showExitDialog`)는 다이얼로그라 토스트와 레이어 분리 |
| F4 | 햅틱 강도 일관성 | PASS | 입력=selectionClick, 검증실패=selectionClick(약함), 완료=heavyImpact(강함) — 사양 §3.3 일치 |

## G. 게임 흐름 시나리오 (코드 정적 분석)

| # | 시나리오 | 예상 동작 | 결과 |
|---|---------|----------|------|
| G1 | ■을 정답 아닌 위치에 놓음 | mistakeCount 불변, selectionClick 햅틱만 | PASS — `_applyValue`에서 정답 비교 분기 없음 |
| G2 | ✕를 정답 위치에 놓음 | 동일하게 카운트 없음 | PASS — fill/cross/erase 분기 모두 `_applyValue`로 수렴, 검증 없음 |
| G3 | 모든 채움 정답대로 놓음 | 자동 완료 | PASS — `_applyValue` 끝에서 `_checkCompletion` 호출, `isComplete` 시 결과화면 전환 |
| G4 | 일부만 풀고 verify | 토스트 "아직 풀이가 완성되지 않았어요" | PASS — verify()가 false 반환 → `_onVerify`에서 `nonogram.verify.fail` 스낵바 표시 |
| G5 | 정답 완성 후 verify | 즉시 완료 (이미 자동 완료됐을 수도) | PASS — verify() 진입 시 `isCompleted`면 즉시 false 반환(L249, 멱등 안전). 자동완료 이전이라면 `_checkCompletion` 호출로 완료 |

## 종합 판정

🟢 **PASS**

- 사양서 9개 항목 100% 구현
- 47개 단위 테스트 통과
- 정적 분석 에러 0건
- 백워드 호환(저장 데이터 무손상), 다른 게임 무영향
- 가로/세로 UX, 햅틱, 다국어 4개국어 일관

## 발견 사항

| # | 심각도 | 항목 | 권고 |
|---|--------|------|------|
| 1 | Low | screen.dart L22 `_badgePopupShown` 필드와 L500-529 `_showBadgePopup` 메서드가 더 이상 사용되지 않음 (L32-37에서 호출 부분이 주석 처리됨) | 후속 정리 PR에서 제거. 현재 사양과 무관하지만 사양 변경 부수효과로 발생. flutter analyze 경고 3건 발생원 |
| 2 | Info | nonogram_state.dart `gradeThresholds` 함수(L94-103)가 mistakes 임계값을 여전히 노출하나 evaluate에서 미사용 | 후속 정리 시 제거 검토. 외부 참조 없으면 dead code |
| 3 | Info | `mistakeCount` 필드는 백워드 호환 목적으로 보존되었으나 영구적으로 0으로 유지됨 | 통계/배지 서비스가 이 값을 읽어 "실수 0회 보너스" 같은 잘못된 배지를 부여하지 않는지 별도 확인 권고 (`NonogramBadgeService` 점검) |
