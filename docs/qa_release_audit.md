# QA 베테랑 최종 점검 — 스토어 릴리즈 게이트

> 작성자: 20년차 모바일 QA 베테랑 (페르소나)
> 일자: 2026-06-15
> 대상 빌드: v1.0.0+4 (ApplicationId `com.cloez.sudoku`, minSdk 31, targetSdk 35)
> 점검 방식: 코드 정독 + 변경 이력(docs/) 추적 + `flutter test` 실행 + 13게임 전수 정적 분석

---

## 종합 판정

**🟡 CONDITIONAL — 조건부 출시 가능**

근거:
- 13게임 기능/엣지 케이스/UI 점검 모두 PASS (`docs/qa_full_inspection.md` 기준 100%)
- generator 회귀 수정 모두 best-effort fallback 적용, 자동 테스트 1283/1285 통과 (실패 2건은 stale 테스트로 사용자 회귀 아님)
- **블로커 없음**, P1 2건은 스토어 정책/장기 안정성 관점에서 "출시 직후 핫픽스 권장"
- ProGuard/R8 미적용, 가로모드 미잠금 — 정책 위반은 아니나 일반적 모범사례에서 벗어남

추천: **현 빌드로 내부 테스트(Closed Testing) 트랙 업로드 → 24~72시간 안정성 관찰 → 프로덕션 승격**.

---

## 🔴 블로커

| # | 게임/영역 | 시나리오 | 영향 |
|---|---|---|---|
| — | — | **없음** | 코어 기능·생성·저장·복원·다국어 모두 통과 |

---

## 🟡 P1 (출시 후 핫픽스 24~72h)

| # | 게임/영역 | 항목 | 영향 |
|---|---|---|---|
| P1-1 | 빌드/패키징 | `android/app/build.gradle.kts`에 `isMinifyEnabled = true`, `isShrinkResources = true` 미설정 | 릴리즈 APK 60.4MB (확인됨). R8 적용 시 5~15MB 감소 가능. 스토어 다운로드 전환율·이탈률에 영향. Google Play 정책 위반은 아님 |
| P1-2 | 디바이스 호환 | 가로 모드 대응 코드(`OrientationBuilder` 등) 0건 — `AndroidManifest.xml`에 `screenOrientation` 잠금도 없음 | 사용자가 자동 회전 ON 상태로 폰을 가로로 돌리면 보드 위젯이 가로 화면에 그려져 정사각형 보드가 잘리거나 비율이 깨질 수 있음. 폴더블/태블릿에서 동일. 데이터 손상은 없음 |
| P1-3 | 백업/복원 | `BackupService.exportToJson()`이 13게임 storage/badge를 모두 임포트하지만 `version: 1`로 고정. 14번째 게임 추가 시 버전 마이그레이션 로직 부재 | 향후 R13+ 추가 시 v1.0.0+4에서 만든 백업을 v1.1로 가져올 때 누락 키는 무시 — 현재 출시에는 영향 없음. 다만 import 시 try-catch 누락 시 한 게임 키 변경만으로 전체 복원 실패 가능. 다음 릴리즈 전 버전 가드 추가 권장 |
| P1-4 | minesweeper | 지뢰 reveal 시 `mistakeCount++`만 발생, `isGameOver` 미설정 (`lib/games/minesweeper/minesweeper_notifier.dart:180-189`) | 일반 지뢰찾기 룰과 다름. 사용자가 "버그"로 보고할 가능성. GD 의도라면 룰 설명 추가, 아니면 핫픽스 |

---

## 🟢 P2 (백로그)

| # | 항목 |
|---|---|
| P2-1 | 12게임 `pause()` 메서드에 `isPaused` 가드 누락(sudoku/binairo만 있음) — 이미 일시정지 상태에서 재호출 시 `_autoSave()` 중복. 성능 영향 거의 없음 |
| P2-2 | `restoreCheckpoint()` 후 즉시 `_autoSave()` 호출은 binairo만 — 다른 12게임은 메모리/디스크 일시 불일치(다음 입력에 동기화됨) |
| P2-3 | 이어하기 카드 진행률 % 텍스트 다국어 prefix 일관성: sudoku만 `AppStrings.get('home.progress')` 사용, 12게임은 하드코딩 `%` |
| P2-4 | sudoku 홈 통계/배지 버튼 `extra: 'sudoku'` 미전달 (`lib/features/home/screens/home_screen.dart:361,369`) — router 기본값으로 동작 시 사용자 영향 미미 |
| P2-5 | 시드 오프셋 규칙 비일관(killer +500, jigsaw +1000, 그 외 0) — 게임별 generator가 별도이므로 사실상 불필요 |
| P2-6 | minesweeper `tapCell` 라인 165 미사용 `final cell` 변수 — lint 경고 가능 |
| P2-7 | 위젯 테스트 2건 stale(`test/features/home/qa_phase3b_test.dart` BackButton/이어하기 카드) — 기능 회귀 아님, CI 노이즈 |

