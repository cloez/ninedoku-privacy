# PM 핸즈오프 문서

> 작성일: 2026-06-01
> 목적: 새 세션의 PM 에이전트가 프로젝트를 즉시 이어받을 수 있도록 전체 맥락을 전달

---

## 1. 프로젝트 개요

**Ninedoku** — 완전 오프라인 모바일 논리 퍼즐 플랫폼 (Flutter)
- 현재 2개 게임(스도쿠 + 비나이로) 탑재, 총 13개로 확장 예정
- Play Store Alpha 비공개 테스트 중

### 절대 불변 제약
- INTERNET 권한 금지 (완전 오프라인)
- Firebase/광고/분석 SDK 금지
- 개인정보 수집 금지
- applicationId: `com.cloez.sudoku` (변경 불가)

---

## 2. 핵심 파일 위치

| 구분 | 경로 |
|------|------|
| 코드베이스 | `D:\00. Workspace\sudoku\` |
| 마스터 플랜 | `D:\00. Workspace\ninedoku-privacy\MASTER_PLAN.md` |
| PM 지침 (CLAUDE.md) | `D:\00. Workspace\sudoku\CLAUDE.md` |
| 에이전트 프롬프트 | `D:\00. Workspace\sudoku\agents\` (PM/GD/UX/DEV/QA/GC/UT.md) |
| 공통 QA 체크리스트 | `D:\00. Workspace\sudoku\test\GAME_QA_CHECKLIST.md` |
| 비나이로 QA 결과 | `D:\00. Workspace\sudoku\test\games\binairo\QA_CHECKLIST.md` |
| 게임 레지스트리 | `lib\core\engine\game_registry.dart` |
| 라우터 | `lib\app\router.dart` |
| 다국어 문자열 | `lib\shared\l10n\app_strings.dart` |
| 백업 서비스 | `lib\core\storage\backup_service.dart` |
| 통계 화면 | `lib\features\statistics\screens\statistics_screen.dart` |
| 배지 화면 | `lib\features\badges\screens\badges_screen.dart` |

---

## 3. 현재 상태

### 버전
- **pubspec.yaml**: `1.1.0+4`
- **Git 태그**: `v1.0.0-r0-complete`, `v1.1.0-r1-binairo`
- **커밋**: `d2b8e13` (최신)

### 릴리스 현황
| 릴리스 | 상태 | 테스트 | 비고 |
|--------|------|--------|------|
| R0 (Sudoku) | ✅ 완료 | 640개 | v1.0.0+3, Play Store Alpha |
| R1 (Binairo) | ✅ 완료 | 725개 (84개 신규) | v1.1.0+4, 실기기 APK 설치 완료 |
| R2 (Minesweeper) | ⏳ **다음 작업** | - | - |

### 미커밋 변경사항
- `CLAUDE.md` — 현재 상태 업데이트 (R1 완료, APK 설치 명령어 추가)
- `README.md` — 변경 있음
- `agents/` — 에이전트 프롬프트 7개 (신규, untracked)

### R1 미완료 항목 (Play Store 배포)
- [ ] Play Store AAB 업로드
- [ ] 스토어 설명/스크린샷 업데이트
- [ ] GitHub ninedoku-privacy 리포지토리 소스 동기화

---

## 4. R1 (비나이로) 완료 요약

### 구현된 것
- 비나이로 게임 엔진 (Board, Solver, Generator, Hint)
- 5단계 난이도: 6×6(입문) → 8×8(쉬움) → 10×10(보통) → 12×12(어려움) → 14×14(마스터)
- 이진 토글 입력 (●/○/지우개 모드) + 셀 탭 토글
- 게임 허브 화면 (카드 그리드)
- 통합 통계/배지 화면 (전체/스도쿠/비나이로 탭 필터)
- 배지 10개, 4단계 힌트, S/A/B/C 등급
- 백업/복원에 비나이로 데이터 포함
- 4개국어 (한/영/일/중)
- 공통 QA 체크리스트 프레임워크 수립

### R1에서 배운 교훈 (R2부터 반드시 적용)

| # | 교훈 | 상세 |
|---|------|------|
| 1 | **SharedPreferences 주입** | 게임별 별도 Provider 만들지 말고 `sharedPreferencesProvider`를 직접 watch. 별도 Provider는 null 기본값 → 배지/저장 미동작 |
| 2 | **힌트 기호** | 힌트 텍스트에 0, 1 등 숫자 금지. 게임 고유 기호(●, ○, ⚑ 등) 사용 필수 |
| 3 | **일시정지 통일** | 모든 게임의 일시정지 화면은 스도쿠와 동일해야 함. `pause.resume`/`pause.home`/`pause.giveUp` 공통 키 사용. "허브로" 표기 금지 |
| 4 | **결과 화면** | ConsumerStatefulWidget + initState에서 배지 팝업 + 결과 화면 내 배지 칩 섹션 |
| 5 | **AnimatedSize** | 힌트 메시지처럼 동적으로 나타나는 영역은 `AnimatedSize`로 감싸서 레이아웃 흔들림 방지 |
| 6 | **원/도형 크기** | 같은 종류 도형의 크기를 통일 (고정/비고정 구분 불필요) |
| 7 | **게임 홈 백키** | PopScope `canPop: false`. 허브 이동은 `Icons.apps_rounded` 아이콘으로만 |
| 8 | **lastGameRoute** | 게임 홈 initState에서 저장. 앱 재시작 시 마지막 게임으로 자동 복귀 |
| 9 | **라우터 테스트** | `initialLocationProvider` 오버라이드로 테스트별 시작 경로 지정 가능 |
| 10 | **이름 통일** | 게임 이름은 처음부터 하나로 확정. 혼용(바이네리/바이너리/비나이로) 방지 |

---

## 5. 기술 아키텍처

### 기술 스택
- Flutter 3.44.0 + Dart 3.12.0
- Riverpod (StateNotifier + StateNotifierProvider)
- go_router
- SharedPreferences (전 게임 공용)
- minSdk 31 (Android 12+), targetSdk 35

### 게임 추가 패턴 (플러그인 구조)
```
1. lib/games/{게임명}/ 폴더 생성 (engine/, screens/, widgets/)
2. game_registry.dart에 GameInfo 추가
3. router.dart에 경로 추가
4. app_strings.dart에 4개국어 문자열 추가
5. backup_service.dart에 completedGames + badges 키 추가
6. statistics_screen.dart / badges_screen.dart에 탭 추가
```

### 인터랙션 패턴 (3가지만 허용)
- **패턴 A: 이진 토글** — Binairo, Yin-Yang, Minesweeper(깃발), Star Battle 등
- **패턴 B: 숫자 입력** — Sudoku, Killer Sudoku, Futoshiki 등
- **패턴 C: 노노그램 전용** — 드래그 채우기

### 라우팅 구조
```
/hub                  → 게임 허브
/                     → 스도쿠 홈
/game                 → 스도쿠 플레이
/binairo              → 비나이로 홈
/binairo/game         → 비나이로 플레이
/statistics           → 통계 (extra로 탭 선택)
/badges               → 배지 (extra로 탭 선택)
/settings             → 설정
```

### 빌드 명령어
```bash
# 테스트
export PATH="/d/flutter/bin:$PATH" && export TEMP="/d/temp" && export TMP="/d/temp" && cd "/d/00. Workspace/sudoku" && flutter test

