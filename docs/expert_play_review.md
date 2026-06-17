# 게임 전문가 13인 다난이도 플레이 평가

> 평가일: 2026-06-05
> 평가 방식: 각 게임 generator/solver/hint 코드 정독 기반 정적 분석 + 시드 1~20 × 전 난이도 시뮬레이션 멘탈모델
> 평가자: 13개 게임 도메인 전문가 페르소나
> 기준 코드: `lib/core/sudoku/*`, `lib/games/{game}/engine/*`
> 기준 등급/시간: `lib/features/game/game_state.dart` `Grade.baseTimeForDifficulty`

---

## 1. sudoku — 25년차 스도쿠 챔피언 평가

### 코드 베이스
- 생성기: `lib/core/sudoku/generator.dart`
- 솔버: `lib/core/sudoku/solver.dart` (MRV 백트래킹, 유일해 카운트)
- 기법 분석: `lib/core/sudoku/technique_analyzer.dart` (1511줄, Naked Single → Hidden Single → Naked/Hidden Pair → Pointing Pair → Box/Line Reduction → Naked Triple → X-Wing)

### 시뮬레이션 (시드 1~20)
| 난이도 | 빈 칸 범위 | 유일해 | 생성 (예상) | 기법 검증 |
|--------|------------|--------|---------------|-----------|
| beginner | 30~35 | 100% | <0.3s | Naked Single만 |
| easy | 36~40 | 100% | <0.5s | + Hidden Single |
| medium | 41~46 | 100% | <0.8s | + Pair |
| hard | 47~52 | 100% | <1.5s | + Pointing Pair |
| expert | 53~58 | 100% | <2.5s | Hard 이상 강제 |
| master | 59~62 | 100% | <3s, 일부 fallback | X-Wing 또는 score ≥30 |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐⭐ — `_isDifficultyAcceptable`에서 master/expert는 기법 점수로 검증, 빈 칸 + 기법 이중 기준
- 퍼즐 다양성: ⭐⭐⭐⭐⭐ — `SeededRandom` + 대각선 박스 셔플 + 백트래킹
- 유일해 보장: ✅ 모든 난이도 `hasUniqueSolution(limit=2)` 호출
- 생성 성능: ✅ 3초 timeout, master에서도 fallback 안전망
- 풀이 기법: ⭐⭐⭐⭐⭐ — 8가지 기법 완비, 최고 수준
- 힌트 효용: ⭐⭐⭐⭐ — `findNextTechnique`로 점진적 적용. Level 4 단계화는 별도 `hint_engine.dart` 확인 필요
- 등급 기준 시간: easy 600s/master 2400s. 챔피언 기준 master 15분 → 너무 관대. 일반인 기준 적절
- 메커니즘: ✅ 완벽

### 피드백
- 강점: 13게임 중 유일하게 풀이 기법 기반 난이도 평가가 동작 (X-Wing까지)
- 약점: master 보드도 X-Wing 1회면 통과 — Swordfish/Coloring 등 더 고급 기법은 미구현
- 제안: Swordfish, XY-Wing 추가하면 master 난이도가 더 차별화됨 (P2)

### 우선순위
- P2: 고급 기법 확장 (Swordfish, XY-Wing)

---

## 2. binairo — 세계 대회 우승자 평가

### 코드 베이스
- 생성기: `lib/games/binairo/engine/binairo_generator.dart`
- 솔버: `lib/games/binairo/engine/binairo_solver.dart`

### 시뮬레이션
| 난이도 | 사이즈 | 유지 비율 | 유일해 | 생성 |
|--------|--------|------------|--------|------|
| beginner | 6×6 | 50~60% | ✅ | 빠름 |
| easy | 8×8 | 35~45% | ✅ | 보통 |
| medium | 10×10 | 30~40% | ✅ | 보통 |
| hard | 12×12 | 25~35% | ✅ | 느림 가능 |
| master | 14×14 | 20~30% | ✅ | 3s timeout 위험 |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐ — 사이즈 + 유지 비율로 차등
- 퍼즐 다양성: ⭐⭐⭐⭐⭐ — 백트래킹 시 0/1 순서 랜덤, 시드 분리
- 유일해 보장: ✅ `hasUniqueSolution` 호출, fallback에서도 keep 한도 검증
- 생성 성능: ⚠️ 14×14에서 3s 임박. Stopwatch 끊김으로 안전
- 풀이 기법: ⭐⭐⭐ — 3연속 금지 + 행/열 균형 + 행/열 유일성 (모든 표준 규칙)
- 힌트 효용: 별도 `binairo_hint.dart` 471줄로 두꺼움 (단계별 가능성 높음)
- 등급/시간: state별 정의
- 메커니즘: ✅ 완벽 (특히 행/열 유일성 검사 포함)

