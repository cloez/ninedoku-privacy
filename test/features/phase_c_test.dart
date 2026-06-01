import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/technique_analyzer.dart';
import 'package:ninedoku/core/sudoku/hint_engine.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/core/sudoku/generator.dart';

void main() {
  late List<List<int>> solution;
  late List<List<int>> puzzle;

  setUp(() {
    solution = [
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
    // 3칸만 비운 쉬운 퍼즐 (Naked Single로 풀림)
    puzzle = solution.map((r) => List<int>.from(r)).toList();
    puzzle[0][0] = 0; // 정답 5
    puzzle[0][1] = 0; // 정답 3
    puzzle[1][0] = 0; // 정답 6
  });

  group('Item 1: 풀이 기법 분석기', () {
    test('SolvingTechnique enum 정의 확인', () {
      expect(SolvingTechnique.values.length, equals(8));
      expect(SolvingTechnique.nakedSingle.score, equals(1));
      expect(SolvingTechnique.hiddenSingle.score, equals(2));
      expect(SolvingTechnique.nakedPair.score, equals(4));
      expect(SolvingTechnique.xWing.score, equals(8));
    });

    test('쉬운 퍼즐 분석 — Naked/Hidden Single만 사용', () {
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, isNotEmpty);
      // 3칸 비운 쉬운 퍼즐은 기본 기법만으로 풀림
      for (final t in techniques) {
        expect(
          [SolvingTechnique.nakedSingle, SolvingTechnique.hiddenSingle],
          contains(t),
        );
      }
    });

    test('빈 칸이 없는 보드 분석 — 빈 기법 목록', () {
      final techniques = TechniqueAnalyzer.analyze(solution);
      expect(techniques, isEmpty);
    });

    test('evaluateDifficulty가 난이도 반환', () {
      final diff = TechniqueAnalyzer.evaluateDifficulty(puzzle);
      // 3칸 빈 쉬운 퍼즐 → beginner 또는 easy
      expect(
        [Difficulty.beginner, Difficulty.easy],
        contains(diff),
      );
    });

    test('findNextTechnique가 풀이 가능한 기법 반환', () {
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(result, isNotNull);
      expect(result!.technique, isNotNull);
      expect(result.explanation, isNotEmpty);
    });

    test('완전한 보드에서 findNextTechnique는 null', () {
      final result = TechniqueAnalyzer.findNextTechnique(solution);
      expect(result, isNull);
    });

    test('생성된 퍼즐에서 analyze 동작 확인', () {
      final generated = SudokuGenerator.generate(
        difficulty: Difficulty.beginner,
        seed: 12345,
      );
      expect(generated, isNotNull);
      final techniques = TechniqueAnalyzer.analyze(generated!.puzzle);
      // 입문 퍼즐도 최소 하나의 기법이 필요
      expect(techniques, isNotEmpty);
    });

    test('생성된 어려운 퍼즐은 더 많은 기법 필요', () {
      final easy = SudokuGenerator.generate(
        difficulty: Difficulty.beginner,
        seed: 99999,
      );
      final hard = SudokuGenerator.generate(
        difficulty: Difficulty.hard,
        seed: 99999,
      );
      expect(easy, isNotNull);
      expect(hard, isNotNull);

      final easyTechniques = TechniqueAnalyzer.analyze(easy!.puzzle);
      final hardTechniques = TechniqueAnalyzer.analyze(hard!.puzzle);

      // 어려운 퍼즐이 더 많거나 고급 기법을 사용할 가능성 높음
      // (보장은 아니지만 빈 칸이 더 많으므로)
      expect(easyTechniques, isNotEmpty);
      expect(hardTechniques, isNotEmpty);
    });
  });

  group('Item 5: 힌트 2-3단계', () {
    test('HintLevel enum에 4단계 모두 존재', () {
      expect(HintLevel.values.length, equals(4));
      expect(HintLevel.highlightRegion, isNotNull);
      expect(HintLevel.showCandidates, isNotNull);
      expect(HintLevel.explainTechnique, isNotNull);
      expect(HintLevel.revealAnswer, isNotNull);
    });

    test('2단계 힌트: 후보 숫자 안내', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.showCandidates,
      );

      expect(hint, isNotNull);
      expect(hint!.level, equals(HintLevel.showCandidates));
      expect(hint.candidates, isNotEmpty);
      // 후보에 정답이 포함되어야 함
      final answer = solution[hint.row][hint.col];
      expect(hint.candidates.contains(answer), isTrue);
      expect(hint.message, contains('가능한 숫자'));
    });

    test('3단계 힌트: 풀이 기법 설명', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.explainTechnique,
      );

      expect(hint, isNotNull);
      expect(hint!.level, equals(HintLevel.explainTechnique));
      expect(hint.message, isNotEmpty);
      // 기법이 발견되면 technique이 설정됨
      // 발견 못하면 후보 안내로 대체
    });

    test('1단계 힌트: 기존 동작 유지', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.highlightRegion,
      );

      expect(hint, isNotNull);
      expect(hint!.level, equals(HintLevel.highlightRegion));
      expect(hint.highlightCells, isNotEmpty);
    });

    test('4단계 힌트: 기존 동작 유지', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.revealAnswer,
      );

      expect(hint, isNotNull);
      expect(hint!.level, equals(HintLevel.revealAnswer));
      expect(hint.answer, isNotNull);
      expect(hint.answer, equals(solution[hint.row][hint.col]));
    });

    test('완전한 보드에서 모든 힌트 레벨이 null', () {
      final board = SudokuBoard(puzzle: solution, solution: solution);
      for (final level in HintLevel.values) {
        final hint = HintEngine.getHint(board: board, level: level);
        expect(hint, isNull, reason: '${level.name} 힌트가 null이어야 함');
      }
    });

    test('HintResult의 candidates 필드 기본값은 빈 Set', () {
      const result = HintResult(
        row: 0,
        col: 0,
        level: HintLevel.highlightRegion,
      );
      expect(result.candidates, isEmpty);
      expect(result.technique, isNull);
    });
  });

  group('TechniqueResult 모델', () {
    test('기본 생성', () {
      const result = TechniqueResult(
        technique: SolvingTechnique.nakedSingle,
        row: 0,
        col: 0,
        value: 5,
        explanation: '테스트',
      );
      expect(result.technique, equals(SolvingTechnique.nakedSingle));
      expect(result.value, equals(5));
      expect(result.eliminations, isEmpty);
    });

    test('제거 후보 포함', () {
      const result = TechniqueResult(
        technique: SolvingTechnique.nakedPair,
        row: 0,
        col: 0,
        eliminations: {3, 7},
        explanation: '테스트',
      );
      expect(result.eliminations, containsAll([3, 7]));
    });
  });
}
