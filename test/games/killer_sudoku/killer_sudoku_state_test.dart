import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/killer_sudoku/killer_sudoku_state.dart';
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_board.dart'; // ignore: unused_import
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_generator.dart';

// KillerDifficulty는 generator에서, KillerSudokuGrade는 state에서 가져옴

void main() {
  late KillerSudokuState state;
  late KillerSudokuBoard board;

  setUp(() {
    final result = KillerSudokuGenerator.generate(
      difficulty: KillerDifficulty.beginner,
      seed: 12345,
    );
    board = result!.board;
    state = KillerSudokuState(
      board: board,
      mode: KillerSudokuGameMode.classic,
      difficulty: KillerDifficulty.beginner,
    );
  });

  group('KillerSudokuState', () {
    test('초기 상태 검증', () {
      expect(state.elapsedSeconds, 0);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.selectedCell, isNull);
      expect(state.isNoteMode, false);
      expect(state.undoStack.isEmpty, true);
    });

    test('copyWith 기본 동작', () {
      final updated = state.copyWith(elapsedSeconds: 100);
      expect(updated.elapsedSeconds, 100);
      expect(updated.mistakeCount, 0); // 다른 값은 변경 안 됨
    });

    test('copyWith 선택 셀 설정/해제', () {
      final selected = state.copyWith(selectedCell: (3, 4));
      expect(selected.selectedCell, (3, 4));

      final cleared = selected.copyWith(clearSelectedCell: true);
      expect(cleared.selectedCell, isNull);
    });

    test('copyWith 메모 모드 토글', () {
      final noteOn = state.copyWith(isNoteMode: true);
      expect(noteOn.isNoteMode, true);

      final noteOff = noteOn.copyWith(isNoteMode: false);
      expect(noteOff.isNoteMode, false);
    });

    test('난이도 라벨 반환', () {
      expect(state.difficultyLabel, '입문');

      final hard = state.copyWith(difficulty: KillerDifficulty.hard);
      expect(hard.difficultyLabel, '어려움');
    });
  });

  group('KillerSudokuGrade', () {
    test('퍼펙트 — 실수 0, 힌트 0, 시간 이내', () {
      final grade = KillerSudokuGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 100,
        difficulty: KillerDifficulty.beginner,
      );
      expect(grade, KillerSudokuGrade.perfect);
    });

    test('훌륭함 — 실수 0, 힌트 0, 시간 초과', () {
      final grade = KillerSudokuGrade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 500,
        difficulty: KillerDifficulty.beginner,
      );
      expect(grade, KillerSudokuGrade.excellent);
    });

    test('훌륭함 — 소수 실수', () {
      final grade = KillerSudokuGrade.evaluate(
        mistakes: 1,
        hints: 0,
      );
      expect(grade, KillerSudokuGrade.excellent);
    });

    test('좋음 — 보통 실수', () {
      final grade = KillerSudokuGrade.evaluate(
        mistakes: 2,
        hints: 0,
      );
      expect(grade, KillerSudokuGrade.great);
    });

    test('보통 — 많은 실수', () {
      final grade = KillerSudokuGrade.evaluate(
        mistakes: 5,
        hints: 0,
      );
      expect(grade, KillerSudokuGrade.good);
    });

    test('보통 — 많은 힌트', () {
      final grade = KillerSudokuGrade.evaluate(
        mistakes: 0,
        hints: 5,
      );
      expect(grade, KillerSudokuGrade.good);
    });
  });

  group('KillerSudokuState JSON 직렬화', () {
    test('toJson/fromJson 왕복', () {
      final s = state.copyWith(
        elapsedSeconds: 120,
        mistakeCount: 2,
        hintCount: 1,
        selectedCell: (3, 5),
        isNoteMode: true,
      );

      final json = s.toJson();
      final restored = KillerSudokuState.fromJson(json);

      expect(restored.elapsedSeconds, 120);
      expect(restored.mistakeCount, 2);
      expect(restored.hintCount, 1);
      expect(restored.selectedCell, (3, 5));
      expect(restored.isNoteMode, true);
      expect(restored.mode, KillerSudokuGameMode.classic);
      expect(restored.difficulty, KillerDifficulty.beginner);
    });

    test('selectedCell null일 때도 정상 직렬화', () {
      final json = state.toJson();
      final restored = KillerSudokuState.fromJson(json);
      expect(restored.selectedCell, isNull);
    });
  });

  group('KillerSudokuGameMode', () {
    test('모든 모드 라벨 존재', () {
      for (final mode in KillerSudokuGameMode.values) {
        expect(mode.label.isNotEmpty, true);
      }
    });
  });

  group('기준 시간', () {
    test('난이도별 기준 시간', () {
      expect(
        KillerSudokuGrade.baseTimeForDifficulty(KillerDifficulty.beginner),
        180,
      );
      expect(
        KillerSudokuGrade.baseTimeForDifficulty(KillerDifficulty.easy),
        360,
      );
      expect(
        KillerSudokuGrade.baseTimeForDifficulty(KillerDifficulty.medium),
        600,
      );
      expect(
        KillerSudokuGrade.baseTimeForDifficulty(KillerDifficulty.hard),
        900,
      );
      expect(
        KillerSudokuGrade.baseTimeForDifficulty(KillerDifficulty.master),
        1500,
      );
    });
  });
}
