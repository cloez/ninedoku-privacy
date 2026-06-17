# 스도쿠 힌트 시스템 구현 사양서

> 작성: 모바일 기획자
> 입력: `docs/sudoku_hint_champion_review.md` (챔피언 권장안)
> 일자: 2026-06-15
> 정책: 별도 배포 없음 — version 1.0.1+4 유지

---

## 1. 변경 배경

챔피언 검토 결과: **엔진은 우수(9/10), 프레젠테이션은 부재(2/10)**
- `HintResult`의 message/highlightCells/explanation이 생성되지만 사용자에게 전달되지 않음
- 시각 강조, 텍스트 표시, 다국어 모두 0%
- 풀이 기법 자동 감지(8종)는 작동하지만 사용자가 알 수 없음

→ **이번 사이클: 시각/텍스트/다국어 도달성 100% 달성**
→ **다음 사이클: 추가 기법(Naked Pair, Pointing Pair 등)**

---

## 2. 핵심 변경 — 4단계 점진적 공개

### 2.1 Level 1: "영역 안내"
- **트리거**: 힌트 버튼 첫 탭
- **시각**: 대상 박스/행/열 전체에 옅은 노랑 펄스 (500ms × 2회)
- **메시지**: "이 박스를 살펴보세요" (스낵바 5초)
- **사운드**: hint.wav (이미 있음)
- **비용**: hintCount += 1

### 2.2 Level 2: "기법 안내"
- **트리거**: 힌트 버튼 두 번째 탭
- **시각**:
  - 기법 관련 셀들에 초록 테두리 (2px)
  - 화면 상단에 기법 이름 배너 (예: "Hidden Single")
- **메시지**: "Hidden Single — 이 박스에서 숫자 5는 한 셀에만 들어갈 수 있어요"
- **비용**: hintCount 그대로 (Level 1과 합산, 같은 힌트 사이클)

### 2.3 Level 3: "이유 설명"
- **트리거**: 힌트 버튼 세 번째 탭
- **시각**:
  - 대상 셀 배경 글로우 (노랑→초록 전환)
  - 같은 행/열/박스에서 소거되는 셀에 옅은 빨강 X 표시
  - 후보 숫자 시각화 (메모로 표시)
- **메시지**: "행 4, 열 7에는 1,3,6,8,9가 모두 다른 곳에 있어요. 남은 후보는 5입니다."
- **비용**: hintCount 그대로

### 2.4 Level 4: "정답 공개"
- **트리거**: 힌트 버튼 네 번째 탭
- **시각**:
  - 정답 셀 글로우 효과 (scale 1.2 → 1.0, 400ms)
  - 자동 입력 애니메이션
- **메시지**: "이 셀은 5입니다 — Naked Single 기법으로 풀었어요"
- **사운드**: line_complete.wav
- **비용**: hintCount += 2 (총 3 카운트)

### 2.5 Reset 동작
- 사용자가 다른 셀을 탭하거나 새 힌트 버튼 누르면 Level 0으로 리셋

---

## 3. UI 컴포넌트

### 3.1 신규 위젯
**`HintBanner`** (`lib/features/game/widgets/hint_banner.dart`):
- 화면 상단 (게임 정보바 아래)에 표시
- 단계별 메시지 + 기법 이름 + 닫기 버튼
- AnimatedSize로 진입/퇴장
- 5초 후 자동 페이드아웃 (선택)

**`HintRegionPulse`** (`lib/features/game/widgets/hint_region_pulse.dart`):
- 보드 위 오버레이
- 박스/행/열 영역 펄스 (Level 1)
- 옅은 노랑 (alpha 0.25), 500ms × 2회 페이드 in/out

### 3.2 보드 위젯 수정
`sudoku_board_widget.dart`에서:
- `hintTargetCell` 강조 (이미 일부 적용)
- `lastHintResult.highlightCells` 셀 추가 강조
- Level 3: 소거 후보 빨강 X 표시
- Level 4: 정답 글로우

### 3.3 게임 화면 수정
`game_screen.dart`에서:
- 보드 위에 `HintBanner` 추가
- 보드 자체를 `HintRegionPulse`로 감싸기 (Level 1만)

---

## 4. 다국어 문자열 (4언어)

### 4.1 단계 메시지
- `hint.level1.box`: "이 박스를 살펴보세요" / "Look at this box" / "このボックスを見てください" / "查看这个方格"
- `hint.level1.row`: "이 행을 살펴보세요"
- `hint.level1.col`: "이 열을 살펴보세요"

