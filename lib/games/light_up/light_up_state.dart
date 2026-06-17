import '../../shared/l10n/app_strings.dart';
import 'engine/light_up_board.dart';
import 'engine/light_up_hint.dart';

/// Light Up 게임 모드
enum LightUpGameMode {
  classic('mode.classic'),
  relax('mode.relax'),
  dailyPuzzle('mode.dailyPuzzle');

  const LightUpGameMode(this.labelKey);
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
}

/// Light Up 난이도 (격자 크기와 벽 비율 연동)
enum LightUpDifficulty {
  beginner(7, 'difficulty.beginner'),
  easy(8, 'difficulty.easy'),
  medium(10, 'difficulty.medium'),
  hard(12, 'difficulty.hard'),
  master(14, 'difficulty.master');

  const LightUpDifficulty(this.gridSize, this.labelKey);
  final int gridSize;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 난이도 코드 (0~4, 제너레이터 연동)
  int get code => index;
}

/// 입력 모드 (이진 토글 — 탭으로 💡/X/빈칸)
enum LightUpInputMode {
  bulb,   // 💡 전구 배치
  crossMark,  // X 표시
  erase,  // 지우개
}

/// Undo 액션 타입
enum LightUpUndoActionType { setValue, clearValue }

/// Undo 스택 항목
class LightUpUndoAction {
  final LightUpUndoActionType type;
  final int row;
  final int col;
  final int previousValue; // -1(빈칸), 5(전구), 6(X)

  const LightUpUndoAction({
    required this.type,
    required this.row,
    required this.col,
    required this.previousValue,
  });
}

/// 완료 시 등급
enum LightUpGrade {
  perfect('S', 'grade.perfect'),
  excellent('A', 'grade.excellent'),
  great('B', 'grade.great'),
  good('C', 'grade.good');

  const LightUpGrade(this.symbol, this.labelKey);
  final String symbol;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 등급 산정
  static LightUpGrade evaluate({
    required int mistakes,
    required int hints,
    int? elapsedSeconds,
    LightUpDifficulty? difficulty,
  }) {
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
    LightUpDifficulty? difficulty,
  ) {
    switch (difficulty) {
      case LightUpDifficulty.hard:
      case LightUpDifficulty.master:
        return (bMistakes: 2, bHints: 2, cMistakes: 4, cHints: 4);
      default:
        return (bMistakes: 1, bHints: 1, cMistakes: 3, cHints: 3);
    }
  }

  /// 난이도별 기준 시간 (초)
  static int baseTimeForDifficulty(LightUpDifficulty difficulty) {
    switch (difficulty) {
      case LightUpDifficulty.beginner:
        return 90;    // 1분 30초
      case LightUpDifficulty.easy:
        return 180;   // 3분
      case LightUpDifficulty.medium:
        return 360;   // 6분
      case LightUpDifficulty.hard:
        return 600;   // 10분
      case LightUpDifficulty.master:
        return 1200;  // 20분
    }
  }
}

/// Light Up 게임 상태
class LightUpState {
  /// 진행률 (0.0~1.0): 결정된 셀 / 전체.
  double get progress {
    // 라이트업: 사용자가 결정한 흰 셀(전구 또는 X) / 전체 흰 셀
    // (lit 셀 기준은 전구 배치/해제에 따라 흔들리므로 결정 기반으로 안정화)
    final white = current.whiteCellCount;
    if (white == 0) return 1.0;
    var decided = 0;
    for (var r = 0; r < current.size; r++) {
      for (var c = 0; c < current.size; c++) {
        if (!current.isWhite(r, c)) continue;
        final v = current.getValue(r, c);
        // empty(빈칸)는 미결정, bulb 또는 cross 는 결정됨
        if (v != LightUpBoard.empty) decided++;
      }
    }
    return (decided / white).clamp(0.0, 1.0);
  }

  /// 퍼즐 보드 (초기 상태 — 벽만)
  final LightUpBoard puzzle;

  /// 정답 보드
  final LightUpBoard solution;

  /// 현재 보드 (플레이어 입력 반영)
  final LightUpBoard current;

  /// 격자 크기
  int get size => current.size;

  /// 게임 모드
  final LightUpGameMode mode;

  /// 난이도
  final LightUpDifficulty difficulty;

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
  final List<LightUpUndoAction> undoStack;

  /// 선택된 셀 (row, col)
  final (int, int)? selectedCell;

  /// 현재 힌트 레벨 (0: 없음, 1~4: 단계)
  final int currentHintLevel;

  /// 힌트 대상 셀
  final (int, int)? hintTargetCell;

  /// 마지막 힌트 결과 (UI 표시용)
  final LightUpHintResult? lastHintResult;

  /// 현재 입력 모드 (💡 / X / 지우개)
  final LightUpInputMode inputMode;

  const LightUpState({
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
    this.inputMode = LightUpInputMode.bulb,
  });

  /// 완료 등급
  LightUpGrade get grade => LightUpGrade.evaluate(
        mistakes: mistakeCount,
        hints: hintCount,
        elapsedSeconds: elapsedSeconds,
        difficulty: difficulty,
      );

  /// copyWith
  LightUpState copyWith({
    LightUpBoard? puzzle,
    LightUpBoard? solution,
    LightUpBoard? current,
    LightUpGameMode? mode,
    LightUpDifficulty? difficulty,
    int? elapsedSeconds,
    int? mistakeCount,
    int? hintCount,
    bool? isPaused,
    bool? isCompleted,
    bool? isAutoCompleting,
    List<LightUpUndoAction>? undoStack,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    int? currentHintLevel,
    (int, int)? hintTargetCell,
    bool clearHintTarget = false,
    LightUpHintResult? lastHintResult,
    bool clearLastHint = false,
    LightUpInputMode? inputMode,
  }) {
    return LightUpState(
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
    };
  }

  /// JSON 역직렬화
  factory LightUpState.fromJson(Map<String, dynamic> json) {
    final selectedCellJson = json['selectedCell'] as Map<String, dynamic>?;
    final hintTargetJson = json['hintTargetCell'] as Map<String, dynamic>?;

    return LightUpState(
      puzzle: LightUpBoard.fromJson(json['puzzle'] as Map<String, dynamic>),
      solution: LightUpBoard.fromJson(json['solution'] as Map<String, dynamic>),
      current: LightUpBoard.fromJson(json['current'] as Map<String, dynamic>),
      mode: LightUpGameMode.values.byName(json['mode'] as String),
      difficulty: LightUpDifficulty.values.byName(json['difficulty'] as String),
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
