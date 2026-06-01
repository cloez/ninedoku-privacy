import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/games/binairo/binairo_notifier.dart';
import 'package:ninedoku/games/binairo/binairo_state.dart';

/// 비나이로 게임 로직(Notifier) 테스트
void main() {
  late BinairoNotifier notifier;
  late SharedPreferences prefs;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    notifier = BinairoNotifier(prefs: prefs);
  });

  tearDown(() {
    notifier.dispose();
  });

  // ════════════════════════════════════════════════════════════════════
  // 기본 동작 테스트
  // ════════════════════════════════════════════════════════════════════
  group('BinairoNotifier 기본 동작', () {
    test('초기 상태는 null', () {
      expect(notifier.debugState, isNull);
    });

    test('startNewGame 시 상태 생성 확인', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState;
      expect(state, isNotNull);
      expect(state!.mode, BinairoGameMode.classic);
      expect(state.difficulty, BinairoDifficulty.beginner);
      expect(state.isCompleted, false);
      expect(state.isPaused, false);
      expect(state.mistakeCount, 0);
      expect(state.hintCount, 0);
      expect(state.elapsedSeconds, 0);
    });

    test('startNewGame 시 size가 difficulty.gridSize와 일치', () {
      for (final diff in BinairoDifficulty.values) {
        // master(14x14)는 생성 시간이 길 수 있으므로 beginner~medium만 테스트
        if (diff.gridSize > 10) continue;
        notifier.startNewGame(
          mode: BinairoGameMode.classic,
          difficulty: diff,
        );
        final state = notifier.debugState;
        expect(state, isNotNull, reason: '${diff.name} 퍼즐 생성 실패');
        if (state != null) {
          expect(state.size, diff.gridSize,
              reason: '${diff.name} gridSize 불일치');
        }
      }
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 셀 입력 테스트
  // ════════════════════════════════════════════════════════════════════
  group('셀 입력 (tapCell)', () {
    /// 빈 셀의 (row, col)을 찾는 헬퍼
    (int, int)? _findEmptyNonFixedCell(BinairoState state) {
      for (var r = 0; r < state.size; r++) {
        for (var c = 0; c < state.size; c++) {
          final idx = r * state.size + c;
          if (!state.current.fixed.contains(idx) &&
              state.current.getValue(r, c) == -1) {
            return (r, c);
          }
        }
      }
      return null;
    }

    /// 고정 셀의 (row, col)을 찾는 헬퍼
    (int, int)? _findFixedCell(BinairoState state) {
      for (var r = 0; r < state.size; r++) {
        for (var c = 0; c < state.size; c++) {
          final idx = r * state.size + c;
          if (state.current.fixed.contains(idx)) {
            return (r, c);
          }
        }
      }
      return null;
    }

    test('빈 셀에 검은 원(black 모드) 배치', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState!;
      final cell = _findEmptyNonFixedCell(state);
      expect(cell, isNotNull, reason: '빈 셀이 없으면 테스트 불가');

      final (row, col) = cell!;
      // 기본 모드는 black
      expect(state.inputMode, BinairoInputMode.black);
      notifier.tapCell(row, col);

      // 검은 원(0)이 배치되어야 함
      expect(notifier.debugState!.current.getValue(row, col), 0);
      expect(notifier.debugState!.undoStack.length, 1);
    });

    test('같은 셀 재탭 시 지움 (토글)', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState!;
      final cell = _findEmptyNonFixedCell(state);
      expect(cell, isNotNull);

      final (row, col) = cell!;
      // 첫 번째 탭: 검은 원 배치
      notifier.tapCell(row, col);
      expect(notifier.debugState!.current.getValue(row, col), 0);

      // 두 번째 탭: 검은 원 다시 탭 → 지움
      notifier.tapCell(row, col);
      expect(notifier.debugState!.current.getValue(row, col), -1);
    });

    test('white 모드에서 흰 원 배치', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState!;
      final cell = _findEmptyNonFixedCell(state);
      expect(cell, isNotNull);

      final (row, col) = cell!;
      notifier.setInputMode(BinairoInputMode.white);
      notifier.tapCell(row, col);

      // 흰 원(1)이 배치되어야 함
      expect(notifier.debugState!.current.getValue(row, col), 1);
    });

    test('erase 모드에서 셀 지움', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState!;
      final cell = _findEmptyNonFixedCell(state);
      expect(cell, isNotNull);

      final (row, col) = cell!;
      // 먼저 검은 원 배치
      notifier.tapCell(row, col);
      expect(notifier.debugState!.current.getValue(row, col), 0);

      // erase 모드로 전환 후 지우기
      notifier.setInputMode(BinairoInputMode.erase);
      notifier.tapCell(row, col);
      expect(notifier.debugState!.current.getValue(row, col), -1);
    });

    test('고정 셀은 변경 불가', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState!;
      final fixedCell = _findFixedCell(state);
      expect(fixedCell, isNotNull, reason: '고정 셀이 없으면 테스트 불가');

      final (row, col) = fixedCell!;
      final originalValue = state.current.getValue(row, col);

      notifier.tapCell(row, col);

      // 값이 변하지 않아야 함
      expect(notifier.debugState!.current.getValue(row, col), originalValue);
      // undoStack에도 추가되지 않아야 함
      expect(notifier.debugState!.undoStack, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 입력 모드 전환 테스트
  // ════════════════════════════════════════════════════════════════════
  group('입력 모드 전환', () {
    test('setInputMode로 모드 전환 확인', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      expect(notifier.debugState!.inputMode, BinairoInputMode.black);

      notifier.setInputMode(BinairoInputMode.white);
      expect(notifier.debugState!.inputMode, BinairoInputMode.white);

      notifier.setInputMode(BinairoInputMode.erase);
      expect(notifier.debugState!.inputMode, BinairoInputMode.erase);

      notifier.setInputMode(BinairoInputMode.black);
      expect(notifier.debugState!.inputMode, BinairoInputMode.black);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // Undo 테스트
  // ════════════════════════════════════════════════════════════════════
  group('Undo 동작', () {
    test('마지막 동작 되돌리기', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState!;
      // 빈 셀 찾기
      (int, int)? cell;
      for (var r = 0; r < state.size; r++) {
        for (var c = 0; c < state.size; c++) {
          final idx = r * state.size + c;
          if (!state.current.fixed.contains(idx) &&
              state.current.getValue(r, c) == -1) {
            cell = (r, c);
            break;
          }
        }
        if (cell != null) break;
      }
      expect(cell, isNotNull);

      final (row, col) = cell!;
      // 검은 원 배치
      notifier.tapCell(row, col);
      expect(notifier.debugState!.current.getValue(row, col), 0);
      expect(notifier.debugState!.undoStack.length, 1);

      // undo
      notifier.undo();
      expect(notifier.debugState!.current.getValue(row, col), -1);
      expect(notifier.debugState!.undoStack, isEmpty);
    });

    test('빈 스택에서 undo 호출 시 아무 일 없음', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      expect(notifier.debugState!.undoStack, isEmpty);
      notifier.undo(); // 예외 없이 무시
      expect(notifier.debugState!.undoStack, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 일시정지 / 재개 테스트
  // ════════════════════════════════════════════════════════════════════
  group('일시정지 / 재개', () {
    test('pause / resume 동작', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      expect(notifier.debugState!.isPaused, false);

      notifier.pause();
      expect(notifier.debugState!.isPaused, true);

      notifier.resume();
      expect(notifier.debugState!.isPaused, false);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 포기 테스트
  // ════════════════════════════════════════════════════════════════════
  group('포기', () {
    test('giveUp 시 상태 null로 변경', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      expect(notifier.debugState, isNotNull);
      notifier.giveUp();
      expect(notifier.debugState, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 완료 판정 테스트
  // ════════════════════════════════════════════════════════════════════
  group('완료 판정', () {
    test('모든 셀이 정답으로 채워지면 isCompleted = true', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState!;
      final size = state.size;

      // 모든 빈 셀에 정답 입력 (setCell 사용)
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          final idx = r * size + c;
          if (!state.current.fixed.contains(idx)) {
            final correctValue = state.solution.getValue(r, c);
            // 입력 모드를 올바르게 설정
            if (correctValue == 0) {
              notifier.setInputMode(BinairoInputMode.black);
            } else {
              notifier.setInputMode(BinairoInputMode.white);
            }
            notifier.tapCell(r, c);
          }
        }
      }

      expect(notifier.debugState!.isCompleted, true);
    });

    test('완료 시 CompletedGameRecord 저장 확인', () {
      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );

      final state = notifier.debugState!;
      final size = state.size;

      // 모든 빈 셀에 정답 입력
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          final idx = r * size + c;
          if (!state.current.fixed.contains(idx)) {
            final correctValue = state.solution.getValue(r, c);
            if (correctValue == 0) {
              notifier.setInputMode(BinairoInputMode.black);
            } else {
              notifier.setInputMode(BinairoInputMode.white);
            }
            notifier.tapCell(r, c);
          }
        }
      }

      expect(notifier.debugState!.isCompleted, true);
      // SharedPreferences에 binairo_completed_games 키가 저장되었는지 확인
      final savedJson = prefs.getString('binairo_completed_games');
      expect(savedJson, isNotNull, reason: '완료 기록이 SharedPreferences에 저장되어야 함');
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 엣지 케이스 테스트
  // ════════════════════════════════════════════════════════════════════
  group('엣지 케이스', () {
    test('게임 없을 때 모든 액션 안전하게 무시', () {
      // null 상태에서 모든 메서드 호출 → 예외 없이 무시
      notifier.tapCell(0, 0);
      notifier.setInputMode(BinairoInputMode.white);
      notifier.undo();
      notifier.pause();
      notifier.resume();
      notifier.getHint();
      expect(notifier.debugState, isNull);
    });

    test('hasOngoingGame 속성 확인', () {
      expect(notifier.hasOngoingGame, false);

      notifier.startNewGame(
        mode: BinairoGameMode.classic,
        difficulty: BinairoDifficulty.beginner,
      );
      expect(notifier.hasOngoingGame, true);

      notifier.giveUp();
      expect(notifier.hasOngoingGame, false);
    });
  });
}
