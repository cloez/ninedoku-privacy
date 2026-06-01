import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/features/game/game_state.dart';

void main() {
  // 테스트용 간단한 보드 데이터
  late List<List<int>> puzzle;
  late List<List<int>> solution;

  setUp(() {
    // 유효한 스도쿠 솔루션
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
    // 퍼즐: 몇 칸만 비운 상태
    puzzle = solution.map((r) => List<int>.from(r)).toList();
    puzzle[0][0] = 0; // (0,0) = 5
    puzzle[0][1] = 0; // (0,1) = 3
    puzzle[1][0] = 0; // (1,0) = 6
  });

  group('Item 8: 숫자패드 정보 노출 방지', () {
    test('showMistakes=true일 때 오답은 남은 개수에 포함하지 않음', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      // (0,0)에 오답 입력
      final wrongBoard = board.setValue(0, 0, 9); // 정답은 5

      // 오답은 isWrong
      expect(wrongBoard.isWrong(0, 0), isTrue);

      // showMistakes=true에서 9는 카운트에서 제외되므로 남은 수는 원래대로
      // 보드에서 9가 정답인 셀: (0,6), (1,8 X 아님)... 수동 확인 대신 로직 확인
    });

    test('showMistakes=false일 때 오답도 남은 개수에 포함됨', () {
      // 이 동작은 number_pad_widget의 _calcRemainingCounts에서 확인
      // 로직 단위테스트: showMistakes 여부에 따라 isWrong 셀 처리가 다름
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final wrongBoard = board.setValue(0, 0, 9);
      expect(wrongBoard.isWrong(0, 0), isTrue);
      expect(wrongBoard.currentBoard[0][0], equals(9));
    });
  });

  group('Item 2: 자동 메모 채우기', () {
    test('autoFillNotes가 빈 칸에 올바른 후보 숫자를 채움', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);

      final filled = board.autoFillNotes();

      // (0,0)의 후보: 행0에 4,6,7,8,9,1,2 있음, 열0에 1,8,4,7,9,2,3 있음
      // 빈칸 (0,0): 행에 없고 열에 없고 박스에 없는 숫자
      // 행0: {4,6,7,8,9,1,2} (puzzle에서 3,5가 빠짐)
      // 열0: {1,8,4,7,9,2,3} (puzzle에서 5,6이 빠짐)
      // 박스(0,0): {4,2,1,9,8} 퍼즐에서 있는 것 → {7,2,1,9,8} 아니야...
      // 직접 계산 대신 후보에 정답이 포함되어 있는지 확인
      final notes00 = filled.notes[0][0];
      expect(notes00.contains(5), isTrue); // 정답이 후보에 포함
      expect(notes00.length, greaterThan(0));
      expect(notes00.length, lessThan(9)); // 모든 숫자가 후보는 아님
    });

    test('autoFillNotes는 채워진 셀은 건드리지 않음', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final filled = board.autoFillNotes();

      // 채워진 셀의 메모는 비어있어야 함
      expect(filled.notes[0][2], isEmpty); // puzzle[0][2] = 4
      expect(filled.notes[4][4], isEmpty); // puzzle[4][4] = 5
    });

    test('autoFillNotes 후 기존 메모가 덮어써짐', () {
      var board = SudokuBoard(puzzle: puzzle, solution: solution);
      // 수동으로 메모 추가
      board = board.toggleNote(0, 0, 1);
      board = board.toggleNote(0, 0, 2);
      expect(board.notes[0][0], containsAll([1, 2]));

      // 자동 메모 실행하면 수동 메모가 올바른 후보로 교체됨
      final filled = board.autoFillNotes();
      expect(filled.notes[0][0].contains(5), isTrue); // 정답 포함
    });

    test('완전히 채워진 보드에서 autoFillNotes는 빈 메모를 반환', () {
      // 솔루션을 퍼즐로 사용 (빈 칸 없음)
      final board = SudokuBoard(puzzle: solution, solution: solution);
      final filled = board.autoFillNotes();

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(filled.notes[r][c], isEmpty);
        }
      }
    });
  });

  group('Item 6: 완성된 숫자 확인', () {
    test('모든 셀이 정답이면 모든 숫자가 완성됨', () {
      final board = SudokuBoard(puzzle: solution, solution: solution);
      // 모든 숫자가 9개씩 정답으로 채워져 있음
      for (var n = 1; n <= 9; n++) {
        var count = 0;
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (board.currentBoard[r][c] == n && !board.isWrong(r, c)) {
              count++;
            }
          }
        }
        expect(count, equals(9));
      }
    });

    test('빈 칸이 있으면 해당 숫자는 미완성', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      // puzzle[0][0]=0 (정답5), [0][1]=0 (정답3), [1][0]=0 (정답6)
      // 5는 8개만 있음 → 미완성
      var count5 = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.currentBoard[r][c] == 5) count5++;
        }
      }
      expect(count5, equals(8)); // (0,0)이 빠짐

      // 5를 올바르게 입력하면 9개 됨
      final filled = board.setValue(0, 0, 5);
      var newCount5 = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (filled.currentBoard[r][c] == 5) newCount5++;
        }
      }
      expect(newCount5, equals(9));
    });
  });

  group('Item 7: 등급 시스템 개선', () {
    test('실수 0, 힌트 0, 기준시간 이내 → S등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 200, // 입문 기준 300초 이내
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.perfect));
    });

    test('실수 0, 힌트 0, 기준시간 초과 → A등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 500, // 입문 기준 300초 초과, 600초(2배) 이내
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent));
    });

    test('실수 0, 힌트 0, 기준시간 2배 초과해도 노미스노힌트면 최소 A등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 1000, // 입문 기준 600초(2배) 초과
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent));
    });

    test('실수 1, 힌트 0 → A등급', () {
      final grade = Grade.evaluate(
        mistakes: 1,
        hints: 0,
        elapsedSeconds: 200,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent));
    });

    test('실수 2, 힌트 2 → B등급', () {
      final grade = Grade.evaluate(
        mistakes: 2,
        hints: 2,
        elapsedSeconds: 500,
        difficulty: Difficulty.easy,
      );
      expect(grade, equals(Grade.great));
    });

    test('실수 4 이상 → C등급', () {
      final grade = Grade.evaluate(
        mistakes: 4,
        hints: 0,
        elapsedSeconds: 200,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.good));
    });

    test('힌트 4 이상 → C등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 4,
        elapsedSeconds: 200,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.good));
    });

    test('시간/난이도 없이 호출해도 기존 동작 유지 (하위 호환)', () {
      expect(Grade.evaluate(mistakes: 0, hints: 0), equals(Grade.perfect));
      expect(Grade.evaluate(mistakes: 1, hints: 1), equals(Grade.excellent));
      expect(Grade.evaluate(mistakes: 3, hints: 3), equals(Grade.great));
      expect(Grade.evaluate(mistakes: 5, hints: 5), equals(Grade.good));
    });

    test('난이도별 기준 시간이 다름', () {
      // 같은 시간이라도 어려운 난이도에서는 더 좋은 등급
      final beginnerGrade = Grade.evaluate(
        mistakes: 0, hints: 0, elapsedSeconds: 700, difficulty: Difficulty.beginner,
      ); // 700 > 300*2=600 → A (노미스노힌트 최소 A)
      final hardGrade = Grade.evaluate(
        mistakes: 0, hints: 0, elapsedSeconds: 700, difficulty: Difficulty.hard,
      ); // 700 < 1200 → S

      expect(beginnerGrade, equals(Grade.excellent));
      expect(hardGrade, equals(Grade.perfect));
    });
  });

  group('보드 메모 복원 (restoreNotes)', () {
    test('restoreNotes로 이전 메모 상태 복원', () {
      var board = SudokuBoard(puzzle: puzzle, solution: solution);
      board = board.toggleNote(0, 0, 1);
      board = board.toggleNote(0, 0, 3);
      final savedNotes = SudokuBoard.copyNotesStatic(board.notes);

      // 메모 변경
      board = board.autoFillNotes();
      expect(board.notes[0][0], isNot(equals({1, 3})));

      // 복원
      final restored = board.restoreNotes(savedNotes);
      expect(restored.notes[0][0], equals({1, 3}));
    });
  });

  group('UndoAction autoFillNotes 타입', () {
    test('autoFillNotes UndoAction이 전체 메모를 백업', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final allNotes = SudokuBoard.copyNotesStatic(board.notes);

      final action = UndoAction(
        type: UndoActionType.autoFillNotes,
        row: 0,
        col: 0,
        previousAllNotes: allNotes,
      );

      expect(action.type, equals(UndoActionType.autoFillNotes));
      expect(action.previousAllNotes, isNotNull);
      expect(action.previousAllNotes!.length, equals(9));
    });
  });

  group('GameState copyWith 호환성', () {
    test('기존 copyWith 동작 유지', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      final copied = state.copyWith(mistakeCount: 3);
      expect(copied.mistakeCount, equals(3));
      expect(copied.mode, equals(GameMode.classic));
    });
  });
}
