import '../../core/sudoku/board.dart';
import '../../core/sudoku/difficulty.dart';
import '../../core/sudoku/hint_engine.dart';
import '../../core/sudoku/technique_analyzer.dart';
import '../../shared/l10n/app_strings.dart';

/// 추임새 종류
enum Encouragement {
  good('Good!'),     // Naked Pair, Hidden Pair, Box-Line Reduction
  excellent('Excellent!'), // X-Wing 이상
  perfect('Perfect!');     // 실수 0으로 게임 완료

  const Encouragement(this.message);
  final String message;
}

/// 입력 모드: 셀 우선(기본) vs 숫자 우선
enum InputMode {
  cellFirst, // 셀 선택 → 숫자 입력 (기본)
  numberFirst, // 숫자 선택 → 셀 탭으로 입력
}

/// 게임 모드
enum GameMode {
  classic('mode.classic'),
  dailyPuzzle('mode.dailyPuzzle'),
  relax('mode.relax'),
  quickPlay('mode.quickPlay'),
  challenge('mode.challenge');

  const GameMode(this.labelKey);
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);
}

/// Undo 액션 타입
enum UndoActionType { setValue, clearValue, toggleNote, autoFillNotes }

/// Undo 스택 항목
class UndoAction {
  final UndoActionType type;
  final int row;
  final int col;
  final int? previousValue;
  final Set<int>? previousNotes;
  /// 자동 메모 채우기용 — 전체 메모 상태 백업
  final List<List<Set<int>>>? previousAllNotes;

  const UndoAction({
    required this.type,
    required this.row,
    required this.col,
    this.previousValue,
    this.previousNotes,
    this.previousAllNotes,
  });
}

/// 완료 시 등급
enum Grade {
  perfect('S', 'grade.perfect'),
  excellent('A', 'grade.excellent'),
  great('B', 'grade.great'),
  good('C', 'grade.good');

  const Grade(this.symbol, this.labelKey);
  final String symbol;
  final String labelKey;
  // 현재 언어에 맞는 표시명 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 실수, 힌트, 시간, 난이도 기반 등급 산정
  static Grade evaluate({
    required int mistakes,
    required int hints,
    int? elapsedSeconds,
    Difficulty? difficulty,
  }) {
    // 난이도별 실수/힌트 허용 임계값 (어려울수록 관대)
    final thresholds = gradeThresholds(difficulty);

    // 실수/힌트가 많으면 등급 하락
    if (mistakes > thresholds.cMistakes || hints > thresholds.cHints) return good;
    if (mistakes > thresholds.bMistakes || hints > thresholds.bHints) return great;

    // 실수 0, 힌트 0이면 시간도 고려
    if (mistakes == 0 && hints == 0) {
      if (elapsedSeconds != null && difficulty != null) {
        final baseTime = baseTimeForDifficulty(difficulty);
        if (elapsedSeconds <= baseTime) return perfect;
        if (elapsedSeconds <= baseTime * 2) return excellent;
        return excellent; // 시간 초과해도 노미스 노힌트면 최소 A
      }
      return perfect;
    }

    // 실수/힌트가 임계값 이내
    return excellent;
  }

  /// 난이도별 등급 임계값 (결과 화면에서도 참조)
  static ({int bMistakes, int bHints, int cMistakes, int cHints}) gradeThresholds(
    Difficulty? difficulty,
  ) {
    switch (difficulty) {
      case Difficulty.expert:
        // 전문가: 실수 1/힌트 1까지 A, 실수 4/힌트 4까지 B
        return (bMistakes: 1, bHints: 1, cMistakes: 4, cHints: 4);
      case Difficulty.master:
        // 마스터: 실수 1/힌트 1까지 A, 실수 3/힌트 3까지 B
        return (bMistakes: 1, bHints: 1, cMistakes: 3, cHints: 3);
      case Difficulty.hard:
        // 어려움: 실수 2/힌트 2까지 A, 실수 4/힌트 4까지 B
        return (bMistakes: 2, bHints: 2, cMistakes: 4, cHints: 4);
      default:
        // 입문~보통: 기존 기준 유지
        return (bMistakes: 1, bHints: 1, cMistakes: 3, cHints: 3);
    }
  }

  /// 난이도별 기준 시간 (초) — 결과 화면에서도 참조
  static int baseTimeForDifficulty(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.beginner:
        return 300; // 5분
      case Difficulty.easy:
        return 600; // 10분
      case Difficulty.medium:
        return 900; // 15분
      case Difficulty.hard:
        return 1200; // 20분
      case Difficulty.expert:
        return 1800; // 30분
      case Difficulty.master:
        return 2400; // 40분
    }
  }
}

