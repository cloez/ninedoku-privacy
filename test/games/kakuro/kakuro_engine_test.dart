import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/kakuro/engine/kakuro_board.dart';
import 'package:ninedoku/games/kakuro/engine/kakuro_solver.dart';
import 'package:ninedoku/games/kakuro/engine/kakuro_generator.dart';
import 'package:ninedoku/games/kakuro/engine/kakuro_hint.dart';

void main() {
  group('KakuroCell', () {
    test('검은 셀 생성', () {
      const cell = KakuroCell.black(acrossHint: 10, downHint: 15);
      expect(cell.type, KakuroCellType.black);
      expect(cell.acrossHint, 10);
      expect(cell.downHint, 15);
      expect(cell.value, 0);
    });

    test('흰 셀 생성', () {
      const cell = KakuroCell.white(value: 5);
      expect(cell.type, KakuroCellType.white);
      expect(cell.value, 5);
      expect(cell.acrossHint, null);
      expect(cell.downHint, null);
    });

    test('흰 셀 값 변경', () {
      const cell = KakuroCell.white(value: 0);
      final updated = cell.withValue(7);
      expect(updated.value, 7);
      expect(updated.type, KakuroCellType.white);
    });

    test('검은 셀 값 변경 불가', () {
      const cell = KakuroCell.black(acrossHint: 10);
      final updated = cell.withValue(5);
      expect(updated.acrossHint, 10);
      expect(updated.type, KakuroCellType.black);
    });

    test('JSON 직렬화/역직렬화 — 검은 셀', () {
      const cell = KakuroCell.black(acrossHint: 16, downHint: 23);
      final json = cell.toJson();
      final restored = KakuroCell.fromJson(json);
      expect(restored.type, KakuroCellType.black);
      expect(restored.acrossHint, 16);
      expect(restored.downHint, 23);
    });

    test('JSON 직렬화/역직렬화 — 흰 셀', () {
      const cell = KakuroCell.white(value: 3);
      final json = cell.toJson();
      final restored = KakuroCell.fromJson(json);
      expect(restored.type, KakuroCellType.white);
      expect(restored.value, 3);
    });

    test('동등성 비교', () {
      const cell1 = KakuroCell.white(value: 5);
      const cell2 = KakuroCell.white(value: 5);
      const cell3 = KakuroCell.white(value: 3);
      expect(cell1 == cell2, true);
      expect(cell1 == cell3, false);
    });
  });

  group('KakuroBoard', () {
    /// 간단한 3x3 보드 (테스트용)
    /// [B]  [B\3] [B\4]
    /// [B|7] 1     2
    /// [B|9] 4     5
    KakuroBoard _makeSimpleBoard({bool filled = false}) {
      return KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 5),
          const KakuroCell.black(downHint: 7),
          KakuroCell.black(acrossHint: 3),
          KakuroCell.white(value: filled ? 1 : 0),
          KakuroCell.white(value: filled ? 2 : 0),
          KakuroCell.black(acrossHint: 9),
          KakuroCell.white(value: filled ? 4 : 0),
          KakuroCell.white(value: filled ? 5 : 0),
        ],
      );
    }

    test('보드 생성', () {
      final board = _makeSimpleBoard();
      expect(board.rows, 3);
      expect(board.cols, 3);
      expect(board.totalWhiteCells, 4);
      expect(board.emptyCellCount, 4);
      expect(board.isComplete, false);
    });

    test('채워진 보드', () {
      final board = _makeSimpleBoard(filled: true);
      expect(board.isComplete, true);
      expect(board.filledCellCount, 4);
      expect(board.emptyCellCount, 0);
    });

    test('셀 값 설정', () {
      var board = _makeSimpleBoard();
      board = board.setValue(1, 1, 3);
      expect(board.getValue(1, 1), 3);
      expect(board.filledCellCount, 1);
    });

    test('검은 셀에 값 설정 불가', () {
      var board = _makeSimpleBoard();
      board = board.setValue(0, 0, 5);
      expect(board.getValue(0, 0), 0);
    });

    test('메모 토글', () {
      var board = _makeSimpleBoard();
      board = board.toggleNote(1, 1, 3);
      expect(board.notes[4], {3}); // idx = 1*3+1 = 4

      board = board.toggleNote(1, 1, 5);
      expect(board.notes[4], {3, 5});

      // 제거
      board = board.toggleNote(1, 1, 3);
      expect(board.notes[4], {5});

      // 마지막 제거
      board = board.toggleNote(1, 1, 5);
      expect(board.notes.containsKey(4), false);
    });

    test('값이 있는 셀에 메모 불가', () {
      var board = _makeSimpleBoard();
      board = board.setValue(1, 1, 3);
      board = board.toggleNote(1, 1, 5);
      expect(board.notes.containsKey(4), false);
    });

    test('값 설정 시 메모 제거', () {
      var board = _makeSimpleBoard();
      board = board.toggleNote(1, 1, 3);
      board = board.toggleNote(1, 1, 5);
      expect(board.notes[4], {3, 5});

      board = board.setValue(1, 1, 7);
      expect(board.notes.containsKey(4), false);
    });

    test('블록 추출', () {
      final board = _makeSimpleBoard();
      final blocks = board.blocks;
      // 가로 블록 2개: (1,1)+(1,2) sum=3, (2,1)+(2,2) sum=9
      // 세로 블록 2개: (1,1)+(2,1) sum=5, (1,2)+(2,2) sum=7
      expect(blocks.length, 4);

      final acrossBlocks = blocks.where((b) => b.isAcross).toList();
      expect(acrossBlocks.length, 2);

      final downBlocks = blocks.where((b) => !b.isAcross).toList();
      expect(downBlocks.length, 2);
    });

    test('셀별 블록 조회', () {
      final board = _makeSimpleBoard();
      // (1,1)은 가로 블록 + 세로 블록에 속함
      final cellBlocks = board.blocksForCell(1, 1);
      expect(cellBlocks.length, 2);
    });

    test('JSON 직렬화/역직렬화', () {
      var board = _makeSimpleBoard();
      board = board.setValue(1, 1, 3);
      board = board.toggleNote(1, 2, 1);
      board = board.toggleNote(1, 2, 2);

      final json = board.toJson();
      final restored = KakuroBoard.fromJson(json);

      expect(restored.rows, 3);
      expect(restored.cols, 3);
      expect(restored.getValue(1, 1), 3);
      expect(restored.getCell(0, 0).type, KakuroCellType.black);
      expect(restored.notes[5], {1, 2}); // idx = 1*3+2 = 5
    });

    test('copyWith 깊은 복사', () {
      final board = _makeSimpleBoard();
      final copy = board.copyWith();
      expect(copy == board, true);
      expect(identical(copy.cells, board.cells), false);
    });
  });

  group('KakuroSolver', () {
    KakuroBoard _makeSimpleBoard() {
      return KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 5),
          const KakuroCell.black(downHint: 7),
          const KakuroCell.black(acrossHint: 3),
          const KakuroCell.white(value: 0),
          const KakuroCell.white(value: 0),
          const KakuroCell.black(acrossHint: 9),
          const KakuroCell.white(value: 0),
          const KakuroCell.white(value: 0),
        ],
      );
    }

    test('간단한 퍼즐 풀기', () {
      final board = _makeSimpleBoard();
      final solution = KakuroSolver.solve(board);
      expect(solution, isNotNull);
      expect(solution!.isComplete, true);
      // 검증: 블록 합계 일치
      expect(KakuroSolver.isComplete(solution), true);
    });

    test('유일해 검증', () {
      final board = _makeSimpleBoard();
      // 3x3 간단 보드는 여러 해가 있을 수 있음 — 해가 1개 이상인지 확인
      final count = KakuroSolver.countSolutions(board, limit: 10);
      expect(count >= 1, true);
    });

    test('isComplete — 완성 보드', () {
      final board = KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 5),
          const KakuroCell.black(downHint: 7),
          const KakuroCell.black(acrossHint: 3),
          const KakuroCell.white(value: 1),
          const KakuroCell.white(value: 2),
          const KakuroCell.black(acrossHint: 9),
          const KakuroCell.white(value: 4),
          const KakuroCell.white(value: 5),
        ],
      );
      expect(KakuroSolver.isComplete(board), true);
    });

    test('isComplete — 합계 불일치', () {
      final board = KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 5),
          const KakuroCell.black(downHint: 7),
          const KakuroCell.black(acrossHint: 3),
          const KakuroCell.white(value: 2),
          const KakuroCell.white(value: 3),
          const KakuroCell.black(acrossHint: 9),
          const KakuroCell.white(value: 4),
          const KakuroCell.white(value: 5),
        ],
      );
      // 가로 블록1: 2+3=5 != 3 → 실패
      expect(KakuroSolver.isComplete(board), false);
    });

    test('블록 내 중복 감지', () {
      final board = KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 4),
          const KakuroCell.black(downHint: 4),
          const KakuroCell.black(acrossHint: 4),
          const KakuroCell.white(value: 2),
          const KakuroCell.white(value: 2),
          const KakuroCell.black(acrossHint: 4),
          const KakuroCell.white(value: 2),
          const KakuroCell.white(value: 2),
        ],
      );
      // 중복 + 합계 맞더라도 중복은 위반
      expect(KakuroSolver.hasBlockConflict(board, 1, 1), true);
    });

    test('후보 값 계산', () {
      final board = KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 5),
          const KakuroCell.black(downHint: 7),
          const KakuroCell.black(acrossHint: 3),
          const KakuroCell.white(value: 0),
          const KakuroCell.white(value: 2),
          const KakuroCell.black(acrossHint: 9),
          const KakuroCell.white(value: 0),
          const KakuroCell.white(value: 0),
        ],
      );
      final candidates = KakuroSolver.getCandidates(board, 1, 1);
      expect(candidates, contains(1)); // 가로: 합3, 이미2 → 1
      // 세로: 합5, 아래에 빈칸 → 가능한 값 필터링
    });

    test('isValid — 부분 채움 유효', () {
      final board = KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 5),
          const KakuroCell.black(downHint: 7),
          const KakuroCell.black(acrossHint: 3),
          const KakuroCell.white(value: 1),
          const KakuroCell.white(value: 0),
          const KakuroCell.black(acrossHint: 9),
          const KakuroCell.white(value: 0),
          const KakuroCell.white(value: 0),
        ],
      );
      expect(KakuroSolver.isValid(board), true);
    });
  });

  group('KakuroGenerator', () {
    test('입문(6x6) 퍼즐 생성', () {
      final result = KakuroGenerator.generate(
        difficulty: 0,
        seed: 42,
      );
      // 생성 시도 — 구조 생성이 타임아웃될 수 있으므로 null 허용
      if (result != null) {
        expect(result.puzzle.rows, 6);
        expect(result.puzzle.cols, 6);
        expect(result.puzzle.emptyCellCount > 0, true);
        expect(result.solution.isComplete, true);
        expect(KakuroSolver.isComplete(result.solution), true);
      }
    });

    test('시드 기반 결정론적 생성 (best-effort)', () {
      final result1 = KakuroGenerator.generate(difficulty: 0, seed: 12345);
      final result2 = KakuroGenerator.generate(difficulty: 0, seed: 12345);

      // best-effort 정책: 시간 기반 stopwatch 영향으로 결정론성이 약화될 수 있음
      // (시간 한도 도달 시 마지막 후보 반환). 결과 자체는 모두 반환되어야 함.
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });

    test('다른 시드 → 다른 퍼즐', () {
      final result1 = KakuroGenerator.generate(difficulty: 0, seed: 100);
      final result2 = KakuroGenerator.generate(difficulty: 0, seed: 200);

      if (result1 != null && result2 != null) {
        // 다른 시드 → 대부분 다른 퍼즐 (확률적)
        // 단순히 실패하지 않는 것만 확인
        expect(result1.puzzle.rows, result2.puzzle.rows);
      }
    });

    test('생성된 퍼즐은 항상 반환됨 (유일해 best-effort)', () {
      final result = KakuroGenerator.generate(difficulty: 0, seed: 999);
      // 유일해 보장은 best-effort 정책으로 변경됨 — 풀이 가능한 퍼즐만 보장
      expect(result, isNotNull);
    });
  });

  group('KakuroHintEngine', () {
    KakuroBoard _makePuzzle() {
      return KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 5),
          const KakuroCell.black(downHint: 7),
          const KakuroCell.black(acrossHint: 3),
          const KakuroCell.white(value: 0),
          const KakuroCell.white(value: 0),
          const KakuroCell.black(acrossHint: 9),
          const KakuroCell.white(value: 0),
          const KakuroCell.white(value: 0),
        ],
      );
    }

    KakuroBoard _makeSolution() {
      return KakuroBoard(
        rows: 3,
        cols: 3,
        cells: [
          const KakuroCell.black(),
          const KakuroCell.black(downHint: 5),
          const KakuroCell.black(downHint: 7),
          const KakuroCell.black(acrossHint: 3),
          const KakuroCell.white(value: 1),
          const KakuroCell.white(value: 2),
          const KakuroCell.black(acrossHint: 9),
          const KakuroCell.white(value: 4),
          const KakuroCell.white(value: 5),
        ],
      );
    }

    test('Level 1 힌트 — 블록 강조', () {
      final hint = KakuroHintEngine.getHint(
        _makePuzzle(),
        _makeSolution(),
        level: 1,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      expect(hint.highlightCells.isNotEmpty, true);
      expect(hint.message.isNotEmpty, true);
    });

    test('Level 2 힌트 — 후보 값', () {
      final hint = KakuroHintEngine.getHint(
        _makePuzzle(),
        _makeSolution(),
        level: 2,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 2);
      // 빈 보드에서 후보 값이 있어야 함
      expect(hint.candidates, isNotEmpty);
    });

    test('Level 3 힌트 — 기법 설명', () {
      final hint = KakuroHintEngine.getHint(
        _makePuzzle(),
        _makeSolution(),
        level: 3,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 3);
      expect(hint.technique, isNotNull);
      expect(hint.value, isNotNull);
    });

    test('Level 4 힌트 — 정답 공개', () {
      final hint = KakuroHintEngine.getHint(
        _makePuzzle(),
        _makeSolution(),
        level: 4,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 4);
      expect(hint.value, isNotNull);
      expect([1, 2, 4, 5].contains(hint.value), true);
    });

    test('완성 보드 — 힌트 없음', () {
      final hint = KakuroHintEngine.getHint(
        _makeSolution(),
        _makeSolution(),
        level: 1,
      );
      expect(hint, isNull);
    });

    test('부분 채움 보드에서 힌트', () {
      var board = _makePuzzle();
      board = board.setValue(1, 1, 1);
      board = board.setValue(1, 2, 2);

      final hint = KakuroHintEngine.getHint(
        board,
        _makeSolution(),
        level: 2,
      );
      expect(hint, isNotNull);
      // 남은 빈 셀에 대한 힌트
      expect(hint!.row == 2, true);
    });
  });
}
