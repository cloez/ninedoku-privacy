# UX 3인 사용성 검토 보고서

> 검토 대상: Ninedoku 13게임 (sudoku, binairo, minesweeper, yin_yang, nonograms, killer_sudoku, star_battle, light_up, futoshiki, tents, jigsaw_sudoku, skyscrapers, kakuro)
> 검토단: UX1 (IA/내비) / UX2 (인터랙션/마이크로 UX) / UX3 (시각/접근성)
> 검토일: 2026-06-04
> 검토 방식: 실제 코드(`lib/` 트리) 정적 분석 + 사용자 흐름 추적

---

## 0. 공통 구조 요약 (반복 평가 회피)

13게임 공통:

- 진입: `GameHubScreen`(2열 그리드 카드) → 각 게임 홈 → BottomSheet 난이도 선택 → 플레이.
- 게임 홈 패턴(스도쿠/비나이로/카쿠로 등 12게임 동일): `AppBar(apps 아이콘 → 허브, 제목)` → 아이콘+서브타이틀 → (이어하기 카드) → 새 게임/오늘의 퍼즐 → 통계/배지 가로 2분할 → 규칙 카드.
- 플레이 화면: `AppBar(arrow_back → ExitDialog, pause)` → `_GameInfoBar(난이도+크기, 실수, 타이머)` → 보드(Expanded+Center) → `AnimatedSize` 힌트 메시지 → 컨트롤 바.
- 일시정지/결과 화면도 동일 패턴(이어하기/홈/포기 + 등급 원형 + 통계 + 새 게임/홈).
- `PopScope(canPop:false)` + ExitDialog로 백키 일관 처리. 허브에서는 `BackPressExit` 종료 확인.

→ 게임 간 멘탈 모델 일관성은 매우 강력. 패턴 학습 비용이 낮음.

---

## UX1: 정보 구조 + 내비게이션 평가

### 강점 (Strengths)
- 허브 → 게임 진입까지 **2탭**으로 도달 (3탭 룰 준수). `lib/features/hub/screens/game_hub_screen.dart:189-190`
- 12개 게임 홈에 동일한 좌상단 **apps 아이콘**으로 허브 복귀, 일관성 우수. (binairo_home_screen.dart:42-46 등 12개 파일 동일 패턴)
- **이어하기 카드**(진행률 % + 칩 라벨 + 타이머)가 모든 게임 홈에 동일 제공 → 컨텍스트 유지 우수. (`binairo_home_screen.dart:238-328`, `home_screen.dart:391-495`)
- 통계/배지에 `extra:'binairo'`처럼 컨텍스트 전달 → 게임별 통계 탭 자동 선택. (`binairo_home_screen.dart:120-130`)
- 허브 상단 통합 진행률(오늘 완료/전체, 스트릭) — 사용자에게 전체 그림 제공. (`game_hub_screen.dart:99-154`)
- 온보딩 3페이지(`onboarding_screen.dart:21-37`)로 첫 진입 흐름 가벼움.

### 약점 (Pain Points)
- ❌ **스도쿠만 튜토리얼 버튼 보유, 다른 12게임 홈에는 도움말 없음** → 첫 사용자가 카쿠로/킬러 스도쿠/스카이스크래퍼 등 복잡한 규칙을 만났을 때 학습 진입점이 규칙 카드 텍스트 한 덩어리뿐.
  - 위치: `lib/features/home/screens/home_screen.dart:285-289` (스도쿠만 `Icons.help_outline_rounded`). 12게임 홈 전수 검색 결과 `help_outline` 부재.
  - 영향: 카쿠로(=합 규칙), 스카이스크래퍼(=시점), 킬러스도쿠(=케이지), 텐트(=인접 규칙) 등 규칙 학습 곡선이 큰 게임에서 이탈 위험.

