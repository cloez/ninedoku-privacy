# 게임 필링(Game Feel) 격차 분석 — 스도쿠

> 분석가: 모바일 게임 필링 전문가 (Steve Swink 학파, 15년차)
> 트리거: 사용자 "다른 스도쿠가 훨씬 익싸이팅하다" 피드백
> 분석일: 2026-06-15
> 코드베이스: D:\00. Workspace\sudoku (v1.0.1+5)

---

## 종합 진단

### 한 줄 요약
현재 Ninedoku 스도쿠는 **규칙(Rules)·논리(Logic)·정보 표시(Context)는 시장 평균 이상**이지만, Steve Swink가 말하는 "Polish" 레이어 — 즉 **입력 순간의 감각적 보상(시각 미세 변화·사운드·입자 효과)** 이 거의 비어 있다. 햅틱은 있으나 사운드는 시스템 `SystemSound.click` 한 종류뿐이고, 셀 입력/완성/오답/배지 획득의 *시각적 카타르시스*가 정적 색 변경에 머물러 "익싸이팅" 격차의 정확한 진원지가 된다.

### 격차 점수 (10점 만점)

| 차원 | 우리 | 시장 평균 | Sudoku.com | 격차 |
|---|---|---|---|---|
| 입력 피드백 (Input Feedback) | 4/10 | 7/10 | 9/10 | **-5** |
| 진행 시각화 (Progress) | 6/10 | 7/10 | 8/10 | -2 |
| 완성 보상 (Completion Reward) | 3/10 | 8/10 | 9/10 | **-6** |
| 마이크로 인터랙션 | 5/10 | 7/10 | 9/10 | **-4** |
| 사운드 디자인 | 1/10 | 7/10 | 9/10 | **-8** |
| 게이미피케이션 | 5/10 | 7/10 | 9/10 | -4 |
| **종합** | **24/60** | **43/60** | **53/60** | **-29** |

> **핵심 격차 = 사운드(-8) + 완성 보상(-6) + 입력 피드백(-5)**. 이 3개에 집중하면 격차의 65%를 즉시 회수할 수 있다.

---

## 1. 차원별 상세 분석

### 1.1 입력 피드백 (Input Feedback) — 4/10

**현재 상태**
- 햅틱: `lib/core/utils/feedback_service.dart` — `onNumberInput()` → `HapticFeedback.lightImpact()` ✅
- 사운드: `SystemSound.play(SystemSoundType.click)` — OS 기본음(소음 수준)
- 셀 입력 시 시각 변화: 색 즉시 교체뿐, **애니메이션 0ms** (`sudoku_board_widget.dart:160-170` — 평범한 `Text` 위젯)
- 숫자 패드 누름 효과: `InkWell` 머티리얼 ripple만 (`number_pad_widget.dart:242`)
- 같은 숫자 하이라이트: ✅ 정적 색만 (`AppColors.cellSameNumberLight`), 펄스 없음
- 정답 셀 글로우: ❌ 없음

**격차**
- Sudoku.com 표준: 셀에 숫자 입력 → 텍스트 **스케일 1.0 → 1.25 → 1.0 (150ms, easeOutBack)** + 셀 배경 **flash(120ms)**
- 같은 숫자가 전 보드에서 *한 번 더 펄스* (0.85 → 1.0, 200ms)
- 우리는 입력해도 "정적 갱신"으로 보여 **터치-감각 단절(disconnect)** 발생

**증거 (코드)**
- `lib/features/game/widgets/sudoku_board_widget.dart:160-170` — 정적 Text
- `lib/features/game/widgets/sudoku_board_widget.dart:82-100` — 색 즉시 결정, 트랜지션 없음
- `lib/core/utils/feedback_service.dart:42-45` — 시스템 클릭만 재생

---

### 1.2 진행 시각화 (Progress Visualization) — 6/10

**현재 상태**
- 남은 빈 칸 수 표시: ✅ `game_info_bar.dart:33-38`
- 숫자별 남은 개수: ✅ `number_pad_widget.dart:340-348` (각 숫자 버튼 하단)
- 9개 완성 숫자 체크마크: ✅ (초록 ✓)
- 진행률 바: ❌ 없음
- 시간 압박 시각화: ❌ (타이머 텍스트만, 도전 모드 실수 카운트도 텍스트)

