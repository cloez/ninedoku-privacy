# 스도쿠 힌트 시스템 시장 조사 — 5개 앱 비교 분석

> 작성일: 2026-06-15
> 대상 버전: Ninedoku v1.0.1+4 (4단계 점진 힌트 + 기법 분석기)
> 출처: 공개 리뷰/스토어 설명/공식 사이트 (실측 플레이 데이터 아님 — 일부 항목은 "정보 없음" 표기)

---

## 0. 우리 시스템(Ninedoku v1.0.1+4) 현황 요약

코드(`lib/core/sudoku/hint_engine.dart`) 기준 실제 구현:

| 항목 | 현재 구현 |
|---|---|
| 힌트 단계 | **4단계 점진 공개** (Highlight Region → Show Candidates → Explain Technique → Reveal Answer) |
| Lv.1 | 박스(또는 행/열) 영역 강조, "이 박스를 살펴보세요" |
| Lv.2 | 후보 숫자 표시 + 기법 이름 노출 (`hint.l2.{기법}`) |
| Lv.3 | 기법별 상세 이유 설명 (`hint.explain.{기법}`), 다른 셀의 선행 기법 안내 |
| Lv.4 | 정답 + 사용 기법명 동시 공개 |
| 지원 기법 | Naked/Hidden Single, Naked Pair/Triple, Hidden Pair, Pointing Pair, Box-Line Reduction, X-Wing (총 8종) |
| 셀 선택 | 후보 수가 가장 적은 빈 셀 자동 선정 (또는 사용자 선택 셀) |
| 다국어 | messageKey 기반 (한/영/일/중 4개국어 추정) |
| 비용 정책 | 정보 없음 (코드 범위 외 — UI 레이어 확인 필요) |

---

## 1. 앱별 상세 비교표

### 1.1 Sudoku.com (Easybrain) — 시장 1위

| 항목 | 내용 |
|---|---|
| 힌트 단계 | "Smart hints" — 정확한 단계 구분은 **공개 정보 없음**. 일반적으로 1~2단계(셀 강조 → 정답)에 가까운 매스마켓 구조로 알려짐 |
| 영역 강조 | 행/열/박스 하이라이트 (자동 중복 강조 기능과 통합) |
| 후보 시각화 | 사용자 메모(노트) 자동 채움 옵션 별도 제공 — 힌트와는 분리 |
| 정답 공개 | 1회 힌트로 셀에 정답을 직접 채워 넣는 방식 |
| 비용 정책 | **광고 시청형 무료 힌트** + 프리미엄 구독 (월/년) 시 무제한. 정확한 1일 무료 횟수는 정보 없음 |
| 메시지 톤 | 짧고 친근, 기법 이름은 거의 노출하지 않음 (매스마켓 친화) |
| 기법 사전 | 별도 "How to play" 페이지에 기본 규칙만, 본격적 기법 도감 없음 |
| 통계/배지 | 일/주/월 통계, 데일리 챌린지 캘린더, 트로피 — 기법 사용 통계는 없음 |
| 다국어 | 30개 이상 언어 |
| 학습 가치 | **낮음** — "스스로 풀게 하는" 학습보다 즉시 해결 위주 |

### 1.2 Andoku Sudoku 3

| 항목 | 내용 |
|---|---|
| 힌트 단계 | "Intelligent hints" — 다단계로 추정되나 정확한 단계 수 정보 없음. 다음에 둘 셀과 그 기법을 함께 안내 |
| 영역 강조 | 다양한 변형(X, Hyper, Percent, Color) 모두 강조 지원 |
| 후보 시각화 | 사용자 메모 자동 입력/소거 옵션 |
| 정답 공개 | 힌트 단계 진행 시 셀 정답을 알려주는 모드 존재 |
| 비용 정책 | 광고 지원 무료 / 프로 IAP. 무료에서도 힌트는 **무제한 사용 가능**으로 알려짐 |
| 메시지 톤 | 학습 지향 — 기법 이름 적극 노출 |
| 기법 사전 | **별도 "Tutorials" 섹션 보유** — 게임 상황 기반 단계별 튜토리얼. Hidden Single ~ XY Chain, Sashimi Swordfish까지 난이도 순 정렬 |
| 통계/배지 | 트로피, 누적 통계, 클라우드 동기화 |
| 다국어 | 다국어 지원 (영/독 위주, 한국어 정보 없음) |
| 학습 가치 | **높음** — "힌트가 기법 학습 수단"이라는 평가 다수 |

### 1.3 Logiq Lab

