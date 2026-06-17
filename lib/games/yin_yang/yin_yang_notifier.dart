import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';
import 'yin_yang_badge_service.dart';
import 'yin_yang_storage_service.dart';
import 'engine/yin_yang_generator.dart';
import 'engine/yin_yang_hint.dart';
import 'engine/yin_yang_solver.dart';
import 'yin_yang_state.dart';

import '../../shared/services/sound_manager.dart';
const _storageKey = 'yinyang_current_game';

/// 음양 게임 Notifier — 비나이로와 동일 패턴
class YinYangNotifier extends StateNotifier<YinYangState?> with WidgetsBindingObserver {
  Timer? _timer;
  final SharedPreferences? _prefs;
  YinYangStorageService? _storageService;
  YinYangBadgeService? _badgeService;
  List<BadgeDefinition> lastNewBadges = [];

  YinYangNotifier({SharedPreferences? prefs}) : _prefs = prefs, super(null) {
    if (prefs != null) {
      _storageService = YinYangStorageService(prefs);
      _badgeService = YinYangBadgeService(prefs);
    }
    WidgetsBinding.instance.addObserver(this);
    _tryRestore();
  }

  void _tryRestore() {
    if (_prefs == null) return;
    try {
      final jsonStr = _prefs.getString(_storageKey);
      if (jsonStr == null) return;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final saved = YinYangState.fromJson(json);
      if (!saved.isCompleted) state = saved.copyWith(isPaused: true);
    } catch (_) {}
  }

  void _autoSave() {
    if (_prefs == null || state == null || state!.isCompleted) return;
    try { _prefs.setString(_storageKey, jsonEncode(state!.toJson())); } catch (_) {}
  }

  void _clearSave() => _prefs?.remove(_storageKey);

