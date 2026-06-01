# Ninedoku 12개 퍼즐 확장 마스터 플랜

> 최종 합의: 2026-06-01
> 버전: 1.0
> PM 에이전트 관리 문서

---

## 1. 프로젝트 개요

### 1.1 목표
Ninedoku를 단일 스도쿠 앱에서 **13개 논리 퍼즐을 포함하는 오프라인 퍼즐 플랫폼**으로 확장한다.

### 1.2 핵심 제약
- 인터넷 권한 없음 (완전 오프라인)
- Firebase/광고/분석 SDK 없음
- 개인정보 수집 없음
- Android 12+ (minSdk 31), iOS 동시 빌드
- Flutter + Dart, Riverpod, go_router

### 1.3 현재 상태 (v1.0.0+3)
- 스도쿠: 5개 모드, 6단계 난이도, 14개 배지, 4개 국어, 640개 테스트 통과
- GitHub: https://github.com/cloez/ninedoku-privacy/sudoku/
- Play Store: 비공개 테스트 (Alpha) 진행 중

---

## 2. 추가 대상 게임 (12개)

### Tier 1 — 모바일 최적 (7개)
| ID | 게임 | 인터랙션 | 설명 |
|----|------|----------|------|
| G01 | Binairo | 이진 토글 | 0/1로 격자 채우기, 3연속 금지, 행열 균등 |
| G02 | Minesweeper | 배치 | 숫자 힌트로 지뢰 위치 추론 |
| G03 | Yin-Yang | 이진 토글 | 흑/백으로 채우기, 각 색 연결, 2x2 금지 |
| G04 | Nonograms | 격자 채우기 | 행/열 숫자 힌트로 그림 완성 |
| G05 | Star Battle | 배치 | 각 행/열/영역에 N개 별 배치, 인접 금지 |
| G06 | Light Up | 배치 | 전구 배치하여 전체 격자 비추기 |
| G07 | Tents | 배치 | 나무 옆에 텐트 배치, 행/열 개수 맞추기 |

### Tier 2 — 숫자 입력 (5개)
| ID | 게임 | 인터랙션 | 설명 |
|----|------|----------|------|
| G08 | Killer Sudoku | 숫자 입력 | 스도쿠 + 케이지 합계 조건 |
| G09 | Futoshiki | 숫자 입력 | NxN 격자 + 부등호 조건 |
| G10 | Jigsaw Sudoku | 숫자 입력 | 스도쿠 + 불규칙 영역 |
| G11 | Skyscrapers | 숫자 입력 | NxN 격자 + 외곽 가시성 힌트 |
| G12 | Kakuro | 숫자 입력 | 합계 크로스워드, 1~9 중복 금지 |

---

## 3. 릴리스 로드맵

### 3.1 릴리스 순서 (교차 배치 원칙)

| 릴리스 | 게임 | 유형 | 주요 작업 | 예상 기간 | 버전 |
|--------|------|------|----------|----------|------|
| R1 | Binairo | 이진 | 게임 허브 UI + 이진 엔진 + 공유 아키텍처 | 2.5주 | v1.1 |
| R2 | Minesweeper | 배치 | 배치 엔진 기초 + 지뢰 생성기 | 2주 | v1.2 |
| R3 | Yin-Yang | 이진 | 이진 엔진 재활용 + 연결성 검증 | 1.5주 | v1.3 |
| R4 | Nonograms | 격자 | 전용 엔진 + 드래그 UI + 그림 데이터 | 3주 | v2.0 |
| R5 | Killer Sudoku | 숫자 | 스도쿠 엔진 확장 + 케이지 UI | 2주 | v2.1 |
| R6 | Star Battle | 배치 | 영역 생성기 + 배치 엔진 확장 | 2주 | v2.2 |
| R7 | Light Up | 배치 | 빛 전파 로직 + 배치 엔진 재활용 | 1.5주 | v2.3 |
| R8 | Futoshiki | 숫자 | 부등호 UI + 숫자 엔진 | 1.5주 | v2.4 |
| R9 | Tents | 배치 | 나무/텐트 배치 + 배치 엔진 재활용 | 1.5주 | v2.5 |
| R10 | Jigsaw Sudoku | 숫자 | 스도쿠 엔진 변형 + 영역 색상 UI | 1.5주 | v3.0 |
| R11 | Skyscrapers | 숫자 | 외곽 힌트 UI + 숫자 엔진 | 1.5주 | v3.1 |
| R12 | Kakuro | 숫자 | 합계 엔진 + 크로스워드 격자 UI | 2주 | v3.2 |