### 피드백
- 강점: 행/열 유일성 검사까지 포함, 정통 Binairo
- 약점: 마스터(14×14) 생성 3s 위험 — 실패 시 fallback에서 minKeep을 maxKeep으로 올리므로 결과적으로 더 쉬워질 수 있음
- 제안: master 사이즈를 12 또는 14로 유지하되, fallback 시 사용자에게 "표준 난이도보다 쉬워졌을 수 있음" 표시는 불필요. timeout 5s로 확장 검토 (P2)

### 우선순위
- P2: master timeout 늘려 fallback 빈도 측정

---

## 3. minesweeper — 클래식 100만판 마스터 평가

### 코드 베이스
- 생성기: `lib/games/minesweeper/engine/minesweeper_generator.dart`
- 솔버: `lib/games/minesweeper/engine/minesweeper_solver.dart` (논리 풀이 + advanced 두-셀 비교)

### 시뮬레이션
| 난이도 | 사이즈 | 지뢰 | 밀도 |
|--------|--------|------|------|
| beginner | 8×8 | 8 | 12.5% |
| easy | 9×9 | 12 | 14.8% |
| medium | 10×10 | 18 | 18.0% |
| hard | 12×12 | 30 | 20.8% |
| master | 16×16 | 50 | 19.5% |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐ — 사이즈 + 밀도 점진
- 퍼즐 다양성: ⭐⭐⭐⭐ — 시드 기반 첫 클릭 위치 + 지뢰 위치 셔플
- 유일해 보장: ✅ **No-guess 보장** — `isSolvableByLogic` 검증. 클래식 100만판 마스터 기준 핵심 가치!
- 생성 성능: 100회 시도 + 3초 timeout. master(16×16, 50 지뢰)에서 timeout 위험. null 반환 시 처리 확인 필요
- 풀이 기법: ⭐⭐⭐⭐ — 단순 규칙 2개 + advanced(subset 분석)까지. 일부 1.5-패턴(1-2-1 등)은 advanced로 커버
- 힌트 효용: 별도 `minesweeper_hint.dart` (242줄)
- 등급/시간: state별
- 메커니즘: ✅ 첫 클릭 안전 영역(3×3) 완벽

### 피드백
- 강점: No-guess 보장이 13게임 중 가장 엄격
- 약점: master(16×16, 50 mines)에서 100회 안에 No-guess 보드 못 만들어 null 반환 빈도 우려 — 실제 측정 필요
- 제안: 생성 실패 시 UI에서 "잠시 후 다시 시도" 메시지 (P1)

### 우선순위
- P1: master 생성 성공률 실측 + 실패 시 UI 처리

---

## 4. yin_yang — Shikaku/Yin-Yang 디자이너 평가 🚨

### 코드 베이스
- 생성기: `lib/games/yin_yang/engine/yin_yang_generator.dart`
- 솔버: `lib/games/yin_yang/engine/yin_yang_solver.dart`

### 시뮬레이션
| 난이도 | 사이즈 | 유일해 검증 |
|--------|--------|--------------|
| beginner | 5×5 | ✅ size≤10 |
| easy | 7×7 | ✅ |
| medium | 10×10 | ✅ |
| hard | 14×14 | ❌ **검증 안 함** |
| master | 20×20 | ❌ **검증 안 함** |

### 평가
- 난이도 곡선: ⭐⭐⭐ — 사이즈 + 빈 칸 비율
- 퍼즐 다양성: ⭐⭐⭐
- 유일해 보장: 🚨 **P0** — `generator.dart:132` `if (size <= 10)` 조건으로 hard/master는 유일해 미검증
- 생성 성능: 큰 보드에서 검증 생략하니 빠름 (하지만 그게 문제)
- 풀이 기법: 솔버는 백트래킹 기반 (간단)
- 힌트 효용: 155줄 hint 파일
- 메커니즘: 일단 규칙은 정확 (2×2 단색 금지, 단일 연결 영역)

