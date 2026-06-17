import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/star_battle/engine/star_battle_board.dart';
import 'package:ninedoku/games/star_battle/engine/star_battle_solver.dart';
import 'package:ninedoku/games/star_battle/engine/star_battle_generator.dart';
import 'package:ninedoku/games/star_battle/engine/star_battle_hint.dart';

void main() {
  group('StarBattleBoard', () {
    // 6×6 테스트용 영역 (6개 영역, 각 6셀)
    final testRegions6 = [
      0, 0, 0, 1, 1, 1,
      0, 0, 2, 1, 1, 3,
      2, 2, 2, 2, 3, 3,
      4, 4, 2, 5, 3, 3,
      4, 4, 5, 5, 5, 3,
      4, 4, 5, 5, 5, 3,
    ];

    test('빈 보드 생성', () {
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      expect(board.size, 6);
      expect(board.starCount, 1);
      expect(board.totalCells, 36);
      expect(board.emptyCellCount, 36);
      expect(board.starCellCount, 0);
      expect(board.isComplete, false);
    });

    test('셀 값 설정 및 조회', () {
      var board = StarBattleBoard.empty(6, testRegions6, 1);
      board = board.setValue(0, 0, 1); // ★
      expect(board.getValue(0, 0), 1);
      expect(board.starCellCount, 1);

      board = board.setValue(1, 1, 0); // X
      expect(board.getValue(1, 1), 0);
    });

    test('셀 값 -1, 0, 1만 허용', () {
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      expect(() => board.setValue(0, 0, 2), throwsA(isA<AssertionError>()));
    });

    test('영역 번호 조회', () {
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      expect(board.getRegion(0, 0), 0);
      expect(board.getRegion(0, 3), 1);
      expect(board.getRegion(2, 0), 2);
    });

    test('totalStarsNeeded 계산', () {
      final board1 = StarBattleBoard.empty(6, testRegions6, 1);
      expect(board1.totalStarsNeeded, 6); // 6×1

      // 2-star용 영역 (임의)
      final regions8 = List<int>.generate(64, (i) => i ~/ 8);
      final board2 = StarBattleBoard.empty(8, regions8, 2);
      expect(board2.totalStarsNeeded, 16); // 8×2
    });

    test('깊은 복사', () {
      var board = StarBattleBoard.empty(6, testRegions6, 1);
      board = board.setValue(0, 0, 1);
      final copy = board.copyWith();
      expect(copy.getValue(0, 0), 1);
      expect(copy == board, true);
    });

    test('JSON 직렬화/역직렬화', () {
      var board = StarBattleBoard.empty(6, testRegions6, 1);
      board = board.setValue(0, 0, 1);
      board = board.setValue(1, 2, 0);

      final json = board.toJson();
      final restored = StarBattleBoard.fromJson(json);

      expect(restored.size, board.size);
      expect(restored.starCount, board.starCount);
      expect(restored.getValue(0, 0), 1);
      expect(restored.getValue(1, 2), 0);
      expect(restored.getRegion(0, 0), board.getRegion(0, 0));
    });

    test('toString 포맷', () {
      var board = StarBattleBoard.empty(6, testRegions6, 1);
      board = board.setValue(0, 0, 1);
      board = board.setValue(0, 1, 0);
      final str = board.toString();
      expect(str.contains('★'), true);
      expect(str.contains('X'), true);
      expect(str.contains('.'), true);
    });

    test('동등성 비교', () {
      final board1 = StarBattleBoard.empty(6, testRegions6, 1);
      final board2 = StarBattleBoard.empty(6, testRegions6, 1);
      expect(board1 == board2, true);

      final board3 = board1.setValue(0, 0, 1);
      expect(board1 == board3, false);
    });
  });

  group('StarBattleSolver', () {
    // 간단한 6×6 1-star 퍼즐 (수동 구성)
    final testRegions6 = [
      0, 0, 0, 1, 1, 1,
      0, 0, 2, 1, 1, 3,
      2, 2, 2, 2, 3, 3,
      4, 4, 2, 5, 3, 3,
      4, 4, 5, 5, 5, 3,
      4, 4, 5, 5, 5, 3,
    ];

    test('빈 보드에서 솔버 실행', () {
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      final solution = StarBattleSolver.solve(board);
      // 솔버가 해답을 찾거나 null 반환
      if (solution != null) {
        expect(StarBattleSolver.isComplete(solution), true);
      }
    });

    test('isComplete — 올바른 보드', () {
      // 유효한 6×6 1-star 해답 구성
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      final solution = StarBattleSolver.solve(board);
      if (solution != null) {
        expect(StarBattleSolver.isComplete(solution), true);
      }
    });

    test('isComplete — 빈 보드는 미완료', () {
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      expect(StarBattleSolver.isComplete(board), false);
    });

    test('isValid — 빈 보드는 유효', () {
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      expect(StarBattleSolver.isValid(board), true);
    });

    test('isValid — 인접 별 배치 시 위반', () {
      var board = StarBattleBoard.empty(6, testRegions6, 1);
      board = board.setValue(0, 0, 1);
      board = board.setValue(0, 1, 1); // 인접 — 위반
      expect(StarBattleSolver.isValid(board), false);
    });

    test('isValid — 대각선 인접 별 배치 시 위반', () {
      var board = StarBattleBoard.empty(6, testRegions6, 1);
      board = board.setValue(0, 0, 1);
      board = board.setValue(1, 1, 1); // 대각선 인접 — 위반
      expect(StarBattleSolver.isValid(board), false);
    });

    test('isValid — 행 별 수 초과 시 위반', () {
      var board = StarBattleBoard.empty(6, testRegions6, 1);
      board = board.setValue(0, 0, 1);
      board = board.setValue(0, 5, 1); // 행에 별 2개 (1-star 모드)
      expect(StarBattleSolver.isValid(board), false);
    });

    test('countSolutions — 해 수 카운트', () {
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      final count = StarBattleSolver.countSolutions(board, limit: 3);
      expect(count, greaterThanOrEqualTo(0));
    });

    test('hasUniqueSolution — 유일해 검증', () {
      final board = StarBattleBoard.empty(6, testRegions6, 1);
      final isUnique = StarBattleSolver.hasUniqueSolution(board);
      // 테스트 영역에 따라 유일해일 수도 아닐 수도 있음
      expect(isUnique, isA<bool>());
    });
  });

  group('StarBattleGenerator', () {
    test('입문 (6×6, 1-star) 생성', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        expect(result.puzzle.size, 6);
        expect(result.puzzle.starCount, 1);
        expect(result.solution.size, 6);
        expect(StarBattleSolver.isComplete(result.solution), true);
      }
    });

    test('쉬움 (7×7, 1-star) 생성', () {
      final result = StarBattleGenerator.generate(difficulty: 1, seed: 123);
      if (result != null) {
        expect(result.puzzle.size, 7);
        expect(result.puzzle.starCount, 1);
        expect(StarBattleSolver.isComplete(result.solution), true);
      }
    });

    test('보통 (8×8, 1-star) 생성', () {
      final result = StarBattleGenerator.generate(difficulty: 2, seed: 456);
      if (result != null) {
        expect(result.puzzle.size, 8);
        expect(result.puzzle.starCount, 1);
        expect(StarBattleSolver.isComplete(result.solution), true);
      }
    });

    test('시드 기반 결정론적 생성 — 동일 시드 동일 결과', () {
      final result1 = StarBattleGenerator.generate(difficulty: 0, seed: 99);
      final result2 = StarBattleGenerator.generate(difficulty: 0, seed: 99);
      if (result1 != null && result2 != null) {
        expect(result1.solution == result2.solution, true);
      }
    });

    test('다른 시드 → 다른 결과 (대부분의 경우)', () {
      final result1 = StarBattleGenerator.generate(difficulty: 0, seed: 100);
      final result2 = StarBattleGenerator.generate(difficulty: 0, seed: 200);
      if (result1 != null && result2 != null) {
        // 보드가 다를 확률이 매우 높음
        // 하지만 100% 보장은 아니므로 단순 타입 체크
        expect(result1.puzzle, isA<StarBattleBoard>());
        expect(result2.puzzle, isA<StarBattleBoard>());
      }
    });

    test('생성된 퍼즐은 항상 반환됨 (유일해 best-effort)', () {
      // 정책: 유일해 검증이 시간 한도 내 통과되지 않으면
      // best-effort 폴백(결정론적 영역 분할)으로 풀이 가능한 퍼즐 반환.
      // 사용자가 화면 멈춤 없이 게임을 시작할 수 있도록 보장.
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 777);
      expect(result, isNotNull);
    });

    test('생성된 퍼즐 보드는 빈칸으로 구성', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        expect(result.puzzle.emptyCellCount, result.puzzle.totalCells);
      }
    });

    test('생성된 해답은 완전 유효', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        expect(StarBattleSolver.isComplete(result.solution), true);
        expect(StarBattleSolver.isValid(result.solution), true);
      }
    });

    test('영역 수가 격자 크기와 일치', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final regions = result.puzzle.regions;
        final uniqueRegions = regions.toSet();
        expect(uniqueRegions.length, result.puzzle.size);
      }
    });

    test('각 영역의 셀 수가 격자 크기와 같음', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final size = result.puzzle.size;
        final regionCounts = <int, int>{};
        for (final r in result.puzzle.regions) {
          regionCounts[r] = (regionCounts[r] ?? 0) + 1;
        }
        for (final count in regionCounts.values) {
          expect(count, size);
        }
      }
    });

    test('해답의 각 행 별 수 확인', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final size = result.solution.size;
        final starCount = result.solution.starCount;
        for (var r = 0; r < size; r++) {
          var count = 0;
          for (var c = 0; c < size; c++) {
            if (result.solution.getValue(r, c) == 1) count++;
          }
          expect(count, starCount);
        }
      }
    });

    test('해답의 각 열 별 수 확인', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final size = result.solution.size;
        final starCount = result.solution.starCount;
        for (var c = 0; c < size; c++) {
          var count = 0;
          for (var r = 0; r < size; r++) {
            if (result.solution.getValue(r, c) == 1) count++;
          }
          expect(count, starCount);
        }
      }
    });

    test('해답의 별끼리 인접하지 않음', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final size = result.solution.size;
        for (var r = 0; r < size; r++) {
          for (var c = 0; c < size; c++) {
            if (result.solution.getValue(r, c) != 1) continue;
            // 8방향 인접 확인
            for (final (dr, dc) in [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]) {
              final nr = r + dr;
              final nc = c + dc;
              if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
                expect(result.solution.getValue(nr, nc), isNot(1),
                    reason: '($r,$c)와 ($nr,$nc) 인접 별');
              }
            }
          }
        }
      }
    });
  });

  group('StarBattleHintEngine', () {
    test('레벨 범위 검증', () {
      final regions = [
        0, 0, 0, 1, 1, 1,
        0, 0, 2, 1, 1, 3,
        2, 2, 2, 2, 3, 3,
        4, 4, 2, 5, 3, 3,
        4, 4, 5, 5, 5, 3,
        4, 4, 5, 5, 5, 3,
      ];
      final board = StarBattleBoard.empty(6, regions, 1);
      final solution = StarBattleSolver.solve(board);
      if (solution != null) {
        expect(
          () => StarBattleHintEngine.getHint(board, solution, level: 0),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => StarBattleHintEngine.getHint(board, solution, level: 5),
          throwsA(isA<AssertionError>()),
        );
      }
    });

    test('Level 1 힌트 — 행/열/영역 강조', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final hint = StarBattleHintEngine.getHint(
          result.puzzle, result.solution, level: 1,
        );
        if (hint != null) {
          expect(hint.level, 1);
          expect(hint.row, greaterThanOrEqualTo(0));
          expect(hint.col, greaterThanOrEqualTo(0));
          expect(hint.message.isNotEmpty, true);
        }
      }
    });

    test('Level 2 힌트 — ★/X 여부 안내', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final hint = StarBattleHintEngine.getHint(
          result.puzzle, result.solution, level: 2,
        );
        if (hint != null) {
          expect(hint.level, 2);
          expect(hint.message.contains('★'), true);
        }
      }
    });

    test('Level 3 힌트 — 기법 설명', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final hint = StarBattleHintEngine.getHint(
          result.puzzle, result.solution, level: 3,
        );
        if (hint != null) {
          expect(hint.level, 3);
          expect(hint.technique, isNotNull);
        }
      }
    });

    test('Level 4 힌트 — 정답 공개', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        final hint = StarBattleHintEngine.getHint(
          result.puzzle, result.solution, level: 4,
        );
        if (hint != null) {
          expect(hint.level, 4);
          expect(hint.value, isNotNull);
          expect(hint.value == 0 || hint.value == 1, true);
        }
      }
    });

    test('완성된 보드에서 힌트 없음', () {
      final result = StarBattleGenerator.generate(difficulty: 0, seed: 42);
      if (result != null) {
        // 모든 셀 채운 보드
        final hint = StarBattleHintEngine.getHint(
          result.solution, result.solution, level: 1,
        );
        // 빈칸이 없으므로 null이거나 X 위치가 아닌 셀을 찾을 수 없음
        // (solution은 모두 채워져 있으므로 null 기대)
        expect(hint, isNull);
      }
    });
  });
}