**총 예상 기간: 약 22주 (~5.5개월)**

### 3.2 교차 배치 원칙
- 같은 인터랙션 유형의 게임을 연달아 출시하지 않는다
- 매 릴리스마다 사용자에게 "다른 느낌"을 제공한다
- 예외: R1(Binairo)과 R3(Yin-Yang)은 엔진 공유로 2개 사이에 R2를 끼움

---

## 4. 아키텍처 설계

### 4.1 프로젝트 구조

```
lib/
 ├─ app/                        # 공유 레이어
 │  ├─ router.dart              # 전체 라우팅 (게임 허브 포함)
 │  ├─ theme.dart               # 공유 테마
 │  ├─ custom_theme.dart        # 커스텀 테마 시스템
 │  └─ game_hub.dart            # 게임 허브 화면 (R1에서 신규)
 │
 ├─ core/
 │  ├─ engine/                  # 공유 엔진 인터페이스
 │  │  ├─ puzzle_engine.dart    # 추상 클래스: Board, Solver, Generator, Hint
 │  │  ├─ binary_engine.dart    # 이진 토글 공통 (Binairo, Yin-Yang)
 │  │  ├─ placement_engine.dart # 셀 배치 공통 (Star Battle, Light Up, Tents, Minesweeper)
 │  │  └─ number_engine.dart    # 숫자 입력 공통 (Killer, Jigsaw, Futoshiki, Skyscrapers, Kakuro)
 │  ├─ storage/                 # 공유 저장소
 │  ├─ settings/                # 공유 설정
 │  └─ utils/                   # 공유 유틸리티
 │
 ├─ games/                      # 게임별 독립 모듈 (플러그인 구조)
 │  ├─ sudoku/                  # 기존 스도쿠 (features/에서 이전)
 │  │  ├─ engine/
 │  │  ├─ screens/
 │  │  ├─ widgets/
 │  │  └─ sudoku_config.dart
 │  ├─ binairo/                 # R1
 │  ├─ minesweeper/             # R2
 │  ├─ yin_yang/                # R3
 │  ├─ nonograms/               # R4
 │  ├─ killer_sudoku/           # R5
 │  ├─ star_battle/             # R6
 │  ├─ light_up/                # R7
 │  ├─ futoshiki/               # R8
 │  ├─ tents/                   # R9
 │  ├─ jigsaw_sudoku/           # R10
 │  ├─ skyscrapers/             # R11
 │  └─ kakuro/                  # R12
 │
 ├─ features/                   # 크로스 게임 기능
 │  ├─ hub/                     # 게임 허브
 │  ├─ daily_challenge/         # 통합 오늘의 퍼즐
 │  ├─ cross_badges/            # 크로스 게임 배지 (10개)
 │  ├─ statistics/              # 통합 통계 (게임별 필터)
 │  ├─ settings/                # 공유 설정 화면
 │  └─ onboarding/              # 앱 온보딩
 │
 └─ shared/                     # 공통 위젯, 상수
    ├─ widgets/
    │  ├─ grid_board.dart       # 범용 격자 보드 위젯
    │  ├─ number_pad.dart       # 범용 숫자 패드
    │  ├─ binary_toggle.dart    # 범용 이진 토글 UI
    │  └─ game_timer.dart       # 범용 타이머
    ├─ constants/
    └─ l10n/
```

### 4.2 공유 엔진 인터페이스

```dart
/// 모든 퍼즐 게임이 구현하는 추상 인터페이스
abstract class PuzzleEngine<B, S> {
  B generatePuzzle({required int difficulty, required int seed});
  bool validate(B board);
  S solve(B board);
  bool hasUniqueSolution(B board);
  HintResult getHint(B board, S solution, {int level = 1});
  int evaluateDifficulty(B board);
}
```

### 4.3 게임 등록 구조

