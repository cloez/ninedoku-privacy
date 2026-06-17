# 스도쿠 완성 효과 + 4단계 힌트 — 전 게임 확장 계획서

작성자: GD (모바일 게임 기획자)
일자: 2026-06-15
대상: 13게임 (Sudoku 포함, 신규 12종)
요청자: PM

---

## 0. 한눈에 보는 결론

- **현황(중요):**
  - **완성 효과 (`LineCompletePulse` / `CompletedLine`)**: 스도쿠에만 적용. 12개 신규 게임 **전부 미적용**.
  - **힌트**: 12개 신규 게임 **모두 4단계 점진(currentHintLevel 1→4) 기본 골격은 이미 존재**한다. 단, **스도쿠 수준의 기법 분석기(TechniqueAnalyzer) / HintBanner / TechniqueGlossaryModal / HintRegionPulse 등 "고급 레이어"는 12종 전원 미적용**이다.
  - 즉, "힌트 확대"의 실질 과제는 "0→4단계" 신규 도입이 아니라 **"기존 4단계 → 스도쿠 품질의 설명·시각·기법 분석"으로 격상**하는 작업이다.
- **권고: 옵션 B (Phase 1 전체 + Phase 2 전체) 우선 진행.** 옵션 C(기법 분석기까지)는 R13 이후 별도 사이클로 분리.

---

## 1. 현황 파악 (코드 조사 결과)

### 1.1 완성 효과
| 컴포넌트 | 위치 | 현재 사용처 |
|---|---|---|
| `LineCompletePulse` 위젯 | `lib/features/game/widgets/line_complete_pulse.dart` | Sudoku 보드만 |
| `CompletedLine(type: row/col/box, index)` 모델 | `lib/features/game/game_state.dart` | Sudoku만 |
| `game_notifier.dart`의 라인 감지 로직 | `lib/features/game/game_notifier.dart` | Sudoku만 |

→ 12개 신규 게임의 `*_state.dart` / `*_notifier.dart` / `widgets/*_board_widget.dart` 어디에도 `CompletedLine`/`LineCompletePulse` 참조 없음.

### 1.2 힌트 시스템
모든 12개 게임의 `*_notifier.dart`에서 다음 공통 패턴 확인:

```
var nextLevel = state!.currentHintLevel + 1;
if (nextLevel > 4) nextLevel = 1;           // 4단계 후 새 셀
final newHintCount = nextLevel == 1 ? +1 : 동일;
if (nextLevel == 4 && hint.value != null) { 정답 자동 입력 }
```

즉 **L1→L2→L3→L4(정답) 골격 자체는 12종 전부 구현**되어 있다. 다만 다음은 **스도쿠 전용**:

| 스도쿠 전용 자산 | 12 신규 게임 보유 여부 |
|---|---|
| `core/sudoku/hint_engine.dart` (게임용 헬퍼) | ❌ (각 게임 ad-hoc) |
| `core/sudoku/technique_analyzer.dart` (8종 기법 분석) | ❌ |
| `features/game/widgets/hint_banner.dart` (L1~L4 설명 배너) | ❌ |
| `features/game/widgets/hint_region_pulse.dart` (L1 영역 강조) | ❌ |
| `features/game/widgets/technique_glossary_modal.dart` | ❌ |
| 다국어 힌트 키 ~150개 | ❌ (게임당 최소만 존재) |

---

## 2. 게임별 보드 구조 및 적용 가능성

### 2.1 완성 효과 — 게임별 가능성 표

