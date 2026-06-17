import '../../shared/l10n/app_strings.dart';
import 'engine/nonogram_board.dart';
import 'engine/nonogram_hint.dart';

/// 노노그램 게임 모드
enum NonogramGameMode {
  classic('mode.classic'),
  relax('mode.relax'),
  dailyPuzzle('mode.dailyPuzzle');

  const NonogramGameMode(this.labelKey);
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
}

/// 노노그램 난이도 (격자 크기와 연동)
enum NonogramDifficulty {
  beginner(5, 'difficulty.beginner'),
  easy(10, 'difficulty.easy'),
  medium(15, 'difficulty.medium'),
  hard(20, 'difficulty.hard');

  const NonogramDifficulty(this.gridSize, this.labelKey);
  final int gridSize;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 난이도 코드 (0~3, 제너레이터 연동)
  int get code => index;
}

/// 입력 모드 (채움/크로스/지우개)
enum NonogramInputMode {
  fill,   // ■ 채움
  cross,  // ✕ 크로스 표시
  erase,  // 지우개
}

/// Undo 액션 타입
enum NonogramUndoActionType { setValue, clearValue }

/// Undo 스택 항목
class NonogramUndoAction {
  final NonogramUndoActionType type;
  final int row;
  final int col;
  final int previousValue; // -1(빈칸), 0(크로스), 1(채움)

  const NonogramUndoAction({
    required this.type,
    required this.row,
    required this.col,
    required this.previousValue,
  });
}

/// 완료 시 등급
enum NonogramGrade {
  perfect('S', 'grade.perfect'),
  excellent('A', 'grade.excellent'),
  great('B', 'grade.great'),
  good('C', 'grade.good');

  const NonogramGrade(this.symbol, this.labelKey);
  final String symbol;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 등급 산정
  ///
  /// 정통 노노그램 방식: 실수 카운트 없음. 힌트와 시간만으로 평가한다.
  /// [mistakes] 파라미터는 백워드 호환을 위해 유지하되 사용하지 않는다.
  static NonogramGrade evaluate({
    required int mistakes, // 호환성 유지 — 사용하지 않음
    required int hints,
    int? elapsedSeconds,
    NonogramDifficulty? difficulty,
  }) {
    // 힌트 사용량 기반 1차 분류
    if (hints > 3) return good;       // C: 힌트 4회 이상
    if (hints > 1) return great;      // B: 힌트 2~3회

    // 힌트 0회: 시간 기준으로 S/A 분기
    if (hints == 0) {
      if (elapsedSeconds != null && difficulty != null) {
        final baseTime = baseTimeForDifficulty(difficulty);
        if (elapsedSeconds <= baseTime) return perfect; // S: 기준시간 이내
        return excellent;                               // A: 기준시간 초과
      }
      return perfect;
    }

    // 힌트 1회: A
    return excellent;
  }

  /// 난이도별 등급 임계값
  static ({int bMistakes, int bHints, int cMistakes, int cHints}) gradeThresholds(
    NonogramDifficulty? difficulty,
  ) {
    switch (difficulty) {
      case NonogramDifficulty.hard:
        return (bMistakes: 2, bHints: 2, cMistakes: 4, cHints: 4);
      default:
        return (bMistakes: 1, bHints: 1, cMistakes: 3, cHints: 3);
    }
  }

  /// 난이도별 기준 시간 (초)
  static int baseTimeForDifficulty(NonogramDifficulty difficulty) {
    switch (difficulty) {
      case NonogramDifficulty.beginner:
        return 120;   // 2분
      case NonogramDifficulty.easy:
        return 360;   // 6분
      case NonogramDifficulty.medium:
        return 900;   // 15분
      case NonogramDifficulty.hard:
        return 1800;  // 30분
    }
  }
}

/// 노노그램 게임 상태
class NonogramState {
  /// 진행률 (0.0~1.0).
  double get progress {
    final total = current.rows * current.cols; if (total == 0) return 1.0; final decided = total - current.undecidedCount; return decided / total;
  }

  /// 퍼즐 보드 (초기 상태 — 힌트만 있는 빈 보드)
  final NonogramBoard puzzle;

  /// 정답 보드
  final NonogramBoard solution;

  /// 현재 보드 (플레이어 입력 반영)
  final NonogramBoard current;

  /// 게임 모드
  final NonogramGameMode mode;

  /// 난이도
  final NonogramDifficulty difficulty;

  /// 경과 시간 (초)
  final int elapsedSeconds;

  /// 실수 횟수
  final int mistakeCount;

  /// 힌트 사용 횟수
  final int hintCount;

  /// 일시정지 여부
  final bool isPaused;

  /// 완료 여부
  final bool isCompleted;

  /// 자동완성 진행 중 여부
  final bool isAutoCompleting;

  /// Undo 스택
  final List<NonogramUndoAction> undoStack;