```dart
/// 각 게임이 자기 정보를 등록하는 설정 객체
class GameConfig {
  final String id;                    // 'binairo', 'star_battle' 등
  final String nameKey;               // 다국어 키
  final String icon;                  // 이모지 또는 아이콘
  final InteractionPattern pattern;   // binary, placement, number, nonogram
  final List<DifficultyLevel> difficulties;
  final List<BadgeDefinition> badges;
  final bool hasDailyPuzzle;
  final List<GameMode> modes;
  final Widget Function() screenBuilder;
  final PuzzleEngine engine;
}

/// 게임 레지스트리 (게임 허브에서 사용)
class GameRegistry {
  static final List<GameConfig> games = [
    sudokuConfig,
    binairoConfig,
    // ... 추가 시 여기에 등록
  ];
}
```

---

## 5. 시스템 설계

### 5.1 공유 vs 독립

| 시스템 | 범위 | 설명 |
|--------|------|------|
| 테마 (6개) | 공유 | 앱 전체 일관된 시각 경험 |
| 설정 (전역) | 공유 | 사운드, 진동, 글자 크기, 언어 |
| 설정 (게임별) | 독립 | 스도쿠 '실수 표시', 노노그램 '자동 X' 등 |
| 통계 | 독립 | 게임별 완료 수, 평균 시간, 기록 |
| 배지 (게임별) | 독립 | 게임별 8~14개 |
| 배지 (크로스) | 공유 | 크로스 게임 배지 10개 |
| 오늘의 퍼즐 | 독립 | 게임별 일일 퍼즐 (시드 기반) |
| 타이머/등급 | 공유 | S/A/B/C 등급 체계 |
| 백업/복원 | 공유 | 하나의 JSON에 전체 데이터 포함 |
| 다국어 | 공유 | 통합 문자열 관리 (4개국어) |
| 난이도 | 독립 | 게임별 스케일이 다름 |

### 5.2 크로스 게임 배지 (10개)

| 배지 | 아이콘 | 조건 |
|------|--------|------|
| 호기심 | 🌱 | 3가지 퍼즐 각 1게임 완료 |
| 다재다능 | 🌿 | 5가지 퍼즐 각 1게임 완료 |
| 만능 퍼즐러 | 🌳 | 전체 퍼즐 각 1게임 완료 |
| 하루의 달인 | ⚡ | 하루에 3가지 오늘의 퍼즐 완료 |
| 퍼즐 마라톤 | 🔥 | 하루에 전체 오늘의 퍼즐 완료 |
| 퍼펙트 콜렉터 | 💎 | 5가지 퍼즐에서 S등급 |
| 마스터 오브 마스터 | 🏆 | 3가지 퍼즐의 최고 난이도 클리어 |
| 7일 다양성 | 📅 | 7일 연속 매일 다른 퍼즐 플레이 |
| 100게임 클럽 | 🎯 | 전체 합산 100게임 완료 |
| 1000게임 클럽 | 👑 | 전체 합산 1000게임 완료 |

### 5.3 인터랙션 패턴 (3가지)

#### 패턴 A: 이진 토글
```
빈 칸 → 탭 → 상태1 → 탭 → 상태2 → 탭 → 빈 칸
```
적용: Binairo(0/1), Yin-Yang(흑/백), Minesweeper(깃발/열기), Tents(텐트/잔디), Star Battle(별/X), Light Up(전구/X), Nonograms(채움/X)

#### 패턴 B: 숫자 입력
```
셀 탭 → 하단 숫자 패드에서 숫자 선택
```
적용: Sudoku, Killer Sudoku, Jigsaw Sudoku, Futoshiki, Skyscrapers, Kakuro

#### 패턴 C: 노노그램 전용
```
셀 탭(채움) + 길게 누르기(X) + 드래그(연속 채움)
```
적용: Nonograms

---

## 6. 릴리스별 상세 작업 목록

### R1: Binairo + 게임 허브 (v1.1) — 2.5주

#### 인프라 작업 (게임 허브 + 공유 아키텍처)
- [ ] 프로젝트 구조 리팩토링: features/ → games/ 이전
- [ ] PuzzleEngine 추상 인터페이스 정의
- [ ] GameConfig / GameRegistry 구현
- [ ] 게임 허브 화면 (game_hub.dart) 구현
  - [ ] 게임 카드 그리드 (최근 플레이 우선 정렬)
  - [ ] 진행 중 게임 배지 표시
  - [ ] NEW 표시 (28일)
  - [ ] 오늘의 퍼즐 통합 진행률
