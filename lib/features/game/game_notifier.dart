import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/sudoku/board.dart';
import '../../core/sudoku/difficulty.dart';
import '../../core/sudoku/generator.dart';
import '../../core/sudoku/hint_engine.dart';
import '../../core/sudoku/puzzle_cache_service.dart';
import '../../core/sudoku/technique_analyzer.dart';
import '../../core/utils/feedback_service.dart';
import '../../core/settings/settings_service.dart';
import 'game_state.dart';
import '../../core/storage/game_storage_service.dart';
import '../../core/storage/storage_providers.dart';
import '../badges/badge_service.dart';
import '../badges/badge_definitions.dart';
import '../daily_puzzle/daily_puzzle_service.dart';

/// 게임 상태 관리 Notifier
class GameNotifier extends StateNotifier<GameState?> with WidgetsBindingObserver {
  Timer? _timer;
  final GameStorageService? _storage;
  final SharedPreferences? _prefs;
  final FeedbackService? _feedback;

  /// 새로 획득한 배지 (UI에서 팝업 표시용)
  List<BadgeDefinition> lastNewBadges = [];

  GameNotifier({GameStorageService? storage, SharedPreferences? prefs})
      : _storage = storage,
        _prefs = prefs,
        _feedback = prefs != null ? FeedbackService(SettingsService(prefs)) : null,
        super(null) {
    WidgetsBinding.instance.addObserver(this);
    _tryRestoreFromStorage();
  }

  /// 테스트용 상태 접근
  @visibleForTesting
  GameState? get testState => state;

  /// 저장소에서 게임 복원 시도
  void _tryRestoreFromStorage() {
    if (_storage == null) return;
    final saved = _storage.loadCurrentGame();
    if (saved != null && !saved.isCompleted) {
      state = saved.copyWith(isPaused: true);
    }
  }

