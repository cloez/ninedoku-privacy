import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';
import 'kakuro_badge_service.dart';
import 'kakuro_storage_service.dart';
import 'engine/kakuro_board.dart';
import 'engine/kakuro_generator.dart';
import 'engine/kakuro_hint.dart';
import 'engine/kakuro_solver.dart';
import 'kakuro_state.dart';

import '../../shared/services/sound_manager.dart';
/// SharedPreferences 저장 키
const _storageKey = 'kakuro_current_game';

/// 카쿠로 게임 상태 관리 Notifier
class KakuroNotifier extends StateNotifier<KakuroState?>
    with WidgetsBindingObserver {
  Timer? _timer;
  final SharedPreferences? _prefs;

  /// 완료 기록 저장 서비스
  KakuroStorageService? _storageService;

  /// 배지 평가 서비스
  KakuroBadgeService? _badgeService;

  /// 마지막으로 새로 획득한 배지 목록 (결과 화면 표시용)
  List<BadgeDefinition> lastNewBadges = [];

  KakuroNotifier({SharedPreferences? prefs})
      : _prefs = prefs,
        super(null) {
    if (prefs != null) {
      _storageService = KakuroStorageService(prefs);
      _badgeService = KakuroBadgeService(prefs);
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
      final saved = KakuroState.fromJson(json);
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
    required KakuroGameMode mode,
    required KakuroDifficulty difficulty,
  }) {
    _timer?.cancel();
    lastNewBadges = [];

    final seed = DateTime.now().millisecondsSinceEpoch;
    final result = KakuroGenerator.generate(
      difficulty: difficulty.code,
      seed: seed,
    );

    if (result == null) return; // 생성 실패

    state = KakuroState(
      puzzle: result.puzzle,
      solution: result.solution,
      current: result.puzzle.copyWith(),
      mode: mode,
      difficulty: difficulty,
    );

    _startTimer();
    _autoSave();
  }

  /// 오늘의 퍼즐 시작 (날짜 기반 시드)
  void startDailyPuzzle() {
    _timer?.cancel();
    lastNewBadges = [];

    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    const difficulty = KakuroDifficulty.medium;

    final result = KakuroGenerator.generate(
      difficulty: difficulty.code,
      seed: seed,
    );

    if (result == null) return;

    state = KakuroState(
      puzzle: result.puzzle,
      solution: result.solution,
      current: result.puzzle.copyWith(),
      mode: KakuroGameMode.dailyPuzzle,
      difficulty: difficulty,
    );

    _startTimer();
    _autoSave();
  }

  /// 셀 선택
  void selectCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    // 검은 셀은 선택 불가
    final cell = state!.current.getCell(row, col);
    if (cell.type != KakuroCellType.white) return;

    // 같은 셀 재탭 시 선택 해제
    if (state!.selectedCell == (row, col)) {
      state = state!.copyWith(clearSelectedCell: true);
      _clearHintState();
      return;
    }

    // 다른 셀 선택 시 힌트 상태 초기화
    final hintTarget = state!.hintTargetCell;
    if (hintTarget != null &&
        (hintTarget.$1 != row || hintTarget.$2 != col)) {
      _clearHintState();
    }

    state = state!.copyWith(selectedCell: (row, col));
  }

  /// 숫자 입력
  void inputNumber(int num) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    if (state!.selectedCell == null) return;

    final (row, col) = state!.selectedCell!;
    final cell = state!.current.getCell(row, col);
    if (cell.type != KakuroCellType.white) return;

    final idx = row * state!.current.cols + col;
    if (state!.current.fixed.contains(idx)) return;

    if (state!.isNoteMode) {
      _toggleNote(row, col, num);
    } else {
      final currentValue = state!.current.getValue(row, col);
      if (currentValue == num) {
        // 같은 값 재입력 = 토글 삭제 (체크포인트 해제, 빈 값으로 복원)
        _applyValue(row, col, currentValue, 0);
        return;
      }
      _applyValue(row, col, currentValue, num);
    }
  }

  /// 메모 토글
  void _toggleNote(int row, int col, int num) {
    final idx = row * state!.current.cols + col;
    final previousNotes = state!.current.notes[idx] != null
        ? Set<int>.from(state!.current.notes[idx]!)
        : <int>{};

    final newBoard = state!.current.toggleNote(row, col, num);

    final undoAction = KakuroUndoAction(
      type: KakuroUndoType.toggleNote,
      row: row,
      col: col,
      previousValue: 0,
      previousNotes: previousNotes,
    );
    final newStack = [...state!.undoStack, undoAction];

    state = state!.copyWith(
      current: newBoard,
      undoStack: newStack,
    );

    _autoSave();
  }

  /// 선택된 셀 삭제
  void deleteSelected() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    if (state!.selectedCell == null) return;

    final (row, col) = state!.selectedCell!;
    final idx = row * state!.current.cols + col;
    if (state!.current.fixed.contains(idx)) return;

    final currentValue = state!.current.getValue(row, col);
    if (currentValue == 0) return;

    _applyValue(row, col, currentValue, 0);
  }

  /// 메모 모드 토글
  void toggleNoteMode() {
    if (state == null || state!.isCompleted) return;
    state = state!.copyWith(isNoteMode: !state!.isNoteMode);
  }

  /// 값 적용 (undo 스택 포함)
  void _applyValue(int row, int col, int previousValue, int newValue) {
    final newBoard = state!.current.setValue(row, col, newValue);
    // 햅틱: 셀 입력 가벼운 진동
    HapticFeedback.selectionClick();
    SoundManager().play(SoundManager.kClick);

    // 실수 판정: 값을 넣었는데 정답과 다르면 실수
    var newMistakeCount = state!.mistakeCount;
    if (newValue != 0) {
      final correctValue = state!.solution.getValue(row, col);
      if (newValue != correctValue) {
        newMistakeCount++;
        // 햅틱: 실수 강한 진동
        HapticFeedback.heavyImpact();
        SoundManager().play(SoundManager.kMistake);
      }
    }

    // Undo 스택에 추가
    final actionType = newValue == 0
        ? KakuroUndoType.clearValue
        : KakuroUndoType.setValue;
    final undoAction = KakuroUndoAction(
      type: actionType,
      row: row,
      col: col,
      previousValue: previousValue,
    );
    final newStack = [...state!.undoStack, undoAction];

    state = state!.copyWith(
      current: newBoard,
      undoStack: newStack,
      mistakeCount: newMistakeCount,
    );

    // 완료 판정
    _checkCompletion();
    _autoSave();
  }

  /// 되돌리기
  void undo() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    if (state!.undoStack.isEmpty) return;

    final lastAction = state!.undoStack.last;
    final newStack =
        state!.undoStack.sublist(0, state!.undoStack.length - 1);

    KakuroBoard newBoard;

    if (lastAction.type == KakuroUndoType.toggleNote) {
      final idx = lastAction.row * state!.current.cols + lastAction.col;
      final newNotes = Map<int, Set<int>>.fromEntries(
          state!.current.notes.entries
              .map((e) => MapEntry(e.key, Set<int>.from(e.value))));
      if (lastAction.previousNotes != null &&
          lastAction.previousNotes!.isNotEmpty) {
        newNotes[idx] = Set<int>.from(lastAction.previousNotes!);
      } else {
        newNotes.remove(idx);
      }
      newBoard = state!.current.copyWith(notes: newNotes);
    } else {
      newBoard = state!.current.setValue(
        lastAction.row,
        lastAction.col,
        lastAction.previousValue,
      );
    }

    state = state!.copyWith(
      current: newBoard,
      undoStack: newStack,
      selectedCell: (lastAction.row, lastAction.col),
    );

    _autoSave();
  }

  /// 힌트 요청 (단계적)
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

    final hint = KakuroHintEngine.getHint(
      state!.current,
      state!.solution,
      level: nextLevel,
    );

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
      final newBoard =
          state!.current.setValue(hint.row, hint.col, hint.value!);
      state = state!.copyWith(current: newBoard);
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
    if (KakuroSolver.isComplete(state!.current)) {
      _timer?.cancel();
      state = state!.copyWith(isCompleted: true);
      _clearSave();
      // 햅틱: 게임 완료 시 강한 진동
      HapticFeedback.heavyImpact();
      SoundManager().play(SoundManager.kGameComplete);
      _saveCompletionAndEvaluateBadges();
    }
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
      // 저장/평가 실패 시 게임 완료 상태에 영향 없음
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
  KakuroState? _checkpoint;

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

/// Kakuro Provider
final kakuroProvider =
    StateNotifierProvider<KakuroNotifier, KakuroState?>((ref) {
  return KakuroNotifier();
});

/// SharedPreferences가 주입된 KakuroNotifier
final kakuroNotifierProvider =
    StateNotifierProvider<KakuroNotifier, KakuroState?>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return KakuroNotifier(prefs: prefs);
  } catch (_) {
    return KakuroNotifier();
  }
});
