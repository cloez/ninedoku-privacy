import '../../shared/l10n/app_strings.dart';
import 'engine/tents_board.dart';
import 'engine/tents_hint.dart';

/// Tents 게임 모드
enum TentsGameMode {
  classic('mode.classic'),
  relax('mode.relax'),
  dailyPuzzle('mode.dailyPuzzle'),
  quickPlay('mode.quickPlay'),
  challenge('mode.challenge');

  const TentsGameMode(this.labelKey);
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
}

/// Tents 난이도 (격자 크기와 연동)
enum TentsDifficulty {
  beginner(6, 'difficulty.beginner'),
  easy(8, 'difficulty.easy'),
  medium(10, 'difficulty.medium'),
  hard(12, 'difficulty.hard'),
  master(12, 'difficulty.master');

  const TentsDifficulty(this.gridSize, this.labelKey);
  final int gridSize;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 난이도 코드 (0~4, 제너레이터 연동)
  int get code => index;
}

/// 입력 모드 (이진 토글)
enum TentsInputMode {
  tent,   // ⛺ 텐트 배치
  grass,  // ✕ 잔디 배치
  erase,  // 지우개
}

/// Undo 액션 타입
enum TentsUndoActionType { setValue, clearValue }

/// Undo 스택 항목
class TentsUndoAction {
  final TentsUndoActionType type;
  final int row;
  final int col;
  final int previousValue; // 0(빈칸), 2(텐트), 3(잔디)

  const TentsUndoAction({
    required this.type,
    required this.row,
    required this.col,
    required this.previousValue,
  });
}

/// 완료 시 등급
enum TentsGrade {
  perfect('S', 'grade.perfect'),
  excellent('A', 'grade.excellent'),
  great('B', 'grade.great'),
  good('C', 'grade.good');

  const TentsGrade(this.symbol, this.labelKey);
  final String symbol;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 등급 산정
  static TentsGrade evaluate({
    required int mistakes,
    required int hints,
    int? elapsedSeconds,
    TentsDifficulty? difficulty,
  }) {
    final thresholds = gradeThresholds(difficulty);
    if (mistakes > thresholds.cMistakes || hints > thresholds.cHints) {
      return good;
    }
    if (mistakes > thresholds.bMistakes || hints > thresholds.bHints) {
      return great;
    }
    if (mistakes == 0 && hints == 0) {
      if (elapsedSeconds != null && difficulty != null) {
        final baseTime = baseTimeForDifficulty(difficulty);
        if (elapsedSeconds <= baseTime) return perfect;
        return excellent;
      }
      return perfect;
    }
    return excellent;
  }

  /// 난이도별 등급 임계값
  static ({int bMistakes, int bHints, int cMistakes, int cHints})
      gradeThresholds(TentsDifficulty? difficulty) {
    switch (difficulty) {
      case TentsDifficulty.hard:
        return (bMistakes: 2, bHints: 2, cMistakes: 4, cHints: 4);
      case TentsDifficulty.master:
        return (bMistakes: 1, bHints: 1, cMistakes: 3, cHints: 3);
      default:
        return (bMistakes: 1, bHints: 1, cMistakes: 3, cHints: 3);
    }
  }

  /// 난이도별 기준 시간 (초)
  static int baseTimeForDifficulty(TentsDifficulty difficulty) {
    switch (difficulty) {
      case TentsDifficulty.beginner:
        return 60;
      case TentsDifficulty.easy:
        return 120;
      case TentsDifficulty.medium:
        return 300;
      case TentsDifficulty.hard:
        return 600;
      case TentsDifficulty.master:
        return 1200;
    }
  }
}

/// Tents 게임 상태
class TentsState {
  /// 진행률 (0.0~1.0): 결정된 셀 / 전체.
  double get progress {
    // tents: 채워진 셀 / 전체 셀
    final t = current.totalCells;
    if (t == 0) return 1.0;
    final placed = current.filledCellCount;
    return (placed / t).clamp(0.0, 1.0);
  }

  /// 퍼즐 보드 (초기 상태)
  final TentsBoard puzzle;

  /// 정답 보드
  final TentsBoard solution;

  /// 현재 보드 (플레이어 입력 반영)
  final TentsBoard current;

  /// 격자 크기
  int get size => current.size;

  /// 게임 모드
  final TentsGameMode mode;

  /// 난이도
  final TentsDifficulty difficulty;

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
  final List<TentsUndoAction> undoStack;

  /// 선택된 셀 (row, col)
  final (int, int)? selectedCell;

  /// 현재 힌트 레벨
  final int currentHintLevel;

  /// 힌트 대상 셀
  final (int, int)? hintTargetCell;

  /// 마지막 힌트 결과
  final TentsHintResult? lastHintResult;

  /// 현재 입력 모드
  final TentsInputMode inputMode;

  const TentsState({
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
    this.inputMode = TentsInputMode.tent,
  });

  /// 완료 등급
  TentsGrade get grade => TentsGrade.evaluate(
        mistakes: mistakeCount,
        hints: hintCount,
        elapsedSeconds: elapsedSeconds,
        difficulty: difficulty,
      );

  /// copyWith
  TentsState copyWith({
    TentsBoard? puzzle,
    TentsBoard? solution,
    TentsBoard? current,
    TentsGameMode? mode,
    TentsDifficulty? difficulty,
    int? elapsedSeconds,
    int? mistakeCount,
    int? hintCount,
    bool? isPaused,
    bool? isCompleted,
    bool? isAutoCompleting,
    List<TentsUndoAction>? undoStack,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    int? currentHintLevel,
    (int, int)? hintTargetCell,
    bool clearHintTarget = false,
    TentsHintResult? lastHintResult,
    bool clearLastHint = false,
    TentsInputMode? inputMode,
  }) {
    return TentsState(
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
      selectedCell:
          clearSelectedCell ? null : (selectedCell ?? this.selectedCell),
      currentHintLevel: currentHintLevel ?? this.currentHintLevel,
      hintTargetCell:
          clearHintTarget ? null : (hintTargetCell ?? this.hintTargetCell),
      lastHintResult:
          clearLastHint ? null : (lastHintResult ?? this.lastHintResult),
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
    };
  }

  /// JSON 역직렬화
  factory TentsState.fromJson(Map<String, dynamic> json) {
    final selectedCellJson = json['selectedCell'] as Map<String, dynamic>?;
    final hintTargetJson = json['hintTargetCell'] as Map<String, dynamic>?;

    return TentsState(
      puzzle: TentsBoard.fromJson(json['puzzle'] as Map<String, dynamic>),
      solution: TentsBoard.fromJson(json['solution'] as Map<String, dynamic>),
      current: TentsBoard.fromJson(json['current'] as Map<String, dynamic>),
      mode: TentsGameMode.values.byName(json['mode'] as String),
      difficulty: TentsDifficulty.values.byName(json['difficulty'] as String),
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
    );
  }
}
