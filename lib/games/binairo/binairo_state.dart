import 'engine/binairo_board.dart';
import 'engine/binairo_hint.dart';

/// Binairo 게임 모드
enum BinairoGameMode {
  classic('클래식'),
  relax('릴렉스'),
  dailyPuzzle('오늘의 퍼즐'),
  quickPlay('빠른 게임'),
  challenge('도전');

  const BinairoGameMode(this.label);
  final String label;
}

/// Binairo 난이도 (격자 크기와 연동)
enum BinairoDifficulty {
  beginner(6, '입문'),
  easy(8, '쉬움'),
  medium(10, '보통'),
  hard(12, '어려움'),
  master(14, '마스터');

  const BinairoDifficulty(this.gridSize, this.label);
  final int gridSize;
  final String label;

  /// 난이도 코드 (0~4, 제너레이터 연동)
  int get code => index;
}

/// Undo 액션 타입
enum BinairoUndoActionType { setValue, clearValue }

/// Undo 스택 항목
class BinairoUndoAction {
  final BinairoUndoActionType type;
  final int row;
  final int col;
  final int previousValue; // -1(빈칸), 0, 1

  const BinairoUndoAction({
    required this.type,
    required this.row,
    required this.col,
    required this.previousValue,
  });
}

/// 완료 시 등급
enum BinairoGrade {
  perfect('S', '퍼펙트'),
  excellent('A', '훌륭함'),
  great('B', '좋음'),
  good('C', '보통');

  const BinairoGrade(this.symbol, this.label);
  final String symbol;
  final String label;

  /// 등급 산정
  static BinairoGrade evaluate({
    required int mistakes,
    required int hints,
    int? elapsedSeconds,
    BinairoDifficulty? difficulty,
  }) {
    // 난이도별 임계값
    final thresholds = gradeThresholds(difficulty);

    if (mistakes > thresholds.cMistakes || hints > thresholds.cHints) return good;
    if (mistakes > thresholds.bMistakes || hints > thresholds.bHints) return great;

    // 실수 0, 힌트 0이면 시간 고려
    if (mistakes == 0 && hints == 0) {
      if (elapsedSeconds != null && difficulty != null) {
        final baseTime = baseTimeForDifficulty(difficulty);
        if (elapsedSeconds <= baseTime) return perfect;
        if (elapsedSeconds <= baseTime * 2) return excellent;
        return excellent; // 시간 초과해도 노미스 노힌트면 최소 A
      }
      return perfect;
    }

    return excellent;
  }

  /// 난이도별 등급 임계값
  static ({int bMistakes, int bHints, int cMistakes, int cHints}) gradeThresholds(
    BinairoDifficulty? difficulty,
  ) {
    switch (difficulty) {
      case BinairoDifficulty.hard:
        return (bMistakes: 2, bHints: 2, cMistakes: 4, cHints: 4);
      case BinairoDifficulty.master:
        return (bMistakes: 1, bHints: 1, cMistakes: 3, cHints: 3);
      default:
        return (bMistakes: 1, bHints: 1, cMistakes: 3, cHints: 3);
    }
  }

  /// 난이도별 기준 시간 (초)
  static int baseTimeForDifficulty(BinairoDifficulty difficulty) {
    switch (difficulty) {
      case BinairoDifficulty.beginner:
        return 120; // 2분
      case BinairoDifficulty.easy:
        return 240; // 4분
      case BinairoDifficulty.medium:
        return 480; // 8분
      case BinairoDifficulty.hard:
        return 720; // 12분
      case BinairoDifficulty.master:
        return 1200; // 20분
    }
  }
}

/// Binairo 게임 상태
class BinairoState {
  /// 퍼즐 보드 (초기 상태)
  final BinairoBoard puzzle;

  /// 정답 보드
  final BinairoBoard solution;

  /// 현재 보드 (플레이어 입력 반영)
  final BinairoBoard current;

  /// 격자 크기
  int get size => current.size;

  /// 게임 모드
  final BinairoGameMode mode;

  /// 난이도
  final BinairoDifficulty difficulty;

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
  final List<BinairoUndoAction> undoStack;

  /// 선택된 셀 (row, col)
  final (int, int)? selectedCell;

  /// 현재 힌트 레벨 (0: 없음, 1~4: 단계)
  final int currentHintLevel;

  /// 힌트 대상 셀
  final (int, int)? hintTargetCell;

  /// 마지막 힌트 결과 (UI 표시용)
  final BinairoHintResult? lastHintResult;

  const BinairoState({
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
  });

  /// 완료 등급
  BinairoGrade get grade => BinairoGrade.evaluate(
        mistakes: mistakeCount,
        hints: hintCount,
        elapsedSeconds: elapsedSeconds,
        difficulty: difficulty,
      );

  /// copyWith
  BinairoState copyWith({
    BinairoBoard? puzzle,
    BinairoBoard? solution,
    BinairoBoard? current,
    BinairoGameMode? mode,
    BinairoDifficulty? difficulty,
    int? elapsedSeconds,
    int? mistakeCount,
    int? hintCount,
    bool? isPaused,
    bool? isCompleted,
    bool? isAutoCompleting,
    List<BinairoUndoAction>? undoStack,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    int? currentHintLevel,
    (int, int)? hintTargetCell,
    bool clearHintTarget = false,
    BinairoHintResult? lastHintResult,
    bool clearLastHint = false,
  }) {
    return BinairoState(
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
  factory BinairoState.fromJson(Map<String, dynamic> json) {
    final selectedCellJson = json['selectedCell'] as Map<String, dynamic>?;
    final hintTargetJson = json['hintTargetCell'] as Map<String, dynamic>?;

    return BinairoState(
      puzzle: BinairoBoard.fromJson(json['puzzle'] as Map<String, dynamic>),
      solution: BinairoBoard.fromJson(json['solution'] as Map<String, dynamic>),
      current: BinairoBoard.fromJson(json['current'] as Map<String, dynamic>),
      mode: BinairoGameMode.values.byName(json['mode'] as String),
      difficulty: BinairoDifficulty.values.byName(json['difficulty'] as String),
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