| 항목 | 내용 |
|---|---|
| 비고 | **이 정확한 명칭의 앱은 검색에서 확인되지 않음**. 유사 명칭 후보: Sudoku Coach, Sudoku Lab, Logiqo, Sudozen 등 학습 중심 후발 앱군 |
| 일반 패턴(이 카테고리) | "왜 이 숫자가 들어가는가"를 설명하는 다단계 힌트, 단계별 튜토리얼, 캠페인 모드 |
| 기법 수 | 학습 중심 앱들은 9~41개 기법 커버 (Naked/Hidden Single ~ XY-Wing, Swordfish 등) |
| 학습 가치 | 카테고리 특성상 매우 높음 — 단, 구체 앱 미특정으로 상세 비교 불가 |
| 권장 | 사용자가 다른 앱을 의도했을 가능성. **재확인 필요** |

### 1.4 Good Sudoku (Zach Gage)

| 항목 | 내용 |
|---|---|
| 힌트 단계 | **AI 솔버 상시 가동형** — 사용자의 노트/입력을 실시간 분석, 막혔을 때 "다음 가장 논리적인 수"를 위치+기법 이름과 함께 제시. 별도 점진 단계 UI보다는 "필요한 만큼 도와주는" 적응형 |
| 영역 강조 | 우아한 컬러 그라데이션으로 행/열/박스 동시 강조, 후보 셀 사이의 관계선 시각화 |
| 후보 시각화 | **상시 자동 후보 표시(Pencil marks) 옵션** — 토글 가능. "Talkback" 노트 입력 시스템이 차별점 |
| 정답 공개 | 명시적 "Reveal" 버튼은 존재하나, 그보다 **기법 설명 우선** 정책 |
| 비용 정책 | 유료 앱 (또는 구독) — 광고 없음. 힌트는 게임 내 무제한 |
| 메시지 톤 | **간결+위트** — "Look here", "You can place X because…" 식. 기법 이름을 노출하되 짧은 1~2줄로 요약 |
| 기법 사전 | **인앱 튜토리얼 + 기법 가이드** — 난이도 상승 시 "이번 난이도에서 배우는 기법" 안내 |
| 통계/배지 | 난이도별 기록, 데일리 — 기법 사용 통계는 정보 없음 |
| 다국어 | 영어 위주 (다국어 범위 정보 없음) |
| 학습 가치 | **매우 높음** — "고급 기법을 가장 잘 가르치는 앱"이라는 평가 다수 |

### 1.5 Cracking The Cryptic (CTC)

| 항목 | 내용 |
|---|---|
| 힌트 단계 | **수작업 힌트(Hand-written hints)** — Mark & Simon 본인이 퍼즐별로 직접 작성. 솔버 자동 생성 아님 |
| 영역 강조 | SudokuPad 기반 풍부한 시각화(컬러링, 화살표, 케이지) — 매우 강력 |
| 후보 시각화 | 코너/센터 펜슬 마크, 컬러링 도구 |
| 정답 공개 | **숫자 자체는 알려주지 않음** — "방향만" 제시하는 게 원칙 |
| 비용 정책 | 앱 무료 + 퍼즐 팩 IAP. 힌트는 해당 퍼즐에 포함 |
| 메시지 톤 | **길고 교육적, 친근** — "Look at row 4 — does this column have somewhere for the 3 to go?" 식 산문체 |
| 기법 사전 | 별도 가이드는 약함 — 대신 유튜브 채널이 사실상 도감 역할 (외부 의존) |
| 통계/배지 | 정보 없음(고급자 대상이라 게이미피케이션 약함) |
| 다국어 | 영어 전용으로 알려짐 |
| 학습 가치 | **고급자에 매우 높음**, 초보자에는 진입 장벽 큼 |

---

## 2. 항목별 횡단 비교 매트릭스

### 2.1 힌트 점진 단계 수

| 앱 | 단계 수 | 정답 공개 옵션 |
|---|---|---|
| Sudoku.com | 1~2 (실질 1) | ✅ (즉시) |
| Andoku 3 | 다단계(추정 2~3) | ✅ |
| Good Sudoku | 적응형(단계 X) | ✅ (있으나 기법 우선) |
| CTC | 1 (수작업, 산문) | ❌ (원칙적으로) |
| **Ninedoku** | **4단계** | ✅ (Lv.4) |

→ **Ninedoku의 4단계 점진 공개는 상위권 수준**. Sudoku.com보다 학습 친화적이고, Andoku와 동급, Good Sudoku의 적응형보다 사용자 통제권이 명확.

### 2.2 비용 정책

| 앱 | 모델 | 무료 힌트 |
|---|---|---|
| Sudoku.com | 광고+구독 | 광고 시청 시 추가 (정확 횟수 정보 없음) |
| Andoku 3 | 광고+프로 IAP | 사실상 무제한 |
| Good Sudoku | 유료/구독 | 무제한 |
| CTC | 무료 앱+퍼즐 IAP | 퍼즐당 포함 |
| **Ninedoku** | **정보 없음** (UI 레이어 확인 필요) | — |

