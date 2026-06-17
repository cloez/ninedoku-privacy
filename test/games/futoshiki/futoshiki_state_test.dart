import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/futoshiki/engine/futoshiki_board.dart';
import 'package:ninedoku/games/futoshiki/futoshiki_state.dart';
import 'package:ninedoku/games/futoshiki/futoshiki_notifier.dart';

void main() {
  // Notifier 테스트에 필요한 WidgetsBinding 초기화
  TestWidgetsFlutterBinding.ensureInitialized();
  // 테스트용 간단한 4x4 보드
  late FutoshikiBoard solution;
  late FutoshikiBoard puzzle;

  setUp(() {
    solution = FutoshikiBoard(
      size: 4,
      cells: [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
      horizontalConstraints: List.filled(12, 0),
      verticalConstraints: List.filled(12, 0),
      fixed: {},
    );
    puzzle = FutoshikiBoard(
      size: 4,
      cells: [0, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
      horizontalConstraints: List.filled(12, 0),
      verticalConstraints: List.filled(12, 0),
      fixed: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
    );
  });

  group('FutoshikiState', () {
    test('초기 상태 생성', () {
      final state = FutoshikiState(
        puzzle: puzzle,
        solution: solution,
        current: puzzle.copyWith(),
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
      );

      expect(state.size, 4);
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.selectedCell, isNull);
      expect(state.isNoteMode, false);
    });

    test('copyWith', () {
      final state = FutoshikiState(
        puzzle: puzzle,
        solution: solution,
        current: puzzle.copyWith(),
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
      );

      final updated = state.copyWith(
        elapsedSeconds: 10,
        mistakeCount: 1,
        isPaused: true,
      );

      expect(updated.elapsedSeconds, 10);
      expect(updated.mistakeCount, 1);
      expect(updated.isPaused, true);
      expect(updated.mode, FutoshikiGameMode.classic);
    });

    test('copyWith — 셀 선택 해제', () {
      final state = FutoshikiState(
        puzzle: puzzle,
        solution: solution,
        current: puzzle.copyWith(),
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
        selectedCell: (1, 2),
      );

      final cleared = state.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, isNull);
    });

    test('JSON 직렬화/역직렬화', () {
      final state = FutoshikiState(
        puzzle: puzzle,
        solution: solution,
        current: puzzle.copyWith(),
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
        elapsedSeconds: 42,
        mistakeCount: 2,
        hintCount: 1,
        selectedCell: (0, 0),
        isNoteMode: true,
      );

      final json = state.toJson();
      final restored = FutoshikiState.fromJson(json);

      expect(restored.mode, FutoshikiGameMode.classic);
      expect(restored.difficulty, FutoshikiDifficulty.beginner);
      expect(restored.elapsedSeconds, 42);
      expect(restored.mistakeCount, 2);
      expect(restored.hintCount, 1);
      expect(restored.selectedCell, (0, 0));
      expect(restored.isNoteMode, true);
    });

    test('등급 — 퍼펙트 (노미스 노힌트)', () {
      final grade = FutoshikiGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 30,
        difficulty: FutoshikiDifficulty.beginner,
      );
      expect(grade, FutoshikiGrade.perfect);
    });

    test('등급 — 실수 많으면 C', () {
      final grade = FutoshikiGrade.evaluate(
        mistakes: 5,
        hints: 0,
      );
      expect(grade, FutoshikiGrade.good);
    });

    test('등급 — 적당한 실수면 B', () {
      final grade = FutoshikiGrade.evaluate(
        mistakes: 2,
        hints: 0,
      );
      expect(grade, FutoshikiGrade.great);
    });

    test('등급 — 약간의 실수면 A', () {
      final grade = FutoshikiGrade.evaluate(
        mistakes: 1,
        hints: 0,
      );
      expect(grade, FutoshikiGrade.excellent);
    });
  });

  group('FutoshikiDifficulty', () {
    test('격자 크기 확인', () {
      expect(FutoshikiDifficulty.beginner.gridSize, 4);
      expect(FutoshikiDifficulty.easy.gridSize, 5);
      expect(FutoshikiDifficulty.medium.gridSize, 6);
      expect(FutoshikiDifficulty.hard.gridSize, 7);
      expect(FutoshikiDifficulty.master.gridSize, 9);
    });

    test('코드 확인', () {
      expect(FutoshikiDifficulty.beginner.code, 0);
      expect(FutoshikiDifficulty.easy.code, 1);
      expect(FutoshikiDifficulty.medium.code, 2);
      expect(FutoshikiDifficulty.hard.code, 3);
      expect(FutoshikiDifficulty.master.code, 4);
    });

    test('기준 시간 확인', () {
      expect(FutoshikiGrade.baseTimeForDifficulty(FutoshikiDifficulty.beginner), 60);
      expect(FutoshikiGrade.baseTimeForDifficulty(FutoshikiDifficulty.easy), 120);
      expect(FutoshikiGrade.baseTimeForDifficulty(FutoshikiDifficulty.medium), 300);
      expect(FutoshikiGrade.baseTimeForDifficulty(FutoshikiDifficulty.hard), 600);
      expect(FutoshikiGrade.baseTimeForDifficulty(FutoshikiDifficulty.master), 1200);
    });
  });

  group('FutoshikiNotifier', () {
    test('초기 상태 null', () {
      final notifier = FutoshikiNotifier();
      expect(notifier.state, isNull);
      expect(notifier.hasOngoingGame, false);
      notifier.dispose();
    });

    test('새 게임 시작', () {
      final notifier = FutoshikiNotifier();
      notifier.startNewGame(
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
      );
      expect(notifier.state, isNotNull);
      expect(notifier.state!.size, 4);
      expect(notifier.state!.mode, FutoshikiGameMode.classic);
      expect(notifier.state!.difficulty, FutoshikiDifficulty.beginner);
      expect(notifier.hasOngoingGame, true);
      notifier.dispose();
    });

    test('포기', () {
      final notifier = FutoshikiNotifier();
      notifier.startNewGame(
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
      );
      expect(notifier.state, isNotNull);

      notifier.giveUp();
      expect(notifier.state, isNull);
      notifier.dispose();
    });

    test('셀 선택', () {
      final notifier = FutoshikiNotifier();
      notifier.startNewGame(
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
      );

      notifier.selectCell(1, 1);
      expect(notifier.state!.selectedCell, (1, 1));

      // 같은 셀 재탭 시 선택 해제
      notifier.selectCell(1, 1);
      expect(notifier.state!.selectedCell, isNull);

      notifier.dispose();
    });

    test('메모 모드 토글', () {
      final notifier = FutoshikiNotifier();
      notifier.startNewGame(
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
      );

      expect(notifier.state!.isNoteMode, false);
      notifier.toggleNoteMode();
      expect(notifier.state!.isNoteMode, true);
      notifier.toggleNoteMode();
      expect(notifier.state!.isNoteMode, false);

      notifier.dispose();
    });

    test('일시정지 및 재개', () {
      final notifier = FutoshikiNotifier();
      notifier.startNewGame(
        mode: FutoshikiGameMode.classic,
        difficulty: FutoshikiDifficulty.beginner,
      );

      notifier.pause();
      expect(notifier.state!.isPaused, true);

      notifier.resume();
      expect(notifier.state!.isPaused, false);

      notifier.dispose();
    });
  });
}
