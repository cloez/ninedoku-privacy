import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/solver.dart';

void main() {
  group('SudokuSolver', () {
    // TC-001: 생성된 문제는 유일해답을 가져야 한다
    test('TC-001: 유일해답이 있는 퍼즐을 올바르게 풀 수 있다', () {
      final puzzle = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];

      final solution = SudokuSolver.solve(puzzle);
      expect(solution, isNotNull);

      // 솔루션이 유효한지 검증
      expect(SudokuSolver.isValid(solution!), isTrue);

      // 모든 셀이 채워졌는지
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(solution[r][c], inInclusiveRange(1, 9));
        }
      }

      // 원래 퍼즐의 숫자가 보존되었는지
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (puzzle[r][c] != 0) {
            expect(solution[r][c], equals(puzzle[r][c]));
          }
        }
      }
    });

    test('TC-001: 유일해답 검증', () {
      final puzzle = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];

      expect(SudokuSolver.hasUniqueSolution(puzzle), isTrue);
    });

    test('빈 보드는 여러 해답이 있다', () {
      final emptyBoard = List.generate(9, (_) => List.filled(9, 0));
      expect(SudokuSolver.hasUniqueSolution(emptyBoard), isFalse);
    });

    test('이미 완성된 유효한 보드는 유일해답을 가진다', () {
      final completed = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];

      expect(SudokuSolver.isValid(completed), isTrue);
      expect(SudokuSolver.hasUniqueSolution(completed), isTrue);
    });

    test('유효하지 않은 보드 감지', () {
      final invalid = [
        [5, 5, 0, 0, 0, 0, 0, 0, 0], // 행에 5가 중복
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ];
      expect(SudokuSolver.isValid(invalid), isFalse);
    });
  });
}
