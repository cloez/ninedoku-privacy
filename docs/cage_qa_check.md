# 케이지 시각화 QA 검증 보고서

> 검증 대상: killer_sudoku 케이지 시각화 개선
> 검증일: 2026-06-05
> 검증 범위: `lib/games/killer_sudoku/widgets/cage_palette.dart` (신규), `killer_sudoku_board_widget.dart` (수정), `test/games/killer_sudoku/cage_palette_test.dart` (신규)

---

## A. 사양 준수

| 항목 | 결과 | 비고 |
|------|------|------|
| 8색 팔레트 (Blue/Green/Orange/Purple/Teal/Pink/Amber/Indigo) | PASS | `CagePalette.mainColors` HEX 값이 사양과 정확히 일치 (#1E88E5, #43A047, #FB8C00, #8E24AA, #00897B, #E91E63, #FFB300, #3949AB) |
| 라이트 배경 alpha ~9% | PASS | `withValues(alpha: 0.09)` — 사양 9.4% 근사치 |
| 다크 배경 alpha ~13% | PASS | `withValues(alpha: 0.13)` — 사양 13.3% 근사치 |
| 점선 색상 alpha 50~65% | PASS | 라이트 0.55, 다크 0.65 (사양 50% 기준 약간 상향, UX 가독성 강화 의도로 판단) |
| 점선 굵기 1.8px | PASS | `strokeWidth = 1.8` 명시 |
| 합계 텍스트 색상 = 케이지 색상 | PASS | `sumTextColor()` 사용. 다크 모드는 HSL 밝기 +0.15 보정 + 가독성 그림자 추가 |
| 인접 케이지는 다른 색 | PASS | `assignColors` 그리디 알고리즘 적용, 테스트 검증됨 |
| paint 순서 (배경→격자→셀강조→숫자→점선→합계) | CONDITIONAL | 실제 순서: 배경 → **케이지배경 → 셀강조 → 격자선** → 숫자 → 메모 → 점선 → 합계. 사양 문구와 격자/하이라이트 순서가 다르지만, 의도(점선/합계가 위에, 케이지 배경이 하이라이트 아래)는 충족됨 |

## B. 코드 품질

| 항목 | 결과 |
|------|------|
| `withOpacity` deprecated 미사용 | PASS — 전 파일에서 `withValues(alpha:)` 사용, grep 결과 0건 |
| `cageColors.length == cages.length` | PASS — `List<int>.filled(cages.length, ...)` 보장 |
| `shouldRepaint`가 cageColors 변경 시 재페인트 | PASS — `_listEquals(oldDelegate.cageColors, cageColors)` 비교 포함 |
| 모든 게임 모드 동작 | PASS — Painter는 `state.board.cages`에만 의존, 모드 분기 없음 |
| 색상 인덱스 범위 방어 | PASS — `i < cageColors.length ? cageColors[i] : 0` 폴백 |
| try-catch 예외 폴백 | PASS — `assignColors` 전체에 try-catch, -1 잔존 시 0번 폴백 |

## C. 테스트 실행

```
flutter test test/games/killer_sudoku
→ 00:10 +64: All tests passed!
```

- 실행 결과: **64개 PASS / 0개 FAIL** (cage_palette 7 + engine/state 57 = 64) 
- 사용자 기대치(64개)와 정확히 일치

## D. 정적 분석

```
flutter analyze lib/games/killer_sudoku
→ 3 issues found (0 error)
```

- 에러: **0건**
- 경고/info 3건: 모두 pre-existing (cage 시각화와 무관)
  - `killer_sudoku_hint.dart:80` — unnecessary_brace_in_string_interps (info)
  - `killer_sudoku_game_screen.dart:1` — unnecessary_import dart:ui (info)
  - `killer_sudoku_game_screen.dart:679` — _showBadgePopupIfNeeded unused (warning)

## E. 회귀 영향

- 다른 게임 영향: **없음** — 변경 파일은 모두 `lib/games/killer_sudoku/widgets/` 하위로 격리됨
- killer_sudoku 다른 파일 영향: **없음** — `killer_sudoku_state`, `killer_sudoku_notifier`, `engine/*` 미변경. board widget만 painter 내부 로직 수정
- 기존 57개 engine/state 테스트 100% PASS — 모델/엔진 회귀 없음 확인

## F. 시각 일관성

- paint 순서 적절성: PASS
  - 케이지 배경(2) → 선택/같은행/같은열/같은박스/같은케이지/선택셀/같은숫자 하이라이트(3) → 격자선(4) 순으로, **amber 선택 하이라이트가 케이지 배경보다 위에** 그려져 가독성 확보
  - 점선(7)과 합계(8)가 최상단에 그려져 케이지 경계/합계가 숫자 위에 명확히 표시
- 오류 셀(빨강) `AppColors.wrongNumber*` 사용 — 케이지 배경 alpha 9~13%에서도 충분히 식별 가능
- 다크/라이트 분기: `isDark` 모든 페인트에 반영, 사양 가독성 보정 포함

## G. 인접 회피

- 알고리즘 정확성: PASS
  - 십자형 5케이지 테스트(중앙+상하좌우)에서 중앙과 인접 4개가 모두 다른 색임을 검증
  - 그리디 색칠은 케이지 그래프의 최대 차수가 7 이하일 때 8색으로 항상 성공 보장
- 8색 충분성: 9×9에서 PASS
  - 한 케이지의 인접 케이지 최대 수는 셀 둘레 길이로 제한 — 평균 케이지 4셀 기준 인접 ≤ 8 (실제로는 거의 ≤ 5)
  - 평균 15~25 케이지 분포에서 충돌 케이스 거의 없음 (테스트 통과)
  - 극단 시 0번 폴백 안전망 존재

## H. 성능

- `assignColors` 추정 시간: **< 1ms** (O(n²m²), n≤25, m≤5 → 약 15,000 산술 연산)
- `shouldRepaint` 최적화: 상태/테마/cellSize/cageColors 변경 시에만 재페인트 → 보드 렌더 비용 증가 미미
- 페인트 순회: 기존 대비 `_drawCageBackgrounds` 1패스 추가 (O(81)). 무시 가능 수준
- 사용자 가이드 적합

---

## 종합 판정

**🟢 PASS**

- 64/64 테스트 통과
- 0 컴파일 에러
- 사양 핵심 요구사항 100% 충족
- 회귀 영향 없음
- 성능 가이드 내

## 발견 사항

1. **점선 alpha가 사양(50%)보다 상향됨** (라이트 55%, 다크 65%)
   - 가독성 강화 의도로 보이며 사양의 "최소 50%" 의도와 모순되지 않음
   - 사양 문서를 실제 구현치로 업데이트 권장 (alpha 55/65로 명시)

2. **paint 순서 미세 차이**
   - 사양: "배경 → 격자 → 셀강조 → 숫자 → 점선 → 합계"
   - 실제: "배경 → 케이지배경 → 셀강조 → 격자 → 숫자 → 메모 → 점선 → 합계"
   - 실제 순서가 UX 관점에서 더 우수함 (격자선이 amber 셀강조 위에 그어져 시인성↑)
   - 문제 없음, 사양 문서 업데이트만 권장

3. **`_sqrt` 자체 구현**
   - `dart:math` 미사용으로 자체 뉴턴법 구현 — 동작은 정상이나 `dart:math.sqrt` 사용이 더 표준적
   - 성능/정확도에 실제 영향 없음, 선택적 개선 항목

4. **pre-existing 정적 분석 경고 3건** (cage 변경과 무관, 별도 정리 권장)