- [ ] go_router 라우팅 확장 (허브 → 게임별 홈)
- [ ] 기존 스도쿠를 games/sudoku/로 이전 + GameConfig 등록
- [ ] 공유 위젯: grid_board.dart, game_timer.dart
- [ ] 통합 백업/복원 구조 확장 (게임별 데이터 키)
- [ ] 통합 통계 화면 (게임별 필터 탭)

#### Binairo 게임 구현
- [ ] BinairoBoard 모델 (NxN, 셀 상태: empty/zero/one)
- [ ] BinairoSolver (행열 검증, 3연속 검증, 균등 검증, 동일행열 검증)
- [ ] BinairoGenerator (유일해 보장, 시드 기반)
- [ ] DifficultyEvaluator (격자 크기 + 빈 칸 기반)
  - 6x6(입문) → 8x8(쉬움) → 10x10(보통) → 12x12(어려움) → 14x14(마스터)
- [ ] BinairoHintEngine (4단계 점진적 힌트)
- [ ] 플레이 화면 (이진 토글 UI)
- [ ] 일시정지/결과 화면 (공유 위젯 활용)
- [ ] 배지 정의 (8~10개)
- [ ] 오늘의 퍼즐
- [ ] 튜토리얼
- [ ] 다국어 문자열 (4개국어)
- [ ] 단위 테스트

#### QA
- [ ] 기존 스도쿠 640개 테스트 전체 통과 확인
- [ ] Binairo 테스트 전체 통과
- [ ] 실기기 골든 패스: 허브 → Binairo → 플레이 → 완료 → 허브
- [ ] 실기기 골든 패스: 허브 → 스도쿠 → 기존과 동일하게 동작 확인
- [ ] 오프라인 모드 전체 정상 동작

#### 빌드 & 배포
- [ ] AAB 빌드
- [ ] Play Store 업로드
- [ ] 스토어 설명/스크린샷 업데이트
- [ ] GitHub 소스 커밋 (ninedoku-privacy/sudoku/ 업데이트)

---

### R2: Minesweeper (v1.2) — 2주

#### 게임 구현
- [ ] MinesweeperBoard 모델 (NxN, 지뢰/숫자/열림/깃발)
- [ ] MinesweeperGenerator (지뢰 배치, 첫 클릭 안전 보장, 시드 기반)
- [ ] 논리적 풀이 가능 보장 (찍기 없는 지뢰찾기)
- [ ] DifficultyEvaluator (격자 크기 + 지뢰 비율)
  - 8x8(입문) → 10x10(쉬움) → 12x12(보통) → 16x16(어려움)
- [ ] HintEngine
- [ ] 플레이 화면 (탭: 열기, 길게누르기: 깃발)
- [ ] 셀 열기 시 연쇄 오픈 애니메이션
- [ ] 배지 정의 (8~10개)
- [ ] 오늘의 퍼즐
- [ ] 튜토리얼
- [ ] 다국어 문자열
- [ ] 단위 테스트

#### QA & 배포
- [ ] 전체 테스트 통과
- [ ] 실기기 검증
- [ ] AAB 빌드 & Play Store 업로드
- [ ] GitHub 커밋

---

### R3: Yin-Yang (v1.3) — 1.5주

#### 게임 구현
- [ ] YinYangBoard 모델 (NxN, 셀 상태: empty/black/white)
- [ ] YinYangSolver (연결성 검증 BFS/DFS, 2x2 검증)
- [ ] YinYangGenerator (유일해 보장, 시드 기반)
- [ ] DifficultyEvaluator (격자 크기 + 빈 칸)
  - 5x5(입문) → 7x7(쉬움) → 10x10(보통) → 14x14(어려움) → 20x20(마스터)
- [ ] HintEngine (연결성 기반 추론 힌트)
- [ ] 플레이 화면 (이진 토글 UI 재활용)
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포
- [ ] 전체 테스트 통과 + 실기기 검증 + 배포

---

### R4: Nonograms (v2.0) — 3주