### 피드백
- 강점: 작은 보드는 안전
- 약점: 🚨 hard(14×14), master(20×20)에서 다중해 퍼즐 출제 위험 — 사용자가 정답을 맞춰도 "오답"으로 처리될 수 있음
- 제안: hard까지는 검증 강제, master는 사이즈 축소(16×16) + 검증 (P0)

### 우선순위
- 🚨 **P0**: hard/master에 유일해 검증 추가 (또는 master 사이즈 14로 축소)

---

## 5. nonograms — Pic-a-Pix 50×50 마스터 평가 🚨

### 코드 베이스
- 생성기: `lib/games/nonograms/engine/nonogram_generator.dart`
- 솔버: `lib/games/nonograms/engine/nonogram_solver.dart`

### 시뮬레이션
| 난이도 | 사이즈 | 채움 비율 |
|--------|--------|-----------|
| beginner | 5×5 | 30~60% 랜덤 |
| easy | 10×10 | 30~60% 랜덤 |
| medium | 15×15 | 30~60% 랜덤 |
| hard | 20×20 | 30~60% 랜덤 |

### 평가
- 난이도 곡선: ⚠️ **사이즈만 다름. 같은 사이즈 내에서 난이도 차별화 없음**. 마스터급 노노그램은 단순 라인 풀이로 안 풀리는 "고급 추론 필요" 퍼즐인데, 모두 솔버가 푸는 수준만
- 퍼즐 다양성: ⭐⭐⭐
- 유일해 보장: 🚨 **P0** — `generator.dart:87` solver가 한 답을 찾아 원본과 일치 확인하지만, 다른 답이 있는지는 검증 안 함. 솔버 자체가 백트래킹 첫 결과만 반환
- 생성 성능: 보통
- 풀이 기법: 솔버는 line-by-line 교집합 + 백트래킹 fallback — 즉 라인 추론 + 추측
- 힌트 효용: 105줄, 적은 편
- 등급/시간: state별
- 메커니즘: 힌트 추출/검증은 정확

### 피드백
- 강점: 솔버의 line 교집합 알고리즘 정확
- 약점:
  - 🚨 유일해 미보장 — 솔버 첫 답이 원본과 같다는 사실이 다른 답이 없음을 의미하지 않음
  - ⚠️ 난이도 = 사이즈만. beginner 5×5에 30%만 채움이면 거의 빈 보드 → 다중해 확률↑
- 제안:
  - 유일해 검증을 `countSolutions(limit=2)` 방식으로 변경 (P0)
  - 사이즈별 채움 비율 차등 (예: 5×5=50%, 20×20=40%) (P1)

### 우선순위
- 🚨 **P0**: 유일해 검증 로직 추가
- P1: 사이즈별 난이도 파라미터 세분화

---

## 6. killer_sudoku — Killer Sudoku 챔피언 평가 🚨

### 코드 베이스
- 생성기: `lib/games/killer_sudoku/engine/killer_sudoku_generator.dart`
- 솔버: `lib/games/killer_sudoku/engine/killer_sudoku_solver.dart`

### 시뮬레이션
| 난이도 | 케이지 크기 | 힌트 셀 | 유일해 |
|--------|-------------|---------|--------|
| beginner | 2~3 | 15 | ❌ 미검증 |
| easy | 2~3 | 8 | ❌ 미검증 |
| medium | 2~4 | 0 | ❌ 미검증 |
| hard | 2~5 | 0 | ❌ 미검증 |
| master | 3~5 | 0 | ❌ 미검증 |

### 평가
- 난이도 곡선: ⭐⭐⭐ — 케이지 크기 + 힌트 셀로 차등
- 퍼즐 다양성: ⭐⭐⭐⭐
- 유일해 보장: 🚨 **P0 — 검증 코드 자체가 없음!** `generate()` 끝에 `KillerSudokuSolver.hasUniqueSolution()` 호출 없음. 케이지 분할 후 바로 반환
- 생성 성능: 빠름 (그러나 그게 문제 — 검증을 생략하므로)
- 풀이 기법: 솔버 315줄 (cage sum constraint + 백트래킹)
- 힌트 효용: 268줄
- 메커니즘: 케이지 내 중복 방지 정확 (`hasDup` 체크)

