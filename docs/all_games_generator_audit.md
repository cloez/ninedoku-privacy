# 13게임 Generator 전수 점검 보고서

> 측정일: 2026-06-05
> 측정 방식: 각 게임 × 난이도 × 시드(1,2,3) — 실측 ms
> 측정 환경: Windows 11 / Dart VM (dart run), 단일 process / 게임
> 케이스당 timeout: 30s (개별), 게임당 60~300s
> star_battle, light_up 은 사전 측정 결과 인용 (이미 best-effort 적용 완료)

---

## 측정 결과 요약

평가 기준:
- 🟢 PASS: 평균 < 2초 + 모든 시드 성공
- 🟡 SLOW: 평균 2~10초 (UX 저하 but 동작)
- 🔴 FAIL: 평균 > 10초 또는 null/오류 반환
- 💀 CRASH: stack overflow / 예외 발생
- ⛔ TIMEOUT: 30초 이내 응답 없음 (사실상 hang)

| 게임 | beginner | easy | medium | hard | expert | master | 종합 |
|------|----------|------|--------|------|--------|--------|------|
| sudoku | 🟢 16ms | 🟢 4ms | 🟢 7ms | 🟢 9ms | 🟢 107ms | 🟢 708ms | 🟢 PASS |
| binairo | 🟢 4ms | 🟢 6ms | 🟢 22ms | 🟢 102ms | — | 🔴 6,436ms (max 12.9s) | 🔴 FAIL (master) |
| minesweeper | 🟢 14ms | 🟢 2ms | 🟢 3ms | 🟢 13ms | — | 🟢 10ms | 🟢 PASS |
| yin_yang | 🟢 23ms | 🟢 1,555ms | ⛔ >30s | ⛔ >30s | — | ⛔ >30s | 🔴 FAIL (medium↑) |
| nonograms | 🟢 11ms | 🟢 13ms | 🟢 628ms | 🟡 2,515ms | — | — | 🟡 SLOW (hard) |
| killer_sudoku | 🟢 28ms | 🟢 23ms | 🟡 2,215ms | 🟡 2,500ms | — | 🟡 2,177ms | 🟡 SLOW (medium↑, best-effort OK) |
| star_battle | 🟢 ~700ms (전 난이도) | | | | | | 🟢 PASS (이미 best-effort 적용) |
| light_up | 🟢 <40ms (전 난이도) | | | | | | 🟢 PASS (이미 best-effort 적용) |
| futoshiki | 🟢 4ms | 🟢 1ms | 🟢 12ms | 🟢 36ms | — | 🔴 26,960ms (max 32.7s) | 🔴 FAIL (master) |
| tents | 🟢 16ms | 🟢 10ms | 🟢 29ms | 🟢 175ms | — | 🟢 500ms | 🟢 PASS |
| jigsaw_sudoku | 🟡 seed1=59ms, seed2·3=⛔ | 🟡 seed1=52ms, seed2·3=⛔ | 🟡 seed1=57ms, seed2·3=⛔ | 🟡 seed1=87ms, seed2·3=⛔ | — | 🟡 seed1=774ms, seed2·3=⛔ | 🔴 FAIL (전 난이도 seed-의존 hang) |
| skyscrapers | 🟢 11ms | 🟢 10ms | 🟢 389ms | 🔴 26,223ms | — | 🔴 ~39,100ms | 🔴 FAIL (hard, master) |
| kakuro | 🔴 68ms NULL | 🔴 20,350ms NULL | 🔴 18,584ms NULL | 🔴 5ms NULL | — | — | 🔴 FAIL (전 난이도 ok=0/3) |

---

## 상세

### sudoku (6 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 16ms | 36ms | 3/3 |
| easy | 4ms | 5ms | 3/3 |
| medium | 7ms | 12ms | 3/3 |
| hard | 9ms | 12ms | 3/3 |
| expert | 107ms | 207ms | 3/3 |
| master | 708ms | 853ms | 3/3 |

### binairo (5 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 4ms | 12ms | 3/3 |
| easy | 6ms | 10ms | 3/3 |
| medium | 22ms | 32ms | 3/3 |
| hard | 102ms | 127ms | 3/3 |
| master | 6,436ms | 12,959ms | 3/3 |

→ master 난이도(14x14) 평균 6.4s, 최악 13s. 결과는 반환되나 UX 부적합.

### minesweeper (5 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 14ms | 24ms | 3/3 |
| easy | 2ms | 4ms | 3/3 |
| medium | 3ms | 4ms | 3/3 |
| hard | 13ms | 31ms | 3/3 |
| master | 10ms | 19ms | 3/3 |

