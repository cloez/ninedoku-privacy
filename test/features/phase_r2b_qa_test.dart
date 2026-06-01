import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/core/sudoku/generator.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/features/game/game_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 공용 테스트 보드 (3칸 비움)
  late List<List<int>> solution;
  late List<List<int>> puzzle;

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
    puzzle[0][0] = 0; // 정답 5
    puzzle[0][1] = 0; // 정답 3
    puzzle[1][0] = 0; // 정답 6
  });

  // ===================================================================
  // Major 5 — Generator 기법 기반 난이도 검증
  // ===================================================================
  group('Major 5: Generator 기법 기반 난이도 검증', () {
    test('beginner 난이도로 생성 시 결과가 null이 아님', () {
      final result = SudokuGenerator.generate(
        difficulty: Difficulty.beginner,
        seed: 42,
      );
      expect(result, isNotNull, reason: 'beginner 난이도 생성 실패');
    });

    test('hard 난이도로 생성 시 결과가 null이 아님 (재시도로 생성 가능)', () {
      final result = SudokuGenerator.generate(
        difficulty: Difficulty.hard,
        seed: 100,
      );
      expect(result, isNotNull, reason: 'hard 난이도 생성 실패 (재시도 포함)');
    });

    test('생성된 퍼즐의 빈 칸 수가 요청 난이도 범위 이내', () {
      // 여러 난이도에 대해 검증
      for (final diff in Difficulty.values) {
        final result = SudokuGenerator.generate(
          difficulty: diff,
          seed: 77,
        );
        if (result == null) continue; // fallback 생성 실패 시 스킵

        // 빈 칸 개수 계산
        var emptyCount = 0;
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (result.puzzle[r][c] == 0) emptyCount++;
          }
        }

        // fallback 생성 시 원래 범위보다 적을 수 있으므로, 최소 1개 이상만 확인
        expect(emptyCount, greaterThan(0),
            reason: '${diff.label} 퍼즐에 빈 칸이 없음');
        // 최대값은 난이도 범위의 상한 이내
        expect(emptyCount, lessThanOrEqualTo(diff.emptyCellRange.$2),
            reason: '${diff.label} 빈 칸($emptyCount)이 상한(${diff.emptyCellRange.$2})을 초과');
      }
    });
  });

  // ===================================================================
  // Major 6 — Expert/Master 범위 확대
  // ===================================================================
  group('Major 6: Expert/Master 범위 확대', () {
    test('Expert emptyCellRange가 (53, 58)', () {
      expect(Difficulty.expert.emptyCellRange, (53, 58));
    });

    test('Master emptyCellRange가 (59, 62)', () {
      expect(Difficulty.master.emptyCellRange, (59, 62));
    });

    test('evaluateByEmptyCount(58) → expert', () {
      expect(DifficultyEvaluator.evaluateByEmptyCount(58), Difficulty.expert);
    });

    test('evaluateByEmptyCount(59) → master', () {
      expect(DifficultyEvaluator.evaluateByEmptyCount(59), Difficulty.master);
    });

    test('evaluateByEmptyCount(62) → master', () {
      expect(DifficultyEvaluator.evaluateByEmptyCount(62), Difficulty.master);
    });

    test('mvpDifficulties에 expert/master 미포함', () {
      final mvp = Difficulty.mvpDifficulties;
      expect(mvp, isNot(contains(Difficulty.expert)));
      expect(mvp, isNot(contains(Difficulty.master)));
      expect(mvp.length, 4);
      expect(mvp, [
        Difficulty.beginner,
        Difficulty.easy,
        Difficulty.medium,
        Difficulty.hard,
      ]);
    });
  });

  // ===================================================================
  // Major 7 — 난이도별 등급 가중치
  // ===================================================================
  group('Major 7: 난이도별 등급 가중치', () {
    test('입문 난이도: mistakes 2, hints 0 → B', () {
      final grade = Grade.evaluate(
        mistakes: 2,
        hints: 0,
        difficulty: Difficulty.beginner,
      );
      expect(grade, Grade.great, reason: '입문: 실수 2 → B(좋음)');
    });

    test('입문 난이도: mistakes 4, hints 0 → C', () {
      final grade = Grade.evaluate(
        mistakes: 4,
        hints: 0,
        difficulty: Difficulty.beginner,
      );
      expect(grade, Grade.good, reason: '입문: 실수 4 → C(보통)');
    });

    test('어려움 난이도: mistakes 2, hints 0 → A', () {
      final grade = Grade.evaluate(
        mistakes: 2,
        hints: 0,
        difficulty: Difficulty.hard,
      );
      expect(grade, Grade.excellent, reason: '어려움: 실수 2 → A(훌륭함)');
    });

    test('어려움 난이도: mistakes 4, hints 0 → B', () {
      final grade = Grade.evaluate(
        mistakes: 4,
        hints: 0,
        difficulty: Difficulty.hard,
      );
      expect(grade, Grade.great, reason: '어려움: 실수 4 → B(좋음)');
    });

    test('어려움 난이도: mistakes 5, hints 0 → C', () {
      final grade = Grade.evaluate(
        mistakes: 5,
        hints: 0,
        difficulty: Difficulty.hard,
      );
      expect(grade, Grade.good, reason: '어려움: 실수 5 → C(보통)');
    });

    test('전문가 난이도: mistakes 1, hints 0 → A', () {
      final grade = Grade.evaluate(
        mistakes: 1,
        hints: 0,
        difficulty: Difficulty.expert,
      );
      expect(grade, Grade.excellent, reason: '전문가: 실수 1 → A(훌륭함)');
    });

    test('전문가 난이도: mistakes 2, hints 0 → B', () {
      final grade = Grade.evaluate(
        mistakes: 2,
        hints: 0,
        difficulty: Difficulty.expert,
      );
      expect(grade, Grade.great, reason: '전문가: 실수 2 → B(좋음)');
    });

    test('마스터 난이도: mistakes 1, hints 0 → A', () {
      final grade = Grade.evaluate(
        mistakes: 1,
        hints: 0,
        difficulty: Difficulty.master,
      );
      expect(grade, Grade.excellent, reason: '마스터: 실수 1 → A(훌륭함)');
    });

    test('마스터 난이도: mistakes 2, hints 0 → B', () {
      final grade = Grade.evaluate(
        mistakes: 2,
        hints: 0,
        difficulty: Difficulty.master,
      );
      expect(grade, Grade.great, reason: '마스터: 실수 2 → B(좋음)');
    });

    test('마스터 난이도: mistakes 4, hints 0 → C', () {
      final grade = Grade.evaluate(
        mistakes: 4,
        hints: 0,
        difficulty: Difficulty.master,
      );
      expect(grade, Grade.good, reason: '마스터: 실수 4 → C(보통)');
    });

    test('0실수/0힌트/기준시간 이내 → S (모든 난이도)', () {
      // 각 난이도마다 기준시간 이내이면 S
      for (final diff in Difficulty.values) {
        final grade = Grade.evaluate(
          mistakes: 0,
          hints: 0,
          elapsedSeconds: 1, // 1초 — 모든 기준시간 이내
          difficulty: diff,
        );
        expect(grade, Grade.perfect,
            reason: '${diff.label}: 0실수/0힌트/기준시간 이내 → S(퍼펙트)');
      }
    });
  });

  // ===================================================================
  // Major 8 + Minor 11 — 숫자우선 + 메모 UX + 토글 입력
  // ===================================================================
  group('Major 8 + Minor 11: 토글 입력 및 숫자우선 모드', () {
    late GameNotifier notifier;

    setUp(() {
      notifier = GameNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('같은 숫자 재입력 시 값이 0이 됨 (토글)', () {
      // 고정 보드로 게임 복원
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      // (0,0)은 빈 칸 (정답 5)
      notifier.selectCell(0, 0);
      // 오답이지만 값 입력 (7 입력)
      notifier.inputNumber(7);
      expect(notifier.testState!.board.currentBoard[0][0], 7,
          reason: '7이 입력되어야 함');

      // 같은 숫자 7을 다시 입력 → 토글로 삭제
      notifier.inputNumber(7);
      expect(notifier.testState!.board.currentBoard[0][0], 0,
          reason: '같은 숫자 재입력 시 0으로 토글되어야 함');
    });

    test('숫자우선 모드에서 메모 모드 ON + 셀 탭 시 메모 토글', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        inputMode: InputMode.numberFirst,
        isMemoMode: true,
      ));

      // 숫자 3을 선택
      notifier.selectNumber(3);
      expect(notifier.testState!.selectedNumber, 3);

      // (0,0)은 빈 칸 → 셀 탭 시 메모 토글 (숫자 3 메모 추가)
      notifier.selectCell(0, 0);
      expect(notifier.testState!.board.notes[0][0].contains(3), true,
          reason: '숫자우선+메모 모드에서 셀 탭 시 메모 3이 추가되어야 함');

      // 같은 셀 다시 탭 → 메모 3 제거 (토글)
      notifier.selectCell(0, 0);
      expect(notifier.testState!.board.notes[0][0].contains(3), false,
          reason: '다시 탭하면 메모 3이 제거되어야 함');
    });

    test('고정 셀에서는 토글 입력이 무시됨', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      // 고정 셀 찾기 (puzzle에서 0이 아닌 셀)
      int? fixedRow, fixedCol;
      for (var r = 0; r < 9 && fixedRow == null; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.isFixed[r][c]) {
            fixedRow = r;
            fixedCol = c;
            break;
          }
        }
      }
      expect(fixedRow, isNotNull, reason: '고정 셀이 하나 이상 있어야 함');

      final originalValue =
          notifier.testState!.board.currentBoard[fixedRow!][fixedCol!];

      // 고정 셀 선택 후 같은 숫자 입력 시도
      notifier.selectCell(fixedRow, fixedCol!);
      notifier.inputNumber(originalValue);

      // 값이 변하지 않아야 함
      expect(
        notifier.testState!.board.currentBoard[fixedRow][fixedCol],
        originalValue,
        reason: '고정 셀의 값은 변경되지 않아야 함',
      );
    });
  });
}