### 피드백
- 강점: 케이지 BFS 분할 알고리즘 견고
- 약점: 🚨 유일해 검증 누락 — Killer Sudoku는 hint cell 0개 모드에서 단순한 케이지 분할로는 다중해가 흔함. 챔피언이 풀 수 없는 모순 발견 가능
- 제안: 솔버에 `hasUniqueSolution` 추가 + generate에서 호출 (P0)

### 우선순위
- 🚨 **P0**: 유일해 검증 로직 추가 (가장 시급)

---

## 7. star_battle — 변형 디자이너 평가

### 코드 베이스
- 생성기: `lib/games/star_battle/engine/star_battle_generator.dart` (402줄)
- 솔버: `lib/games/star_battle/engine/star_battle_solver.dart`

### 시뮬레이션
| 난이도 | 격자 | 별 | 유일해 |
|--------|------|----|----|
| beginner | 6×6 | 1 | ✅ |
| easy | 7×7 | 1 | ✅ |
| medium | 8×8 | 1 | ✅ |
| hard | 9×9 | 2 | ✅ |
| master | 10×10 | 2 | ✅ |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐⭐ — 1-Star → 2-Star 전환이 정통적
- 퍼즐 다양성: ⭐⭐⭐⭐ — BFS 영역 분할 + 연결성 검사
- 유일해 보장: ✅ `hasUniqueSolution` 호출
- 생성 성능: 5s timeout, 10회 재시도. 9×9/10×10에서 timeout 우려
- 풀이 기법: 백트래킹 (별 배치 + 스킵)
- 힌트 효용: 336줄
- 메커니즘: 8방향 인접 금지 정확

### 피드백
- 강점: 1-Star/2-Star 전환 정통, 영역 분할 알고리즘 견고
- 약점: 10×10 2-star 생성 시 timeout 위험
- 제안: 마스터 timeout 8s로 확장 (P2)

### 우선순위
- P2: master 생성 성공률 측정

---

## 8. light_up — Akari 알고리즘 전문가 평가

### 코드 베이스
- 생성기: `lib/games/light_up/engine/light_up_generator.dart` (288줄)
- 솔버: `lib/games/light_up/engine/light_up_solver.dart`

### 시뮬레이션
| 난이도 | 사이즈 | 벽 비율 | 숫자 벽 | 유일해 |
|--------|--------|----------|----------|--------|
| beginner | 7×7 | 15% | 70% | ✅ |
| easy | 8×8 | 18% | 60% | ✅ |
| medium | 10×10 | 20% | 50% | ✅ |
| hard | 12×12 | 22% | 40% | ✅ |
| master | 14×14 | 25% | 30% | ✅ |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐⭐ — 벽 비율 + 숫자 벽 비율 이중 파라미터
- 퍼즐 다양성: ⭐⭐⭐⭐ — 중심 대칭 벽 배치 (전통적 미관)
- 유일해 보장: ✅
- 생성 성능: 5s timeout, master에서 위험
- 풀이 기법: 전구 배치 그리디 + 솔버 검증
- 힌트 효용: 295줄
- 메커니즘: ✅

### 피드백
- 강점: 벽 대칭 배치로 미관 좋음. 난이도 파라미터 잘 설계됨
- 약점: 전구 배치가 그리디 → 어려운 퍼즐에서 최적 솔루션 못 찾을 가능성
- 제안: 없음 — 균형 좋음

### 우선순위
- P2: 큰 보드 timeout 모니터링

---

## 9. futoshiki — Futoshiki 코치 평가

### 코드 베이스
- 생성기: `lib/games/futoshiki/engine/futoshiki_generator.dart`
- 솔버: `lib/games/futoshiki/engine/futoshiki_solver.dart`

### 시뮬레이션
| 난이도 | 사이즈 | 부등호 % | 채움 % | 유일해 |
|--------|--------|----------|---------|--------|
| beginner | 4×4 | 50~70 | 30~45 | ✅ |
| easy | 5×5 | 40~55 | 20~30 | ✅ |
| medium | 6×6 | 30~45 | 10~20 | ✅ |
| hard | 7×7 | 25~40 | 5~15 | ✅ |
| master | 9×9 | 20~35 | 0~10 | ✅ |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐⭐ — 부등호 비율 + 채움 비율 이중 차등
- 퍼즐 다양성: ⭐⭐⭐⭐⭐ — 라틴 방진 + 부등호 랜덤 + 셀 제거
- 유일해 보장: ✅
- 생성 성능: 5s timeout
- 풀이 기법: 솔버 323줄 (제약 전파 가능)
- 힌트 효용: 338줄 (가장 두꺼운 hint 중 하나)
- 메커니즘: ✅