# AAB 빌드
export PATH="/d/flutter/bin:$PATH" && export PUB_CACHE="/d/pub-cache" && export ANDROID_SDK_ROOT="D:/Android/SDK" && export TEMP="/d/temp" && export TMP="/d/temp" && cd "/d/00. Workspace/sudoku" && flutter build appbundle --release

# APK + 실기기 설치 (USB)
export PATH="/d/flutter/bin:$PATH" && export PUB_CACHE="/d/pub-cache" && export ANDROID_SDK_ROOT="D:/Android/SDK" && export TEMP="/d/temp" && export TMP="/d/temp" && cd "/d/00. Workspace/sudoku" && flutter build apk --release && "D:/Android/SDK/platform-tools/adb.exe" install -r "build/app/outputs/flutter-apk/app-release.apk"
```

> ⚠️ `PUB_CACHE="/d/pub-cache"` — 사용자 이름에 한글이 포함되어 기본 경로가 작동하지 않음

---

## 6. 7+1단계 프로세스 요약

```
STEP 1 (GD 기획서) → PM 승인
STEP 2 (UX 명세)   → GD + PM 승인
STEP 3 (DEV 엔진)  → QA 검증
STEP 4 (DEV UI)    → UX + QA 검증
STEP 5 (QA 통합)   → PM 승인 (71개+ 테스트, 체크리스트 전항목)
STEP 6 (GC 리뷰)   → PM 승인 (8차원 평가, PASS/COND/FAIL)
STEP 6.5 (UT 10명) → GD + UX + PM 합의 (피드백 대응 완료)
STEP 7 (빌드/배포)  → AAB + Play Store + GitHub + MASTER_PLAN 업데이트
```

**에이전트 프롬프트 파일**: `agents/PM.md`, `GD.md`, `UX.md`, `DEV.md`, `QA.md`, `GC.md`, `UT.md`
→ 각 STEP에서 해당 에이전트 프롬프트를 참조하여 역할 수행

---

## 7. R2 (Minesweeper) 착수 가이드

### 마스터 플랜에 정의된 R2 작업

```
R2: Minesweeper (v1.2) — 예상 2주
- 인터랙션: 배치 (패턴 A 변형: 탭 열기, 길게누르기 깃발)
- 교차 배치: R1(이진) → R2(배치) ✅ 유형 다름
```

### R2 시작 전 PM 확인 사항
1. [ ] R1 미완료 항목(Play Store 업로드 등)에 대해 사용자와 확인 — 병행 or 순차
2. [ ] `agents/` 폴더와 CLAUDE.md 변경사항 커밋 여부 확인
3. [ ] MASTER_PLAN.md의 R2 섹션 작업 목록 재확인
4. [ ] GD에게 STEP 1 착수 요청

### R2 예상 파일 구조
```
lib/games/minesweeper/
  ├── engine/
  │   ├── minesweeper_board.dart
  │   ├── minesweeper_solver.dart
  │   ├── minesweeper_generator.dart
  │   └── minesweeper_hint.dart
  ├── screens/
  │   ├── minesweeper_home_screen.dart
  │   └── minesweeper_game_screen.dart
  ├── widgets/
  │   └── minesweeper_board_widget.dart
  ├── minesweeper_state.dart
  ├── minesweeper_notifier.dart
  ├── minesweeper_storage_service.dart
  ├── minesweeper_badge_service.dart
  └── minesweeper_badge_definitions.dart

