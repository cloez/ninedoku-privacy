import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';
import 'minesweeper_badge_service.dart';
import 'minesweeper_storage_service.dart';
import 'engine/minesweeper_board.dart';
import 'engine/minesweeper_generator.dart';
import 'engine/minesweeper_hint.dart';
import 'engine/minesweeper_solver.dart';
import 'minesweeper_state.dart';

import '../../shared/services/sound_manager.dart';
/// SharedPreferences 저장 키
const _storageKey = 'minesweeper_current_game';

/// Minesweeper 게임 상태 관리 Notifier
class MinesweeperNotifier extends StateNotifier<MinesweeperState?> with WidgetsBindingObserver {
  Timer? _timer;
  final SharedPreferences? _prefs;

  /// 완료 기록 저장 서비스
  MinesweeperStorageService? _storageService;

  /// 배지 평가 서비스
  MinesweeperBadgeService? _badgeService;

  /// 마지막으로 새로 획득한 배지 목록 (결과 화면 표시용)
  List<BadgeDefinition> lastNewBadges = [];

  MinesweeperNotifier({SharedPreferences? prefs})
      : _prefs = prefs,
        super(null) {
    if (prefs != null) {
      _storageService = MinesweeperStorageService(prefs);
      _badgeService = MinesweeperBadgeService(prefs);
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
      final saved = MinesweeperState.fromJson(json);
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
    required MinesweeperGameMode mode,
    required MinesweeperDifficulty difficulty,
  }) {
    _timer?.cancel();
    lastNewBadges = [];

    final seed = DateTime.now().millisecondsSinceEpoch;
    final result = MinesweeperGenerator.generate(
      size: difficulty.gridSize,
      mineCount: difficulty.mineCount,
      seed: seed,
    );

    if (result == null) return;

    state = MinesweeperState(
      puzzle: result.puzzle,
      solution: result.solution,
      current: result.puzzle.copyWith(),
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
    final seed = now.year * 10000 + now.month * 100 + now.day;
    const difficulty = MinesweeperDifficulty.medium;

    final result = MinesweeperGenerator.generate(
      size: difficulty.gridSize,
      mineCount: difficulty.mineCount,
      seed: seed,
    );

    if (result == null) return;

    state = MinesweeperState(
      puzzle: result.puzzle,
      solution: result.solution,
      current: result.puzzle.copyWith(),
      mode: MinesweeperGameMode.dailyPuzzle,
      difficulty: difficulty,
    );

    _startTimer();
    _autoSave();
  }

  /// 입력 모드 변경 (열기 / 깃발)
  void setInputMode(MinesweeperInputMode mode) {
    if (state == null) return;
    state = state!.copyWith(inputMode: mode);
  }

  /// 셀 탭 — 현재 입력 모드에 따라 동작
  void tapCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    switch (state!.inputMode) {
      case MinesweeperInputMode.reveal:
        _revealCell(row, col);
      case MinesweeperInputMode.flag:
        _toggleFlag(row, col);
    }
  }

  /// 셀 열기
  void _revealCell(int row, int col) {
    final cell = state!.current.getCell(row, col);
    if (cell.revealed || cell.flagged) return;

    // 햅틱: 셀 열기 가벼운 진동
    HapticFeedback.selectionClick();
    SoundManager().play(SoundManager.kClick);

    if (cell.isMine) {
      // 지뢰를 열었을 때 — 실수 처리
      // 햅틱: 지뢰 폭발 강한 진동
      HapticFeedback.heavyImpact();
      SoundManager().play(SoundManager.kMistake);
      final newBoard = state!.current.revealCell(row, col);
      state = state!.copyWith(
        current: newBoard,
        mistakeCount: state!.mistakeCount + 1,
        selectedCell: (row, col),
      );
      _autoSave();
      return;
    }

    // 안전한 셀 열기 (연쇄 오픈 포함)
    final newBoard = MinesweeperSolver.revealWithCascade(state!.current, row, col);

    state = state!.copyWith(
      current: newBoard,
      selectedCell: (row, col),
    );

    _checkCompletion();
    _autoSave();
  }

  /// 깃발 토글
  void _toggleFlag(int row, int col) {
    final cell = state!.current.getCell(row, col);
    if (cell.revealed) return;

    final newBoard = state!.current.toggleFlag(row, col);
    state = state!.copyWith(
      current: newBoard,
      selectedCell: (row, col),
    );

    _autoSave();
  }