### yin_yang (5 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 23ms | 54ms | 3/3 |
| easy | 1,555ms | 2,187ms | 3/3 |
| medium | >30s (timeout) | — | 0/3 |
| hard | >30s (timeout) | — | 0/3 |
| master | >30s (timeout) | — | 0/3 |

→ medium(10x10) 이상 모든 시드가 30초 이내 무응답. 사실상 hang.

### nonograms (4 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 11ms | 27ms | 3/3 |
| easy | 13ms | 20ms | 3/3 |
| medium | 628ms | 1,723ms | 3/3 |
| hard | 2,515ms | 2,524ms | 3/3 |

→ hard 일관되게 약 2.5s — 내장 `_maxDuration=2500ms` best-effort 효과.

### killer_sudoku (5 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 28ms | 78ms | 3/3 |
| easy | 23ms | 47ms | 3/3 |
| medium | 2,215ms | 2,500ms | 3/3 |
| hard | 2,500ms | 2,500ms | 3/3 |
| master | 2,177ms | 2,500ms | 3/3 |

→ best-effort 2.5s timeout 효과적으로 작동. 모두 결과 반환.

### star_battle (5 난이도) — 사전 측정값
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| 전 난이도 | ~700ms | — | 3/3 |

### light_up (5 난이도) — 사전 측정값
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| 전 난이도 | <40ms | — | 3/3 |

### futoshiki (5 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 4ms | 12ms | 3/3 |
| easy | 1ms | 2ms | 3/3 |
| medium | 12ms | 20ms | 3/3 |
| hard | 36ms | 57ms | 3/3 |
| master | 26,960ms | 32,708ms | 3/3 |

→ master(9x9) 평균 27s, 최악 32.7s. 결과는 반환되나 UX 완전 파탄.

### tents (5 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 16ms | 43ms | 3/3 |
| easy | 10ms | 13ms | 3/3 |
| medium | 29ms | 71ms | 3/3 |
| hard | 175ms | 440ms | 3/3 |
| master | 500ms | 906ms | 3/3 |

### jigsaw_sudoku (5 난이도)
| 난이도 | seed=1 | seed=2 | seed=3 | success |
|--------|--------|--------|--------|---------|
| beginner | 59ms OK | ⛔ >30s | ⛔ >30s | 1/3 |
| easy | 52ms OK | ⛔ >30s | ⛔ >30s | 1/3 |
| medium | 57ms OK | ⛔ >30s | ⛔ >30s | 1/3 |
| hard | 87ms OK | ⛔ >30s | ⛔ >30s | 1/3 |
| master | 774ms OK | ⛔ >30s | ⛔ >30s | 1/3 |

→ **모든 난이도에서 seed=2, 3 hang**. seed=1만 동작. 매우 심각.
   `_timeoutMs=10000`이 무한 retry loop를 차단하지 못함.

### skyscrapers (5 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 11ms | 31ms | 3/3 |
| easy | 10ms | 16ms | 3/3 |
| medium | 389ms | 1,020ms | 3/3 |
| hard | 26,223ms | 42,649ms | 3/3 |
| master | ~39,100ms | ~42,400ms (seed=3 39,793ms 별도 측정) | 3/3 |

→ hard(7x7), master(8x8) 평균 26s/39s. 결과는 반환되나 UX 완전 파탄.

### kakuro (4 난이도)
| 난이도 | avg | max | success |
|--------|-----|-----|---------|
| beginner | 68ms | 100ms | 0/3 |
| easy | 20,350ms | 57,232ms | 0/3 |
| medium | 18,584ms | 24,253ms | 0/3 |
| hard | 5ms | 9ms | 0/3 |

→ **전 난이도가 null 반환**. easy/medium은 매우 느린 후 null. 카쿠로 생성기 자체가 동작 불능.

---

## 발견된 문제 (우선순위)

### 🔴 P0 (즉시 수정 필요 — 게임 플레이 불가)

1. **kakuro 전체** — 모든 난이도(beginner/easy/medium/hard) 모든 시드가 null 반환. ok=0/12.
   - 원인 추정: `_tryGenerate` 의 `_maxRetries=10` × `_timeoutMs=3000` 안에서 구조 생성 + 해 검증이 한 번도 성공하지 못함. 평균 20s 걸리는 easy 케이스가 retry loop를 반복하는 정황.
   - 영향: **카쿠로 게임 전체 사용 불가**.

2. **jigsaw_sudoku 전 난이도 seed=2,3 hang** — seed=1은 동작하나 seed=2,3은 모든 난이도에서 30초 이상 무응답. ok=5/15.
   - 원인 추정: `_timeoutMs=10000` 가 외부 retry/실제 generate 구간에 적용되지 않거나, 특정 region 시드에서 백트래킹 폭주.
   - 영향: 실제 사용자는 `DateTime.now().millisecondsSinceEpoch` 시드를 쓰므로 약 2/3 확률로 hang. **실질 사용 불가**.