**격차**
- 시장 표준: 화면 상단 **얇은 progress bar** (81셀 중 채워진 비율, 그라데이션) — 0.5초 ease로 부드럽게 차오름
- 도전 모드: 실수 슬롯 3개를 **하트/별 아이콘**으로 표시 → 실수 시 깨지는 애니메이션 (Royal Match 패턴)
- 우리는 숫자(0/3, 1/3)만 → "퀘스트 게이지" 체감 0

**증거**
- `lib/features/game/widgets/game_info_bar.dart:41-48` — 텍스트 카운트만
- `lib/features/game/widgets/number_pad_widget.dart:340` — 숫자 카운트 미니 텍스트

---

### 1.3 완성 보상 (Completion Reward) — 3/10

**현재 상태** (`result_screen.dart`)
- 트로피 아이콘 (`Icons.emoji_events_rounded`, 정적, 크기 72)
- 등급 배지 박스 (스케일/회전 없음, `_GradeBadge` 정적)
- 통계 카드 (시간/난이도/실수/힌트) — **숫자 그냥 표시** (카운트업 0)
- 새 배지: `Chip` 형태로 표시 + `AlertDialog` 팝업 (이모지 🎉만)
- 자동완성 애니메이션: ✅ 300ms 간격 순차 표시 (`game_notifier.dart:450-479`) — 유일한 좋은 시각 연출

**격차**
- 시장 표준 완성 컷씬:
  1. 보드 셀들이 **순차적으로 빛남** (이미 있음, 1.5초)
  2. **콘페티 입자** 폭발 (0~2초, 50~100개)
  3. 트로피 **스케일 0 → 1.3 → 1.0 + 회전 -15° → 0°** (elasticOut 600ms)
  4. 타이머 숫자 **0초 → 실제값 카운트업** (1초 동안)
  5. 등급별 차등 **사운드+화면 글로우** (S: 금색 빛 페이드, A: 파랑 글로우)
- 배지 획득: 별 입자 + 스케일 1.5 + 회전 360° + 글로우 펄스 → 현재는 AlertDialog (단조)

**증거**
- `lib/features/game/screens/result_screen.dart:108-119` — 정적 Icon + Text
- `result_screen.dart:128-155` — `_StatRow`는 트랜지션 없는 텍스트
- `result_screen.dart:37-76` — 배지 다이얼로그는 표준 `AlertDialog` 그대로

---

### 1.4 마이크로 인터랙션 — 5/10

**현재 상태**
- 행/열/박스 옅은 하이라이트: ✅ (`sudoku_board_widget.dart:248-257`)
- 같은 숫자 하이라이트: ✅ 정적
- 잘못된 입력 시 셀 흔들기: ❌ 빨강 텍스트로만 표시
- 릴렉스 모드 오답 플래시: ✅ 500ms 붉은 배경 (`sudoku_board_widget.dart:89-91`) — 좋음
- 정답 입력 글로우: ❌
- 박스/행/열 완성 시 펄스: ❌
- 추임새: ✅ `Encouragement.good/excellent/perfect` (`encouragement_widget.dart`) — 좋음

**격차**
- 잘못된 입력 시 **horizontal shake** (좌우 ±6px, 80ms × 3회) + 빨강 펄스 — 표준
- 행/열/박스 완성 시 **셀별 순차 하이라이트 wave** (각 9개 셀 100ms 간격, 노란빛 펄스)
- 정답 셀에 **드롭 인** (위에서 떨어지듯 y: -10 → 0, 200ms)

**증거**
- `lib/features/game/game_notifier.dart:222` — 오답 시 햅틱만, shake 없음
- `sudoku_board_widget.dart` 전체 — Row/Col/Box 완성 감지 후 액션 트리거 없음

---

### 1.5 사운드 디자인 — 1/10 ⚠️ **최대 격차**

**현재 상태**
- `pubspec.yaml`: `audioplayers`, `just_audio`, `soundpool` 등 **사운드 패키지 0개**
- `assets/` 디렉토리에 사운드 파일 0개 (pubspec.yaml:67 assets 단일 항목)
- 유일한 사운드: `SystemSound.play(SystemSoundType.click)` (OS 기본 부저, 거슬릴 수 있음)

