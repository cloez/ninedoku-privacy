import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/minesweeper/engine/minesweeper_board.dart';
import 'package:ninedoku/games/minesweeper/minesweeper_state.dart';

void main() {
  late MinesweeperState state;

  setUp(() {
    final board = MinesweeperBoard.empty(8, 8);
    state = MinesweeperState(
      puzzle: board,
      solution: board,
      current: board,
      mode: MinesweeperGameMode.classic,
      difficulty: MinesweeperDifficulty.beginner,
    );
  });

  group('B. MinesweeperState 상태 모델', () {
    test('기본값 초기화', () {
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.inputMode, MinesweeperInputMode.reveal);
      expect(state.undoStack, isEmpty);
      expect(state.selectedCell, isNull);
    });

    test('copyWith 동작', () {
      final updated = state.copyWith(
        elapsedSeconds: 60,
        mistakeCount: 2,
        isPaused: true,
        inputMode: MinesweeperInputMode.flag,
      );
      expect(updated.elapsedSeconds, 60);
      expect(updated.mistakeCount, 2);
      expect(updated.isPaused, true);
      expect(updated.inputMode, MinesweeperInputMode.flag);
      // 원본 불변
      expect(state.elapsedSeconds, 0);
    });

    test('copyWith — clearSelectedCell', () {
      final s1 = state.copyWith(selectedCell: (1, 2));
      expect(s1.selectedCell, (1, 2));
      final s2 = s1.copyWith(clearSelectedCell: true);
      expect(s2.selectedCell, isNull);
    });

    test('copyWith — clearHintTarget', () {
      final s1 = state.copyWith(hintTargetCell: (3, 4));
      final s2 = s1.copyWith(clearHintTarget: true);
      expect(s2.hintTargetCell, isNull);
    });

    test('toJson / fromJson 라운드트립', () {
      final updated = state.copyWith(
        elapsedSeconds: 120,
        mistakeCount: 1,
        hintCount: 2,
        isPaused: true,
        selectedCell: (3, 4),
        inputMode: MinesweeperInputMode.flag,
      );
      final json = updated.toJson();
      final restored = MinesweeperState.fromJson(json);
      expect(restored.elapsedSeconds, 120);
      expect(restored.mistakeCount, 1);
      expect(restored.hintCount, 2);
      expect(restored.isPaused, true);
      expect(restored.selectedCell, (3, 4));
      expect(restored.inputMode, MinesweeperInputMode.flag);
    });

    test('GameMode enum JSON 왕복', () {
      for (final mode in MinesweeperGameMode.values) {
        final s = state.copyWith(mode: mode);
        final json = s.toJson();
        final restored = MinesweeperState.fromJson(json);
        expect(restored.mode, mode);
      }
    });

    test('Difficulty enum JSON 왕복', () {
      for (final diff in MinesweeperDifficulty.values) {
        expect(diff.gridSize, greaterThan(0));
        expect(diff.mineCount, greaterThan(0));
        expect(diff.code, diff.index);
      }
    });

    test('InputMode enum JSON 왕복', () {
      for (final mode in MinesweeperInputMode.values) {
        final s = state.copyWith(inputMode: mode);
        final json = s.toJson();
        final restored = MinesweeperState.fromJson(json);
        expect(restored.inputMode, mode);
      }
    });

    test('등급 산정 — S등급 (노미스, 노힌트, 기준시간 이내)', () {
      final s = state.copyWith(
        elapsedSeconds: 30, // 입문 기준 60초 이내
        mistakeCount: 0,
        hintCount: 0,
      );
      expect(s.grade, MinesweeperGrade.perfect);
    });

    test('등급 산정 — C등급 (실수 많음)', () {
      final s = state.copyWith(mistakeCount: 5, hintCount: 5);
      expect(s.grade, MinesweeperGrade.good);
    });

    test('등급 산정 — B등급', () {
      final s = state.copyWith(mistakeCount: 2, hintCount: 2);
      expect(s.grade, MinesweeperGrade.great);
    });

    test('remainingMines 계산', () {
      expect(state.remainingMines, 8); // 8지뢰, 깃발 0
    });

    test('난이도별 기준시간', () {
      expect(MinesweeperGrade.baseTimeForDifficulty(MinesweeperDifficulty.beginner), 60);
      expect(MinesweeperGrade.baseTimeForDifficulty(MinesweeperDifficulty.master), 1200);
    });
  });
}
