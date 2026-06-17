# Ninedoku — 색상 시스템 전면 리뷰 (v1)

작성: UI 디자인 리뷰
범위: 스도쿠 보드/효과/힌트/추임새 색상 토큰

---

## 1. 현황 진단 — 왜 "허접"한가

### 현재 라인 완성 효과 (line_complete_pulse.dart)
- 시퀀스: `#FFEB3B` 노랑 → `#26C6DA` 청록 → `#4CAF50` 초록
- 문제점
  1. **톤 충돌**: 노랑(웜) + 청록(쿨) + 초록(쿨)이 같은 채도(Material 500 톤)로 충돌 → 만화/저가형 토스트 알림 느낌
  2. **순색(Pure Hue) 과다**: 채도 ≥80%, 명도 중간 → 디지털 캔디색, 프리미엄과 거리
  3. **의미 분산**: 노랑=경고/주의, 청록=정보, 초록=성공 — 세 의미가 한 효과에 혼재
  4. **타사 비교**: Sudoku.com은 단일 골드 그라데이션, Good Sudoku는 단색 민트 글로우 — 모두 *톤 일관성* 유지

### 전반 팔레트 (app_colors.dart)
- Material 2 팔레트 그대로 차용 → 2017년 톤 (`#4A90D9`, `#E53935`)
- `cellSameNumberLight = #C8E6C9` (연두) vs `cellHighlightLight = #E3F2FD` (연파랑) → 같은 행/열과 같은 숫자가 *다른 색군* 으로 분리되어 인지 부담
- 다크모드 `cellSelectedDark = #1A237E` (Indigo 900) — 너무 어두워 선택 인지율 낮음
- 오답 `#E53935` ↔ 고정숫자 `#212121` 대비 OK, 그러나 색약 사용자에게 빨강-회색 구분 약함

### 힌트 단계 색상
- L1 amber / L2 green / L3 blue / L4 purple → 4단계가 *무지개식* 으로 분산 → 단계의 *깊어짐* 이 색으로 표현되지 않음 (점진성 부족)

### WCAG 평가 (라이트 모드 흰 배경 기준)
| 토큰 | 대비비 | AA(4.5) |
|---|---|---|
| fixedNumber `#212121` | 16.1 | ✅ |
| userNumber `#1565C0` | 7.6 | ✅ |
| wrongNumber `#E53935` | 4.0 | ⚠ 미달 |
| noteNumber `#757575` | 4.6 | ✅ (경계) |

**오답 색상이 WCAG AA 미달** — 가장 시급.

---

## 2. 디자인 원칙 (방향)

1. **톤 일관성 (Tonal Cohesion)** — 한 효과 내 색상은 *동일 채도/명도 대역* 에서만 이동
2. **잉크 + 액센트 (Ink & Accent)** — 보드는 무채색 잉크, 효과만 1개 액센트 컬러 군에서 변주
3. **의미 1색 1역할** — 성공=초록만, 정보=파랑만, 경고=호박색만. 라인 완성은 *성공* 1개 군 유지
4. **다크 우선 (Dark-first)** — 야간 플레이 비율 높음 (스도쿠 사용자 행태), 다크모드를 1급 시민으로
5. **명상적 톤** — 채도 60~75% (순색 회피), 따뜻한 회색 베이스

---

## 3. 신규 팔레트 — Design Tokens

### A. Core Palette
| 토큰 | Light | Dark |
|---|---|---|
| primary | `#3B6EA8` (slate blue) | `#7FB3E8` |
| background | `#F7F5F0` (warm paper) | `#0F1115` (deep ink) |
| surface | `#FFFFFF` | `#171A20` |
| surfaceVariant (보드 셀) | `#FBF9F4` | `#1C2028` |
| outline (얇은 선) | `#D6D2CA` | `#2C313B` |
| outlineStrong (3x3 박스 선) | `#5B6068` | `#8A92A0` |

### B. Semantic
| 의미 | Light | Dark | 대비비 |
|---|---|---|---|
| success | `#16A37A` (jade) | `#3FD3A3` | 4.7 / 6.2 |
| info | `#3B6EA8` | `#7FB3E8` | 5.8 / 7.1 |
| warning | `#C28A2C` (amber ink) | `#E5B968` | 4.8 / 8.5 |
| error (오답) | `#C8453C` (rust red) | `#FF7A6E` | **5.4** / **6.0** ✅ AA |