### 4.2 기법 이름 (8종)
- `hint.technique.nakedSingle`: "유일 후보 (Naked Single)" 등
- `hint.technique.hiddenSingle`: "숨은 후보 (Hidden Single)"
- `hint.technique.nakedPair`: "유일 쌍 (Naked Pair)"
- `hint.technique.hiddenPair`: "숨은 쌍 (Hidden Pair)"
- `hint.technique.pointingPair`: "포인팅 쌍 (Pointing Pair)"
- `hint.technique.boxLine`: "박스-라인 (Box-Line Reduction)"
- `hint.technique.xWing`: "X-Wing"
- `hint.technique.swordfish`: "Swordfish"

### 4.3 기법 설명 템플릿
- `hint.explain.nakedSingle`: "이 셀에 들어갈 수 있는 숫자는 하나뿐입니다."
- `hint.explain.hiddenSingle`: "이 {area}에서 숫자 {n}이 들어갈 수 있는 곳은 한 곳뿐입니다."
- (8종 각각)

### 4.4 정답 메시지
- `hint.answer`: "이 셀은 {n}입니다 — {technique} 기법으로 풀었어요"

### 4.5 닫기 버튼
- `hint.close`: "닫기"

---

## 5. 비용 정책 (변경)

기존: 힌트 버튼 1번 누를 때마다 hintCount += 1
**변경**: 한 힌트 사이클(Level 1~4)에 hintCount += 1 (Level 4 도달 시 추가 +1, 총 2)

근거: 사용자가 Level 1만 보고 풀이를 알아내면 hint 1회만 카운트하는 게 공정함. Sudoku.com 정책과 일치.

---

## 6. 영향 받지 않음
- 다른 12게임 (스도쿠 전용)
- 배지 평가 (hintCount 의미는 그대로)
- 저장된 게임 (state 직렬화 호환)

---

## 7. 영향 받음 (확인 필요)
- `GameGrade.evaluate` — hintCount 기반 계산. 정책 변경 후 균형 유지.
- 배지 `no_hint` 조건 — 사용자가 Level 1까지만 봐도 카운트 → 의도 동일.

---

## 8. 코드 변경 영역

### 신규 파일
- `lib/features/game/widgets/hint_banner.dart`
- `lib/features/game/widgets/hint_region_pulse.dart`

### 수정 파일
- `lib/features/game/game_state.dart`:
  - `lastHintResult` 필드 확인 (이미 있음)
  - `hintTechnique: String?` 필드 추가 (기법 이름)
  - `hintMessageKey: String?` 필드 추가 (다국어 키)
- `lib/features/game/game_notifier.dart`:
  - `useHint()` 메서드: 단계별 동작 정의 + 비용 정책
  - 동일 힌트 사이클 내 추가 누름 처리
- `lib/features/game/widgets/sudoku_board_widget.dart`:
  - `hintTargetCell` 강조 강화
  - `highlightCells` (영역) 강조 추가
  - Level 3/4 시각 효과
- `lib/features/game/screens/game_screen.dart`:
  - `HintBanner` 추가
  - `HintRegionPulse` 보드 감싸기
- `lib/shared/l10n/app_strings.dart`:
  - 4언어 힌트 키 약 30개 추가
- `lib/core/sudoku/hint_engine.dart`:
  - 메시지 하드코딩 → 다국어 키 반환
  - 기법 이름을 키 형태로 반환

---

## 9. 테스트 계획

- `test/core/sudoku/hint_engine_test.dart`: 다국어 키 반환 검증
- `test/features/game/game_notifier_test.dart`:
  - useHint 호출 4번 → 각 단계 정확
  - 셀 변경 시 Level 0 리셋
  - 비용 정책 (총 2 카운트)

---

## PM 검증

✅ 챔피언 권장안 P0 모두 반영
✅ 시각/텍스트/다국어 도달성 보장
✅ 13게임 영향 없음 (스도쿠 전용)
✅ 다국어 4언어 키 명시
✅ 모션 감소 대응 (motionScale 활용)

→ **DEV 진행 승인**

---

## 10. 합의 — 후속 사이클 (P1)
- 추가 기법 (Naked Pair/Triple, Pointing Pair, X-Wing)
- 풀이 기법 학습 모드
- 통계: 자주 사용한 기법 분석
- 배지: "기법 마스터" 등