### 2.3 시각 효과

| 항목 | 1위 | 2위 | 비고 |
|---|---|---|---|
| 영역 강조 | Good Sudoku | CTC | Ninedoku Lv.1은 박스 단위 펄스 — 충분 |
| 후보 시각화 | Good Sudoku (상시 자동) | Andoku | Ninedoku는 Lv.2에서만 노출 — **차별점이자 약점** |
| 정답 셀 강조 | Sudoku.com | Good Sudoku | Ninedoku는 Lv.4 단일 셀 강조만 |
| 소거 후보(빨강 X 등) | Good Sudoku만 본격 구현 | — | Ninedoku 미구현 |

### 2.4 학습 가치

| 앱 | 기법 노출 | 기법 사전 | 기법 통계 | 배지(기법 기반) |
|---|---|---|---|---|
| Sudoku.com | 약함 | ❌ | ❌ | ❌ |
| Andoku 3 | 강함 | ✅ | △ | △ |
| Good Sudoku | 강함 | ✅ | 정보 없음 | 정보 없음 |
| CTC | 산문체 | △ | ❌ | ❌ |
| **Ninedoku** | **강함** (Lv.2~4) | ❌ (코드상 미확인) | ❌ | ✅ (전체 배지 시스템 보유) |

---

## 3. Ninedoku vs 시장 1위(Sudoku.com) 단원

### 3.1 우리가 명확히 앞서는 것

1. **4단계 점진 공개의 학습 곡선** — Sudoku.com이 "즉시 정답" 위주인 반면 Ninedoku는 사용자가 원하는 만큼만 단계를 열 수 있음. 자존심 보존 + 학습 가치 확보.
2. **기법 이름·이유의 명시적 노출** — `hint.l2.{기법}`, `hint.explain.{기법}` 키 분리. Sudoku.com은 기법 이름을 거의 노출하지 않음.
3. **8종 기법 분석기** (`TechniqueAnalyzer.findNextTechnique`) — 매스마켓 앱은 보통 Naked/Hidden Single에 그침. Ninedoku는 X-Wing까지 커버.
4. **다른 셀의 선행 기법 안내** — "이 셀은 직접 풀기 어렵습니다. (r,c)에서 Pointing Pair를 먼저…" — 매우 교육적, Sudoku.com 미보유.
5. **완전 오프라인 + 개인정보 미수집** — Sudoku.com은 광고 SDK 트래킹 다수.

### 3.2 따라잡아야 할 것

1. **자동 후보 메모(Auto Pencil)** — Sudoku.com 표준 기능. 힌트와 별개이지만 힌트 사용 빈도를 줄여줌. (Ninedoku는 수동 메모만 추정)
2. **광고 보상 힌트 흐름** — F2P 정책 결정 필요. 무료 무제한 vs 광고 시청. (Ninedoku 정책 정보 없음)
3. **틀린 셀 자동 강조 옵션** — Sudoku.com "auto-check"는 사실상 약한 힌트. 토글 옵션 검토.
4. **데일리 챌린지 캘린더** — 힌트와 직접 무관하나, 힌트 사용 동기를 만드는 컨텍스트.

### 3.3 차별화 포인트 제안

1. **"학습 모드 vs 빠른 모드" 토글** — 학습 모드에서는 Lv.2(기법명)를 건너뛰지 못하게, 빠른 모드에서는 Lv.4 직행. Sudoku.com/Good Sudoku 모두 미보유.
2. **기법 마스터 배지** — 이미 보유한 배지 시스템에 "Pointing Pair를 힌트 없이 10회 적용" 등 행동 기반 배지 추가. CTC/Good Sudoku도 없음.
3. **"왜 이 셀이 가장 쉬운가" 메타 힌트** — Lv.0(가칭)으로 "후보가 2개뿐인 셀이 3개 있습니다" 같은 전체 보드 관점 안내.

---

## 4. 벤치마크 — Ninedoku가 채택할 만한 베스트 프랙티스 5선

구현 난이도: **L**(Low, 1~2일) / **M**(Medium, 3~7일) / **H**(High, 1주+)

### ① Auto Pencil Marks 토글 — 난이도 **M**
- **출처**: Sudoku.com, Good Sudoku 표준
- **내용**: 설정에서 "자동 후보 표시" 토글 제공. 켜면 모든 빈 셀에 후보 자동 채움/소거.
- **효과**: 힌트 사용량 자체를 줄여, Lv.4(정답 공개) 의존도 감소 → 학습 효과 상승.
- **위험**: 노트 자동 채움 로직은 이미 `_getCandidateSet` 보유 → 재사용 가능. UI 레이어가 메인 작업.

