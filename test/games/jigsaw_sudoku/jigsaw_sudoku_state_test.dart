import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/jigsaw_sudoku/engine/jigsaw_sudoku_board.dart';
import 'package:ninedoku/games/jigsaw_sudoku/engine/jigsaw_sudoku_generator.dart';
import 'package:ninedoku/games/jigsaw_sudoku/jigsaw_sudoku_state.dart';

void main() {
  // 표준 3x3 영역 (테스트 편의용)
  final standardRegions = List.generate(
    9,
    (r) => List.generate(9, (c) => (r ~/ 3) * 3 + (c ~/ 3)),
  );

  JigsawSudokuState _createTestState() {
    final board = JigsawSudokuBoard(
      cells: List.generate(9, (_) => List.filled(9, 0)),
      solution: List.generate(9, (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1)),
      regions: standardRegions,
    );
    return JigsawSudokuState(
      board: board,
      mode: JigsawSudokuGameMode.classic,
      difficulty: JigsawDifficulty.beginner,
    );
  }

  group('JigsawSudokuState', () {
    test('초기 상태', () {
      final state = _createTestState();
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.selectedCell, null);
      expect(state.isNoteMode, false);
    });

    test('copyWith — 기본 필드', () {
      final state = _createTestState();
      final updated = state.copyWith(
        elapsedSeconds: 120,
        mistakeCount: 2,
        isPaused: true,
      );
      expect(updated.elapsedSeconds, 120);
      expect(updated.mistakeCount, 2);
      expect(updated.isPaused, true);
      expect(updated.hintCount, 0); // 변경 안 됨
    });

    test('copyWith — 선택된 셀', () {
      final state = _createTestState();
      final selected = state.copyWith(selectedCell: (3, 4));
      expect(selected.selectedCell, (3, 4));
      final cleared = selected.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, null);
    });

    test('copyWith — 힌트 관련', () {
      final state = _createTestState();
      final withHint = state.copyWith(
        currentHintLevel: 2,
        hintTargetCell: (1, 2),
      );
      expect(withHint.currentHintLevel, 2);
      expect(withHint.hintTargetCell, (1, 2));
      final cleared = withHint.copyWith(
        clearHintTarget: true,
        clearLastHint: true,
      );
      expect(cleared.hintTargetCell, null);
      expect(cleared.lastHintResult, null);
    });

    test('난이도 라벨', () {
      for (final diff in JigsawDifficulty.values) {
        final state = JigsawSudokuState(
          board: JigsawSudokuBoard(
            cells: List.generate(9, (_) => List.filled(9, 0)),
            solution: List.generate(9, (_) => List.filled(9, 0)),
            regions: standardRegions,
          ),
          mode: JigsawSudokuGameMode.classic,
          difficulty: diff,
        );
        expect(state.difficultyLabel.isNotEmpty, true);
      }
    });

    test('등급 산정 — 퍼펙트', () {
      final grade = JigsawSudokuGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 100,
        difficulty: JigsawDifficulty.beginner,
      );
      expect(grade, JigsawSudokuGrade.perfect);
    });

    test('등급 산정 — 훌륭함 (시간 초과)', () {
      final grade = JigsawSudokuGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 999,
        difficulty: JigsawDifficulty.beginner,
      );
      expect(grade, JigsawSudokuGrade.excellent);
    });

    test('등급 산정 — 좋음 (실수 2)', () {
      final grade = JigsawSudokuGrade.evaluate(
        mistakes: 2,
        hints: 0,
      );
      expect(grade, JigsawSudokuGrade.great);
    });

    test('등급 산정 — 보통 (실수 4)', () {
      final grade = JigsawSudokuGrade.evaluate(
        mistakes: 4,
        hints: 0,
      );
      expect(grade, JigsawSudokuGrade.good);
    });

    test('기준 시간', () {
      expect(JigsawSudokuGrade.baseTimeForDifficulty(JigsawDifficulty.beginner), 180);
      expect(JigsawSudokuGrade.baseTimeForDifficulty(JigsawDifficulty.easy), 300);
      expect(JigsawSudokuGrade.baseTimeForDifficulty(JigsawDifficulty.medium), 480);
      expect(JigsawSudokuGrade.baseTimeForDifficulty(JigsawDifficulty.hard), 720);
      expect(JigsawSudokuGrade.baseTimeForDifficulty(JigsawDifficulty.master), 1200);
    });

    test('JSON 직렬화/역직렬화', () {
      final state = _createTestState().copyWith(
        elapsedSeconds: 60,
        mistakeCount: 1,
        hintCount: 2,
        selectedCell: (4, 5),
        isNoteMode: true,
      );
      final json = state.toJson();
      final restored = JigsawSudokuState.fromJson(json);
      expect(restored.elapsedSeconds, 60);
      expect(restored.mistakeCount, 1);
      expect(restored.hintCount, 2);
      expect(restored.selectedCell, (4, 5));
      expect(restored.isNoteMode, true);
      expect(restored.mode, JigsawSudokuGameMode.classic);
      expect(restored.difficulty, JigsawDifficulty.beginner);
    });

    test('게임 모드 라벨', () {
      expect(JigsawSudokuGameMode.classic.label, '클래식');
      expect(JigsawSudokuGameMode.dailyPuzzle.label, '오늘의 퍼즐');
    });
  });

  group('JigsawSudokuUndoAction', () {
    test('생성', () {
      final action = JigsawSudokuUndoAction(
        type: JigsawSudokuUndoType.setValue,
        row: 1,
        col: 2,
        previousValue: 3,
        previousNotes: {4, 5},
      );
      expect(action.type, JigsawSudokuUndoType.setValue);
      expect(action.row, 1);
      expect(action.col, 2);
      expect(action.previousValue, 3);
      expect(action.previousNotes, {4, 5});
    });
  });
}