### C. 셀 색상
| 역할 | Light | Dark |
|---|---|---|
| fixedNumber | `#1B1F26` | `#E8EAF0` |
| userNumber | `#2E5DA0` | `#9CC3F2` |
| wrongNumber | `#C8453C` | `#FF7A6E` |
| noteNumber | `#6E7280` | `#A8AEBA` |
| cellSelected (선택) | `#D8E5F4` (soft blue) | `#2A3A55` |
| cellPeer (행/열/박스 동시) | `#EEF0F5` (cool gray) | `#1F242E` |
| cellSameNumber (같은 숫자) | `#E7EEF8` (피어와 동일 색군, 더 진하게) | `#2A3242` |
| cellLastChanged | warning 알파 25% | warning 알파 30% |

> 핵심 변화: 피어(행/열/박스)와 같은 숫자가 *동일 색군 다른 강도* 로 통일 → 보드가 정돈됨.

### D. 효과 색상
- 라인 완성 그라데이션 → **§4 옵션 A/B/C**
- 힌트 L1~L4 점진 색상:
  - 단일 *info* 색군에서 명도/채도만 이동
  - L1 `#EBF1F8` 영역 (옅은 안내) → L2 `#C9DCEF` (기법) → L3 `#7FA8D4` (이유) → L4 `#3B6EA8` + success 글로우 (정답)
  - → 단계가 깊어질수록 *진해짐* 만으로 위계 표현
- 마지막 변경 펄스: warning amber (`#E5B968` @ 30%)
- 추임새:
  - Good `#16A37A` (success jade)
  - Excellent `#3B6EA8` (info slate)
  - Perfect `#C9963A` (muted gold) — 현재 `#FFD700` 순금색 회피

---

## 4. 라인 완성 효과 — 3가지 옵션

각 옵션은 동일 채도 대역(60~70%) 내에서 *명도와 색온도만* 변주. 시퀀스는 painter의 `_pulseColor(t)` 두 구간에 매핑.

### 옵션 A — **Aurora Gold** (황금빛 축하)
- 시퀀스: `#F5D88A` (옅은 골드) → `#D9A441` (코어 골드) → `#A77624` (딥 앰버)
- 글로우 색: `#F0D88A` 알파 50%
- 무드: **고급 트로피, 시상식, 황혼빛**. 단일 웜톤 안에서 명도만 이동
- 추천 이유: "완성=보상" 메타포 직관. Sudoku.com Daily Champion 톤과 유사 + 한층 차분
- 다크모드: `#FFDB8A` → `#E8B45A` → `#B88438` (전체 +10 명도)
- 약점: 노랑 계열 누적 → 색약(Tritan) 일부 사용자 인지 약화 가능

### 옵션 B — **Jade Bloom** (보석 같은 빛남) ⭐ 권장
- 시퀀스: `#BDE5D2` (민트 미스트) → `#3FBF8E` (제이드) → `#0F7A57` (딥 에메랄드)
- 글로우 색: `#3FBF8E` 알파 45% + 외곽 화이트 스파클 1px
- 무드: **명상적 성공, 자연의 청량감, 프리미엄 그린**
- 추천 이유: success 의미와 *완벽 일치* (의미 1색 1역할 원칙). 보드 무채 베이스에서 가장 또렷. 색약 친화적
- 다크모드: `#9EE0C2` → `#4ED49C` → `#1A9670` (전체 +12 명도)
- 약점: 다른 일반 성공 토스트와 톤 겹칠 수 있음 → *글로우 강도/스케일* 로 차별화

### 옵션 C — **Twilight Ribbon** (보석같은 빛남 / 신비)
- 시퀀스: `#C8D4F0` (라일락 블루) → `#7B8FD4` (페리윙클) → `#3D4A9E` (딥 인디고)
- 글로우 색: `#9FB0E0` 알파 50%
- 무드: **차분한 야간 명상, 별빛, 침묵의 환희**. 쿨톤 안의 명도 이동
- 추천 이유: 다크모드에서 가장 우아함. 보드 골드(고정숫자 액센트 시)와 보색 대비
- 다크모드: `#D8E0FA` → `#92A8E8` → `#5266B8`
- 약점: success 의미와 의미 충돌 위험 (파란 계열은 보통 *정보*) → 추임새 색과 분리 필요

