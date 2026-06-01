import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';
import 'binairo_badge_service.dart';
import 'binairo_storage_service.dart';
import 'engine/binairo_generator.dart';
import 'engine/binairo_hint.dart';
import 'engine/binairo_solver.dart';
import 'binairo_state.dart';

/// SharedPreferences 저장 키
const _storageKey = 'binairo_current_game';

/// Binairo 게임 상태 관리 Notifier
class BinairoNotifier extends StateNotifier<BinairoState?> with WidgetsBindingObserver {
  Timer? _timer;
  final SharedPreferences? _prefs;

  /// 완료 기록 저장 서비스
  BinairoStorageService? _storageService;

  /// 배지 평가 서비스
  BinairoBadgeService? _badgeService;

  /// 마지막으로 새로 획득한 배지 목록 (결과 화면 표시용)
  List<BadgeDefinition> lastNewBadges = [];

  BinairoNotifier({SharedPreferences? prefs})
      : _prefs = prefs,
        super(null) {
    // SharedPreferences가 있으면 서비스 초기화
    if (prefs != null) {
      _storageService = BinairoStorageService(prefs);
      _badgeService = BinairoBadgeService(prefs);
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
      final saved = BinairoState.fromJson(json);
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
    required BinairoGameMode mode,
    required BinairoDifficulty difficulty,
  }) {
    _timer?.cancel();
    lastNewBadges = []; // 이전 배지 결과 초기화

    final seed = DateTime.now().millisecondsSinceEpoch;
    final result = BinairoGenerator.generate(
      size: difficulty.gridSize,
      difficulty: difficulty.code,
      seed: seed,
    );

    if (result == null) return; // 생성 실패

    state = BinairoState(
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
    lastNewBadges = []; // 이전 배지 결과 초기화

    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    // 데일리 퍼즐은 보통 난이도 (10x10)
    const difficulty = BinairoDifficulty.medium;

    final result = BinairoGenerator.generate(
      size: difficulty.gridSize,
      difficulty: difficulty.code,
      seed: seed,
    );

    if (result == null) return;

    state = BinairoState(
      puzzle: result.puzzle,
      solution: result.solution,
      current: result.puzzle.copyWith(),
      mode: BinairoGameMode.dailyPuzzle,
      difficulty: difficulty,
    );

    _startTimer();
    _autoSave();
  }

  /// 입력 모드 변경 (● / ○ / 지우개)
  void setInputMode(BinairoInputMode mode) {
    if (state == null) return;
    state = state!.copyWith(inputMode: mode);
  }

  /// 셀 탭 — 현재 입력 모드에 따라 동작
  void tapCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    final idx = row * state!.size + col;
    if (state!.current.fixed.contains(idx)) return;

    final currentValue = state!.current.getValue(row, col);

    switch (state!.inputMode) {
      case BinairoInputMode.black:
        // 이미 검은 원이면 지우기, 아니면 검은 원 배치
        if (currentValue == 0) {
          _applyValue(row, col, currentValue, -1);
        } else {
          _applyValue(row, col, currentValue, 0);
        }
      case BinairoInputMode.white:
        // 이미 흰 원이면 지우기, 아니면 흰 원 배치
        if (currentValue == 1) {
          _applyValue(row, col, currentValue, -1);
        } else {
          _applyValue(row, col, currentValue, 1);
        }
      case BinairoInputMode.erase:
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

  /// 셀 토글: 빈칸→0→1→빈칸 순환
  void toggleCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    final idx = row * state!.size + col;
    // 고정 셀은 변경 불가
    if (state!.current.fixed.contains(idx)) return;

    final currentValue = state!.current.getValue(row, col);
    int newValue;
    // 빈칸(-1) → 0 → 1 → 빈칸(-1) 순환
    switch (currentValue) {
      case -1:
        newValue = 0;
      case 0:
        newValue = 1;
      case 1:
        newValue = -1;
      default:
        newValue = -1;
    }

    _applyValue(row, col, currentValue, newValue);
  }

  /// 셀에 직접 값 설정
  void setCell(int row, int col, int value) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    final idx = row * state!.size + col;
    if (state!.current.fixed.contains(idx)) return;

    final currentValue = state!.current.getValue(row, col);
    if (currentValue == value) return; // 같은 값이면 무시

    _applyValue(row, col, currentValue, value);
  }

  /// 선택된 셀 지우기
  void clearCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    final idx = row * state!.size + col;
    if (state!.current.fixed.contains(idx)) return;

    final currentValue = state!.current.getValue(row, col);
    if (currentValue == -1) return; // 이미 빈칸

    _applyValue(row, col, currentValue, -1);
  }

  /// 값 적용 (undo 스택 포함)
  void _applyValue(int row, int col, int previousValue, int newValue) {
    final newBoard = state!.current.setValue(row, col, newValue);

    // 실수 판정: 값을 넣었는데 정답과 다르면 실수
    var newMistakeCount = state!.mistakeCount;
    if (newValue != -1) {
      final correctValue = state!.solution.getValue(row, col);
      if (newValue != correctValue) {
        newMistakeCount++;
      }
    }

    // Undo 스택에 추가
    final actionType = newValue == -1
        ? BinairoUndoActionType.clearValue
        : BinairoUndoActionType.setValue;
    final undoAction = BinairoUndoAction(
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
      selectedCell: (row, col),
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

    final hint = BinairoHintEngine.getHint(
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
    if (BinairoSolver.isComplete(state!.current)) {
      _timer?.cancel();
      state = state!.copyWith(isCompleted: true);
      _clearSave();

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
}

/// Binairo Provider
final binairoProvider = StateNotifierProvider<BinairoNotifier, BinairoState?>((ref) {
  // SharedPreferences는 비동기이므로 동기 접근을 위한 override 필요
  // 실제 앱에서는 ProviderScope에서 override 해야 함
  return BinairoNotifier();
});

/// SharedPreferences가 주입된 BinairoNotifier
/// (sharedPreferencesProvider를 직접 사용하여 별도 오버라이드 불필요)
final binairoNotifierProvider = StateNotifierProvider<BinairoNotifier, BinairoState?>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return BinairoNotifier(prefs: prefs);
  } catch (_) {
    // 테스트 등에서 sharedPreferencesProvider가 없으면 prefs 없이 생성
    return BinairoNotifier();
  }
});