- ❌ **허브 → 게임 → 통계/배지/설정 도달 불일치**. 허브 하단에 통계/배지/설정 진입이 있지만 게임 홈에서 설정 도달 불가(스도쿠 제외).
  - 위치: `binairo_home_screen.dart:40-47` (AppBar actions 비어 있음, 설정 아이콘 없음). 12게임 모두 동일.
  - 영향: 게임 중 폰트 크기/언어/사운드 변경하려면 허브로 돌아가야 함. 2단계가 강제됨.

- ❌ **허브가 스도쿠를 첫 카드로 표시하면서 라우트가 `/`** 인데, 게임 홈에서 `apps_rounded` 아이콘이 "홈"인지 "허브"인지 라벨링 모호.
  - 위치: `home_screen.dart:280-283` tooltip `'hub.title'` vs 일반 사용자 멘탈 모델("뒤로 = ←").
  - 영향: 초보자는 `apps` 아이콘을 "메뉴"로 인지하기 쉬움, "전체 게임 목록"임이 직관적이지 않음.

- ❌ **빈 상태(통계/배지) 안내가 약함**. 통계 빈 화면은 작은 텍스트 2줄.
  - 위치: `statistics_screen.dart:438-466`. CTA(예: "지금 첫 게임 시작") 부재.
  - 영향: 처음 진입한 사용자가 "왜 비어 있는지"는 알지만 "어디로 가야 채우는지" 불명확.

- ❌ **각 게임 홈 → 통계/배지 진입 시 게임별 탭이 14개**(전체 + 13게임)나 가로 스크롤 TabBar → 탭 인식 부하 큼.
  - 위치: `statistics_screen.dart:252-269` (`isScrollable: true`, 14개 탭).
  - 영향: "내 게임" 통계로 자동 이동은 OK지만, 다른 탭 탐색 시 좌우 스와이프 14단계 필요.

- ❌ **진행 중 게임으로의 빠른 복귀 경로가 게임 홈 한 군데뿐**. 허브 카드에는 "이어하기 중" 배지 없음.
  - 위치: `game_hub_screen.dart:183-267` 카드에 NEW 배지만 표시, 진행중 표시 없음.
  - 영향: 허브에서 "어느 게임이 진행 중인지" 알 수 없어 게임 홈마다 들어가야 확인 가능.

### 우선순위
- 🚨 **P0**: 12게임 홈 도움말/튜토리얼 진입점 부재 (전 게임)
- 🚨 **P0**: 허브 카드에 "진행 중" 배지 표시 (전 게임)
- ⚠️ **P1**: 게임 홈 AppBar에 설정 아이콘 추가 (전 게임, 스도쿠 제외)
- ⚠️ **P1**: 통계 빈 상태에 CTA 버튼
- 📝 **P2**: `apps_rounded` 아이콘 → 명시적 "전체 게임" 라벨 BottomNav 패턴 검토
- 📝 **P2**: 통계 TabBar 14개를 게임 카테고리(스도쿠 변형/이진 토글/숫자 입력 등)로 그룹화

---

## UX2: 인터랙션 + 마이크로 UX 평가

### 강점 (Strengths)
- **컨트롤 바 패턴 통일** — 비나이로/노노그램(이진 토글), 카쿠로/킬러/직소/스카이/후토(숫자 패드 1~9), 메모 토글, 되돌리기, 힌트, 체크포인트가 동일 위치. (`kakuro_game_screen.dart:280-403`, `binairo_game_screen.dart:272-369`)
- **48dp 터치 타깃** 준수 — `_ActionButton width:48 height:48` (`kakuro_game_screen.dart:425-427`), 토글 `width:56 height:44` (`binairo_game_screen.dart:474-476`). Material 44dp 가이드 충족.
- **체크포인트 버튼**(탭=저장/복원, 길게=삭제) 통일 — 실수 복구 강력. (`shared/widgets/checkpoint_button.dart`)
- **이전 난이도 가중치 랜덤**(스도쿠 빠른 게임) — 사용자 선호 학습. (`home_screen.dart:36-61`)
- **가로 모드 전용 레이아웃** 전 게임 구현 — 보드 5 : 컨트롤 4 비율. AppBar 숨기고 우측 컴팩트 헤더. (`binairo_game_screen.dart:115-182`, `kakuro_game_screen.dart:117-191`)
- **백키 이중 안전망** — 플레이 중 백키 → ExitDialog, 일시정지 백키 → resume, 허브 백키 → 종료 확인. `PopScope(canPop:false)` 일관 적용 (24/24 파일).
- **힌트 메시지 영역에 `AnimatedSize`** — 레이아웃 흔들림 없음. (`binairo_game_screen.dart:99-106`)