#### 게임 구현
- [ ] NonogramBoard 모델 (NxM, 행/열 힌트, 셀 상태)
- [ ] NonogramSolver (행/열 교차 논리)
- [ ] NonogramGenerator (그림 → 퍼즐 변환, 유일해 보장)
- [ ] 기본 그림 라이브러리 (5x5: 30개, 10x10: 20개, 15x15: 15개)
- [ ] DifficultyEvaluator (크기 + 풀이 기법)
- [ ] HintEngine
- [ ] 플레이 화면 (드래그 채우기 + 길게눌러 X)
- [ ] 완성 시 그림 표시 애니메이션
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포
- [ ] 전체 테스트 통과 + 실기기 검증 + 배포
- [ ] 앱 제목 변경: "Ninedoku: Logic Puzzles"

---

### R5: Killer Sudoku (v2.1) — 2주

#### 게임 구현
- [ ] KillerSudokuBoard 모델 (9x9 + 케이지 정의)
- [ ] KillerSudokuSolver (스도쿠 규칙 + 케이지 합계)
- [ ] KillerSudokuGenerator (케이지 생성 + 유일해)
- [ ] 케이지 UI (점선 테두리 + 합계 표시)
- [ ] 숫자 패드 재활용 (기존 스도쿠)
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포

---

### R6: Star Battle (v2.2) — 2주

#### 게임 구현
- [ ] StarBattleBoard 모델 (NxN + 영역 정의 + 별 수)
- [ ] StarBattleSolver (행/열/영역 별 수 + 인접 금지)
- [ ] StarBattleGenerator (영역 생성 + 유일해)
- [ ] 영역 색상 UI
- [ ] 1-Star(쉬움) → 2-Star(어려움) 스케일링
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포

---

### R7: Light Up (v2.3) — 1.5주

#### 게임 구현
- [ ] LightUpBoard 모델 (NxN, 검은벽/흰칸/전구)
- [ ] LightUpSolver (빛 전파 + 조건 검증)
- [ ] LightUpGenerator (벽 배치 + 유일해)
- [ ] 빛 전파 시각화 (전구 배치 시 빛이 퍼지는 애니메이션)
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포

---

### R8: Futoshiki (v2.4) — 1.5주

#### 게임 구현
- [ ] FutoshikiBoard 모델 (NxN + 부등호 제약)
- [ ] FutoshikiSolver (라틴 방진 + 부등호)
- [ ] FutoshikiGenerator (부등호 배치 + 유일해)
- [ ] 부등호 UI (셀 사이 < > 표시)
- [ ] 격자 크기: 4x4(입문) → 5x5(쉬움) → 6x6(보통) → 7x7(어려움) → 9x9(마스터)
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포

---

### R9: Tents (v2.5) — 1.5주

#### 게임 구현
- [ ] TentsBoard 모델 (NxN, 나무/텐트/잔디 + 행열 개수)
- [ ] TentsSolver (나무-텐트 매칭 + 인접 금지 + 행열 개수)
- [ ] TentsGenerator (나무 배치 + 텐트 배치 + 유일해)
- [ ] 나무-텐트 연결 시각화
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포

---

### R10: Jigsaw Sudoku (v3.0) — 1.5주

#### 게임 구현
- [ ] JigsawSudokuBoard 모델 (9x9 + 불규칙 영역)
- [ ] JigsawSudokuSolver (라틴 방진 + 불규칙 영역)
- [ ] JigsawSudokuGenerator (영역 생성 + 유일해)
- [ ] 영역별 색상/테두리 UI
- [ ] 숫자 패드 재활용
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포

---

### R11: Skyscrapers (v3.1) — 1.5주

#### 게임 구현
- [ ] SkyscrapersBoard 모델 (NxN + 외곽 힌트)
- [ ] SkyscrapersSolver (라틴 방진 + 가시성 규칙)
- [ ] SkyscrapersGenerator (외곽 힌트 생성 + 유일해)
- [ ] 외곽 힌트 UI (격자 바깥 숫자)
- [ ] 격자 크기: 4x4 → 5x5 → 6x6 → 7x7 → 8x8
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포

---

### R12: Kakuro (v3.2) — 2주

