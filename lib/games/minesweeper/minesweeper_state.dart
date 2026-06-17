import '../../shared/l10n/app_strings.dart';
import 'engine/minesweeper_board.dart';
import 'engine/minesweeper_hint.dart';

/// 지뢰찾기 게임 모드
enum MinesweeperGameMode {
  classic('mode.classic'),
  relax('mode.relax'),
  dailyPuzzle('mode.dailyPuzzle');

  const MinesweeperGameMode(this.labelKey);
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
}

/// 지뢰찾기 난이도 (격자 크기 + 지뢰 수 연동)
enum MinesweeperDifficulty {
  beginner(8, 8, 'difficulty.beginner'),
  easy(9, 12, 'difficulty.easy'),
  medium(10, 18, 'difficulty.medium'),
  hard(12, 30, 'difficulty.hard'),
  master(16, 50, 'difficulty.master');

  const MinesweeperDifficulty(this.gridSize, this.mineCount, this.labelKey);
  final int gridSize;
  final int mineCount;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 난이도 코드 (0~4, Generator 연동)
  int get code => index;
}

/// 입력 모드
enum MinesweeperInputMode {
  reveal, // 셀 열기
  flag,   // 깃발 배치
}

/// Undo 액션 타입
enum MinesweeperUndoActionType { reveal, flag, unflag }

/// Undo 스택 항목
class MinesweeperUndoAction {
  final MinesweeperUndoActionType type;
  final int row;
  final int col;
  /// reveal 시 연쇄 오픈된 셀 목록
  final List<(int, int)> cascadeRevealed;

  const MinesweeperUndoAction({
    required this.type,
    required this.row,
    required this.col,
    this.cascadeRevealed = const [],
  });
}

/// 완료 시 등급
enum MinesweeperGrade {
  perfect('S', 'grade.perfect'),
  excellent('A', 'grade.excellent'),
  great('B', 'grade.great'),
  good('C', 'grade.good');

  const MinesweeperGrade(this.symbol, this.labelKey);
  final String symbol;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 등급 산정
  static MinesweeperGrade evaluate({
    required int mistakes,
    required int hints,
    int? elapsedSeconds,
    MinesweeperDifficulty? difficulty,
  }) {
    if (mistakes > 3 || hints > 3) return good;
    if (mistakes > 1 || hints > 1) return great;

    if (mistakes == 0 && hints == 0) {
      if (elapsedSeconds != null && difficulty != null) {
        final baseTime = baseTimeForDifficulty(difficulty);
        if (elapsedSeconds <= baseTime) return perfect;
        if (elapsedSeconds <= baseTime * 2) return excellent;
        return excellent;
      }
      return perfect;
    }

    return excellent;
  }

  /// 난이도별 기준 시간 (초)
  static int baseTimeForDifficulty(MinesweeperDifficulty difficulty) {
    switch (difficulty) {
      case MinesweeperDifficulty.beginner:
        return 60;
      case MinesweeperDifficulty.easy:
        return 120;
      case MinesweeperDifficulty.medium:
        return 300;
      case MinesweeperDifficulty.hard:
        return 600;
      case MinesweeperDifficulty.master:
        return 1200;
    }
  }
}

/// 지뢰찾기 게임 상태
class MinesweeperState {
  /// 진행률 (0.0~1.0).
  double get progress {
    final safe = current.safeCount; if (safe == 0) return 1.0; return (current.revealedCount / safe).clamp(0.0, 1.0);
  }

  /// 초기 퍼즐 보드 (첫 클릭 후 상태)
  final MinesweeperBoard puzzle;

  /// 정답 보드
  final MinesweeperBoard solution;

  /// 현재 보드 (플레이어 입력 반영)
  final MinesweeperBoard current;

  /// 격자 크기
  int get size => current.size;

  /// 지뢰 수
  int get mineCount => current.mineCount;

  /// 게임 모드
  final MinesweeperGameMode mode;

  /// 난이도
  final MinesweeperDifficulty difficulty;

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

  /// 자동완성 진행 중
  final bool isAutoCompleting;

  /// Undo 스택
  final List<MinesweeperUndoAction> undoStack;

  /// 선택된 셀
  final (int, int)? selectedCell;

  /// 현재 힌트 레벨
  final int currentHintLevel;

  /// 힌트 대상 셀
  final (int, int)? hintTargetCell;

  /// 마지막 힌트 결과
  final MinesweeperHintResult? lastHintResult;

  /// 현재 입력 모드
  final MinesweeperInputMode inputMode;

  /// 남은 지뢰 수 (전체 - 깃발 수)
  int get remainingMines => mineCount - current.flagCount;

  const MinesweeperState({
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
    this.inputMode = MinesweeperInputMode.reveal,
  });

  /// 완료 등급
  MinesweeperGrade get grade => MinesweeperGrade.evaluate(
        mistakes: mistakeCount,
        hints: hintCount,
        elapsedSeconds: elapsedSeconds,
        difficulty: difficulty,
      );

  /// copyWith
  MinesweeperState copyWith({
    MinesweeperBoard? puzzle,
    MinesweeperBoard? solution,
    MinesweeperBoard? current,
    MinesweeperGameMode? mode,
    MinesweeperDifficulty? difficulty,
    int? elapsedSeconds,
    int? mistakeCount,
    int? hintCount,
    bool? isPaused,
    bool? isCompleted,
    bool? isAutoCompleting,
    List<MinesweeperUndoAction>? undoStack,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    int? currentHintLevel,
    (int, int)? hintTargetCell,
    bool clearHintTarget = false,
    MinesweeperHintResult? lastHintResult,
    bool clearLastHint = false,
    MinesweeperInputMode? inputMode,
  }) {
    return MinesweeperState(
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
  factory MinesweeperState.fromJson(Map<String, dynamic> json) {
    final selectedCellJson = json['selectedCell'] as Map<String, dynamic>?;
    final hintTargetJson = json['hintTargetCell'] as Map<String, dynamic>?;

    return MinesweeperState(
      puzzle: MinesweeperBoard.fromJson(json['puzzle'] as Map<String, dynamic>),
      solution: MinesweeperBoard.fromJson(json['solution'] as Map<String, dynamic>),
      current: MinesweeperBoard.fromJson(json['current'] as Map<String, dynamic>),
      mode: MinesweeperGameMode.values.byName(json['mode'] as String),
      difficulty: MinesweeperDifficulty.values.byName(json['difficulty'] as String),
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
          ? MinesweeperInputMode.values.byName(json['inputMode'] as String)
          : MinesweeperInputMode.reveal,
    );
  }
}