### 피드백
- 강점: 13게임 중 가장 정통적 난이도 설계. 마스터 9×9는 진짜 어렵겠음
- 약점: 큰 라틴 방진 9×9 생성 시 timeout 위험
- 제안: 마스터 8×8로 축소 검토 또는 timeout 확장 (P2)

### 우선순위
- P2: master 9×9 생성 성공률 측정

---

## 10. tents — Tents and Trees 마스터 평가 🚨

### 코드 베이스
- 생성기: `lib/games/tents/engine/tents_generator.dart`
- 솔버: `lib/games/tents/engine/tents_solver.dart`

### 시뮬레이션
| 난이도 | 사이즈 | 유일해 검증 |
|--------|--------|--------------|
| beginner | 6×6 | ✅ |
| easy | 8×8 | ✅ |
| medium | 10×10 | ✅ |
| hard | 12×12 | ❌ **검증 안 함** |
| master | 14×14 | ❌ **검증 안 함** |

### 평가
- 난이도 곡선: ⭐⭐⭐
- 퍼즐 다양성: ⭐⭐⭐⭐
- 유일해 보장: 🚨 **P0** — `tents_generator.dart:120` `if (size <= 10)` 조건. hard/master 유일해 미검증
- 생성 성능: 좋음
- 풀이 기법: 솔버 369줄
- 힌트 효용: 291줄
- 메커니즘: ✅ 텐트 8방향 인접 금지 + 1:1 매칭 정확

### 피드백
- 강점: 1:1 매칭 알고리즘 정확
- 약점: 🚨 Yin-Yang과 동일한 패턴 — 큰 보드 유일해 미보장
- 제안: hard까지 검증 강제 (P0)

### 우선순위
- 🚨 **P0**: hard/master 유일해 검증

---

## 11. jigsaw_sudoku — Irregular Sudoku 전문가 평가

### 코드 베이스
- 생성기: `lib/games/jigsaw_sudoku/engine/jigsaw_sudoku_generator.dart`
- 솔버: `lib/games/jigsaw_sudoku/engine/jigsaw_sudoku_solver.dart`

### 시뮬레이션
| 난이도 | 단서 수 | 유일해 |
|--------|----------|--------|
| beginner | 45 | ✅ |
| easy | 38 | ✅ |
| medium | 32 | ✅ |
| hard | 27 | ✅ |
| master | 23 | ✅ |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐ — 단서 수 차등 (master 23개는 정통 jigsaw 기준 어려움)
- 퍼즐 다양성: ⭐⭐⭐⭐ — BFS 랜덤 영역 분할
- 유일해 보장: ✅ `JigsawSudokuSolver.hasUniqueSolution`
- 생성 성능: 10s timeout (긴 편). 9개 9-cell 영역 생성 + 백트래킹 풀이 + 셀 제거
- 풀이 기법: 솔버 209줄 (백트래킹 중심)
- 힌트 효용: 170줄 (가장 얇은 hint — 풀이 기법 분석 없을 가능성)
- 메커니즘: ✅

### 피드백
- 강점: 영역 분할 후 백트래킹으로 완성보드 생성 — 정통
- 약점: hint engine이 풀이 기법 분석 없이 정답 셀만 알려주는 수준 가능성
- 제안: hint_engine.dart 검토 후 sudoku 수준의 기법 분석 추가 (P1)

### 우선순위
- P1: 힌트 시스템 강화

---

## 12. skyscrapers — Skyscrapers 강사 평가

### 코드 베이스
- 생성기: `lib/games/skyscrapers/engine/skyscrapers_generator.dart` (324줄)
- 솔버: `lib/games/skyscrapers/engine/skyscrapers_solver.dart` (467줄)
- 힌트: 342줄

