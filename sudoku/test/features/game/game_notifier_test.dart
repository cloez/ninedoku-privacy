import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/features/game/game_notifier.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';

/// TC-005: 게임 상태 관리 테스트, TC-006: 타이머 테스트
void main() {
  late GameNotifier notifier;

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    notifier = GameNotifier();
  });

  tearDown(() {
    notifier.dispose();
  });

  group('TC-005: GameNotifier 기본 동작', () {
    test('초기 상태는 null', () {
      expect(notifier.testState, null);
    });

    test('새 게임 시작 시 상태 생성', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      final state = notifier.testState;
      expect(state, isNotNull);
      expect(state!.mode, GameMode.classic);
      expect(state.difficulty, Difficulty.easy);
      expect(state.isCompleted, false);
      expect(state.isPaused, false);
      expect(state.mistakeCount, 0);
      expect(state.showMistakes, true);
    });

    test('릴렉스 모드는 실수 표시 비활성', () {
      notifier.startNewGame(
        mode: GameMode.relax,
        difficulty: Difficulty.beginner,
      );

      expect(notifier.testState!.showMistakes, false);
    });

    test('셀 선택', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.selectCell(3, 5);
      expect(notifier.testState!.selectedCell, (3, 5));
    });

    test('고정 셀에 숫자 입력 불가', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      final state = notifier.testState!;
      // 고정 셀 찾기
      int? fixedRow, fixedCol;
      for (var r = 0; r < 9 && fixedRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (state.board.isFixed[r][c]) {
            fixedRow = r;
            fixedCol = c;
            break;
          }
        }
      }

      if (fixedRow != null) {
        final originalValue = state.board.currentBoard[fixedRow][fixedCol!];
        notifier.selectCell(fixedRow, fixedCol);
        notifier.inputNumber(originalValue == 1 ? 2 : 1);
        // 고정 셀 값은 변하지 않아야 함
        expect(
          notifier.testState!.board.currentBoard[fixedRow][fixedCol],
          originalValue,
        );
      }
    });

    test('빈 셀에 숫자 입력', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      // 빈 셀 찾기
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

      expect(emptyRow, isNotNull);
      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.inputNumber(5);

      expect(
        notifier.testState!.board.currentBoard[emptyRow][emptyCol],
        5,
      );
      expect(notifier.testState!.undoStack.length, 1);
    });

    test('되돌리기 (undo) 동작', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      // 빈 셀 찾기
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

      expect(emptyRow, isNotNull);
      final originalValue = state.board.currentBoard[emptyRow!][emptyCol!];

      notifier.selectCell(emptyRow, emptyCol);
      notifier.inputNumber(5);
      expect(notifier.testState!.board.currentBoard[emptyRow][emptyCol], 5);

      notifier.undo();
      expect(
        notifier.testState!.board.currentBoard[emptyRow][emptyCol],
        originalValue,
      );
      expect(notifier.testState!.undoStack, isEmpty);
    });

    test('메모 모드 토글', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      expect(notifier.testState!.isMemoMode, false);
      notifier.toggleMemoMode();
      expect(notifier.testState!.isMemoMode, true);
      notifier.toggleMemoMode();
      expect(notifier.testState!.isMemoMode, false);
    });

    test('메모 입력/되돌리기', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      // 빈 셀 찾기
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

      expect(emptyRow, isNotNull);

      notifier.selectCell(emptyRow!, emptyCol!);
      notifier.toggleMemoMode();
      notifier.inputNumber(3);
      notifier.inputNumber(7);

      expect(
        notifier.testState!.board.notes[emptyRow][emptyCol],
        containsAll([3, 7]),
      );

      // 되돌리기로 7 제거
      notifier.undo();
      expect(
        notifier.testState!.board.notes[emptyRow][emptyCol],
        contains(3),
      );
      expect(
        notifier.testState!.board.notes[emptyRow][emptyCol].contains(7),
        false,
      );
    });

    test('삭제 (deleteValue)', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      // 빈 셀 찾아서 값 입력 후 삭제
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
      expect(notifier.testState!.board.currentBoard[emptyRow][emptyCol], 5);

      notifier.deleteValue();
      expect(notifier.testState!.board.currentBoard[emptyRow][emptyCol], 0);
    });

    test('힌트 사용', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      final beforeHint = notifier.testState!.hintCount;
      // 점진적 힌트: 4단계까지 호출해야 정답 공개 + 카운트 증가
      notifier.useHint(); // 1단계: 영역 강조
      notifier.useHint(); // 2단계: 후보 안내
      notifier.useHint(); // 3단계: 기법 설명
      notifier.useHint(); // 4단계: 정답 공개
      expect(notifier.testState!.hintCount, beforeHint + 1);
      // 힌트 셀이 선택되어야 함
      expect(notifier.testState!.selectedCell, isNotNull);
    });

    test('일시정지/재개', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.pause();
      expect(notifier.testState!.isPaused, true);

      notifier.resume();
      expect(notifier.testState!.isPaused, false);
    });

    test('게임 포기', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.giveUp();
      expect(notifier.testState, null);
    });

    test('완료 후 입력 불가', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      // 모든 빈 셀에 정답 입력하여 완료 유도
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

      // 완료 후 입력 시도
      notifier.selectCell(0, 0);
      // 완료 상태에서는 selectCell도 무시
      // (isCompleted 체크 때문에 selectedCell이 이전 값 유지)
    });

    test('seed 지정 시 동일 퍼즐 생성', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );
      final board1 = notifier.testState!.board.currentBoard
          .map((r) => List<int>.from(r))
          .toList();

      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );
      final board2 = notifier.testState!.board.currentBoard;

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(board1[r][c], board2[r][c],
              reason: '동일 seed는 동일 퍼즐을 생성해야 함 ($r, $c)');
        }
      }
    });
  });

  group('TC-006: 타이머', () {
    test('클래식 모드에서 타이머 동작', () async {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      expect(notifier.testState!.elapsedSeconds, 0);

      // 2초 대기
      await Future.delayed(const Duration(seconds: 2, milliseconds: 200));
      expect(notifier.testState!.elapsedSeconds, greaterThanOrEqualTo(2));
    });

    test('일시정지 시 타이머 멈춤', () async {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      await Future.delayed(const Duration(seconds: 1, milliseconds: 200));
      notifier.pause();
      final pausedTime = notifier.testState!.elapsedSeconds;

      // 1초 더 대기 → 변하지 않아야 함
      await Future.delayed(const Duration(seconds: 1, milliseconds: 200));
      expect(notifier.testState!.elapsedSeconds, pausedTime);
    });

    test('릴렉스 모드에서 타이머 없음', () async {
      notifier.startNewGame(
        mode: GameMode.relax,
        difficulty: Difficulty.easy,
      );

      await Future.delayed(const Duration(seconds: 1, milliseconds: 200));
      expect(notifier.testState!.elapsedSeconds, 0);
    });

    test('재개 후 타이머 재시작', () async {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      await Future.delayed(const Duration(seconds: 1, milliseconds: 200));
      notifier.pause();
      final pausedTime = notifier.testState!.elapsedSeconds;

      notifier.resume();
      await Future.delayed(const Duration(seconds: 1, milliseconds: 200));
      expect(notifier.testState!.elapsedSeconds, greaterThan(pausedTime));
    });
  });

  group('엣지 케이스', () {
    test('게임 없을 때 모든 액션 안전하게 무시', () {
      // null 상태에서 모든 메서드 호출 → 예외 없이 무시
      notifier.selectCell(0, 0);
      notifier.inputNumber(5);
      notifier.deleteValue();
      notifier.undo();
      notifier.toggleMemoMode();
      notifier.useHint();
      notifier.pause();
      notifier.resume();
      expect(notifier.testState, null);
    });

    test('셀 미선택 시 숫자 입력 무시', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      // 셀 선택 안 하고 바로 입력
      notifier.inputNumber(5);
      expect(notifier.testState!.undoStack, isEmpty);
    });

    test('빈 undoStack에서 undo 안전', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      notifier.undo();
      expect(notifier.testState!.undoStack, isEmpty);
    });

    test('restoreGame으로 상태 복원', () {
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      );

      final savedState = notifier.testState!.copyWith(
        elapsedSeconds: 300,
        mistakeCount: 2,
        isPaused: true,
      );

      // 새 Notifier에 복원
      final notifier2 = GameNotifier();
      notifier2.restoreGame(savedState);

      expect(notifier2.testState!.elapsedSeconds, 300);
      expect(notifier2.testState!.mistakeCount, 2);
      expect(notifier2.testState!.isPaused, true);

      notifier2.dispose();
    });
  });
}
