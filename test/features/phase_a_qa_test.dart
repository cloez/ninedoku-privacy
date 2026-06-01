import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/features/game/game_notifier.dart';

/// Phase A QA 검증 테스트
/// 4개 항목: Item 8(숫자패드 정보노출방지), Item 2(자동메모),
/// Item 6(완성숫자 표시), Item 7(등급시스템 개선)
void main() {
  // 테스트용 유효한 스도쿠 데이터
  late List<List<int>> puzzle;
  late List<List<int>> solution;

  setUp(() {
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
    // 3칸만 비운 퍼즐: (0,0)=5, (0,1)=3, (1,0)=6
    puzzle = solution.map((r) => List<int>.from(r)).toList();
    puzzle[0][0] = 0;
    puzzle[0][1] = 0;
    puzzle[1][0] = 0;
  });

  // ========================================================
  // Item 8: 숫자 패드 정보 노출 방지 — 남은 개수 정확성 테스트
  // ========================================================
  group('QA Item 8: _calcRemainingCounts 수동 계산 검증', () {
    // _calcRemainingCounts는 위젯 내 private 메서드이므로,
    // 동일한 로직을 여기서 재현하여 검증

    /// 위젯의 _calcRemainingCounts와 동일한 로직
    Map<int, int> calcRemainingCounts(SudokuBoard board, bool showMistakes) {
      final counts = <int, int>{};
      for (var n = 1; n <= 9; n++) {
        counts[n] = 9;
      }
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final v = board.currentBoard[r][c];
          if (v > 0) {
            if (showMistakes && board.isWrong(r, c)) continue;
            counts[v] = (counts[v] ?? 0) - 1;
          }
        }
      }
      return counts;
    }

    test('초기 상태: 빈 칸에 해당하는 숫자만 남은 수가 줄어듦', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);

      final counts = calcRemainingCounts(board, true);

      // (0,0)=0 → 5가 8개, (0,1)=0 → 3이 8개, (1,0)=0 → 6이 8개
      // 나머지 숫자는 모두 9개씩 있음
      expect(counts[5], equals(1)); // 9 - 8 = 1
      expect(counts[3], equals(1)); // 9 - 8 = 1
      expect(counts[6], equals(1)); // 9 - 8 = 1
      // 다른 숫자(1,2,4,7,8,9)는 9개 모두 있음 → 남은 수 0
      expect(counts[1], equals(0));
      expect(counts[2], equals(0));
      expect(counts[4], equals(0));
      expect(counts[7], equals(0));
      expect(counts[8], equals(0));
      expect(counts[9], equals(0));
    });

    test('showMistakes=true: 오답을 넣으면 해당 숫자는 카운트에서 제외', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      // (0,0)에 오답 9 입력 (정답은 5)
      final wrongBoard = board.setValue(0, 0, 9);

      final counts = calcRemainingCounts(wrongBoard, true);

      // 오답 9는 isWrong → continue → 카운트에서 제외
      // 따라서 9의 남은 수는 여전히 0 (기존 정답 9개)
      expect(counts[9], equals(0));
      // 5는 여전히 1개 남음 (빈 칸 하나)
      expect(counts[5], equals(1));
    });

    test('showMistakes=false: 오답도 카운트에 포함', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      // (0,0)에 오답 9 입력 (정답은 5)
      final wrongBoard = board.setValue(0, 0, 9);

      final counts = calcRemainingCounts(wrongBoard, false);

      // showMistakes=false이므로 오답 9도 카운트에 포함
      // 9가 기존 9개 + 오답 1개 = 10개 → 남은 수 = 9 - 10 = -1
      expect(counts[9], equals(-1));
      // 5는 8개만 있으므로 남은 수 = 9 - 8 = 1
      expect(counts[5], equals(1));
    });

    test('showMistakes=false: 여러 오답에서도 모두 카운트', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      // (0,0)에 오답 1 입력, (0,1)에 오답 1 입력
      var wrongBoard = board.setValue(0, 0, 1);
      wrongBoard = wrongBoard.setValue(0, 1, 1);

      final counts = calcRemainingCounts(wrongBoard, false);

      // 1이 기존 9개 + 오답 2개 = 11개 → 남은 수 = 9 - 11 = -2
      expect(counts[1], equals(-2));
      // 5: 빈칸(0,0)이 1로 채워져서 8개 → 남은 수 1
      expect(counts[5], equals(1));
      // 3: 빈칸(0,1)이 1로 채워져서 8개 → 남은 수 1
      expect(counts[3], equals(1));
    });

    test('모든 칸이 정답이면 모든 숫자 남은 수 0', () {
      final board = SudokuBoard(puzzle: solution, solution: solution);
      final counts = calcRemainingCounts(board, true);

      for (var n = 1; n <= 9; n++) {
        expect(counts[n], equals(0), reason: '숫자 $n의 남은 수가 0이어야 함');
      }
    });
  });

  // ========================================================
  // Item 2: 자동 메모 채우기 — autoFillNotes → undo 통합 테스트
  // ========================================================
  group('QA Item 2: autoFillNotes + Undo 통합 테스트 (GameNotifier)', () {
    late GameNotifier notifier;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      notifier = GameNotifier();
      // seed 고정으로 동일 퍼즐 생성
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 12345,
      );
    });

    tearDown(() {
      notifier.dispose();
    });

    test('autoFillNotes 실행 후 빈 칸에 메모가 채워짐', () {
      final stateBefore = notifier.testState!;
      // 빈 셀 하나 찾기
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!stateBefore.board.isFixed[r][c] &&
              stateBefore.board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }
      expect(emptyRow, isNotNull, reason: '빈 셀이 하나 이상 있어야 함');

      // 자동 메모 실행
      notifier.autoFillNotes();

      final stateAfter = notifier.testState!;
      // 빈 셀에 메모가 채워져야 함
      expect(stateAfter.board.notes[emptyRow!][emptyCol!].isNotEmpty, isTrue,
          reason: '자동 메모 후 빈 셀에 후보가 있어야 함');
      // 메모에 정답이 포함되어야 함
      final correctAnswer = stateAfter.board.solution[emptyRow][emptyCol];
      expect(stateAfter.board.notes[emptyRow][emptyCol].contains(correctAnswer),
          isTrue,
          reason: '자동 메모에 정답이 포함되어야 함');
    });

    test('autoFillNotes → undo → 메모가 이전 상태로 완벽히 복원', () {
      // 수동으로 메모 하나 입력
      final state = notifier.testState!;
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!state.board.isFixed[r][c] &&
              state.board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }
      expect(emptyRow, isNotNull);

      // 수동 메모 입력
      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.toggleMemoMode();
      notifier.inputNumber(1);
      notifier.inputNumber(2);

      // 수동 메모 상태 저장
      final manualNotes =
          Set<int>.from(notifier.testState!.board.notes[emptyRow][emptyCol]);
      expect(manualNotes, containsAll([1, 2]));

      // 자동 메모 실행
      notifier.autoFillNotes();
      // 자동 메모가 덮어씌워서 다름
      final autoNotes =
          Set<int>.from(notifier.testState!.board.notes[emptyRow][emptyCol]);
      expect(autoNotes, isNot(equals(manualNotes)),
          reason: '자동 메모가 수동 메모를 덮어써야 함 (또는 동일할 수도 있지만 대부분 다름)');

      // Undo 실행
      notifier.undo();
      // 수동 메모 상태로 복원되어야 함
      final restoredNotes =
          Set<int>.from(notifier.testState!.board.notes[emptyRow][emptyCol]);
      expect(restoredNotes, equals(manualNotes),
          reason: 'undo 후 수동 메모가 복원되어야 함');
    });

    test('autoFillNotes → undo → 모든 셀의 메모가 복원', () {
      // 전체 메모 상태 백업 (비교용)
      final notesBefore = SudokuBoard.copyNotesStatic(
          notifier.testState!.board.notes);

      // 자동 메모 실행
      notifier.autoFillNotes();

      // Undo 실행
      notifier.undo();

      // 모든 셀의 메모가 이전과 동일한지 확인
      final notesAfterUndo = notifier.testState!.board.notes;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(notesAfterUndo[r][c], equals(notesBefore[r][c]),
              reason: '($r, $c) 셀의 메모가 undo 후 복원되어야 함');
        }
      }
    });

    test('autoFillNotes 후 undoStack에 정확히 1개 추가', () {
      final undoBefore = notifier.testState!.undoStack.length;
      notifier.autoFillNotes();
      expect(notifier.testState!.undoStack.length, equals(undoBefore + 1));
      expect(notifier.testState!.undoStack.last.type,
          equals(UndoActionType.autoFillNotes));
    });

    test('autoFillNotes 연속 2회 → undo 2회로 원래 상태 복원', () {
      final notesBefore = SudokuBoard.copyNotesStatic(
          notifier.testState!.board.notes);

      notifier.autoFillNotes();
      // 일부 셀에 값 입력하여 상태 변경
      final state = notifier.testState!;
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!state.board.isFixed[r][c] &&
              state.board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }
      if (emptyRow != null) {
        notifier.selectCell(emptyRow, emptyCol!);
        notifier.toggleMemoMode(); // 메모모드 끄기 (이미 켜져있으면 끄기)
        if (notifier.testState!.isMemoMode) {
          notifier.toggleMemoMode();
        }
        // 정답 입력해서 보드 상태 변경
        notifier.inputNumber(state.board.solution[emptyRow][emptyCol]);
      }

      // 두 번째 자동 메모
      notifier.autoFillNotes();
      final notesAfterSecond = SudokuBoard.copyNotesStatic(
          notifier.testState!.board.notes);

      // undo 1회: 두 번째 자동 메모 취소
      notifier.undo();

      // undo 2회 (값 입력 취소) + undo 3회 (첫 번째 자동 메모 취소)
      // 입력이 있었으면 입력 undo도 해야 함
      if (emptyRow != null) {
        notifier.undo(); // 값 입력 undo
      }
      notifier.undo(); // 첫 번째 자동 메모 undo

      // 원래 상태 확인
      final notesAfterAllUndo = notifier.testState!.board.notes;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(notesAfterAllUndo[r][c], equals(notesBefore[r][c]),
              reason: '($r, $c) 셀의 메모가 모든 undo 후 복원되어야 함');
        }
      }
    });

    test('게임 완료 후 autoFillNotes 무시', () {
      // 모든 빈 셀에 정답 입력하여 게임 완료
      final board = notifier.testState!.board;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            notifier.selectCell(r, c);
            notifier.inputNumber(board.solution[r][c]);
          }
        }
      }
      expect(notifier.testState!.isCompleted, isTrue);

      final undoBefore = notifier.testState!.undoStack.length;
      notifier.autoFillNotes();
      // 완료 후에는 undoStack이 변하지 않아야 함
      expect(notifier.testState!.undoStack.length, equals(undoBefore));
    });
  });

  // ========================================================
  // Item 2 (추가): 빈 보드에서 autoFillNotes 동작
  // ========================================================
  group('QA Item 2: 빈 보드 autoFillNotes', () {
    test('빈 보드에서 autoFillNotes: 모든 셀에 1~9 후보', () {
      // 완전히 빈 퍼즐 (모든 셀이 0)
      final emptyPuzzle =
          List.generate(9, (_) => List.generate(9, (_) => 0));
      // 유효한 솔루션 사용
      final board = SudokuBoard(puzzle: emptyPuzzle, solution: solution);
      final filled = board.autoFillNotes();

      // 모든 셀이 비어있으므로 각 셀에 1~9 모두 후보가 됨?
      // 아님 — 같은 행/열/박스에 값이 있는지 체크하지만 모두 0이므로 모든 셀에 {1..9}
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(filled.notes[r][c], equals({1, 2, 3, 4, 5, 6, 7, 8, 9}),
              reason: '($r, $c) 빈 보드의 모든 셀은 1~9 모두 후보');
        }
      }
    });

    test('부분 입력 보드에서 autoFillNotes 후 후보에 행/열/박스 숫자 미포함', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final filled = board.autoFillNotes();

      // (0,0) 빈칸의 후보 수동 계산
      // 행 0: [0, 0, 4, 6, 7, 8, 9, 1, 2] → 존재: {4,6,7,8,9,1,2}
      // 열 0: [0, 0, 1, 8, 4, 7, 9, 2, 3] → 존재: {1,8,4,7,9,2,3}
      // 박스(0,0)~(2,2): [0,0,4, 0,7,2, 1,9,8] → 존재: {4,7,2,1,9,8}
      // 전체 used = {1,2,3,4,6,7,8,9}
      // 후보 = {1..9} - used = {5}
      expect(filled.notes[0][0], equals({5}),
          reason: '(0,0) 후보는 정답 5만 있어야 함');

      // (0,1) 빈칸의 후보 수동 계산
      // 행 0: [0, 0, 4, 6, 7, 8, 9, 1, 2] → 존재: {4,6,7,8,9,1,2}
      // 열 1: [0, 7, 9, 5, 2, 1, 6, 8, 4] → 존재: {7,9,5,2,1,6,8,4}
      // 박스(0,0)~(2,2): [0,0,4, 0,7,2, 1,9,8] → 존재: {4,7,2,1,9,8}
      // 전체 used = {1,2,4,5,6,7,8,9}
      // 후보 = {3}
      expect(filled.notes[0][1], equals({3}),
          reason: '(0,1) 후보는 정답 3만 있어야 함');

      // (1,0) 빈칸의 후보 수동 계산
      // 행 1: [0, 7, 2, 1, 9, 5, 3, 4, 8] → 존재: {7,2,1,9,5,3,4,8}
      // 열 0: [0, 0, 1, 8, 4, 7, 9, 2, 3] → 존재: {1,8,4,7,9,2,3}
      // 박스(0,0)~(2,2): [0,0,4, 0,7,2, 1,9,8] → 존재: {4,7,2,1,9,8}
      // 전체 used = {1,2,3,4,5,7,8,9}
      // 후보 = {6}
      expect(filled.notes[1][0], equals({6}),
          reason: '(1,0) 후보는 정답 6만 있어야 함');
    });
  });

  // ========================================================
  // Item 6: 완성된 숫자 시각적 표시 — 로직 검증
  // ========================================================
  group('QA Item 6: 완성 숫자 판별 로직', () {
    /// _getCompletedNumbers 동일 로직
    Set<int> getCompletedNumbers(SudokuBoard board) {
      final correctCounts = <int, int>{};
      for (var n = 1; n <= 9; n++) {
        correctCounts[n] = 0;
      }
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final v = board.currentBoard[r][c];
          if (v > 0 && !board.isWrong(r, c)) {
            correctCounts[v] = (correctCounts[v] ?? 0) + 1;
          }
        }
      }
      return correctCounts.entries
          .where((e) => e.value >= 9)
          .map((e) => e.key)
          .toSet();
    }

    /// _isNumberCompleted 동일 로직
    bool isNumberCompleted(SudokuBoard board, int number) {
      var count = 0;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.currentBoard[r][c] == number && !board.isWrong(r, c)) {
            count++;
          }
        }
      }
      return count >= 9;
    }

    test('완전 풀이 보드: 모든 숫자가 완성', () {
      final board = SudokuBoard(puzzle: solution, solution: solution);
      final completed = getCompletedNumbers(board);
      expect(completed, equals({1, 2, 3, 4, 5, 6, 7, 8, 9}));
    });

    test('빈 칸 있으면 해당 숫자 미완성', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final completed = getCompletedNumbers(board);

      // 5, 3, 6이 각각 8개씩만 있으므로 미완성
      expect(completed.contains(5), isFalse);
      expect(completed.contains(3), isFalse);
      expect(completed.contains(6), isFalse);
      // 나머지는 9개씩 완성
      expect(completed.contains(1), isTrue);
      expect(completed.contains(2), isTrue);
      expect(completed.contains(4), isTrue);
      expect(completed.contains(7), isTrue);
      expect(completed.contains(8), isTrue);
      expect(completed.contains(9), isTrue);
    });

    test('오답이 있으면 해당 숫자 미완성 (정답 카운트에 오답 미포함)', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      // (0,0)에 오답 9 입력 → 9가 10개가 되지만, (0,0)은 isWrong이므로 정답 9는 여전히 9개
      final wrongBoard = board.setValue(0, 0, 9);

      // 9는 여전히 정답 9개 → 완성
      expect(isNumberCompleted(wrongBoard, 9), isTrue);
      // 5는 8개로 미완성
      expect(isNumberCompleted(wrongBoard, 5), isFalse);
    });

    test('_getCompletedNumbers와 _isNumberCompleted 결과 일치', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      // 하나만 정답 입력
      final updated = board.setValue(0, 0, 5);

      final completed = getCompletedNumbers(updated);
      for (var n = 1; n <= 9; n++) {
        expect(completed.contains(n), equals(isNumberCompleted(updated, n)),
            reason: '숫자 $n에 대해 두 함수 결과 일치해야 함');
      }
    });

    test('정답 1개 입력하면 해당 숫자만 완성됨', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      // (0,0)에 정답 5 입력 → 5가 9개 완성
      final updated = board.setValue(0, 0, 5);

      expect(isNumberCompleted(updated, 5), isTrue);
      // 3, 6은 여전히 미완성
      expect(isNumberCompleted(updated, 3), isFalse);
      expect(isNumberCompleted(updated, 6), isFalse);
    });
  });

  // ========================================================
  // Item 7: 등급 시스템 개선 — 경계값 테스트
  // ========================================================
  group('QA Item 7: 등급 경계값 테스트', () {
    test('정확히 기준시간일 때 → S등급', () {
      // beginner 기준 300초
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 300,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.perfect),
          reason: '정확히 기준시간이면 S등급');
    });

    test('기준시간 + 1초일 때 → A등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 301,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent),
          reason: '기준시간 1초 초과 시 A등급');
    });

    test('정확히 기준시간 2배일 때 → A등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 600,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent),
          reason: '정확히 2배 시간이면 A등급');
    });

    test('기준시간 2배 + 1초일 때 → 노미스노힌트면 최소 A등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 601,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent),
          reason: '2배 초과해도 노미스노힌트면 최소 A등급');
    });

    test('0초에 완료 → S등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 0,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.perfect));
    });

    test('매우 긴 시간이어도 노미스노힌트면 A등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 99999,
        difficulty: Difficulty.master,
      );
      expect(grade, equals(Grade.excellent));
    });

    test('난이도별 기준 시간 정확성 검증', () {
      // 각 난이도의 기준 시간 정확히 맞을 때 S등급
      final difficulties = {
        Difficulty.beginner: 300,
        Difficulty.easy: 600,
        Difficulty.medium: 900,
        Difficulty.hard: 1200,
        Difficulty.expert: 1800,
        Difficulty.master: 2400,
      };

      for (final entry in difficulties.entries) {
        final grade = Grade.evaluate(
          mistakes: 0,
          hints: 0,
          elapsedSeconds: entry.value,
          difficulty: entry.key,
        );
        expect(grade, equals(Grade.perfect),
            reason: '${entry.key.label} 기준시간 ${entry.value}초 이내면 S등급');

        // 1초 초과하면 A등급
        final gradeOver = Grade.evaluate(
          mistakes: 0,
          hints: 0,
          elapsedSeconds: entry.value + 1,
          difficulty: entry.key,
        );
        expect(gradeOver, equals(Grade.excellent),
            reason: '${entry.key.label} 기준시간 1초 초과면 A등급');
      }
    });

    test('실수 1 + 기준시간 이내 → A등급 (시간보다 실수가 우선)', () {
      final grade = Grade.evaluate(
        mistakes: 1,
        hints: 0,
        elapsedSeconds: 100,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent));
    });

    test('실수 0, 힌트 1 + 기준시간 이내 → A등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 1,
        elapsedSeconds: 100,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent));
    });

    test('실수 2, 힌트 0 → B등급 (시간 무관)', () {
      final grade = Grade.evaluate(
        mistakes: 2,
        hints: 0,
        elapsedSeconds: 100,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.great));
    });

    test('실수 4 → C등급 (시간/난이도 무관)', () {
      final grade = Grade.evaluate(
        mistakes: 4,
        hints: 0,
        elapsedSeconds: 1,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.good));
    });

    test('하위 호환: elapsedSeconds/difficulty 없이 호출', () {
      // 기존 테스트와 동일한 기대값
      expect(Grade.evaluate(mistakes: 0, hints: 0), equals(Grade.perfect));
      expect(Grade.evaluate(mistakes: 1, hints: 0), equals(Grade.excellent));
      expect(Grade.evaluate(mistakes: 0, hints: 1), equals(Grade.excellent));
      expect(Grade.evaluate(mistakes: 2, hints: 0), equals(Grade.great));
      expect(Grade.evaluate(mistakes: 0, hints: 2), equals(Grade.great));
      expect(Grade.evaluate(mistakes: 4, hints: 0), equals(Grade.good));
      expect(Grade.evaluate(mistakes: 0, hints: 4), equals(Grade.good));
    });

    test('GameState.grade getter가 시간/난이도를 올바르게 전달', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);

      // 빠르게 완료: S등급 기대
      final fastState = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        elapsedSeconds: 100,
        mistakeCount: 0,
        hintCount: 0,
      );
      expect(fastState.grade, equals(Grade.perfect));

      // 느리게 완료: A등급 기대
      final slowState = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        elapsedSeconds: 500,
        mistakeCount: 0,
        hintCount: 0,
      );
      expect(slowState.grade, equals(Grade.excellent));
    });
  });

  // ========================================================
  // 복합 시나리오: autoFillNotes + 완성 숫자 + 등급
  // ========================================================
  group('QA 복합 시나리오', () {
    test('autoFillNotes는 고정 셀에 메모를 추가하지 않음', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final filled = board.autoFillNotes();

      // 고정 셀은 currentBoard[r][c] != 0이므로 메모가 비어야 함
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.isFixed[r][c]) {
            expect(filled.notes[r][c], isEmpty,
                reason: '고정 셀 ($r, $c)에는 메모가 없어야 함');
          }
        }
      }
    });

    test('autoFillNotes는 이미 값이 입력된 셀에 메모를 추가하지 않음', () {
      var board = SudokuBoard(puzzle: puzzle, solution: solution);
      // (0,0)에 값 입력
      board = board.setValue(0, 0, 5);
      final filled = board.autoFillNotes();

      expect(filled.notes[0][0], isEmpty,
          reason: '값이 있는 셀에는 메모가 없어야 함');
    });

    test('copyNotesStatic은 원본 board.notes의 깊은 복사', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final copied = SudokuBoard.copyNotesStatic(board.notes);

      // 복사본 수정해도 원본에 영향 없음
      copied[0][0].add(99);
      expect(board.notes[0][0].contains(99), isFalse,
          reason: '깊은 복사이므로 복사본 수정이 원본에 영향주지 않아야 함');
    });

    test('UndoAction previousAllNotes는 참조 저장 (GameNotifier에서 복사 담당)', () {
      // UndoAction은 단순 참조 저장, 실제 깊은 복사는
      // GameNotifier.autoFillNotes()에서 copyNotesStatic으로 수행
      // 따라서 GameNotifier를 통한 undo가 정상 동작하면 충분함
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final copied = SudokuBoard.copyNotesStatic(board.notes);
      final action = UndoAction(
        type: UndoActionType.autoFillNotes,
        row: 0,
        col: 0,
        previousAllNotes: copied,
      );

      expect(action.previousAllNotes, isNotNull);
      expect(action.previousAllNotes!.length, equals(9));
      // copied와 action.previousAllNotes는 같은 참조
      // 이는 의도된 설계 — GameNotifier가 이미 복사된 데이터를 넘기므로 안전
      expect(identical(action.previousAllNotes, copied), isTrue);
    });

    test('restoreNotes도 깊은 복사', () {
      var board = SudokuBoard(puzzle: puzzle, solution: solution);
      board = board.toggleNote(0, 0, 5);
      final saved = SudokuBoard.copyNotesStatic(board.notes);

      board = board.autoFillNotes();
      final restored = board.restoreNotes(saved);

      // saved 수정해도 restored에 영향 없음
      saved[0][0].add(99);
      expect(restored.notes[0][0].contains(99), isFalse);
    });
  });
}
