import '../../shared/l10n/app_strings.dart';
import 'engine/yin_yang_board.dart';
import 'engine/yin_yang_hint.dart';

/// 음양 게임 모드
enum YinYangGameMode {
  classic('mode.classic'),
  relax('mode.relax'),
  dailyPuzzle('mode.dailyPuzzle');

  const YinYangGameMode(this.labelKey);
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
}

/// 음양 난이도
enum YinYangDifficulty {
  beginner(5, 'difficulty.beginner'),
  easy(7, 'difficulty.easy'),
  medium(10, 'difficulty.medium'),
  hard(14, 'difficulty.hard'),
  master(16, 'difficulty.master');

  const YinYangDifficulty(this.gridSize, this.labelKey);
  final int gridSize;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
  int get code => index;
}

/// 입력 모드
enum YinYangInputMode { black, white, erase }

/// Undo 액션
enum YinYangUndoActionType { setValue, clearValue }

class YinYangUndoAction {
  final YinYangUndoActionType type;
  final int row;
  final int col;
  final int previousValue;

  const YinYangUndoAction({
    required this.type,
    required this.row,
    required this.col,
    required this.previousValue,
  });
}

/// 등급
enum YinYangGrade {
  perfect('S', 'grade.perfect'),
  excellent('A', 'grade.excellent'),
  great('B', 'grade.great'),
  good('C', 'grade.good');

  const YinYangGrade(this.symbol, this.labelKey);
  final String symbol;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  static YinYangGrade evaluate({
    required int mistakes,
    required int hints,
    int? elapsedSeconds,
    YinYangDifficulty? difficulty,
  }) {
    if (mistakes > 3 || hints > 3) return good;
    if (mistakes > 1 || hints > 1) return great;
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

  static int baseTimeForDifficulty(YinYangDifficulty d) {
    switch (d) {
      case YinYangDifficulty.beginner: return 60;
      case YinYangDifficulty.easy: return 180;
      case YinYangDifficulty.medium: return 420;
      case YinYangDifficulty.hard: return 720;
      case YinYangDifficulty.master: return 1500;
    }
  }
}

/// 음양 게임 상태
class YinYangState {
  /// 진행률 (0.0~1.0): 결정된 셀 / 전체.
  double get progress {
    final t = current.cells.length; if (t == 0) return 1.0; return current.filledCellCount / t;
  }

  final YinYangBoard puzzle;
  final YinYangBoard solution;
  final YinYangBoard current;
  int get size => current.size;
  final YinYangGameMode mode;
  final YinYangDifficulty difficulty;
  final int elapsedSeconds;
  final int mistakeCount;
  final int hintCount;
  final bool isPaused;
  final bool isCompleted;
  final bool isAutoCompleting;
  final List<YinYangUndoAction> undoStack;
  final (int, int)? selectedCell;
  final int currentHintLevel;
  final (int, int)? hintTargetCell;
  final YinYangHintResult? lastHintResult;
  final YinYangInputMode inputMode;

  const YinYangState({
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
    this.inputMode = YinYangInputMode.black,
  });

  YinYangGrade get grade => YinYangGrade.evaluate(
        mistakes: mistakeCount, hints: hintCount,
        elapsedSeconds: elapsedSeconds, difficulty: difficulty,
      );

  YinYangState copyWith({
    YinYangBoard? puzzle, YinYangBoard? solution, YinYangBoard? current,
    YinYangGameMode? mode, YinYangDifficulty? difficulty,
    int? elapsedSeconds, int? mistakeCount, int? hintCount,
    bool? isPaused, bool? isCompleted, bool? isAutoCompleting,
    List<YinYangUndoAction>? undoStack,
    (int, int)? selectedCell, bool clearSelectedCell = false,
    int? currentHintLevel,
    (int, int)? hintTargetCell, bool clearHintTarget = false,
    YinYangHintResult? lastHintResult, bool clearLastHint = false,
    YinYangInputMode? inputMode,
  }) {
    return YinYangState(
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

  Map<String, dynamic> toJson() => {
    'puzzle': puzzle.toJson(), 'solution': solution.toJson(), 'current': current.toJson(),
    'mode': mode.name, 'difficulty': difficulty.name,
    'elapsedSeconds': elapsedSeconds, 'mistakeCount': mistakeCount, 'hintCount': hintCount,
    'isPaused': isPaused, 'isCompleted': isCompleted,
    'selectedCell': selectedCell != null ? {'row': selectedCell!.$1, 'col': selectedCell!.$2} : null,
    'currentHintLevel': currentHintLevel,
    'hintTargetCell': hintTargetCell != null ? {'row': hintTargetCell!.$1, 'col': hintTargetCell!.$2} : null,
    'inputMode': inputMode.name,
  };

  factory YinYangState.fromJson(Map<String, dynamic> json) {
    final sc = json['selectedCell'] as Map<String, dynamic>?;
    final ht = json['hintTargetCell'] as Map<String, dynamic>?;
    return YinYangState(
      puzzle: YinYangBoard.fromJson(json['puzzle'] as Map<String, dynamic>),
      solution: YinYangBoard.fromJson(json['solution'] as Map<String, dynamic>),
      current: YinYangBoard.fromJson(json['current'] as Map<String, dynamic>),
      mode: YinYangGameMode.values.byName(json['mode'] as String),
      difficulty: YinYangDifficulty.values.byName(json['difficulty'] as String),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      mistakeCount: json['mistakeCount'] as int? ?? 0,
      hintCount: json['hintCount'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      selectedCell: sc != null ? (sc['row'] as int, sc['col'] as int) : null,
      currentHintLevel: json['currentHintLevel'] as int? ?? 0,
      hintTargetCell: ht != null ? (ht['row'] as int, ht['col'] as int) : null,
      inputMode: json['inputMode'] != null
          ? YinYangInputMode.values.byName(json['inputMode'] as String)
          : YinYangInputMode.black,
    );
  }
}