  @override
  void dispose() { _timer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (state == null) return;
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      if (!state!.isPaused && !state!.isCompleted) pause();
    }
  }

  void startNewGame({required YinYangGameMode mode, required YinYangDifficulty difficulty}) {
    _timer?.cancel();
    lastNewBadges = [];
    final seed = DateTime.now().millisecondsSinceEpoch;
    final result = YinYangGenerator.generate(
      size: difficulty.gridSize, difficulty: difficulty.code, seed: seed,
    );
    if (result == null) return;
    state = YinYangState(
      puzzle: result.puzzle, solution: result.solution,
      current: result.puzzle.copyWith(), mode: mode, difficulty: difficulty,
    );
    _startTimer(); _autoSave();
  }

  void startDailyPuzzle() {
    _timer?.cancel();
    lastNewBadges = [];
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    const difficulty = YinYangDifficulty.medium;
    final result = YinYangGenerator.generate(
      size: difficulty.gridSize, difficulty: difficulty.code, seed: seed,
    );
    if (result == null) return;
    state = YinYangState(
      puzzle: result.puzzle, solution: result.solution,
      current: result.puzzle.copyWith(),
      mode: YinYangGameMode.dailyPuzzle, difficulty: difficulty,
    );
    _startTimer(); _autoSave();
  }

  void setInputMode(YinYangInputMode mode) {
    if (state == null) return;
    state = state!.copyWith(inputMode: mode);
  }

  void tapCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    final idx = row * state!.size + col;
    if (state!.current.fixed.contains(idx)) return;
    final currentValue = state!.current.getValue(row, col);
    switch (state!.inputMode) {
      case YinYangInputMode.black:
        _applyValue(row, col, currentValue, currentValue == 0 ? -1 : 0);
      case YinYangInputMode.white:
        _applyValue(row, col, currentValue, currentValue == 1 ? -1 : 1);
      case YinYangInputMode.erase:
        if (currentValue != -1) _applyValue(row, col, currentValue, -1);
    }
  }

  void toggleCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    final idx = row * state!.size + col;
    if (state!.current.fixed.contains(idx)) return;
    final v = state!.current.getValue(row, col);
    final newV = switch (v) { -1 => 0, 0 => 1, 1 => -1, _ => -1 };
    _applyValue(row, col, v, newV);
  }

  void _applyValue(int row, int col, int previousValue, int newValue) {
    final newBoard = state!.current.setValue(row, col, newValue);
    // 햅틱: 셀 입력 가벼운 진동
    HapticFeedback.selectionClick();
    SoundManager().play(SoundManager.kClick);
    var mistakes = state!.mistakeCount;
    final wasMistake = newValue != -1 && newValue != state!.solution.getValue(row, col);
    if (wasMistake) {
      mistakes++;
      // 햅틱: 실수 강한 진동
      HapticFeedback.heavyImpact();
      SoundManager().play(SoundManager.kMistake);
    }

    final action = YinYangUndoAction(
      type: newValue == -1 ? YinYangUndoActionType.clearValue : YinYangUndoActionType.setValue,
      row: row, col: col, previousValue: previousValue,
    );

    state = state!.copyWith(
      current: newBoard,
      undoStack: [...state!.undoStack, action],
      mistakeCount: mistakes,
      selectedCell: (row, col),
    );
    _checkCompletion(); _autoSave();
  }

  void undo() {
    if (state == null || state!.isCompleted || state!.undoStack.isEmpty) return;
    final last = state!.undoStack.last;
    state = state!.copyWith(
      current: state!.current.setValue(last.row, last.col, last.previousValue),
      undoStack: state!.undoStack.sublist(0, state!.undoStack.length - 1),
      selectedCell: (last.row, last.col),
    );
    _autoSave();
  }

  void getHint() {
    if (state == null || state!.isCompleted) return;
    var nextLevel = state!.currentHintLevel + 1;
    if (nextLevel > 4) nextLevel = 1;
    if (nextLevel == 1) {
      state = state!.copyWith(clearHintTarget: true, currentHintLevel: 0);
    }
    final hint = YinYangHintEngine.getHint(state!.current, state!.solution, level: nextLevel);
    if (hint == null) return;
    final newHintCount = nextLevel == 1 ? state!.hintCount + 1 : state!.hintCount;
    state = state!.copyWith(
      currentHintLevel: nextLevel, hintTargetCell: (hint.row, hint.col),
      lastHintResult: hint, hintCount: newHintCount, selectedCell: (hint.row, hint.col),
    );
    if (nextLevel == 4 && hint.value != null) {
      state = state!.copyWith(current: state!.current.setValue(hint.row, hint.col, hint.value!));
      _checkCompletion();
    }
    _autoSave();
  }

  void pause() {
    if (state == null || state!.isCompleted) return;
    _timer?.cancel();
    state = state!.copyWith(isPaused: true); _autoSave();
  }

  void resume() {
    if (state == null || state!.isCompleted) return;
    state = state!.copyWith(isPaused: false); _startTimer();
  }

  void giveUp() { _timer?.cancel(); _clearSave(); state = null; }

  void _checkCompletion() {
    if (state == null) return;
    if (YinYangSolver.isComplete(state!.current)) {
      _timer?.cancel();
      state = state!.copyWith(isCompleted: true);
      _clearSave();
      // 햅틱: 게임 완료 시 강한 진동
      HapticFeedback.heavyImpact();
      SoundManager().play(SoundManager.kGameComplete);
      _saveCompletionAndEvaluateBadges();
    }
  }

  void _saveCompletionAndEvaluateBadges() {
    if (state == null || _storageService == null) return;
    try {
      final record = CompletedGameRecord(
        mode: state!.mode.name, difficulty: state!.difficulty.name,
        elapsedSeconds: state!.elapsedSeconds, mistakeCount: state!.mistakeCount,
        hintCount: state!.hintCount, grade: state!.grade.symbol, completedAt: DateTime.now(),
      );
      _storageService!.saveCompletedGame(record);
      if (_badgeService != null) {
        lastNewBadges = _badgeService!.evaluateNewBadges(_storageService!.loadCompletedGames());
      }
    } catch (_) {}
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == null || state!.isPaused || state!.isCompleted) return;
      state = state!.copyWith(elapsedSeconds: state!.elapsedSeconds + 1);
    });
  }

  bool get hasOngoingGame => state != null && !state!.isCompleted;

  // === 체크포인트 (메모리 저장) ===
  YinYangState? _checkpoint;

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

final yinYangProvider = StateNotifierProvider<YinYangNotifier, YinYangState?>((ref) {
  return YinYangNotifier();
});

final yinYangNotifierProvider = StateNotifierProvider<YinYangNotifier, YinYangState?>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return YinYangNotifier(prefs: prefs);
  } catch (_) {
    return YinYangNotifier();
  }
});
