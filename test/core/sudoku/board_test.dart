import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';

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

  group('SudokuBoard', () {
    test('고정 숫자는 수정할 수 없다', () {
      // (0,0)은 5로 고정
      expect(board.isFixed[0][0], isTrue);
      final modified = board.setValue(0, 0, 9);
      expect(modified.currentBoard[0][0], equals(5)); // 변경 안 됨
    });

    test('빈 셀에 값을 입력할 수 있다', () {
      // (0,2)는 빈 칸
      expect(board.isFixed[0][2], isFalse);
      final modified = board.setValue(0, 2, 4);
      expect(modified.currentBoard[0][2], equals(4));
    });

    test('값을 삭제할 수 있다', () {
      final withValue = board.setValue(0, 2, 4);
      final cleared = withValue.clearValue(0, 2);
      expect(cleared.currentBoard[0][2], equals(0));
    });

    test('메모를 토글할 수 있다', () {
      final withNote = board.toggleNote(0, 2, 4);
      expect(withNote.notes[0][2], contains(4));

      final withoutNote = withNote.toggleNote(0, 2, 4);
      expect(withoutNote.notes[0][2], isNot(contains(4)));
    });

    test('숫자가 입력된 셀에는 메모를 추가할 수 없다', () {
      final withValue = board.setValue(0, 2, 4);
      final tryNote = withValue.toggleNote(0, 2, 1);
      expect(tryNote.notes[0][2], isEmpty);
    });

    test('숫자 입력 시 메모가 자동 제거된다', () {
      // (0,2)에 메모 4 추가
      var modified = board.toggleNote(0, 2, 4);
      // (0,3)에도 메모 4 추가 (같은 행)
      modified = modified.toggleNote(0, 3, 4);
      expect(modified.notes[0][3], contains(4));

      // (0,2)에 4 입력 후 자동 메모 제거
      modified = modified.setValue(0, 2, 4);
      modified = modified.autoRemoveNotes(0, 2, 4);
      // 같은 행의 (0,3)에서 4가 제거되어야 함
      expect(modified.notes[0][3], isNot(contains(4)));
    });

    test('오답 감지', () {
      final withWrong = board.setValue(0, 2, 9); // 정답은 4
      expect(withWrong.isWrong(0, 2), isTrue);

      final withRight = board.setValue(0, 2, 4);
      expect(withRight.isWrong(0, 2), isFalse);
    });

    test('완료 판정', () {
      expect(board.isCompleted, isFalse);

      // 모든 빈 칸을 정답으로 채움
      var completed = board;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c]) {
            completed = completed.setValue(r, c, solution[r][c]);
          }
        }
      }
      expect(completed.isCompleted, isTrue);
    });

    test('빈 셀 개수', () {
      var expectedEmpty = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (puzzle[r][c] == 0) expectedEmpty++;
        }
      }
      expect(board.emptyCellCount, equals(expectedEmpty));
    });

    test('JSON 직렬화/역직렬화', () {
      final modified = board.setValue(0, 2, 4);
      final json = modified.toJson();
      final restored = SudokuBoard.fromJson(json);

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(restored.puzzle[r][c], equals(modified.puzzle[r][c]));
          expect(restored.solution[r][c], equals(modified.solution[r][c]));
          expect(restored.currentBoard[r][c], equals(modified.currentBoard[r][c]));
        }
      }
    });
  });
}