#### 게임 구현
- [ ] KakuroBoard 모델 (크로스워드 격자 + 합계 힌트)
- [ ] KakuroSolver (합계 조합 + 중복 금지)
- [ ] KakuroGenerator (격자 구조 + 합계 배치 + 유일해)
- [ ] 크로스워드 격자 UI (대각선 분할 셀)
- [ ] 숫자 패드 재활용 (1~9)
- [ ] 배지, 오늘의 퍼즐, 튜토리얼, 다국어, 테스트

#### QA & 배포
- [ ] 전체 13개 게임 통합 테스트
- [ ] 크로스 게임 배지 전체 동작 검증
- [ ] 최종 릴리스

---

## 7. 각 릴리스 공통 프로세스

### 7.1 개발 프로세스 (매 릴리스)
```
1. 기획 검토: PM이 해당 릴리스 요구사항 확인
2. 코어 엔진: Board → Solver → Generator → HintEngine
3. 단위 테스트: 엔진 로직 100% 커버리지
4. UI 구현: 플레이 화면, 결과, 일시정지, 튜토리얼
5. 통합: GameConfig 등록, 허브 연동, 배지, 오늘의 퍼즐
6. QA: 기존 전체 테스트 + 신규 테스트 + 실기기 골든 패스
7. 빌드: AAB 빌드 (versionCode 증가)
8. 배포: Play Store 업로드, 스토어 설명 업데이트
9. 커밋: GitHub 소스 커밋
```

### 7.2 QA 체크리스트 (매 릴리스)
- [ ] 기존 모든 게임 테스트 통과 (리그레션)
- [ ] 신규 게임 테스트 통과
- [ ] 게임 허브 → 각 게임 진입/복귀 정상
- [ ] 오늘의 퍼즐 정상 동작
- [ ] 백업/복원에 신규 게임 데이터 포함
- [ ] 하드웨어 백키 동작 통일 (PopScope)
- [ ] 오프라인 모드 전체 정상
- [ ] 4개국어 문자열 누락 없음

### 7.3 Play Store 업데이트 (매 릴리스)
- [ ] versionCode 증가
- [ ] 출시 노트 작성 (한국어 + 영어)
- [ ] 스크린샷 업데이트 (필요 시)
- [ ] 앱 설명 업데이트 (새 게임 추가 반영)

---

## 8. 진행 상태 추적

### 현재 상태
| 릴리스 | 상태 | 시작일 | 완료일 |
|--------|------|--------|--------|
| R0 (Sudoku) | ✅ 완료 | - | 2026-06-01 |
| R1 (Binairo) | ⏳ 대기 | - | - |
| R2 (Minesweeper) | ⏳ 대기 | - | - |
| R3 (Yin-Yang) | ⏳ 대기 | - | - |
| R4 (Nonograms) | ⏳ 대기 | - | - |
| R5 (Killer Sudoku) | ⏳ 대기 | - | - |
| R6 (Star Battle) | ⏳ 대기 | - | - |
| R7 (Light Up) | ⏳ 대기 | - | - |
| R8 (Futoshiki) | ⏳ 대기 | - | - |
| R9 (Tents) | ⏳ 대기 | - | - |
| R10 (Jigsaw Sudoku) | ⏳ 대기 | - | - |
| R11 (Skyscrapers) | ⏳ 대기 | - | - |
| R12 (Kakuro) | ⏳ 대기 | - | - |

---

## 9. 설계 원칙 (불변)

| 원칙 | 설명 |
|------|------|
| 플러그인 아키텍처 | 새 게임 추가 = games/ 폴더 1개 + GameConfig 등록 |
| 교차 릴리스 | 같은 유형 게임을 연달아 출시하지 않음 |
| 3패턴 통일 | 이진 토글 / 숫자 입력 / 노노그램 전용 |
| 독립 + 연결 | 게임별 통계/배지 분리, 크로스 배지로 연결 |
| 허브 중심 | 최근 플레이 우선 정렬, 진행률 한눈에 |
| 점진적 공개 | 2~3주 간격, 매번 1개씩 추가 |
| 기존 보존 | 스도쿠 사용자 경험에 영향 없음 |
| 완전 오프라인 | INTERNET 권한 절대 추가 금지 |
| 코드 품질 | 모든 릴리스에서 기존 테스트 100% 통과 |