/// 게임 상태
class GameState {
  final SudokuBoard board;
  final GameMode mode;
  final Difficulty difficulty;
  final List<UndoAction> undoStack;
  final int mistakeCount;
  final int hintCount;
  final int elapsedSeconds;
  final bool isPaused;
  final bool isCompleted;
  final bool isMemoMode;
  final (int, int)? selectedCell;
  final bool showMistakes; // 실수 표시 설정
  final InputMode inputMode; // 입력 모드
  final int? selectedNumber; // 숫자 우선 모드에서 선택된 숫자
  final int currentHintLevel; // 현재 힌트 진행 단계 (0: 없음, 1~4: 단계)
  final (int, int)? hintTargetCell; // 힌트 대상 셀 (같은 셀에 대해 단계적 제공)
  final HintResult? lastHintResult; // 마지막 힌트 결과 (UI 표시용)
  final int? maxMistakes; // 도전 모드 실수 제한 (null = 무제한)
  final bool isGameOver; // 도전 모드 실패 여부
  final Encouragement? lastEncouragement; // 마지막 추임새 (UI에서 표시 후 소멸)
  final (int, int)? wrongFlashCell; // 릴렉스 모드 오답 시 깜빡일 셀 좌표
  final bool isAutoCompleting; // 자동완성 애니메이션 진행 중
  final List<(int, int, int)> autoCompleteCells; // 자동완성 대상 셀 목록 [(row, col, value)]
  final int autoCompleteStep; // 애니메이션 진행 단계 (0~셀 수, step번째까지 표시)
  /// 방금 완성된 행/열/박스 목록 (UI 펄스 트리거용, 0.7초 뒤 자동 클리어)
  /// type: 'row' | 'col' | 'box', index: 0~8
  final List<({String type, int index})> recentlyCompletedLines;

  /// 이번 게임 중 힌트로 학습한 기법 목록 — H4(결과 화면 표시용).
  /// L2 진입 시점에 lastHintResult.technique을 누적. 세션 휘발(영속화 없음).
  final Set<SolvingTechnique> usedTechniques;

  /// H3: 방금 L4로 정답이 공개된 셀 좌표. UI 글로우/scale 트리거용.
  /// 800ms 후 notifier에서 null로 클리어.
  final (int, int)? recentlyRevealedHintCell;

  /// 도전 모드에서 힌트 사용 불가
  bool get isHintDisabled => mode == GameMode.challenge;

