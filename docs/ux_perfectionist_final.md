# 결벽적 UX 전문가 최종 검토 — 스토어 릴리즈 게이트

> 검토일: 2026-06-15
> 검토자: 픽셀 단위 완벽함을 추구하는 UX 전문가
> 검토 범위: 13게임 + 허브/통계/배지/설정/온보딩
> 코드베이스: D:\00. Workspace\sudoku (v1.1.0+4)

---

## 종합 판정

**🟡 CONDITIONAL — 블로커 없음, P1 핫픽스 항목 다수**

스토어 정식 릴리즈를 진행해도 사용자 즉시 불만이 발생할 "블로커"는 발견되지 않았다.
13게임 사이의 핵심 UX 패턴(허브 카드, 난이도 BottomSheet, 200ms 애니메이션, 이어하기 카드, 규칙 카드)은 잘 통일되어 있다.
다만 **스도쿠 홈 화면이 12개 신규 게임 홈과 미묘하게 다른 디자인 토큰**을 사용하고 있어 결벽적 시각에서는 거슬리는 차이가 다수 존재한다.
또한 generator 로딩이 1~2초 걸릴 수 있는데 "퍼즐 생성 중" 텍스트 없이 무미한 스피너만 보여주는 점은 첫 인상에서 손해이다.

---

## 🔴 블로커 (즉시 수정 필요)

**없음.** 릴리즈 차단 수준의 결함은 발견되지 않았다.

| # | 항목 | 영향 | 위치 |
|---|---|---|---|
| — | (해당 없음) | — | — |

---

## 🟡 P1 (출시 후 핫픽스 — 1주 이내)

| # | 항목 | 영향 | 위치 |
|---|---|---|---|
| P1-1 | 스도쿠 홈만 **vertical padding 16**, 나머지 12게임은 **vertical 24** — 같은 그리드 시스템 안에서 첫 진입 시 점프 발생 | 13게임 통일성 깨짐 | `lib/features/home/screens/home_screen.dart:299` vs 12 게임 home 58~59 |
| P1-2 | 스도쿠 홈 아이콘 **size:64**, 나머지 12게임 **size:56** — 같은 헤더 슬롯 크기 차이 8px | 첫 인상 비일관 | `home_screen.dart:305` vs 12 게임 `size: 56` |
| P1-3 | 스도쿠 홈에는 **이어하기 위/아래 spacing 40**, 다른 12게임은 **32** — 8px 그리드 어긋남 | 픽셀 정렬 | `home_screen.dart:315` |
| P1-4 | **로딩 인디케이터에 텍스트 없음** — generator가 1~2초 걸리는 게임(Killer/Star Battle/Light Up/Nonogram master)에서 무미한 스피너만 노출 | "앱이 멈춘 것 아닌가?" 의심 발생 가능 | 13게임 game_screen 31줄 부근 (`Center(child: CircularProgressIndicator())` 일률) |
| P1-5 | **난이도 색상 토큰 미정의 + 13개 파일에 동일 switch 복붙** — `Colors.green/lightGreen/orange/deepOrange/purple` 하드코딩. 다크모드에서 명도 대비 부족(특히 `Colors.orange` 위 흰 텍스트) | 다크모드 가독성 + 유지보수성 | 13 game home 각각 `_difficultyColor()` |
| P1-6 | 허브 카드 **NEW/진행중 배지 위치(top:8, right:8) 일관**이지만 진행중 배지 색이 `Colors.amber.shade700` 하드코딩 — 다크모드 테마 토큰 사용 안 함 | 다크모드 톤 부조화 | `game_hub_screen.dart:256` |
| P1-7 | 허브 진행률 카드에서 **streak 0일 때 회색(Colors.grey)** — 다크모드에서 거의 안 보임 (배경과 명도 차 부족) | 다크모드 시인성 | `game_hub_screen.dart:139` |
| P1-8 | 스도쿠 `_ChipLabel` text color `Colors.white60`, 비나이로 `_ChipLabel`은 `Colors.white54` — 두 글자에 명도 차이 발생 | 다크모드 미세 비일관 | `home_screen.dart:515` vs `binairo_home_screen.dart:407` |
| P1-9 | **에러 상태 UI 부재** — generator 실패 시 SnackBar/에러 다이얼로그 코드 grep 결과 없음. 극단적 케이스에서 스피너가 영구히 돌 가능성 | 극한 상황에서 사용자 갇힘 | 13게임 game_screen 공통 |
| P1-10 | 통계 빈 상태는 있으나 **배지 빈 상태 UI 코드는 별도 위젯이 없음** (문자열만 정의 `badges.empty`) — 그래서 화면이 비어보일 가능성 | 배지 첫 진입 빈 화면 | `badges_screen.dart` |
| P1-11 | 허브 카드 그리드 `childAspectRatio: 0.85` 고정 — 작은 화면(폭 < 360dp)에서 설명 3줄이 잘릴 위험 | 저해상도 단말 | `game_hub_screen.dart:173` |
| P1-12 | 허브 진행률 카드 안의 두 Row가 `Expanded`로 분할되어 **언어별 텍스트 길이(독일어/일본어)에서 줄바꿈 가능성** 미검증 | 다국어 레이아웃 | `game_hub_screen.dart:113-150` |

