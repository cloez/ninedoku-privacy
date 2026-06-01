import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/features/game/game_state.dart';

/// TC-007: 영속성 테스트
void main() {
  late SharedPreferences prefs;
  late GameStorageService storage;
  late SudokuBoard testBoard;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = GameStorageService(prefs);

    // 테스트용 보드
    final puzzle = List.generate(9, (_) => List.filled(9, 0));
    final solution = List.generate(
      9,
      (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
    );
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 3; c++) {
        puzzle[r][c] = solution[r][c];
      }
    }
    testBoard = SudokuBoard(puzzle: puzzle, solution: solution);
  });

  group('TC-007: 게임 상태 저장/복구', () {
    test('게임 상태 저장 후 정상 복구', () async {
      final state = GameState(
        board: testBoard,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        mistakeCount: 2,
        hintCount: 1,
        elapsedSeconds: 180,
        isPaused: true,
        isMemoMode: true,
        selectedCell: (3, 5),
        showMistakes: true,
      );

      await storage.saveCurrentGame(state);
      final restored = storage.loadCurrentGame();

      expect(restored, isNotNull);
      expect(restored!.mode, GameMode.classic);
      expect(restored.difficulty, Difficulty.easy);
      expect(restored.mistakeCount, 2);
      expect(restored.hintCount, 1);
      expect(restored.elapsedSeconds, 180);
      expect(restored.isPaused, true);
      expect(restored.isMemoMode, true);
      expect(restored.selectedCell, (3, 5));
      expect(restored.showMistakes, true);
    });

    test('보드 상태 복구 정합성', () async {
      // 값 입력 후 저장
      final modifiedBoard = testBoard.setValue(0, 3, 5);
      final state = GameState(
        board: modifiedBoard,
        mode: GameMode.classic,
        difficulty: Difficulty.medium,
      );

      await storage.saveCurrentGame(state);
      final restored = storage.loadCurrentGame();

      expect(restored!.board.currentBoard[0][3], 5);
      // 퍼즐 원본 유지 확인
      expect(restored.board.puzzle[0][3], 0);
      // 정답 유지 확인
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(restored.board.solution[r][c], testBoard.solution[r][c]);
        }
      }
    });

    test('메모(notes) 저장/복구', () async {
      var board = testBoard;
      // 빈 셀에 메모 추가
      board = board.toggleNote(0, 5, 3);
      board = board.toggleNote(0, 5, 7);
      board = board.toggleNote(1, 4, 1);

      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      await storage.saveCurrentGame(state);
      final restored = storage.loadCurrentGame();

      expect(restored!.board.notes[0][5], containsAll([3, 7]));
      expect(restored.board.notes[1][4], contains(1));
      // 빈 메모 셀은 비어있어야 함
      expect(restored.board.notes[0][0], isEmpty);
    });

    test('게임 삭제', () async {
      final state = GameState(
        board: testBoard,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      await storage.saveCurrentGame(state);
      expect(storage.hasCurrentGame(), true);

      await storage.deleteCurrentGame();
      expect(storage.hasCurrentGame(), false);
      expect(storage.loadCurrentGame(), null);
    });

    test('저장된 게임 없을 때 null 반환', () {
      expect(storage.loadCurrentGame(), null);
      expect(storage.hasCurrentGame(), false);
    });

    test('손상된 JSON 시 null 반환 (안전 처리)', () async {
      await prefs.setString('current_game', 'invalid json {{{');
      expect(storage.loadCurrentGame(), null);
      // 손상 데이터 자동 삭제 확인
      expect(storage.hasCurrentGame(), false);
    });

    test('selectedCell null인 상태 저장/복구', () async {
      final state = GameState(
        board: testBoard,
        mode: GameMode.relax,
        difficulty: Difficulty.beginner,
        showMistakes: false,
      );

      await storage.saveCurrentGame(state);
      final restored = storage.loadCurrentGame();

      expect(restored!.selectedCell, null);
      expect(restored.mode, GameMode.relax);
      expect(restored.showMistakes, false);
    });

    test('완료 상태 저장/복구', () async {
      final state = GameState(
        board: testBoard,
        mode: GameMode.classic,
        difficulty: Difficulty.hard,
        isCompleted: true,
        elapsedSeconds: 600,
        mistakeCount: 3,
      );

      await storage.saveCurrentGame(state);
      final restored = storage.loadCurrentGame();

      expect(restored!.isCompleted, true);
      expect(restored.elapsedSeconds, 600);
    });
  });

  group('완료 게임 기록', () {
    test('완료 기록 저장 및 조회', () async {
      final record = CompletedGameRecord(
        mode: 'classic',
        difficulty: 'easy',
        elapsedSeconds: 300,
        mistakeCount: 1,
        hintCount: 0,
        grade: 'A',
        completedAt: DateTime(2026, 5, 26, 14, 30),
      );

      await storage.saveCompletedGame(record);
      final records = storage.loadCompletedGames();

      expect(records.length, 1);
      expect(records[0].mode, 'classic');
      expect(records[0].elapsedSeconds, 300);
      expect(records[0].grade, 'A');
    });

    test('여러 기록 누적 저장', () async {
      for (var i = 0; i < 5; i++) {
        await storage.saveCompletedGame(CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 100 + i * 50,
          mistakeCount: i,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime(2026, 5, 26 + i),
        ));
      }

      final records = storage.loadCompletedGames();
      expect(records.length, 5);
    });

    test('빈 기록 목록', () {
      expect(storage.loadCompletedGames(), isEmpty);
    });

    test('CompletedGameRecord JSON 왕복', () {
      final record = CompletedGameRecord(
        mode: 'relax',
        difficulty: 'beginner',
        elapsedSeconds: 450,
        mistakeCount: 0,
        hintCount: 2,
        grade: 'B',
        completedAt: DateTime(2026, 1, 15, 10, 0),
      );

      final json = record.toJson();
      final restored = CompletedGameRecord.fromJson(json);

      expect(restored.mode, 'relax');
      expect(restored.difficulty, 'beginner');
      expect(restored.elapsedSeconds, 450);
      expect(restored.grade, 'B');
      expect(restored.completedAt, DateTime(2026, 1, 15, 10, 0));
    });
  });

  group('GameState JSON 직렬화', () {
    test('toJson/fromJson 왕복 정합성', () {
      final state = GameState(
        board: testBoard,
        mode: GameMode.dailyPuzzle,
        difficulty: Difficulty.medium,
        mistakeCount: 1,
        hintCount: 2,
        elapsedSeconds: 245,
        isMemoMode: true,
        selectedCell: (7, 2),
      );

      final json = state.toJson();
      final jsonStr = jsonEncode(json);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = GameState.fromJson(decoded);

      expect(restored.mode, GameMode.dailyPuzzle);
      expect(restored.difficulty, Difficulty.medium);
      expect(restored.mistakeCount, 1);
      expect(restored.hintCount, 2);
      expect(restored.elapsedSeconds, 245);
      expect(restored.isMemoMode, true);
      expect(restored.selectedCell, (7, 2));
    });

    test('모든 GameMode JSON 왕복', () {
      for (final mode in GameMode.values) {
        final state = GameState(
          board: testBoard,
          mode: mode,
          difficulty: Difficulty.easy,
        );
        final restored = GameState.fromJson(state.toJson());
        expect(restored.mode, mode);
      }
    });

    test('모든 Difficulty JSON 왕복', () {
      for (final diff in Difficulty.values) {
        final state = GameState(
          board: testBoard,
          mode: GameMode.classic,
          difficulty: diff,
        );
        final restored = GameState.fromJson(state.toJson());
        expect(restored.difficulty, diff);
      }
    });
  });
}