| # | 게임 | 행 | 열 | 박스/영역 | 게임 완성 | 추가 단위 | 적용 난이도 |
|---|---|---|---|---|---|---|---|
| R0 | Sudoku | ✅ | ✅ | ✅ 3x3 | ✅ | — | 적용 완료 |
| R1 | Binairo | ✅ | ✅ | ❌ | ✅ | 행/열 균형 완성 시 | **L** |
| R2 | Minesweeper | ❌ | ❌ | ❌ | ✅ | 모든 안전 칸 공개 | **L** (게임 완성만) |
| R3 | Yin Yang | ❌ | ❌ | ❌ | ✅ | 단일 연결 영역 형성 | **L** (게임 완성만) |
| R4 | Nonograms | ✅ | ✅ | ❌ | ✅ | 행/열 단서 100% 만족 | **M** |
| R5 | Killer Sudoku | ✅ | ✅ | ✅ 3x3 + 케이지 | ✅ | 케이지(합 일치+중복없음) | **M** |
| R6 | Star Battle | ✅ | ✅ | ✅ 비대칭 영역 | ✅ | 영역 별 N개 채움 | **M** |
| R7 | Light Up | ❌ | ❌ | ❌ | ✅ | 모든 흰 칸 점등 | **L** (게임 완성만 + 옵션: 숫자 블록 만족 펄스) |
| R8 | Futoshiki | ✅ | ✅ | ❌ | ✅ | 행/열만 | **L** |
| R9 | Tents | ✅ (텐트 수) | ✅ (텐트 수) | ❌ | ✅ | 행/열 텐트 카운트 일치 | **L** |
| R10 | Jigsaw Sudoku | ✅ | ✅ | ✅ 불규칙 9영역 | ✅ | 불규칙 영역 | **M** |
| R11 | Skyscrapers | ✅ | ✅ | ❌ | ✅ | 행/열 + (옵션) 단서 시야 일치 시 단서 셀 펄스 | **M** |
| R12 | Kakuro | ❌ | ❌ | ❌ | ✅ | 합산 런(run) 완성 (가로/세로) | **M** |

**박스/영역 효과 도입 시 코드 변경 위치:**
- `CompletedLine.type`을 enum 확장 → `row|col|box|region|cage|run|tentRow|tentCol` 정도까지.
- 게임별 notifier가 자기 정의에 맞춰 `completedLines`를 채워주면 보드 위젯은 동일한 `LineCompletePulse` 재사용 가능.

### 2.2 힌트 4단계 — 게임별 가능성

| # | 게임 | 현재 골격 | 기법 분석기 신규 필요 | 스도쿠 수준 격상 난이도 | 비고 |
|---|---|---|---|---|---|
| R0 | Sudoku | 완전 구현 | — | 완료 | 기준 |
| R1 | Binairo | L1~L4 골격 ✅ | 강제수/패턴/균형 3종 | **M** | 분석기 단순 |
| R2 | Minesweeper | L1~L4 골격 ✅ | 안전/지뢰 추론 2종 | **H** | 확률 기반 부분 회피 |
| R3 | Yin Yang | L1~L4 골격 ✅ | 2x2 금지/연결 강제 2종 | **H** | 연결성 추론 복잡 |
| R4 | Nonograms | L1~L4 골격 ✅ | line solver 강제칸/제외칸 | **M** | 표준 알고리즘 |
| R5 | Killer Sudoku | L1~L4 골격 ✅ | 스도쿠 8종 + 케이지 합 분해 | **H** | 스도쿠 분석기 재사용 가능 |
| R6 | Star Battle | L1~L4 골격 ✅ | 별 강제/금지 2종 | **H** | 영역 제약 |
| R7 | Light Up | L1~L4 골격 ✅ | 등불 강제/벽 단서 2종 | **M** | |
| R8 | Futoshiki | L1~L4 골격 ✅ | 부등호 강제 + 스도쿠 기본 | **M** | |
| R9 | Tents | L1~L4 골격 ✅ | 행/열 카운트 + 인접 매칭 | **M** | |
| R10 | Jigsaw Sudoku | L1~L4 골격 ✅ | **스도쿠 기법 그대로 재사용** | **L** | 박스 → 불규칙 영역만 치환 |
| R11 | Skyscrapers | L1~L4 골격 ✅ | 시야 추론 + 사도쿠 기본 | **M** | |
| R12 | Kakuro | L1~L4 골격 ✅ | 합 분해(unique combos) | **H** | |

→ **Jigsaw는 거의 무료**, Killer는 스도쿠 분석기 큰 부분을 그대로 재사용 가능.

---

## 3. Phase 정의

### Phase 1 — 완성 효과 확대 (예상 8~12h)
1. `CompletedLine.type` enum 확장 (`region`, `cage`, `run` 추가).
2. 12개 게임의 board widget에 `LineCompletePulse` 오버레이 적용 (스도쿠 위젯과 동일 패턴).
3. 게임별 notifier에 "완성 단위 감지 + state.completedLines 갱신" 로직 추가.
4. **공통**: 모든 게임 완료(승리) 시 전체 보드 셀에 스태거 펄스 (이미 사운드 `kLineComplete`/`kVictory`와 동기).