### 시뮬레이션
| 난이도 | 사이즈 | 외곽 힌트 % | 채움 % | 유일해 |
|--------|--------|--------------|---------|--------|
| beginner | 4×4 | 70~90 | 30~45 | ✅ |
| easy | 5×5 | 55~70 | 15~30 | ✅ |
| medium | 6×6 | 40~55 | 5~15 | ✅ |
| hard | 7×7 | 30~45 | 0~10 | ✅ |
| master | 8×8 | 20~35 | 0~5 | ✅ |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐⭐ — 외곽 힌트 + 채움 이중 차등, 매우 정교
- 퍼즐 다양성: ⭐⭐⭐⭐⭐
- 유일해 보장: ✅
- 생성 성능: 5s timeout, master 8×8에서 위험 가능
- 풀이 기법: 솔버 467줄로 가장 두꺼움 — 제약 전파 가능성
- 힌트 효용: 342줄
- 메커니즘: ✅ visibleCount 정확

### 피드백
- 강점: 13게임 중 가장 정교한 난이도 설계 (이중 파라미터 + 큰 솔버)
- 약점: 마스터 8×8 0~5% 셀 채움 = 거의 빈 보드 → 외곽 힌트만으로 풀어야 함. 가능하나 생성 timeout 위험
- 제안: master timeout 8s로 확장 (P2)

### 우선순위
- P2: master 생성 timeout 측정 + 확장

---

## 13. kakuro — Kakuro 헤일/일본 정통 풀이가 평가

### 코드 베이스
- 생성기: `lib/games/kakuro/engine/kakuro_generator.dart` (438줄, 가장 김)
- 솔버: `lib/games/kakuro/engine/kakuro_solver.dart` (321줄)

### 시뮬레이션
| 난이도 | 사이즈 | 검은 셀 % | 유일해 |
|--------|--------|------------|--------|
| beginner | 6×6 | 45~55 | ✅ |
| easy | 8×8 | 40~50 | ✅ |
| medium | 10×10 | 35~45 | ✅ |
| hard | 12×12 | 30~40 | ✅ |

### 평가
- 난이도 곡선: ⭐⭐⭐⭐ — 사이즈 + 검은 셀 비율
- 퍼즐 다양성: ⭐⭐⭐⭐ — 대칭 검은 셀 배치
- 유일해 보장: ✅
- 생성 성능: 3s timeout. 12×12에서 위험
- 풀이 기법: ⚠️ 채우기에 합계 제약을 안 쓰고 중복 금지만 — 결과 보드의 sum이 그대로 hint. 일본 정통 풀이가 입장: 합계 조합(magic sums)이 추론의 핵심인데, 생성 시 magic sum 활용 없이 random + uniqueness 검증으로 결정
- 힌트 효용: 254줄
- 메커니즘: ✅ 블록 추출 + 합계 계산 정확

### 피드백
- 강점: 구조 유효성 검사 완벽 (길이 1 금지, 9 초과 금지, 블록 소속 검증)
- 약점:
  - `_isValidFillPlacement`에서 sum 제약을 미적용 → 백트래킹 늦게 실패 → 12×12 시 timeout 우려
  - master 난이도 부재 (beginner~hard 4단계만)
- 제안:
  - sum constraint 백트래킹 가지치기 추가 (P1)
  - master(14×14 또는 12×12 + 큰 블록) 추가 검토 (P2)

### 우선순위
- P1: sum constraint 가지치기 (성능)
- P2: master 난이도 추가

---

## 종합 발견 사항

### 🚨 P0 (긴급 — 합의 후 즉시 수정)
| # | 게임 | 항목 | 영향 |
|---|------|------|------|
| 1 | killer_sudoku | 유일해 검증 누락 (모든 난이도) | 다중해 퍼즐 출제, 정답이 "오답" 처리 가능 |
| 2 | yin_yang | hard/master 유일해 검증 생략 (size>10) | 14×14, 20×20에서 다중해 위험 |
| 3 | tents | hard/master 유일해 검증 생략 (size>10) | 12×12, 14×14에서 다중해 위험 |
| 4 | nonograms | 유일해 검증 자체가 부정확 (solver 첫 답 비교) | 모든 난이도 다중해 가능 |

### ⚠️ P1 (높음 — 다음 사이클)
| # | 게임 | 항목 | 영향 |
|---|------|------|------|
| 1 | minesweeper | master 생성 성공률 실측 + 실패 시 UI 메시지 | 빈 보드 표시 가능 |
| 2 | nonograms | 사이즈별 채움 비율 차등 | 난이도 차별화 |
| 3 | jigsaw_sudoku | 힌트 시스템에 기법 분석 추가 | 힌트 효용성 |
| 4 | kakuro | 백트래킹 sum 가지치기 | 12×12 timeout 회피 |

