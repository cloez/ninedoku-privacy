import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';
import 'killer_sudoku_badge_service.dart';
import 'killer_sudoku_storage_service.dart';
import 'engine/killer_sudoku_generator.dart';
import 'engine/killer_sudoku_hint.dart';
import 'killer_sudoku_state.dart';

import '../../shared/services/sound_manager.dart';
/// SharedPreferences 저장 키
const _storageKey = 'killer_sudoku_current_game';

/// 킬러 스도쿠 게임 상태 관리 Notifier
class KillerSudokuNotifier extends StateNotifier<KillerSudokuState?>
    with WidgetsBindingObserver {
  Timer? _timer;
  final SharedPreferences? _prefs;

  /// 완료 기록 저장 서비스
  KillerSudokuStorageService? _storageService;

  /// 배지 평가 서비스
  KillerSudokuBadgeService? _badgeService;

  /// 마지막으로 새로 획득한 배지 목록 (결과 화면 표시용)
  List<BadgeDefinition> lastNewBadges = [];

  KillerSudokuNotifier({SharedPreferences? prefs})
      : _prefs = prefs,
        super(null) {
    if (prefs != null) {
      _storageService = KillerSudokuStorageService(prefs);
      _badgeService = KillerSudokuBadgeService(prefs);
    }
    WidgetsBinding.instance.addObserver(this);
    _tryRestore();
  }

  /// 저장된 게임 복원
  void _tryRestore() {
    if (_prefs == null) return;
    try {
      final jsonStr = _prefs.getString(_storageKey);
      if (jsonStr == null) return;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final saved = KillerSudokuState.fromJson(json);
      if (!saved.isCompleted) {
        state = saved.copyWith(isPaused: true);
      }
    } catch (_) {
      // 복원 실패 시 무시
    }
  }

  /// 자동 저장
  void _autoSave() {
    if (_prefs == null || state == null) return;
    if (state!.isCompleted) return;
    try {
      final jsonStr = jsonEncode(state!.toJson());
      _prefs.setString(_storageKey, jsonStr);
    } catch (_) {
      // 저장 실패 무시
    }
  }

  /// 저장 데이터 삭제
  void _clearSave() {
    _prefs?.remove(_storageKey);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱 라이프사이클 핸들링
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (state == null) return;
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      if (!state!.isPaused && !state!.isCompleted) {
        pause();
      }
    }
  }

  /// 새 게임 시작
  void startNewGame({
    required KillerSudokuGameMode mode,
    required KillerDifficulty difficulty,
  }) {
    _timer?.cancel();
    lastNewBadges = [];

    final seed = DateTime.now().millisecondsSinceEpoch;
    final result = KillerSudokuGenerator.generate(
      difficulty: difficulty,
      seed: seed,
    );

    if (result == null) return; // 생성 실패

    state = KillerSudokuState(
      board: result.board,
      mode: mode,
      difficulty: difficulty,
    );

    _startTimer();
    _autoSave();
  }

  /// 오늘의 퍼즐 시작
  void startDailyPuzzle() {
    _timer?.cancel();
    lastNewBadges = [];

    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day + 500;
    const difficulty = KillerDifficulty.medium;

    final result = KillerSudokuGenerator.generate(
      difficulty: difficulty,
      seed: seed,
    );

    if (result == null) return;

    state = KillerSudokuState(
      board: result.board,
      mode: KillerSudokuGameMode.dailyPuzzle,
      difficulty: difficulty,
    );

    _startTimer();
    _autoSave();
  }

  /// 셀 선택
  void selectCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    if (state!.selectedCell == (row, col)) {
      state = state!.copyWith(clearSelectedCell: true);
      _clearHintState();
      return;
    }

    final hintTarget = state!.hintTargetCell;
    if (hintTarget != null &&
        (hintTarget.$1 != row || hintTarget.$2 != col)) {
      _clearHintState();
    }

    state = state!.copyWith(selectedCell: (row, col));
  }

  /// 숫자 입력 (메모 모드 고려)
  void inputNumber(int value) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    final sel = state!.selectedCell;
    if (sel == null) return;
    final (row, col) = sel;
    if (state!.board.isFixed[row][col]) return;

    if (state!.isNoteMode) {
      _toggleNote(row, col, value);
    } else {
      _setValue(row, col, value);
    }
  }

  /// 셀에 직접 값 설정
  void _setValue(int row, int col, int value) {
    final currentValue = state!.board.cells[row][col];

    // 같은 값이면 삭제
    if (currentValue == value) {
      _clearCell(row, col);
      return;
    }

    // Undo 기록
    final undoAction = KillerSudokuUndoAction(
      type: KillerSudokuUndoType.setValue,
      row: row,
      col: col,
      previousValue: currentValue,
      previousNotes: Set<int>.from(state!.board.notes[row][col]),
    );
    final newStack = [...state!.undoStack, undoAction];

    // 햅틱: 셀 입력 가벼운 진동
    HapticFeedback.selectionClick();
    SoundManager().play(SoundManager.kClick);

    // 실수 판정
    var newMistakeCount = state!.mistakeCount;
    final correctValue = state!.board.solution[row][col];
    if (value != correctValue) {
      newMistakeCount++;
      // 햅틱: 실수 강한 진동
      HapticFeedback.heavyImpact();
      SoundManager().play(SoundManager.kMistake);
    }

    // 값 설정 + 관련 메모 제거
    var newBoard = state!.board.setValue(row, col, value);
    newBoard = newBoard.removeRelatedNotes(row, col, value);

    state = state!.copyWith(
      board: newBoard,
      undoStack: newStack,
      mistakeCount: newMistakeCount,
    );

    _checkCompletion();
    _autoSave();
  }

  /// 셀 값 삭제
  void _clearCell(int row, int col) {
    final currentValue = state!.board.cells[row][col];
    if (currentValue == 0) return;

    final undoAction = KillerSudokuUndoAction(
      type: KillerSudokuUndoType.clearValue,
      row: row,
      col: col,
      previousValue: currentValue,
    );
    final newStack = [...state!.undoStack, undoAction];
    final newBoard = state!.board.clearValue(row, col);

    state = state!.copyWith(board: newBoard, undoStack: newStack);
    _autoSave();
  }

  /// 선택된 셀 삭제
  void deleteSelected() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    final sel = state!.selectedCell;
    if (sel == null) return;
    final (row, col) = sel;
    if (state!.board.isFixed[row][col]) return;

    if (state!.board.cells[row][col] != 0) {
      _clearCell(row, col);
    } else if (state!.board.notes[row][col].isNotEmpty) {
      // 메모도 삭제
      final undoAction = KillerSudokuUndoAction(
        type: KillerSudokuUndoType.toggleNote,
        row: row,
        col: col,
        previousValue: 0,
        previousNotes: Set<int>.from(state!.board.notes[row][col]),
      );
      final newStack = [...state!.undoStack, undoAction];
      var newBoard = state!.board.copyWith();
      // 메모 전체 클리어
      final newNotes = List.generate(
        9,
        (r) => List.generate(
          9,
          (c) => r == row && c == col
              ? <int>{}
              : Set<int>.from(newBoard.notes[r][c]),
        ),
      );
      newBoard = newBoard.copyWith(notes: newNotes);
      state = state!.copyWith(board: newBoard, undoStack: newStack);
      _autoSave();
    }
  }

  /// 메모 토글
  void _toggleNote(int row, int col, int value) {
    if (state!.board.cells[row][col] != 0) return;

    final undoAction = KillerSudokuUndoAction(
      type: KillerSudokuUndoType.toggleNote,
      row: row,
      col: col,
      previousValue: 0,
      previousNotes: Set<int>.from(state!.board.notes[row][col]),
    );
    final newStack = [...state!.undoStack, undoAction];
    final newBoard = state!.board.toggleNote(row, col, value);

    state = state!.copyWith(board: newBoard, undoStack: newStack);
    _autoSave();
  }

  /// 메모 모드 토글
  void toggleNoteMode() {
    if (state == null) return;
    state = state!.copyWith(isNoteMode: !state!.isNoteMode);
  }

  /// 되돌리기
  void undo() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    if (state!.undoStack.isEmpty) return;

    final lastAction = state!.undoStack.last;
    final newStack = state!.undoStack.sublist(0, state!.undoStack.length - 1);

    var newBoard = state!.board;
    switch (lastAction.type) {
      case KillerSudokuUndoType.setValue:
      case KillerSudokuUndoType.clearValue:
        if (lastAction.previousValue == 0) {
          newBoard = newBoard.clearValue(lastAction.row, lastAction.col);
        } else {
          newBoard = newBoard.setValue(
            lastAction.row,
            lastAction.col,
            lastAction.previousValue,
          );
        }
        // 이전 메모 복원
        if (lastAction.previousNotes != null) {
          final restoredNotes = List.generate(
            9,
            (r) => List.generate(
              9,
              (c) => r == lastAction.row && c == lastAction.col
                  ? Set<int>.from(lastAction.previousNotes!)
                  : Set<int>.from(newBoard.notes[r][c]),
            ),
          );
          newBoard = newBoard.copyWith(notes: restoredNotes);
        }
      case KillerSudokuUndoType.toggleNote:
        if (lastAction.previousNotes != null) {
          final restoredNotes = List.generate(
            9,
            (r) => List.generate(
              9,
              (c) => r == lastAction.row && c == lastAction.col
                  ? Set<int>.from(lastAction.previousNotes!)
                  : Set<int>.from(newBoard.notes[r][c]),
            ),
          );
          newBoard = newBoard.copyWith(notes: restoredNotes);
        }
    }

    state = state!.copyWith(
      board: newBoard,
      undoStack: newStack,
      selectedCell: (lastAction.row, lastAction.col),
    );
    _autoSave();
  }

  /// 힌트 요청
  void getHint() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    var nextLevel = state!.currentHintLevel + 1;
    if (nextLevel > 4) nextLevel = 1;

    if (nextLevel == 1) {
      state = state!.copyWith(
        clearHintTarget: true,
        currentHintLevel: 0,
      );
    }

    final hint = KillerSudokuHintEngine.getHint(state!.board, nextLevel);
    if (hint == null) return;

    final newHintCount =
        nextLevel == 1 ? state!.hintCount + 1 : state!.hintCount;

    state = state!.copyWith(
      currentHintLevel: nextLevel,
      hintTargetCell: (hint.row, hint.col),
      lastHintResult: hint,
      hintCount: newHintCount,
      selectedCell: (hint.row, hint.col),
    );

    // Level 4: 정답 자동 입력
    if (nextLevel == 4 && hint.value != null) {
      var newBoard = state!.board.setValue(hint.row, hint.col, hint.value!);
      newBoard = newBoard.removeRelatedNotes(hint.row, hint.col, hint.value!);
      state = state!.copyWith(board: newBoard);
      _checkCompletion();
    }

    _autoSave();
  }

  /// 힌트 상태 초기화
  void _clearHintState() {
    if (state == null) return;
    state = state!.copyWith(
      currentHintLevel: 0,
      clearHintTarget: true,
      clearLastHint: true,
    );
  }

  /// 일시정지
  void pause() {
    if (state == null || state!.isCompleted) return;
    _timer?.cancel();
    state = state!.copyWith(isPaused: true);
    _autoSave();
  }

  /// 게임 재개
  void resume() {
    if (state == null || state!.isCompleted) return;
    state = state!.copyWith(isPaused: false);
    _startTimer();
  }

  /// 포기
  void giveUp() {
    _timer?.cancel();
    _clearSave();
    state = null;
  }

  /// 완료 판정
  void _checkCompletion() {
    if (state == null) return;
    final board = state!.board;
    // 모든 셀이 정답과 일치하는지 확인
    if (!board.isComplete) return;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.cells[r][c] != board.solution[r][c]) return;
      }
    }

    _timer?.cancel();
    state = state!.copyWith(isCompleted: true);
    _clearSave();
    // 햅틱: 게임 완료 시 강한 진동
    HapticFeedback.heavyImpact();
    SoundManager().play(SoundManager.kGameComplete);
    _saveCompletionAndEvaluateBadges();
  }

  /// 완료 기록 저장 + 배지 평가
  void _saveCompletionAndEvaluateBadges() {
    if (state == null || _storageService == null) return;

    try {
      final record = CompletedGameRecord(
        mode: state!.mode.name,
        difficulty: state!.difficulty.name,
        elapsedSeconds: state!.elapsedSeconds,
        mistakeCount: state!.mistakeCount,
        hintCount: state!.hintCount,
        grade: state!.grade.symbol,
        completedAt: DateTime.now(),
      );

      _storageService!.saveCompletedGame(record);

      if (_badgeService != null) {
        final allRecords = _storageService!.loadCompletedGames();
        lastNewBadges = _badgeService!.evaluateNewBadges(allRecords);
      }
    } catch (_) {
      // 저장 실패 시 무시
    }
  }

  /// 타이머 시작
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == null || state!.isPaused || state!.isCompleted) return;
      state = state!.copyWith(elapsedSeconds: state!.elapsedSeconds + 1);
    });
  }

  /// 진행 중인 게임이 있는지
  bool get hasOngoingGame => state != null && !state!.isCompleted;

  // === 체크포인트 (메모리 저장) ===
  KillerSudokuState? _checkpoint;

  /// 체크포인트가 저장되어 있는지 여부
  bool get hasCheckpoint => _checkpoint != null;

  /// 현재 상태를 체크포인트로 저장
  void saveCheckpoint() {
    if (state == null || state!.isCompleted) return;
    _checkpoint = state;
  }

  /// 체크포인트로 복원
  void restoreCheckpoint() {
    if (_checkpoint == null) return;
    state = _checkpoint;
  }

  /// 체크포인트 삭제
  void clearCheckpoint() {
    _checkpoint = null;
  }
}

/// 킬러 스도쿠 Provider
final killerSudokuProvider =
    StateNotifierProvider<KillerSudokuNotifier, KillerSudokuState?>((ref) {
  return KillerSudokuNotifier();
});

/// SharedPreferences가 주입된 KillerSudokuNotifier
final killerSudokuNotifierProvider =
    StateNotifierProvider<KillerSudokuNotifier, KillerSudokuState?>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return KillerSudokuNotifier(prefs: prefs);
  } catch (_) {
    return KillerSudokuNotifier();
  }
});