**격차**
시장 표준 사운드 팔레트 (8~12 SFX):
| 이벤트 | SFX | 길이 |
|---|---|---|
| 셀 선택 | soft tap | 30ms |
| 숫자 입력 정답 | 부드러운 틱 (피치 살짝 ↑) | 80ms |
| 오답 | 가벼운 부저 (저음 thud) | 150ms |
| 메모 토글 | pencil tick | 40ms |
| 행/열 완성 | 짧은 차임 (5음표) | 400ms |
| 박스 완성 | 글래스 ding | 500ms |
| 게임 완성 | 팡파레 | 1.2s |
| 퍼펙트 | 빛나는 chord + 박수 | 2s |
| 배지 획득 | 별 + 스파클 | 800ms |
| 힌트 사용 | magical chime | 300ms |
| 카운트다운(도전) | 째깍 (5초 이하) | 100ms |
| BGM (옵션) | 명상 루프 | 60~120s |

**증거**
- `pubspec.yaml:9-40` — 의존성에 audioplayers 류 패키지 부재
- `lib/core/utils/feedback_service.dart:42-45` — `SystemSound.click`만 호출
- `assets/` 폴더에 음원 파일 부재

---

### 1.6 게이미피케이션 — 5/10

**현재 상태**
- 등급 시스템: ✅ S/A/B/C (`Grade` enum, `result_screen.dart`)
- 배지: ✅ `BadgeService`, `BadgeDefinitions`
- 일일 퍼즐: ✅ `DailyPuzzleService`
- 도전 모드: ✅ 실수 3개 제한
- 콤보/스트릭: ❌
- 레벨/경험치: ❌
- 시즌 테마: ❌
- 추임새: ✅ Encouragement (`good/excellent/perfect`)

**격차**
- 시장 표준: **연속 정답 콤보** ("3 연속!", "5 연속!"), 연속 일일 완료 스트릭(🔥 N일 표시), 주간 경험치 바
- Wordscapes/Royal Match: 게임 외부에서 도전 과제 진행 게이지 → 우리는 배지(이진)뿐
- 오프라인 제약상 외부 리더보드 불가하지만 *자체 메타 진행*은 가능

---

## 2. 개선 로드맵

### Wave 1 — 즉시 효과 (1주, 적은 코드 변경 큰 임팩트)

| # | 항목 | 차원 | 예상 임팩트 | 작업량 |
|---|---|---|---|---|
| W1-1 | 셀 입력 시 텍스트 스케일 애니 (1.0→1.25→1.0, 150ms, easeOutBack) | 입력 피드백 | ★★★★★ | XS (1파일, AnimatedScale 래핑) |
| W1-2 | 오답 시 셀 horizontal shake (±6px, 80ms×3) | 마이크로 | ★★★★ | XS (TweenAnimation) |
| W1-3 | 같은 숫자 하이라이트 펄스 (alpha 0.6→1.0→0.6, 600ms loop) | 입력 피드백 | ★★★ | XS (AnimatedContainer) |
| W1-4 | 진행률 바 (상단 얇은 LinearProgressIndicator, 81-empty/81) | 진행 시각화 | ★★★ | XS (game_info_bar에 추가) |
| W1-5 | 도전 모드 실수 슬롯 하트 아이콘 (3개 → 실수 시 깨지는 fade) | 진행 시각화 | ★★★ | S |
| W1-6 | 결과 화면 통계 카운트업 (`AnimatedDigit`, 0→실제값, 1s) | 완성 보상 | ★★★★ | S |
| W1-7 | 트로피 아이콘 스케일+회전 등장 (elasticOut, 600ms) | 완성 보상 | ★★★ | XS |
| W1-8 | 등급별 색 글로우 (배경 RadialGradient 페이드 인) | 완성 보상 | ★★★ | S |

**Wave 1 총 작업량**: ~3~4일 (1인 DEV), **격차 회수 추정 -29 → -18**

---

### Wave 2 — 중간 임팩트 (2주)