### Phase 2 — 힌트 공통 인프라 + 배너/용어집 격상 (예상 6~10h)
1. `core/hints/` 신규 디렉터리: `HintEngine` 인터페이스 + `HintBanner`를 게임 비종속(generic)으로 이동.
2. 다국어 힌트 키를 **공통 키(L1 영역 강조 / L2 기법 / L3 후보 소거 / L4 정답)** + **게임별 기법명 키**로 이원화.
3. 12 게임 화면에 `HintBanner` + `HintRegionPulse` 위젯 표시 (L1만 채워도 즉시 가치 발생).
4. `TechniqueGlossaryModal`을 게임별 기법 리스트를 주입받는 형태로 리팩터.
5. **이 Phase 종료 시점에 12 게임 모두: L1=영역 강조 + 배너 설명, L2=문구만(기법명 placeholder), L3=후보 단일화 시각, L4=정답 자동 입력**까지 동작.

### Phase 3 — 게임별 기법 분석기 (게임당 3~8h, 총 30~60h)
- 우선순위:
  1. **Jigsaw Sudoku** (스도쿠 분석기 어댑팅) — 3h
  2. **Killer Sudoku** (스도쿠 + 케이지 합) — 6h
  3. **Futoshiki / Skyscrapers / Tents / Nonograms / Light Up / Binairo** — 각 4~5h
  4. **Star Battle / Yin Yang / Minesweeper / Kakuro** (분석기 복잡) — 각 6~8h
- 각 게임 완료 후 `test/games/{game}/QA_CHECKLIST.md`에 분석기 단위 테스트 ≥5개 기록.

---

## 4. 옵션 비교

| 옵션 | 범위 | 공수 | 단기 가치 | 누가 행복? | 리스크 |
|---|---|---|---|---|---|
| **A. 미니멈** | Phase 1만 (13게임 완성 효과 전부) | ~10h | ★★★★ | 모든 사용자 (즉각적 시각 만족) | 힌트 격차는 남음 |
| **B. 표준** ⭐ | Phase 1 + Phase 2 (완성 효과 + L1 배너/영역 강조 일관성) | ~18h | ★★★★ | 입문~중급 유저 | 기법 설명은 placeholder |
| **C. Full** | Phase 1 + 2 + Phase 3 일부(Jigsaw/Killer) | ~30h | ★★★★★ | 사도쿠 계열 코어 유저 | 스코프 큼, R13 일정 영향 |
| **C+ (비추)** | Phase 1+2+3 12게임 전체 | 50~70h | ★★★★★ | — | 단일 사이클로 무리, R13 지연 확정 |

---

## 5. GD 권고

### 5.1 추천: **옵션 B (Phase 1 + Phase 2)**

이유:
1. **사용자 체감의 80%는 Phase 1**. 시각적 완성 펄스는 13게임 모두에서 "성취감" 증폭.
2. **Phase 2의 L1 영역 강조 + 배너**만으로도 "스도쿠와 동급의 UI"라는 일관성이 확보된다. L2~L3의 기법 설명은 placeholder("이 영역에서 정답이 결정됩니다") 수준이어도 디자인 일관성은 깨지지 않는다.
3. **공수 18h는 단일 사이클(STEP 1~7)에 안전하게 수용 가능**. R13 일정에 영향 없음.
4. Phase 3은 게임별 사이클(소규모 릴리스 R13.1~R13.12)로 분리하면 QA 부담도 분산.

### 5.2 합의 필요 안건 (PM 주재)
- 박스/영역 완성 펄스를 **모든 가능 게임에 적용할지(B안), 게임 완성 펄스만 일괄 적용할지(미니멈A안)**: GD+UX+GC 합의 필요.
- Phase 2의 L2~L4 placeholder 문구의 톤: UX와 합의.
- Phase 3 우선순위(Jigsaw → Killer): GD+QA 합의 (QA 공수 평가).

---

## 6. 영향 받지 않는 영역 (변경 없음)

- 모든 게임의 **generator / solver / 채점 로직**.
- **GameRegistry / 라우터 / 허브 진행률 계산**.
- **사운드 / motionScale / 진행률 바**.
- **배지 시스템**.
- **백업/저장 서비스**.
- **다국어 키 중 기존 게임 규칙/UI 키** (힌트 키만 추가/확장).

---

## 7. 다음 액션

1. PM이 옵션 A/B/C 중 결정 (GD 추천: **B**).
2. 결정 후 STEP 1 기획서 → STEP 2 UX 명세 → STEP 3 DEV 진입.
3. Phase 2의 `core/hints/` 인터페이스 설계는 DEV+QA 합의 필요.
4. 13게임 리그레션은 STEP 5에서 `test/GAME_QA_CHECKLIST.md` 섹션 H를 기준으로 100% 통과 확인.

---

끝.
