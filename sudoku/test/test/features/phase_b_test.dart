import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';

void main() {
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
    puzzle = solution.map((r) => List<int>.from(r)).toList();
    puzzle[0][0] = 0;
    puzzle[0][1] = 0;
    puzzle[1][0] = 0;
  });

  group('Item 3: 숫자 우선 입력 모드', () {
    test('InputMode enum 정의 확인', () {
      expect(InputMode.values.length, equals(2));
      expect(InputMode.cellFirst.name, equals('cellFirst'));
      expect(InputMode.numberFirst.name, equals('numberFirst'));
    });

    test('GameState 기본 inputMode는 cellFirst', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );
      expect(state.inputMode, equals(InputMode.cellFirst));
      expect(state.selectedNumber, isNull);
    });

    test('copyWith로 inputMode 변경', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      final changed = state.copyWith(inputMode: InputMode.numberFirst);
      expect(changed.inputMode, equals(InputMode.numberFirst));
    });

    test('copyWith로 selectedNumber 설정 및 해제', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      final withNumber = state.copyWith(selectedNumber: 5);
      expect(withNumber.selectedNumber, equals(5));

      final cleared = withNumber.copyWith(clearSelectedNumber: true);
      expect(cleared.selectedNumber, isNull);
    });

    test('JSON 직렬화/역직렬화에 inputMode, selectedNumber 포함', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        selectedNumber: 3,
      );

      final json = state.toJson();
      expect(json['inputMode'], equals('numberFirst'));
      expect(json['selectedNumber'], equals(3));

      final restored = GameState.fromJson(json);
      expect(restored.inputMode, equals(InputMode.numberFirst));
      expect(restored.selectedNumber, equals(3));
    });

    test('잘못된 inputMode 문자열에서 기본값 반환', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );
      final json = state.toJson();
      json['inputMode'] = 'invalidMode';

      final restored = GameState.fromJson(json);
      expect(restored.inputMode, equals(InputMode.cellFirst));
    });

    test('inputMode가 null인 JSON에서 기본값 반환', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );
      final json = state.toJson();
      json.remove('inputMode');

      final restored = GameState.fromJson(json);
      expect(restored.inputMode, equals(InputMode.cellFirst));
    });
  });

  group('Item 4: 시간 추이 차트 데이터', () {
    test('CompletedGameRecord에 필요한 필드가 모두 있음', () {
      final record = CompletedGameRecord(
        mode: 'classic',
        difficulty: 'beginner',
        elapsedSeconds: 300,
        mistakeCount: 1,
        hintCount: 0,
        grade: 'A',
        completedAt: DateTime(2026, 5, 26),
      );

      expect(record.elapsedSeconds, equals(300));
      expect(record.difficulty, equals('beginner'));
      expect(record.completedAt, equals(DateTime(2026, 5, 26)));
    });

    test('여러 기록을 난이도별로 필터링 가능', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 200,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 1),
        ),
        CompletedGameRecord(
          mode: 'classic', difficulty: 'easy', elapsedSeconds: 400,
          mistakeCount: 1, hintCount: 0, grade: 'A',
          completedAt: DateTime(2026, 5, 2),
        ),
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 250,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 3),
        ),
      ];

      final beginnerRecords = records.where((r) => r.difficulty == 'beginner').toList();
      expect(beginnerRecords.length, equals(2));

      final easyRecords = records.where((r) => r.difficulty == 'easy').toList();
      expect(easyRecords.length, equals(1));
    });

    test('기록을 시간순으로 정렬 가능', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 200,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 3),
        ),
        CompletedGameRecord(
          mode: 'classic', difficulty: 'beginner', elapsedSeconds: 300,
          mistakeCount: 0, hintCount: 0, grade: 'S',
          completedAt: DateTime(2026, 5, 1),
        ),
      ];

      records.sort((a, b) => a.completedAt.compareTo(b.completedAt));
      expect(records.first.elapsedSeconds, equals(300));
      expect(records.last.elapsedSeconds, equals(200));
    });

    test('분 단위 변환 정확', () {
      const seconds = 365;
      final minutes = seconds / 60.0;
      expect(minutes, closeTo(6.083, 0.01));
    });
  });
}