  /// 선택된 셀 (row, col)
  final (int, int)? selectedCell;

  /// 현재 힌트 레벨 (0: 없음, 1~4: 단계)
  final int currentHintLevel;

  /// 힌트 대상 셀
  final (int, int)? hintTargetCell;

  /// 마지막 힌트 결과 (UI 표시용)
  final NonogramHintResult? lastHintResult;

  /// 현재 입력 모드 (■ / ✕ / 지우개)
  final NonogramInputMode inputMode;

  const NonogramState({
    required this.puzzle,
    required this.solution,
    required this.current,
    required this.mode,
    required this.difficulty,
    this.elapsedSeconds = 0,
    this.mistakeCount = 0,
    this.hintCount = 0,
    this.isPaused = false,
    this.isCompleted = false,
    this.isAutoCompleting = false,
    this.undoStack = const [],
    this.selectedCell,
    this.currentHintLevel = 0,
    this.hintTargetCell,
    this.lastHintResult,
    this.inputMode = NonogramInputMode.fill,
  });

  /// 완료 등급
  NonogramGrade get grade => NonogramGrade.evaluate(
        mistakes: mistakeCount,
        hints: hintCount,
        elapsedSeconds: elapsedSeconds,
        difficulty: difficulty,
      );

  /// copyWith
  NonogramState copyWith({
    NonogramBoard? puzzle,
    NonogramBoard? solution,
    NonogramBoard? current,
    NonogramGameMode? mode,
    NonogramDifficulty? difficulty,
    int? elapsedSeconds,
    int? mistakeCount,
    int? hintCount,
    bool? isPaused,
    bool? isCompleted,
    bool? isAutoCompleting,
    List<NonogramUndoAction>? undoStack,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    int? currentHintLevel,
    (int, int)? hintTargetCell,
    bool clearHintTarget = false,
    NonogramHintResult? lastHintResult,
    bool clearLastHint = false,
    NonogramInputMode? inputMode,
  }) {
    return NonogramState(
      puzzle: puzzle ?? this.puzzle,
      solution: solution ?? this.solution,
      current: current ?? this.current,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      hintCount: hintCount ?? this.hintCount,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      isAutoCompleting: isAutoCompleting ?? this.isAutoCompleting,
      undoStack: undoStack ?? this.undoStack,
      selectedCell: clearSelectedCell ? null : (selectedCell ?? this.selectedCell),
      currentHintLevel: currentHintLevel ?? this.currentHintLevel,
      hintTargetCell: clearHintTarget ? null : (hintTargetCell ?? this.hintTargetCell),
      lastHintResult: clearLastHint ? null : (lastHintResult ?? this.lastHintResult),
      inputMode: inputMode ?? this.inputMode,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'puzzle': puzzle.toJson(),
      'solution': solution.toJson(),
      'current': current.toJson(),
      'mode': mode.name,
      'difficulty': difficulty.name,
      'elapsedSeconds': elapsedSeconds,
      'mistakeCount': mistakeCount,
      'hintCount': hintCount,
      'isPaused': isPaused,
      'isCompleted': isCompleted,
      'selectedCell': selectedCell != null
          ? {'row': selectedCell!.$1, 'col': selectedCell!.$2}
          : null,
      'currentHintLevel': currentHintLevel,
      'hintTargetCell': hintTargetCell != null
          ? {'row': hintTargetCell!.$1, 'col': hintTargetCell!.$2}
          : null,
      'inputMode': inputMode.name,
    };
  }

  /// JSON 역직렬화
  factory NonogramState.fromJson(Map<String, dynamic> json) {
    final selectedCellJson = json['selectedCell'] as Map<String, dynamic>?;
    final hintTargetJson = json['hintTargetCell'] as Map<String, dynamic>?;

    return NonogramState(
      puzzle: NonogramBoard.fromJson(json['puzzle'] as Map<String, dynamic>),
      solution: NonogramBoard.fromJson(json['solution'] as Map<String, dynamic>),
      current: NonogramBoard.fromJson(json['current'] as Map<String, dynamic>),
      mode: NonogramGameMode.values.byName(json['mode'] as String),
      difficulty: NonogramDifficulty.values.byName(json['difficulty'] as String),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      mistakeCount: json['mistakeCount'] as int? ?? 0,
      hintCount: json['hintCount'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      selectedCell: selectedCellJson != null
          ? (selectedCellJson['row'] as int, selectedCellJson['col'] as int)
          : null,
      currentHintLevel: json['currentHintLevel'] as int? ?? 0,
      hintTargetCell: hintTargetJson != null
          ? (hintTargetJson['row'] as int, hintTargetJson['col'] as int)
          : null,
      inputMode: json['inputMode'] != null
          ? NonogramInputMode.values.byName(json['inputMode'] as String)
          : NonogramInputMode.fill,
    );
  }
}