---

## ✅ P1 반영 상태 (2026-06-15)

| # | 상태 | 변경 요약 |
|---|---|---|
| P1-1 | ✅ 반영 | `home_screen.dart` SingleChildScrollView padding vertical 16→24 |
| P1-2 | ✅ 반영 | 스도쿠 홈 아이콘 size 64→56 |
| P1-3 | ✅ 반영 | 아이콘↔부제목 12→8, 부제목 후 40→32 |
| P1-4 | ✅ 반영 | `loading.generating` 다국어 키 4언어 추가 + 공통 `GameLoadingScreen` 위젯 도입 → 13게임 game_screen 일괄 교체 |
| P1-5 | ✅ 반영 | `app_colors.dart`에 `DifficultyTokens` 클래스 추가 (다크모드 명도 상향), 13개 home_screen `_difficultyColor()` 토큰화 |
| P1-6 | ✅ 반영 | 진행중 배지 다크모드 분기 (`isDark ? amber.shade400 : amber.shade700`) |
| P1-7 | ✅ 반영 | 스트릭 0일 색상 `Colors.grey` → `colorScheme.onSurfaceVariant` |
| P1-8 | ✅ 반영 | 스도쿠 `_ChipLabel` `Colors.white60` → `Colors.white54` (비나이로와 통일) |
| P1-9 | ⏭ 다음 사이클 | generator 실패 토스트/에러 다이얼로그는 별도 사이클로 이관 |
| P1-10 | ✅ 반영 | `_BadgesContent`에 빈 상태 안내 위젯(`Icons.emoji_events_outlined` + `badges.emptyHint`) 추가 |
| P1-11 | ✅ 반영 | 허브 그리드 `childAspectRatio`를 너비 360dp 기준 분기 (0.75 vs 0.85) |
| P1-12 | ✅ 반영 | 진행률/스트릭 Text에 `overflow: ellipsis, maxLines: 1` + Expanded 적용 |

검증: `flutter analyze` 에러 0건, 신규 회귀 테스트 실패 없음.

---

## 🟢 P2 (백로그 — 다음 메이저)

| # | 항목 | 영향 |
|---|---|---|
| P2-1 | 13게임 game_screen이 모두 200ms duration 사용 — easing 명시 없음(`Curves.easeInOut` 등 누락). 디폴트 linear에 가까울 수 있음 |
| P2-2 | 난이도 BottomSheet 핸들 width:40 height:4 일관 — 좋음. 다만 `withValues(alpha: 0.2)` 고정으로 라이트모드에서 거의 안 보이는 옅음 |
| P2-3 | 13게임 모두 `Icons.help_outline_rounded`로 도움말 통일 — 베스트 사례. 다만 sudoku만 `Icons.help_outline_rounded` + tutorial 별도 라우트 보유(다른 게임은 dialog), UX 패턴 분기 |
| P2-4 | 허브 하단 nav 버튼이 `InkWell` + `borderRadius:12`인데 게임별 홈의 버튼은 `ElevatedButton`/`OutlinedButton` — ripple 모양 다름 |
| P2-5 | 13게임 game_screen 31줄 `Scaffold(body: Center(CircularProgressIndicator))` 복붙 → 공통 `LoadingScaffold` 위젯으로 추출 권장 |
| P2-6 | 난이도 색상 9곳에 동일 switch 함수 복사 — 차후 `DifficultyTokens` 클래스로 추출 |
| P2-7 | 허브 상단 진행률 카드 `EdgeInsets.symmetric(horizontal:16, vertical:8)` + `Card padding all 16` → 외곽 16, 내부 16 = 32 통합 — 살짝 두꺼움. 24/12 등 시도 가능 |
| P2-8 | `_ContinueCard` 진행률 라벨이 스도쿠는 `${(progress * 100).toInt()}${AppStrings.get('home.progress')}`인 반면 비나이로는 `${(progress * 100).toInt()}%` 하드코딩 — 다국어 처리 차이 |
| P2-9 | 13게임 difficulty leading bar `width:4, height:36` 통일 — 좋음. 다만 라벨 굵기는 `FontWeight.bold`로만 (스도쿠 다른 패턴 가능성) |
| P2-10 | 카드 모서리 radius가 일부는 `BorderRadius.circular(12)`, 일부는 `8`, BottomSheet은 `20` — 디자인 시스템 토큰 부재 |
| P2-11 | 그림자: Material3 디폴트 `elevation` 사용 — 게임별 카드 elevation 명시 없음. 디자인 토큰 정의 권장 |
| P2-12 | `Colors.white12/24/38/54/60/70` 7단계 명도 — 다크모드 텍스트 hierarchy 일관성 점검 필요 (`onSurfaceVariant` 등 시맨틱 토큰 권장) |
| P2-13 | 게임 카드 emoji `fontSize:44` — emoji 폰트 굵기는 OS별 차이 발생. SVG 아이콘 대체 고려 |

