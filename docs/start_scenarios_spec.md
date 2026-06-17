# K-Puzzles 시작 시나리오 UX 명세

작성자: UX 기획자 (UX) | 대상: PM, DEV, GD
범위: 13개 게임 일반화 | 코드 변경 금지(명세만)

---

## 1. 4가지 시나리오 흐름

### S1. 앱 최초 시작
```
AppLaunch → NativeSplash(0~500ms) → FlutterSplash(3s, K 애니메이션)
→ settings.isFirstLaunch == true
→ /onboarding (4페이지) → [완료/스킵] → /hub (GameHubScreen)
→ isFirstLaunch = false 저장
```

### S2. 게임 시작 (허브에서 게임 진입)
```
/hub → [게임 카드 탭 (gameId)]
→ settings.tutorialSeen[gameId] == false?
   ├─ true  : /tutorial/:gameId (push) → [완료/스킵]
   │           → tutorialSeen[gameId] = true 저장
   │           → /{game}-home (replace)
   └─ false : /{game}-home (push)
→ 진입 즉시 settings.lastGameRoute = '/{game}-home' 저장
```

### S3. 앱 두 번째 이상 시작
```
AppLaunch → NativeSplash → FlutterSplash(3s)
→ settings.isFirstLaunch == false && lastGameRoute != null
→ lastGameRoute(=게임 home screen) 로 replace
→ (lastGameRoute 없음) → /hub
```

### S4. 게임 메인화면 도움말 진입점
```
[{Game}HomeScreen AppBar]
[← back] {게임명}   [?] [⚙]
→ [?] 탭 → showModalBottomSheet (90% height, draggable)
   → TutorialScreen(gameId, embedded:true)
   → [닫기] dismiss → 원위치 복귀
```

---

## 2. 시나리오 2 — 자동 튜토리얼 로직

- 키 구조: `settings.tutorialSeen: Map<String, bool>` (SharedPreferences JSON 직렬화)
- 게임 카드 탭 → `_onGameTap(gameId)`:
  1. `if (!tutorialSeen[gameId])` → `/tutorial/:gameId` push
  2. TutorialScreen 마지막 페이지에 **"다음에 다시 표시 안함"** 체크박스(기본 ON)
  3. [시작] 탭 → 체크 ON이면 `tutorialSeen[gameId] = true` 저장 → home으로 replace
  4. 스킵 버튼은 우상단 상시 노출 (강제 금지)

---

## 3. 시나리오 3 — 마지막 게임 자동 진입

- `lastGameRoute` 는 항상 **게임 home screen 경로**만 저장 (`/binairo`, `/sudoku` 등). game screen(`/binairo/game`) 은 저장하지 않음 — 진행중 퍼즐은 home에서 "이어하기" 카드로 노출
- 저장 시점: 게임 home screen `initState` 진입 시
- 합의 필요 (아래 8번 참조)

---

## 4. 시나리오 4 — 도움말 진입점

| 항목 | 명세 |
|---|---|
| 위치 | 모든 `{Game}HomeScreen` AppBar actions, Settings(⚙) **왼쪽** |
| 아이콘 | `Icons.help_outline` (24dp, AppBar foreground 색) |
| 라벨(a11y) | "게임 방법" (i18n: ko/en/ja/zh) |
| 동작 | `showModalBottomSheet(isScrollControlled:true, useSafeArea:true)` |
| 컨텐츠 | `TutorialScreen(gameId, embedded:true)` 재사용 — 풀스크린 라우트와 동일 페이지/카피 |
| 닫기 | 상단 핸들 드래그 + 우상단 닫기 버튼 |

선정 사유: 풀스크린 다이얼로그는 컨텍스트 단절감, 바텀시트는 home 복귀 자연스러움.

---

## 5. 라우터 변경 명세 (DEV용)

`lib/app/router.dart`:
- 신규 상수: `static const tutorial = '/tutorial/:gameId';`
- 신규 라우트:
  ```
  GoRoute(path: '/tutorial/:gameId',
    builder: (c,s) => TutorialScreen(gameId: s.pathParameters['gameId']!))
  ```
- `redirect` 로직 변경: 게임 카드 탭은 **redirect로 처리하지 말 것** (UX 명세서대로 카드 onTap에서 분기). redirect는 가시성/예측성이 낮음.
- `effectiveInitial`: 기존 로직 유지 (`lastGameRoute` 우선). 단 splash 페이드 후 splash 내부에서 push (현재 동일).

---

## 6. settings 모델 확장 명세

`lib/core/settings/settings_service.dart`:
| 필드 | 타입 | 키 | 기본값 | 설명 |
|---|---|---|---|---|
| `tutorialSeen` | `Map<String,bool>` | `tutorial_seen_v1` | `{}` | 게임별 튜토리얼 본 여부 (JSON 문자열로 저장) |
| `setTutorialSeen(gameId,bool)` | method | - | - | upsert + save |
| `isTutorialSeen(gameId)` | getter | - | `false` | null-safe |

기존 `lastGameRoute` 는 유지하되 게임 home 경로만 set 하도록 호출 지점 통일.

---

## 7. UI 명세 — 게임 카드 탭 흐름

```
[GameHubScreen]
  └ GameCard(onTap: () => _openGame(ctx, 'binairo'))

_openGame(ctx, id):
  final s = ref.read(settingsProvider);
  if (!s.isTutorialSeen(id)) {
    context.push('/tutorial/$id');
  } else {
    context.push(homeRouteOf(id));
  }
```

`/tutorial/:gameId` 종료(시작 버튼) → `context.pushReplacement(homeRouteOf(gameId))` + tutorialSeen 저장.

---

## 8. 합의 필요 안건 (PM 결정 요청)

| # | 안건 | UX 추천 | 선택지 |
|---|---|---|---|
| Q1 | S1에서 4페이지 온보딩 유지? | **유지** (브랜드/오프라인/프라이버시 메시지 가치) | 유지 / 제거 / 1페이지 축약 |
| Q2 | S3의 "메인화면" 정의 | **home screen** (모드/난이도 선택) | home / game screen(즉시 재개) |
| Q3 | S4 도움말 형식 | **모달 바텀시트** | 바텀시트 / 풀스크린 다이얼로그 |
| Q4 | "다시 표시 안함" 위치 | **튜토리얼 마지막 페이지** 체크박스(기본 ON) | 마지막 페이지 / 첫 페이지 / 옵션 없음(항상 1회) |
| Q5 | 스킵 허용 | **허용** (우상단 상시) | 허용 / 마지막 페이지에서만 |
| Q6 | 튜토리얼 다국어 | **4개국어 필수 (ko/en/ja/zh)** | 필수 / ko 우선 후속 |
| Q7 | 허브 경유 없이 S3 진입 시 "허브로" 버튼 위치 | **{Game}HomeScreen AppBar 좌측 back** = 허브 이동 | back=허브 / 별도 홈 아이콘 |

GD/DEV/QA 의견 수렴 후 확정 → 본 명세 v1.1 업데이트.

---

## 9. 13게임 일반화 체크

- 모든 게임은 `{game}HomeScreen` 존재 (확인됨: binairo, minesweeper, yin_yang, nonograms, killer_sudoku, star_battle, light_up, futoshiki, tents, jigsaw_sudoku, skyscrapers, kakuro + sudoku)
- 라우트 매핑 함수 `homeRouteOf(gameId)` 를 `AppRoutes`에 신설하여 13개 케이스 일괄 처리
- TutorialScreen은 `gameId` 파라미터화 — 게임별 페이지 콘텐츠는 `assets/tutorials/{gameId}.json` 또는 위젯 맵으로 분리

---

끝.
