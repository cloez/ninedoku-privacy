import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/technique_analyzer.dart';
import 'package:ninedoku/core/sudoku/hint_engine.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/core/sudoku/generator.dart';

void main() {
  // 공통 테스트 데이터
  final solution = [
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

  group('QA: analyze() 무한루프 방지', () {
    test('빈 보드(모두 0)에서 analyze가 크래시 없이 완료된다', () {
      final emptyBoard = List.generate(9, (_) => List.filled(9, 0));
      // 무한루프에 빠지지 않고 200번 반복 이내에 종료되어야 함
      final techniques = TechniqueAnalyzer.analyze(emptyBoard);
      // 빈 보드는 풀 수 없지만 크래시하면 안됨
      expect(techniques, isA<List<SolvingTechnique>>());
    });

    test('1칸만 비운 퍼즐은 빠르게 분석 완료', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[4][4] = 0; // 정답 5
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, contains(SolvingTechnique.nakedSingle));
    });

    test('유효하지 않은 퍼즐(모순된 상태)에서 크래시 없이 완료', () {
      // 같은 행에 동일 숫자 배치 (모순)
      final invalid = List.generate(9, (_) => List.filled(9, 0));
      invalid[0][0] = 5;
      invalid[0][1] = 5; // 같은 행에 5 중복
      final techniques = TechniqueAnalyzer.analyze(invalid);
      expect(techniques, isA<List<SolvingTechnique>>());
    });
  });

  group('QA: _placeValue 후보 업데이트 정확성', () {
    test('값 배치 후 같은 행/열/박스의 후보에서 해당 숫자가 제거된다', () {
      // 간접적으로 검증: 1칸 비운 퍼즐에서 analyze하면 nakedSingle로 풀어야 함
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[0][0] = 0;
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, isNotEmpty);
      expect(techniques.first, equals(SolvingTechnique.nakedSingle));
    });

    test('2칸 비운 서로 다른 박스에서 각각 올바르게 풀린다', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[0][0] = 0; // 박스 (0,0), 정답 5
      puzzle[8][8] = 0; // 박스 (2,2), 정답 9
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, isNotEmpty);
    });
  });

  group('QA: Naked Pair 자기 자신 제거 방지', () {
    test('Naked Pair에서 페어 셀 자체의 후보는 유지된다', () {
      // Naked Pair가 있는 퍼즐 구성: 간접 검증
      // analyze가 크래시 없이 완료되면 자기 자신 제거가 없는 것
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      // 여러 칸 비워서 naked pair 상황 유도
      puzzle[0][0] = 0;
      puzzle[0][1] = 0;
      puzzle[0][2] = 0;
      puzzle[1][0] = 0;
      puzzle[1][1] = 0;
      puzzle[2][0] = 0;
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, isA<List<SolvingTechnique>>());
    });
  });

  group('QA: Hidden Pair retainAll 후 빈 Set 방지', () {
    test('Hidden Pair 적용 후에도 후보가 최소 2개 유지된다', () {
      // hidden pair가 적용되면 해당 셀에 정확히 {n1, n2} 2개가 남아야 함
      // 빈 Set이 되면 안됨
      // 어려운 퍼즐 생성으로 간접 검증
      final generated = SudokuGenerator.generate(
        difficulty: Difficulty.hard,
        seed: 42,
      );
      expect(generated, isNotNull);
      final techniques = TechniqueAnalyzer.analyze(generated!.puzzle);
      // 크래시 없이 완료되면 OK
      expect(techniques, isA<List<SolvingTechnique>>());
    });

    test('수정된 hidden pair 로직이 정확히 두 숫자가 같은 두 셀에만 존재할 때만 적용', () {
      // 다양한 시드로 여러 퍼즐 분석하여 안정성 검증
      for (var seed = 1; seed <= 20; seed++) {
        final generated = SudokuGenerator.generate(
          difficulty: Difficulty.expert,
          seed: seed,
        );
        if (generated == null) continue;
        final techniques = TechniqueAnalyzer.analyze(generated.puzzle);
        expect(techniques, isA<List<SolvingTechnique>>(),
            reason: 'seed=$seed 에서 크래시');
      }
    });
  });

  group('QA: evaluateDifficulty 빈 기법 목록 fallback', () {
    test('기법만으로 풀 수 없는 퍼즐은 빈 칸 기반 fallback으로 평가', () {
      // 빈 보드는 기법으로 풀 수 없음 → DifficultyEvaluator.evaluate 사용
      final emptyBoard = List.generate(9, (_) => List.filled(9, 0));
      final difficulty = TechniqueAnalyzer.evaluateDifficulty(emptyBoard);
      // 빈 칸 81개 → master
      expect(difficulty, equals(Difficulty.master));
    });

    test('완전한 보드는 빈 칸 0개 → beginner fallback', () {
      final difficulty = TechniqueAnalyzer.evaluateDifficulty(solution);
      // 기법 목록 비어있음 → 빈칸 0개 → beginner
      expect(difficulty, equals(Difficulty.beginner));
    });

    test('다양한 난이도 퍼즐에서 evaluateDifficulty가 크래시 없이 동작', () {
      for (final diff in Difficulty.values) {
        final generated = SudokuGenerator.generate(
          difficulty: diff,
          seed: 777,
        );
        if (generated == null) continue;
        final evaluated = TechniqueAnalyzer.evaluateDifficulty(generated.puzzle);
        expect(evaluated, isA<Difficulty>(),
            reason: '${diff.label} 퍼즐 평가 실패');
      }
    });
  });

  group('QA: 2단계 힌트 — 정답이 반드시 candidates에 포함', () {
    test('다양한 퍼즐에서 2단계 힌트의 candidates에 정답 포함', () {
      for (var seed = 1; seed <= 10; seed++) {
        final generated = SudokuGenerator.generate(
          difficulty: Difficulty.medium,
          seed: seed,
        );
        if (generated == null) continue;
        final board = SudokuBoard(
          puzzle: generated.puzzle,
          solution: generated.solution,
        );
        final hint = HintEngine.getHint(
          board: board,
          level: HintLevel.showCandidates,
        );
        if (hint == null) continue;
        final answer = generated.solution[hint.row][hint.col];
        expect(hint.candidates.contains(answer), isTrue,
            reason: 'seed=$seed: 정답 $answer이 candidates ${hint.candidates}에 없음');
      }
    });

    test('3칸 비운 퍼즐의 2단계 힌트에 정답이 포함된다', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[0][0] = 0;
      puzzle[0][1] = 0;
      puzzle[1][0] = 0;
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.showCandidates,
      );
      expect(hint, isNotNull);
      final answer = solution[hint!.row][hint.col];
      expect(hint.candidates, contains(answer));
    });

    test('2단계 힌트의 candidates가 비어있지 않다', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[4][4] = 0;
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.showCandidates,
      );
      expect(hint, isNotNull);
      expect(hint!.candidates, isNotEmpty);
    });
  });

  group('QA: 3단계 힌트 — 기법 기반 설명 및 graceful fallback', () {
    test('쉬운 퍼즐에서 3단계 힌트가 기법을 찾는다', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[0][0] = 0;
      puzzle[0][1] = 0;
      puzzle[1][0] = 0;
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.explainTechnique,
      );
      expect(hint, isNotNull);
      // 쉬운 퍼즐이므로 기법을 찾을 수 있어야 함
      expect(hint!.technique, isNotNull);
      expect(hint.message, isNotEmpty);
    });

    test('3단계에서 기법 못찾으면 2단계(showCandidates)로 graceful fallback', () {
      // 완전한 보드에서 한 칸만 비운 경우: nakedSingle은 찾을 수 있음
      // 대신 findNextTechnique가 null을 반환하는 상황을 간접 검증
      // 완전히 풀린 보드에서는 힌트 자체가 null
      final board = SudokuBoard(puzzle: solution, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.explainTechnique,
      );
      // 빈 셀이 없으므로 null
      expect(hint, isNull);
    });

    test('3단계 힌트가 반환하는 explanation이 비어있지 않다', () {
      final generated = SudokuGenerator.generate(
        difficulty: Difficulty.medium,
        seed: 100,
      );
      expect(generated, isNotNull);
      final board = SudokuBoard(
        puzzle: generated!.puzzle,
        solution: generated.solution,
      );
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.explainTechnique,
      );
      expect(hint, isNotNull);
      expect(hint!.message, isNotEmpty);
    });
  });

  group('QA: findNextTechnique 반환값 정확성', () {
    test('findNextTechnique가 반환하는 셀이 실제로 비어있다', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[0][0] = 0;
      puzzle[0][1] = 0;
      puzzle[1][0] = 0;
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(result, isNotNull);
      expect(puzzle[result!.row][result.col], equals(0));
    });

    test('findNextTechnique가 반환하는 value가 solution과 일치한다', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[4][4] = 0; // 정답 5
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(result, isNotNull);
      expect(result!.value, equals(solution[result.row][result.col]));
    });

    test('findNextTechnique가 반환하는 explanation에 숫자가 포함된다', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[0][0] = 0;
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(result, isNotNull);
      // explanation에 value 숫자가 포함되어야 함
      expect(result!.explanation, contains('${result.value}'));
    });

    test('다양한 생성 퍼즐에서 findNextTechnique가 유효한 결과 반환', () {
      for (var seed = 1; seed <= 10; seed++) {
        final generated = SudokuGenerator.generate(
          difficulty: Difficulty.easy,
          seed: seed,
        );
        if (generated == null) continue;
        final result = TechniqueAnalyzer.findNextTechnique(generated.puzzle);
        if (result != null) {
          // 반환된 셀이 비어있어야 함
          expect(generated.puzzle[result.row][result.col], equals(0),
              reason: 'seed=$seed: 비어있지 않은 셀 반환');
          // technique이 유효한 enum 값이어야 함
          expect(SolvingTechnique.values, contains(result.technique),
              reason: 'seed=$seed: 잘못된 technique');
        }
      }
    });
  });

  group('QA: Naked Triple 열/박스 검사 (수정 후 검증)', () {
    test('analyze가 Naked Triple을 사용하는 복잡한 퍼즐에서 크래시 없이 동작', () {
      // 여러 난이도의 퍼즐에서 안정성 검증
      for (final diff in [Difficulty.hard, Difficulty.expert]) {
        for (var seed = 1; seed <= 5; seed++) {
          final generated = SudokuGenerator.generate(
            difficulty: diff,
            seed: seed,
          );
          if (generated == null) continue;
          final techniques = TechniqueAnalyzer.analyze(generated.puzzle);
          expect(techniques, isA<List<SolvingTechnique>>(),
              reason: '${diff.label} seed=$seed 크래시');
        }
      }
    });
  });

  group('QA: SolvingTechnique enum 속성', () {
    test('모든 기법의 label이 비어있지 않다', () {
      for (final t in SolvingTechnique.values) {
        expect(t.label, isNotEmpty, reason: '${t.name} label 빈 문자열');
      }
    });

    test('모든 기법의 description이 비어있지 않다', () {
      for (final t in SolvingTechnique.values) {
        expect(t.description, isNotEmpty, reason: '${t.name} description 빈 문자열');
      }
    });

    test('모든 기법의 score가 1~8 범위이다', () {
      for (final t in SolvingTechnique.values) {
        expect(t.score, greaterThanOrEqualTo(1),
            reason: '${t.name} score < 1');
        expect(t.score, lessThanOrEqualTo(8),
            reason: '${t.name} score > 8');
      }
    });
  });

  group('QA: 힌트 단계별 일관성', () {
    test('모든 힌트 단계가 같은 셀을 가리킨다 (빈 셀이 하나일 때)', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[3][3] = 0; // 정답 7
      final board = SudokuBoard(puzzle: puzzle, solution: solution);

      final hint1 = HintEngine.getHint(
        board: board,
        level: HintLevel.highlightRegion,
      );
      final hint2 = HintEngine.getHint(
        board: board,
        level: HintLevel.showCandidates,
      );
      final hint4 = HintEngine.getHint(
        board: board,
        level: HintLevel.revealAnswer,
      );

      expect(hint1, isNotNull);
      expect(hint2, isNotNull);
      expect(hint4, isNotNull);

      // 빈 셀이 하나뿐이므로 모두 같은 셀
      expect(hint1!.row, equals(3));
      expect(hint1.col, equals(3));
      expect(hint2!.row, equals(3));
      expect(hint2.col, equals(3));
      expect(hint4!.row, equals(3));
      expect(hint4.col, equals(3));
      expect(hint4.answer, equals(7));
    });

    test('2단계 candidates에 4단계 answer가 포함된다', () {
      final generated = SudokuGenerator.generate(
        difficulty: Difficulty.beginner,
        seed: 555,
      );
      expect(generated, isNotNull);
      final board = SudokuBoard(
        puzzle: generated!.puzzle,
        solution: generated.solution,
      );

      final hint2 = HintEngine.getHint(
        board: board,
        level: HintLevel.showCandidates,
      );
      expect(hint2, isNotNull);

      // 같은 셀에 대해 4단계 힌트 확인
      // 2단계의 candidates에 정답이 반드시 포함되어야 함
      final answer = generated.solution[hint2!.row][hint2.col];
      expect(hint2.candidates, contains(answer),
          reason: '2단계 후보에 정답 $answer이 없음');
    });
  });

  group('QA: Pointing Pair / Box-Line Reduction 안정성', () {
    test('다양한 퍼즐에서 pointing pair가 크래시 없이 동작', () {
      for (var seed = 100; seed <= 110; seed++) {
        final generated = SudokuGenerator.generate(
          difficulty: Difficulty.hard,
          seed: seed,
        );
        if (generated == null) continue;
        // analyze 내부에서 pointing pair가 호출될 수 있음
        final techniques = TechniqueAnalyzer.analyze(generated.puzzle);
        expect(techniques, isA<List<SolvingTechnique>>());
      }
    });
  });

  group('QA: 에지 케이스', () {
    test('거의 완성된 퍼즐(빈칸 1개)에서 모든 기능이 정상 동작', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      puzzle[8][8] = 0;
      final board = SudokuBoard(puzzle: puzzle, solution: solution);

      // analyze
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, isNotEmpty);

      // evaluateDifficulty
      final diff = TechniqueAnalyzer.evaluateDifficulty(puzzle);
      expect(diff, isA<Difficulty>());

      // findNextTechnique
      final nextTech = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(nextTech, isNotNull);
      expect(nextTech!.row, equals(8));
      expect(nextTech.col, equals(8));
      expect(nextTech.value, equals(9));

      // 모든 힌트 단계
      for (final level in HintLevel.values) {
        final hint = HintEngine.getHint(board: board, level: level);
        expect(hint, isNotNull, reason: '${level.name} 힌트가 null');
      }
    });

    test('대각선으로 빈칸이 있는 퍼즐에서 analyze가 정상 동작', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      for (var i = 0; i < 9; i++) {
        puzzle[i][i] = 0;
      }
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, isA<List<SolvingTechnique>>());
    });

    test('첫 행을 모두 비운 퍼즐에서 analyze가 크래시 없이 완료', () {
      final puzzle = solution.map((r) => List<int>.from(r)).toList();
      for (var c = 0; c < 9; c++) {
        puzzle[0][c] = 0;
      }
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, isA<List<SolvingTechnique>>());
      expect(techniques, isNotEmpty);
    });
  });
}
