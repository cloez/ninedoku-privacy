import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/star_battle/engine/star_battle_board.dart';
import 'package:ninedoku/games/star_battle/star_battle_state.dart';

void main() {
  // 테스트용 6×6 영역
  final testRegions = [
    0, 0, 0, 1, 1, 1,
    0, 0, 2, 1, 1, 3,
    2, 2, 2, 2, 3, 3,
    4, 4, 2, 5, 3, 3,
    4, 4, 5, 5, 5, 3,
    4, 4, 5, 5, 5, 3,
  ];

  StarBattleState _createTestState() {
    final puzzle = StarBattleBoard.empty(6, testRegions, 1);
    final solution = StarBattleBoard(
      size: 6,
      cells: List<int>.filled(36, 0), // 임시 해답
      regions: testRegions,
      starCount: 1,
    );
    return StarBattleState(
      puzzle: puzzle,
      solution: solution,
      current: puzzle.copyWith(),
      mode: StarBattleGameMode.classic,
      difficulty: StarBattleDifficulty.beginner,
    );
  }

  group('StarBattleGameMode', () {
    test('모든 모드 존재', () {
      expect(StarBattleGameMode.values.length, 3);
      expect(StarBattleGameMode.classic.label, '클래식');
      expect(StarBattleGameMode.relax.label, '릴렉스');
      expect(StarBattleGameMode.dailyPuzzle.label, '오늘의 퍼즐');
    });
  });

  group('StarBattleDifficulty', () {
    test('5단계 난이도', () {
      expect(StarBattleDifficulty.values.length, 5);
    });

    test('입문: 6×6, 1-star', () {
      expect(StarBattleDifficulty.beginner.gridSize, 6);
      expect(StarBattleDifficulty.beginner.starCount, 1);
      expect(StarBattleDifficulty.beginner.label, '입문');
      expect(StarBattleDifficulty.beginner.code, 0);
    });

    test('쉬움: 7×7, 1-star', () {
      expect(StarBattleDifficulty.easy.gridSize, 7);
      expect(StarBattleDifficulty.easy.starCount, 1);
    });

    test('보통: 8×8, 1-star', () {
      expect(StarBattleDifficulty.medium.gridSize, 8);
      expect(StarBattleDifficulty.medium.starCount, 1);
    });

    test('어려움: 9×9, 2-star', () {
      expect(StarBattleDifficulty.hard.gridSize, 9);
      expect(StarBattleDifficulty.hard.starCount, 2);
    });

    test('마스터: 10×10, 2-star', () {
      expect(StarBattleDifficulty.master.gridSize, 10);
      expect(StarBattleDifficulty.master.starCount, 2);
    });
  });

  group('StarBattleInputMode', () {
    test('3가지 입력 모드', () {
      expect(StarBattleInputMode.values.length, 3);
      expect(StarBattleInputMode.star, isNotNull);
      expect(StarBattleInputMode.cross, isNotNull);
      expect(StarBattleInputMode.erase, isNotNull);
    });
  });

  group('StarBattleGrade', () {
    test('S등급 — 실수 0, 힌트 0, 시간 이내', () {
      final grade = StarBattleGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 30,
        difficulty: StarBattleDifficulty.beginner,
      );
      expect(grade, StarBattleGrade.perfect);
    });

    test('A등급 — 실수 0, 힌트 0, 시간 초과', () {
      final grade = StarBattleGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 200, // 기준 60초 초과
        difficulty: StarBattleDifficulty.beginner,
      );
      expect(grade, StarBattleGrade.excellent);
    });

    test('C등급 — 실수/힌트 많음', () {
      final grade = StarBattleGrade.evaluate(
        mistakes: 5,
        hints: 5,
        difficulty: StarBattleDifficulty.beginner,
      );
      expect(grade, StarBattleGrade.good);
    });

    test('기준 시간 — 입문 60초', () {
      expect(
        StarBattleGrade.baseTimeForDifficulty(StarBattleDifficulty.beginner),
        60,
      );
    });

    test('기준 시간 — 마스터 1200초', () {
      expect(
        StarBattleGrade.baseTimeForDifficulty(StarBattleDifficulty.master),
        1200,
      );
    });
  });

  group('StarBattleState', () {
    test('초기 상태 검증', () {
      final state = _createTestState();
      expect(state.size, 6);
      expect(state.starCount, 1);
      expect(state.mode, StarBattleGameMode.classic);
      expect(state.difficulty, StarBattleDifficulty.beginner);
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
      expect(state.inputMode, StarBattleInputMode.star);
    });

    test('copyWith — 기본값 유지', () {
      final state = _createTestState();
      final copy = state.copyWith();
      expect(copy.size, state.size);
      expect(copy.mode, state.mode);
      expect(copy.elapsedSeconds, state.elapsedSeconds);
    });

    test('copyWith — 특정 필드 변경', () {
      final state = _createTestState();
      final updated = state.copyWith(
        elapsedSeconds: 100,
        mistakeCount: 2,
        isPaused: true,
        inputMode: StarBattleInputMode.cross,
      );
      expect(updated.elapsedSeconds, 100);
      expect(updated.mistakeCount, 2);
      expect(updated.isPaused, true);
      expect(updated.inputMode, StarBattleInputMode.cross);
    });

    test('copyWith — clearSelectedCell', () {
      final state = _createTestState().copyWith(selectedCell: (2, 3));
      expect(state.selectedCell, (2, 3));
      final cleared = state.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, isNull);
    });

    test('copyWith — clearHintTarget', () {
      final state = _createTestState().copyWith(hintTargetCell: (1, 1));
      expect(state.hintTargetCell, (1, 1));
      final cleared = state.copyWith(clearHintTarget: true);
      expect(cleared.hintTargetCell, isNull);
    });

    test('grade 속성 접근', () {
      final state = _createTestState();
      expect(state.grade, isA<StarBattleGrade>());
    });

    test('JSON 직렬화/역직렬화', () {
      final state = _createTestState().copyWith(
        elapsedSeconds: 42,
        mistakeCount: 1,
        selectedCell: (3, 4),
      );
      final json = state.toJson();
      final restored = StarBattleState.fromJson(json);
      expect(restored.size, state.size);
      expect(restored.elapsedSeconds, 42);
      expect(restored.mistakeCount, 1);
      expect(restored.selectedCell, (3, 4));
      expect(restored.mode, StarBattleGameMode.classic);
      expect(restored.difficulty, StarBattleDifficulty.beginner);
    });

    test('JSON 직렬화 — selectedCell null', () {
      final state = _createTestState();
      final json = state.toJson();
      final restored = StarBattleState.fromJson(json);
      expect(restored.selectedCell, isNull);
    });

    test('JSON 직렬화 — hintTargetCell 포함', () {
      final state = _createTestState().copyWith(
        hintTargetCell: (2, 5),
        currentHintLevel: 2,
      );
      final json = state.toJson();
      final restored = StarBattleState.fromJson(json);
      expect(restored.hintTargetCell, (2, 5));
      expect(restored.currentHintLevel, 2);
    });
  });

  group('StarBattleUndoAction', () {
    test('생성 및 필드 접근', () {
      const action = StarBattleUndoAction(
        type: StarBattleUndoActionType.setValue,
        row: 1,
        col: 2,
        previousValue: -1,
      );
      expect(action.type, StarBattleUndoActionType.setValue);
      expect(action.row, 1);
      expect(action.col, 2);
      expect(action.previousValue, -1);
    });
  });
}