### 약점 (Pain Points)
- ❌ **햅틱 피드백이 1개 파일에만 존재**(`lib/core/utils/feedback_service.dart`). 실제 보드 셀 탭/실수/완료 시 햅틱이 일관 적용되었는지 코드상 확신 불가.
  - 영향: 즉각 피드백 부재 → 입력 감각 저하. iOS/Android 모바일 게임 표준 미달.
  - Grep 결과 `HapticFeedback` 직접 호출 파일 0개(서비스 1개만).

- ❌ **결과 화면의 등급/배지 팝업이 다이얼로그+결과화면 이중 표시**. 사용자가 OK 누르면 다시 결과화면이 보임.
  - 위치: `binairo_game_screen.dart:687-738` `_showBadgePopupIfNeeded` + `_buildNewBadgesSection`. 카쿠로 동일(`kakuro_game_screen.dart:671-723`).
  - 영향: 동일 정보 2번 노출 → 마찰. 한 번에 통합된 결과 시퀀스가 더 자연스러움.

- ❌ **하단 컨트롤 바가 화면 하단에 고정되지 않음** — `Column` 흐름 후 `SizedBox(height:16)`. Thumb zone(하단 우측) 최적화 미흡.
  - 위치: `binairo_game_screen.dart:107-110`, `kakuro_game_screen.dart:107-112`.
  - 영향: 큰 화면(접이식 폰)에서 컨트롤이 중앙에 떠 있게 보일 수 있음.

- ❌ **일시정지에서 "포기"가 빨간색 TextButton 한 줄 → 미스탭 가능**. 다이얼로그가 있으나 큰 화면에서 ElevatedButton "이어하기"와 거리가 가까움.
  - 위치: `binairo_game_screen.dart:614-633`. `_BinairoPauseView` 동일 패턴 13게임.
  - 영향: 실수로 누르면 다이얼로그가 한 번 더 막아주지만 인지 부하 증가.

- ❌ **노노그램 롱프레스로 크로스 토글 → 모드 즉시 복원**의 흐름이 비표준.
  - 위치: `nonogram_game_screen.dart:100-105`. `setInputMode(cross)` → `tapCell` → `setInputMode(state.inputMode)`.
  - 영향: 빠르게 두 번 롱프레스 시 race condition 가능. 다른 게임과 멘탈 모델 다름(보통 롱프레스=메모/플래그 영구 모드).

- ❌ **카쿠로 숫자 패드 9개가 한 줄** — 작은 폰(360dp)에서 셀당 폭이 좁음. `AspectRatio 0.9`로 보정하나 좁은 폰에서 탭 영역 < 40dp 가능.
  - 위치: `kakuro_game_screen.dart:290-326`.
  - 영향: 손가락 큰 사용자 미스탭. (스도쿠 NumberPad는 9개를 5+4 또는 별도 처리 — 확인 필요)

- ❌ **선택된 셀 표시가 색 의존**(파란 stroke 3px). 색맹 사용자에게 약함.
  - 위치: `binairo_board_widget.dart:106-110`.
  - 영향: 적록 색맹 사용자가 선택 셀 식별 곤란.

- ❌ **`_showBadgePopupIfNeeded` 가 `_badgePopupShown` 로컬 플래그 사용** → 화면 회전 시 재표시 가능.
  - 위치: `binairo_game_screen.dart:682-700`, `kakuro_game_screen.dart:661-679`.
  - 영향: 가로 모드 전환 시 같은 배지 팝업이 다시 뜸.

