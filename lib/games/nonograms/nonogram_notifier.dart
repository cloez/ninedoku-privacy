import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';
import 'nonogram_badge_service.dart';
import 'nonogram_storage_service.dart';
import 'engine/nonogram_generator.dart';
import 'engine/nonogram_hint.dart';
import 'engine/nonogram_solver.dart';
import 'nonogram_state.dart';

import '../../shared/services/sound_manager.dart';
/// SharedPreferences 저장 키
const _storageKey = 'nonogram_current_game';

/// 노노그램 게임 상태 관리 Notifier
class NonogramNotifier extends StateNotifier<NonogramState?> with WidgetsBindingObserver {
  Timer? _timer;
  final SharedPreferences? _prefs;

  /// 완료 기록 저장 서비스
  NonogramStorageService? _storageService;

  /// 배지 평가 서비스
  NonogramBadgeService? _badgeService;

  /// 마지막으로 새로 획득한 배지 목록 (결과 화면 표시용)
  List<BadgeDefinition> lastNewBadges = [];

  NonogramNotifier({SharedPreferences? prefs})
      : _prefs = prefs,
        super(null) {
    // SharedPreferences가 있으면 서비스 초기화
    if (prefs != null) {
      _storageService = NonogramStorageService(prefs);
      _badgeService = NonogramBadgeService(prefs);
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
      final saved = NonogramState.fromJson(json);
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
    required NonogramGameMode mode,
    required NonogramDifficulty difficulty,
  }) {
    _timer?.cancel();
    lastNewBadges = []; // 이전 배지 결과 초기화

    final seed = DateTime.now().millisecondsSinceEpoch;
    final result = NonogramGenerator.generate(
      size: difficulty.gridSize,
      seed: seed,
      difficulty: difficulty.code,
    );

    if (result == null) return; // 생성 실패

    state = NonogramState(
      puzzle: result.puzzle,
      solution: result.solution,
      current: result.puzzle.copyWith(),
      mode: mode,
      difficulty: difficulty,
    );

    _startTimer();
    _autoSave();
  }

  /// 오늘의 퍼즐 시작 (날짜 기반 시드, easy 난이도)
  void startDailyPuzzle() {
    _timer?.cancel();
    lastNewBadges = []; // 이전 배지 결과 초기화

    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    const difficulty = NonogramDifficulty.easy;

    final result = NonogramGenerator.generate(
      size: difficulty.gridSize,
      seed: seed,
      difficulty: difficulty.code,
    );

    if (result == null) return;

    state = NonogramState(
      puzzle: result.puzzle,
      solution: result.solution,
      current: result.puzzle.copyWith(),
      mode: NonogramGameMode.dailyPuzzle,
      difficulty: difficulty,
    );

    _startTimer();
    _autoSave();
  }

  /// 입력 모드 변경 (■ / ✕ / 지우개)
  void setInputMode(NonogramInputMode mode) {
    if (state == null) return;
    state = state!.copyWith(inputMode: mode);
  }

  /// 셀 탭 — 현재 입력 모드에 따라 동작
  void tapCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    final currentValue = state!.current.getValue(row, col);

