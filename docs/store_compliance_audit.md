# 앱스토어 컴플라이언스 점검 — 스토어 릴리즈 게이트

**검토 대상**: Ninedoku v1.0.0+4 (applicationId: com.cloez.sudoku)
**검토일**: 2026-06-15
**검토 범위**: Google Play Store 정식 릴리즈 직전 정책/패키징/메타데이터

---

## 종합 판정

**🟡 CONDITIONAL** — 코드/권한/SDK 측면은 정책 위반 없음 (PUBLISH READY 수준).
다만 **빌드/메타데이터 산출물 준비**가 미완료 상태로, 아래 P1 항목 처리 후 업로드 가능.

핵심 결론:
- 코드/권한/SDK: 🟢 위반 사항 0건
- 빌드 산출물: 🟡 ProGuard/R8 미설정, AAB 미빌드(명령은 준비됨)
- 스토어 메타데이터: 🟡 산출물(스크린샷/피처 그래픽/등록 설명문) 미확인

---

## 🔴 블로커
| # | 영역 | 항목 |
|---|---|---|
| — | — | **블로커 없음** |

---

## 🟡 P1
| # | 영역 | 항목 |
|---|---|---|
| 1 | 빌드 | `android/app/build.gradle.kts` release 빌드 타입에 `isMinifyEnabled=true`, `isShrinkResources=true` 미설정. R8 비활성 상태로 AAB 크기/성능 손해 — 활성화 후 회귀 테스트 권장 |
| 2 | 빌드 | `proguard-rules.pro` 파일 없음. R8 활성화 시 Flutter/Riverpod 관련 keep 규칙 추가 필요 |
| 3 | 서명 | `android/app/keystore/upload-keystore.jks`, `key.properties` 존재 확인됨. **두 파일이 `.gitignore`에 포함되었는지** 및 **백업 안전 보관(분실 시 업데이트 불가)** 확인 필수 |
| 4 | 메타데이터 | Play Console 등록용 메타데이터(앱 이름/짧은 설명/자세한 설명 4언어, 스크린샷, 피처 그래픽 1024x500, 아이콘 512x512) 산출물 미확인 — 별도 산출 필요 |
| 5 | 데이터 안전 | Play Console "Data Safety" 양식 답변지 미작성 — 본 문서 하단 템플릿 사용 |
| 6 | 개인정보처리방침 | Play Console 정책상 개인정보 미수집 앱도 **개인정보처리방침 URL 입력란이 있는 경우 종종 요구됨**. GitHub Pages 등으로 정적 페이지 1장 게시 권장 |
| 7 | 콘텐츠 등급 | IARC 설문 미제출. 퍼즐 게임/전 연령 응답으로 즉시 통과 가능 |
| 8 | versionCode | pubspec `version: 1.0.0+4` — Play Store에 이전 업로드 동일 버전코드(+4) 존재 시 `+5`로 증분 필요. Internal/Closed 트랙에 +4가 있었는지 확인 |

---

## 정책 준수 점검

| 항목 | 결과 | 비고 |
|---|---|---|
| 권한 (INTERNET 없음) | 🟢 PASS | `AndroidManifest.xml` L4에서 `tools:node="remove"`로 INTERNET 강제 제거. Flutter 자동 머지된 INTERNET을 명시적으로 차단함 |
| 광고 SDK 없음 | 🟢 PASS | `pubspec.yaml` 의존성 전수 검사 — google_mobile_ads/admob 계열 없음 |
| 분석 SDK 없음 | 🟢 PASS | firebase/crashlytics/sentry/amplitude/mixpanel/google_analytics 모두 없음 |
| 결제 없음 | 🟢 PASS | in_app_purchase, billing 클라이언트 없음 |
| 사용자 추적 없음 | 🟢 PASS | 광고 ID(advertising ID) 호출 없음, UUID는 로컬 백업 식별자로만 사용 |
| Manifest 권한 적절 | 🟢 PASS | 선언된 권한: INTERNET 제거 1건뿐. 위치/카메라/마이크/연락처/저장소 등 sensitive 권한 0건 |
| Manifest 쿼리 | 🟢 PASS | `<queries>`에 `PROCESS_TEXT`, `https` VIEW만 — url_launcher용 정상 범위 |
| 타겟 API 35 | 🟢 PASS | `build.gradle.kts` L40 `targetSdk = 35` — 2026년 Play 요구사항 충족 |
| minSdk | 🟢 PASS | `minSdk = 31` (Android 12+) — 비즈 의사결정상 OK |
| 64bit 지원 | 🟢 PASS | Flutter 기본 빌드는 arm64-v8a 포함, AAB가 ABI split 자동 처리 |
| HTTP 통신 | 🟢 PASS | `http`, `dio` 등 네트워크 라이브러리 import 0건 (lib 전수 grep) |
| 외부 링크 | 🟡 NOTE | `url_launcher`/`share_plus`를 `settings_screen.dart`에서 사용. 외부 브라우저/공유 시트로 OS에 위임 — INTERNET 권한 불필요. 정책상 문제 없음 |
| 콘텐츠 등급 | 🟢 N/A | 퍼즐/논리, 전 연령. IARC 설문 응답으로 즉시 통과 |
| ApplicationId | 🟢 PASS | `com.cloez.sudoku` — 일관성 있음 |
| AAB 빌드 | 🟡 미실행 | 명령은 CLAUDE.md에 정의됨 — R8 설정 후 빌드 권장 |
| Hardcoded Secrets | 🟢 PASS | API 키/토큰 코드 내 노출 없음 (네트워크 자체가 없음) |