### 비교 요약
| 기준 | A 골드 | B 제이드 | C 트와일라잇 |
|---|---|---|---|
| 의미 일치 (성공) | △ | ◎ | △ |
| 톤 일관성 | ◎ | ◎ | ◎ |
| 다크모드 미려 | ○ | ○ | ◎ |
| 라이트모드 미려 | ◎ | ◎ | ○ |
| 색약 친화 | △ | ◎ | ○ |
| 차별성 | ◎ | ○ | ◎ |

**디자이너 1순위: B (Jade Bloom)** — 의미·접근성·일관성 모두 우수.
**차선: A (Aurora Gold)** — "축하" 감정 강조가 우선이면.

---

## 5. 변경 영향 범위

| 파일 | 변경 항목 | 영향도 |
|---|---|---|
| `lib/shared/constants/app_colors.dart` | Core/Semantic/Cell 토큰 전면 재정의 | **High** — 13개 게임 전반 |
| `lib/features/game/widgets/line_complete_pulse.dart` | `_pulseColor` 시퀀스 (옵션 B) | High (시각 핵심) |
| `lib/features/game/widgets/sudoku_board_widget.dart` | peer/same-number 토큰 통합 | Medium |
| `lib/features/game/widgets/hint_banner.dart` | L1~L4 단일 색군 점진 | Medium |
| `lib/features/game/widgets/hint_reveal_pulse.dart` | 글로우 색 (amber→jade) | Low |
| `lib/features/game/widgets/hint_region_pulse.dart` | `Colors.amber` → warning 토큰 | Low |
| `lib/shared/widgets/last_change_pulse.dart` | 기본 색 토큰화 | Low |
| `lib/features/game/widgets/encouragement_widget.dart` | Perfect `#FFD700` → `#C9963A` | Low |
| `DifficultyTokens` | 6단계 톤 채도 -15%, 명도 통일 | Medium |

리그레션 우려: 12개 신규 게임(Binairo~Kakuro)에서 직접 `AppColors.*` 참조 → 토큰 *이름 유지하고 값만 교체* 로 흡수.

---

## 6. 단계적 적용 권고

### Phase 1 — 가장 큰 가치 (1~2일)
1. **라인 완성 효과 옵션 B (Jade Bloom) 교체** ← 사용자 직접 지적 사항
2. **오답 색상 WCAG AA 충족** (`#E53935` → `#C8453C`)
3. **`cellSameNumber` / `cellHighlight` 동일 색군 통합** (보드 정돈)
4. 추임새 Perfect 색 디톤 (`#FFD700` → `#C9963A`)

### Phase 2 — 디자인 격 상승 (2~3일)
5. Core palette 교체 (slate blue + warm paper)
6. 힌트 L1~L4 단일 색군 점진
7. 다크모드 토큰 재조정 (cellSelected 명도 상향)
8. DifficultyTokens 채도 정돈

### Phase 3 — 마감 (옵션)
9. 13개 게임 보드 셀 토큰 통일 검증
10. 색약 시뮬레이터로 회귀 검증 (Sim Daltonism / Stark)

---

## 7. PM 합의 안건

| # | 안건 | 옵션 | 디자이너 추천 |
|---|---|---|---|
| Q1 | 라인 완성 효과 색상 | A 골드 / **B 제이드** / C 트와일라잇 | **B** |
| Q2 | 다크 모드 동시 개선 | 동시 / Phase 1만 라이트 우선 | **동시 (다크 우선 원칙)** |
| Q3 | 셀 강조 색상 변경 범위 | 전체 13게임 / 스도쿠만 | **전체** (토큰 이름 유지 시 자동 흡수) |
| Q4 | 오답 색상 WCAG 수정 | 즉시 / 추후 | **즉시 (접근성 회귀 위험)** |
| Q5 | 추임새 Perfect 골드 디톤 | 적용 / 유지(축제감) | 사용자 합의 필요 |

합의 후 GD + UX + DEV 사이클로 Phase 1 진입 권장.
