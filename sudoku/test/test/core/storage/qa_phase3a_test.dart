import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/features/game/game_notifier.dart';
import 'package:ninedoku/features/game/game_state.dart';

/// Phase 3A QA 엣지 케이스 테스트
void main() {
  late SharedPreferences prefs;
  late GameStorageService storage;
  late SudokuBoard testBoard;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = GameStorageService(prefs);

    // 테스트용 보드 생성
    final puzzle = List.generate(9, (_) => List.filled(9, 0));
    final solution = List.generate(
      9,
      (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
    );
    // 첫 3열은 고정 (퍼즐 값)
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 3; c++) {
        puzzle[r][c] = solution[r][c];
      }
    }
    testBoard = SudokuBoard(puzzle: puzzle, solution: solution);
  });

  group('GameNotifier + Storage 통합 테스트', () {
    test('저장 후 새 Notifier로 복원', () async {
      // 첫 번째 Notifier: 게임 시작 + 진행
      final notifier1 = GameNotifier(storage: storage);
      notifier1.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );

      // 빈 셀 찾아서 입력
      final state1 = notifier1.testState!;
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!state1.board.isFixed[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }
      notifier1.selectCell(emptyRow!, emptyCol!);
      notifier1.inputNumber(5);
      notifier1.pause();

      final savedElapsed = notifier1.testState!.elapsedSeconds;
      final savedMistakes = notifier1.testState!.mistakeCount;
      notifier1.dispose();

      // 두 번째 Notifier: 저장소에서 자동 복원
      final notifier2 = GameNotifier(storage: storage);
      expect(notifier2.testState, isNotNull, reason: '저장된 게임이 자동 복원되어야 함');
      expect(notifier2.testState!.isPaused, true, reason: '복원 시 일시정지 상태여야 함');
      expect(notifier2.testState!.elapsedSeconds, savedElapsed);
      expect(notifier2.testState!.mistakeCount, savedMistakes);
      expect(notifier2.testState!.board.currentBoard[emptyRow][emptyCol], 5);
      // UndoStack은 의도적으로 직렬화하지 않음
      expect(notifier2.testState!.undoStack, isEmpty,
          reason: 'UndoStack은 복원하지 않는 설계');
      notifier2.dispose();
    });

    test('완료된 게임은 복원하지 않음', () async {
      // 완료 상태 저장
      final completedState = GameState(
        board: testBoard,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        isCompleted: true,
      );
      await storage.saveCurrentGame(completedState);

      // 새 Notifier: 완료 게임은 무시해야 함
      final notifier = GameNotifier(storage: storage);
      expect(notifier.testState, isNull,
          reason: '완료된 게임은 복원하지 않아야 함');
      notifier.dispose();
    });

    test('새 게임 시작 시 이전 저장 덮어쓰기', () async {
      final notifier = GameNotifier(storage: storage);

      // 첫 번째 게임
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 100,
      );
      notifier.pause();
      final firstBoard = notifier.testState!.board.currentBoard
          .map((r) => List<int>.from(r))
          .toList();

      // 두 번째 게임 (덮어쓰기)
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.medium,
        seed: 200,
      );

      // 저장소 확인: 두 번째 게임이 저장되어야 함
      final loaded = storage.loadCurrentGame();
      expect(loaded, isNotNull);
      expect(loaded!.difficulty, Difficulty.medium);

      // 첫 번째 게임 보드와 다른지 확인
      bool isDifferent = false;
      for (var r = 0; r < 9 && !isDifferent; r++) {
        for (var c = 0; c < 9; c++) {
          if (loaded.board.currentBoard[r][c] != firstBoard[r][c]) {
            isDifferent = true;
            break;
          }
        }
      }
      expect(isDifferent, true, reason: '새 게임이 이전 저장을 덮어써야 함');
      notifier.dispose();
    });

    test('게임 완료 시 current_game 삭제 + completed_games 기록', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 42,
      );

      // 모든 빈 셀에 정답 입력 → 완료
      final board = notifier.testState!.board;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c]) {
            notifier.selectCell(r, c);
            notifier.inputNumber(board.solution[r][c]);
          }
        }
      }

      expect(notifier.testState!.isCompleted, true);
      // current_game 삭제 확인
      expect(storage.hasCurrentGame(), false,
          reason: '완료 시 current_game이 삭제되어야 함');
      // completed_games 기록 확인
      final records = storage.loadCompletedGames();
      expect(records.length, 1, reason: '완료 기록이 1개 저장되어야 함');
      expect(records[0].mode, 'classic');
      expect(records[0].difficulty, 'beginner');
      notifier.dispose();
    });

    test('게임 포기 시 current_game 삭제', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );
      expect(storage.hasCurrentGame(), true);

      notifier.giveUp();
      expect(storage.hasCurrentGame(), false,
          reason: '포기 시 current_game이 삭제되어야 함');
      expect(notifier.testState, isNull);
      notifier.dispose();
    });
  });

  group('앱 생명주기 시뮬레이션', () {
    test('pause 시 상태 자동 저장', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      // 게임 진행 후 일시정지
      final state = notifier.testState!;
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!state.board.isFixed[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }
      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(state.board.solution[emptyRow][emptyCol]);

      notifier.pause();

      // 저장소에 일시정지 상태가 저장되어 있어야 함
      final saved = storage.loadCurrentGame();
      expect(saved, isNotNull);
      expect(saved!.isPaused, true);
      expect(saved.board.currentBoard[emptyRow][emptyCol],
          state.board.solution[emptyRow][emptyCol]);
      notifier.dispose();
    });

    test('didChangeAppLifecycleState - paused 시 자동 일시정지', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      expect(notifier.testState!.isPaused, false);

      // 앱 백그라운드 전환 시뮬레이션
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(notifier.testState!.isPaused, true);
      // 저장소에도 반영되어야 함
      final saved = storage.loadCurrentGame();
      expect(saved, isNotNull);
      expect(saved!.isPaused, true);
      notifier.dispose();
    });

    test('이미 일시정지 상태에서 백그라운드 전환 시 중복 처리 없음', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );
      notifier.pause();
      expect(notifier.testState!.isPaused, true);

      // 다시 백그라운드 전환 — 에러 없이 무시
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(notifier.testState!.isPaused, true);
      notifier.dispose();
    });

    test('완료된 게임에서 백그라운드 전환 시 일시정지하지 않음', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 42,
      );

      // 완료
      final board = notifier.testState!.board;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c]) {
            notifier.selectCell(r, c);
            notifier.inputNumber(board.solution[r][c]);
          }
        }
      }
      expect(notifier.testState!.isCompleted, true);

      // 백그라운드 전환 — 에러 없음
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      // isCompleted 상태 유지
      expect(notifier.testState!.isCompleted, true);
      notifier.dispose();
    });

    test('게임 없을 때 백그라운드 전환 안전', () {
      final notifier = GameNotifier(storage: storage);
      expect(notifier.testState, isNull);

      // 예외 없이 무시
      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      notifier.didChangeAppLifecycleState(AppLifecycleState.inactive);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(notifier.testState, isNull);
      notifier.dispose();
    });
  });

  group('Storage 에러 핸들링 강화', () {
    test('부분적으로 손상된 JSON (필드 누락)', () async {
      // 필수 필드 누락된 JSON
      final partialJson = jsonEncode({
        'board': testBoard.toJson(),
        'mode': 'classic',
        // 'difficulty' 누락
      });
      await prefs.setString('current_game', partialJson);

      // fromJson에서 예외 발생 → null 반환 + 데이터 삭제
      final loaded = storage.loadCurrentGame();
      expect(loaded, isNull, reason: '필수 필드 누락 시 null 반환');
      expect(storage.hasCurrentGame(), false,
          reason: '손상 데이터 자동 삭제');
    });

    test('유효하지 않은 enum 값', () async {
      final invalidJson = jsonEncode({
        'board': testBoard.toJson(),
        'mode': 'invalid_mode',
        'difficulty': 'easy',
        'mistakeCount': 0,
        'hintCount': 0,
        'elapsedSeconds': 0,
        'isPaused': false,
        'isCompleted': false,
        'isMemoMode': false,
        'showMistakes': true,
        'selectedCell': null,
      });
      await prefs.setString('current_game', invalidJson);

      final loaded = storage.loadCurrentGame();
      expect(loaded, isNull, reason: '유효하지 않은 enum 값 시 null 반환');
    });

    test('빈 문자열 JSON', () async {
      await prefs.setString('current_game', '');
      final loaded = storage.loadCurrentGame();
      expect(loaded, isNull);
    });

    test('completed_games 손상 시 빈 리스트 반환', () async {
      await prefs.setString('completed_games', 'not valid json');
      final records = storage.loadCompletedGames();
      expect(records, isEmpty,
          reason: '손상된 completed_games 시 빈 리스트 반환');
    });

    test('completed_games 내부 항목 손상', () async {
      await prefs.setString(
        'completed_games',
        jsonEncode([
          {'mode': 'classic'} // 불완전한 레코드
        ]),
      );
      final records = storage.loadCompletedGames();
      // 파싱 실패 시 빈 리스트 반환
      expect(records, isEmpty);
    });
  });

  group('Storage 없이 GameNotifier 동작 (하위 호환성)', () {
    test('storage=null인 GameNotifier 정상 동작', () {
      final notifier = GameNotifier();
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      expect(notifier.testState, isNotNull);
      expect(notifier.testState!.mode, GameMode.classic);

      // 모든 동작이 에러 없이 수행
      final state = notifier.testState!;
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!state.board.isFixed[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }
      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(5);
      notifier.undo();
      notifier.pause();
      notifier.resume();
      notifier.giveUp();

      expect(notifier.testState, isNull);
      notifier.dispose();
    });

    test('storage=null인 GameNotifier 완료 시 에러 없음', () {
      final notifier = GameNotifier();
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 42,
      );

      // 완료 유도
      final board = notifier.testState!.board;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c]) {
            notifier.selectCell(r, c);
            notifier.inputNumber(board.solution[r][c]);
          }
        }
      }

      expect(notifier.testState!.isCompleted, true);
      notifier.dispose();
    });
  });

  group('GameState toJson/fromJson 정합성 검증', () {
    test('UndoStack은 직렬화에 포함되지 않음', () {
      final state = GameState(
        board: testBoard,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        undoStack: [
          const UndoAction(
            type: UndoActionType.setValue,
            row: 0,
            col: 3,
            previousValue: 0,
          ),
        ],
      );

      final json = state.toJson();
      expect(json.containsKey('undoStack'), false,
          reason: 'UndoStack은 의도적으로 JSON에 포함하지 않음');

      final restored = GameState.fromJson(json);
      expect(restored.undoStack, isEmpty,
          reason: '복원 시 UndoStack은 빈 리스트');
    });

    test('기본값으로 fromJson 안전 처리 (필드 없는 JSON)', () {
      // 최소한의 필드만 있는 JSON (이전 버전 호환 시나리오)
      final minimalJson = {
        'board': testBoard.toJson(),
        'mode': 'classic',
        'difficulty': 'easy',
      };

      final restored = GameState.fromJson(minimalJson);
      expect(restored.mistakeCount, 0);
      expect(restored.hintCount, 0);
      expect(restored.elapsedSeconds, 0);
      expect(restored.isPaused, false);
      expect(restored.isCompleted, false);
      expect(restored.isMemoMode, false);
      expect(restored.showMistakes, true);
      expect(restored.selectedCell, isNull);
    });

    test('selectedCell (0,0) 직렬화/역직렬화', () {
      // (0,0)은 falsy가 아닌 유효한 좌표
      final state = GameState(
        board: testBoard,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        selectedCell: (0, 0),
      );

      final json = state.toJson();
      final restored = GameState.fromJson(json);
      expect(restored.selectedCell, (0, 0),
          reason: '(0,0) 좌표가 정상 복원되어야 함');
    });

    test('큰 elapsedSeconds 값 직렬화', () {
      // 10시간 = 36000초
      final state = GameState(
        board: testBoard,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        elapsedSeconds: 36000,
      );

      final json = state.toJson();
      final restored = GameState.fromJson(json);
      expect(restored.elapsedSeconds, 36000);
    });
  });

  group('_autoSave 호출 위치 검증', () {
    test('숫자 입력 후 자동 저장', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );

      final state = notifier.testState!;
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!state.board.isFixed[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }

      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(5);

      // 저장소에서 확인
      final saved = storage.loadCurrentGame();
      expect(saved, isNotNull);
      expect(saved!.board.currentBoard[emptyRow][emptyCol], 5);
      notifier.dispose();
    });

    test('메모 입력 후 자동 저장', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );

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

      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.toggleMemoMode();
      notifier.inputNumber(3);

      final saved = storage.loadCurrentGame();
      expect(saved, isNotNull);
      expect(saved!.board.notes[emptyRow][emptyCol], contains(3));
      notifier.dispose();
    });

    test('undo 후 자동 저장', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );

      final state = notifier.testState!;
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!state.board.isFixed[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }

      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(5);
      notifier.undo();

      // undo 후 저장된 상태에서 값이 원래대로
      final saved = storage.loadCurrentGame();
      expect(saved, isNotNull);
      expect(saved!.board.currentBoard[emptyRow][emptyCol], 0);
      notifier.dispose();
    });

    test('deleteValue 후 자동 저장', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );

      final state = notifier.testState!;
      int? emptyRow, emptyCol;
      for (var r = 0; r < 9 && emptyRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (!state.board.isFixed[r][c]) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }

      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(5);
      notifier.deleteValue();

      final saved = storage.loadCurrentGame();
      expect(saved, isNotNull);
      expect(saved!.board.currentBoard[emptyRow][emptyCol], 0);
      notifier.dispose();
    });

    test('pause 후 자동 저장', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.pause();

      final saved = storage.loadCurrentGame();
      expect(saved, isNotNull);
      expect(saved!.isPaused, true);
      notifier.dispose();
    });

    test('힌트 사용 후 자동 저장', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      // 점진적 힌트: 4단계까지 호출해야 정답 공개 + 카운트 증가
      notifier.useHint(); // 1단계: 영역 강조
      notifier.useHint(); // 2단계: 후보 안내
      notifier.useHint(); // 3단계: 기법 설명
      notifier.useHint(); // 4단계: 정답 공개

      final saved = storage.loadCurrentGame();
      expect(saved, isNotNull);
      expect(saved!.hintCount, 1);
      notifier.dispose();
    });

    test('toggleMemoMode는 자동 저장하지 않음 (정상 동작)', () {
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      final beforeToggle = storage.loadCurrentGame();
      final beforeMemo = beforeToggle!.isMemoMode;

      notifier.toggleMemoMode();

      // toggleMemoMode에는 _autoSave가 호출되지 않으므로
      // 저장소의 isMemoMode는 변경 전 값 유지
      final afterToggle = storage.loadCurrentGame();
      expect(afterToggle!.isMemoMode, beforeMemo,
          reason: 'toggleMemoMode는 _autoSave를 호출하지 않음');
      notifier.dispose();
    });
  });

  group('SudokuBoard JSON 직렬화 엣지 케이스', () {
    test('메모가 있는 보드 직렬화/역직렬화', () {
      var board = testBoard;
      board = board.toggleNote(0, 5, 1);
      board = board.toggleNote(0, 5, 9);
      board = board.toggleNote(8, 8, 5);

      final json = board.toJson();
      final restored = SudokuBoard.fromJson(json);

      expect(restored.notes[0][5], containsAll([1, 9]));
      expect(restored.notes[8][8], contains(5));
      // 메모 없는 셀은 빈 Set
      expect(restored.notes[0][0], isEmpty);
    });

    test('빈 보드 메모 직렬화 (빈 문자열 처리)', () {
      // 메모가 전혀 없는 보드
      final json = testBoard.toJson();
      final restored = SudokuBoard.fromJson(json);

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(restored.notes[r][c], isEmpty);
        }
      }
    });
  });

  group('Provider 패턴 검증', () {
    test('storage 없는 GameNotifier (인메모리 모드) 정상', () {
      // gameProvider가 storage 없이도 동작하는지 확인
      // (ProviderScope overrides 없이 GameNotifier 직접 생성)
      final notifier = GameNotifier();
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );
      expect(notifier.testState, isNotNull);
      notifier.dispose();
    });
  });

  group('CompletedGameRecord 추가 엣지 케이스', () {
    test('여러 게임 완료 후 기록 누적 확인', () {
      for (var i = 0; i < 3; i++) {
        final notifier = GameNotifier(storage: storage);
        notifier.startNewGame(
          mode: GameMode.classic,
          difficulty: Difficulty.beginner,
          seed: 42 + i,
        );

        final board = notifier.testState!.board;
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (!board.isFixed[r][c]) {
              notifier.selectCell(r, c);
              notifier.inputNumber(board.solution[r][c]);
            }
          }
        }
        expect(notifier.testState!.isCompleted, true);
        notifier.dispose();
      }

      final records = storage.loadCompletedGames();
      expect(records.length, 3, reason: '3게임 완료 기록이 누적되어야 함');
    });

    test('CompletedGameRecord.completedAt 시간 정밀도', () async {
      final before = DateTime.now();
      final notifier = GameNotifier(storage: storage);
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 42,
      );

      final board = notifier.testState!.board;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!board.isFixed[r][c]) {
            notifier.selectCell(r, c);
            notifier.inputNumber(board.solution[r][c]);
          }
        }
      }
      final after = DateTime.now();

      final records = storage.loadCompletedGames();
      expect(records.length, 1);
      // completedAt이 before~after 범위 내
      expect(records[0].completedAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(records[0].completedAt.isBefore(after.add(const Duration(seconds: 1))), true);
      notifier.dispose();
    });
  });
}