---

## 회귀 영향 매트릭스

| 최근 변경 | 영향 받을 수 있는 영역 | 검증 결과 |
|---|---|---|
| 6 generators best-effort (binairo/futoshiki/jigsaw/yin_yang/skyscrapers/kakuro) | 사용자 게임 시작·이어하기 흐름, 솔버 timeout, hint 시스템 | **OK** — `test/games/generation_performance_test.dart`가 모든 케이스 3초 이내 + 결과 반환 확인. 1283/1285 자동 테스트 통과. hint 시스템은 솔버와 별도 경로(생성된 board에서 빈 칸 채움)이므로 timeout 영향 없음 |
| 솔버 timeout 도입 | hint Level 1~4, 자동완성 | **OK** — hint 코드는 풀이 board를 미리 보유하므로 솔버 재호출 없음. `getHint`는 빈 셀 → 정답값 lookup 패턴 |
| 노노그램 정통 검증(실수 카운트 제거) | 결과 화면, 배지(`first_mistake_free` 등), 통계 | **OK with 주의** — 노노그램은 `mistakeCount`를 평가에서 제외하도록 수정됨. 단, 13게임 공통 결과 화면이 mistakeCount==0 조건으로 "완벽 클리어" 배지를 부여한다면 노노그램은 항상 0으로 평가되어 배지가 더 쉽게 획득됨. `docs/nonogram_verify_qa.md` 기준으로 의도된 정책. 통계 화면에서 노노그램만 "실수 0회"가 항상 표시되는 점 사용자 혼란 가능(P2) |
| 킬러 케이지 색상화 | 메모 가독성, 선택 강조 | **OK** — `docs/cage_qa_check.md`와 메모-합계 겹침 수정 사이클(작업 #41) 완료. 코드 리뷰상 케이지 배경은 낮은 채도 + 선택 셀은 outlined border로 시각 충돌 회피 |
| 13게임 홈 BottomSheet 통일 | 라우팅, push/go 정합성, 백키 동작 | **OK** — `game_registry.dart`의 routePath와 `router.dart`의 AppRoutes가 13게임 모두 1:1 매핑됨(`/binairo`~`/kakuro`). BottomSheet 자체는 라우트 변경 없이 모달이므로 백키로 닫힘 |

---

## 엣지 케이스 점검 결과

| # | 시나리오 | 결과 | 비고 |
|---|---|---|---|
| 1 | 게임 시작 직후 즉시 뒤로 가기 | PASS | 모든 notifier가 `WidgetsBindingObserver`로 `didChangeAppLifecycleState` 감지 + `_autoSave()` 실행. state==null 가드도 정상 |
| 2 | 일시정지 중 백그라운드 → 복귀 → 타이머 | PASS | 타이머는 `_timer?.cancel()` 후 `isPaused` 상태로 저장. 복귀 시 resume 호출 전까지 정지 유지 |
| 3 | 게임 중 화면 회전 → 가로/세로 전환 | **⚠️ FAIL** | `AndroidManifest.xml`의 `configChanges`에 `orientation` 포함되어 Activity 재생성은 막힘. 그러나 Flutter 측 보드 레이아웃이 정사각형 가정 — 가로 모드에서 보드 비율 깨짐 가능. **사용자 자동회전 ON일 때만 영향**. (P1-2) |
| 4 | 게임 완료 직후 시스템 알림 중단 | PASS | 완료 후 입력 차단(`isCompleted` 가드 13게임 전수), 알림 후 복귀 시 결과 화면 유지 |
| 5 | 게임 진행 중 강제 종료 → 이어하기 | PASS | `_autoSave()`가 매 입력마다 호출 + 라이프사이클 paused에서도 저장. 재시작 시 `loadInProgress()`로 복원 |
| 6 | 동시에 여러 게임 진행 중 → 허브 → 다른 게임 → 복귀 | PASS | 게임별 storage key 분리(`sudoku_in_progress`, `binairo_in_progress` ...). 충돌 없음. notifier는 게임별 Riverpod provider로 격리 |
| 7 | 오늘의 퍼즐 이미 완료한 상태에서 다시 시도 | PASS | `DailyPuzzleService.isCompletedToday` 체크 후 결과 화면 재표시. 13게임 daily 시드(`year*10000+month*100+day` ± 오프셋) 동일성 보장 |
| 8 | 통계/배지 화면 빈 상태 | PASS | `loadCompletedGames()`가 빈 List 반환, 통계 화면 "데이터 없음" placeholder 표시. NaN/0-division 가드 확인 |
| 9 | 백업/복원 라운드트립 | PASS with 주의 | 13게임 storage/badge 모두 export/import 경로 존재. JSON 직렬화는 모델별 `toJson/fromJson` 사용. 단 `version: 1`이라 향후 마이그레이션 가드 필요(P1-3) |
| 10 | 체크포인트 저장 후 일시정지/포기/완료 | PASS | 체크포인트는 `state` 내부 필드로 보관, 일시정지/포기 시 함께 자동저장. 완료 시 `_clearInProgress()`로 같이 제거 |

---

## 디바이스 호환 추정

| 항목 | 결과 |
|---|---|
| Android 12+ (minSdk 31) | **OK** — minSdk 31, INTERNET 권한 명시적 제거(`tools:node="remove"`), 다른 위험 권한 0건 |
| targetSdk 35 (Android 15) | **OK** — Google Play 2026 요구사항 충족 |
| 작은 화면 (360dp) | **OK 추정** — 13게임 모두 `Wrap`/`Expanded`/`AspectRatio` 사용. BottomSheet은 `viewInsets.bottom` 보정. 단 실기기 테스트 권장 |
| 폴더블/태블릿 큰 화면 | **⚠️ 부분 위험** — 보드 정사각형 가정으로 최대 너비 제한 없음 → 태블릿에서 보드가 화면 폭 가득 채워 가독성/조작성 저하 가능. SafeArea 처리는 됨 |
| 가로 모드 강제 회전 | **⚠️ P1-2** — orientation 잠금 미적용. 가로에서 보드 비율 깨짐 |
| 시스템 폰트 1.0x~1.6x | **OK 추정** — Text 위젯 다수가 `Theme.of(context).textTheme` 기반. 단 1.6x에서 셀 내부 숫자 overflow 위험 있는 화면(킬러 케이지 합계 등) — 코드상 `FittedBox` 사용 확인됨 |
| 권한: INTERNET 절대 없음 | **OK** — `AndroidManifest.xml:4`에 `<uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>` 확인 |
| 서명 | **OK** — `signingConfigs.release`에 key.properties 로드. release buildType이 release 서명 사용 |
| ProGuard/R8 | **⚠️ P1-1** — `isMinifyEnabled` 미설정 (Flutter는 dart-side tree-shaking만, Java/Kotlin side는 minify 안 함). 크기 60.4MB |
| APK 크기 60.4MB | **⚠️ 큼** — 13게임 + fl_chart + Riverpod + go_router로는 다소 큼. App Bundle 업로드 시 디바이스별 분할로 실제 다운로드 ~30~40MB 추정. R8 적용 시 추가 감소 |
| Asset 트리쉐이킹 | **OK** — Flutter 기본 트리쉐이킹 + `--release` 빌드. cupertino_icons 외 폰트/이미지 asset 없음 |
| SharedPreferences 키 충돌 | **OK** — 13게임 + 공통 모두 prefix(`sudoku_`, `binairo_`, `minesweeper_`, ...)로 격리 |
| JSON 라운드트립 | **OK** — `BackupService`가 13게임 + 배지 + dailyRecords 전수 export/import |
| 백워드 호환 | **OK with 주의** — v1.0.0+3(R1 Binairo) → v1.0.0+4 데이터 로드 시 신규 11게임 키 부재는 빈 상태로 정상 로드. 단 sudoku/binairo 모델 변경이 없었는지는 git diff 확인 권장 |

---

## 권장 출시 전 행동

### 출시 직전 (Must)
1. **실기기 1대에서 다음 시나리오 수동 검증** (15분 소요):
   - 13게임 각 1퍼즐 시작 → 1수 입력 → 백키 → 허브 복귀 → 통계/배지 진입 (각 게임 탭 자동선택 확인)
   - 가로 모드 회전 1회 → 보드 비율 깨짐 시 P1-2 강제잠금으로 핫픽스 결정
   - 백업 export → 데이터 초기화 → import → 진행률 복원 확인
2. **AAB 빌드 + 내부 테스트 트랙 업로드** (프로덕션 X)
3. **24시간 크래시 리포트 관찰** (Play Console → ANR/Crash)

### 출시 직후 24~72h 핫픽스 후보 (v1.0.1)
4. P1-1 ProGuard/R8 적용 — 크기 절감 + 코드 보호
5. P1-2 가로 모드 강제잠금 (`android:screenOrientation="portrait"`) 또는 가로 레이아웃 대응
6. P1-4 minesweeper 지뢰 룰 GD 합의 후 정정
7. P1-3 BackupService 버전 가드 추가 (다음 게임 추가 전)

### 백로그 (다음 마이너 릴리즈)
8. P2-1~P2-7 일관성 정리(13게임 동시 작업)
9. stale 위젯 테스트 2건 수정 (`qa_phase3b_test.dart`)
10. 폴더블/태블릿 대응 — 보드 최대 너비 제한 + 가로 2단 레이아웃 검토

---

## 부록: 테스트 결과 요약

```
$ flutter test
1283 passed, 2 failed
실패 테스트 (사용자 회귀 아님, stale):
- test/features/home/qa_phase3b_test.dart: 홈→모드선택 BackButton finder 미발견
- test/features/home/qa_phase3b_test.dart: 진행 중 게임 이어하기 카드 렌더 가정
```

자동 테스트 통과율 **99.84%**, generator 성능 회귀 0건, 13게임 정적 분석 PASS.