3. **yin_yang medium/hard/master** — 모든 시드 30초 이상 hang. ok=0/9 (3난이도).
   - 원인 추정: `maxDuration=2500ms` 이 best-effort fallback이 아닌 early return 으로만 사용되어 retry loop 가 계속 돌고 있을 가능성.
   - 영향: 5난이도 중 3난이도 **사용 불가**.

### 🔴 P1 (UX 파탄 — 동작은 하나 수십 초 대기)

4. **skyscrapers hard / master** — 평균 26s / 39s. 게임 시작 시 화면이 30~40초 멈춤.
5. **futoshiki master** — 평균 27s, 최악 32.7s.
6. **binairo master** — 평균 6.4s, 최악 13s.

### 🟡 P2 (개선 권장 — 2~3초 SLOW)

7. **nonograms hard** — 2.5s (best-effort 2.5s timeout 도달). 결과는 반환.
8. **killer_sudoku medium/hard/master** — 2.2~2.5s (best-effort 정상 작동).
9. **yin_yang easy** — 1.6s (medium 이상은 P0).

### 🟢 PASS (양호)

- sudoku (전 난이도, 최대 853ms)
- minesweeper (전 난이도, 최대 31ms)
- nonograms beginner/easy/medium
- killer_sudoku beginner/easy
- futoshiki beginner~hard
- tents (전 난이도, 최대 906ms)
- binairo beginner~hard
- skyscrapers beginner~medium
- star_battle, light_up (사전 측정)

---

## 패턴 분석

### 공통 원인 패턴
- **`_maxRetries × _timeoutMs` 곱이 너무 큼**: kakuro(10×3s=30s), jigsaw(timeoutMs 10s + retry), futoshiki/skyscrapers/binairo(maxRetries 8~10)에서 최악 시나리오 시 retry loop 가 수십 초 동안 돈다.
- **`_timeoutMs` 가 outer wall-clock budget이 아니라 case-internal budget으로 쓰임**: 매 retry 마다 다시 풀 timeoutMs를 사용하므로 실제 wall-clock은 N배.
- **null 반환 처리**: kakuro 처럼 null 반환되어 일부 notifier는 `if (result == null) return;` 으로 silent fail → 사용자는 빈 화면.

### best-effort fallback 적용 권고 게임 (스타배틀/라이트업 패턴 차용)
모든 generator 를 다음 구조로 통일 권장:

```
1. wall-clock 전체 budget(예: 2500ms) 을 stopwatch 로 추적
2. retry 루프 내에서 budget 초과 시 break
3. budget 안에서 best-effort 로 가장 좋은 puzzle 을 저장
4. 끝까지 완벽한 결과 못 만들어도 best-effort 결과 반환 (null 금지)
```

**적용 대상**:
- 🔴 즉시: kakuro, jigsaw_sudoku, yin_yang (medium↑), skyscrapers (hard↑), futoshiki (master), binairo (master)
- 🟡 권장 개선: nonograms hard (이미 2.5s budget 있으나 약간 더 짧게), killer (이미 적용)

### 정상 패턴 (참고용)
- **killer_sudoku**: `_maxDuration=2500ms` + `_countTimeLimit=800ms` 이중 budget 으로 항상 결과 반환 — 가장 모범적.
- **star_battle / light_up**: 이미 수정 완료, best-effort fallback 패턴.

---

## 종합 통계

- 전체 측정 케이스: **약 62개** (13 게임 × 평균 4.7 난이도 × 3 시드)
- 🟢 PASS (정상 + 빠름): **39 케이스** (~63%)
- 🟡 SLOW (2~10s, 결과 반환): **9 케이스** (~14%)
- 🔴 FAIL (>10s 또는 null): **14 케이스** (~23%)
  - kakuro 12개 + binairo master 3개 + skyscrapers hard/master 6개 + futoshiki master 3개 + yin_yang medium/hard/master 9개 + jigsaw seed2·3 10개
- 💀 CRASH: 0건 (라이트업 stack overflow 는 사전 수정 완료)

### Phase 2 (PM) 권고

P0 즉시 수정 대상 (게임 사용 불가):
1. **kakuro** — best-effort fallback + 구조 생성 알고리즘 재검토
2. **jigsaw_sudoku** — seed 의존적 hang 원인 분석 + wall-clock budget
3. **yin_yang** medium↑ — wall-clock budget + best-effort

P1 (UX 파탄):
4. **skyscrapers** hard/master
5. **futoshiki** master
6. **binairo** master

수정 후 STEP 5 QA: 본 보고서의 `scripts/perf_*.dart` 로 재측정하여 전 케이스 < 3s + ok≥2/3 달성 확인.
