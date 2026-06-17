import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/nonograms/engine/nonogram_board.dart';
import 'package:ninedoku/games/nonograms/engine/nonogram_generator.dart';
import 'package:ninedoku/games/nonograms/engine/nonogram_hint.dart';
import 'package:ninedoku/games/nonograms/engine/nonogram_solver.dart';

void main() {
  // ===== A1. 보드 모델 (7개) =====
  group('A1. NonogramBoard', () {
    test('빈 보드 생성', () {
      final board = NonogramBoard.empty(
        rows: 5, cols: 5,
        rowHints: List.generate(5, (_) => [0]),
        colHints: List.generate(5, (_) => [0]),
      );
      expect(board.rows, 5);
      expect(board.cols, 5);
      expect(board.undecidedCount, 25);
    });

    test('getValue / setValue', () {
      var board = NonogramBoard.empty(
        rows: 3, cols: 3,
        rowHints: [[1], [0], [0]], colHints: [[1], [0], [0]],
      );
      board = board.setValue(0, 0, 1);
      expect(board.getValue(0, 0), 1);
      expect(board.getValue(1, 1), -1);
    });

    test('toJson / fromJson 라운드트립', () {
      var board = NonogramBoard.empty(
        rows: 3, cols: 3,
        rowHints: [[1, 1], [3], [1]], colHints: [[2], [1], [2]],
      );
      board = board.setValue(0, 0, 1);
      board = board.setValue(1, 1, 0);

      final json = board.toJson();
      final restored = NonogramBoard.fromJson(json);
      expect(restored.rows, 3);
      expect(restored.getValue(0, 0), 1);
      expect(restored.getValue(1, 1), 0);
      expect(restored.rowHints[0], [1, 1]);
    });

    test('getRow / getCol', () {
      final board = NonogramBoard(
        rows: 2, cols: 3,
        rowHints: [[1], [2]], colHints: [[1], [1], [1]],
        cells: [1, 0, -1, 1, 1, 0],
      );
      expect(board.getRow(0), [1, 0, -1]);
      expect(board.getCol(0), [1, 1]);
    });

    test('filledCount / undecidedCount', () {
      final board = NonogramBoard(
        rows: 2, cols: 2,
        rowHints: [[1], [1]], colHints: [[1], [1]],
        cells: [1, 0, -1, 1],
      );
      expect(board.filledCount, 2);
      expect(board.undecidedCount, 1);
    });

    test('isComplete', () {
      final board = NonogramBoard(
        rows: 2, cols: 2,
        rowHints: [[1], [1]], colHints: [[1], [1]],
        cells: [1, 0, 0, 1],
      );
      expect(board.isComplete, true);
    });

    test('범위 초과 에러', () {
      final board = NonogramBoard.empty(
        rows: 3, cols: 3,
        rowHints: [[0], [0], [0]], colHints: [[0], [0], [0]],
      );
      expect(() => board.getValue(-1, 0), throwsA(isA<RangeError>()));
      expect(() => board.getValue(3, 0), throwsA(isA<RangeError>()));
    });
  });

  // ===== A2. 솔버 (8개) =====
  group('A2. NonogramSolver', () {
    test('빈 힌트 보드 풀이 (전부 0)', () {
      final board = NonogramBoard.empty(
        rows: 3, cols: 3,
        rowHints: [[0], [0], [0]], colHints: [[0], [0], [0]],
      );
      final result = NonogramSolver.solve(board);
      expect(result, isNotNull);
      expect(result!.filledCount, 0);
    });

    test('전부 채움 보드 풀이', () {
      final board = NonogramBoard.empty(
        rows: 2, cols: 2,
        rowHints: [[2], [2]], colHints: [[2], [2]],
      );
      final result = NonogramSolver.solve(board);
      expect(result, isNotNull);
      expect(result!.filledCount, 4);
    });

    test('간단한 3×3 풀이', () {
      // L자 패턴: [1,0,0], [1,0,0], [1,1,1]
      final board = NonogramBoard.empty(
        rows: 3, cols: 3,
        rowHints: [[1], [1], [3]],
        colHints: [[3], [1], [1]],
      );
      final result = NonogramSolver.solve(board);
      expect(result, isNotNull);
      expect(NonogramSolver.isComplete(result!), true);
    });

    test('isComplete — 유효한 보드', () {
      final board = NonogramBoard(
        rows: 2, cols: 2,
        rowHints: [[1], [1]], colHints: [[1], [1]],
        cells: [1, 0, 0, 1],
      );
      expect(NonogramSolver.isComplete(board), true);
    });

    test('isComplete — 힌트 불일치', () {
      final board = NonogramBoard(
        rows: 2, cols: 2,
        rowHints: [[2], [0]], colHints: [[1], [1]],
        cells: [1, 0, 0, 1], // 행0 힌트[2]인데 실제 [1]
      );
      expect(NonogramSolver.isComplete(board), false);
    });

    test('isRowSatisfied', () {
      final board = NonogramBoard(
        rows: 2, cols: 3,
        rowHints: [[2], [1]], colHints: [[1], [1], [1]],
        cells: [1, 1, 0, 0, 1, 0],
      );
      expect(NonogramSolver.isRowSatisfied(board, 0), true);
      expect(NonogramSolver.isRowSatisfied(board, 1), true);
    });

    test('solve 원본 불변', () {
      final board = NonogramBoard.empty(
        rows: 3, cols: 3,
        rowHints: [[1], [1], [1]], colHints: [[1], [1], [1]],
      );
      NonogramSolver.solve(board);
      expect(board.undecidedCount, 9);
    });

    test('모순 보드 → null', () {
      // 행0=[2], 행1=[0] 이지만 열0=[0], 열1=[0] → 모순
      final board = NonogramBoard.empty(
        rows: 2, cols: 2,
        rowHints: [[2], [0]], colHints: [[0], [0]],
      );
      final result = NonogramSolver.solve(board);
      expect(result, isNull);
    });
  });

  // ===== A3. 생성기 (6개) =====
  group('A3. NonogramGenerator', () {
    test('5×5 생성 성공', () {
      final result = NonogramGenerator.generate(size: 5, seed: 42);
      expect(result, isNotNull);
      expect(result!.puzzle.rows, 5);
    });

    test('같은 시드 → 같은 퍼즐', () {
      final r1 = NonogramGenerator.generate(size: 5, seed: 42);
      final r2 = NonogramGenerator.generate(size: 5, seed: 42);
      if (r1 != null && r2 != null) {
        expect(r1.solution.cells, r2.solution.cells);
      }
    });

    test('다른 시드 → 다른 퍼즐', () {
      final r1 = NonogramGenerator.generate(size: 5, seed: 42);
      final r2 = NonogramGenerator.generate(size: 5, seed: 43);
      if (r1 != null && r2 != null) {
        expect(r1.solution.cells.toString() == r2.solution.cells.toString(), false);
      }
    });

    test('생성 시간 3초 이내', () {
      final sw = Stopwatch()..start();
      NonogramGenerator.generate(size: 5, seed: 999);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });

    test('생성된 솔루션이 유효', () {
      final result = NonogramGenerator.generate(size: 5, seed: 42);
      if (result != null) {
        expect(NonogramSolver.isComplete(result.solution), true);
      }
    });

    test('난이도 크기 매핑', () {
      expect(NonogramGenerator.sizeForDifficulty(0), 5);
      expect(NonogramGenerator.sizeForDifficulty(3), 20);
    });
  });

  // ===== A4. 힌트 (5개) =====
  group('A4. NonogramHintEngine', () {
    NonogramGeneratorResult? genResult;

    setUpAll(() {
      genResult = NonogramGenerator.generate(size: 5, seed: 42);
    });

    test('Level 1 — 위치', () {
      if (genResult == null) return;
      final hint = NonogramHintEngine.getHint(genResult!.puzzle, genResult!.solution, level: 1);
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      expect(hint.message.contains('행'), true);
    });

    test('Level 2 — 힌트 설명', () {
      if (genResult == null) return;
      final hint = NonogramHintEngine.getHint(genResult!.puzzle, genResult!.solution, level: 2);
      expect(hint, isNotNull);
      expect(hint!.level, 2);
      expect(hint.message.contains('힌트'), true);
    });

    test('Level 3 — 상세', () {
      if (genResult == null) return;
      final hint = NonogramHintEngine.getHint(genResult!.puzzle, genResult!.solution, level: 3);
      expect(hint, isNotNull);
      expect(hint!.message.isNotEmpty, true);
    });

    test('Level 4 — 정답', () {
      if (genResult == null) return;
      final hint = NonogramHintEngine.getHint(genResult!.puzzle, genResult!.solution, level: 4);
      expect(hint, isNotNull);
      expect(hint!.value, isNotNull);
    });

    test('힌트 값이 솔루션과 일치', () {
      if (genResult == null) return;
      final hint = NonogramHintEngine.getHint(genResult!.puzzle, genResult!.solution, level: 4);
      if (hint == null) return;
      expect(hint.value, genResult!.solution.getValue(hint.row, hint.col));
    });
  });

  // ===== A5. 통합 (4개) =====
  group('A5. 통합', () {
    test('생성 → 풀이 → 완료', () {
      final result = NonogramGenerator.generate(size: 5, seed: 42);
      if (result == null) return;
      final solved = NonogramSolver.solve(result.puzzle);
      expect(solved, isNotNull);
      expect(NonogramSolver.isComplete(solved!), true);
    });

    test('직렬화 후 풀이', () {
      final result = NonogramGenerator.generate(size: 5, seed: 42);
      if (result == null) return;
      final json = result.puzzle.toJson();
      final restored = NonogramBoard.fromJson(json);
      final solved = NonogramSolver.solve(restored);
      expect(solved, isNotNull);
    });

    test('빈 보드 힌트 → 정상', () {
      final result = NonogramGenerator.generate(size: 5, seed: 42);
      if (result == null) return;
      final hint = NonogramHintEngine.getHint(result.puzzle, result.solution, level: 1);
      expect(hint, isNotNull);
    });

    test('copyWith 불변성', () {
      final result = NonogramGenerator.generate(size: 5, seed: 42);
      if (result == null) return;
      final copy = result.puzzle.copyWith();
      final modified = copy.setValue(0, 0, 1);
      expect(result.puzzle.getValue(0, 0), -1); // 원본 불변
      expect(modified.getValue(0, 0), 1);
    });

    test('countSolutions — 생성된 퍼즐은 유일해', () {
      final result = NonogramGenerator.generate(size: 5, seed: 42);
      if (result == null) return;
      final count = NonogramSolver.countSolutions(result.puzzle, maxCount: 2);
      expect(count, 1, reason: '생성된 퍼즐은 유일해를 가져야 한다');
    });
  });
}