### ② Lv.2 시각화 강화 — 소거 사유 표시 — 난이도 **M**
- **출처**: Good Sudoku
- **내용**: Lv.2에서 후보를 보여줄 때, "이 후보가 왜 후보인지" 같은 행/열의 영향 셀을 옅은 색으로 연결.
- **효과**: 텍스트 설명을 읽지 않아도 시각만으로 학습 가능. 다국어 부담 감소.
- **위험**: 보드 위젯 수정 범위 큼.

### ③ 기법 사전(In-app Glossary) — 난이도 **L~M**
- **출처**: Andoku 3
- **내용**: 설정/메뉴에 "풀이 기법 도감" 별도 화면. 8개 기법 각각 정적 일러스트 + 예제 + "지금까지 사용한 횟수".
- **효과**: 학습 가치 즉시 향상, 배지 시스템과 연동 가능.
- **위험**: 일러스트(예제 보드)는 정적 데이터로 충분 → 콘텐츠 작업이 메인.

### ④ 광고 보상 힌트 + 프리미엄 무제한 — 난이도 **M**
- **출처**: Sudoku.com 모델
- **내용**: 무료 사용자에게 1게임당 무료 힌트 N회 후 광고 보상. 1회 광고당 1힌트(또는 Lv.4 1회).
- **효과**: F2P 수익화. 다만 "완전 오프라인 + 개인정보 미수집" 원칙과 충돌 가능 → **GD/UX/PM 합의 안건**.
- **위험**: 광고 SDK 도입 시 설계 원칙(INTERNET 권한 금지) 위반. **현 원칙상 채택 불가, 대안으로 일일 무료 힌트 제한 + 시청 광고 없는 보너스 시스템 검토 권장**.

### ⑤ 기법 기반 배지(행동 배지) — 난이도 **L**
- **출처**: 없음(독자 차별화)
- **내용**: "힌트 없이 Hidden Single 30회 적용", "X-Wing을 힌트로 배운 후 직접 5회 사용" 등. `TechniqueAnalyzer`가 사용자 입력이 어떤 기법에 해당하는지 이미 판정 가능.
- **효과**: 학습 동기 강화. 시장 어떤 앱도 본격 구현 안 함 → **차별화 포인트**.
- **위험**: 통계 스토리지 스키마 확장 필요(누적 카운터).

---

## 5. 종합 권고

**전략**: Ninedoku는 이미 "학습 친화적 4단계 점진 힌트 + 8종 기법 분석"으로 매스마켓(Sudoku.com)보다 앞서 있고, 학습 카테고리 강자(Good Sudoku, Andoku)와 동급. 다만 시각 강화와 기법 사전이 부족.

**우선순위**:
1. **단기(R0 패치)**: ③ 기법 사전 + ⑤ 기법 기반 배지 — 기존 자산(TechniqueAnalyzer, 배지 시스템) 재사용 가능, 차별화 효과 큼.
2. **중기(R0 후속)**: ① Auto Pencil 토글 + ② Lv.2 시각화 강화 — UX 가치 큼.
3. **장기/보류**: ④ 광고 보상 힌트 — 오프라인 원칙과 충돌, **PM이 사용자/GD 합의로 결정**.

**합의 필요 안건**(CLAUDE.md 의사결정 원칙 준수):
- ① ② ③ ⑤: GD + UX 합의 후 진행
- ④: 설계 원칙 예외 사항 — 사용자 최종 결정 필수

---

## 출처

- [Sudoku.com — Easybrain](https://easybrain.com/sudoku)
- [Sudoku.com on Google Play](https://play.google.com/store/apps/details?id=com.easybrain.sudoku.android)
- [Andoku Sudoku 3 — Andoku.com](https://www.andoku.com/apps/andoku3/)
- [Andoku Sudoku 3 Guide — Zilaba](https://www.zilaba.com/guides/andoku-sudoku-3-guide)
- [Good Sudoku by Zach Gage — App Store](https://apps.apple.com/us/app/good-sudoku-by-zach-gage/id1489118195)
- [Good Sudoku — Press Kit](https://www.playgoodsudoku.com/presskit/)
- [Game Day: Good Sudoku — MacStories](https://www.macstories.net/reviews/game-day-good-sudoku/)
- [Cracking the Cryptic — App Store](https://apps.apple.com/us/app/cracking-the-cryptic/id1629992934)
- [SudokuPad — CTC](https://sudokupad.app/)
- [Sudoku Platforms With Guided Paths — LoveSudoku](https://lovesudoku.net/en/articles/sudoku-guided-path-platforms/)
- [Sudoku Coach — sudokucoach.app](https://sudokucoach.app/)

> **주의**: "Logiq Lab"은 검색에서 정확히 일치하는 앱이 확인되지 않음. 사용자 확인 필요 (Sudoku Coach / Sudoku Lab / Logiqo 등 유사 명칭 후보 존재).
