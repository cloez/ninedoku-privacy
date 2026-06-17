import '../../shared/l10n/app_strings.dart';
import 'engine/skyscrapers_board.dart';
import 'engine/skyscrapers_hint.dart';

/// Skyscrapers 게임 모드
enum SkyscrapersGameMode {
  classic('mode.classic'),
  relax('mode.relax'),
  dailyPuzzle('mode.dailyPuzzle'),
  challenge('mode.challenge');

  const SkyscrapersGameMode(this.labelKey);
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
}

/// Skyscrapers 난이도 (격자 크기와 연동)
enum SkyscrapersDifficulty {
  beginner(4, 'difficulty.beginner'),
  easy(5, 'difficulty.easy'),
  medium(6, 'difficulty.medium'),
  hard(7, 'difficulty.hard'),
  master(8, 'difficulty.master');

  const SkyscrapersDifficulty(this.gridSize, this.labelKey);
  final int gridSize;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 난이도 코드 (0~4, 제너레이터 연동)
  int get code => index;
}

/// Undo 액션 타입
enum SkyscrapersUndoType { setValue, clearValue, toggleNote }

/// Undo 스택 항목
class SkyscrapersUndoAction {
  final SkyscrapersUndoType type;
  final int row;
  final int col;
  final int previousValue;
  final Set<int>? previousNotes;

  const SkyscrapersUndoAction({
    required this.type,
    required this.row,
    required this.col,
    required this.previousValue,
    this.previousNotes,
  });
}

/// 완료 시 등급
enum SkyscrapersGrade {
  perfect('S', 'grade.perfect'),
  excellent('A', 'grade.excellent'),
  great('B', 'grade.great'),
  good('C', 'grade.good');

  const SkyscrapersGrade(this.symbol, this.labelKey);
  final String symbol;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 등급 산정
  static SkyscrapersGrade evaluate({
    required int mistakes,
    required int hints,
    int? elapsedSeconds,
    SkyscrapersDifficulty? difficulty,
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
  static int baseTimeForDifficulty(SkyscrapersDifficulty difficulty) {
    switch (difficulty) {
      case SkyscrapersDifficulty.beginner:
        return 60;
      case SkyscrapersDifficulty.easy:
        return 120;
      case SkyscrapersDifficulty.medium:
        return 300;
      case SkyscrapersDifficulty.hard:
        return 600;
      case SkyscrapersDifficulty.master:
        return 1200;
    }
  }
}

/// Skyscrapers 게임 상태
class SkyscrapersState {
  /// 진행률 (0.0~1.0): 결정된 셀 / 전체.
  double get progress {
    final t = current.totalCells; if (t == 0) return 1.0; return current.filledCellCount / t;
  }

  /// 퍼즐 보드 (초기 상태)
  final SkyscrapersBoard puzzle;

  /// 정답 보드
  final SkyscrapersBoard solution;

  /// 현재 보드 (플레이어 입력 반영)
  final SkyscrapersBoard current;

  /// 격자 크기
  int get size => current.size;

  /// 게임 모드
  final SkyscrapersGameMode mode;

  /// 난이도
  final SkyscrapersDifficulty difficulty;

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
  final List<SkyscrapersUndoAction> undoStack;

  /// 선택된 셀 (row, col)
  final (int, int)? selectedCell;

  /// 현재 힌트 레벨 (0: 없음, 1~4: 단계)
  final int currentHintLevel;

  /// 힌트 대상 셀
  final (int, int)? hintTargetCell;

  /// 마지막 힌트 결과 (UI 표시용)
  final SkyscrapersHintResult? lastHintResult;

  /// 메모 모드 여부
  final bool isNoteMode;

  const SkyscrapersState({
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
    this.isNoteMode = false,
  });

  /// 완료 등급
  SkyscrapersGrade get grade => SkyscrapersGrade.evaluate(
        mistakes: mistakeCount,
        hints: hintCount,
        elapsedSeconds: elapsedSeconds,
        difficulty: difficulty,
      );

  /// 난이도 라벨
  String get difficultyLabel => difficulty.label;

  /// copyWith
  SkyscrapersState copyWith({
    SkyscrapersBoard? puzzle,
    SkyscrapersBoard? solution,
    SkyscrapersBoard? current,
    SkyscrapersGameMode? mode,
    SkyscrapersDifficulty? difficulty,
    int? elapsedSeconds,
    int? mistakeCount,
    int? hintCount,
    bool? isPaused,
    bool? isCompleted,
    bool? isAutoCompleting,
    List<SkyscrapersUndoAction>? undoStack,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    int? currentHintLevel,
    (int, int)? hintTargetCell,
    bool clearHintTarget = false,
    SkyscrapersHintResult? lastHintResult,
    bool clearLastHint = false,
    bool? isNoteMode,
  }) {
    return SkyscrapersState(
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
      isNoteMode: isNoteMode ?? this.isNoteMode,
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
      'isNoteMode': isNoteMode,
    };
  }

  /// JSON 역직렬화
  factory SkyscrapersState.fromJson(Map<String, dynamic> json) {
    final selectedCellJson = json['selectedCell'] as Map<String, dynamic>?;
    final hintTargetJson = json['hintTargetCell'] as Map<String, dynamic>?;

    return SkyscrapersState(
      puzzle:
          SkyscrapersBoard.fromJson(json['puzzle'] as Map<String, dynamic>),
      solution:
          SkyscrapersBoard.fromJson(json['solution'] as Map<String, dynamic>),
      current:
          SkyscrapersBoard.fromJson(json['current'] as Map<String, dynamic>),
      mode: SkyscrapersGameMode.values.byName(json['mode'] as String),
      difficulty:
          SkyscrapersDifficulty.values.byName(json['difficulty'] as String),
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
      isNoteMode: json['isNoteMode'] as bool? ?? false,
    );
  }
}