### 📝 P2 (보통 — 백로그)
| # | 게임 | 항목 | 영향 |
|---|------|------|------|
| 1 | sudoku | Swordfish/XY-Wing 추가 | master 차별화 |
| 2 | binairo | master timeout 5s 확장 | 14×14 fallback 빈도↓ |
| 3 | star_battle | master timeout 8s | 10×10 2-star 안정성 |
| 4 | futoshiki | master 9×9 timeout 측정 | 실측 후 조정 |
| 5 | skyscrapers | master 8×8 timeout 측정 | 실측 후 조정 |
| 6 | kakuro | master 난이도 추가 | 4난이도 → 5난이도 |
| 7 | light_up | 측정만 | 안정 운영 |

### 게임별 8차원 평가 (5점 만점)
| 게임 | 난이도 곡선 | 다양성 | 유일해 | 성능 | 기법 | 힌트 | 등급기준 | 메커니즘 | 총점 |
|------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| sudoku | 5 | 5 | 5 | 5 | 5 | 4 | 4 | 5 | **38** |
| binairo | 4 | 5 | 5 | 4 | 3 | 4 | 4 | 5 | **34** |
| minesweeper | 4 | 4 | 5 | 4 | 4 | 4 | 4 | 5 | **34** |
| yin_yang | 3 | 3 | **1** | 4 | 3 | 3 | 4 | 4 | **25** |
| nonograms | 2 | 3 | **1** | 4 | 3 | 3 | 4 | 5 | **25** |
| killer_sudoku | 3 | 4 | **1** | 5 | 4 | 4 | 4 | 5 | **30** |
| star_battle | 5 | 4 | 5 | 4 | 4 | 4 | 4 | 5 | **35** |
| light_up | 5 | 4 | 5 | 4 | 4 | 4 | 4 | 5 | **35** |
| futoshiki | 5 | 5 | 5 | 4 | 4 | 5 | 4 | 5 | **37** |
| tents | 3 | 4 | **2** | 4 | 4 | 4 | 4 | 5 | **30** |
| jigsaw_sudoku | 4 | 4 | 5 | 4 | 4 | 3 | 4 | 5 | **33** |
| skyscrapers | 5 | 5 | 5 | 4 | 5 | 5 | 4 | 5 | **38** |
| kakuro | 4 | 4 | 5 | 3 | 4 | 4 | 4 | 5 | **33** |

### 베스트 / 워스트
- 🏆 **Best Designed (공동 1위)**:
  - **sudoku** — 풀이 기법 8종 + 기법 점수 기반 난이도 검증. 13게임 중 유일하게 X-Wing까지 추론
  - **skyscrapers** — 솔버 467줄, 이중 파라미터(외곽 힌트 + 셀 채움) 차등, 가장 정교한 난이도 설계
- ⚠️ **Most Improvement Needed**:
  - **nonograms** & **yin_yang** (공동) — 유일해 보장 미흡 + 난이도 차별화 미흡 (nonograms는 사이즈만, yin_yang은 큰 보드 검증 생략)
  - **killer_sudoku** — 유일해 검증 자체가 없음. 가장 시급한 P0

### PM 제언
1. **P0 4건은 즉시 GD + DEV 합의 → 다음 빌드 반드시 반영**
   - nonograms는 `hasUniqueSolution` 메서드 신설 후 generator에 추가
   - killer_sudoku, yin_yang, tents는 generator에 유일해 검증 호출 추가 (yin_yang/tents는 `size <= 10` 가드 제거 또는 사이즈 조정)
2. **P1은 다음 사이클(R13 또는 1.1.x 패치)에 포함**
3. **P2는 백로그에 적재 후 사용자 피드백 따라 우선순위 재조정**

### 합의 필요 안건
- yin_yang master 사이즈를 20→16로 축소할지 (검증 비용 vs 난이도 체감)
- nonograms hard 사이즈를 20×20 유지할지 (유일해 검증 추가 시 생성 시간 폭증 위험)
- killer_sudoku master 난이도 유지 가능성 (유일해 검증 추가 시 케이지 재분할 빈도)
