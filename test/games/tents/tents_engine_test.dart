import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/tents/engine/tents_board.dart';
import 'package:ninedoku/games/tents/engine/tents_solver.dart';
import 'package:ninedoku/games/tents/engine/tents_generator.dart';
import 'package:ninedoku/games/tents/engine/tents_hint.dart';

void main() {
  group('TentsBoard', () {
    test('빈 보드 생성', () {
      final board = TentsBoard.blank(6);
      expect(board.size, 6);
      expect(board.totalCells, 36);
      expect(board.emptyCellCount, 36);
      expect(board.filledCellCount, 0);
      expect(board.isComplete, false);
    });

    test('셀 값 설정 및 조회', () {
      var board = TentsBoard.blank(6);
      board = board.setValue(0, 0, TentsBoard.tent);
      expect(board.getValue(0, 0), TentsBoard.tent);
    });

    test('나무 셀은 변경 불가', () {
      final cells = List<int>.filled(36, TentsBoard.empty);
      cells[0] = TentsBoard.tree;
      final board = TentsBoard(
        size: 6,
        cells: cells,
        rowCounts: List.filled(6, 0),
        colCounts: List.filled(6, 0),
        treePositions: {0},
      );
      final modified = board.setValue(0, 0, TentsBoard.tent);
      expect(modified.getValue(0, 0), TentsBoard.tree);
    });

    test('행/열 텐트 수 카운트', () {
      final cells = List<int>.filled(36, TentsBoard.empty);
      cells[0] = TentsBoard.tent; // (0,0)
      cells[5] = TentsBoard.tent; // (0,5)
      cells[6] = TentsBoard.tent; // (1,0)
      final board = TentsBoard(
        size: 6,
        cells: cells,
        rowCounts: List.filled(6, 0),
        colCounts: List.filled(6, 0),
        treePositions: {},
      );
      expect(board.currentRowTents(0), 2);
      expect(board.currentRowTents(1), 1);
      expect(board.currentColTents(0), 2);
      expect(board.currentColTents(5), 1);
    });

    test('playableCells 계산', () {
      final cells = List<int>.filled(36, TentsBoard.empty);
      cells[0] = TentsBoard.tree;
      cells[7] = TentsBoard.tree;
      final board = TentsBoard(
        size: 6,
        cells: cells,
        rowCounts: List.filled(6, 0),
        colCounts: List.filled(6, 0),
        treePositions: {0, 7},
      );
      expect(board.playableCells, 34);
    });

    test('JSON 직렬화/역직렬화', () {
      final cells = List<int>.filled(36, TentsBoard.empty);
      cells[0] = TentsBoard.tree;
      cells[1] = TentsBoard.tent;
      cells[2] = TentsBoard.grass;
      final rowCounts = [1, 0, 1, 0, 0, 0];
      final colCounts = [0, 1, 0, 0, 0, 1];
      final board = TentsBoard(
        size: 6,
        cells: cells,
        rowCounts: rowCounts,
        colCounts: colCounts,
        treePositions: {0},
      );

      final json = board.toJson();
      final restored = TentsBoard.fromJson(json);
      expect(restored.size, 6);
      expect(restored.getValue(0, 0), TentsBoard.tree);
      expect(restored.getValue(0, 1), TentsBoard.tent);
      expect(restored.getValue(0, 2), TentsBoard.grass);
      expect(restored.rowCounts, rowCounts);
      expect(restored.colCounts, colCounts);
      expect(restored.treePositions, {0});
    });

    test('copyWith 깊은 복사', () {
      final board = TentsBoard.blank(6);
      final copy = board.copyWith();
      expect(copy.size, board.size);
      expect(copy.cells, board.cells);
      expect(identical(copy.cells, board.cells), false);
    });

    test('동등성 비교', () {
      final board1 = TentsBoard.blank(6);
      final board2 = TentsBoard.blank(6);
      expect(board1, equals(board2));

      final board3 = board1.setValue(0, 0, TentsBoard.tent);
      expect(board1, isNot(equals(board3)));
    });

    test('toString 포맷', () {
      final board = TentsBoard.blank(6);
      final str = board.toString();
      expect(str.contains('.'), true);
    });

    test('isComplete 판정', () {
      // 나무+텐트+잔디로 꽉 채운 보드
      final cells = <int>[];
      final treePositions = <int>{};
      for (var i = 0; i < 36; i++) {
        if (i % 4 == 0) {
          cells.add(TentsBoard.tree);
          treePositions.add(i);
        } else if (i % 4 == 1) {
          cells.add(TentsBoard.tent);
        } else {
          cells.add(TentsBoard.grass);
        }
      }
      final board = TentsBoard(
        size: 6,
        cells: cells,
        rowCounts: List.filled(6, 0),
        colCounts: List.filled(6, 0),
        treePositions: treePositions,
      );
      expect(board.isComplete, true);
    });

    test('빈칸이 있으면 isComplete false', () {
      final cells = List<int>.filled(36, TentsBoard.grass);
      cells[5] = TentsBoard.empty;
      final board = TentsBoard(
        size: 6,
        cells: cells,
        rowCounts: List.filled(6, 0),
        colCounts: List.filled(6, 0),
        treePositions: {},
      );
      expect(board.isComplete, false);
    });
  });

  group('TentsSolver', () {
    // 간단한 2x2 유사 테스트용 보드 (실제는 6 이상이지만 로직 검증)
    TentsBoard _makeSmallBoard({
      required List<int> cells,
      required List<int> rowCounts,
      required List<int> colCounts,
      required Set<int> treePositions,
    }) {
      return TentsBoard(
        size: 6,
        cells: cells,
        rowCounts: rowCounts,
        colCounts: colCounts,
        treePositions: treePositions,
      );
    }

    test('텐트 인접 위반 감지', () {
      // 텐트 2개가 대각선 인접
      final cells = List<int>.filled(36, TentsBoard.grass);
      cells[0] = TentsBoard.tent;
      cells[7] = TentsBoard.tent; // (1,1) — 대각선 인접
      final board = _makeSmallBoard(
        cells: cells,
        rowCounts: [1, 1, 0, 0, 0, 0],
        colCounts: [1, 1, 0, 0, 0, 0],
        treePositions: {},
      );
      final violations = TentsSolver.getAdjacentTentViolations(board);
      expect(violations.contains(0), true);
      expect(violations.contains(7), true);
    });

    test('텐트 비인접 시 위반 없음', () {
      final cells = List<int>.filled(36, TentsBoard.grass);
      cells[0] = TentsBoard.tent;
      cells[2] = TentsBoard.tent; // (0,2) — 한 칸 건너
      final board = _makeSmallBoard(
        cells: cells,
        rowCounts: [2, 0, 0, 0, 0, 0],
        colCounts: [1, 0, 1, 0, 0, 0],
        treePositions: {},
      );
      final violations = TentsSolver.getAdjacentTentViolations(board);
      expect(violations.isEmpty, true);
    });

    test('isValid 부분 검증', () {
      final cells = List<int>.filled(36, TentsBoard.empty);
      cells[1] = TentsBoard.tree;
      cells[0] = TentsBoard.tent; // (0,0) 텐트, (0,1) 나무 — 인접 OK
      final board = _makeSmallBoard(
        cells: cells,
        rowCounts: [1, 0, 0, 0, 0, 0],
        colCounts: [1, 0, 0, 0, 0, 0],
        treePositions: {1},
      );
      expect(TentsSolver.isValid(board), true);
    });

    test('isValid 행/열 초과 시 false', () {
      final cells = List<int>.filled(36, TentsBoard.empty);
      cells[1] = TentsBoard.tree;
      cells[3] = TentsBoard.tree;
      cells[0] = TentsBoard.tent;
      cells[2] = TentsBoard.tent;
      cells[4] = TentsBoard.tent; // 행 0에 텐트 3개 — rowCounts[0]=1 초과
      final board = _makeSmallBoard(
        cells: cells,
        rowCounts: [1, 0, 0, 0, 0, 0],
        colCounts: [1, 0, 1, 0, 1, 0],
        treePositions: {1, 3},
      );
      expect(TentsSolver.isValid(board), false);
    });

    test('isComplete 전체 검증 — 유효한 보드', () {
      // 6x6 보드에서 간단한 유효 배치:
      // 나무 (0,1), 텐트 (0,0), 나머지 잔디
      final cells = List<int>.filled(36, TentsBoard.grass);
      cells[0] = TentsBoard.tent;
      cells[1] = TentsBoard.tree;
      final board = _makeSmallBoard(
        cells: cells,
        rowCounts: [1, 0, 0, 0, 0, 0],
        colCounts: [1, 0, 0, 0, 0, 0],
        treePositions: {1},
      );
      expect(TentsSolver.isComplete(board), true);
    });

    test('isComplete — 나무-텐트 매칭 실패', () {
      // 텐트가 나무와 인접하지 않음
      final cells = List<int>.filled(36, TentsBoard.grass);
      cells[0] = TentsBoard.tent;
      cells[8] = TentsBoard.tree; // (1,2) — (0,0)과 인접하지 않음
      final board = _makeSmallBoard(
        cells: cells,
        rowCounts: [1, 0, 0, 0, 0, 0],
        colCounts: [1, 0, 0, 0, 0, 0],
        treePositions: {8},
      );
      expect(TentsSolver.isComplete(board), false);
    });

    test('solve 간단한 퍼즐', () {
      // 나무 (0,1), 행/열 힌트 → 텐트는 (0,0)
      final cells = List<int>.filled(36, TentsBoard.empty);
      cells[1] = TentsBoard.tree;
      final board = TentsBoard(
        size: 6,
        cells: cells,
        rowCounts: [1, 0, 0, 0, 0, 0],
        colCounts: [1, 0, 0, 0, 0, 0],
        treePositions: {1},
      );
      final solution = TentsSolver.solve(board);
      expect(solution, isNotNull);
      if (solution != null) {
        expect(TentsSolver.isComplete(solution), true);
      }
    });
  });

  group('TentsGenerator', () {
    test('6x6 입문 퍼즐 생성', () {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);
      if (result != null) {
        expect(result.puzzle.size, 6);
        expect(result.solution.size, 6);
        // 퍼즐에는 나무와 빈칸만 있어야 함
        for (var i = 0; i < 36; i++) {
          final v = result.puzzle.cells[i];
          expect(v == TentsBoard.empty || v == TentsBoard.tree, true);
        }
        // 솔루션은 완성 상태여야 함
        expect(TentsSolver.isComplete(result.solution), true);
      }
    });

    test('8x8 쉬움 퍼즐 생성', () {
      final result = TentsGenerator.generate(
        size: 8,
        difficulty: 1,
        seed: 123,
      );
      expect(result, isNotNull);
      if (result != null) {
        expect(result.puzzle.size, 8);
        expect(TentsSolver.isComplete(result.solution), true);
      }
    });

    test('다른 시드는 다른 퍼즐 생성', () {
      final r1 = TentsGenerator.generate(size: 6, difficulty: 0, seed: 1);
      final r2 = TentsGenerator.generate(size: 6, difficulty: 0, seed: 2);
      if (r1 != null && r2 != null) {
        expect(r1.puzzle == r2.puzzle, false);
      }
    });

    test('같은 시드는 같은 퍼즐 생성', () {
      final r1 = TentsGenerator.generate(size: 6, difficulty: 0, seed: 42);
      final r2 = TentsGenerator.generate(size: 6, difficulty: 0, seed: 42);
      if (r1 != null && r2 != null) {
        expect(r1.puzzle, equals(r2.puzzle));
      }
    });

    test('10x10 보통 퍼즐 생성', () {
      final result = TentsGenerator.generate(
        size: 10,
        difficulty: 2,
        seed: 999,
      );
      expect(result, isNotNull);
      if (result != null) {
        expect(result.puzzle.size, 10);
        expect(TentsSolver.isComplete(result.solution), true);
      }
    });

    test('나무와 텐트 1:1 매칭 보장', () {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 77,
      );
      if (result != null) {
        final treeCount = result.solution.treePositions.length;
        var tentCount = 0;
        for (final cell in result.solution.cells) {
          if (cell == TentsBoard.tent) tentCount++;
        }
        expect(treeCount, tentCount);
      }
    });

    test('행/열 힌트 정확성', () {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 55,
      );
      if (result != null) {
        final sol = result.solution;
        for (var r = 0; r < sol.size; r++) {
          expect(sol.currentRowTents(r), sol.rowCounts[r]);
        }
        for (var c = 0; c < sol.size; c++) {
          expect(sol.currentColTents(c), sol.colCounts[c]);
        }
      }
    });
  });

  group('TentsHintEngine', () {
    test('Level 1 힌트 — 위치 강조', () {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      if (result == null) return;

      final hint = TentsHintEngine.getHint(
        result.puzzle,
        result.solution,
        level: 1,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      expect(hint.message.isNotEmpty, true);
    });

    test('Level 2 힌트 — 값 힌트', () {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      if (result == null) return;

      final hint = TentsHintEngine.getHint(
        result.puzzle,
        result.solution,
        level: 2,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 2);
    });

    test('Level 3 힌트 — 기법 설명', () {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      if (result == null) return;

      final hint = TentsHintEngine.getHint(
        result.puzzle,
        result.solution,
        level: 3,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 3);
      expect(hint.technique, isNotNull);
    });

    test('Level 4 힌트 — 정답 공개', () {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      if (result == null) return;

      final hint = TentsHintEngine.getHint(
        result.puzzle,
        result.solution,
        level: 4,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 4);
      expect(hint.value, isNotNull);
      expect(
        hint.value == TentsBoard.tent || hint.value == TentsBoard.grass,
        true,
      );
    });

    test('완성된 보드에서 힌트 없음', () {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      if (result == null) return;

      final hint = TentsHintEngine.getHint(
        result.solution,
        result.solution,
        level: 1,
      );
      expect(hint, isNull);
    });
  });
}