---

## 차원별 평가 (10점 만점)

| 차원 | 점수 | 비고 |
|---|---|---|
| 픽셀 정렬 | 8/10 | 12 신규 게임 완벽 통일. 스도쿠만 padding/icon size 미세 차이 (P1-1~3) |
| 마이크로 인터랙션 | 7/10 | 200ms 일관 OK. easing 미명시, 햅틱 피드백 통합 점검 필요 |
| 타이포그래피 | 8/10 | `textTheme.titleMedium/bodyMedium` 토큰 사용 — 베스트 사례. 다만 일부 `TextStyle(fontSize:15)` 하드코딩 잔존 |
| 색상 시스템 | 6/10 | `colorScheme` 부분 사용. 난이도 색상 + 다크모드 텍스트 명도 다단계 하드코딩 (P1-5~8) |
| 상태 피드백 | 7/10 | 탭 ripple/누름 OK. **에러 상태 UI 없음** (P1-9) — 가장 약한 고리 |
| 빈 상태 | 7/10 | 통계 빈 상태 완성도 좋음. 배지 빈 상태 위젯 미확인 (P1-10), 허브 진행률 0/13 자연 노출 OK |
| 에러 상태 | 5/10 | catch 블록의 사용자향 UI 없음. 영구 스피너 위험 (P1-9) |
| 로딩 상태 | 6/10 | 스피너만 노출, "퍼즐 생성 중" 안내문 없음 (P1-4). 마스터 난이도에서 가장 문제 |
| 컨텍스트 손실 | 9/10 | `didChangeAppLifecycleState`로 13게임 모두 pause 처리 통일 — 베스트 사례 |
| 세부 마감 | 7/10 | BottomSheet 핸들/SafeArea/viewInsets 처리 우수. 다만 토큰화 부족, 13파일 복붙 코드 |
| **종합** | **70/100** | 릴리즈 가능 수준이지만 결벽적 시선에서는 첫 핫픽스 사이클 명확 |

---

## 베스트 사례 (유지해야 할 것)

- **13게임 BottomSheet 난이도 선택 패턴 통일** — 핸들 + 제목 + `isScrollControlled` + `viewInsets` 대응까지 동일 (R26~27 작업 결과 우수)
- **이어하기 카드 구조 통일** — 시간/모드칩/진행률 바/퍼센트 일관 (스도쿠/비나이로 모두)
- **`didChangeAppLifecycleState`로 13게임 모두 백그라운드 자동 pause** — 컨텍스트 손실 방지 (R22 작업 결과)
- **허브 카드 NEW/진행중 우선순위** — `inProgress > isNew` 명시적 분기, 라벨 색 의도 명확
- **`SafeArea(top: false) + viewInsets.bottom` 키보드/시스템바 대응** — 13게임 모두 적용
- **400+ 줄 home_screen이지만 책임 분리 (`_ContinueCard`/`_DifficultyTile`/`_RulesHint`/`_ChipLabel`)** — 가독성 우수

---

## 권장 출시 전 행동

- **블로커 0건** — 스토어 정식 릴리즈 진행 가능
- **출시 후 핫픽스 1.1.1 패치(1주 이내) 권장 항목**:
  1. **P1-1~3 (스도쿠 홈 토큰 통일)** — 가장 눈에 띄는 결벽 항목, 5분 작업
  2. **P1-4 (로딩 텍스트 추가)** — `AppStrings.get('common.generating')` 신설 + 13게임 game_screen 일괄 적용
  3. **P1-9 (에러 상태 UI)** — generator timeout 시 SnackBar + 재시도 버튼
  4. **P1-10 (배지 빈 상태 위젯)** — `_EmptyStats`와 같은 패턴으로 `_EmptyBadges` 추가
- **다음 메이저 1.2.0 계획**:
  - `DesignTokens` 클래스 신설 (난이도 색상/카드 radius/elevation/명도 단계)
  - 13게임 `LoadingScaffold` 공통 위젯 추출
  - 그리드 그리드/스페이싱 시스템 (4px base) 문서화

---

## 한 줄 결론

> **"13게임이 70%의 결벽성을 달성했다. 30%의 결벽은 v1.1.1 핫픽스로 마저 잡으면 90%에 도달한다.
> 지금 출시하라 — 단, 첫 핫픽스 사이클을 이미 예약해두라."**
