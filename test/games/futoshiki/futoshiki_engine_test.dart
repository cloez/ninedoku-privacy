import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/futoshiki/engine/futoshiki_board.dart';
import 'package:ninedoku/games/futoshiki/engine/futoshiki_solver.dart';
import 'package:ninedoku/games/futoshiki/engine/futoshiki_generator.dart';
import 'package:ninedoku/games/futoshiki/engine/futoshiki_hint.dart';

void main() {
  group('FutoshikiBoard', () {
    test('빈 보드 생성', () {
      final board = FutoshikiBoard.empty(4);
      expect(board.size, 4);
      expect(board.totalCells, 16);
      expect(board.emptyCellCount, 16);
      expect(board.filledCellCount, 0);
      expect(board.isComplete, false);
    });

    test('셀 값 설정 및 조회', () {
      var board = FutoshikiBoard.empty(4);
      board = board.setValue(0, 0, 3);
      expect(board.getValue(0, 0), 3);
      expect(board.filledCellCount, 1);
    });

    test('고정 셀은 변경 불가', () {
      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {0},
      );
      final modified = board.setValue(0, 0, 2);
      expect(modified.getValue(0, 0), 1); // 변경 안 됨
    });

    test('수평 부등호 조회', () {
      final hConstraints = List<int>.filled(12, 0);
      hConstraints[0] = 1; // (0,0) < (0,1)
      hConstraints[1] = 2; // (0,1) > (0,2)

      final board = FutoshikiBoard(
        size: 4,
        cells: List.filled(16, 0),
        horizontalConstraints: hConstraints,
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );

      expect(board.getHorizontalConstraint(0, 0), 1);
      expect(board.getHorizontalConstraint(0, 1), 2);
      expect(board.getHorizontalConstraint(0, 2), 0);
    });

    test('수직 부등호 조회', () {
      final vConstraints = List<int>.filled(12, 0);
      vConstraints[0] = 1; // (0,0) < (1,0) — 위 < 아래
      vConstraints[1] = 2; // (0,1) > (1,1)

      final board = FutoshikiBoard(
        size: 4,
        cells: List.filled(16, 0),
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: vConstraints,
        fixed: {},
      );

      expect(board.getVerticalConstraint(0, 0), 1);
      expect(board.getVerticalConstraint(0, 1), 2);
    });

    test('메모 토글', () {
      var board = FutoshikiBoard.empty(4);
      board = board.toggleNote(0, 0, 1);
      expect(board.notes[0], {1});

      board = board.toggleNote(0, 0, 3);
      expect(board.notes[0], {1, 3});

      // 이미 있는 숫자 제거
      board = board.toggleNote(0, 0, 1);
      expect(board.notes[0], {3});
    });

    test('값 설정 시 메모 제거', () {
      var board = FutoshikiBoard.empty(4);
      board = board.toggleNote(0, 0, 1);
      board = board.toggleNote(0, 0, 2);
      expect(board.notes.containsKey(0), true);

      board = board.setValue(0, 0, 3);
      expect(board.notes.containsKey(0), false);
    });

    test('JSON 직렬화/역직렬화', () {
      var board = FutoshikiBoard.empty(4);
      board = board.setValue(0, 0, 1);
      board = board.toggleNote(1, 1, 3);

      final json = board.toJson();
      final restored = FutoshikiBoard.fromJson(json);

      expect(restored.size, 4);
      expect(restored.getValue(0, 0), 1);
      expect(restored.notes[5], {3}); // (1,1) = index 5
    });

    test('toString 출력', () {
      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0],
        verticalConstraints: [1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0],
        fixed: {},
      );
      final str = board.toString();
      expect(str.contains('<'), true);
      expect(str.contains('>'), true);
    });

    test('동등성 비교', () {
      final board1 = FutoshikiBoard(
        size: 4,
        cells: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      final board2 = FutoshikiBoard(
        size: 4,
        cells: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(board1, equals(board2));
    });

    test('copyWith', () {
      final board = FutoshikiBoard.empty(4);
      final copy = board.copyWith(size: 4);
      expect(copy.size, 4);
      expect(copy.emptyCellCount, 16);
    });
  });

  group('FutoshikiSolver', () {
    test('완성된 4x4 라틴 방진 검증', () {
      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(FutoshikiSolver.isComplete(board), true);
    });

    test('행 중복 있는 보드는 incomplete', () {
      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 1, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(FutoshikiSolver.isComplete(board), false);
    });

    test('부등호 위반 검출', () {
      // 1 > 2 인데 부등호는 < (1 < 2)
      final hConstraints = List<int>.filled(12, 0);
      hConstraints[0] = 2; // (0,0) > (0,1), 즉 왼쪽이 커야 함

      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: hConstraints,
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      // 1 > 2 는 거짓이므로 완전하지 않음
      expect(FutoshikiSolver.isComplete(board), false);
    });

    test('부등호 만족 보드', () {
      final hConstraints = List<int>.filled(12, 0);
      hConstraints[0] = 1; // (0,0) < (0,1), 즉 1 < 2 → 만족

      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: hConstraints,
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(FutoshikiSolver.isComplete(board), true);
    });

    test('간단한 퍼즐 풀기', () {
      // 3x3 — 아, 4 이상만. 4x4로 테스트
      // 대부분 채워진 4x4 퍼즐
      final board = FutoshikiBoard(
        size: 4,
        cells: [0, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
      );
      final solution = FutoshikiSolver.solve(board);
      expect(solution, isNotNull);
      expect(solution!.getValue(0, 0), 1);
    });

    test('유일해 검증', () {
      // 하나만 빈칸인 퍼즐 → 유일해
      final board = FutoshikiBoard(
        size: 4,
        cells: [0, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(FutoshikiSolver.hasUniqueSolution(board), true);
    });

    test('isValid — 부분 검증 (빈칸 허용)', () {
      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(FutoshikiSolver.isValid(board), true);
    });

    test('isValid — 중복 있으면 false', () {
      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(FutoshikiSolver.isValid(board), false);
    });

    test('hasRowColConflict 검출', () {
      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        horizontalConstraints: List.filled(12, 0),
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(FutoshikiSolver.hasRowColConflict(board, 0, 0), true);
      expect(FutoshikiSolver.hasRowColConflict(board, 0, 1), true);
    });

    test('hasConstraintViolation 검출', () {
      final hConstraints = List<int>.filled(12, 0);
      hConstraints[0] = 2; // (0,0) > (0,1), 하지만 1 < 2 → 위반

      final board = FutoshikiBoard(
        size: 4,
        cells: [1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        horizontalConstraints: hConstraints,
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );
      expect(FutoshikiSolver.hasConstraintViolation(board, 0, 0), true);
    });
  });

  group('FutoshikiGenerator', () {
    test('4x4 입문 퍼즐 생성', () {
      final result = FutoshikiGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 4);
      expect(result.solution.size, 4);
      expect(result.puzzle.emptyCellCount, greaterThan(0));
      expect(FutoshikiSolver.isComplete(result.solution), true);
    });

    test('5x5 쉬움 퍼즐 생성', () {
      final result = FutoshikiGenerator.generate(
        size: 5,
        difficulty: 1,
        seed: 123,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 5);
      expect(FutoshikiSolver.isComplete(result.solution), true);
    });

    test('6x6 보통 퍼즐 생성', () {
      final result = FutoshikiGenerator.generate(
        size: 6,
        difficulty: 2,
        seed: 456,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 6);
    });

    test('생성된 퍼즐은 유일해', () {
      final result = FutoshikiGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 789,
      );
      expect(result, isNotNull);
      expect(FutoshikiSolver.hasUniqueSolution(result!.puzzle), true);
    });

    test('생성된 퍼즐에 부등호 포함', () {
      final result = FutoshikiGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 100,
      );
      expect(result, isNotNull);
      // 부등호가 최소 1개 이상
      final hCount =
          result!.puzzle.horizontalConstraints.where((c) => c != 0).length;
      final vCount =
          result.puzzle.verticalConstraints.where((c) => c != 0).length;
      expect(hCount + vCount, greaterThan(0));
    });

    test('같은 시드로 같은 퍼즐 생성', () {
      final r1 = FutoshikiGenerator.generate(size: 4, difficulty: 0, seed: 42);
      final r2 = FutoshikiGenerator.generate(size: 4, difficulty: 0, seed: 42);
      expect(r1, isNotNull);
      expect(r2, isNotNull);
      expect(r1!.puzzle, equals(r2!.puzzle));
    });

    test('다른 시드로 다른 퍼즐 생성', () {
      final r1 = FutoshikiGenerator.generate(size: 4, difficulty: 0, seed: 1);
      final r2 = FutoshikiGenerator.generate(size: 4, difficulty: 0, seed: 2);
      expect(r1, isNotNull);
      expect(r2, isNotNull);
      // 다른 퍼즐일 가능성이 높음 (이론적으로 같을 수 있지만 매우 드물다)
      expect(r1!.solution != r2!.solution, true);
    });
  });

  group('FutoshikiHintEngine', () {
    late FutoshikiBoard solution;
    late FutoshikiBoard puzzle;

    setUp(() {
      // 간단한 4x4 완성 보드
      solution = FutoshikiBoard(
        size: 4,
        cells: [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        verticalConstraints: List.filled(12, 0),
        fixed: {},
      );

      // 하나만 빈칸
      puzzle = FutoshikiBoard(
        size: 4,
        cells: [0, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1],
        horizontalConstraints: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        verticalConstraints: List.filled(12, 0),
        fixed: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
      );
    });

    test('Level 1: 행/열 강조', () {
      final hint = FutoshikiHintEngine.getHint(puzzle, solution, level: 1);
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      expect(hint.row, 0);
      expect(hint.col, 0);
      expect(hint.highlightRows, [0]);
      expect(hint.highlightCols, [0]);
    });

    test('Level 2: 후보 표시', () {
      final hint = FutoshikiHintEngine.getHint(puzzle, solution, level: 2);
      expect(hint, isNotNull);
      expect(hint!.level, 2);
      expect(hint.candidates, contains(1));
    });

    test('Level 3: 기법 설명', () {
      final hint = FutoshikiHintEngine.getHint(puzzle, solution, level: 3);
      expect(hint, isNotNull);
      expect(hint!.level, 3);
      expect(hint.technique, isNotNull);
      expect(hint.message.isNotEmpty, true);
    });

    test('Level 4: 정답 공개', () {
      final hint = FutoshikiHintEngine.getHint(puzzle, solution, level: 4);
      expect(hint, isNotNull);
      expect(hint!.level, 4);
      expect(hint.value, 1);
    });

    test('완성 보드에서는 힌트 없음', () {
      final hint = FutoshikiHintEngine.getHint(solution, solution, level: 1);
      expect(hint, isNull);
    });

    test('getCandidates — 행/열 중복 소거', () {
      // (0,0)은 빈칸, 행에 2,3,4가 있으므로 1만 가능
      final candidates = FutoshikiHintEngine.getCandidates(puzzle, 0, 0);
      expect(candidates, [1]);
    });

    test('getCandidates — 부등호 제약 적용', () {
      // 부등호: (0,0) < (0,1)=2, 이므로 (0,0)은 1만 가능
      final candidates = FutoshikiHintEngine.getCandidates(puzzle, 0, 0);
      expect(candidates.every((v) => v < 2), true);
    });
  });
}