test/games/minesweeper/
  ├── minesweeper_engine_test.dart    (≥30개)
  ├── minesweeper_state_test.dart     (≥12개)
  ├── minesweeper_notifier_test.dart  (≥15개)
  ├── minesweeper_storage_test.dart   (≥8개)
  ├── minesweeper_backup_test.dart    (≥6개)
  └── QA_CHECKLIST.md
```

### R2 특이사항 (마스터 플랜 참조)
- **논리적 풀이 가능 보장**: "찍기 없는 지뢰찾기" — 모든 퍼즐이 논리만으로 풀려야 함
- **첫 클릭 안전 보장**: 첫 번째로 여는 셀은 반드시 안전
- **연쇄 오픈 애니메이션**: 빈 칸 주변 자동 오픈 시 시각 효과
- **난이도**: 8×8(입문) → 10×10(쉬움) → 12×12(보통) → 16×16(어려움)
- **라우팅**: `/minesweeper` (홈), `/minesweeper/game` (플레이)

---

## 8. PM 첫 번째 행동

새 세션에서 PM으로 활동을 시작하려면:

```
1. CLAUDE.md를 읽어 PM 지침을 로드한다
2. MASTER_PLAN.md를 읽어 전체 로드맵과 현재 상태를 확인한다
3. agents/ 폴더의 프롬프트를 확인한다
4. 이 HANDOFF.md의 내용을 숙지한다
5. 사용자에게 현재 상태를 보고하고 다음 행동을 제안한다:
   - R1 잔여 작업(Play Store 배포) 처리 여부
   - 미커밋 변경사항(CLAUDE.md, agents/) 커밋 여부
   - R2 착수 여부
```

### PM 보고 템플릿
```
📋 [현재 릴리스]: R1 (Binairo) ✅ 완료 / R2 (Minesweeper) 대기
📍 [현재 단계]: R1 STEP 7 잔여 (Play Store 업로드) / R2 미착수
👥 [가용 에이전트]: PM, GD, UX, DEV, QA, GC, UT

---
[상황 보고]
---

⏭️ [제안]: R2 착수 시 STEP 1(GD 기획서)부터 시작
```

---

## 9. 참고: Git 이력

```
d2b8e13 Unify pause screen strings and add QA checklist for pause consistency
ae9c87d Add common QA checklist + Binairo comprehensive tests (84 tests)
210fe68 R1: Add Binairo game + Game Hub (v1.1.0+4)
be60eab Update PM guidelines: consensus-based decision making
51e40f9 Initial commit: Sudoku v1.0.0+3 complete

태그:
  v1.0.0-r0-complete  ← 스도쿠 완료 시점
  v1.1.0-r1-binairo   ← 비나이로 완료 시점
```
