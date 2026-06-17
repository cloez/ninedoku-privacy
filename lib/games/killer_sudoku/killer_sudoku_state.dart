import '../../shared/l10n/app_strings.dart';
import 'engine/killer_sudoku_board.dart';
import 'engine/killer_sudoku_generator.dart';
import 'engine/killer_sudoku_hint.dart';

/// 킬러 스도쿠 게임 모드
enum KillerSudokuGameMode {
  classic('mode.classic'),
  relax('mode.relax'),
  dailyPuzzle('mode.dailyPuzzle'),
  challenge('mode.challenge');

  const KillerSudokuGameMode(this.labelKey);
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
}

/// Undo 액션 타입
enum KillerSudokuUndoType { setValue, clearValue, toggleNote }

/// Undo 스택 항목
class KillerSudokuUndoAction {
  final KillerSudokuUndoType type;
  final int row;
  final int col;
  final int previousValue;
  final Set<int>? previousNotes;

  const KillerSudokuUndoAction({
    required this.type,
    required this.row,
    required this.col,
    required this.previousValue,
    this.previousNotes,
  });
}

/// 완료 시 등급
enum KillerSudokuGrade {
  perfect('S', 'grade.perfect'),
  excellent('A', 'grade.excellent'),
  great('B', 'grade.great'),
  good('C', 'grade.good');

  const KillerSudokuGrade(this.symbol, this.labelKey);
  final String symbol;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 등급 산정
  static KillerSudokuGrade evaluate({
    required int mistakes,
    required int hints,
    int? elapsedSeconds,
    KillerDifficulty? difficulty,
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

  /// 난이도별 기준 시간 (초)
  static int baseTimeForDifficulty(KillerDifficulty difficulty) {
    switch (difficulty) {
      case KillerDifficulty.beginner:
        return 180;
      case KillerDifficulty.easy:
        return 360;
      case KillerDifficulty.medium:
        return 600;
      case KillerDifficulty.hard:
        return 900;
      case KillerDifficulty.master:
        return 1500;
    }
  }
}

/// 킬러 스도쿠 게임 상태
class KillerSudokuState {
  /// 진행률 (0.0~1.0).
  double get progress {
    var needed = 0; var filled = 0; for (var r = 0; r < 9; r++) { for (var c = 0; c < 9; c++) { if (board.isFixed[r][c]) continue; needed++; if (board.cells[r][c] != 0) filled++; } } if (needed == 0) return 1.0; return filled / needed;
  }

  /// 게임 보드
  final KillerSudokuBoard board;

  /// 게임 모드
  final KillerSudokuGameMode mode;

  /// 난이도
  final KillerDifficulty difficulty;

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
  final List<KillerSudokuUndoAction> undoStack;

  /// 선택된 셀
  final (int, int)? selectedCell;

  /// 메모 모드 여부
  final bool isNoteMode;

  /// 현재 힌트 레벨
  final int currentHintLevel;

  /// 힌트 대상 셀
  final (int, int)? hintTargetCell;

  /// 마지막 힌트 결과
  final KillerSudokuHintResult? lastHintResult;

  const KillerSudokuState({
    required this.board,
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
    this.isNoteMode = false,
    this.currentHintLevel = 0,
    this.hintTargetCell,
    this.lastHintResult,
  });

  /// 등급
  KillerSudokuGrade get grade => KillerSudokuGrade.evaluate(
        mistakes: mistakeCount,
        hints: hintCount,
        elapsedSeconds: elapsedSeconds,
        difficulty: difficulty,
      );

  /// 난이도 라벨
  String get difficultyLabel {
    switch (difficulty) {
      case KillerDifficulty.beginner:
        return '입문';
      case KillerDifficulty.easy:
        return '쉬움';
      case KillerDifficulty.medium:
        return '보통';
      case KillerDifficulty.hard:
        return '어려움';
      case KillerDifficulty.master:
        return '마스터';
    }
  }

  /// copyWith
  KillerSudokuState copyWith({
    KillerSudokuBoard? board,
    KillerSudokuGameMode? mode,
    KillerDifficulty? difficulty,
    int? elapsedSeconds,
    int? mistakeCount,
    int? hintCount,
    bool? isPaused,
    bool? isCompleted,
    bool? isAutoCompleting,
    List<KillerSudokuUndoAction>? undoStack,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    bool? isNoteMode,
    int? currentHintLevel,
    (int, int)? hintTargetCell,
    bool clearHintTarget = false,
    KillerSudokuHintResult? lastHintResult,
    bool clearLastHint = false,
  }) {
    return KillerSudokuState(
      board: board ?? this.board,
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
      isNoteMode: isNoteMode ?? this.isNoteMode,
      currentHintLevel: currentHintLevel ?? this.currentHintLevel,
      hintTargetCell:
          clearHintTarget ? null : (hintTargetCell ?? this.hintTargetCell),
      lastHintResult:
          clearLastHint ? null : (lastHintResult ?? this.lastHintResult),
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'board': board.toJson(),
        'mode': mode.name,
        'difficulty': difficulty.name,
        'elapsedSeconds': elapsedSeconds,
        'mistakeCount': mistakeCount,
        'hintCount': hintCount,
        'isPaused': isPaused,
        'isCompleted': isCompleted,
        'isNoteMode': isNoteMode,
        'selectedCell': selectedCell != null
            ? {'row': selectedCell!.$1, 'col': selectedCell!.$2}
            : null,
        'currentHintLevel': currentHintLevel,
      };

  /// JSON 역직렬화
  factory KillerSudokuState.fromJson(Map<String, dynamic> json) {
    final selectedCellJson = json['selectedCell'] as Map<String, dynamic>?;

    return KillerSudokuState(
      board: KillerSudokuBoard.fromJson(
        json['board'] as Map<String, dynamic>,
      ),
      mode: KillerSudokuGameMode.values.byName(json['mode'] as String),
      difficulty: KillerDifficulty.values.byName(json['difficulty'] as String),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      mistakeCount: json['mistakeCount'] as int? ?? 0,
      hintCount: json['hintCount'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isNoteMode: json['isNoteMode'] as bool? ?? false,
      selectedCell: selectedCellJson != null
          ? (selectedCellJson['row'] as int, selectedCellJson['col'] as int)
          : null,
      currentHintLevel: json['currentHintLevel'] as int? ?? 0,
    );
  }
}
