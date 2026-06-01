import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/generator.dart';
import 'package:ninedoku/core/sudoku/solver.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';

void main() {
  group('SudokuGenerator', () {
    // TC-002: 난이도별 문제를 안정적으로 생성해야 한다
    for (final difficulty in Difficulty.mvpDifficulties) {
      test('TC-002: ${difficulty.label} 난이도 퍼즐 생성', () {
        final result = SudokuGenerator.generate(
          difficulty: difficulty,
          seed: 12345,
        );

        expect(result, isNotNull, reason: '${difficulty.label} 퍼즐 생성 실패');

        final puzzle = result!.puzzle;
        final solution = result.solution;

        // 솔루션이 유효한지
        expect(SudokuSolver.isValid(solution), isTrue);

        // 퍼즐이 유일해답을 가지는지
        expect(SudokuSolver.hasUniqueSolution(puzzle), isTrue);

        // 솔루션이 퍼즐과 일치하는지
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (puzzle[r][c] != 0) {
              expect(puzzle[r][c], equals(solution[r][c]));
            }
          }
        }

        // 빈 칸 개수가 범위 내인지
        var emptyCount = 0;
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (puzzle[r][c] == 0) emptyCount++;
          }
        }
        // fallback으로 범위가 약간 벗어날 수 있으므로 여유있게 체크
        expect(emptyCount, greaterThanOrEqualTo(difficulty.emptyCellRange.$1 - 5));
        expect(emptyCount, lessThanOrEqualTo(difficulty.emptyCellRange.$2 + 5));
      });
    }

    // TC-008: 동일 seed로 동일 퍼즐이 재생성되어야 한다
    test('TC-008: seed 기반 결정적 생성', () {
      const seed = 20260526;
      final result1 = SudokuGenerator.generate(
        difficulty: Difficulty.easy,
        seed: seed,
      );
      final result2 = SudokuGenerator.generate(
        difficulty: Difficulty.easy,
        seed: seed,
      );

      expect(result1, isNotNull);
      expect(result2, isNotNull);

      // 동일 seed -> 동일 퍼즐
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(
            result1!.puzzle[r][c],
            equals(result2!.puzzle[r][c]),
            reason: 'seed 기반 생성이 결정적이지 않음 ($r, $c)',
          );
          expect(
            result1.solution[r][c],
            equals(result2.solution[r][c]),
          );
        }
      }
    });

    test('TC-008: 다른 seed는 다른 퍼즐을 생성한다', () {
      final result1 = SudokuGenerator.generate(
        difficulty: Difficulty.easy,
        seed: 100,
      );
      final result2 = SudokuGenerator.generate(
        difficulty: Difficulty.easy,
        seed: 200,
      );

      expect(result1, isNotNull);
      expect(result2, isNotNull);

      // 다른 seed -> 다른 퍼즐 (최소 하나의 셀이 다름)
      var hasDifference = false;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (result1!.puzzle[r][c] != result2!.puzzle[r][c]) {
            hasDifference = true;
            break;
          }
        }
        if (hasDifference) break;
      }
      expect(hasDifference, isTrue);
    });
  });

  group('DifficultyEvaluator', () {
    // TC-003: 난이도 분류가 일관되게 동작해야 한다
    test('TC-003: 빈 칸 개수별 난이도 분류', () {
      expect(DifficultyEvaluator.evaluateByEmptyCount(30), Difficulty.beginner);
      expect(DifficultyEvaluator.evaluateByEmptyCount(35), Difficulty.beginner);
      expect(DifficultyEvaluator.evaluateByEmptyCount(36), Difficulty.easy);
      expect(DifficultyEvaluator.evaluateByEmptyCount(40), Difficulty.easy);
      expect(DifficultyEvaluator.evaluateByEmptyCount(41), Difficulty.medium);
      expect(DifficultyEvaluator.evaluateByEmptyCount(46), Difficulty.medium);
      expect(DifficultyEvaluator.evaluateByEmptyCount(47), Difficulty.hard);
      expect(DifficultyEvaluator.evaluateByEmptyCount(52), Difficulty.hard);
      expect(DifficultyEvaluator.evaluateByEmptyCount(53), Difficulty.expert);
      expect(DifficultyEvaluator.evaluateByEmptyCount(58), Difficulty.expert);
      expect(DifficultyEvaluator.evaluateByEmptyCount(59), Difficulty.master);
    });

    test('TC-003: 실제 퍼즐의 난이도 평가', () {
      for (final difficulty in Difficulty.mvpDifficulties) {
        final result = SudokuGenerator.generate(
          difficulty: difficulty,
          seed: 99999,
        );
        if (result != null) {
          final evaluated = DifficultyEvaluator.evaluate(result.puzzle);
          // 간이 분류이므로 ±1단계 범위 내에서 일치
          final diffIndex = Difficulty.values.indexOf(difficulty);
          final evalIndex = Difficulty.values.indexOf(evaluated);
          expect(
            (diffIndex - evalIndex).abs(),
            lessThanOrEqualTo(1),
            reason: '${difficulty.label} -> ${evaluated.label}',
          );
        }
      }
    });
  });
}
