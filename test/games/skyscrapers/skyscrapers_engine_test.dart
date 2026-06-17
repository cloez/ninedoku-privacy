import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/skyscrapers/engine/skyscrapers_board.dart';
import 'package:ninedoku/games/skyscrapers/engine/skyscrapers_solver.dart';
import 'package:ninedoku/games/skyscrapers/engine/skyscrapers_generator.dart';
import 'package:ninedoku/games/skyscrapers/engine/skyscrapers_hint.dart';

void main() {
  group('SkyscrapersBoard', () {
    test('빈 보드 생성', () {
      final board = SkyscrapersBoard.empty(4);
      expect(board.size, 4);
      expect(board.totalCells, 16);
      expect(board.emptyCellCount, 16);
      expect(board.filledCellCount, 0);
      expect(board.isComplete, false);
    });

    test('셀 값 설정 및 조회', () {
      var board = SkyscrapersBoard.empty(4);
      board = board.setValue(0, 0, 3);
      expect(board.getValue(0, 0), 3);
      expect(board.filledCellCount, 1);
    });

    test('고정 셀은 변경 불가', () {
      final board = SkyscrapersBoard(
        size: 4,
        cells: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        topClues: [0, 0, 0, 0],
        bottomClues: [0, 0, 0, 0],
        leftClues: [0, 0, 0, 0],
        rightClues: [0, 0, 0, 0],
        fixed: {0},
      );
      final modified = board.setValue(0, 0, 2);
      expect(modified.getValue(0, 0), 1); // 변경 안 됨
    });

    test('메모 토글', () {
      var board = SkyscrapersBoard.empty(4);
      board = board.toggleNote(0, 0, 1);
      expect(board.notes[0], {1});

      board = board.toggleNote(0, 0, 3);
      expect(board.notes[0], {1, 3});

      // 이미 있는 숫자 제거
      board = board.toggleNote(0, 0, 1);
      expect(board.notes[0], {3});

      // 마지막 숫자 제거 시 notes에서 삭제
      board = board.toggleNote(0, 0, 3);
      expect(board.notes.containsKey(0), false);
    });

    test('값이 있는 셀에 메모 불가', () {
      var board = SkyscrapersBoard.empty(4);
      board = board.setValue(0, 0, 2);
      final result = board.toggleNote(0, 0, 1);
      expect(result.notes.containsKey(0), false);
    });

    test('값 설정 시 메모 제거', () {
      var board = SkyscrapersBoard.empty(4);
      board = board.toggleNote(0, 0, 1);
      board = board.toggleNote(0, 0, 2);
      expect(board.notes[0], {1, 2});

      board = board.setValue(0, 0, 3);
      expect(board.notes.containsKey(0), false);
      expect(board.getValue(0, 0), 3);
    });

    test('JSON 직렬화/역직렬화', () {
      var board = SkyscrapersBoard(
        size: 4,
        cells: [1, 2, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        topClues: [1, 3, 2, 4],
        bottomClues: [4, 2, 3, 1],
        leftClues: [1, 0, 3, 0],
        rightClues: [0, 2, 0, 4],
        fixed: {0, 1, 2, 3},
      );

      final json = board.toJson();
      final restored = SkyscrapersBoard.fromJson(json);

      expect(restored.size, 4);
      expect(restored.getValue(0, 0), 1);
      expect(restored.getValue(0, 3), 4);
      expect(restored.topClues, [1, 3, 2, 4]);
      expect(restored.bottomClues, [4, 2, 3, 1]);
      expect(restored.leftClues, [1, 0, 3, 0]);
      expect(restored.rightClues, [0, 2, 0, 4]);
      expect(restored.fixed, {0, 1, 2, 3});
    });

    test('깊은 복사', () {
      final board = SkyscrapersBoard.empty(4);
      final copy = board.copyWith();
      expect(copy.size, board.size);
      expect(copy == board, true);
    });

    test('toString 출력', () {
      final board = SkyscrapersBoard(
        size: 4,
        cells: [2, 1, 4, 3, 3, 4, 1, 2, 4, 3, 2, 1, 1, 2, 3, 4],
        topClues: [2, 3, 1, 2],
        bottomClues: [3, 2, 4, 1],
        leftClues: [2, 2, 1, 4],
        rightClues: [2, 3, 4, 1],
        fixed: {},
      );
      final str = board.toString();
      expect(str.isNotEmpty, true);
    });
  });

  group('SkyscrapersSolver', () {
    test('visibleCount — 기본 테스트', () {
      expect(SkyscrapersSolver.visibleCount([1, 2, 3, 4]), 4);
      expect(SkyscrapersSolver.visibleCount([4, 3, 2, 1]), 1);
      expect(SkyscrapersSolver.visibleCount([2, 1, 4, 3]), 2);
      expect(SkyscrapersSolver.visibleCount([1, 3, 2, 4]), 3);
    });

    test('visibleCount — 역순', () {
      final line = [2, 1, 4, 3];
      expect(SkyscrapersSolver.visibleCount(line.reversed.toList()), 2);
    });

    test('완성된 유효한 보드 isComplete', () {
      // 유효한 4x4 라틴 방진
      // 2 1 4 3  → left visible: 2(2,4), right visible: 2(3,4→rev:3,4,1,2→2)
      // 3 4 1 2  → left visible: 2(3,4), right visible: 3(2,1,4,3→rev:2,1,4,3→3)
      // 4 3 2 1  → left visible: 1(4), right visible: 4(1,2,3,4→rev)
      // 1 2 3 4  → left visible: 4, right visible: 1
      // top col0: [2,3,4,1]→visible 3   col1: [1,4,3,2]→visible 2
      // col2: [4,1,2,3]→visible 1   col3: [3,2,1,4]→visible 2
      // bottom col0: [1,4,3,2]→visible 3  col1: [2,3,4,1]→visible 3
      // col2: [3,2,1,4]→visible 2   col3: [4,1,2,3]→visible 1
      final board = SkyscrapersBoard(
        size: 4,
        cells: [2, 1, 4, 3, 3, 4, 1, 2, 4, 3, 2, 1, 1, 2, 3, 4],
        topClues: [3, 2, 1, 2],
        bottomClues: [2, 3, 2, 1],
        leftClues: [2, 2, 1, 4],
        rightClues: [2, 2, 4, 1],
        fixed: {},
      );
      expect(SkyscrapersSolver.isComplete(board), true);
    });

    test('미완성 보드는 isComplete false', () {
      final board = SkyscrapersBoard(
        size: 4,
        cells: [2, 1, 4, 3, 3, 4, 1, 2, 4, 3, 0, 1, 1, 2, 3, 4],
        topClues: [3, 2, 1, 2],
        bottomClues: [2, 3, 2, 1],
        leftClues: [2, 2, 1, 4],
        rightClues: [2, 2, 4, 1],
        fixed: {},
      );
      expect(SkyscrapersSolver.isComplete(board), false);
    });

    test('행 중복이 있으면 isComplete false', () {
      final board = SkyscrapersBoard(
        size: 4,
        cells: [2, 2, 4, 3, 3, 4, 1, 2, 4, 3, 2, 1, 1, 1, 3, 4],
        topClues: [0, 0, 0, 0],
        bottomClues: [0, 0, 0, 0],
        leftClues: [0, 0, 0, 0],
        rightClues: [0, 0, 0, 0],
        fixed: {},
      );
      expect(SkyscrapersSolver.isComplete(board), false);
    });

    test('가시성 힌트 위반 시 isComplete false', () {
      final board = SkyscrapersBoard(
        size: 4,
        cells: [2, 1, 4, 3, 3, 4, 1, 2, 4, 3, 2, 1, 1, 2, 3, 4],
        topClues: [1, 0, 0, 0], // 실제는 2이므로 위반
        bottomClues: [0, 0, 0, 0],
        leftClues: [0, 0, 0, 0],
        rightClues: [0, 0, 0, 0],
        fixed: {},
      );
      expect(SkyscrapersSolver.isComplete(board), false);
    });

    test('hasRowColConflict — 중복 감지', () {
      final board = SkyscrapersBoard(
        size: 4,
        cells: [2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        topClues: [0, 0, 0, 0],
        bottomClues: [0, 0, 0, 0],
        leftClues: [0, 0, 0, 0],
        rightClues: [0, 0, 0, 0],
        fixed: {},
      );
      expect(SkyscrapersSolver.hasRowColConflict(board, 0, 0), true);
      expect(SkyscrapersSolver.hasRowColConflict(board, 0, 1), true);
    });

    test('hasRowColConflict — 빈 셀은 false', () {
      final board = SkyscrapersBoard.empty(4);
      expect(SkyscrapersSolver.hasRowColConflict(board, 0, 0), false);
    });

    test('solve — 4x4 퍼즐 풀기', () {
      final board = SkyscrapersBoard(
        size: 4,
        cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        topClues: [3, 2, 1, 2],
        bottomClues: [2, 3, 2, 1],
        leftClues: [2, 2, 1, 4],
        rightClues: [2, 2, 4, 1],
        fixed: {},
      );
      final solution = SkyscrapersSolver.solve(board);
      expect(solution, isNotNull);
      expect(solution!.isComplete, true);
      expect(SkyscrapersSolver.isComplete(solution), true);
    });

    test('solve — 고정 셀 유지', () {
      final board = SkyscrapersBoard(
        size: 4,
        cells: [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        topClues: [3, 2, 1, 2],
        bottomClues: [2, 3, 2, 1],
        leftClues: [2, 2, 1, 4],
        rightClues: [2, 2, 4, 1],
        fixed: {0},
      );
      final solution = SkyscrapersSolver.solve(board);
      expect(solution, isNotNull);
      expect(solution!.getValue(0, 0), 2);
    });

    test('hasUniqueSolution — 유일해 검증', () {
      // 모든 힌트를 제공하면 유일해를 가짐
      final board = SkyscrapersBoard(
        size: 4,
        cells: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        topClues: [3, 2, 1, 2],
        bottomClues: [2, 3, 2, 1],
        leftClues: [2, 2, 1, 4],
        rightClues: [2, 2, 4, 1],
        fixed: {},
      );
      expect(SkyscrapersSolver.hasUniqueSolution(board), true);
    });
  });

  group('SkyscrapersGenerator', () {
    test('4x4 입문 퍼즐 생성', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 4);
      expect(result.solution.size, 4);
      expect(SkyscrapersSolver.isComplete(result.solution), true);
      expect(result.puzzle.emptyCellCount, greaterThan(0));
    });

    test('5x5 쉬움 퍼즐 생성', () {
      final result = SkyscrapersGenerator.generate(
        size: 5,
        difficulty: 1,
        seed: 123,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 5);
      expect(SkyscrapersSolver.isComplete(result.solution), true);
    });

    test('6x6 보통 퍼즐 생성', () {
      final result = SkyscrapersGenerator.generate(
        size: 6,
        difficulty: 2,
        seed: 456,
      );
      expect(result, isNotNull);
      expect(result!.puzzle.size, 6);
      expect(SkyscrapersSolver.isComplete(result.solution), true);
    });

    test('같은 시드로 같은 퍼즐 생성 (결정론적)', () {
      final r1 = SkyscrapersGenerator.generate(size: 4, difficulty: 0, seed: 999);
      final r2 = SkyscrapersGenerator.generate(size: 4, difficulty: 0, seed: 999);
      expect(r1, isNotNull);
      expect(r2, isNotNull);
      expect(r1!.solution.cells, r2!.solution.cells);
    });

    test('생성된 퍼즐의 유일해 보장', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 77,
      );
      expect(result, isNotNull);
      expect(SkyscrapersSolver.hasUniqueSolution(result!.puzzle), true);
    });

    test('생성된 퍼즐에 외곽 힌트 존재', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 100,
      );
      expect(result, isNotNull);
      // 입문 난이도에서는 힌트가 많아야 함
      final totalClues = result!.puzzle.topClues.where((c) => c > 0).length +
          result.puzzle.bottomClues.where((c) => c > 0).length +
          result.puzzle.leftClues.where((c) => c > 0).length +
          result.puzzle.rightClues.where((c) => c > 0).length;
      expect(totalClues, greaterThan(0));
    });
  });

  group('SkyscrapersHintEngine', () {
    test('레벨 1 — 행/열 강조', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);

      final hint = SkyscrapersHintEngine.getHint(
        result!.puzzle,
        result.solution,
        level: 1,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      expect(hint.highlightRows, isNotEmpty);
      expect(hint.highlightCols, isNotEmpty);
      expect(hint.message.isNotEmpty, true);
    });

    test('레벨 2 — 후보 값 표시', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);

      final hint = SkyscrapersHintEngine.getHint(
        result!.puzzle,
        result.solution,
        level: 2,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 2);
      expect(hint.candidates, isNotEmpty);
    });

    test('레벨 3 — 기법 설명', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);

      final hint = SkyscrapersHintEngine.getHint(
        result!.puzzle,
        result.solution,
        level: 3,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 3);
      expect(hint.technique, isNotNull);
    });

    test('레벨 4 — 정답 공개', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);

      final hint = SkyscrapersHintEngine.getHint(
        result!.puzzle,
        result.solution,
        level: 4,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 4);
      expect(hint.value, isNotNull);
      // 정답 값이 실제 해답과 일치
      expect(hint.value, result.solution.getValue(hint.row, hint.col));
    });

    test('getCandidates — 후보 값 정확성', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);

      // 빈 셀 찾기
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 4; c++) {
          if (result!.puzzle.getValue(r, c) == 0) {
            final candidates = SkyscrapersHintEngine.getCandidates(
              result.puzzle, r, c,
            );
            // 정답 값이 후보에 포함되어야 함
            final answer = result.solution.getValue(r, c);
            expect(candidates.contains(answer), true,
                reason: '정답 $answer이 후보 $candidates에 포함되어야 함 ($r, $c)');
            return; // 첫 번째 빈 셀만 확인
          }
        }
      }
    });

    test('완성된 보드에서 힌트 없음', () {
      final result = SkyscrapersGenerator.generate(
        size: 4,
        difficulty: 0,
        seed: 42,
      );
      expect(result, isNotNull);

      final hint = SkyscrapersHintEngine.getHint(
        result!.solution,
        result.solution,
        level: 1,
      );
      expect(hint, isNull);
    });
  });
}
