import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';

/// TC-005: 게임 상태 테스트
void main() {
  late SudokuBoard board;

  setUp(() {
    // 간단한 테스트용 보드
    final puzzle = List.generate(9, (_) => List.filled(9, 0));
    final solution = List.generate(9, (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1));
    // 일부 셀만 고정
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 3; c++) {
        puzzle[r][c] = solution[r][c];
      }
    }
    board = SudokuBoard(puzzle: puzzle, solution: solution);
  });

  group('GameState 기본', () {
    test('초기 상태 기본값 확인', () {
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.elapsedSeconds, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.isMemoMode, false);
      expect(state.selectedCell, null);
      expect(state.showMistakes, true);
      expect(state.undoStack, isEmpty);
    });

    test('copyWith로 필드 변경', () {
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      final updated = state.copyWith(
        mistakeCount: 2,
        hintCount: 1,
        elapsedSeconds: 120,
        isPaused: true,
        isMemoMode: true,
        selectedCell: (3, 4),
      );

      expect(updated.mistakeCount, 2);
      expect(updated.hintCount, 1);
      expect(updated.elapsedSeconds, 120);
      expect(updated.isPaused, true);
      expect(updated.isMemoMode, true);
      expect(updated.selectedCell, (3, 4));
      // 변경하지 않은 필드는 유지
      expect(updated.mode, GameMode.classic);
      expect(updated.difficulty, Difficulty.easy);
      expect(updated.isCompleted, false);
    });

    test('copyWith clearSelectedCell', () {
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      ).copyWith(selectedCell: (1, 1));

      expect(state.selectedCell, (1, 1));

      final cleared = state.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, null);
    });

    test('릴렉스 모드 showMistakes 기본값', () {
      // 릴렉스 모드에서도 showMistakes는 생성자 호출 시 결정
      final state = GameState(
        board: board,
        mode: GameMode.relax,
        difficulty: Difficulty.beginner,
        showMistakes: false,
      );
      expect(state.showMistakes, false);
    });
  });

  group('Grade 평가', () {
    test('실수 0, 힌트 0 → perfect (S)', () {
      expect(Grade.evaluate(mistakes: 0, hints: 0), Grade.perfect);
    });

    test('실수 1, 힌트 0 → excellent (A)', () {
      expect(Grade.evaluate(mistakes: 1, hints: 0), Grade.excellent);
    });

    test('실수 0, 힌트 1 → excellent (A)', () {
      expect(Grade.evaluate(mistakes: 0, hints: 1), Grade.excellent);
    });

    test('실수 1, 힌트 1 → excellent (A)', () {
      expect(Grade.evaluate(mistakes: 1, hints: 1), Grade.excellent);
    });

    test('실수 3, 힌트 3 → great (B)', () {
      expect(Grade.evaluate(mistakes: 3, hints: 3), Grade.great);
    });

    test('실수 2, 힌트 2 → great (B)', () {
      expect(Grade.evaluate(mistakes: 2, hints: 2), Grade.great);
    });

    test('실수 4, 힌트 0 → good (C)', () {
      expect(Grade.evaluate(mistakes: 4, hints: 0), Grade.good);
    });

    test('실수 0, 힌트 4 → good (C)', () {
      expect(Grade.evaluate(mistakes: 0, hints: 4), Grade.good);
    });

    test('대량 실수/힌트 → good (C)', () {
      expect(Grade.evaluate(mistakes: 10, hints: 10), Grade.good);
    });
  });

  group('GameMode', () {
    test('모드 라벨 확인', () {
      expect(GameMode.classic.label, '클래식');
      expect(GameMode.dailyPuzzle.label, '오늘의 퍼즐');
      expect(GameMode.relax.label, '릴렉스');
    });
  });

  group('UndoAction', () {
    test('setValue 액션 생성', () {
      final action = UndoAction(
        type: UndoActionType.setValue,
        row: 3,
        col: 5,
        previousValue: 7,
        previousNotes: {1, 3, 5},
      );

      expect(action.type, UndoActionType.setValue);
      expect(action.row, 3);
      expect(action.col, 5);
      expect(action.previousValue, 7);
      expect(action.previousNotes, {1, 3, 5});
    });

    test('toggleNote 액션 생성', () {
      final action = UndoAction(
        type: UndoActionType.toggleNote,
        row: 0,
        col: 0,
        previousNotes: {2, 4},
      );

      expect(action.type, UndoActionType.toggleNote);
      expect(action.previousValue, null);
      expect(action.previousNotes, {2, 4});
    });

    test('clearValue 액션 생성', () {
      final action = UndoAction(
        type: UndoActionType.clearValue,
        row: 8,
        col: 8,
        previousValue: 9,
      );

      expect(action.type, UndoActionType.clearValue);
      expect(action.previousValue, 9);
      expect(action.previousNotes, null);
    });
  });

  group('GameState grade 속성', () {
    test('상태에서 grade 계산', () {
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.medium,
        mistakeCount: 0,
        hintCount: 0,
      );
      expect(state.grade, Grade.perfect);

      final state2 = state.copyWith(mistakeCount: 5, hintCount: 5);
      expect(state2.grade, Grade.good);
    });
  });

  group('UndoStack 관리', () {
    test('undoStack에 액션 추가', () {
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      final action = UndoAction(
        type: UndoActionType.setValue,
        row: 0,
        col: 3,
        previousValue: 0,
      );

      final updated = state.copyWith(undoStack: [...state.undoStack, action]);
      expect(updated.undoStack.length, 1);
      expect(updated.undoStack.first.type, UndoActionType.setValue);
    });
  });
}