    switch (state!.inputMode) {
      case NonogramInputMode.fill:
        // 이미 채움이면 지우기, 아니면 채움(1) 배치
        if (currentValue == 1) {
          _applyValue(row, col, currentValue, -1);
        } else {
          _applyValue(row, col, currentValue, 1);
        }
      case NonogramInputMode.cross:
        // 이미 크로스면 지우기, 아니면 크로스(0) 배치
        if (currentValue == 0) {
          _applyValue(row, col, currentValue, -1);
        } else {
          _applyValue(row, col, currentValue, 0);
        }
      case NonogramInputMode.erase:
        if (currentValue != -1) {
          _applyValue(row, col, currentValue, -1);
        }
    }
  }

  /// 셀 선택
  void selectCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    // 같은 셀 재탭 시 선택 해제
    if (state!.selectedCell == (row, col)) {
      state = state!.copyWith(clearSelectedCell: true);
      _clearHintState();
      return;
    }

    // 다른 셀 선택 시 힌트 상태 초기화
    final hintTarget = state!.hintTargetCell;
    if (hintTarget != null && (hintTarget.$1 != row || hintTarget.$2 != col)) {
      _clearHintState();
    }

    state = state!.copyWith(selectedCell: (row, col));
  }

  /// 값 적용 (undo 스택 포함)
  ///
  /// 정통 노노그램 방식: 실수 카운트 없음.
  /// 사용자가 자유롭게 채움/X를 표시하고 "확인" 버튼으로 검증한다.
  /// mistakeCount는 항상 0으로 유지되며, 필드는 백워드 호환을 위해 보존된다.
  void _applyValue(int row, int col, int previousValue, int newValue) {
    final newBoard = state!.current.setValue(row, col, newValue);
    // 햅틱: 셀 입력 가벼운 진동 (실수 햅틱 제거)
    HapticFeedback.selectionClick();
    SoundManager().play(SoundManager.kClick);

    // Undo 스택에 추가
    final actionType = newValue == -1
        ? NonogramUndoActionType.clearValue
        : NonogramUndoActionType.setValue;
    final undoAction = NonogramUndoAction(
      type: actionType,
      row: row,
      col: col,
      previousValue: previousValue,
    );
    final newStack = [...state!.undoStack, undoAction];

    state = state!.copyWith(
      current: newBoard,
      undoStack: newStack,
      selectedCell: (row, col),
    );

    // 완료 판정 (정답과 일치하면 자동 완료)
    _checkCompletion();
    _autoSave();
  }

  /// 사용자의 명시적 정답 확인.
  ///
  /// 정통 노노그램 스타일: 틀린 위치를 알려주지 않고 완성 여부만 응답한다.
  /// - 정답이면 _checkCompletion이 완료 처리하고 true를 반환한다.
  /// - 정답이 아니면 false를 반환한다 (UI에서 토스트 표시).
  bool verify() {
    if (state == null || state!.isCompleted) return false;

    if (NonogramSolver.isComplete(state!.current)) {
      // 자동 완료 판정과 동일한 흐름 (이미 완료 처리됐다면 멱등)
      _checkCompletion();
      return true;
    }
    return false;
  }

  /// 되돌리기
  void undo() {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    if (state!.undoStack.isEmpty) return;

    final lastAction = state!.undoStack.last;
    final newStack = state!.undoStack.sublist(0, state!.undoStack.length - 1);
    final newBoard = state!.current.setValue(
      lastAction.row,
      lastAction.col,
      lastAction.previousValue,
    );

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

    // 다음 힌트 레벨 결정
    var nextLevel = state!.currentHintLevel + 1;
    if (nextLevel > 4) nextLevel = 1; // 4단계 후 다시 1단계 (새 셀 대상)

    // 레벨 초과 시 새 셀로 리셋
    if (nextLevel == 1) {
      state = state!.copyWith(
        clearHintTarget: true,
        currentHintLevel: 0,
      );
    }

    final hint = NonogramHintEngine.getHint(
      state!.current,
      state!.solution,
      level: nextLevel,
    );

    if (hint == null) return; // 힌트 없음

    // 첫 힌트 요청 시 힌트 카운트 증가
    final newHintCount = nextLevel == 1
        ? state!.hintCount + 1
        : state!.hintCount;

    state = state!.copyWith(
      currentHintLevel: nextLevel,
      hintTargetCell: (hint.row, hint.col),
      lastHintResult: hint,
      hintCount: newHintCount,
      selectedCell: (hint.row, hint.col),
    );

    // Level 4: 정답 자동 입력
    if (nextLevel == 4 && hint.value != null) {
      final newBoard = state!.current.setValue(hint.row, hint.col, hint.value!);
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
    if (NonogramSolver.isComplete(state!.current)) {
      _timer?.cancel();
      state = state!.copyWith(isCompleted: true);
      _clearSave();
      // 햅틱: 게임 완료 시 강한 진동
      HapticFeedback.heavyImpact();
      SoundManager().play(SoundManager.kGameComplete);

      // 완료 기록 저장 및 배지 평가
      _saveCompletionAndEvaluateBadges();
    }
  }

  /// 완료 기록 저장 + 배지 평가
  void _saveCompletionAndEvaluateBadges() {
    if (state == null || _storageService == null) return;

    try {
      // CompletedGameRecord 생성
      final record = CompletedGameRecord(
        mode: state!.mode.name,
        difficulty: state!.difficulty.name,
        elapsedSeconds: state!.elapsedSeconds,
        mistakeCount: state!.mistakeCount,
        hintCount: state!.hintCount,
        grade: state!.grade.symbol,
        completedAt: DateTime.now(),
      );

      // 기록 저장
      _storageService!.saveCompletedGame(record);

      // 배지 평가
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
  NonogramState? _checkpoint;

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

/// Nonogram Provider (기본 — SharedPreferences 없이)
final nonogramProvider = StateNotifierProvider<NonogramNotifier, NonogramState?>((ref) {
  return NonogramNotifier();
});

/// SharedPreferences가 주입된 NonogramNotifier
/// (sharedPreferencesProvider를 직접 사용하여 별도 오버라이드 불필요)
final nonogramNotifierProvider = StateNotifierProvider<NonogramNotifier, NonogramState?>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NonogramNotifier(prefs: prefs);
  } catch (_) {
    // 테스트 등에서 sharedPreferencesProvider가 없으면 prefs 없이 생성
    return NonogramNotifier();
  }
});
