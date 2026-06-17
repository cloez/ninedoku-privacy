import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_board.dart';
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_solver.dart';
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_generator.dart';
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_hint.dart';

void main() {
  // === KillerSudokuBoard 테스트 ===
  group('KillerSudokuBoard', () {
    late KillerSudokuBoard board;
    late List<List<int>> sampleSolution;
    late List<Cage> sampleCages;

    setUp(() {
      // 간단한 완성 보드
      sampleSolution = [
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

      sampleCages = [
        Cage(cells: [(0, 0), (0, 1)], sum: 8), // 5+3
        Cage(cells: [(0, 2), (0, 3)], sum: 10), // 4+6
      ];

      board = KillerSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: sampleSolution,
        cages: sampleCages,
      );
    });

    test('초기 보드는 빈칸으로 시작', () {
      expect(board.emptyCellCount, 81);
      expect(board.isComplete, false);
    });

    test('getValue로 셀 조회', () {
      expect(board.getValue(0, 0), 0);
    });

    test('setValue로 값 설정', () {
      final newBoard = board.setValue(0, 0, 5);
      expect(newBoard.getValue(0, 0), 5);
      expect(newBoard.emptyCellCount, 80);
    });

    test('clearValue로 값 삭제', () {
      final filled = board.setValue(0, 0, 5);
      final cleared = filled.clearValue(0, 0);
      expect(cleared.getValue(0, 0), 0);
    });

    test('고정 셀은 변경 불가', () {
      final isFixed = List.generate(9, (_) => List.filled(9, false));
      isFixed[0][0] = true;
      final fixedBoard = KillerSudokuBoard(
        cells: sampleSolution,
        solution: sampleSolution,
        cages: sampleCages,
        isFixed: isFixed,
      );
      final result = fixedBoard.setValue(0, 0, 1);
      expect(result.getValue(0, 0), 5); // 변경 안 됨
    });

    test('메모 토글', () {
      final withNote = board.toggleNote(0, 0, 5);
      expect(withNote.notes[0][0].contains(5), true);
      final without = withNote.toggleNote(0, 0, 5);
      expect(without.notes[0][0].contains(5), false);
    });

    test('값 설정 시 메모 클리어', () {
      final withNote = board.toggleNote(0, 0, 5);
      final withValue = withNote.setValue(0, 0, 3);
      expect(withValue.notes[0][0].isEmpty, true);
    });

    test('getCageAt으로 케이지 조회', () {
      final cage = board.getCageAt(0, 0);
      expect(cage, isNotNull);
      expect(cage!.sum, 8);
    });

    test('getCageAt — 케이지 없는 셀', () {
      final cage = board.getCageAt(5, 5);
      expect(cage, isNull);
    });

    test('Cage toJson/fromJson 왕복', () {
      final cage = Cage(cells: [(0, 0), (0, 1)], sum: 8);
      final json = cage.toJson();
      final restored = Cage.fromJson(json);
      expect(restored.sum, 8);
      expect(restored.cells.length, 2);
      expect(restored.cells[0], (0, 0));
    });

    test('KillerSudokuBoard toJson/fromJson 왕복', () {
      final filled = board.setValue(3, 3, 7);
      final json = filled.toJson();
      final restored = KillerSudokuBoard.fromJson(json);
      expect(restored.getValue(3, 3), 7);
      expect(restored.cages.length, sampleCages.length);
      expect(restored.solution[0][0], 5);
    });

    test('fixedCount 계산', () {
      final isFixed = List.generate(9, (_) => List.filled(9, false));
      isFixed[0][0] = true;
      isFixed[1][1] = true;
      final fixedBoard = KillerSudokuBoard(
        cells: List.generate(9, (_) => List.filled(9, 0)),
        solution: sampleSolution,
        cages: sampleCages,
        isFixed: isFixed,
      );
      expect(fixedBoard.fixedCount, 2);
    });

    test('removeRelatedNotes로 관련 메모 제거', () {
      var b = board;
      // (0,2)에 메모 4 추가 — 같은 행
      b = b.toggleNote(0, 2, 4);
      // (2,0)에 메모 4 추가 — 같은 열
      b = b.toggleNote(2, 0, 4);
      // (0,0)에 값 4 설정 후 관련 메모 제거
      b = b.removeRelatedNotes(0, 0, 4);
      expect(b.notes[0][2].contains(4), false);
      expect(b.notes[2][0].contains(4), false);
    });

    test('copyWith 깊은 복사', () {
      final filled = board.setValue(0, 0, 5);
      final copy = filled.copyWith();
      expect(copy.getValue(0, 0), 5);
    });
  });

  // === KillerSudokuSolver 테스트 ===
  group('KillerSudokuSolver', () {
    late List<List<int>> validBoard;
    late List<Cage> fullCages;

    setUp(() {
      validBoard = [
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

      // 전체 보드를 커버하는 간단한 케이지 (각 행을 2~3셀씩 분할)
      fullCages = [];
      for (var r = 0; r < 9; r++) {
        // 각 행을 3개의 3셀 케이지로 분할
        for (var startC = 0; startC < 9; startC += 3) {
          final cells = <(int, int)>[];
          var sum = 0;
          for (var c = startC; c < startC + 3; c++) {
            cells.add((r, c));
            sum += validBoard[r][c];
          }
          fullCages.add(Cage(cells: cells, sum: sum));
        }
      }
    });

    test('isComplete — 유효한 완성 보드', () {
      expect(KillerSudokuSolver.isComplete(validBoard, fullCages), true);
    });

    test('isComplete — 빈칸 있으면 false', () {
      final board = List.generate(9, (r) => List<int>.from(validBoard[r]));
      board[0][0] = 0;
      expect(KillerSudokuSolver.isComplete(board, fullCages), false);
    });

    test('canPlace — 유효한 배치', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      expect(
        KillerSudokuSolver.canPlace(board, fullCages, 0, 0, 5),
        true,
      );
    });

    test('canPlace — 행 중복', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][1] = 5;
      expect(
        KillerSudokuSolver.canPlace(board, fullCages, 0, 0, 5),
        false,
      );
    });

    test('canPlace — 열 중복', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[1][0] = 5;
      expect(
        KillerSudokuSolver.canPlace(board, fullCages, 0, 0, 5),
        false,
      );
    });

    test('canPlace — 3x3 박스 중복', () {
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[1][1] = 5;
      expect(
        KillerSudokuSolver.canPlace(board, fullCages, 0, 0, 5),
        false,
      );
    });

    test('canPlace — 케이지 내 중복', () {
      final cages = [Cage(cells: [(0, 0), (0, 1), (0, 2)], sum: 12)];
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][1] = 5;
      expect(
        KillerSudokuSolver.canPlace(board, cages, 0, 0, 5),
        false,
      );
    });

    test('canPlace — 케이지 합계 초과', () {
      final cages = [Cage(cells: [(0, 0), (0, 1)], sum: 5)];
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 3;
      // 3 + 5 = 8 > 5이므로 false
      expect(
        KillerSudokuSolver.canPlace(board, cages, 0, 1, 5),
        false,
      );
    });

    test('canPlace — 케이지 합계 정확', () {
      final cages = [Cage(cells: [(0, 0), (0, 1)], sum: 8)];
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 5;
      // 5 + 3 = 8 == 8이므로 true
      expect(
        KillerSudokuSolver.canPlace(board, cages, 0, 1, 3),
        true,
      );
    });

    test('getCandidates — 후보 목록 반환', () {
      final cages = [Cage(cells: [(0, 0), (0, 1)], sum: 8)];
      final board = List.generate(9, (_) => List.filled(9, 0));
      board[0][0] = 5;
      final candidates = KillerSudokuSolver.getCandidates(
        board, cages, 0, 1,
      );
      expect(candidates.contains(3), true); // 5+3=8
      expect(candidates.contains(5), false); // 케이지 중복
    });

    test('solve — 간단한 퍼즐 풀기', () {
      final puzzle = List.generate(9, (r) => List<int>.from(validBoard[r]));
      // 몇 개의 셀만 비우기
      puzzle[0][0] = 0;
      puzzle[0][1] = 0;
      puzzle[1][0] = 0;

      final result = KillerSudokuSolver.solve(puzzle, fullCages);
      expect(result, isNotNull);
      expect(result![0][0], 5);
      expect(result[0][1], 3);
      expect(result[1][0], 6);
    });

    test('matchesSolution — 일치 확인', () {
      final current = List.generate(9, (r) => List<int>.from(validBoard[r]));
      current[0][0] = 0; // 빈칸은 무시
      expect(
        KillerSudokuSolver.matchesSolution(current, validBoard),
        true,
      );
    });

    test('matchesSolution — 불일치 확인', () {
      final current = List.generate(9, (r) => List<int>.from(validBoard[r]));
      current[0][0] = 9; // 5여야 하는데 9
      expect(
        KillerSudokuSolver.matchesSolution(current, validBoard),
        false,
      );
    });
  });

  // === KillerSudokuGenerator 테스트 ===
  group('KillerSudokuGenerator', () {
    test('beginner 난이도 생성', () {
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.beginner,
        seed: 12345,
      );
      expect(result, isNotNull);
      expect(result!.cages.isNotEmpty, true);
      // 모든 81셀이 케이지에 포함되는지 확인
      final covered = <String>{};
      for (final cage in result.cages) {
        for (final cell in cage.cells) {
          covered.add('${cell.$1},${cell.$2}');
        }
      }
      expect(covered.length, 81);
    });

    test('medium 난이도 생성', () {
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.medium,
        seed: 54321,
      );
      expect(result, isNotNull);
      // medium은 힌트 없음
      expect(result!.board.fixedCount, 0);
    });

    test('hard 난이도 생성', () {
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.hard,
        seed: 99999,
      );
      expect(result, isNotNull);
    });

    test('같은 시드로 같은 결과', () {
      final r1 = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.easy,
        seed: 42,
      );
      final r2 = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.easy,
        seed: 42,
      );
      expect(r1, isNotNull);
      expect(r2, isNotNull);
      // 같은 정답 보드
      for (var row = 0; row < 9; row++) {
        for (var col = 0; col < 9; col++) {
          expect(r1!.solution[row][col], r2!.solution[row][col]);
        }
      }
    });

    test('beginner에는 힌트 셀 제공', () {
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.beginner,
        seed: 777,
      );
      expect(result, isNotNull);
      expect(result!.board.fixedCount, greaterThan(0));
    });

    test('케이지 합계 검증 — 정답과 일치', () {
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.medium,
        seed: 11111,
      );
      expect(result, isNotNull);
      for (final cage in result!.cages) {
        var sum = 0;
        for (final cell in cage.cells) {
          sum += result.solution[cell.$1][cell.$2];
        }
        expect(sum, cage.sum);
      }
    });

    test('케이지 내 중복 없음 검증', () {
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.medium,
        seed: 22222,
      );
      expect(result, isNotNull);
      for (final cage in result!.cages) {
        final values = <int>{};
        for (final cell in cage.cells) {
          final v = result.solution[cell.$1][cell.$2];
          expect(values.contains(v), false,
            reason: '케이지 내 중복: $v (케이지 sum=${cage.sum})');
          values.add(v);
        }
      }
    });

    test('생성된 보드는 유효한 스도쿠', () {
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.easy,
        seed: 33333,
      );
      expect(result, isNotNull);
      expect(
        KillerSudokuSolver.isComplete(result!.solution, result.cages),
        true,
      );
    });
  });

  // === KillerSudokuHintEngine 테스트 ===
  group('KillerSudokuHintEngine', () {
    late KillerSudokuBoard board;

    setUp(() {
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.beginner,
        seed: 55555,
      );
      board = result!.board;
    });

    test('Level 1 힌트 — 케이지 안내', () {
      final hint = KillerSudokuHintEngine.getHint(board, 1);
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      expect(hint.message.isNotEmpty, true);
    });

    test('Level 2 힌트 — 후보/조합 안내', () {
      final hint = KillerSudokuHintEngine.getHint(board, 2);
      expect(hint, isNotNull);
      expect(hint!.level, 2);
    });

    test('Level 3 힌트 — 구체적 후보', () {
      final hint = KillerSudokuHintEngine.getHint(board, 3);
      expect(hint, isNotNull);
      expect(hint!.level, 3);
      expect(hint.candidates.isNotEmpty, true);
    });

    test('Level 4 힌트 — 정답 제공', () {
      final hint = KillerSudokuHintEngine.getHint(board, 4);
      expect(hint, isNotNull);
      expect(hint!.level, 4);
      expect(hint.value, isNotNull);
      expect(hint.value, board.solution[hint.row][hint.col]);
    });

    test('완성된 보드에서 힌트 없음', () {
      final completeBoard = KillerSudokuBoard(
        cells: board.solution,
        solution: board.solution,
        cages: board.cages,
      );
      final hint = KillerSudokuHintEngine.getHint(completeBoard, 1);
      expect(hint, isNull);
    });
  });

  // === 유일해 보장 테스트 ===
  group('KillerSudokuGenerator 유일해', () {
    test('생성된 beginner 퍼즐은 (힌트+케이지)로 유일해', () {
      // beginner는 힌트가 있어 검증이 비교적 빠름
      final result = KillerSudokuGenerator.generate(
        difficulty: KillerDifficulty.beginner,
        seed: 42,
      );
      expect(result, isNotNull);

      // 힌트 셀을 그대로 두고 검증
      final count = KillerSudokuSolver.countSolutions(
        result!.board.cells,
        result.cages,
        limit: 2,
      );
      expect(count, 1, reason: '힌트 + 케이지로 유일해가 보장되어야 한다');
    });

    test('countSolutions API 동작', () {
      // 간단한 케이지로 countSolutions가 작동하는지 확인
      final emptyBoard = List.generate(9, (_) => List.filled(9, 0));
      // 빈 케이지 리스트는 스도쿠 해답이 매우 많음 → 2에서 중단
      final count = KillerSudokuSolver.countSolutions(
        emptyBoard,
        [],
        limit: 2,
      );
      expect(count, 2, reason: 'limit에 도달하면 즉시 중단');
    });
  });
}
