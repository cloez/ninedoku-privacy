# 접근성/국제화 최종 점검 — 스토어 릴리즈 게이트

> 페르소나: WCAG 2.1 AA 전문 접근성/국제화 감사관
> 대상: Ninedoku v1.0.0+4 (13 게임)
> 검토일: 2026-06-15
> 검토 범위: lib/shared/l10n/app_strings.dart, 13 게임 board/screen, settings_screen.dart, custom_theme.dart, main.dart

---

## 종합 판정

| 항목 | 결과 | 근거 |
|---|---|---|
| **WCAG 2.1 AA 적합성** | **부적합 (Non-Conformant)** | 13게임 중 1게임(Sudoku)만 Semantics 적용, 12게임 보드/컨트롤이 스크린리더에 노출 불가 |
| **4개 언어 키 완전성** | **100%** (928/928 키, 한·영·일·중 일치, 누락 0건) | 자동 diff 결과 4언어 키 셋 동일 |
| **색맹 대응** | **부분 적합** | 실수 표시가 `Colors.red` 단색에만 의존, 보조 심볼 없음 |
| **폰트 크기 조절** | **적합** | `TextScaler.linear(fontScale)` 전역 적용 (main.dart) |
| **모션 감소 / 햅틱 토글** | **부분 적합** | 진동/사운드 토글 존재, 모션 감소(애니메이션 비활성) 옵션 없음 |
| **라이브 영역(LiveRegion)** | **부적합** | 코드베이스 전역 `LiveRegion`/`SemanticsService.announce` 0건 |

**결론: 현 상태로 Play Store 정식 릴리즈 시 WCAG 2.1 AA 미준수.** 최소 블로커 2건(B1, B2) 해소 후 출시 권고. P1 항목은 1.0.1 핫픽스로 처리 가능.

---

## 🔴 블로커 (출시 차단)

| # | 영역 | 항목 | 위치 | 권고 |
|---|---|---|---|---|
| **B1** | A11y - Name/Role/Value (WCAG 4.1.2) | **12개 신규 게임(Binairo, Minesweeper, Yin-Yang, Nonograms, Killer, Star Battle, Light Up, Futoshiki, Tents, Jigsaw, Skyscrapers, Kakuro) 보드/컨트롤에 `Semantics` 위젯 0건.** TalkBack 사용자는 셀 위치·값·상태를 전혀 들을 수 없어 게임 자체가 불가능. | `lib/games/*/screens/*_board.dart`, `*_game_screen.dart` 전 파일 | 각 셀에 `Semantics(label: ...)` 추가. 라벨은 `AppStrings.get('a11y.cell.label', row, col, value)` 형태로 다국어화 |
| **B2** | i18n × A11y (WCAG 3.1.1) | **Sudoku 보드 Semantics 라벨이 한국어 하드코딩** (`'행 ${row + 1}, 열 ${col + 1}...'`). 영/일/중 시스템에서도 한국어 음성으로 발표돼 비한국어권 시각장애 사용자가 게임 인식 불가. | `lib/features/game/widgets/sudoku_board_widget.dart:110` | 하드코딩 문자열을 `AppStrings.get('sudoku.a11y.cell', ...)` 키로 추출, 4언어 정의 추가 |

## 🟡 P1 (출시 후 1주 내 핫픽스)

| # | 영역 | 항목 | 위치 | 권고 |
|---|---|---|---|---|
| **P1-1** | A11y - 색 의존 (WCAG 1.4.1) | 실수 표시가 `wrongNumber: Colors.red` 단색에만 의존. 적록 색맹(전체 인구 ~8%) 사용자가 정답/오답 구분 불가 | `lib/app/custom_theme.dart:296`, `sudoku_board_widget.dart` 등 | 오답에 굵은 밑줄/취소선/⚠ 심볼 병행. 옵션으로 "색맹 친화 모드" 토글 |
| **P1-2** | A11y - LiveRegion (WCAG 4.1.3) | 타이머/힌트 메시지/완료 알림/뱃지 획득 등 동적 변경이 스크린리더에 발표되지 않음. `LiveRegion` 또는 `SemanticsService.announce` 사용처 0건 | 13 game_screen 전반, badges 토스트 | 힌트 토스트와 게임 완료/오류 알림을 `LiveRegion(child: Text(...))` 으로 감싸기 |
| **P1-3** | A11y - 터치 타깃 (WCAG 2.5.5) | NumberPad/입력 모드 토글 셀 최소 크기 명시 없음 — 작은 단말(예: 360dp 너비)에서 9버튼 가로 배치 시 셀당 ~40dp로 권고치 44×44dp 미달 우려 | `lib/features/game/widgets/number_pad_widget.dart` 외 12게임 패드 | `ConstrainedBox(minHeight: 48, minWidth: 48)` 적용, 좁은 화면에서는 2행 분할 |
| **P1-4** | A11y - 모션 감소 (WCAG 2.3.3) | 셀 채움/완료 애니메이션, 페이지 전환 애니메이션에 대한 "모션 감소" 옵션 부재. 전정기능 장애·멀미 사용자 배려 미비 | 설정 화면 | `settings.reduceMotion` 추가, `AnimatedSwitcher`/`Hero` 등에서 분기 |
| **P1-5** | i18n - 게임 용어 검수 | "이어하기"/"한 판 더"/"포기" 같은 게임 캐주얼 표현이 일본어("諦める")·중국어("放棄") 직역 톤인지 네이티브 감수 필요. 4언어 키는 존재하나 자연스러움 미검증 | `app_strings.dart` 전반 (4090 라인) | 네이티브 감수 1회, 특히 onboarding/tutorial/exit/giveUp 영역 우선 |

