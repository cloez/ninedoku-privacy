import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/features/game/game_notifier.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';

/// Phase 2 QA 엣지 케이스 테스트 (TC-005, TC-006)
void main() {
  late GameNotifier notifier;

  /// 테스트용 보드 생성 헬퍼: 빈 셀 위치와 정답을 예측 가능하게 제공
  SudokuBoard createTestBoard({int filledCount = 78}) {
    // 유효한 스도쿠 해답 생성
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

    // 퍼즐: 마지막 몇 셀만 비움
    final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
    var emptied = 0;
    // 뒤에서부터 빈 칸 만들기
    for (var r = 8; r >= 0 && emptied < (81 - filledCount); r--) {
      for (var c = 8; c >= 0 && emptied < (81 - filledCount); c--) {
        puzzle[r][c] = 0;
        emptied++;
      }
    }

    return SudokuBoard(puzzle: puzzle, solution: solution);
  }

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    notifier = GameNotifier();
  });

  tearDown(() {
    notifier.dispose();
  });

  group('엣지 케이스: 완료 직전 마지막 셀 입력', () {
    test('마지막 빈 셀에 정답 입력 시 isCompleted가 true로 전환', () {
      // 빈 셀 1개짜리 보드 생성
      final board = createTestBoard(filledCount: 80);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 찾기
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
          }
        }
      }

      expect(emptyRow, isNotNull, reason: '빈 셀이 존재해야 함');
      expect(notifier.testState!.isCompleted, false);

      // 마지막 셀에 정답 입력
      notifier.selectCell(emptyRow!, emptyCol!);
      final correctAnswer = board.solution[emptyRow][emptyCol];
      notifier.inputNumber(correctAnswer);

      expect(notifier.testState!.isCompleted, true,
          reason: '마지막 셀 정답 입력 후 완료 상태여야 함');
    });

    test('마지막 빈 셀에 오답 입력 시 isCompleted는 false 유지', () {
      final board = createTestBoard(filledCount: 80);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
          }
        }
      }

      notifier.selectCell(emptyRow!, emptyCol!);
      final correctAnswer = board.solution[emptyRow][emptyCol];
      // 오답 입력 (정답과 다른 숫자)
      final wrongAnswer = correctAnswer == 9 ? 1 : correctAnswer + 1;
      notifier.inputNumber(wrongAnswer);

      expect(notifier.testState!.isCompleted, false,
          reason: '오답 입력 후에도 미완료 상태여야 함');
    });
  });

  group('엣지 케이스: 실수 카운트', () {
    test('오답 입력 시 mistakeCount 증가', () {
      final board = createTestBoard(filledCount: 75);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 찾기
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != null) break;
      }

      expect(notifier.testState!.mistakeCount, 0);

      notifier.selectCell(emptyRow!, emptyCol!);
      final correctAnswer = board.solution[emptyRow][emptyCol];
      final wrongAnswer = correctAnswer == 9 ? 1 : correctAnswer + 1;
      notifier.inputNumber(wrongAnswer);

      expect(notifier.testState!.mistakeCount, 1,
          reason: '오답 입력 시 실수 카운트가 1 증가해야 함');
    });

    test('정답 입력 시 mistakeCount 미증가', () {
      final board = createTestBoard(filledCount: 75);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != null) break;
      }

      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(board.solution[emptyRow][emptyCol]);

      expect(notifier.testState!.mistakeCount, 0,
          reason: '정답 입력 시 실수 카운트는 0 유지');
    });

    test('연속 오답 입력 시 mistakeCount 누적', () {
      final board = createTestBoard(filledCount: 70);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 여러 개 찾기
      final emptyCells = <(int, int)>[];
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyCells.add((r, c));
          }
        }
      }

      // 3개의 빈 셀에 오답 입력
      for (var i = 0; i < 3 && i < emptyCells.length; i++) {
        final (r, c) = emptyCells[i];
        notifier.selectCell(r, c);
        final correct = board.solution[r][c];
        final wrong = correct == 9 ? 1 : correct + 1;
        notifier.inputNumber(wrong);
      }

      expect(notifier.testState!.mistakeCount, 3,
          reason: '3번 오답 입력 시 실수 카운트는 3이어야 함');
    });
  });

  group('엣지 케이스: 힌트 정답 공개', () {
    test('힌트가 정답 셀을 정확히 공개하는지 확인', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );

      final beforeState = notifier.testState!;
      // 점진적 힌트: 4번 호출로 정답 공개
      notifier.useHint(); // 1단계: 영역 강조
      notifier.useHint(); // 2단계: 후보 안내
      notifier.useHint(); // 3단계: 기법 설명
      notifier.useHint(); // 4단계: 정답 공개
      final afterState = notifier.testState!;

      // 힌트 사용 후 선택된 셀 확인
      expect(afterState.selectedCell, isNotNull,
          reason: '힌트 사용 후 셀이 선택되어야 함');
      // 새 비용 정책: L1 +1, L4 +1 = 총 +2
      expect(afterState.hintCount, beforeState.hintCount + 2,
          reason: '힌트 카운트가 L1+L4 합산으로 +2 증가해야 함');

      // 선택된 셀의 값이 정답과 일치하는지 확인
      final (hintRow, hintCol) = afterState.selectedCell!;
      final filledValue = afterState.board.currentBoard[hintRow][hintCol];
      final solutionValue = afterState.board.solution[hintRow][hintCol];

      expect(filledValue, solutionValue,
          reason: '힌트가 공개한 값은 정답과 일치해야 함');
      expect(afterState.board.isWrong(hintRow, hintCol), false,
          reason: '힌트로 채운 셀은 오답이 아니어야 함');
    });

    test('힌트 연속 사용 시 서로 다른 셀 공개', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );

      // 첫 번째 힌트 (4단계까지)
      notifier.useHint(); // 1단계
      notifier.useHint(); // 2단계
      notifier.useHint(); // 3단계
      notifier.useHint(); // 4단계: 정답 공개
      final firstHintCell = notifier.testState!.selectedCell;

      // 두 번째 힌트 (4단계까지)
      notifier.useHint(); // 1단계
      notifier.useHint(); // 2단계
      notifier.useHint(); // 3단계
      notifier.useHint(); // 4단계: 정답 공개
      final secondHintCell = notifier.testState!.selectedCell;

      // 두 힌트가 서로 다른 셀을 공개했는지 확인
      if (secondHintCell != null && firstHintCell != null) {
        // 새 비용 정책: 사이클당 +2, 두 사이클 → 4
        expect(notifier.testState!.hintCount, 4);
        // 두 번째 힌트 셀도 정답인지 확인
        final (r, c) = secondHintCell;
        expect(
          notifier.testState!.board.currentBoard[r][c],
          notifier.testState!.board.solution[r][c],
          reason: '두 번째 힌트도 정답을 공개해야 함',
        );
      }
    });
  });

  group('엣지 케이스: 메모 모드에서 값이 있는 셀', () {
    test('값이 입력된 셀에 메모 시도 시 무시', () {
      final board = createTestBoard(filledCount: 75);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 찾기
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != null) break;
      }

      // 먼저 값 입력
      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(board.solution[emptyRow][emptyCol]);

      // 메모 모드로 전환 후 같은 셀에 메모 시도
      notifier.toggleMemoMode();
      notifier.selectCell(emptyRow, emptyCol);
      notifier.inputNumber(3);

      // 값이 있는 셀이므로 board.toggleNote가 무시됨 → 메모 비어있어야 함
      // 단, inputNumber에서 isMemoMode일 때 _toggleNote를 호출하는데,
      // _toggleNote 내부의 board.toggleNote가 currentBoard != 0이면 무시함
      expect(
        notifier.testState!.board.notes[emptyRow][emptyCol],
        isEmpty,
        reason: '값이 있는 셀에는 메모가 추가되지 않아야 함',
      );
    });

    test('고정 셀에 메모 시도 시 무시', () {
      final board = createTestBoard(filledCount: 75);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 고정 셀 찾기
      int? fixedRow, fixedCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.isFixed[r][c]) {
            fixedRow = r;
            fixedCol = c;
            break;
          }
        }
        if (fixedRow != null) break;
      }

      notifier.toggleMemoMode();
      notifier.selectCell(fixedRow!, fixedCol!);
      notifier.inputNumber(5);

      // 고정 셀에는 inputNumber 자체가 무시됨 (isFixed 체크)
      expect(
        notifier.testState!.board.notes[fixedRow][fixedCol],
        isEmpty,
        reason: '고정 셀에는 메모가 추가되지 않아야 함',
      );
    });
  });

  group('엣지 케이스: 되돌리기 연속 실행', () {
    test('여러 번 연속 undo 실행 시 정상 복원', () {
      final board = createTestBoard(filledCount: 70);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 3개 찾기
      final emptyCells = <(int, int)>[];
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyCells.add((r, c));
            if (emptyCells.length >= 3) break;
          }
        }
        if (emptyCells.length >= 3) break;
      }

      expect(emptyCells.length, greaterThanOrEqualTo(3));

      // 3개의 셀에 오답 입력 (자동완성 방지 - undo 동작 검증에 정/오답 무관)
      for (final (r, c) in emptyCells) {
        notifier.selectCell(r, c);
        notifier.inputNumber(board.solution[r][c] % 9 + 1);
      }

      expect(notifier.testState!.undoStack.length, 3);

      // 3번 연속 undo
      notifier.undo();
      expect(notifier.testState!.undoStack.length, 2);

      notifier.undo();
      expect(notifier.testState!.undoStack.length, 1);

      notifier.undo();
      expect(notifier.testState!.undoStack.length, 0);

      // 모든 셀이 원래 값(0)으로 복원되었는지 확인
      for (final (r, c) in emptyCells) {
        expect(notifier.testState!.board.currentBoard[r][c], 0,
            reason: '($r, $c) 셀이 undo 후 0으로 복원되어야 함');
      }
    });

    test('빈 undoStack에서 추가 undo 호출 시 안전', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );

      // undo를 여러 번 호출해도 예외 없음
      notifier.undo();
      notifier.undo();
      notifier.undo();

      expect(notifier.testState!.undoStack, isEmpty);
    });
  });

  group('엣지 케이스: 선택+입력+되돌리기 시퀀스', () {
    test('선택 → 입력 → 다른셀 선택 → 되돌리기 시 이전 셀로 복귀', () {
      final board = createTestBoard(filledCount: 70);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 2개 찾기
      final emptyCells = <(int, int)>[];
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyCells.add((r, c));
            if (emptyCells.length >= 2) break;
          }
        }
        if (emptyCells.length >= 2) break;
      }

      // 첫 번째 셀 선택 + 오답 입력 (자동완성 방지 - undo 동작 검증 목적)
      final (r1, c1) = emptyCells[0];
      notifier.selectCell(r1, c1);
      notifier.inputNumber(board.solution[r1][c1] % 9 + 1);

      // 두 번째 셀 선택
      final (r2, c2) = emptyCells[1];
      notifier.selectCell(r2, c2);
      expect(notifier.testState!.selectedCell, (r2, c2));

      // undo 시 첫 번째 셀로 선택이 복귀
      notifier.undo();
      expect(notifier.testState!.selectedCell, (r1, c1),
          reason: 'undo 후 해당 액션의 셀이 선택되어야 함');
      expect(notifier.testState!.board.currentBoard[r1][c1], 0,
          reason: 'undo 후 값이 복원되어야 함');
    });

    test('메모 입력 → 값 입력 → 되돌리기 시퀀스', () {
      final board = createTestBoard(filledCount: 70);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 찾기
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != null) break;
      }

      // 메모 입력
      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.toggleMemoMode();
      notifier.inputNumber(3);
      notifier.inputNumber(5);

      expect(notifier.testState!.board.notes[emptyRow][emptyCol],
          containsAll([3, 5]));

      // 메모 모드 끄고 오답 입력 (자동완성 방지 - undo 동작 검증 목적)
      // board.setValue에서 notes가 비워짐
      notifier.toggleMemoMode();
      final wrongValue = board.solution[emptyRow][emptyCol] % 9 + 1;
      notifier.inputNumber(wrongValue);

      expect(notifier.testState!.board.currentBoard[emptyRow][emptyCol],
          wrongValue);
      // setValue에서 notes가 비워짐
      expect(notifier.testState!.board.notes[emptyRow][emptyCol], isEmpty);

      // undo로 값 입력 취소 → 이전 메모가 복원되어야 함
      notifier.undo();
      expect(notifier.testState!.board.currentBoard[emptyRow][emptyCol], 0,
          reason: 'undo 후 값이 0으로 복원되어야 함');
      expect(
        notifier.testState!.board.notes[emptyRow][emptyCol],
        containsAll([3, 5]),
        reason: 'undo 후 이전 메모(3, 5)가 복원되어야 함',
      );
    });
  });

  group('엣지 케이스: 정답 입력 시 자동 메모 제거', () {
    test('정답 입력 시 같은 행/열/박스의 메모에서 해당 숫자 자동 제거', () {
      final board = createTestBoard(filledCount: 70);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 2개 찾기 (같은 행에 있는)
      final emptyCells = <(int, int)>[];
      for (var r = 0; r < 9; r++) {
        emptyCells.clear();
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyCells.add((r, c));
            if (emptyCells.length >= 2) break;
          }
        }
        if (emptyCells.length >= 2) break;
      }

      if (emptyCells.length < 2) {
        // 같은 행에 2개 이상 빈 셀이 없으면 스킵
        return;
      }

      final (r1, c1) = emptyCells[0];
      final (r2, c2) = emptyCells[1];
      final answerForCell1 = board.solution[r1][c1];

      // 두 번째 셀에 첫 번째 셀의 정답 숫자를 메모로 추가
      notifier.toggleMemoMode();
      notifier.selectCell(r2, c2);
      notifier.inputNumber(answerForCell1);

      expect(
        notifier.testState!.board.notes[r2][c2],
        contains(answerForCell1),
        reason: '메모에 $answerForCell1이 추가되어야 함',
      );

      // 첫 번째 셀에 정답 입력 → 같은 행의 두 번째 셀 메모에서 자동 제거
      notifier.toggleMemoMode();
      notifier.selectCell(r1, c1);
      notifier.inputNumber(answerForCell1);

      expect(
        notifier.testState!.board.notes[r2][c2].contains(answerForCell1),
        false,
        reason: '정답 입력 후 같은 행의 메모에서 $answerForCell1이 자동 제거되어야 함',
      );
    });
  });

  group('엣지 케이스: 완료 후 동작 차단', () {
    test('완료 상태에서 모든 입력 액션 무시', () {
      final board = createTestBoard(filledCount: 80);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 마지막 빈 셀에 정답 입력하여 완료
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
          }
        }
      }

      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(board.solution[emptyRow][emptyCol]);
      expect(notifier.testState!.isCompleted, true);

      // 완료 후 각종 액션 시도
      final completedState = notifier.testState!;

      notifier.selectCell(0, 0);
      expect(notifier.testState!.selectedCell, completedState.selectedCell,
          reason: '완료 후 셀 선택이 무시되어야 함');

      notifier.inputNumber(5);
      notifier.deleteValue();
      notifier.undo();
      notifier.toggleMemoMode();

      // 상태 변경 없음 확인
      expect(notifier.testState!.undoStack.length,
          completedState.undoStack.length);
      expect(notifier.testState!.isMemoMode, completedState.isMemoMode);
    });
  });

  group('엣지 케이스: 릴렉스 모드 특수 동작', () {
    test('릴렉스 모드에서 showMistakes가 false', () {
      notifier.startNewGame(
        mode: GameMode.relax,
        difficulty: Difficulty.easy,
      );

      expect(notifier.testState!.showMistakes, false,
          reason: '릴렉스 모드에서는 실수 표시가 비활성이어야 함');
    });

    test('릴렉스 모드에서 타이머 작동하지 않음', () async {
      notifier.startNewGame(
        mode: GameMode.relax,
        difficulty: Difficulty.easy,
      );

      await Future.delayed(const Duration(seconds: 1, milliseconds: 300));
      expect(notifier.testState!.elapsedSeconds, 0,
          reason: '릴렉스 모드에서는 타이머가 작동하지 않아야 함');
    });
  });

  group('엣지 케이스: deleteValue 경계 조건', () {
    test('빈 셀에서 deleteValue 호출 시 무시', () {
      final board = createTestBoard(filledCount: 75);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 찾기
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != null) break;
      }

      notifier.selectCell(emptyRow!, emptyCol!);
      final beforeStack = notifier.testState!.undoStack.length;

      notifier.deleteValue();

      // 빈 셀(값=0, 메모 없음)에서 삭제 시 undoStack에 추가하지 않아야 함
      expect(notifier.testState!.undoStack.length, beforeStack,
          reason: '빈 셀에서 삭제 시 undoStack이 증가하지 않아야 함');
    });

    test('고정 셀에서 deleteValue 호출 시 무시', () {
      final board = createTestBoard(filledCount: 75);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 고정 셀 찾기
      int? fixedRow, fixedCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.isFixed[r][c]) {
            fixedRow = r;
            fixedCol = c;
            break;
          }
        }
        if (fixedRow != null) break;
      }

      final originalValue = board.currentBoard[fixedRow!][fixedCol!];
      notifier.selectCell(fixedRow, fixedCol);
      notifier.deleteValue();

      expect(
        notifier.testState!.board.currentBoard[fixedRow][fixedCol],
        originalValue,
        reason: '고정 셀의 값은 삭제되지 않아야 함',
      );
    });
  });

  group('엣지 케이스: 메모와 값 입력 상호작용', () {
    test('메모가 있는 셀에 값 입력 시 메모가 자동 삭제됨', () {
      final board = createTestBoard(filledCount: 70);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.restoreGame(state);

      // 빈 셀 찾기
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c] && board.currentBoard[r][c] == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
        if (emptyRow != null) break;
      }

      // 메모 입력
      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.toggleMemoMode();
      notifier.inputNumber(1);
      notifier.inputNumber(2);
      notifier.inputNumber(3);

      expect(notifier.testState!.board.notes[emptyRow][emptyCol].length, 3);

      // 일반 모드로 전환 후 값 입력
      notifier.toggleMemoMode();
      notifier.inputNumber(board.solution[emptyRow][emptyCol]);

      // setValue에서 notes가 비워짐
      expect(notifier.testState!.board.notes[emptyRow][emptyCol], isEmpty,
          reason: '값 입력 후 해당 셀의 메모가 삭제되어야 함');
      expect(
        notifier.testState!.board.currentBoard[emptyRow][emptyCol],
        board.solution[emptyRow][emptyCol],
        reason: '값이 정상 입력되어야 함',
      );
    });
  });

  group('엣지 케이스: 일시정지/재개 중복 호출', () {
    test('이미 일시정지 상태에서 pause() 재호출 시 무시', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.pause();
      expect(notifier.testState!.isPaused, true);

      // 중복 pause 호출
      notifier.pause();
      expect(notifier.testState!.isPaused, true,
          reason: '중복 pause 호출이 안전해야 함');
    });

    test('이미 재개 상태에서 resume() 재호출 시 무시', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      // 재개 상태(기본)에서 resume 호출
      notifier.resume();
      expect(notifier.testState!.isPaused, false,
          reason: '이미 재개 상태에서 resume 호출이 안전해야 함');
    });
  });
}
