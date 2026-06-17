# 스토어 정식 릴리즈 마스터 플랜

> 작성: PM (5인 전문가 종합 후)
> 일자: 2026-06-05
> 트리거: 결벽적 UX 전문가 최종 검토 요청

---

## 1. 5인 전문가 판정 종합

| 전문가 | 판정 | 블로커 | P1 | 보고서 |
|--------|------|--------|-----|--------|
| 결벽적 UX | 🟡 CONDITIONAL | 0 | 12 | `docs/ux_perfectionist_final.md` |
| QA 베테랑 | 🟡 CONDITIONAL | 0 | 4 | `docs/qa_release_audit.md` |
| 접근성/i18n | 🔴 **부적합** | **2** | 5 | `docs/a11y_i18n_audit.md` |
| 컴플라이언스 | 🟡 CONDITIONAL | 0 | 8 | `docs/store_compliance_audit.md` |
| 성능/안정성 | 🟢 STABLE | 0 | 6 | `docs/performance_stability_audit.md` |

**최종 PM 판정**: 🔴 **현 상태 정식 릴리즈 차단** (접근성 블로커 2건)

---

## 2. 차단 항목 (B0)

### B0-1: 12개 신규 게임 Semantics 부재
- **영향**: TalkBack 사용자 12게임 불가 → Play Store 접근성 정책 위반
- **위치**: `lib/games/{12개}/widgets/*_board_widget.dart`, `*_game_screen.dart`
- **예상 작업**: 약 20시간
- **담당**: DEV (게임별 Semantics 라벨 추가)

### B0-2: 스도쿠 Semantics 한국어 하드코딩
- **영향**: 영/일/중 시스템 사용자가 한국어로 발표받음
- **위치**: `lib/features/game/widgets/sudoku_board_widget.dart:110`
- **예상 작업**: 2시간
- **담당**: DEV (다국어 키로 교체)

---

## 3. 단계적 릴리즈 로드맵

### Phase 1: 알파 유지 (현재 v1.0.0+4)
- ✅ 이미 알파 트랙에 배포됨
- 내부 테스터 피드백 수집

### Phase 2: B0 패치 (v1.0.1 → 정식 출시)
**필수 작업** (예상 1주):
- B0-1: 12게임 Semantics 추가
- B0-2: 스도쿠 Semantics 다국어화
- 함께 처리할 P1 핵심 (시너지):
  - UX P1-4: generator 로딩 "퍼즐 생성 중" 텍스트 (사용자 의심 해소)
  - UX P1-9: generator 실패 시 SnackBar + 재시도 (안정성)
  - QA P1-2: 가로 모드 자동회전 대응 (정사각형 보드 비율)
  - A11y P1: 오답 색맹 대응 (패턴/심볼 병행)
  - 컴플라이언스 P1-1,2: ProGuard/R8 활성화 (AAB 20~30% 감소)
  - 컴플라이언스 P1-3: 키스토어 .gitignore 확인
  - 컴플라이언스 P1-4: 스토어 메타데이터 4언어 준비
  - 컴플라이언스 P1-5: 데이터 안전 양식
  - 컴플라이언스 P1-6: 개인정보처리방침 1쪽

**Phase 2 검증**:
- 5인 재점검 (B0 해결 + P1 일부)
- TalkBack 수동 테스트 (실기기 1시간)
- 4언어 시스템 폰트 렌더링 확인

### Phase 3: v1.0.1 정식 출시
- AAB 빌드 (51.6MB, R8 적용 후 40MB대 예상)
- 내부 테스트 트랙 24시간 검증
- Play Store 프로덕션 승격

### Phase 4: v1.0.2 핫픽스 (1주 후)
- UX P1 잔여 6건 (스도쿠 홈 정렬, 토큰 일관성 등)
- QA P1 잔여 (BackupService 버전 가드, minesweeper 게임오버 정책)
- 성능 P1 (StatisticsScreen lazy load, autoSave debounce)

### Phase 5: v1.1.0 메이저 업데이트 (1개월 후)
- 전체 P2 백로그
- 색맹 모드 토글
- 모션 감소 옵션
- 일/중 네이티브 감수

---

## 4. 즉시 실행 — Phase 2 작업 분할

### 4-1. B0-1 (가장 큼) — DEV 작업 명세
12게임 보드/컨트롤에 Semantics 추가. 각 게임 패턴:

**보드 위젯**:
```dart
Semantics(
  label: AppStrings.get('{game}.board.label'),
  hint: AppStrings.get('{game}.board.hint'),
  container: true,
  child: CustomPaint(...),
)
```

각 셀 단위 Semantics는 비현실적 → **보드 전체에 1개 + 선택 셀 변경 시 announce**:
```dart
// 선택 셀이 바뀔 때
SemanticsService.announce(
  AppStrings.get('{game}.cellSelected')
      .replaceAll('{r}', '${row+1}')
      .replaceAll('{c}', '${col+1}'),
  TextDirection.ltr,
);
```

**컨트롤 버튼**: `tooltip:` 활용 (이미 일부 적용됨, 누락 추가)

### 4-2. B0-2 — 즉시 수정
`sudoku_board_widget.dart:110` 한국어 하드코딩 → `AppStrings.get('sudoku.board.label')` 등 4언어 키로 교체

### 4-3. 동반 P1 패치 (시너지)
별도 사이클로 처리하되 같은 v1.0.1 묶음:
- 로딩 UI 개선
- 가로모드 정사각형 보드
- 오답 패턴 표시
- R8 활성화
- 메타데이터 작성

---

## 5. 위험 관리

| 위험 | 확률 | 영향 | 대응 |
|------|------|------|------|
| TalkBack 라벨 텍스트 자연스러움 (4언어) | 높음 | 중간 | 네이티브 검수 또는 후속 정리 |
| R8 활성화로 크래시 | 중간 | 높음 | proguard-rules.pro 보강 + 알파 테스트 |
| 정식 출시 후 부정 리뷰 (B0 미해결 시) | 높음 | 매우 높음 | **Phase 2 필수 완료 후 출시** |
| 가로 모드 보드 비율 | 낮음 | 낮음 | 자동회전 잠금으로 단순화 가능 |

---

## 6. 향후 방향 (1~3개월)

### 1개월: 안정성/접근성 강화
- 색맹 모드 토글
- 모션 감소 옵션
- 햅틱 강도/사용 토글
- TalkBack 라이브 영역 (타이머/힌트/완료)

### 2개월: 사용자 확장
- 일/중 게임 용어 네이티브 검수
- 스토어 스크린샷 4언어
- 출시 노트 4언어

### 3개월: 게임 콘텐츠 확장
- 새 게임 R13~ 추가 (마스터 플랜 외)
- 챌린지/이벤트 모드
- 통계 시각화 강화

---

## 7. PM 최종 결론

**5인 전문가 종합 결과**:
- ✅ 기능/성능/컴플라이언스: 정식 출시 가능 수준
- 🔴 **접근성: 정식 출시 부적합** (TalkBack 사용자 불가)

**권장 액션**:
1. v1.0.0+4는 **알파 유지**
2. **Phase 2 작업 1주 진행** (B0-1, B0-2 + 동반 P1)
3. v1.0.1로 **정식 출시**
4. 1주 후 v1.0.2 잔여 P1 핫픽스

**현재 시점에서 즉시 정식 출시는 권장하지 않음.**