---

## 데이터 안전 양식 — 답변 템플릿 (Play Console 입력용)

**Data collection**
- Does your app collect or share any of the required user data types? → **No**

**Data security**
- Is all of the user data collected by your app encrypted in transit? → **N/A** (네트워크 통신 없음)
- Do you provide a way for users to request that their data be deleted? → **N/A** (수집 데이터 없음). 다만 사용자가 앱 삭제 시 모든 로컬 데이터(SharedPreferences/파일) 자동 삭제됨을 명시

**근거**:
- 모든 데이터(설정, 진행 상황, 통계, 뱃지)는 단말 로컬(SharedPreferences/path_provider 파일)에만 저장
- 외부 전송 없음 (INTERNET 권한 자체 없음)
- 광고 ID 미사용

---

## 출시 준비 체크리스트

- [ ] **AAB 빌드** — R8 활성화 후 `flutter build appbundle --release` 실행 → 크기/실행 검증
- [x] **키스토어 보유** — `android/app/keystore/upload-keystore.jks` 확인
- [ ] **키스토어 안전 보관** — 오프라인 백업(USB/암호화 클라우드) 2벌 이상, `key.properties` 비밀번호 별도 보관, `.gitignore` 등록 확인
- [ ] **데이터 안전 양식** — 위 템플릿대로 Play Console 입력
- [ ] **스토어 등록 메타데이터** — 앱 이름/짧은 설명/자세한 설명 4언어(KO/EN/JA/ZH)
- [ ] **콘텐츠 등급 양식** — IARC 설문, 퍼즐/전 연령
- [ ] **스크린샷** — 한국어 우선, 게임 13종 대표 화면 + 허브 + 통계 (최소 4장, 권장 8장)
- [ ] **피처 그래픽** 1024x500 PNG
- [ ] **앱 아이콘** 512x512 PNG (현재 `assets/app_icon.png` 활용)
- [ ] **개인정보처리방침 URL** — GitHub Pages 등에 정적 페이지 게시 후 URL 입력
- [ ] **versionCode 충돌 확인** — 기존 Alpha 트랙 versionCode와 중복 시 +5로 증분

---

## 권장 출시 전 행동

### 1. ProGuard/R8 활성화 (P1)
`android/app/build.gradle.kts`의 `buildTypes { release { ... } }` 블록에 다음 추가:
```kotlin
isMinifyEnabled = true
isShrinkResources = true
proguardFiles(
    getDefaultProguardFile("proguard-android-optimize.txt"),
    "proguard-rules.pro"
)
```
그리고 `android/app/proguard-rules.pro` 파일을 만들어 Flutter 권장 keep 규칙 추가. AAB 크기 20~30% 감소 기대.

### 2. 개인정보처리방침 1쪽 게시
내용 골자(추천):
- 본 앱은 어떠한 개인정보도 수집/저장/전송하지 않습니다
- 모든 데이터는 사용자 기기 내부에만 저장됩니다
- 광고/분석/추적 SDK를 사용하지 않습니다
- 인터넷 권한이 없으며 외부 서버 통신을 수행하지 않습니다
- 문의: shinhandscloud26@gmail.com

### 3. .gitignore 검증
다음 항목이 반드시 무시되어야 함:
- `android/app/keystore/upload-keystore.jks`
- `android/app/keystore/key.properties`
- `**/key.properties`

### 4. Internal Testing 트랙 선 업로드
정식 릴리즈 전 Play Console **Internal testing** 트랙에 AAB 업로드 → Play 자체 정책 스캐너가 권한/SDK 자동 검증 → 경고 0건 확인 후 Production 승격.

### 5. 출시 후 모니터링
- Play Console "사전 출시 보고서(Pre-launch report)"에서 크래시/ANR 확인
- "정책 상태" 페이지에서 위반 경고 모니터링

---

## 부록 — 코드 검토 증거

- **AndroidManifest** (`android/app/src/main/AndroidManifest.xml` L4):
  `<uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>` — 명시적 제거
- **빌드 설정** (`android/app/build.gradle.kts` L37-43): `minSdk=31`, `targetSdk=35`, `applicationId="com.cloez.sudoku"`
- **의존성** (`pubspec.yaml`): 광고/분석/결제/네트워크 SDK 전무. flutter_riverpod, go_router, shared_preferences, fl_chart, path_provider, uuid, intl, url_launcher, share_plus, cupertino_icons만 사용
- **lib 전수 import 검색**: firebase/admob/google_mobile_ads/sentry/crashlytics/amplitude/mixpanel/google_analytics/in_app_purchase/google_sign_in/http/dio — **0건**
- **외부 통신 가능 라이브러리**: url_launcher(OS 위임), share_plus(OS 위임) — 자체 네트워크 트래픽 없음

> 결론: **정책/코드 측면 PUBLISH READY**. 빌드 최적화와 스토어 메타데이터만 마무리하면 정식 릴리즈 가능.
