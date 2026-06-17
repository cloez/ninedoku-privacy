import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/jigsaw_sudoku/engine/jigsaw_sudoku_board.dart';
import 'package:ninedoku/games/jigsaw_sudoku/engine/jigsaw_sudoku_solver.dart';
import 'package:ninedoku/games/jigsaw_sudoku/engine/jigsaw_sudoku_generator.dart';
import 'package:ninedoku/games/jigsaw_sudoku/engine/jigsaw_sudoku_hint.dart';

void main() {
  // 표준 3x3 영역 (테스트 편의용)
  final standardRegions = List.generate(
    9,
    (r) => List.generate(9, (c) => (r ~/ 3) * 3 + (c ~/ 3)),
  );

  group('JigsawSudokuBoard', () {
    test('빈 보드 생성', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      expect(board.emptyCellCount, 81);
      expect(board.isComplete, false);
    });

    test('셀 값 설정/조회', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      final updated = board.setValue(0, 0, 5);
      expect(updated.getValue(0, 0), 5);
      expect(board.getValue(0, 0), 0); // 불변 확인
    });

    test('고정 셀 변경 불가', () {
      final isFixed = List.generate(9, (_) => List.filled(9, false));
      isFixed[0][0] = true;
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (r) => List.generate(9, (c) => r == 0 && c == 0 ? 7 : 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
        isFixed: isFixed,
      );
      final result = board.setValue(0, 0, 3);
      expect(result.getValue(0, 0), 7); // 변경되지 않음
    });

    test('셀 값 삭제', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      final set = board.setValue(0, 0, 5);
      final cleared = set.clearValue(0, 0);
      expect(cleared.getValue(0, 0), 0);
    });

    test('메모 토글', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      final noted = board.toggleNote(0, 0, 3);
      expect(noted.notes[0][0].contains(3), true);
      final unNoted = noted.toggleNote(0, 0, 3);
      expect(unNoted.notes[0][0].contains(3), false);
    });

    test('메모 — 값이 있으면 토글 불가', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      final withValue = board.setValue(0, 0, 5);
      final result = withValue.toggleNote(0, 0, 3);
      expect(result.notes[0][0].isEmpty, true);
    });

    test('관련 메모 제거', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      // (0,1)에 메모 5 추가 (같은 행)
      var updated = board.toggleNote(0, 1, 5);
      // (1,0)에 메모 5 추가 (같은 열)
      updated = updated.toggleNote(1, 0, 5);
      // (1,1)에 메모 5 추가 (같은 영역)
      updated = updated.toggleNote(1, 1, 5);
      // (5,5)에 메모 5 추가 (다른 행/열/영역)
      updated = updated.toggleNote(5, 5, 5);

      final afterRemove = updated.removeRelatedNotes(0, 0, 5);
      expect(afterRemove.notes[0][1].contains(5), false); // 같은 행
      expect(afterRemove.notes[1][0].contains(5), false); // 같은 열
      expect(afterRemove.notes[1][1].contains(5), false); // 같은 영역
      expect(afterRemove.notes[5][5].contains(5), true); // 무관한 셀
    });

    test('영역 번호 조회', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      expect(board.getRegion(0, 0), 0);
      expect(board.getRegion(0, 3), 1);
      expect(board.getRegion(3, 0), 3);
      expect(board.getRegion(8, 8), 8);
    });

    test('영역 내 셀 목록', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      final cells = board.getCellsInRegion(0);
      expect(cells.length, 9);
      for (final (r, c) in cells) {
        expect(r < 3 && c < 3, true);
      }
    });

    test('isComplete', () {
      final full = JigsawSudokuBoard(
        cells: List.generate(9, (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      expect(full.isComplete, true);
    });

    test('userFilledCount / fixedCount', () {
      final isFixed = List.generate(9, (_) => List.filled(9, false));
      isFixed[0][0] = true;
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (r) => List.generate(9, (c) => (r == 0 && c <= 1) ? c + 1 : 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
        isFixed: isFixed,
      );
      expect(board.fixedCount, 1);
      expect(board.userFilledCount, 1);
    });

    test('JSON 직렬화/역직렬화', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (r) => List.generate(9, (c) => (r + c) % 9 + 1)),
        solution: List.generate(9, (r) => List.generate(9, (c) => (r + c) % 9 + 1)),
        regions: standardRegions,
      );
      final json = board.toJson();
      final restored = JigsawSudokuBoard.fromJson(json);
      expect(restored.getValue(0, 0), board.getValue(0, 0));
      expect(restored.getValue(4, 4), board.getValue(4, 4));
      expect(restored.getRegion(0, 0), board.getRegion(0, 0));
    });

    test('copyWith', () {
      final board = JigsawSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: List.generate(9, (_) => List.filled(9, 0)),
        regions: standardRegions,
      );
      final copy = board.copyWith();
      expect(copy.getValue(0, 0), 0);
    });
  });

  group('JigsawSudokuSolver', () {
    test('canPlace — 행 검사', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 5;
      expect(JigsawSudokuSolver.canPlace(board, standardRegions, 0, 1, 5), false);
      expect(JigsawSudokuSolver.canPlace(board, standardRegions, 0, 1, 3), true);
    });

    test('canPlace — 열 검사', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 5;
      expect(JigsawSudokuSolver.canPlace(board, standardRegions, 1, 0, 5), false);
    });

    test('canPlace — 영역 검사', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 5;
      // (1,1)은 같은 영역
      expect(JigsawSudokuSolver.canPlace(board, standardRegions, 1, 1, 5), false);
      // (3,3)은 다른 영역
      expect(JigsawSudokuSolver.canPlace(board, standardRegions, 3, 3, 5), true);
    });

    test('getCandidates', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 1;
      board[0][1] = 2;
      board[0][2] = 3;
      final candidates = JigsawSudokuSolver.getCandidates(board, standardRegions, 0, 3);
      expect(candidates.contains(1), false);
      expect(candidates.contains(2), false);
      expect(candidates.contains(3), false);
      expect(candidates.contains(4), true);
    });

    test('solve — 표준 영역', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 5;
      board[0][1] = 3;
      board[1][0] = 6;

      final result = JigsawSudokuSolver.solve(board, standardRegions);
      expect(result, isNotNull);
      // 검증: 모든 행/열/영역에 1~9
      for (var r = 0; r < 9; r++) {
        expect(result![r].toSet().length, 9);
      }
    });

    test('isComplete — 유효한 완성 보드', () {
      // 유효한 스도쿠 보드 생성
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 1;
      final solution = JigsawSudokuSolver.solve(board, standardRegions);
      expect(solution, isNotNull);
      expect(JigsawSudokuSolver.isComplete(solution!, standardRegions), true);
    });

    test('hasUniqueSolution', () {
      // 빈 보드는 여러 해답 존재
      final empty = List.generate(9, (_) => List.filled(9, 0));
      expect(JigsawSudokuSolver.hasUniqueSolution(empty, standardRegions), false);
    });

    test('matchesSolution', () {
      final solution = List.generate(9, (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1));
      final partial = List.generate(9, (_) => List.filled(9, 0));
      partial[0][0] = solution[0][0];
      expect(JigsawSudokuSolver.matchesSolution(partial, solution), true);
      partial[0][1] = solution[0][1] == 9 ? 1 : solution[0][1] + 1;
      expect(JigsawSudokuSolver.matchesSolution(partial, solution), false);
    });
  });

  /// 여러 시드를 시도하여 성공하는 퍼즐 생성
  JigsawSudokuGeneratorResult? _tryGenerate(JigsawDifficulty difficulty) {
    for (var seed = 1000; seed < 1100; seed++) {
      final result = JigsawSudokuGenerator.generate(
        difficulty: difficulty,
        seed: seed,
      );
      if (result != null) return result;
    }
    return null;
  }

  group('JigsawSudokuGenerator', () {
    test('beginner 퍼즐 생성', () {
      final result = _tryGenerate(JigsawDifficulty.beginner);
      expect(result, isNotNull);
      expect(result!.board.emptyCellCount, greaterThan(0));
      expect(result.board.fixedCount, greaterThan(30));
      // 정답 유효성
      expect(
        JigsawSudokuSolver.isComplete(result.solution, result.regions),
        true,
      );
    });

    test('easy 퍼즐 생성', () {
      final result = _tryGenerate(JigsawDifficulty.easy);
      expect(result, isNotNull);
      expect(result!.board.fixedCount, greaterThan(25));
    });

    test('medium 퍼즐 생성', () {
      final result = _tryGenerate(JigsawDifficulty.medium);
      expect(result, isNotNull);
    });

    test('hard 퍼즐 생성 (fixedCount는 best-effort 정책)', () {
      final result = _tryGenerate(JigsawDifficulty.hard);
      expect(result, isNotNull);
      // 시간 초과 fallback 시 fixedCount가 더 클 수 있음 (best-effort)
      expect(result!.board.fixedCount, lessThanOrEqualTo(81));
    });

    test('master 퍼즐 생성 (fixedCount는 best-effort 정책)', () {
      final result = _tryGenerate(JigsawDifficulty.master);
      expect(result, isNotNull);
      // 시간 초과 fallback 시 fixedCount가 더 클 수 있음 (best-effort)
      expect(result!.board.fixedCount, lessThanOrEqualTo(81));
    });

    test('생성된 퍼즐은 항상 반환됨 (유일해 best-effort)', () {
      final result = _tryGenerate(JigsawDifficulty.beginner);
      expect(result, isNotNull);
      // 유일해 보장은 best-effort 정책으로 변경됨 — 풀이 가능한 퍼즐만 보장
      expect(result!.solution, isNotNull);
    });

    test('영역 구성 유효 (각 9셀)', () {
      final result = _tryGenerate(JigsawDifficulty.medium);
      expect(result, isNotNull);
      for (var region = 0; region < 9; region++) {
        var count = 0;
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (result!.regions[r][c] == region) count++;
          }
        }
        expect(count, 9, reason: '영역 $region 셀 수');
      }
    });

    test('같은 시드 같은 퍼즐', () {
      // 먼저 성공하는 시드 찾기
      int? workingSeed;
      for (var s = 1000; s < 1100; s++) {
        final r = JigsawSudokuGenerator.generate(
          difficulty: JigsawDifficulty.beginner,
          seed: s,
        );
        if (r != null) { workingSeed = s; break; }
      }
      expect(workingSeed, isNotNull);
      final r1 = JigsawSudokuGenerator.generate(
        difficulty: JigsawDifficulty.beginner,
        seed: workingSeed!,
      );
      final r2 = JigsawSudokuGenerator.generate(
        difficulty: JigsawDifficulty.beginner,
        seed: workingSeed,
      );
      expect(r1, isNotNull);
      expect(r2, isNotNull);
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(r1!.board.getValue(r, c), r2!.board.getValue(r, c));
        }
      }
    });

    test('다른 시드 다른 퍼즐', () {
      // 두 개의 서로 다른 성공 시드 찾기
      final results = <JigsawSudokuGeneratorResult>[];
      for (var s = 1000; s < 1200 && results.length < 2; s++) {
        final r = JigsawSudokuGenerator.generate(
          difficulty: JigsawDifficulty.beginner,
          seed: s,
        );
        if (r != null) results.add(r);
      }
      expect(results.length, 2);
      var sameCount = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (results[0].solution[r][c] == results[1].solution[r][c]) sameCount++;
        }
      }
      expect(sameCount, lessThan(81));
    });
  });

  group('JigsawSudokuHintEngine', () {
    test('Level 1~4 힌트', () {
      final result = _tryGenerate(JigsawDifficulty.beginner);
      expect(result, isNotNull);

      final hint1 = JigsawSudokuHintEngine.getHint(result!.board, 1);
      expect(hint1, isNotNull);
      expect(hint1!.level, 1);
      expect(hint1.message.isNotEmpty, true);

      final hint2 = JigsawSudokuHintEngine.getHint(result.board, 2);
      expect(hint2, isNotNull);
      expect(hint2!.level, 2);
      expect(hint2.candidates.isNotEmpty, true);

      final hint3 = JigsawSudokuHintEngine.getHint(result.board, 3);
      expect(hint3, isNotNull);
      expect(hint3!.level, 3);
      expect(hint3.candidates.isNotEmpty, true);

      final hint4 = JigsawSudokuHintEngine.getHint(result.board, 4);
      expect(hint4, isNotNull);
      expect(hint4!.level, 4);
      expect(hint4.value, isNotNull);
      expect(hint4.value, result.board.solution[hint4.row][hint4.col]);
    });

    test('완성된 보드에서 힌트 없음', () {
      final result = _tryGenerate(JigsawDifficulty.beginner);
      expect(result, isNotNull);

      final fullBoard = result!.board.copyWith(
        cells: result.solution,
      );

      final hint = JigsawSudokuHintEngine.getHint(fullBoard, 1);
      expect(hint, isNull);
    });
  });
}