- ❌ **인터랙션 패턴 멘탈 모델 분기**: 비나이로/음양/스타배틀(이진 토글) vs 노노그램(채움/크로스/빈칸 3상태) — 동일 카테고리지만 입력 모달리티가 다름.
  - 영향: 비나이로 마스터한 사용자가 노노그램에서 "○가 왜 없지?" 혼란.

### 우선순위
- 🚨 **P0**: 보드 셀 탭/실수/완료에 `HapticFeedback.lightImpact/selectionClick` 명시 적용 (전 게임)
- 🚨 **P0**: 결과 화면 배지 표시 이중화 제거 → 다이얼로그 OR 인라인 둘 중 하나로 통일
- ⚠️ **P1**: `_badgePopupShown`을 Notifier 상태로 이동 (회전 시 재표시 방지)
- ⚠️ **P1**: 카쿠로/킬러/직소/스카이 숫자 패드 — 작은 폰에서 2행 분할 옵션
- ⚠️ **P1**: 포기 버튼을 일시정지 화면 하단 + 색상 단계화(빨강 + 1차 다이얼로그 + 입력 지연)
- 📝 **P2**: 컨트롤 바를 `Scaffold(bottomNavigationBar)`로 옮겨 하단 고정
- 📝 **P2**: 노노그램 입력 모드 패턴 재검토(인접 게임과 일치)

---

## UX3: 시각 디자인 + 정보 위계 + 접근성 평가

### 강점 (Strengths)
- **Theme + ColorScheme + AppColors** 토큰 사용으로 다크/라이트 모드 일관성. (전 파일 `Theme.of(context).textTheme`/`colorScheme` 사용)
- **타이포 위계**: `headlineSmall`(허브/결과), `titleMedium`(섹션 제목), `titleSmall`(타일), `bodyMedium/Small`(설명), `labelSmall`(메타) — 일관 적용. (`game_hub_screen.dart:62-65, 215-217`)
- **난이도 컬러 코드 통일**(beginner=green → master=purple) — 비나이로/스도쿠 동일. (`home_screen.dart:752-767`, `binairo_home_screen.dart:365-378`)
- **타이머에 `tabularFigures` FontFeature** 적용 — 숫자 폭 일정. (`binairo_game_screen.dart:260-262`)
- **`fontScale`** 설정 제공 — 사용자 큰 글씨 모드 지원. (`settings_screen.dart:50-56`)
- **테마 선택 화면** + Material You 톤 — 시각 차별화 옵션. (`theme_select_screen.dart` 존재)
- **선택 셀에 3px 두꺼운 stroke** — 일반 사용자 식별 양호. (`binairo_board_widget.dart:108-110`)
- **결과 화면 등급 원형**(80x80, 색상 border 3px, symbol/label) — 보상감 강력. (`binairo_game_screen.dart:771-798`)
- **`isDark` 분기 일관** — 회색 5단계 사용으로 명도 차 유지.

### 약점 (Pain Points)
- ❌ **`Semantics` / `semanticLabel` 사용 파일 3개뿐**(`sudoku_board_widget.dart`, `game_info_bar.dart`, `number_pad_widget.dart`). 12개 새 게임의 보드/컨트롤은 TalkBack 미지원.
  - 영향: 시각장애 사용자 사용 불가. WCAG 2.1 AA "Name, Role, Value" 위반.

- ❌ **오류 표시가 색에만 의존**. 실수 카운트는 `Icons.close_rounded` + 빨강 텍스트.
  - 위치: `binairo_game_screen.dart:237-249`.
  - 영향: 색맹 사용자가 빨강을 인지 못해도 아이콘+숫자로 보완은 되나, 보드 위 "잘못된 셀" 표시가 빨강 단독이면 식별 곤란. (보드 painter에서 wrong 색 처리 확인 필요)

