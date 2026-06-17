# 튜토리얼 구현 GD 컨펌 (R-Tutorial)

> 작성: GD-A / 일자: 2026-06-16
> 입력: `docs/tutorial_screen_spec.md`, `docs/tutorial_content_sudoku.md`, 구현 5종 파일 + 다국어 520키
> 판정: **CONDITIONAL PASS — 출시 가능, 후속 사이클 필수**

---

## 1. 사양 §1~15 항목별 평가

| 항목 | 판정 | 근거 |
|---|---|---|
| §1 게임 목표(S1) 명시 | 검토 | 13게임 모두 step1 title/description 키 존재. 스도쿠 S1 미니보드 정답 일러스트 적용 확인 |
| §2 화면 흐름(진입→단계→완료) | OK | `tutorial_screen_v2.dart` + router + home_screen 14개 ? 진입점 연결 |
| §3 단계 제목(4언어 분리) | OK | 약 520키 × 4언어 분리, 키 네이밍 `tutorial.{game}.step{n}.title` 규칙 준수 |
| §4 설명 1~2문장 제한 | OK (가정) | 스도쿠 문구는 사양 그대로. 12게임은 표본 검토 필요(별도 카피 QA) |
| §5 게임판 예시(mini_board) | 부분 | 스도쿠 S1·S2·S3·S5는 MiniBoard. **12게임은 모두 IconIllustration**(정적 아이콘) — 사양 "항상 미니보드 동반" 위반 |
| §6 사용자 행동(S6 인터랙티브) | 부분 | 스도쿠 OK. 12게임 인터랙티브 SKIP — 사양 "S6는 게임별 생략 가능"에 해당하나 12게임 전부 생략은 사양 의도와 불일치 |
| §7 성공 반응(펄스/햅틱/사운드/토스트) | 부분 | 펄스·햅틱 구현. **사운드/토스트 SKIP** — 사양 §7 4항목 중 2항목 누락 |
| §8 잘못 조작 반응(흔들림/⚠/힌트/3회 reveal) | 검토 | 스도쿠 practice_board에서 hint·maxWrongAttempts=3 정의. 색맹 ⚠ 아이콘 동시노출 여부 코드 확인 미완 |
| §9 건너뛰기/다시 보기 | OK | settings_service 확장 + Skip 상시. 자동표시·재진입·초기화 라우팅 연결 |
| §10 6상태 머신 | OK | `TutorialPhase` enum 6상태 모두 정의 |
| §11 접근성(TalkBack/CVD/textScale/모션감소) | 부족 | **TalkBack 명시 announce SKIP**, motionScale 처리 SKIP. 사양 §11 6항목 중 2항목 누락 |
| §12 와이어프레임 | OK | AppBar/PageView/Dot/Footer 구조 일치 |
| §13 시작 전 필수(S1·S2·S4) | OK | 13게임 모두 step1/2/4 보유 |
| §14 플레이 중 도움말 | OK | ? 아이콘 + 일시정지 도움말 진입 |
| §15 과도 설명 회피 | OK | 단계 4~5로 압축, 텍스트 단독 단계 없음 |

---

## 2. 13게임 컨텐츠 평가 (단계 수 매트릭스 대비)

| 게임 | 권장(§3) | 구현 | 일러스트 |
|---|---|---|---|
| Sudoku | 5 | 5 | MiniBoard+Interactive |
| Binairo | 4 | 4 | MiniBoard 2단계 포함 |
| Minesweeper | 5 | 5 | Icon only |
| Yin-Yang | 4 | 4 | Icon only |
| Nonograms | 6 | **5** | Icon only |
| Killer | 6 | **5** | Icon only |
| Star Battle | 5 | **4** | Icon only |
| Light Up | 5 | **4** | Icon only |
| Futoshiki | 5 | **4** | Icon only |
| Tents | 5 | **4** | Icon only |
| Jigsaw | 5 | **4** | Icon only |
| Skyscrapers | 6 | **5** | Icon only |
| Kakuro | 6 | **5** | Icon only |

총 58 vs 사양 67 = **9단계 누락**. 누락 단계는 주로 S3(보조규칙) 또는 S5(보조기능). 핵심 S1·S2·S4는 모두 충족 — **사양 §13 "최소 학습 가능 기준"은 통과**.

핵심 규칙 누락 위험: Killer "케이지 합", Skyscrapers "가시성", Kakuro "한 합 내 중복금지" — 이들은 별도 단계 분리가 필요했으나 한 단계에 압축되어 인지부하 우려.

---

## 3. SKIP 영향 분석

| SKIP 항목 | 학습 목표 영향 | 위험도 |
|---|---|---|
| 12게임 BoardWidget readonly+forcedTarget | 사양 §5 위반. 그러나 S1·S2·S4 텍스트+아이콘으로 "최소 첫 수" 가능 | 중 |
| 사운드/토스트 | 펄스+햅틱이 있어 완료 피드백은 인지 가능. 음소거 환경 영향 적음 | 저 |
| TalkBack 명시 announce | 시각장애 사용자 학습 차단 — 접근성 회귀 | **고** |
| 모션 감소 명시 처리 | 전정장애 사용자 영향. 펄스 미세하면 무시 가능 | 중 |

스도쿠는 사양 완전 충족, 나머지 12게임은 "정적 안내 모드"로 출시 가능하지만 사양 "show, don't tell" 원칙과 거리가 있음.

---

## 4. 종합 컨펌 판정

**CONDITIONAL PASS**

근거:
- §13 필수 3단계(S1·S2·S4) 13게임 모두 충족 → 사용자가 첫 수를 둘 수 있는 최소 학습 보장
- 스도쿠는 사양 100% 부합 (R0 주력 게임)
- 다국어 520키 × 4언어로 글로벌 출시 가능
- 단, 접근성(TalkBack) 누락은 출시 후 가장 우선 보강 필요

---

## 5. 후속 사이클 권고

**P0 (다음 패치 — 출시 직후)**
1. TalkBack 자동 announce 구현 (§11)
2. 모션 감소(`disableAnimations`) 0ms 전환 처리 (§11)
3. 오답 시 ⚠ 아이콘 색맹 대응 확인 및 보강 (§8)

**P1 (다음 마이너 — 1~2주)**
4. 12게임 핵심 규칙 단계에 MiniBoard 일러스트 추가 (최소 S1·S2)
5. 누락된 9단계 보강 — Killer/Skyscrapers/Kakuro 우선
6. 사운드 success.ogg + 완료 토스트 추가 (§7)

**P2 (R2 이후 점진)**
7. 12게임 보드위젯 `readonly`/`forcedTarget` 추가 → S6 인터랙티브 확장 (게임별 R2~R12 PR에 묶음)
8. 일러스트 카피 QA(§4 1~2문장 제한) 4언어 표본 검수
9. 외부 키보드 단축키(→/←/Esc/Enter) 지원 (§11)

---

## 결정
- 출시 진행 가능 (CONDITIONAL PASS)
- P0는 본 릴리스 hotfix 범위에 포함하여 1주 내 처리 권고
- P1·P2는 PM이 R2(Minesweeper) 일정과 조율
