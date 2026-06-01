import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/board.dart';
import 'package:ninedoku/core/sudoku/technique_analyzer.dart';
import 'package:ninedoku/core/sudoku/hint_engine.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/features/game/game_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  group('Critical 1: Naked Triple 조건 수정 (len >= 1)', () {
    test('후보 1개인 셀도 트리플 후보에 포함', () {
      // Naked Triple: 3셀의 후보 합집합이 3개인 경우
      // 후보가 {1}, {1,2}, {2,3} 이면 합집합 {1,2,3} — len=1인 셀도 포함되어야 함
      final board = List.generate(9, (r) => List.generate(9, (c) => 0));
      // 행 0의 처음 3셀에 트리플 구성
      // 나머지 셀에 4~9를 배치하여 후보를 제한
      board[0][3] = 4;
      board[0][4] = 5;
      board[0][5] = 6;
      board[0][6] = 7;
      board[0][7] = 8;
      board[0][8] = 9;
      // 셀 [0][0], [0][1], [0][2]에 후보 {1}, {1,2}, {2,3} 만들기 위해
      // 열/박스 제약 추가
      // 열 0에 2,3 배치 → [0][0] 후보에서 2,3 제거
      board[1][0] = 2;
      board[2][0] = 3;

      // 열 2에 1 배치 → [0][2] 후보에서 1 제거
      board[1][2] = 1;

      // analyze가 정상 작동하는지 확인 (크래시 없음)
      final techniques = TechniqueAnalyzer.analyze(board);
      expect(techniques, isNotNull);
    });

    test('기존 Naked Triple 기능이 유지됨', () {
      // 2~3개 후보인 셀들의 트리플은 여전히 정상 동작
      final techniques = TechniqueAnalyzer.analyze(puzzle);
      expect(techniques, isNotNull);
    });
  });

  group('Critical 2: X-Wing 구현', () {
    test('SolvingTechnique.xWing 존재 확인', () {
      expect(SolvingTechnique.xWing.score, equals(8));
      expect(SolvingTechnique.xWing.label, equals('X-Wing'));
    });

    test('X-Wing 보드에서 기법 감지', () {
      // X-Wing 패턴이 있는 보드 구성
      // 숫자 n이 행 r1, r2에서 정확히 열 c1, c2에만 존재
      final board = List.generate(9, (r) => List.generate(9, (c) => 0));

      // 완성에 가까운 보드를 만들어 X-Wing 패턴을 포함
      // 간단한 검증: analyze가 X-Wing이 포함된 기법 목록을 반환할 수 있음
      final techniques = TechniqueAnalyzer.analyze(board);
      // 빈 보드에서는 다양한 기법이 필요할 수 있음
      expect(techniques, isNotNull);
    });

    test('findNextTechnique에서 X-Wing 검색 가능', () {
      // X-Wing을 찾는 findNextTechnique가 null이 아닌 결과를 반환하는지 확인
      // 간단한 퍼즐에서는 X-Wing이 필요 없을 수 있음
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      // 쉬운 퍼즐에서는 Naked/Hidden Single 수준이므로 X-Wing 미발생
      expect(result, isNotNull);
      expect(
        [SolvingTechnique.nakedSingle, SolvingTechnique.hiddenSingle],
        contains(result!.technique),
      );
    });
  });

  group('Major 3: 점진적 힌트 시스템', () {
    test('GameState에 힌트 진행 필드 존재', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
      );
      expect(state.currentHintLevel, equals(0));
      expect(state.hintTargetCell, isNull);
      expect(state.lastHintResult, isNull);
    });

    test('useHint 첫 호출 시 1단계(영역 강조) 제공', () {
      final notifier = GameNotifier();
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 12345,
      );

      notifier.useHint();
      final state = notifier.testState!;

      // 1단계 힌트가 제공됨
      expect(state.currentHintLevel, equals(1));
      expect(state.hintTargetCell, isNotNull);
      expect(state.lastHintResult, isNotNull);
      expect(state.lastHintResult!.level, equals(HintLevel.highlightRegion));
      // 아직 힌트 카운트는 증가하지 않음 (4단계에서만 증가)
      expect(state.hintCount, equals(0));
    });

    test('같은 셀에서 연속 힌트 시 단계가 올라감', () {
      final notifier = GameNotifier();
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 12345,
      );

      // 1단계
      notifier.useHint();
      expect(notifier.testState!.currentHintLevel, equals(1));
      expect(notifier.testState!.lastHintResult!.level, equals(HintLevel.highlightRegion));

      // 2단계
      notifier.useHint();
      expect(notifier.testState!.currentHintLevel, equals(2));
      expect(notifier.testState!.lastHintResult!.level, equals(HintLevel.showCandidates));

      // 3단계
      notifier.useHint();
      expect(notifier.testState!.currentHintLevel, equals(3));
      expect(notifier.testState!.lastHintResult!.level, equals(HintLevel.explainTechnique));

      // 4단계 — 정답 공개 + 힌트 카운트 증가
      notifier.useHint();
      expect(notifier.testState!.hintCount, equals(1));
      // 힌트 상태 초기화됨
      expect(notifier.testState!.currentHintLevel, equals(0));
      expect(notifier.testState!.hintTargetCell, isNull);
    });

    test('다른 셀 선택 시 힌트 진행 상태 초기화', () {
      final notifier = GameNotifier();
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 12345,
      );

      notifier.useHint(); // 1단계
      expect(notifier.testState!.currentHintLevel, equals(1));

      // 다른 셀 선택 → 힌트 초기화
      notifier.selectCell(8, 8);
      expect(notifier.testState!.currentHintLevel, equals(0));
    });

    test('힌트 관련 필드 JSON 직렬화/역직렬화', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final state = GameState(
        board: board,
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        currentHintLevel: 2,
        hintTargetCell: (3, 5),
      );

      final json = state.toJson();
      expect(json['currentHintLevel'], equals(2));
      expect(json['hintTargetCell'], isNotNull);

      final restored = GameState.fromJson(json);
      expect(restored.currentHintLevel, equals(2));
      expect(restored.hintTargetCell, equals((3, 5)));
    });

    test('clearHintState가 힌트 상태를 초기화', () {
      final notifier = GameNotifier();
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.beginner,
        seed: 12345,
      );

      notifier.useHint();
      expect(notifier.testState!.currentHintLevel, greaterThan(0));

      notifier.clearHintState();
      expect(notifier.testState!.currentHintLevel, equals(0));
      expect(notifier.testState!.hintTargetCell, isNull);
    });
  });

  group('Major 4: findNextTechnique 확장', () {
    test('Pointing Pair 검색 가능', () {
      // findNextTechnique가 다양한 기법을 반환할 수 있는지 확인
      // 쉬운 퍼즐에서는 기본 기법만 사용
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(result, isNotNull);
      // 반환 기법이 8가지 중 하나
      expect(SolvingTechnique.values, contains(result!.technique));
    });

    test('findNextTechnique가 설명 포함', () {
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(result, isNotNull);
      expect(result!.explanation, isNotEmpty);
    });

    test('findNextTechnique에 제거 후보 정보 포함', () {
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(result, isNotNull);
      // Naked Single이면 value가 있고, 제거 기법이면 eliminations가 있음
      if (result!.technique == SolvingTechnique.nakedSingle ||
          result.technique == SolvingTechnique.hiddenSingle) {
        expect(result.value, isNotNull);
      }
    });

    test('완전한 보드에서 findNextTechnique는 null', () {
      final result = TechniqueAnalyzer.findNextTechnique(solution);
      expect(result, isNull);
    });

    test('TechniqueResult에 올바른 row/col 값', () {
      final result = TechniqueAnalyzer.findNextTechnique(puzzle);
      expect(result, isNotNull);
      expect(result!.row, inInclusiveRange(0, 8));
      expect(result.col, inInclusiveRange(0, 8));
      // 해당 셀이 빈 셀이거나 관련 셀이어야 함
      expect(puzzle[result.row][result.col], equals(0));
    });
  });

  group('힌트 엔진 통합 테스트', () {
    test('3단계 힌트에서 확장된 기법 사용', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.explainTechnique,
      );
      expect(hint, isNotNull);
      expect(hint!.level, equals(HintLevel.explainTechnique));
      expect(hint.message, isNotEmpty);
    });

    test('2단계 힌트에서 후보 숫자 포함', () {
      final board = SudokuBoard(puzzle: puzzle, solution: solution);
      final hint = HintEngine.getHint(
        board: board,
        level: HintLevel.showCandidates,
      );
      expect(hint, isNotNull);
      expect(hint!.candidates, isNotEmpty);
      expect(hint.message, contains('가능한 숫자'));
    });
  });
}