- ❌ **포기/실수 색상이 `wrongNumberLight/Dark`** — 라이트 모드에서 채도 높은 빨강이라 명도 대비 OK, 다크 모드는 `Colors.red.shade300/400` — 다크 배경 대비 4.5:1 미달 가능성.
  - 위치: `binairo_game_screen.dart:239-247`. WCAG 검증 필요.

- ❌ **카드 본문 라인 높이 1.3~1.5 혼재**. 규칙 카드 line-height 1.5 (`home_screen.dart:550`), 설명 1.4 (`binairo_home_screen.dart:434`).
  - 영향: 카드 간 시각 리듬 미세 흔들림(큰 문제 아님).

- ❌ **NEW 배지가 `colorScheme.error`** 사용 — "오류" 토큰을 "신규" 의미로 재활용. 의미 충돌.
  - 위치: `game_hub_screen.dart:251-253`.
  - 영향: 디자인 시스템 일관성 저해(예: 통계에서 error 색을 보면 무엇을 의미하는지 학습 비용).

- ❌ **이모지를 게임 식별자로 사용**(허브 카드 `fontSize:44`) — 시스템 폰트 의존, 다국어/OS별 렌더링 차이 큼.
  - 위치: `game_hub_screen.dart:208-211`.
  - 영향: 일부 Android 디바이스(특히 한국 통신사 커스텀 폰트)에서 이모지 단색 처리되어 시각 변별력 저하.

- ❌ **카드 설명 maxLines:3 + ellipsis** — 긴 설명 잘림. 다국어(한/영/중/일) 확장 시 변동.
  - 위치: `game_hub_screen.dart:235-237`.
  - 영향: 한국어 기준 OK, 일부 언어에서 핵심 정보 누락 가능.

- ❌ **타이머 색상 `Colors.white54/black45`** → 정보가 약함. 진행 중 게임의 핵심 지표 중 하나인데 시각적 위계가 낮음.
  - 위치: `binairo_game_screen.dart:259-264`.
  - 영향: 도전 모드 사용자가 시간을 모니터링하기 어려움.

- ❌ **컨트롤 라벨 fontSize:9** — 작은 폰트는 가독성 한계. `fontScale` 적용 시 줄바꿈 가능성.
  - 위치: `kakuro_game_screen.dart:457`, `binairo_game_screen.dart:432`.
  - 영향: 시력 약한 사용자/접근성 모드에서 라벨 식별 곤란.

- ❌ **색맹 사용자용 대안 UI 없음**. 설정에 색맹 모드 토글 부재.
  - 위치: `settings_screen.dart` 전체 검사 결과 부재.

### 우선순위
- 🚨 **P0**: 12게임 보드/컨트롤에 `Semantics` 추가 (전 게임, TalkBack)
- 🚨 **P0**: 다크 모드 빨강(`Colors.red.shade300/400`) 대비 측정 + 필요 시 채도 조정
- ⚠️ **P1**: 오류/실수 셀에 패턴(점선/대각선)도 추가 (색 의존 해소, 전 게임)
- ⚠️ **P1**: NEW 배지를 `colorScheme.tertiary` 또는 전용 토큰으로 변경
- ⚠️ **P1**: 컨트롤 라벨 fontSize 9 → 11, 필요 시 가로 모드에서만 9
- 📝 **P2**: 색맹 모드 토글 + 색맹 친화 팔레트 옵션
- 📝 **P2**: 이모지 대신 SVG/IconData 사용한 게임 아이콘
- 📝 **P2**: 카드 설명 줄 수 자동 조절(언어별)

---

## 종합 발견 사항

### 🚨 P0 — 즉시 개선

