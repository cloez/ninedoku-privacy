# 비나이로(Binairo) QA 체크리스트 실적

> 공통 체크리스트(`test/GAME_QA_CHECKLIST.md`) 기준 검증 결과
> 검증일: 2026-06-01
> 검증자: QA + UX 전문가

---

## A. 엔진 테스트 — ✅ 30개 (binairo_engine_test.dart)

- [x] A1. 보드 모델: 5개 (빈 보드, getValue/setValue, JSON, fixed, isComplete)
- [x] A2. 솔버: 8개 (isComplete, 3연속/균등/동일행 위반, solve, 유일해, 모순, 불변성)
- [x] A3. 생성기: 8개 (5난이도 생성, 유일해, 결정성, 시드 다름, 3초 이내, 100회)
- [x] A4. 힌트: 5개 (Level 1~4, 솔루션 일치)
- [x] A5. 통합: 4개 (전체 사이클, 직렬화 후 풀이, 빈 보드 힌트)

## B. 게임 상태 테스트 — ✅ 20개 (binairo_state_test.dart)

- [x] B1. State 모델: 13개 (생성, copyWith, JSON, enum 왕복, selectedCell null, inputMode)
- [x] B2. 등급 산정: 7개 (S/A/B/C 조건, 난이도별 시간, 임계값)

## C. 게임 로직 테스트 — ✅ 17개 (binairo_notifier_test.dart)

- [x] C1. 기본 동작: 6개 (초기 null, startNewGame, size 일치, pause/resume, giveUp, hasOngoingGame)
- [x] C2. 셀 입력: 5개 (black/white/erase 모드, 토글, 고정 셀)
- [x] C3. Undo: 2개 (되돌리기, 빈 스택 안전)
- [x] C4. 완료 판정: 2개 (isCompleted, 기록 저장)
- [x] 엣지 케이스: 2개 (null 상태 액션, setInputMode)

## D. 저장/복구 테스트 — ✅ 11개 (binairo_storage_test.dart)

- [x] D1. 게임 기록: 5개 (저장/조회, 누적, 빈 목록, JSON, 삭제)
- [x] D2. 배지: 6개 (획득/조회, 복원 병합, 삭제, getAllBadges, 재평가 제외)

## E. 백업 통합 테스트 — ✅ 6개 (binairo_backup_test.dart)

- [x] completedGames 키 존재
- [x] badges 키 존재
- [x] 라운드트립 일치
- [x] 덮어쓰기 복원
- [x] 빈 데이터
- [x] 스도쿠+비나이로 혼합

## F. UI/UX 일관성 — ✅ UX 전문가 수동 검증

- [x] F1. 골든 패스 (허브→홈→난이도→플레이→완료→결과→허브)
- [x] F2. 하드웨어 백키 (홈: 무시, 플레이: 다이얼로그, 일시정지: resume, 결과: 홈)
- [x] F3. 가로 모드 (보드 좌측 + 컨트롤 우측, AppBar 숨김)
- [x] F4. 결과 화면 (등급/통계/버튼순서/배지팝업/배지칩 — 스도쿠와 일치)
- [x] F5. 통계/배지 접근 (홈→탭 자동선택, 허브→전체)
- [x] F6. 다국어 4개국어 (이름/설명/규칙/힌트/배지/결과/다이얼로그)

## G. 플랫폼 테스트 — ✅ 코드 리뷰

- [x] G1. 오프라인: INTERNET 권한 없음 확인
- [x] G2. 성능: 생성 3초 이내 (테스트 검증), UI 응답 정상
- [x] G3. 앱 생명주기: WidgetsBindingObserver + autoSave
- [x] G4. 마지막 게임 복귀: lastGameRoute 저장/복원

## H. 리그레션 — ✅

- [x] 기존 테스트 전체 통과 (725개)
- [x] 스도쿠 골든 패스 영향 없음
- [x] 허브 카드 정상 표시
- [x] 통합 통계/배지에 비나이로 포함
- [x] 백업/복원에 비나이로 포함

---

## 총 자동 테스트: 84개 (최소 71개 기준 초과 ✅)

| 섹션 | 기준 | 실적 |
|------|------|------|
| A. 엔진 | 30개 | 30개 ✅ |
| B. 상태 | 12개 | 20개 ✅ |
| C. 로직 | 15개 | 17개 ✅ |
| D. 저장 | 8개 | 11개 ✅ |
| E. 백업 | 6개 | 6개 ✅ |
| **합계** | **71개** | **84개** ✅ |
