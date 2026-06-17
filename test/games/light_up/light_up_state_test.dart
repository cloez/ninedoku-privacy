import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/light_up/engine/light_up_board.dart';
import 'package:ninedoku/games/light_up/light_up_state.dart';

void main() {
  LightUpState _createTestState() {
    final cells = List<int>.filled(49, LightUpBoard.empty);
    cells[0] = LightUpBoard.wallBlank;
    cells[10] = 2;

    final puzzle = LightUpBoard(size: 7, cells: cells, fixed: {0, 10});
    final solution = LightUpBoard(
      size: 7,
      cells: List<int>.from(cells),
      fixed: {0, 10},
    );
    return LightUpState(
      puzzle: puzzle,
      solution: solution,
      current: puzzle.copyWith(),
      mode: LightUpGameMode.classic,
      difficulty: LightUpDifficulty.beginner,
    );
  }

  group('LightUpGameMode', () {
    test('모든 모드 존재', () {
      expect(LightUpGameMode.values.length, 3);
      expect(LightUpGameMode.classic.label, '클래식');
      expect(LightUpGameMode.relax.label, '릴렉스');
      expect(LightUpGameMode.dailyPuzzle.label, '오늘의 퍼즐');
    });
  });

  group('LightUpDifficulty', () {
    test('5단계 난이도', () {
      expect(LightUpDifficulty.values.length, 5);
    });

    test('입문: 7×7', () {
      expect(LightUpDifficulty.beginner.gridSize, 7);
      expect(LightUpDifficulty.beginner.label, '입문');
      expect(LightUpDifficulty.beginner.code, 0);
    });

    test('쉬움: 8×8', () {
      expect(LightUpDifficulty.easy.gridSize, 8);
      expect(LightUpDifficulty.easy.code, 1);
    });

    test('보통: 10×10', () {
      expect(LightUpDifficulty.medium.gridSize, 10);
      expect(LightUpDifficulty.medium.code, 2);
    });

    test('어려움: 12×12', () {
      expect(LightUpDifficulty.hard.gridSize, 12);
      expect(LightUpDifficulty.hard.code, 3);
    });

    test('마스터: 14×14', () {
      expect(LightUpDifficulty.master.gridSize, 14);
      expect(LightUpDifficulty.master.code, 4);
    });
  });

  group('LightUpInputMode', () {
    test('3가지 입력 모드', () {
      expect(LightUpInputMode.values.length, 3);
    });
  });

  group('LightUpGrade', () {
    test('퍼펙트: 실수0 힌트0 시간 기준 이내', () {
      final grade = LightUpGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 60,
        difficulty: LightUpDifficulty.beginner,
      );
      expect(grade, LightUpGrade.perfect);
    });

    test('우수: 실수0 힌트0 시간 초과', () {
      final grade = LightUpGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 300,
        difficulty: LightUpDifficulty.beginner,
      );
      expect(grade, LightUpGrade.excellent);
    });

    test('보통: 실수 많음', () {
      final grade = LightUpGrade.evaluate(
        mistakes: 5,
        hints: 5,
        difficulty: LightUpDifficulty.beginner,
      );
      expect(grade, LightUpGrade.good);
    });

    test('기준 시간 — beginner=90', () {
      expect(LightUpGrade.baseTimeForDifficulty(LightUpDifficulty.beginner), 90);
    });

    test('기준 시간 — easy=180', () {
      expect(LightUpGrade.baseTimeForDifficulty(LightUpDifficulty.easy), 180);
    });

    test('기준 시간 — medium=360', () {
      expect(LightUpGrade.baseTimeForDifficulty(LightUpDifficulty.medium), 360);
    });

    test('기준 시간 — hard=600', () {
      expect(LightUpGrade.baseTimeForDifficulty(LightUpDifficulty.hard), 600);
    });

    test('기준 시간 — master=1200', () {
      expect(LightUpGrade.baseTimeForDifficulty(LightUpDifficulty.master), 1200);
    });
  });

  group('LightUpState', () {
    test('초기 상태', () {
      final state = _createTestState();
      expect(state.size, 7);
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.isAutoCompleting, false);
      expect(state.undoStack, isEmpty);
      expect(state.selectedCell, isNull);
      expect(state.currentHintLevel, 0);
      expect(state.hintTargetCell, isNull);
      expect(state.lastHintResult, isNull);
      expect(state.inputMode, LightUpInputMode.bulb);
    });

    test('copyWith — 기본', () {
      final state = _createTestState();
      final updated = state.copyWith(elapsedSeconds: 100, mistakeCount: 3);
      expect(updated.elapsedSeconds, 100);
      expect(updated.mistakeCount, 3);
      expect(updated.size, 7);
    });

    test('copyWith — selectedCell', () {
      final state = _createTestState();
      final withCell = state.copyWith(selectedCell: (2, 3));
      expect(withCell.selectedCell, (2, 3));

      final cleared = withCell.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, isNull);
    });

    test('copyWith — hintTargetCell', () {
      final state = _createTestState();
      final withTarget = state.copyWith(hintTargetCell: (1, 4));
      expect(withTarget.hintTargetCell, (1, 4));

      final cleared = withTarget.copyWith(clearHintTarget: true);
      expect(cleared.hintTargetCell, isNull);
    });

    test('copyWith — inputMode', () {
      final state = _createTestState();
      final cross = state.copyWith(inputMode: LightUpInputMode.crossMark);
      expect(cross.inputMode, LightUpInputMode.crossMark);
    });

    test('JSON 직렬화/역직렬화', () {
      final state = _createTestState().copyWith(
        elapsedSeconds: 120,
        mistakeCount: 2,
        hintCount: 1,
        selectedCell: (3, 4),
      );

      final json = state.toJson();
      final restored = LightUpState.fromJson(json);

      expect(restored.size, 7);
      expect(restored.elapsedSeconds, 120);
      expect(restored.mistakeCount, 2);
      expect(restored.hintCount, 1);
      expect(restored.selectedCell, (3, 4));
      expect(restored.mode, LightUpGameMode.classic);
      expect(restored.difficulty, LightUpDifficulty.beginner);
    });

    test('등급 계산', () {
      final state = _createTestState();
      expect(state.grade, LightUpGrade.perfect); // 0실수, 0힌트, 0초
    });
  });

  group('LightUpUndoAction', () {
    test('생성', () {
      const action = LightUpUndoAction(
        type: LightUpUndoActionType.setValue,
        row: 1,
        col: 2,
        previousValue: -1,
      );
      expect(action.type, LightUpUndoActionType.setValue);
      expect(action.row, 1);
      expect(action.col, 2);
      expect(action.previousValue, -1);
    });
  });
}