## 🟢 P2 (백로그)

| # | 항목 |
|---|---|
| P2-1 | 명도 대비 자동 측정 미실시 — 라이트/다크 두 테마 × 텍스트/UI 24개 조합 contrast ratio 측정 도구(예: Flutter `WidgetTester` + `ColorChecker`) CI 통합 |
| P2-2 | RTL 대응 — 현재 아랍어/히브리어 미지원이지만 향후 추가 시 보드 좌표(행/열)는 LTR 유지 필요. `Directionality` 격리 영역 표시 가이드 문서화 |
| P2-3 | 숫자 포맷 — 통계 화면의 1,000자리 구분은 영/한 콤마, 독일/유럽 점, 일본 콤마 — 현재 단순 문자열. `NumberFormat.decimalPattern(locale)` 도입 |
| P2-4 | 인지 부담 감소 "단순 모드" — 메모/힌트/타이머 일괄 OFF 프리셋 |
| P2-5 | 일본어/중국어 시스템 폰트 렌더링 실기기 확인 — 일부 한자 글리프 폴백 시 모양 차이 가능 |
| P2-6 | 진동/사운드 토글은 존재하나 "햅틱 강도" 단계 조절 없음 |
| P2-7 | 라이트 모드 다크 모드 모두에서 셀 선택/하이라이트/같은 숫자 강조 3색 구분이 색맹 사용자에게도 유효한지 시뮬레이션 |

---

## WCAG 차원별 평가

| WCAG 기준 | 결과 | 위치/근거 |
|---|---|---|
| **1.1.1 비텍스트 콘텐츠** | 부분 | 아이콘 버튼에 `tooltip` 일부 누락, 게임 보드 SVG-like cell은 `Semantics` 미적용 |
| **1.4.1 색의 사용** | 부적합 | 오답 표시 `Colors.red` 단독, 보조 표식 없음 (P1-1) |
| **1.4.3 명도 대비 (AA)** | 미측정 | 자동/수동 측정 기록 부재 (P2-1) |
| **1.4.4 텍스트 크기 조절** | 적합 | `TextScaler.linear(fontScale)` 전역 적용 (`main.dart:46`) |
| **2.3.3 인터랙션의 모션** | 부적합 | 모션 감소 옵션 부재 (P1-4) |
| **2.5.5 터치 타깃 크기** | 부분 | NumberPad 최소 크기 미보장 (P1-3) |
| **3.1.1 페이지 언어** | 부분 | 4언어 키 완전 일치하나 보드 Semantics는 한국어 고정 (B2) |
| **4.1.2 Name, Role, Value** | **부적합** | 13게임 중 12게임 보드에 Semantics 0건 (B1) |
| **4.1.3 상태 메시지 (LiveRegion)** | 부적합 | `LiveRegion`/`announce` 사용처 0건 (P1-2) |

---

## 4개 언어 키 완전성 검사 결과

자동 diff (`_ko`, `_en`, `_ja`, `_zh` 4개 const Map) 실행 결과:

```
ko = 928 keys
en = 928 keys
ja = 928 keys
zh = 928 keys

ko - en : (없음)
ko - ja : (없음)
ko - zh : (없음)
en - ko : (없음)
ja - ko : (없음)
zh - ko : (없음)
```

**누락 키 0건.** 자동 키셋 측면에서는 완전. 단, 다음은 보고서로 확인 불가하여 추가 검수 필요:

- `badge.$id.name` 동적 키 — 13게임 × 다난이도 배지 ID 전수 검사는 별도 스크립트 필요 (Grep 표본은 통과)
- 번역 품질 (자연스러움) — 네이티브 감수 (P1-5)

---

## 권장 출시 전 행동

### 출시 차단 (필수)
1. **B1 해소** — 13게임 보드 셀에 `Semantics(label, hint, value)` 일괄 적용. 게임당 1~2시간, 총 ~20시간 예상.
   - 라벨 다국어 키 24개 추가 (게임별 cell.label / cell.hint × 12게임)
   - 적용 후 TalkBack ON 상태로 각 게임 1회 플레이 검증
2. **B2 해소** — Sudoku 보드 한국어 하드코딩 라벨을 `AppStrings.get` 키로 치환. 4언어 정의 추가.

### 출시 후 1주 내 (1.0.1 핫픽스)
3. **P1-1** 오답에 보조 심볼/굵기 병행 + 색맹 모드 토글 신설
4. **P1-2** 힌트/완료/오류 토스트 `LiveRegion` 적용
5. **P1-3** NumberPad/패드형 컨트롤 최소 48dp 보장
6. **P1-4** 설정에 `reduceMotion` 토글 추가
7. **P1-5** 영/일/중 네이티브 감수자 1인씩 섭외 (특히 게임 캐주얼 톤)

### 백로그 (1.1.0)
8. P2-1 명도 대비 자동 측정 CI 통합
9. P2-3 `NumberFormat` 로케일 적용
10. P2-4 "단순 모드" 프리셋
11. P2-7 색맹 시뮬레이션 기반 테마 점검

---

## 부록 — 검출 명령 재현

```bash
# 4언어 키 diff (Python)
python3 scripts/check_l10n_keys.py  # (작성 권장)

# Semantics 미적용 게임 식별
for d in binairo minesweeper yin_yang nonograms killer_sudoku star_battle \
         light_up futoshiki tents jigsaw_sudoku skyscrapers kakuro; do
  grep -l "Semantics(" lib/games/$d/**/*.dart || echo "  $d: NONE"
done

# LiveRegion / announce 검색
rg "LiveRegion|SemanticsService\\.announce" lib/
```

— 끝 —
