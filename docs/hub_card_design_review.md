# 게임 허브 카드 디자인 리뷰

대상: `lib/features/hub/screens/game_hub_screen.dart` — `_GameCard`
검토자: 모바일 UI/UX 디자인 전문가
일자: 2026-06-22

---

## 1. 진단 — "숫자 테두리가 박스를 벗어난다"의 원인

코드 라인 기준 핵심 문제 4가지:

| # | 라인 | 문제 | 영향 |
|---|---|---|---|
| **P0-A** | L343–363 | 좌상단 번호 탭 배지(50×32, 우측 padding 3) 위치가 카드 `(0,0)`에 절대 배치. 카드 borderRadius=10인데 배지 우하단만 곡선(`r=0.30*h≈9.6`), 좌상단은 직각 → 카드 보더(1.5px)와 어긋나며 "튀어나온" 느낌. 그림자 elevation 4 + shadowColor #2A205E가 박스 밖으로 새어 나옴 | 가장 시각적으로 어설픔 |
| **P0-B** | L408–414 | 메인 콘텐츠 padding `fromLTRB(4, 30, 6, 4)` — 좌4/우6/하4은 borderRadius 10 + 보더 1.5px 안전영역 대비 절대 부족. 텍스트가 카드 우측 보더에 거의 밀착 | 텍스트 잘림 / 답답함 |
| **P1-A** | L417–428 | 3D PNG 아이콘 SizedBox 68×62 + `Transform.rotate(-0.05)` 적용. 회전축이 중심이라 좌상단 모서리가 좌측 padding(4px)을 침범할 수 있음 | 아이콘이 좌측 보더를 침범 |
| **P1-B** | L88 / L417 | childAspectRatio 1.1 + 아이콘 영역(68) → 텍스트 Expanded 영역이 카드 너비의 **45% 이하**. 18sp 게임명 2줄 + 12sp 설명 3줄을 담기엔 협소 → ellipsis 빈발 | 정보 위계 무너짐 |

---

## 2. 디자인 원칙 (Material 3 + iOS HIG)

- **Safe Area 규칙:** borderRadius R인 컨테이너의 내부 콘텐츠는 최소 `R + 4dp` 만큼 모든 변에서 떨어져야 한다. 현재 R=10 → 최소 padding 14dp 필요. 현재 4dp는 위반.
- **Badge 배치:** Material 3 Badge 가이드는 컨테이너 모서리에서 **6dp 이상** 떨어지거나, 좌상단 일체형일 경우 컨테이너와 **동일 borderRadius**를 공유해야 함.
- **터치 타깃 vs 시각 비중:** 카드 주인공(아이콘) 면적은 카드의 35~40%가 이상적. 현재 ~50%.

---

## 3. 권고 (P0 → P2)

### P0 — 즉시 수정 (가장 큰 시각적 문제)

**[P0-A] 번호 탭 배지를 카드 모서리에 정합**

- 위치: `Positioned(top: 0, left: 0)` → `Positioned(top: 6, left: 6)`
- 모양: `_TabBadgeClipper` 좌상단도 카드와 동일하게 둥글게 (좌상 r=10, 우하 r=12, 우상/좌하 r=6)
- 크기 축소: 50×32 → **44×26** (fontSize 13 → 11)
- elevation 4 → 2, shadowColor 알파 50% 감소
- 효과: 배지가 카드 안에 정확히 안착, "테두리가 박스를 벗어난" 인상 제거

**[P0-B] 메인 콘텐츠 padding 정상화**

```dart
// L408–414 변경 권고
padding: EdgeInsets.fromLTRB(
  isFullWidth ? 16 : 14,   // 4 → 14
  isFullWidth ? 18 : 36,   // 30 → 36 (배지 공간 확보)
  isFullWidth ? 14 : 14,   // 6 → 14
  isFullWidth ? 14 : 12,   // 4 → 12
),
```

