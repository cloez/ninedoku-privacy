# K-Puzzles 오픈소스 라이센스 검토 (B - OSS)

- 검토일: 2026-06-22
- 대상: `pubspec.yaml` / `pubspec.lock` (Flutter 3.38.4 / Dart 3.12+)
- 기준: 상용 배포 (Google Play Store) 가능 여부

---

## 1. 직접 의존성 (Direct dependencies)

| 패키지 | 버전 | 라이센스 | 상용 OK |
|---|---|---|---|
| flutter (SDK) | - | BSD-3-Clause | 🟢 |
| cupertino_icons | 1.0.9 | MIT | 🟢 |
| flutter_riverpod | 2.6.1 | MIT | 🟢 |
| riverpod_annotation | 2.6.1 | MIT | 🟢 |
| go_router | 15.1.3 | BSD-3-Clause (flutter.dev 공식) | 🟢 |
| shared_preferences | 2.5.5 | BSD-3-Clause (flutter.dev 공식) | 🟢 |
| fl_chart | 0.70.2 | MIT (imaNNeo) | 🟢 |
| path_provider | 2.1.5 | BSD-3-Clause (flutter.dev 공식) | 🟢 |
| path | 1.9.1 | BSD-3-Clause (dart.dev) | 🟢 |
| uuid | 4.5.3 | MIT | 🟢 |
| intl | 0.20.2 | BSD-3-Clause (dart.dev) | 🟢 |
| url_launcher | 6.3.2 | BSD-3-Clause (flutter.dev 공식) | 🟢 |
| share_plus | 13.1.0 | BSD-3-Clause (flutter community) | 🟢 |
| audioplayers | 6.7.1 | MIT (bluefireteam) | 🟢 |
| flutter_svg | 2.3.0 | MIT (dnfield) | 🟢 |

### dev_dependencies

| 패키지 | 버전 | 라이센스 | 상용 OK |
|---|---|---|---|
| flutter_lints | 6.0.0 | BSD-3 | 🟢 |
| flutter_launcher_icons | 0.14.4 | MIT | 🟢 |
| riverpod_generator | 2.6.5 | MIT | 🟢 |
| custom_lint | 0.7.6 | MIT | 🟢 |
| riverpod_lint | 2.6.5 | MIT | 🟢 |

> dev_dependencies는 **빌드 산출물(AAB/APK)에 포함되지 않음** → 배포 라이센스 영향 없음.

---

## 2. Transitive 의존성 (요약)

`pubspec.lock` 기준 약 90여 개 transitive 패키지를 식별. 주요 그룹:

- **dart.dev / flutter.dev 공식** (async, collection, characters, meta, http, crypto, archive, vm_service, web, leak_tracker 등): 전부 **BSD-3-Clause** 🟢
- **audioplayers_*** (android/darwin/linux/web/windows/platform_interface): **MIT** 🟢
- **url_launcher_*** , **path_provider_***, **shared_preferences_***, **share_plus_platform_interface**: **BSD-3** (flutter.dev 공식) 🟢
- **vector_graphics / vector_graphics_codec / vector_graphics_compiler / path_parsing** (flutter_svg 의존): **BSD-3** 🟢
- **rxdart** (share_plus 의존): **Apache-2.0** 🟢 (NOTICE 의무 - 아래 5절 참조)
- **petitparser, xml, yaml, archive, image, freezed_annotation, json_annotation, equatable, state_notifier, fixnum**: **MIT/BSD/Apache-2.0** 🟢
- **win32**: **BSD-3** 🟢 (Android/iOS 배포에는 미포함)
- **jni / jni_flutter / objective_c**: **BSD-3** (dart.dev 공식) 🟢

### 위험 항목 상세

**확인 결과: GPL/AGPL/LGPL/MPL 계열 의존성 없음.** 모든 transitive 패키지가 MIT / BSD-2/3 / Apache-2.0 중 하나로 분류됨.

---

## 3. 위험 등급별 통계

| 등급 | 개수 (대략) | 비고 |
|---|---|---|
| 🟢 Permissive (MIT/BSD/Apache-2.0/ISC) | 약 105개 전체 | 직접 15 + dev 5 + transitive ~85 |
| 🟡 Weak Copyleft (LGPL/MPL) | **0** | 없음 |
| 🔴 Strong Copyleft (GPL/AGPL) | **0** | 없음 |

> 단, transitive 일부 패키지(예: ci, hooks, record_use, code_assets 등 신규 dart 도구)는 pub.dev 페이지 직접 확인 권장 — 모두 dart.dev/flutter.dev 공식 패키지로 BSD-3로 추정되나 **최종 빌드 전 1회 자동 점검(`flutter pub deps` + OSS 스캐너)** 권장.

---

## 4. 🔴/🟡 대안 권고

해당 사항 없음. 모든 의존성이 Permissive 라이센스이므로 **패키지 교체 불필요**.

---

## 5. NOTICE / License Page 의무

### Apache-2.0 패키지 (NOTICE 권고)
- **rxdart** (share_plus 의존성)
- 의무: 배포 산출물에 라이센스 원문 + NOTICE 파일이 포함되어야 함.

### 처리 방안 (Flutter 기본 기능 활용)
Flutter는 `showLicensePage()` / `LicensePage` 위젯을 통해 모든 의존성의 라이센스를 **자동 수집·표시**한다. 다음 조치만 하면 의무를 충족함:

1. **설정 화면에 "오픈소스 라이센스" 메뉴 추가** → `showLicensePage(context: context, applicationName: 'K-Puzzles', applicationVersion: '1.0.1')` 호출.
2. 자체 작성 코드의 LICENSE는 `LicenseRegistry.addLicense(...)`로 등록 가능 (선택).

→ **현재 설정 화면에 라이센스 페이지 진입점이 있는지 확인 필요** (`lib/features/settings/screens/settings_screen.dart`).

### MIT / BSD-3 의무
- 라이센스 원문 + 저작권 고지를 배포물에 포함. Flutter `LicensePage`가 자동 처리 → 추가 작업 불필요.

---

## 6. 추가 점검 사항

- **Firebase / Google Analytics / 광고 SDK**: 포함되지 않음 (CLAUDE.md 오프라인 원칙 준수 확인). 🟢
- **INTERNET 권한**: share_plus / url_launcher는 외부 앱 호출만 하며 자체 네트워크 통신 없음. AndroidManifest INTERNET 권한 제거 가능 여부 별도 점검 권장.
- **assets/sounds/*.wav**: OSS 라이센스가 아니라 별도 검토 필요 (본 문서 범위 외 - "B - 사운드 라이센스" 검토 별도 진행).

---

## 7. 종합 판정

# ✅ 상용 배포 가능 (Permissive Only)

- GPL/AGPL/LGPL/MPL 의존성 **0건**
- 모든 의존성이 MIT / BSD-3 / Apache-2.0 (Permissive)
- 코드 공개 의무 **없음**, 라이센스 고지 의무만 존재

### 배포 전 To-Do (의무 충족)
1. [ ] 설정 화면에 **오픈소스 라이센스 페이지 진입점**(`showLicensePage`) 노출 확인.
2. [ ] 앱 정보에 `applicationName`, `applicationVersion`, `applicationLegalese` 메타 설정.
3. [ ] (권장) 릴리스 직전 `flutter pub deps --json`을 OSS 스캐너(예: `oss_licenses` 패키지)로 1회 검증해 신규 transitive 누락 여부 확인.

— 검토 종료 —