| # | 항목 | 차원 | 예상 임팩트 | 작업량 |
|---|---|---|---|---|
| W2-1 | **사운드 시스템 구축** — `audioplayers` 도입 + 8개 SFX 자산 + `FeedbackService` 확장 | 사운드 | ★★★★★ | M (자산 제작 + 코드) |
| W2-2 | 콘페티/입자 효과 (`confetti` 패키지) — 게임 완성 시 2초 폭발 | 완성 보상 | ★★★★ | S |
| W2-3 | 행/열/박스 완성 감지 + 셀별 wave 펄스 (100ms 간격, 9셀) | 마이크로 | ★★★★ | M (`game_notifier`에 감지 로직 + 위젯 트리거) |
| W2-4 | 배지 획득 팝업 리워크 — 스케일+회전+스파클 (커스텀 다이얼로그) | 완성 보상 | ★★★ | M |
| W2-5 | 콤보 시스템 — 연속 정답 카운트 + 우측 상단 floating "x3 콤보!" | 게이미피케이션 | ★★★ | M |
| W2-6 | 도전 모드 마지막 5초 카운트다운 (시각 + 사운드) | 진행 시각화 | ★★★ | S |

**Wave 2 총 작업량**: ~10~12일, **격차 회수 추정 -18 → -8**

---

### Wave 3 — 메이저 업데이트 (1개월)

| # | 항목 | 차원 | 예상 임팩트 | 작업량 |
|---|---|---|---|---|
| W3-1 | 일일 스트릭(🔥 N일) + 주간 경험치 바 + 시즌 테마(여름/가을…) | 게이미피케이션 | ★★★★★ | L |
| W3-2 | BGM 시스템 (3~5트랙 루프, 끄기 토글, 페이드 in/out) | 사운드 | ★★★ | M |
| W3-3 | 게임 완료 컷씬 (보드 zoom out + 폭죽 + 등급별 컬러 테마) | 완성 보상 | ★★★★ | L |
| W3-4 | 햅틱 패턴 라이브러리 확장 (`vibration` 패키지 — 커스텀 패턴) | 입력 피드백 | ★★ | S |
| W3-5 | 일일 도전 과제 (오늘의 미션: "실수 0", "5분 내", "힌트 무사용") + 진행 게이지 | 게이미피케이션 | ★★★★ | L |

**Wave 3 총 작업량**: ~3주, **격차 회수 추정 -8 → -2** (Sudoku.com 근접)

---

## 3. 우선순위 매트릭스

```
높은 임팩트
    ↑
    │ [W1-1] 셀 입력 스케일 애니        │ [W2-1] 사운드 시스템 (★★★★★)
    │ [W1-6] 통계 카운트업             │ [W2-3] 행/열/박스 완성 wave
    │ [W1-2] 오답 shake               │ [W2-2] 콘페티 완성 연출
    │ [W1-7] 트로피 등장 애니          │ [W3-1] 스트릭 + 시즌
    │ [W1-4] 진행률 바                │ [W3-3] 완료 컷씬
────┼─────────────────────────────────┼─────────────────────────────
    │ [W1-3] 같은 숫자 펄스            │ [W2-5] 콤보
    │ [W1-5] 하트 슬롯                │ [W2-4] 배지 팝업 리워크
    │ [W1-8] 등급 글로우              │ [W3-5] 일일 미션
낮은 임팩트                            │ [W3-2] BGM
    │                                │ [W3-4] 햅틱 확장
    └─── 적은 작업 ──────── 큰 작업 ───→
```

**PM 추천 진행 순서**:
1. **즉시 (스프린트 1주)**: W1 전체 → 빠른 가시 효과, 사용자 재평가
2. **다음 (2주)**: W2-1(사운드) + W2-2(콘페티) + W2-3(완성 wave) — 3개로 격차 70% 해소
3. **분기 (1개월)**: W3-1(스트릭) + W3-3(컷씬) — 리텐션 강화

---

## 4. 13게임 공통 적용 가능성

| Wave 항목 | sudoku | binairo | minesweeper | yin_yang | nonograms | killer | star_battle | light_up | futoshiki | tents | jigsaw | skyscrapers | kakuro | 효과 게임 수 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| W1-1 셀 입력 스케일 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| W1-2 오답 shake | ✅ | ✅ | ❌ (즉사) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 12/13 |
| W1-3 같은 숫자 펄스 | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ | 7/13 |
| W1-4 진행률 바 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| W1-5 하트 슬롯 | ✅ (도전) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| W1-6 통계 카운트업 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| W1-7 트로피 등장 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| W2-1 사운드 시스템 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| W2-2 콘페티 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| W2-3 행/열/박스 wave | ✅ | ✅ (행/열) | ❌ | ✅ (행/열) | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ | 10/13 |
| W2-5 콤보 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| W3-1 스트릭/시즌 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |

→ **W1-1, W1-4, W1-7, W2-1, W2-2의 ROI는 13배**. 공통 위젯/서비스로 1회 구현하면 전 게임 적용.

**아키텍처 권고**: `lib/shared/widgets/`에 `AnimatedCell`, `CompletionConfetti`, `AnimatedTrophy`, `ProgressBar`, `LifeSlots` 신설. `FeedbackService`를 확장해 `onRowComplete()`, `onComboHit(int n)`, `onPerfect()` 추가.

---

## 5. 위험/주의사항

| 위험 | 영향 | 완화책 |
|---|---|---|
| **저성능 폰 프레임 드랍** (Wave 2-3 입자) | 60fps 미달, 발열 | `RepaintBoundary` 적극 사용, 파티클 50개 이하, 옵션 토글 "이펙트 줄이기" |
| **사운드 파일 용량 증가** | APK 크기 ↑ (현재 ~25MB) | OGG Vorbis 64kbps, 총 12개 SFX < 500KB 목표. BGM은 별도 다운로드 옵션 |
| **"너무 화려해서 산만"** | 노년/포커스 사용자 이탈 | 설정에 "이펙트 끄기", "사운드 끄기" 분리 토글 (햅틱과 독립) |
| **다크 모드 호환** | 글로우/색 부조화 | 모든 신규 색은 `AppColors` 다크/라이트 페어로 |
| **오프라인 원칙 (INTERNET 금지)** | 자산 다운로드 불가 | 모든 SFX/BGM 앱 번들 포함 (assets/) |
| **개인정보 수집 없음** | 외부 리더보드 불가 | 게이미피케이션은 *자체 메타* (로컬 스트릭/시즌)만 |
| **하드웨어 백키** | 컷씬 중 백키 → 크래시 위험 | 컷씬 진행 중 `PopScope canPop: false` + 스킵 가능 |
| **4개국어 카피** | 새 콤보/스트릭 문구 누락 | `app_strings.dart`에 ko/en/ja/zh 동시 추가 (공통 QA H 항목) |
| **테스트 회귀** | 애니메이션 도입 시 위젯 테스트 깨짐 | `FlutterTestBinding` `pumpAndSettle` 사용, `Duration.zero` 테스트 모드 |

---

## 6. 권장 다음 사이클 (PM 합의 대상)

### 옵션 A — 빠른 회수 (추천)
- **Wave 1만 1주 스프린트** → 사용자 재테스트(UT 5인) → 효과 검증 → Wave 2 진입 결정
- 장점: 위험 낮음, 빠른 학습
- 단점: 사운드 부재(-8)는 그대로

### 옵션 B — 격차 본격 해소
- **Wave 1 + W2-1(사운드) + W2-2(콘페티)** 2.5주 묶음 → 격차 -29 → -10
- 장점: 임팩트 큰 사운드 동시 해결
- 단점: 사운드 자산 제작 리드타임(외주 or AI 생성)

### 옵션 C — 메이저 업데이트 v1.2.0
- **Wave 1+2+3 전체** 4~5주 → v1.2.0 "Juice Update"로 마케팅
- 장점: Sudoku.com 근접
- 단점: 다른 신규 게임 일시 보류

### PM 합의 필요 항목
1. **Wave 선택** (A/B/C) — GD + UX + 사용자
2. **사운드 자산 출처** — AI 생성 vs 라이선스 구매 vs 외주 (DEV + PM)
3. **이펙트 토글 위치** — 설정 화면 신설 섹션 vs 기존 사운드/햅틱 그룹 내 (UX)
4. **v1.2.0 vs v1.1.x 패치** — 마케팅/스토어 영향 (PM)
5. **테스트 기준 갱신** — 애니메이션 단위 테스트 정책 (QA)

---

## 부록 — 적용 예시 코드 스케치 (W1-1 셀 입력 스케일)

```dart
// lib/features/game/widgets/sudoku_board_widget.dart 의 _buildNumberText 교체
Widget _buildNumberText(...) {
  return TweenAnimationBuilder<double>(
    key: ValueKey('$row-$col-$value'), // 값 변경 시 재실행
    tween: Tween(begin: 0.6, end: 1.0),
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutBack,
    builder: (context, scale, child) => Transform.scale(
      scale: scale,
      child: child,
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text('$value', style: TextStyle(...)),
    ),
  );
}
```

— 끝 —