| # | 항목 | 영향 게임 | 개선안 |
|---|------|----------|--------|
| 1 | 게임 홈 도움말/튜토리얼 진입점 부재 | 12게임 (스도쿠 제외) | AppBar actions에 `Icons.help_outline_rounded` 추가 → 게임별 튜토리얼/규칙 풀스크린 |
| 2 | 허브 카드에 "진행 중" 배지 없음 | 13게임 모두 | `GameInfo`에 진행률 조회 추가, NEW 배지와 별도 색으로 "이어하기" 표시 |
| 3 | 보드 셀 탭/실수/완료에 햅틱 미적용 | 13게임 모두 | 각 notifier `tapCell`/`onMistake`/`onComplete`에 `HapticFeedback.selectionClick/heavyImpact` 적용 |
| 4 | 결과 화면 배지 표시 이중화 | 12게임 (스도쿠 제외) | 다이얼로그 또는 인라인 중 1택 통일, 권장: 인라인 후 OK |
| 5 | 12게임 보드/컨트롤에 Semantics 부재 | 12게임 (스도쿠만 일부 적용) | `BoardWidget`에 `Semantics(label, hint, value)` 적용, 셀별 좌표/값 라벨 |
| 6 | 다크 모드 빨강 명도 대비 미검증 | 13게임 모두 | `Colors.red.shade300` → `shade400` 조정 또는 배경 대비 측정 후 토큰화 |

### ⚠️ P1 — 다음 사이클

| # | 항목 | 영향 게임 | 개선안 |
|---|------|----------|--------|
| 7 | 게임 홈 AppBar에 설정 아이콘 없음 | 12게임 (스도쿠 제외) | AppBar actions에 `Icons.settings_outlined` |
| 8 | 통계 빈 상태에 CTA 없음 | 통계 공통 | 빈 화면에 "지금 첫 게임 시작" Button → 허브로 |
| 9 | `_badgePopupShown` 로컬 플래그 → 회전 시 재표시 | 12게임 | Notifier `lastBadgePopupShown` 상태로 이동 |
| 10 | 카쿠로/킬러/직소/스카이 숫자 패드 1줄 9개 | 4게임 | 작은 폰(<360dp)에서 2행 분할 |
| 11 | 포기 버튼 미스탭 위험 | 13게임 일시정지 화면 | 위치를 하단 fold + 입력 지연(200ms) 또는 long-press 확인 |
| 12 | 오류 셀 색 의존 | 13게임 보드 | 패턴(점선 border) 추가 |
| 13 | NEW 배지가 error 토큰 재활용 | 허브 | `tertiary` 또는 전용 accent 토큰 |
| 14 | 컨트롤 라벨 fontSize 9 | 12게임 | 11pt + 가로 모드 한정 9pt |
| 15 | 일시정지 포기 라벨 톤 | 13게임 | "그만두기" → "이 게임 포기" 명시 |

### 📝 P2 — 백로그

| # | 항목 | 영향 게임 | 개선안 |
|---|------|----------|--------|
| 16 | 통계 14개 탭 가로 스크롤 부담 | 통계 화면 | 카테고리(스도쿠 변형 / 이진 토글 / 숫자 / 영역) 그룹 |
| 17 | 컨트롤 바 화면 하단 미고정 | 13게임 | `Scaffold.bottomNavigationBar` 활용 |
| 18 | 노노그램 입력 모드 = 다른 게임과 다름 | 노노그램 | 음양/비나이로와 멘탈 모델 정렬 검토 |
| 19 | 색맹 모드 토글 부재 | 설정 | 토글 + 패턴/심볼 강화 |
| 20 | 이모지 게임 아이콘 | 허브 | SVG 또는 커스텀 IconData |
| 21 | 카드 설명 다국어 줄 잘림 | 허브 | 언어별 maxLines 동적 |
| 22 | `apps_rounded` 아이콘 라벨 모호 | 12게임 홈 | "모든 게임" 라벨 명시 또는 BottomNav 전환 |

### Heuristic Evaluation 종합 점수

| 차원 | 점수 | 근거 |
|---|---|---|
| IA / 내비게이션 | **7.5/10** | 허브-홈-플레이 3계층이 명료. 도달성 우수. 단, 설정/도움말 도달 비대칭. |
| 인터랙션 | **7.0/10** | 패턴 일관성 매우 강력, 체크포인트/Undo/이어하기 견고. 햅틱/배지 이중화 마찰. |
| 시각 / 접근성 | **6.0/10** | 토큰 사용 우수하나 a11y(`Semantics`, 색맹, 다크 빨강) 검증 부족. |
| **종합** | **6.8/10** | 일관성/구조는 상위권, 접근성과 마이크로 UX 디테일에서 개선 여지. |