  /// 더블탭 — 코드(Chord) 오픈
  /// 열린 숫자 셀을 더블탭하면, 주변 깃발 수가 숫자와 같을 때
  /// 나머지 닫힌 셀을 자동으로 연다 (PC 양쪽 클릭과 동일)
  void doubleTapCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;

    final cell = state!.current.getCell(row, col);
    // 열린 숫자 셀에서만 동작
    if (!cell.revealed || cell.adjacentMines == 0) return;

    final nbrs = state!.current.neighbors(row, col);
    int flagCount = 0;
    final closedUnflagged = <(int, int)>[];

    for (final (nr, nc) in nbrs) {
      final n = state!.current.getCell(nr, nc);
      if (!n.revealed && n.flagged) flagCount++;
      if (!n.revealed && !n.flagged) closedUnflagged.add((nr, nc));
    }

    // 깃발 수가 숫자와 같아야 코드 오픈 가능
    if (flagCount != cell.adjacentMines) return;
    if (closedUnflagged.isEmpty) return;

    var board = state!.current;
    var mistakes = state!.mistakeCount;

    for (final (nr, nc) in closedUnflagged) {
      final n = board.getCell(nr, nc);
      if (n.isMine) {
        // 잘못된 깃발로 인해 지뢰가 열림 → 실수
        board = board.revealCell(nr, nc);
        mistakes++;
      } else {
        board = MinesweeperSolver.revealWithCascade(board, nr, nc);
      }
    }

    state = state!.copyWith(
      current: board,
      mistakeCount: mistakes,
      selectedCell: (row, col),
    );

    _checkCompletion();
    _autoSave();
  }

  /// 길게 누르기 — 깃발 토글 (입력 모드 무관)
  void longPressCell(int row, int col) {
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    _toggleFlag(row, col);
  }

  /// 되돌리기 (지뢰찾기에서는 미지원 — 셀 열기는 취소 불가)
  void undo() {
    // 지뢰찾기는 셀 열기 되돌리기가 게임의 특성상 의미 없음
    // 깃발만 토글 되돌리기 지원
    if (state == null || state!.isCompleted || state!.isAutoCompleting) return;
    if (state!.undoStack.isEmpty) return;

    final lastAction = state!.undoStack.last;
    final newStack = state!.undoStack.sublist(0, state!.undoStack.length - 1);

    MinesweeperBoard newBoard;
    switch (lastAction.type) {
      case MinesweeperUndoActionType.flag:
        // 깃발 배치 되돌리기 → 깃발 제거
        newBoard = state!.current.toggleFlag(lastAction.row, lastAction.col);
      case MinesweeperUndoActionType.unflag:
        // 깃발 제거 되돌리기 → 깃발 복원
        newBoard = state!.current.toggleFlag(lastAction.row, lastAction.col);
      case MinesweeperUndoActionType.reveal:
        // 셀 열기는 되돌리기 불가 — 스킵
        newBoard = state!.current;
    }

    state = state!.copyWith(
      current: newBoard,
      undoStack: newStack,
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

    final hint = MinesweeperHintEngine.getHint(
      state!.current,
      state!.solution,
      level: nextLevel,
    );

    if (hint == null) return;

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

    // Level 4: 정답 자동 적용
    if (nextLevel == 4 && hint.action != null) {
      MinesweeperBoard newBoard;
      if (hint.action == HintAction.reveal) {
        newBoard = MinesweeperSolver.revealWithCascade(
          state!.current, hint.row, hint.col,
        );
      } else {
        newBoard = state!.current.toggleFlag(hint.row, hint.col);
      }
      state = state!.copyWith(current: newBoard);
      _checkCompletion();
    }

    _autoSave();
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
    if (state!.current.isWon) {
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
      // 저장/평가 실패 시 게임 완료에 영향 없음
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

  /// 진행 중인 게임 여부
  bool get hasOngoingGame => state != null && !state!.isCompleted;

  // === 체크포인트 (메모리 저장) ===
  MinesweeperState? _checkpoint;

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

/// Minesweeper Provider (기본 — 테스트용)
final minesweeperProvider = StateNotifierProvider<MinesweeperNotifier, MinesweeperState?>((ref) {
  return MinesweeperNotifier();
});

/// SharedPreferences가 주입된 MinesweeperNotifier
final minesweeperNotifierProvider = StateNotifierProvider<MinesweeperNotifier, MinesweeperState?>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return MinesweeperNotifier(prefs: prefs);
  } catch (_) {
    return MinesweeperNotifier();
  }
});