borderRadius 10 + 보더 1.5px 대비 충분한 안전영역 확보. 텍스트가 카드 우측에서 14dp 떨어져 호흡감 발생.

### P1 — 디자인 격 상승

- **아이콘 컨테이너 축소 + 회전 제거:** 68×62 → **56×56**, `Transform.rotate(-0.05)` 제거. 회전이 필요하면 PNG 에셋 자체에 굽기. → 카드 좌측 보더 침범 위험 제거.
- **종횡비 조정:** `childAspectRatio: 1.1` → **1.05** (세로 약간 늘림). 18sp 게임명 + 12sp 설명 3줄이 ellipsis 없이 자연스럽게 들어옴.
- **컬러 토큰 통일:** 그림자 색 하드코딩 `Color(0xFF3F35B5)` → `AppColors.brandIndigo` 참조 (L268). NEW 배지 #59C878 → `AppColors.kpGreen` 참조 (L371).
- **13게임 일관성:** 모든 카드가 동일 `hub-*.png` 3D 에셋 시스템을 쓰고 있어 양호. 단 PNG 픽셀 사이즈가 게임별로 다르면 시각 무게 차이 발생 — 에셋 표준화 권고 (256×256 정사각, 투명 패딩 12%).

### P2 — 다음 사이클

- 탭 시 `scale 0.96` + `Haptic.lightImpact` 마이크로 인터랙션
- 진행중 카드에 좌측 보더 두께 1.5 → 3 + 금색 글로우
- 다크모드 카드 배경에 게임 컬러 알파 0.10 → 0.14 그라데이션 (현재 너무 어둡고 평평)

---

## 4. 아이콘 시스템 — 현 상태 유지 권고

현재 13개 모두 `assets/icons/hub-{id}.png` 3D 캐주얼 일러스트로 통일됨 (L244–258). 이는 프리미엄 캐주얼 컨셉과 일치하며 **변경 불필요**. 단:

- 게임 레지스트리의 `emoji` 필드(L56,62,68 등)는 허브에서 사용되지 않음 → 데드 코드 정리 검토 (별도 작업)
- PNG 에셋의 투명 padding이 게임별로 다른지 점검 필요 (시각 무게 균질화)

---

## 5. 코드 변경 가이드 (수정 금지 — 리뷰만)

| 파일 | 라인 | 변경 |
|---|---|---|
| `lib/features/hub/screens/game_hub_screen.dart` | 343 | `Positioned(top: 0, left: 0)` → `Positioned(top: 6, left: 6)` |
| 동 | 351 | `width: 50, height: 32` → `width: 44, height: 26` |
| 동 | 354 | `EdgeInsets.only(right: 3)` → `EdgeInsets.zero` |
| 동 | 357 | `fontSize: 13` → `fontSize: 11` |
| 동 | 349 | `elevation: 4` → `elevation: 2` |
| 동 | 408–414 | padding `(4,30,6,4)` → `(14,36,14,12)` (그리드 카드 기준) |
| 동 | 418 | `width: 68` → `width: 56` |
| 동 | 419 | `Transform.rotate(angle: -0.05, child: ...)` 제거 |
| 동 | 423–424 | `width/height: 62` → `width/height: 56` |
| 동 | 88 | `childAspectRatio: 1.1` → `1.05` |
| 동 | 542–559 | `_TabBadgeClipper.getClip`에 좌상단 r=10 곡선 추가 |

---

## 결론

"숫자 테두리가 박스를 벗어난" 인상의 본질은 **(1) 좌상단 번호 배지가 카드 borderRadius와 불일치하고 모서리 0,0에 직각으로 박혀있는 것**, **(2) 카드 내부 padding 4~6dp가 borderRadius 10 + 보더 1.5dp 안전영역을 위반**하는 것 두 가지다. P0 두 항목만 적용해도 어설픔의 80%는 해소된다. 작업 공수 약 30분.