  /// 진행률 (0.0~1.0): 결정된 셀 / 결정 필요 셀
  /// 초기 고정 셀은 제외하고, 사용자가 채워야 하는 셀 중 정답이 입력된 비율.
  double get progress {
    var needed = 0;
    var filled = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.isFixed[r][c]) continue;
        needed++;
        final v = board.currentBoard[r][c];
        if (v != 0 && !board.isWrong(r, c)) filled++;
      }
    }
    if (needed == 0) return 1.0;
    return filled / needed;
  }

  const GameState({
    required this.board,
    required this.mode,
    required this.difficulty,
    this.undoStack = const [],
    this.mistakeCount = 0,
    this.hintCount = 0,
    this.elapsedSeconds = 0,
    this.isPaused = false,
    this.isCompleted = false,
    this.isMemoMode = false,
    this.selectedCell,
    this.showMistakes = true,
    this.inputMode = InputMode.cellFirst,
    this.selectedNumber,
    this.currentHintLevel = 0,
    this.hintTargetCell,
    this.lastHintResult,
    this.maxMistakes,
    this.isGameOver = false,
    this.lastEncouragement,
    this.wrongFlashCell,
    this.isAutoCompleting = false,
    this.autoCompleteCells = const [],
    this.autoCompleteStep = 0,
    this.recentlyCompletedLines = const [],
    this.usedTechniques = const {},
    this.recentlyRevealedHintCell,
  });

  /// 완료 등급 (시간/난이도 포함)
  Grade get grade => Grade.evaluate(
        mistakes: mistakeCount,
        hints: hintCount,
        elapsedSeconds: elapsedSeconds,
        difficulty: difficulty,
      );

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'board': board.toJson(),
      'mode': mode.name,
      'difficulty': difficulty.name,
      'mistakeCount': mistakeCount,
      'hintCount': hintCount,
      'elapsedSeconds': elapsedSeconds,
      'isPaused': isPaused,
      'isCompleted': isCompleted,
      'isMemoMode': isMemoMode,
      'showMistakes': showMistakes,
      'inputMode': inputMode.name,
      'selectedNumber': selectedNumber,
      'currentHintLevel': currentHintLevel,
      'hintTargetCell': hintTargetCell != null
          ? {'row': hintTargetCell!.$1, 'col': hintTargetCell!.$2}
          : null,
      'selectedCell': selectedCell != null
          ? {'row': selectedCell!.$1, 'col': selectedCell!.$2}
          : null,
      'maxMistakes': maxMistakes,
      'isGameOver': isGameOver,
      // H4: 학습한 기법은 세션 휘발이지만 직렬화 호환을 위해 키 자리만 마련
      'usedTechniques': usedTechniques.map((t) => t.name).toList(),
    };
  }

  /// JSON 역직렬화
  factory GameState.fromJson(Map<String, dynamic> json) {
    final selectedCellJson = json['selectedCell'] as Map<String, dynamic>?;

    return GameState(
      board: SudokuBoard.fromJson(json['board'] as Map<String, dynamic>),
      mode: GameMode.values.byName(json['mode'] as String),
      difficulty: Difficulty.values.byName(json['difficulty'] as String),
      mistakeCount: json['mistakeCount'] as int? ?? 0,
      hintCount: json['hintCount'] as int? ?? 0,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isMemoMode: json['isMemoMode'] as bool? ?? false,
      showMistakes: json['showMistakes'] as bool? ?? true,
      inputMode: _parseInputMode(json['inputMode'] as String?),
      selectedNumber: json['selectedNumber'] as int?,
      currentHintLevel: json['currentHintLevel'] as int? ?? 0,
      hintTargetCell: _parseCell(json['hintTargetCell']),
      maxMistakes: json['maxMistakes'] as int?,
      isGameOver: json['isGameOver'] as bool? ?? false,
      selectedCell: selectedCellJson != null
          ? (selectedCellJson['row'] as int, selectedCellJson['col'] as int)
          : null,
      usedTechniques: _parseUsedTechniques(json['usedTechniques']),
    );
  }

  /// 학습한 기법 목록 안전 파싱 (누락/잘못된 값은 빈 셋으로 폴백)
  static Set<SolvingTechnique> _parseUsedTechniques(dynamic raw) {
    if (raw is! List) return const {};
    final result = <SolvingTechnique>{};
    for (final v in raw) {
      if (v is! String) continue;
      try {
        result.add(SolvingTechnique.values.byName(v));
      } catch (_) {
        // 알 수 없는 기법 이름은 무시
      }
    }
    return result;
  }

  GameState copyWith({
    SudokuBoard? board,
    GameMode? mode,
    Difficulty? difficulty,
    List<UndoAction>? undoStack,
    int? mistakeCount,
    int? hintCount,
    int? elapsedSeconds,
    bool? isPaused,
    bool? isCompleted,
    bool? isMemoMode,
    (int, int)? selectedCell,
    bool clearSelectedCell = false,
    bool? showMistakes,
    InputMode? inputMode,
    int? selectedNumber,
    bool clearSelectedNumber = false,
    int? currentHintLevel,
    (int, int)? hintTargetCell,
    bool clearHintTarget = false,
    HintResult? lastHintResult,
    bool clearLastHint = false,
    int? maxMistakes,
    bool? isGameOver,
    Encouragement? lastEncouragement,
    bool clearEncouragement = false,
    (int, int)? wrongFlashCell,
    bool clearWrongFlash = false,
    bool? isAutoCompleting,
    List<(int, int, int)>? autoCompleteCells,
    int? autoCompleteStep,
    List<({String type, int index})>? recentlyCompletedLines,
    Set<SolvingTechnique>? usedTechniques,
    (int, int)? recentlyRevealedHintCell,
    bool clearRecentlyRevealedHintCell = false,
  }) {
    return GameState(
      board: board ?? this.board,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      undoStack: undoStack ?? this.undoStack,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      hintCount: hintCount ?? this.hintCount,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      isMemoMode: isMemoMode ?? this.isMemoMode,
      selectedCell: clearSelectedCell ? null : (selectedCell ?? this.selectedCell),
      showMistakes: showMistakes ?? this.showMistakes,
      inputMode: inputMode ?? this.inputMode,
      selectedNumber: clearSelectedNumber ? null : (selectedNumber ?? this.selectedNumber),
      currentHintLevel: currentHintLevel ?? this.currentHintLevel,
      hintTargetCell: clearHintTarget ? null : (hintTargetCell ?? this.hintTargetCell),
      lastHintResult: clearLastHint ? null : (lastHintResult ?? this.lastHintResult),
      maxMistakes: maxMistakes ?? this.maxMistakes,
      isGameOver: isGameOver ?? this.isGameOver,
      lastEncouragement: clearEncouragement ? null : (lastEncouragement ?? this.lastEncouragement),
      wrongFlashCell: clearWrongFlash ? null : (wrongFlashCell ?? this.wrongFlashCell),
      isAutoCompleting: isAutoCompleting ?? this.isAutoCompleting,
      autoCompleteCells: autoCompleteCells ?? this.autoCompleteCells,
      autoCompleteStep: autoCompleteStep ?? this.autoCompleteStep,
      recentlyCompletedLines: recentlyCompletedLines ?? this.recentlyCompletedLines,
      usedTechniques: usedTechniques ?? this.usedTechniques,
      recentlyRevealedHintCell: clearRecentlyRevealedHintCell
          ? null
          : (recentlyRevealedHintCell ?? this.recentlyRevealedHintCell),
    );
  }

  /// 셀 좌표 JSON 파싱
  static (int, int)? _parseCell(dynamic json) {
    if (json == null) return null;
    final map = json as Map<String, dynamic>;
    return (map['row'] as int, map['col'] as int);
  }

  /// 안전한 InputMode 파싱
  static InputMode _parseInputMode(String? value) {
    if (value == null) return InputMode.cellFirst;
    try {
      return InputMode.values.byName(value);
    } catch (_) {
      return InputMode.cellFirst;
    }
  }
}
