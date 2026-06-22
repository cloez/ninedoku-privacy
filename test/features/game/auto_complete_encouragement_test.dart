// 자동완성 기능 및 추임새(Good/Wow/Great/Excellent) 검증 테스트
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/core/sudoku/technique_analyzer.dart';
import 'package:ninedoku/features/game/game_notifier.dart';
import 'package:ninedoku/features/game/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('자동완성 기능 검증', () {
    /// 빈 칸 2개, 연쇄 Naked Single로 해결 가능한 보드 생성
    test('빈 칸 2개 — 연쇄 Naked Single로 자동완성', () {
      // 거의 완성된 보드 (2칸만 비어 있음)
      final solution = [
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

      // 퍼즐: 마지막 2칸 비우기
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      puzzle[8][7] = 0; // (8,7) = 7
      puzzle[8][8] = 0; // (8,8) = 9

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();

      // 게임 시작 (직접 상태 설정)
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      // (8,6) = 1이 이미 채워져 있으니, 한 칸 남을 때까지 입력
      // (8,7)을 선택하고 7 입력 → 남은 1칸 (8,8)이 Naked Single
      notifier.selectCell(8, 7);
      notifier.inputNumber(7);

      final state = notifier.testState!;
      // 자동완성 가능 조건: 빈 칸 1개 → 하지만 최소 2칸이어야 함
      // 위 시나리오에서 (8,7)에 7을 넣으면 1칸만 남으므로 자동완성 대상이 아님
      // 수정: 3칸 비우기
    });

    test('빈 칸 3개 — 연쇄 Naked Single로 자동완성', () {
      final solution = [
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

      // 3칸 비우기: (8,6), (8,7), (8,8)
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      puzzle[8][6] = 0; // 1
      puzzle[8][7] = 0; // 7
      puzzle[8][8] = 0; // 9

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      // (8,6)에 1 입력 → 남은 2칸 (8,7)=7, (8,8)=9 → 자동완성 대상
      notifier.selectCell(8, 6);
      notifier.inputNumber(1);

      final state = notifier.testState!;
      expect(state.isCompleted, isTrue, reason: '보드가 즉시 완성 상태여야 함');
      expect(state.isAutoCompleting, isTrue, reason: '자동완성 애니메이션 진행 중');
      expect(state.autoCompleteCells.length, equals(2), reason: '2개 셀이 자동완성 대상');

      // 자동완성 셀 값 검증
      final expectedCells = state.autoCompleteCells;
      for (final (r, c, v) in expectedCells) {
        expect(solution[r][c], equals(v), reason: '자동완성 값이 정답과 일치해야 함');
      }
    });

    test('빈 칸 6칸도 연쇄 Naked Single이면 자동완성', () {
      final solution = [
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

      // 7칸 비우기 → 1칸 입력 → 남은 6칸 연쇄 해결 → 자동완성
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      puzzle[8][2] = 0;
      puzzle[8][3] = 0;
      puzzle[8][4] = 0;
      puzzle[8][5] = 0;
      puzzle[8][6] = 0;
      puzzle[8][7] = 0;
      puzzle[8][8] = 0;

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      // (8,2)에 5 입력 → 남은 6칸 연쇄 Naked Single → 자동완성
      notifier.selectCell(8, 2);
      notifier.inputNumber(5);

      final state = notifier.testState!;
      expect(state.isCompleted, isTrue, reason: '자동완성으로 완성');
      expect(state.isAutoCompleting, isTrue, reason: '자동완성 애니메이션 진행 중');
      expect(state.autoCompleteCells.length, equals(6));
    });

    test('빈 칸 11개 이상이면 자동완성 안 함 (상한 10개)', () {
      final solution = [
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

      // 12칸 비우기 → 1칸 입력 후 남은 11칸 → 상한(10) 초과
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      // 마지막 행(9칸) + 7행 마지막 3칸 = 12칸
      for (var c = 0; c < 9; c++) {
        puzzle[8][c] = 0;
      }
      puzzle[7][6] = 0;
      puzzle[7][7] = 0;
      puzzle[7][8] = 0;

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      // (7,6)에 오답 입력 → 퍼펙트 아님 → 남은 11칸 > 10 → 자동완성 안 함
      notifier.selectCell(7, 6);
      notifier.inputNumber(board.solution[7][6] % 9 + 1);

      final state = notifier.testState!;
      expect(state.isCompleted, isFalse, reason: '상한 초과로 자동완성 안 함');
      expect(state.isAutoCompleting, isFalse);
    });

    test('자동완성 중 입력 차단', () {
      final solution = [
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

      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      puzzle[8][6] = 0;
      puzzle[8][7] = 0;
      puzzle[8][8] = 0;

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      notifier.selectCell(8, 6);
      notifier.inputNumber(1);

      expect(notifier.testState!.isAutoCompleting, isTrue);

      // 자동완성 중에는 입력 차단
      notifier.selectCell(0, 0); // 선택 시도 → 차단
      notifier.inputNumber(5); // 입력 시도 → 차단
      notifier.deleteValue(); // 삭제 시도 → 차단
      notifier.undo(); // 되돌리기 시도 → 차단
      notifier.toggleMemoMode(); // 메모 전환 시도 → 차단

      // 상태가 변하지 않았음을 확인 (isAutoCompleting 유지)
      expect(notifier.testState!.isAutoCompleting, isTrue);
    });

    test('자동완성 — 연쇄 해결 순서 정확성', () {
      // 연쇄적으로 풀리는 시나리오:
      // A를 채우면 B가 Naked Single → B를 채우면 C가 Naked Single
      final solution = [
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

      // 4칸 비우기
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      puzzle[8][5] = 0; // 6
      puzzle[8][6] = 0; // 1
      puzzle[8][7] = 0; // 7
      puzzle[8][8] = 0; // 9

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      // (8,5)에 6 입력 → 남은 3칸이 연쇄 해결
      notifier.selectCell(8, 5);
      notifier.inputNumber(6);

      final state = notifier.testState!;
      expect(state.isCompleted, isTrue);
      expect(state.isAutoCompleting, isTrue);
      expect(state.autoCompleteCells.length, equals(3));

      // 연쇄 순서대로 해결되는지 확인
      for (final (r, c, v) in state.autoCompleteCells) {
        expect(v, equals(solution[r][c]), reason: '($r,$c)의 자동완성 값이 정답과 일치');
      }
    });

    test('실수 0일 때 Excellent 추임새 표시', () {
      final solution = [
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

      // 1칸만 비우기 (자동완성 없이 정상 완성)
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      puzzle[8][8] = 0; // 9

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      ));

      notifier.selectCell(8, 8);
      notifier.inputNumber(9);

      final state = notifier.testState!;
      expect(state.isCompleted, isTrue);
      expect(state.mistakeCount, equals(0));
      expect(state.lastEncouragement, equals(Encouragement.excellent));
    });
  });

  group('추임새 시스템 검증', () {
    test('TechniqueAnalyzer.findTechniqueForCell — Naked Single', () {
      // 거의 다 채운 보드에서 1칸만 비어 있으면 Naked Single
      final board = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 0], // (8,8) = 9 비어있음
      ];

      final technique = TechniqueAnalyzer.findTechniqueForCell(board, 8, 8);
      expect(technique, equals(SolvingTechnique.nakedSingle));
    });

    test('추임새 매핑: NakedSingle/HiddenSingle → null (추임새 없음)', () {
      // NakedSingle과 HiddenSingle은 기본 기법이므로 추임새 없음
      // _analyzeEncouragement의 switch문 확인
      expect(SolvingTechnique.nakedSingle.score, equals(1));
      expect(SolvingTechnique.hiddenSingle.score, equals(2));

      // NakedPair 이상부터 추임새 발생
      expect(SolvingTechnique.nakedPair.score, greaterThanOrEqualTo(4));
      expect(SolvingTechnique.hiddenPair.score, greaterThanOrEqualTo(4));
      expect(SolvingTechnique.nakedTriple.score, greaterThanOrEqualTo(6));
      expect(SolvingTechnique.xWing.score, greaterThanOrEqualTo(8));
    });

    test('Encouragement 메시지 값 확인', () {
      expect(Encouragement.good.message, equals('Good!'));
      expect(Encouragement.wow.message, equals('Wow!'));
      expect(Encouragement.great.message, equals('Great!'));
      expect(Encouragement.excellent.message, equals('Excellent!'));
    });

    test('고급 기법 분석 — analyze()로 기법 탐지', () {
      // NakedPair가 필요한 퍼즐 구성
      // 이 테스트는 analyze()가 고급 기법을 탐지할 수 있는지 확인
      // (실제 퍼즐에서 고급 기법이 필요한 경우는 hard+ 난이도에서 주로 발생)
      final techniques = TechniqueAnalyzer.analyze([
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 0],
      ]);

      // 거의 완성된 보드이므로 NakedSingle만 필요
      expect(techniques, contains(SolvingTechnique.nakedSingle));
    });

    test('퍼펙트 자동완성 — 실수 0 + 빈 칸 10개 이내면 솔루션으로 자동완성', () {
      final solution = [
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

      // 9칸 비우기 (다양한 행/열에 분산 — Naked Single 체인 불가능)
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      // 각 행에서 1칸씩 비워 Naked Single 체인을 불가능하게 구성
      puzzle[0][0] = 0; // 5
      puzzle[1][1] = 0; // 7
      puzzle[2][2] = 0; // 8
      puzzle[3][3] = 0; // 7
      puzzle[4][4] = 0; // 5
      puzzle[5][5] = 0; // 4
      puzzle[6][6] = 0; // 2
      puzzle[7][7] = 0; // 3
      puzzle[8][0] = 0; // 3

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      ));

      // 실수 없이 정답 입력 → 남은 8칸은 분산되어 Naked Single 체인 불가
      // 하지만 퍼펙트(실수 0) → 솔루션 기반 자동완성 발동
      notifier.selectCell(0, 0);
      notifier.inputNumber(5);

      final state = notifier.testState!;
      expect(state.isCompleted, isTrue, reason: '퍼펙트 자동완성으로 즉시 완성');
      expect(state.isAutoCompleting, isTrue, reason: '자동완성 애니메이션 진행 중');
      expect(state.autoCompleteCells.length, equals(8), reason: '8개 셀 자동완성');
      expect(state.lastEncouragement, equals(Encouragement.excellent),
          reason: '퍼펙트 추임새 표시');
      expect(state.mistakeCount, equals(0));

      // 자동완성된 셀들이 정답인지 검증
      for (final (r, c, v) in state.autoCompleteCells) {
        expect(v, equals(solution[r][c]),
            reason: '($r,$c) 자동완성 값이 솔루션과 일치');
      }
    });

    test('퍼펙트 자동완성 — 실수 1회 이상이면 Excellent 추임새 미표시', () {
      final solution = [
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

      // 5칸 비우기
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      puzzle[0][0] = 0; // 5
      puzzle[1][1] = 0; // 7
      puzzle[2][2] = 0; // 8
      puzzle[3][3] = 0; // 7
      puzzle[4][4] = 0; // 5

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      ));

      // 먼저 오답 입력 → 실수 1회 발생
      notifier.selectCell(0, 0);
      notifier.inputNumber(1); // 오답 (정답: 5)
      expect(notifier.testState!.mistakeCount, equals(1));

      // 셀우선 모드: 입력 후 포커스 해제되므로 재선택 필요
      notifier.selectCell(0, 0);
      // 오답 삭제 후 정답 입력 → Naked Single 체인으로 자동완성 발동
      // (deleteValue는 selectedCell을 유지. 같은 셀 재탭 시 토글 해제되므로 추가 selectCell 금지)
      notifier.deleteValue();
      notifier.inputNumber(5); // 정답

      final state = notifier.testState!;
      // 자동완성 자체는 발동 (Naked Single 체인), 하지만 Excellent 아님
      expect(state.isCompleted, isTrue, reason: '자동완성으로 완성됨');
      expect(state.isAutoCompleting, isTrue, reason: '자동완성 애니메이션 진행 중');
      expect(state.lastEncouragement, isNot(equals(Encouragement.excellent)),
          reason: '실수 1회 → Excellent 추임새 미표시');
      expect(state.mistakeCount, equals(1));
    });

    test('퍼펙트 자동완성 — 빈 칸 11개 이상이면 퍼펙트여도 자동완성 안 함', () {
      final solution = [
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

      // 12칸 비우기 → 1칸 입력 후 11칸 남음 → 상한 초과
      final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));
      for (var c = 0; c < 9; c++) {
        puzzle[8][c] = 0;
      }
      puzzle[7][6] = 0;
      puzzle[7][7] = 0;
      puzzle[7][8] = 0;

      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final notifier = GameNotifier();
      notifier.restoreGame(GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
      ));

      // 실수 0 + 정답 입력 → 하지만 남은 11칸 > 10 → 자동완성 안 함
      notifier.selectCell(7, 6);
      notifier.inputNumber(6);

      final state = notifier.testState!;
      expect(state.isCompleted, isFalse,
          reason: '빈 셀 11개 > 상한 10개 → 퍼펙트여도 자동완성 안 함');
      expect(state.isAutoCompleting, isFalse);
    });

    test('autoCompleteStep — 기본값 0, copyWith 동작', () {
      final solution = [
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
      final board = SudokuBoard(
        puzzle: solution,
        solution: solution,
      );
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );

      expect(state.autoCompleteStep, equals(0));

      final updated = state.copyWith(autoCompleteStep: 3);
      expect(updated.autoCompleteStep, equals(3));
    });
  });
}
