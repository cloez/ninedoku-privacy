import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/binairo/engine/binairo_board.dart';
import 'package:ninedoku/games/binairo/engine/binairo_solver.dart';
import 'package:ninedoku/games/binairo/engine/binairo_generator.dart';
import 'package:ninedoku/games/binairo/engine/binairo_hint.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════
  // Board 모델 테스트
  // ════════════════════════════════════════════════════════════════════
  group('Board 모델', () {
    test('빈 보드 생성 (6x6)', () {
      // 6x6 빈 보드를 생성하고 기본 속성 검증
      final board = BinairoBoard.empty(6);
      expect(board.size, 6);
      expect(board.cells.length, 36);
      expect(board.fixed.isEmpty, true);
      expect(board.emptyCellCount, 36);
      expect(board.isComplete, false);
    });

    test('getValue/setValue 동작', () {
      // 빈 보드에 값을 설정하고 조회 가능한지 검증
      var board = BinairoBoard.empty(6);
      expect(board.getValue(0, 0), -1); // 초기값은 빈칸

      board = board.setValue(0, 0, 1);
      expect(board.getValue(0, 0), 1);

      board = board.setValue(2, 3, 0);
      expect(board.getValue(2, 3), 0);

      // 빈칸으로 되돌리기
      board = board.setValue(0, 0, -1);
      expect(board.getValue(0, 0), -1);
    });

    test('toJson/fromJson 라운드트립', () {
      // 직렬화 후 역직렬화하면 동일한 보드가 복원되는지 검증
      final original = BinairoBoard(
        size: 6,
        cells: List.generate(36, (i) => i % 3 == 0 ? 0 : (i % 3 == 1 ? 1 : -1)),
        fixed: {0, 3, 6, 9},
      );

      final json = original.toJson();
      final restored = BinairoBoard.fromJson(json);

      expect(restored.size, original.size);
      expect(restored.cells, original.cells);
      expect(restored.fixed, original.fixed);
    });

    test('fixed 셀은 수정 불가', () {
      // 고정된 셀에 setValue를 호출해도 값이 변경되지 않는지 검증
      final board = BinairoBoard(
        size: 6,
        cells: List.generate(36, (i) => i == 0 ? 1 : -1),
        fixed: {0}, // 인덱스 0을 고정
      );

      // 고정 셀 변경 시도 → 동일 보드 반환
      final result = board.setValue(0, 0, 0);
      expect(result.getValue(0, 0), 1); // 변경되지 않음
      expect(identical(result, board), true); // 동일 인스턴스 반환
    });

    test('isComplete 판단', () {
      // 모든 셀이 채워지면 isComplete == true
      final completeCells = List.generate(36, (i) => i % 2);
      final completeBoard = BinairoBoard(
        size: 6,
        cells: completeCells,
        fixed: {},
      );
      expect(completeBoard.isComplete, true);

      // 빈칸이 하나라도 있으면 false
      final incompleteCells = List.generate(36, (i) => i == 0 ? -1 : i % 2);
      final incompleteBoard = BinairoBoard(
        size: 6,
        cells: incompleteCells,
        fixed: {},
      );
      expect(incompleteBoard.isComplete, false);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Solver 테스트
  // ════════════════════════════════════════════════════════════════════
  group('Solver', () {
    test('6x6 완성 보드가 isComplete == true', () {
      // generator가 만든 솔루션은 반드시 유효해야 함
      final result = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);
      expect(result!.solution.isComplete, true);
      expect(BinairoSolver.isComplete(result.solution), true);
    });

    test('규칙 위반 보드가 isValid == false (3연속)', () {
      // 3연속 규칙 위반 검증
      final cells = List<int>.filled(36, -1);
      // 첫 행에 0, 0, 0 연속 배치
      cells[0] = 0;
      cells[1] = 0;
      cells[2] = 0;
      final board = BinairoBoard(size: 6, cells: cells, fixed: {});
      expect(BinairoSolver.isValid(board), false);
    });

    test('규칙 위반 보드가 isValid == false (균등 위반)', () {
      // 행에 한쪽 값이 절반 초과 (예: 6x6에서 0이 4개)
      final cells = List<int>.filled(36, -1);
      // 첫 행에 0을 4개 배치 (3 초과 → 위반)
      cells[0] = 0;
      cells[1] = 1;
      cells[2] = 0;
      cells[3] = 0;
      cells[4] = 0;
      cells[5] = 1;
      final board = BinairoBoard(size: 6, cells: cells, fixed: {});
      expect(BinairoSolver.isValid(board), false);
    });

    test('규칙 위반 보드가 isValid == false (동일 행)', () {
      // 두 행이 완전히 동일한 경우 (유일성 위반)
      // 유효한 패턴의 두 동일 행 생성
      final cells = List<int>.filled(36, -1);
      // 행 0: 0,1,0,1,0,1
      // 행 1: 0,1,0,1,0,1 (동일)
      for (var c = 0; c < 6; c++) {
        cells[0 * 6 + c] = c % 2;
        cells[1 * 6 + c] = c % 2;
      }
      final board = BinairoBoard(size: 6, cells: cells, fixed: {});
      expect(BinairoSolver.isValid(board), false);
    });

    test('빈 6x6 보드를 solve하면 유효한 해답 반환', () {
      // 생성된 퍼즐에서 풀이 시도 (유일해 보장된 퍼즐)
      final genResult = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 33,
      );
      expect(genResult, isNotNull);
      final result = BinairoSolver.solve(genResult!.puzzle);
      expect(result, isNotNull);
      expect(result!.isComplete, true);
      expect(BinairoSolver.isComplete(result), true);
    });

    test('solve 결과가 isComplete == true', () {
      // 생성된 퍼즐을 solve하면 모든 규칙을 만족해야 함
      final genResult = BinairoGenerator.generate(
        size: 8,
        difficulty: 1,
        seed: 44,
      );
      expect(genResult, isNotNull);
      final solved = BinairoSolver.solve(genResult!.puzzle);
      expect(solved, isNotNull);
      expect(solved!.isComplete, true);
      expect(BinairoSolver.isComplete(solved), true);
    });

    test('hasUniqueSolution 검증 (유일해인 퍼즐)', () {
      // 생성기로 퍼즐을 만들어 유일해 검증
      final result = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);
      expect(BinairoSolver.hasUniqueSolution(result!.puzzle), true);
    });

    test('해가 없는 모순 보드에서 solve == null', () {
      // 해결 불가능한 모순 보드 구성
      // 첫 행에 0,0,1,0,0,1 (0이 4개 → 균형 위반으로 풀이 불가)
      final cells = List<int>.filled(36, -1);
      cells[0] = 0;
      cells[1] = 0;
      cells[2] = 1;
      cells[3] = 0;
      cells[4] = 0;
      cells[5] = 1;
      final board = BinairoBoard(
        size: 6,
        cells: cells,
        fixed: {0, 1, 2, 3, 4, 5},
      );
      final result = BinairoSolver.solve(board);
      expect(result, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Generator 테스트
  // ════════════════════════════════════════════════════════════════════
  group('Generator', () {
    test('6x6 입문 퍼즐 생성 성공', () {
      final result = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 1,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 6);
      expect(result.puzzle.emptyCellCount, greaterThan(0));
      expect(result.solution.isComplete, true);
    });

    test('8x8 쉬움 퍼즐 생성 성공', () {
      final result = BinairoGenerator.generate(
        size: 8,
        difficulty: 1,
        seed: 10,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 8);
      expect(result.puzzle.emptyCellCount, greaterThan(0));
      expect(result.solution.isComplete, true);
    });

    test('10x10 보통 퍼즐 생성 성공', () {
      final result = BinairoGenerator.generate(
        size: 10,
        difficulty: 2,
        seed: 100,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 10);
      expect(result.puzzle.emptyCellCount, greaterThan(0));
      expect(result.solution.isComplete, true);
    });

    test('12x12 어려움 퍼즐 생성 성공', () {
      final result = BinairoGenerator.generate(
        size: 12,
        difficulty: 3,
        seed: 200,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 12);
      expect(result.puzzle.emptyCellCount, greaterThan(0));
      expect(result.solution.isComplete, true);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('생성된 퍼즐이 유일해를 가짐', () {
      final result = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 55,
      );
      expect(result, isNotNull);
      expect(BinairoSolver.hasUniqueSolution(result!.puzzle), true);
    });

    test('같은 시드로 같은 퍼즐 생성 (결정성)', () {
      // 동일 시드로 두 번 생성하면 동일한 퍼즐이 나와야 함
      final result1 = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 77,
      );
      final result2 = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 77,
      );
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!.puzzle.cells, result2!.puzzle.cells);
      expect(result1.solution.cells, result2.solution.cells);
    });

    test('다른 시드로 다른 퍼즐 생성', () {
      // 다른 시드로 생성하면 다른 퍼즐이 나와야 함
      final result1 = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 100,
      );
      final result2 = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 200,
      );
      expect(result1, isNotNull);
      expect(result2, isNotNull);
      // 두 퍼즐이 다른지 확인 (셀 데이터가 다름)
      expect(result1!.puzzle.cells == result2!.puzzle.cells, false);
    });

    test('생성 시간 3초 이내', () {
      // 6x6 퍼즐 생성이 3초 이내에 완료되는지 검증
      final stopwatch = Stopwatch()..start();
      final result = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 999,
      );
      stopwatch.stop();
      expect(result, isNotNull);
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Hint 테스트
  // ════════════════════════════════════════════════════════════════════
  group('Hint', () {
    // 힌트 테스트를 위한 퍼즐 및 솔루션 준비
    late BinairoBoard puzzle;
    late BinairoBoard solution;

    setUp(() {
      // 생성기로 퍼즐/솔루션 쌍 준비
      final result = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      puzzle = result!.puzzle;
      solution = result.solution;
    });

    test('level 1: 행/열 인덱스 반환', () {
      final hint = BinairoHintEngine.getHint(puzzle, solution, level: 1);
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      // 행/열 인덱스가 유효 범위
      expect(hint.row, inInclusiveRange(0, 5));
      expect(hint.col, inInclusiveRange(0, 5));
      // 강조 행/열 포함
      expect(hint.highlightRows, contains(hint.row));
      expect(hint.highlightCols, contains(hint.col));
    });

    test('level 2: 후보 값 반환', () {
      final hint = BinairoHintEngine.getHint(puzzle, solution, level: 2);
      expect(hint, isNotNull);
      expect(hint!.level, 2);
      // 후보 목록이 비어있지 않음
      expect(hint.candidates, isNotEmpty);
      // 후보는 0 또는 1만 포함
      for (final c in hint.candidates) {
        expect(c == 0 || c == 1, true);
      }
    });

    test('level 3: 기법 설명 문자열 반환', () {
      final hint = BinairoHintEngine.getHint(puzzle, solution, level: 3);
      expect(hint, isNotNull);
      expect(hint!.level, 3);
      // 기법 설명이 비어있지 않음
      expect(hint.technique, isNotNull);
      expect(hint.technique!.isNotEmpty, true);
      expect(hint.message.isNotEmpty, true);
    });

    test('level 4: 정답 값 반환', () {
      final hint = BinairoHintEngine.getHint(puzzle, solution, level: 4);
      expect(hint, isNotNull);
      expect(hint!.level, 4);
      // 정답 값은 0 또는 1
      expect(hint.value, isNotNull);
      expect(hint.value == 0 || hint.value == 1, true);
    });

    test('힌트가 실제 솔루션과 일치', () {
      // level 4 힌트의 정답 값이 솔루션과 일치하는지 검증
      final hint = BinairoHintEngine.getHint(puzzle, solution, level: 4);
      expect(hint, isNotNull);
      final solutionValue = solution.getValue(hint!.row, hint.col);
      expect(hint.value, solutionValue);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 통합 테스트
  // ════════════════════════════════════════════════════════════════════
  group('통합', () {
    test('생성 → 풀이 → 완료 전체 사이클', () {
      // 퍼즐 생성
      final genResult = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 123,
      );
      expect(genResult, isNotNull);

      // 퍼즐 풀이
      final solved = BinairoSolver.solve(genResult!.puzzle);
      expect(solved, isNotNull);
      expect(solved!.isComplete, true);
      expect(BinairoSolver.isComplete(solved), true);

      // 풀이 결과가 원래 솔루션과 동일한지
      expect(solved.cells, genResult.solution.cells);
    });

    test('100회 생성 시 모두 유일해 (여러 난이도)', () {
      // 다양한 난이도로 100회 생성하여 모두 유일해인지 검증
      var successCount = 0;
      for (var i = 0; i < 100; i++) {
        // 난이도 0~2, 크기 6~8 변경하며 테스트
        final size = (i % 2 == 0) ? 6 : 8;
        final difficulty = i % 3; // 0, 1, 2
        final result = BinairoGenerator.generate(
          size: size,
          difficulty: difficulty,
          seed: i * 7 + 13,
        );
        if (result != null) {
          expect(BinairoSolver.hasUniqueSolution(result.puzzle), true,
              reason: '시드=${i * 7 + 13}, size=$size, diff=$difficulty');
          successCount++;
        }
      }
      // 대부분의 생성이 성공해야 함
      expect(successCount, greaterThanOrEqualTo(90));
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('Board 직렬화 후 풀이 가능', () {
      // 생성된 퍼즐을 JSON으로 직렬화 → 역직렬화 → 풀이
      final genResult = BinairoGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 456,
      );
      expect(genResult, isNotNull);

      // 직렬화 라운드트립
      final json = genResult!.puzzle.toJson();
      final restored = BinairoBoard.fromJson(json);

      // 복원된 보드를 풀이
      final solved = BinairoSolver.solve(restored);
      expect(solved, isNotNull);
      expect(solved!.isComplete, true);
      // 풀이 결과가 원래 솔루션과 동일한지
      expect(solved.cells, genResult.solution.cells);
    });

    test('빈 보드에서 힌트 요청', () {
      // 빈 보드에서도 힌트를 받을 수 있는지 검증
      final emptyBoard = BinairoBoard.empty(6);
      // 솔루션은 빈 보드를 풀어서 구함
      final solution = BinairoSolver.solve(emptyBoard);
      expect(solution, isNotNull);

      final hint = BinairoHintEngine.getHint(emptyBoard, solution!, level: 1);
      expect(hint, isNotNull);
      expect(hint!.row, inInclusiveRange(0, 5));
      expect(hint.col, inInclusiveRange(0, 5));

      // level 4도 요청
      final hint4 = BinairoHintEngine.getHint(emptyBoard, solution, level: 4);
      expect(hint4, isNotNull);
      expect(hint4!.value == 0 || hint4.value == 1, true);
      // 힌트 값이 솔루션과 일치
      expect(hint4.value, solution.getValue(hint4.row, hint4.col));
    });
  });
}