  /// 상태 변경 시 자동 저장 (완료된 게임은 _onGameCompleted에서 처리)
  void _autoSave() {
    if (_storage == null || state == null) return;
    // 완료된 게임은 저장하지 않음 (_onGameCompleted에서 삭제 처리)
    if (state!.isCompleted) return;
    _storage.saveCurrentGame(state!);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoCompleteTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱 라이프사이클 핸들링
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (state == null) return;
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      // 앱이 백그라운드로 갈 때 자동 일시정지
      if (!state!.isPaused && !state!.isCompleted) {
        pause();
      }
    }
  }

  /// 새 게임 시작 (캐시 우선 사용)
  void startNewGame({
    required GameMode mode,
    required Difficulty difficulty,
    int? seed,
  }) {
    _timer?.cancel();

    List<List<int>>? puzzle;
    List<List<int>>? solution;

    // seed 미지정 시 캐시에서 퍼즐 가져오기
    if (seed == null && _prefs != null) {
      final cache = PuzzleCacheService(_prefs);
      final cached = cache.take(difficulty);
      if (cached != null) {
        puzzle = cached.puzzle;
        solution = cached.solution;
      }
      // 사용 후 백그라운드 보충
      cache.refill(difficulty);
    }

    // 캐시에 없으면 실시간 생성
    if (puzzle == null || solution == null) {
      final result = SudokuGenerator.generate(
        difficulty: difficulty,
        seed: seed,
      );
      if (result == null) return;
      puzzle = result.puzzle;
      solution = result.solution;
    }

    final board = SudokuBoard(puzzle: puzzle, solution: solution);

    // 릴렉스 모드는 실수 표시 안 함
    final showMistakes = mode != GameMode.relax;

    state = GameState(
      board: board,
      mode: mode,
      difficulty: difficulty,
      showMistakes: showMistakes,
      maxMistakes: mode == GameMode.challenge ? 3 : null,
    );

    // 마지막 난이도 저장 (빠른 게임 가중치용)
    if (_prefs != null) {
      SettingsService(_prefs).setLastDifficulty(difficulty.name);
    }

    _startTimer();
    _autoSave();
  }

  /// 기존 게임 복원
  void restoreGame(GameState savedState) {
    state = savedState;
    if (!savedState.isPaused && !savedState.isCompleted) {
      _startTimer();
    }
  }

  /// 셀 선택 (같은 셀 재탭 시 해제, 숫자 우선 모드에서는 자동 입력)
  void selectCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    // 같은 셀 재탭 시 선택 해제 (숫자 우선 모드에서 숫자 선택 안 된 경우만)
    if (state!.selectedCell == (row, col)) {
      final hasNumberSelected = state!.inputMode == InputMode.numberFirst &&
          state!.selectedNumber != null;
      if (!hasNumberSelected) {
        state = state!.copyWith(clearSelectedCell: true);
        clearHintState();
        return;
      }
    }

    // 다른 셀 선택 시 힌트 진행 상태 초기화
    final hintTarget = state!.hintTargetCell;
    if (hintTarget != null && (hintTarget.$1 != row || hintTarget.$2 != col)) {
      clearHintState();
    }

    // 숫자 우선 모드: 선택된 숫자가 있으면 즉시 입력 (메모/일반 모드 모두 지원)
    if (state!.inputMode == InputMode.numberFirst && state!.selectedNumber != null) {
      if (!state!.board.isFixed[row][col]) {
        state = state!.copyWith(selectedCell: (row, col));
        // 메모 모드이면 메모 토글, 일반 모드이면 숫자 입력
        inputNumber(state!.selectedNumber!);
        return;
      }
    }
    state = state!.copyWith(selectedCell: (row, col));
  }

  /// 숫자 입력
  void inputNumber(int value) {
    if (state == null || state!.isCompleted || state!.isGameOver || state!.isAutoCompleting || state!.selectedCell == null) return;
    final (row, col) = state!.selectedCell!;
    if (state!.board.isFixed[row][col]) return;

    if (state!.isMemoMode) {
      _toggleNote(row, col, value);
    } else {
      // 같은 숫자 재입력 시 값 삭제 (토글 입력)
      if (state!.board.currentBoard[row][col] == value) {
        deleteValue();
      } else {
        _setValue(row, col, value);
      }
    }
  }

  void _setValue(int row, int col, int value) {
    final currentValue = state!.board.currentBoard[row][col];
    final currentNotes = Set<int>.from(state!.board.notes[row][col]);

    // 정답 입력 전 기법 분석 (추임새용)
    Encouragement? encouragement;
    final isCorrect = state!.board.solution[row][col] == value;
    if (isCorrect) {
      encouragement = _analyzeEncouragement(row, col);
    }

    // Undo 액션 기록
    final undoAction = UndoAction(
      type: UndoActionType.setValue,
      row: row,
      col: col,
      previousValue: currentValue,
      previousNotes: currentNotes,
    );

    var newBoard = state!.board.setValue(row, col, value);

    // 실수 확인
    var mistakes = state!.mistakeCount;
    (int, int)? wrongFlash; // 릴렉스 모드 오답 플래시용
    if (newBoard.isWrong(row, col)) {
      mistakes++;
      _feedback?.onMistake();
      // 릴렉스 모드: 실수 표시 꺼져 있으면 일시 플래시로 피드백
      if (!state!.showMistakes) {
        wrongFlash = (row, col);
        // 0.5초 후 자동 클리어
        Future.delayed(const Duration(milliseconds: 500), () {
          clearWrongFlash();
        });
      }
    } else {
      _feedback?.onNumberInput();
      // 정답이면 관련 메모 자동 제거
      newBoard = newBoard.autoRemoveNotes(row, col, value);
    }

    final newUndo = [...state!.undoStack, undoAction];

    // 도전 모드 실수 초과 → 게임 오버
    final gameOver = state!.maxMistakes != null && mistakes >= state!.maxMistakes!;

    // 자동 완성 체크: 설정이 켜져 있고, 남은 빈 칸이 연쇄 Naked Single로 해결 가능하면 자동 완성
    final autoCompleteEnabled = _prefs != null
        ? SettingsService(_prefs).autoComplete
        : true;
    var autoCompleteCells = autoCompleteEnabled && !gameOver && isCorrect
        ? _getAutoCompleteCells(newBoard)
        : <(int, int, int)>[];

    // 퍼펙트 자동완성: 기존 자동완성 미발동 + 실수 0 → 솔루션 기반 자동완성
    if (autoCompleteCells.isEmpty &&
        autoCompleteEnabled && !gameOver && isCorrect && mistakes == 0) {
      autoCompleteCells = _getPerfectAutoCompleteCells(newBoard);
    }

    final shouldAutoComplete = autoCompleteCells.isNotEmpty;

    // 자동완성 시: 보드를 즉시 완성하되, UI 애니메이션용 셀 목록 저장
    if (shouldAutoComplete) {
      var completedBoard = newBoard;
      for (final (r, c, v) in autoCompleteCells) {
        completedBoard = completedBoard.setValue(r, c, v);
        completedBoard = completedBoard.autoRemoveNotes(r, c, v);
      }
      state = state!.copyWith(
        board: completedBoard,
        undoStack: newUndo,
        mistakeCount: mistakes,
        isCompleted: true,
        isAutoCompleting: true,
        autoCompleteCells: autoCompleteCells,
        lastEncouragement: encouragement,
        clearEncouragement: encouragement == null,
        wrongFlashCell: wrongFlash,
        clearWrongFlash: wrongFlash == null,
      );
      _timer?.cancel();
      _feedback?.onGameComplete();
      if (mistakes == 0) {
        state = state!.copyWith(lastEncouragement: Encouragement.perfect);
      }
      _onGameCompleted();
      // 애니메이션 완료 후 isAutoCompleting 해제 (UI에서 순차 표시)
      _scheduleAutoCompleteEnd(autoCompleteCells.length);
    } else {
      state = state!.copyWith(
        board: newBoard,
        undoStack: newUndo,
        mistakeCount: mistakes,
        isCompleted: newBoard.isCompleted,
        isGameOver: gameOver,
        lastEncouragement: encouragement,
        clearEncouragement: encouragement == null,
        wrongFlashCell: wrongFlash,
        clearWrongFlash: wrongFlash == null,
      );

      if (gameOver) {
        _timer?.cancel();
        _feedback?.onMistake();
        return;
      }

      if (newBoard.isCompleted) {
        _timer?.cancel();
        _feedback?.onGameComplete();
        if (mistakes == 0) {
          state = state!.copyWith(lastEncouragement: Encouragement.perfect);
        }
        _onGameCompleted();
      } else {
        // 숫자 우선 모드: 현재 숫자가 9개 완성 시 다음 미완성 숫자 자동 선택
        _autoAdvanceNumber(newBoard, value);
      }
    }
    _autoSave();
  }

  /// 숫자 우선 모드: 현재 숫자가 9개 완성 시 다음 미완성 숫자 자동 선택
  void _autoAdvanceNumber(SudokuBoard board, int currentNumber) {
    if (state == null || state!.inputMode != InputMode.numberFirst) return;
    if (state!.selectedNumber != currentNumber) return;

    // 현재 숫자의 정답 카운트 확인
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.currentBoard[r][c] == currentNumber && !board.isWrong(r, c)) {
          count++;
        }
      }
    }
    if (count < 9) return; // 아직 완성 안 됨

    // 다음 미완성 숫자 찾기 (현재+1부터 순회, 9 다음은 1로)
    for (var offset = 1; offset <= 9; offset++) {
      final next = ((currentNumber - 1 + offset) % 9) + 1;
      var nextCount = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.currentBoard[r][c] == next && !board.isWrong(r, c)) {
            nextCount++;
          }
        }
      }
      if (nextCount < 9) {
        state = state!.copyWith(selectedNumber: next);
        return;
      }
    }
    // 모든 숫자 완성 시 선택 해제
    state = state!.copyWith(clearSelectedNumber: true);
  }

  /// 정답 입력 시 해당 셀에 필요한 기법 분석 → 추임새 결정
  Encouragement? _analyzeEncouragement(int row, int col) {
    final technique = TechniqueAnalyzer.findTechniqueForCell(
      state!.board.currentBoard, row, col,
    );
    if (technique == null) return null;

    switch (technique) {
      case SolvingTechnique.nakedPair:
      case SolvingTechnique.hiddenPair:
      case SolvingTechnique.pointingPair:
      case SolvingTechnique.boxLineReduction:
        return Encouragement.good;
      case SolvingTechnique.nakedTriple:
      case SolvingTechnique.xWing:
        return Encouragement.excellent;
      default:
        return null; // Naked Single, Hidden Single은 기본 → 반응 없음
    }
  }

  /// 자동완성 가능한 셀 목록을 해결 순서대로 반환
  /// 빈 칸 2~10개 범위, 연쇄 Naked Single로 모두 해결 가능해야 함
  List<(int, int, int)> _getAutoCompleteCells(SudokuBoard board) {
    // 빈 칸 수 확인 (2~10개)
    var emptyCount = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.currentBoard[r][c] == 0) {
          emptyCount++;
          if (emptyCount > 10) return []; // 11개 이상이면 자동완성 안 함
        }
      }
    }
    if (emptyCount < 2) return []; // 1개 이하면 대상 아님

    // 시뮬레이션: 연쇄 Naked Single로 모든 빈 칸 해결 시도
    final simBoard = List.generate(9, (r) => List<int>.from(board.currentBoard[r]));
    final result = <(int, int, int)>[];
    var solved = true;

    for (var iteration = 0; iteration < emptyCount; iteration++) {
      var foundOne = false;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (simBoard[r][c] == 0) {
            final candidates = _getCandidates(simBoard, r, c);
            if (candidates.length == 1) {
              final value = candidates.first;
              simBoard[r][c] = value;
              result.add((r, c, value));
              foundOne = true;
            }
          }
        }
      }
      if (!foundOne) { solved = false; break; }
    }

    // 모든 빈 칸이 해결되지 않으면 자동완성 안 함
    if (!solved) {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (simBoard[r][c] == 0) return [];
        }
      }
    }
    return result;
  }

  /// 퍼펙트 자동완성: 실수 0인 경우 남은 빈 셀을 솔루션으로 직접 채움
  /// Naked Single 체인 불필요 — 퍼펙트 달성 보상으로 자동완성
  List<(int, int, int)> _getPerfectAutoCompleteCells(SudokuBoard board) {
    final cells = <(int, int, int)>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.currentBoard[r][c] == 0) {
          cells.add((r, c, board.solution[r][c]));
        }
      }
    }
    // 빈 셀 2~10개 범위만 자동완성
    if (cells.length < 2 || cells.length > 10) return [];
    return cells;
  }

  Timer? _autoCompleteTimer;

  /// 자동완성 순차 표시 애니메이션: 300ms 간격으로 step 증가
  /// 보드는 이미 완성된 상태이며, UI에서 step까지만 표시
  void _scheduleAutoCompleteEnd(int cellCount) {
    if (cellCount <= 0) return;
    var step = 0;
    _autoCompleteTimer?.cancel();
    _autoCompleteTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (state == null) {
        timer.cancel();
        _autoCompleteTimer = null;
        return;
      }
      step++;
      _feedback?.onNumberInput();

      // 현재 표시 중인 셀로 선택 커서 이동
      if (step <= state!.autoCompleteCells.length) {
        final (r, c, _) = state!.autoCompleteCells[step - 1];
        state = state!.copyWith(
          autoCompleteStep: step,
          selectedCell: (r, c),
        );
      }

      if (step >= cellCount) {
        // 모든 셀 표시 완료 → 자동완성 상태 해제
        timer.cancel();
        _autoCompleteTimer = null;
        state = state!.copyWith(
          isAutoCompleting: false,
          autoCompleteCells: const [],
          autoCompleteStep: 0,
        );
      }
    });
  }

  /// 셀의 후보 숫자 계산
  Set<int> _getCandidates(List<List<int>> board, int row, int col) {
    final used = <int>{};
    for (var c = 0; c < 9; c++) {
      if (board[row][c] != 0) used.add(board[row][c]);
    }
    for (var r = 0; r < 9; r++) {
      if (board[r][col] != 0) used.add(board[r][col]);
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] != 0) used.add(board[r][c]);
      }
    }
    return {for (var n = 1; n <= 9; n++) if (!used.contains(n)) n};
  }

  void _toggleNote(int row, int col, int value) {
    final currentNotes = Set<int>.from(state!.board.notes[row][col]);

    final undoAction = UndoAction(
      type: UndoActionType.toggleNote,
      row: row,
      col: col,
      previousNotes: currentNotes,
    );

    final newBoard = state!.board.toggleNote(row, col, value);
    final newUndo = [...state!.undoStack, undoAction];
    _feedback?.onNumberInput();

    state = state!.copyWith(board: newBoard, undoStack: newUndo);
    _autoSave();
  }

  /// 셀 값 삭제
  void deleteValue() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting || state!.selectedCell == null) return;
    final (row, col) = state!.selectedCell!;
    if (state!.board.isFixed[row][col]) return;

    final currentValue = state!.board.currentBoard[row][col];
    final currentNotes = Set<int>.from(state!.board.notes[row][col]);
    if (currentValue == 0 && currentNotes.isEmpty) return;

    final undoAction = UndoAction(
      type: UndoActionType.clearValue,
      row: row,
      col: col,
      previousValue: currentValue,
      previousNotes: currentNotes,
    );

    final newBoard = state!.board.clearValue(row, col);
    final newUndo = [...state!.undoStack, undoAction];

    state = state!.copyWith(board: newBoard, undoStack: newUndo);
    _autoSave();
  }

  /// 되돌리기
  void undo() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting || state!.undoStack.isEmpty) return;

    final newUndo = List<UndoAction>.from(state!.undoStack);
    final action = newUndo.removeLast();
    var newBoard = state!.board;

    switch (action.type) {
      case UndoActionType.setValue:
        if (action.previousValue != null && action.previousValue! > 0) {
          newBoard = newBoard.setValue(action.row, action.col, action.previousValue!);
        } else {
          newBoard = newBoard.clearValue(action.row, action.col);
        }
        // 이전 메모 복원
        if (action.previousNotes != null && action.previousNotes!.isNotEmpty) {
          for (final note in action.previousNotes!) {
            newBoard = newBoard.toggleNote(action.row, action.col, note);
          }
        }

      case UndoActionType.clearValue:
        if (action.previousValue != null && action.previousValue! > 0) {
          newBoard = newBoard.setValue(action.row, action.col, action.previousValue!);
        }

      case UndoActionType.toggleNote:
        // 이전 메모 상태로 복원: 현재 메모를 모두 제거 후 이전 메모 추가
        final currentNotes = Set<int>.from(newBoard.notes[action.row][action.col]);
        for (final n in currentNotes) {
          newBoard = newBoard.toggleNote(action.row, action.col, n);
        }
        if (action.previousNotes != null) {
          for (final n in action.previousNotes!) {
            newBoard = newBoard.toggleNote(action.row, action.col, n);
          }
        }

      case UndoActionType.autoFillNotes:
        // 전체 메모 상태를 백업으로 복원
        if (action.previousAllNotes != null) {
          newBoard = newBoard.restoreNotes(action.previousAllNotes!);
        }
    }

    state = state!.copyWith(
      board: newBoard,
      undoStack: newUndo,
      selectedCell: (action.row, action.col),
    );
    _autoSave();
  }

  /// 자동 메모 채우기 — 모든 빈 칸에 가능한 후보 숫자를 기록
  void autoFillNotes() {
    if (state == null || state!.isCompleted) return;

    // 현재 메모 상태 백업 (Undo용)
    final previousNotes = SudokuBoard.copyNotesStatic(state!.board.notes);
    final undoAction = UndoAction(
      type: UndoActionType.autoFillNotes,
      row: 0,
      col: 0,
      previousAllNotes: previousNotes,
    );

    final newBoard = state!.board.autoFillNotes();
    state = state!.copyWith(
      board: newBoard,
      undoStack: [...state!.undoStack, undoAction],
    );
    _autoSave();
  }

  /// 입력 모드 전환 (셀 우선 ↔ 숫자 우선)
  void toggleInputMode() {
    if (state == null || state!.isCompleted) return;
    final newMode = state!.inputMode == InputMode.cellFirst
        ? InputMode.numberFirst
        : InputMode.cellFirst;
    state = state!.copyWith(
      inputMode: newMode,
      clearSelectedNumber: true,
    );
  }

  /// 숫자 우선 모드에서 숫자 선택 (같은 숫자 재선택 시 해제)
  void selectNumber(int number) {
    if (state == null || state!.isCompleted) return;
    if (state!.selectedNumber == number) {
      state = state!.copyWith(clearSelectedNumber: true);
    } else {
      state = state!.copyWith(selectedNumber: number);
    }
  }

  /// 메모 모드 토글
  void toggleMemoMode() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    state = state!.copyWith(isMemoMode: !state!.isMemoMode);
  }

  /// 점진적 힌트 사용 (1→2→3→4 단계)
  void useHint() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting || state!.isHintDisabled) return;

    // 다음 힌트 단계 결정
    final nextLevel = _getNextHintLevel();
    final hint = HintEngine.getHint(
      board: state!.board,
      level: nextLevel,
      targetCell: state!.hintTargetCell,
    );
    if (hint == null) return;
    _feedback?.onHintUsed();

    // 4단계(정답 공개)에서만 실제 값 입력 + 힌트 카운트 증가
    if (nextLevel == HintLevel.revealAnswer) {
      _applyRevealHint(hint);
    } else {
      // 1~3단계: 정보만 제공 (힌트 결과를 상태에 저장)
      state = state!.copyWith(
        selectedCell: (hint.row, hint.col),
        lastHintResult: hint,
        currentHintLevel: nextLevel.index + 1,
        hintTargetCell: (hint.row, hint.col),
      );
    }
  }

  /// 다음 힌트 단계 결정
  HintLevel _getNextHintLevel() {
    final current = state!.currentHintLevel;
    final targetCell = state!.hintTargetCell;

    // 이전에 힌트를 사용한 같은 셀이면 다음 단계로 진행
    if (current > 0 && current < 4 && targetCell != null) {
      // 대상 셀이 아직 비어있으면 다음 단계
      final (r, c) = targetCell;
      if (state!.board.currentBoard[r][c] == 0) {
        return HintLevel.values[current]; // 현재 1이면 index 1 = showCandidates
      }
    }

    // 새 힌트 시작 — 1단계부터
    return HintLevel.highlightRegion;
  }

  /// 4단계 힌트 적용 — 정답 입력
  void _applyRevealHint(HintResult hint) {
    state = state!.copyWith(
      selectedCell: (hint.row, hint.col),
      isMemoMode: false,
      lastHintResult: hint,
    );

    if (hint.answer != null) {
      final undoAction = UndoAction(
        type: UndoActionType.setValue,
        row: hint.row,
        col: hint.col,
        previousValue: state!.board.currentBoard[hint.row][hint.col],
        previousNotes: Set<int>.from(state!.board.notes[hint.row][hint.col]),
      );

      var newBoard = state!.board.setValue(hint.row, hint.col, hint.answer!);
      newBoard = newBoard.autoRemoveNotes(hint.row, hint.col, hint.answer!);

      state = state!.copyWith(
        board: newBoard,
        hintCount: state!.hintCount + 1,
        undoStack: [...state!.undoStack, undoAction],
        isCompleted: newBoard.isCompleted,
        currentHintLevel: 0,
        clearHintTarget: true,
        clearLastHint: true,
      );

      if (newBoard.isCompleted) {
        _timer?.cancel();
        _onGameCompleted();
      }
      _autoSave();
    }
  }

  /// 오답 플래시 소비 (UI 애니메이션 후 호출)
  void clearWrongFlash() {
    if (state == null || state!.wrongFlashCell == null) return;
    state = state!.copyWith(clearWrongFlash: true);
  }

  /// 추임새 소비 (UI에서 표시 후 호출)
  void clearEncouragement() {
    if (state == null || state!.lastEncouragement == null) return;
    state = state!.copyWith(clearEncouragement: true);
  }

  /// 힌트 상태 초기화 (셀 선택 변경 시 등)
  void clearHintState() {
    if (state == null) return;
    if (state!.currentHintLevel > 0) {
      state = state!.copyWith(
        currentHintLevel: 0,
        clearHintTarget: true,
        clearLastHint: true,
      );
    }
  }

  /// 일시정지
  void pause() {
    if (state == null || state!.isCompleted || state!.isPaused) return;
    _timer?.cancel();
    state = state!.copyWith(isPaused: true);
    _autoSave();
  }

  /// 재개
  void resume() {
    if (state == null || state!.isCompleted || !state!.isPaused) return;
    state = state!.copyWith(isPaused: false);
    _startTimer();
  }

  /// 타이머 시작
  void _startTimer() {
    // 릴렉스 모드는 타이머 없음
    if (state?.mode == GameMode.relax) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state != null && !state!.isPaused && !state!.isCompleted) {
        state = state!.copyWith(elapsedSeconds: state!.elapsedSeconds + 1);
      }
    });
  }

  /// 게임 포기
  void giveUp() {
    _timer?.cancel();
    state = null;
    _storage?.deleteCurrentGame();
  }

  /// 게임 완료 시 기록 저장 + 배지 평가 + 오늘의 퍼즐 기록
  void _onGameCompleted() {
    if (_storage == null || state == null) return;

    final now = DateTime.now();
    _storage.saveCompletedGame(CompletedGameRecord(
      mode: state!.mode.name,
      difficulty: state!.difficulty.name,
      elapsedSeconds: state!.elapsedSeconds,
      mistakeCount: state!.mistakeCount,
      hintCount: state!.hintCount,
      grade: state!.grade.symbol,
      completedAt: now,
    ));
    _storage.deleteCurrentGame();

    // 배지 평가
    if (_prefs != null) {
      final badgeService = BadgeService(_prefs);
      final records = _storage.loadCompletedGames();
      lastNewBadges = badgeService.evaluateNewBadges(records);
      if (lastNewBadges.isNotEmpty) _feedback?.onBadgeEarned();

      // 오늘의 퍼즐 완료 기록
      if (state!.mode == GameMode.dailyPuzzle) {
        final dailyService = DailyPuzzleService(_prefs);
        dailyService.markCompleted(now, perfect: state!.grade == Grade.perfect);
      }
    }
  }
}

/// 게임 상태 Provider
final gameProvider = StateNotifierProvider<GameNotifier, GameState?>((ref) {
  // storage/prefs가 없으면 인메모리 모드 (테스트 호환)
  GameStorageService? storage;
  SharedPreferences? prefs;
  try {
    storage = ref.read(gameStorageProvider);
    prefs = ref.read(sharedPreferencesProvider);
  } catch (_) {
    // ProviderScope에 provider가 없으면 무시
  }
  return GameNotifier(storage: storage, prefs: prefs);
});
