import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/tents/engine/tents_board.dart';
import 'package:ninedoku/games/tents/engine/tents_generator.dart';
import 'package:ninedoku/games/tents/tents_state.dart';
import 'package:ninedoku/games/tents/tents_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TentsState', () {
    late TentsState state;

    setUp(() {
      final result = TentsGenerator.generate(
        size: 6,
        difficulty: 0,
        seed: 42,
      );
      if (result != null) {
        state = TentsState(
          puzzle: result.puzzle,
          solution: result.solution,
          current: result.puzzle.copyWith(),
          mode: TentsGameMode.classic,
          difficulty: TentsDifficulty.beginner,
        );
      }
    });

    test('초기 상태 검증', () {
      expect(state.size, 6);
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.undoStack, isEmpty);
      expect(state.selectedCell, isNull);
      expect(state.inputMode, TentsInputMode.tent);
    });

    test('copyWith 동작', () {
      final modified = state.copyWith(
        elapsedSeconds: 100,
        mistakeCount: 2,
        isPaused: true,
      );
      expect(modified.elapsedSeconds, 100);
      expect(modified.mistakeCount, 2);
      expect(modified.isPaused, true);
      expect(modified.hintCount, 0);
    });

    test('선택 셀 clearSelectedCell', () {
      final withSel = state.copyWith(selectedCell: (1, 2));
      expect(withSel.selectedCell, (1, 2));

      final cleared = withSel.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, isNull);
    });

    test('JSON 직렬화/역직렬화', () {
      final json = state.toJson();
      final restored = TentsState.fromJson(json);
      expect(restored.size, state.size);
      expect(restored.mode, state.mode);
      expect(restored.difficulty, state.difficulty);
      expect(restored.elapsedSeconds, state.elapsedSeconds);
    });

    test('JSON 직렬화 선택 셀 포함', () {
      final withSel = state.copyWith(selectedCell: (3, 4));
      final json = withSel.toJson();
      final restored = TentsState.fromJson(json);
      expect(restored.selectedCell, (3, 4));
    });
  });

  group('TentsDifficulty', () {
    test('모든 난이도 정의', () {
      expect(TentsDifficulty.values.length, 5);
      expect(TentsDifficulty.beginner.gridSize, 6);
      expect(TentsDifficulty.easy.gridSize, 8);
      expect(TentsDifficulty.medium.gridSize, 10);
      expect(TentsDifficulty.hard.gridSize, 12);
      // master 난이도는 12×12로 축소 (유일해 보장 강화)
      expect(TentsDifficulty.master.gridSize, 12);
    });

    test('난이도 코드', () {
      expect(TentsDifficulty.beginner.code, 0);
      expect(TentsDifficulty.master.code, 4);
    });
  });

  group('TentsGrade', () {
    test('퍼펙트 등급 — 실수/힌트 0 + 기준시간 이내', () {
      final grade = TentsGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 30,
        difficulty: TentsDifficulty.beginner,
      );
      expect(grade, TentsGrade.perfect);
    });

    test('좋음 등급 — 실수/힌트 많음', () {
      final grade = TentsGrade.evaluate(
        mistakes: 5,
        hints: 5,
        difficulty: TentsDifficulty.beginner,
      );
      expect(grade, TentsGrade.good);
    });

    test('훌륭함 등급 — 적은 실수', () {
      final grade = TentsGrade.evaluate(
        mistakes: 1,
        hints: 0,
        difficulty: TentsDifficulty.beginner,
      );
      expect(grade, TentsGrade.excellent);
    });

    test('기준 시간 검증', () {
      expect(TentsGrade.baseTimeForDifficulty(TentsDifficulty.beginner), 60);
      expect(TentsGrade.baseTimeForDifficulty(TentsDifficulty.easy), 120);
      expect(TentsGrade.baseTimeForDifficulty(TentsDifficulty.medium), 300);
      expect(TentsGrade.baseTimeForDifficulty(TentsDifficulty.hard), 600);
      expect(TentsGrade.baseTimeForDifficulty(TentsDifficulty.master), 1200);
    });
  });

  group('TentsNotifier', () {
    test('초기 상태 null', () {
      final notifier = TentsNotifier();
      expect(notifier.state, isNull);
      expect(notifier.hasOngoingGame, false);
      notifier.dispose();
    });

    test('새 게임 시작', () {
      final notifier = TentsNotifier();
      notifier.startNewGame(
        mode: TentsGameMode.classic,
        difficulty: TentsDifficulty.beginner,
      );
      expect(notifier.state, isNotNull);
      expect(notifier.state!.size, 6);
      expect(notifier.state!.isCompleted, false);
      expect(notifier.hasOngoingGame, true);
      notifier.dispose();
    });

    test('포기 시 상태 null', () {
      final notifier = TentsNotifier();
      notifier.startNewGame(
        mode: TentsGameMode.classic,
        difficulty: TentsDifficulty.beginner,
      );
      notifier.giveUp();
      expect(notifier.state, isNull);
      notifier.dispose();
    });

    test('일시정지 및 재개', () {
      final notifier = TentsNotifier();
      notifier.startNewGame(
        mode: TentsGameMode.classic,
        difficulty: TentsDifficulty.beginner,
      );
      notifier.pause();
      expect(notifier.state!.isPaused, true);
      notifier.resume();
      expect(notifier.state!.isPaused, false);
      notifier.dispose();
    });

    test('입력 모드 변경', () {
      final notifier = TentsNotifier();
      notifier.startNewGame(
        mode: TentsGameMode.classic,
        difficulty: TentsDifficulty.beginner,
      );
      expect(notifier.state!.inputMode, TentsInputMode.tent);
      notifier.setInputMode(TentsInputMode.grass);
      expect(notifier.state!.inputMode, TentsInputMode.grass);
      notifier.setInputMode(TentsInputMode.erase);
      expect(notifier.state!.inputMode, TentsInputMode.erase);
      notifier.dispose();
    });

    test('나무 셀 탭 시 무시', () {
      final notifier = TentsNotifier();
      notifier.startNewGame(
        mode: TentsGameMode.classic,
        difficulty: TentsDifficulty.beginner,
      );
      // 나무 위치 찾기
      final treeIdx = notifier.state!.current.treePositions.first;
      final row = treeIdx ~/ 6;
      final col = treeIdx % 6;
      notifier.tapCell(row, col);
      // 나무는 변경 불가
      expect(
        notifier.state!.current.getValue(row, col),
        TentsBoard.tree,
      );
      notifier.dispose();
    });

    test('undo 동작', () {
      final notifier = TentsNotifier();
      notifier.startNewGame(
        mode: TentsGameMode.classic,
        difficulty: TentsDifficulty.beginner,
      );
      // 빈칸 찾기
      final size = notifier.state!.size;
      int? emptyRow, emptyCol;
      for (var r = 0; r < size && emptyRow == null; r++) {
        for (var c = 0; c < size; c++) {
          final idx = r * size + c;
          if (!notifier.state!.current.treePositions.contains(idx) &&
              notifier.state!.current.cells[idx] == TentsBoard.empty) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }
      if (emptyRow != null && emptyCol != null) {
        notifier.tapCell(emptyRow, emptyCol);
        expect(notifier.state!.undoStack.length, 1);
        notifier.undo();
        expect(notifier.state!.undoStack.isEmpty, true);
        expect(
          notifier.state!.current.getValue(emptyRow, emptyCol),
          TentsBoard.empty,
        );
      }
      notifier.dispose();
    });
  });

  group('TentsInputMode', () {
    test('모든 입력 모드 정의', () {
      expect(TentsInputMode.values.length, 3);
      expect(TentsInputMode.tent.index, 0);
      expect(TentsInputMode.grass.index, 1);
      expect(TentsInputMode.erase.index, 2);
    });
  });

  group('TentsUndoAction', () {
    test('생성 및 필드 접근', () {
      const action = TentsUndoAction(
        type: TentsUndoActionType.setValue,
        row: 1,
        col: 2,
        previousValue: 0,
      );
      expect(action.type, TentsUndoActionType.setValue);
      expect(action.row, 1);
      expect(action.col, 2);
      expect(action.previousValue, 0);
    });
  });
}
