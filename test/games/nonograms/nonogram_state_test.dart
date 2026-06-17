import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/nonograms/engine/nonogram_board.dart';
import 'package:ninedoku/games/nonograms/nonogram_state.dart';

void main() {
  late NonogramState state;

  setUp(() {
    final board = NonogramBoard.empty(
      rows: 5, cols: 5,
      rowHints: List.generate(5, (_) => [0]),
      colHints: List.generate(5, (_) => [0]),
    );
    state = NonogramState(
      puzzle: board, solution: board, current: board,
      mode: NonogramGameMode.classic, difficulty: NonogramDifficulty.beginner,
    );
  });

  group('B. NonogramState', () {
    test('기본값', () {
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.inputMode, NonogramInputMode.fill);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
    });

    test('copyWith', () {
      final u = state.copyWith(elapsedSeconds: 60, isPaused: true);
      expect(u.elapsedSeconds, 60);
      expect(u.isPaused, true);
      expect(state.elapsedSeconds, 0);
    });

    test('clearSelectedCell', () {
      final s1 = state.copyWith(selectedCell: (1, 2));
      final s2 = s1.copyWith(clearSelectedCell: true);
      expect(s2.selectedCell, isNull);
    });

    test('toJson / fromJson', () {
      final u = state.copyWith(
        elapsedSeconds: 120, mistakeCount: 1,
        selectedCell: (2, 3), inputMode: NonogramInputMode.cross,
      );
      final restored = NonogramState.fromJson(u.toJson());
      expect(restored.elapsedSeconds, 120);
      expect(restored.selectedCell, (2, 3));
      expect(restored.inputMode, NonogramInputMode.cross);
    });

    test('GameMode JSON 왕복', () {
      for (final m in NonogramGameMode.values) {
        final s = state.copyWith(mode: m);
        expect(NonogramState.fromJson(s.toJson()).mode, m);
      }
    });

    test('Difficulty enum', () {
      for (final d in NonogramDifficulty.values) {
        expect(d.gridSize, greaterThan(0));
        expect(d.code, d.index);
      }
    });

    test('InputMode JSON 왕복', () {
      for (final m in NonogramInputMode.values) {
        final s = state.copyWith(inputMode: m);
        expect(NonogramState.fromJson(s.toJson()).inputMode, m);
      }
    });

    test('등급 S', () {
      final s = state.copyWith(elapsedSeconds: 30, mistakeCount: 0, hintCount: 0);
      expect(s.grade, NonogramGrade.perfect);
    });

    test('등급 C', () {
      final s = state.copyWith(mistakeCount: 5, hintCount: 5);
      expect(s.grade, NonogramGrade.good);
    });

    test('등급 B', () {
      final s = state.copyWith(mistakeCount: 2, hintCount: 2);
      expect(s.grade, NonogramGrade.great);
    });

    test('기준시간', () {
      expect(NonogramGrade.baseTimeForDifficulty(NonogramDifficulty.beginner), 120);
      expect(NonogramGrade.baseTimeForDifficulty(NonogramDifficulty.hard), 1800);
    });

    test('실수가 등급에 영향 없음 (정통 노노그램)', () {
      // 정통 노노그램은 실수 카운트 없음 → 같은 힌트/시간이면 등급 동일
      final s1 = state.copyWith(
        mistakeCount: 0, hintCount: 0, elapsedSeconds: 30,
      );
      final s2 = state.copyWith(
        mistakeCount: 100, hintCount: 0, elapsedSeconds: 30,
      );
      expect(s1.grade, s2.grade);
      expect(s1.grade, NonogramGrade.perfect);
    });

    test('힌트 0 + 기준시간 초과 → A 등급', () {
      // beginner 기준시간 120초 초과 → excellent
      final s = state.copyWith(
        mistakeCount: 0, hintCount: 0, elapsedSeconds: 200,
      );
      expect(s.grade, NonogramGrade.excellent);
    });

    test('힌트 1회 → A 등급', () {
      final s = state.copyWith(mistakeCount: 0, hintCount: 1, elapsedSeconds: 30);
      expect(s.grade, NonogramGrade.excellent);
    });

    test('힌트 4회 → C 등급', () {
      final s = state.copyWith(mistakeCount: 0, hintCount: 4, elapsedSeconds: 30);
      expect(s.grade, NonogramGrade.good);
    });

    test('board size', () {
      expect(state.current.rows, 5);
      expect(state.current.cols, 5);
    });
  });
}