### 베스트 사용성 우수 사례 (Best Practices 발견)

- **허브 → 게임 홈 → 플레이 3단계 일관 구조**: 13게임 동일 → 두 번째 게임부터 학습 0. (`game_hub_screen.dart` + 13개 game_home)
- **이어하기 카드**(진행률 %, 칩 라벨, 타이머): 컨텍스트 유지의 모범. (`home_screen.dart:391-495`)
- **체크포인트 버튼**(탭=저장/복원, 길게=삭제) + 토스트 피드백: 어려운 퍼즐 막다른 골목 해소 → 이탈 방지. (`shared/widgets/checkpoint_button.dart`)
- **`AnimatedSize` 힌트 메시지**: 레이아웃 흔들림 없는 정보 표시. (`binairo_game_screen.dart:99-106`)
- **모드 BottomSheet 핸들 + SafeArea + viewInsets**: 다양한 폰 폼 팩터 대응. (`home_screen.dart:86-95, 199-210`)
- **PopScope 백키 일관 처리**: 13/13 게임 동일. 우발적 종료 방지.
- **`fontScale` 사용자 설정** + Material You 테마 선택: 접근성/개인화 토대 확보. (`settings_screen.dart:50`)

### 개선 권장 사용자 흐름 — "어려운 카쿠로/스카이스크래퍼를 처음 만난 사용자"

**현재 흐름** (마찰 지점 5):
```
허브 → 카쿠로 카드 탭 → 카쿠로 홈 (규칙 텍스트만 있음, 튜토리얼 없음) ❶
→ "새 게임" → BottomSheet 난이도 선택 (Beginner 무엇이 다른지 불명확) ❷
→ 플레이 화면 (선택 셀이 색 단독) ❸
→ 실수 시 햅틱 없음, 색만 변경 ❹
→ 막다른 골목 → 포기 다이얼로그 → 홈 복귀 → 재시도 의욕 저하 ❺
```

**제안 흐름** (P0+P1 적용):
```
허브 → "진행 중" 배지 보고 다른 게임 우선 처리 가능
→ 카쿠로 카드 탭 → 카쿠로 홈 (AppBar에 ? 아이콘) ✅
→ ? 탭 → 인터랙티브 튜토리얼(2~3 화면, 실제 작은 보드로 합 규칙 학습) ✅
→ 튜토리얼 종료 → "지금 시작" → 난이도 BottomSheet(각 항목에 예상 시간/특징) ✅
→ 플레이: 셀 탭 시 selectionClick 햅틱, 실수 시 heavyImpact + 패턴 표시 ✅
→ 막힘 → 힌트(이미 OK) → 체크포인트(이미 OK) → 종료 시 결과 화면(인라인 배지만, 다이얼로그 없음) ✅
```

핵심 변화는 **"학습 진입점(❶ → ✅) + 즉각 피드백(❹ → ✅) + 보상 마찰 제거(❺ → ✅)"** 3가지로, P0 6항목 반영만으로 큰 폭의 사용성 개선 가능.

---

## 검토 단 메모

- 본 검토는 코드(`lib/games/*`, `lib/features/*`) 정적 분석 기반이며, 실기 햅틱/대비/색맹 검증은 디바이스 테스트가 추가 필요.
- 핵심 패턴(이어하기, 체크포인트, BottomSheet 난이도)은 이미 우수 → P0/P1 목록은 "확장된 게임 12개에 균등 적용"이 핵심 메시지.
- 다음 합의 안건 추천: P0 6항목 우선 합의 (GD: 게임별 튜토리얼 범위, DEV: 햅틱/Semantics 일괄 작업 공수, QA: 대비 측정 도구).
