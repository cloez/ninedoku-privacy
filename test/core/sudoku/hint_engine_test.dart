import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/hint_engine.dart';

void main() {
  late SudokuBoard board;

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

  setUp(() {
    board = SudokuBoard(puzzle: puzzle, solution: solution);
  });

  group('HintEngine', () {
    // TC-004: 힌트가 정답과 모순되지 않아야 한다
    test('TC-004: 영역 강조 힌트가 빈 셀을 가리킨다', () {
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.highlightRegion,
      );

      expect(hint, isNotNull);
      expect(board.currentBoard[hint!.row][hint.col], equals(0));
      expect(hint.level, equals(HintLevel.highlightRegion));
      expect(hint.highlightCells, isNotEmpty);
    });

    test('TC-004: 정답 공개 힌트가 실제 정답과 일치한다', () {
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.revealAnswer,
      );

      expect(hint, isNotNull);
      expect(hint!.level, equals(HintLevel.revealAnswer));
      expect(hint.answer, isNotNull);
      // 힌트 정답이 솔루션과 일치
      expect(
        hint.answer,
        equals(solution[hint.row][hint.col]),
        reason: '힌트 정답이 솔루션과 불일치',
      );
    });

    test('완성된 보드에서는 힌트가 null', () {
      var completed = board;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c]) {
            completed = completed.setValue(r, c, solution[r][c]);
          }
        }
      }

      final hint = HintEngine.getHint(
        board: completed,
        level: HintLevel.highlightRegion,
      );
      expect(hint, isNull);
    });

    test('영역 강조 셀 목록에 대상 셀의 박스가 포함된다 (Level 1: 단일 영역)', () {
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.highlightRegion,
      );
      expect(hint, isNotNull);

      final row = hint!.row;
      final col = hint.col;

      // 새 정책: Level 1은 박스 단일 영역만 강조 (9칸)
      expect(hint.regionType, equals('box'));
      expect(hint.highlightCells.length, equals(9));
      // 같은 박스의 셀들이 포함되어야 함
      final boxRow = (row ~/ 3) * 3;
      final boxCol = (col ~/ 3) * 3;
      for (var r = boxRow; r < boxRow + 3; r++) {
        for (var c = boxCol; c < boxCol + 3; c++) {
          expect(hint.highlightCells, contains((r, c)));
        }
      }
      // 다국어 메시지 키
      expect(hint.messageKey, equals('hint.level1.box'));
    });
  });
}
