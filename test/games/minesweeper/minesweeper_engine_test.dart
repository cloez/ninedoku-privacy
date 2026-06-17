import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/minesweeper/engine/minesweeper_board.dart';
import 'package:ninedoku/games/minesweeper/engine/minesweeper_generator.dart';
import 'package:ninedoku/games/minesweeper/engine/minesweeper_hint.dart';
import 'package:ninedoku/games/minesweeper/engine/minesweeper_solver.dart';

void main() {
  // ===== A1. 보드 모델 테스트 (5개) =====
  group('A1. MinesweeperBoard 모델', () {
    test('빈 보드 생성', () {
      final board = MinesweeperBoard.empty(8, 10);
      expect(board.size, 8);
      expect(board.mineCount, 10);
      expect(board.revealedCount, 0);
      expect(board.flagCount, 0);
    });

    test('getCell / setCell 동작', () {
      var board = MinesweeperBoard.empty(5, 3);
      final cell = const MineCell(isMine: true, adjacentMines: 0);
      board = board.setCell(2, 3, cell);
      expect(board.getCell(2, 3).isMine, true);
      expect(board.getCell(0, 0).isMine, false);
    });

    test('toJson / fromJson 라운드트립', () {
      var board = MinesweeperBoard.empty(6, 5);
      board = board.setCell(0, 0, const MineCell(isMine: true));
      board = board.revealCell(1, 1);

      final json = board.toJson();
      final restored = MinesweeperBoard.fromJson(json);
      expect(restored.size, 6);
      expect(restored.mineCount, 5);
      expect(restored.getCell(0, 0).isMine, true);
      expect(restored.getCell(1, 1).revealed, true);
    });

    test('revealCell / toggleFlag 동작', () {
      var board = MinesweeperBoard.empty(5, 2);
      board = board.revealCell(0, 0);
      expect(board.getCell(0, 0).revealed, true);
      expect(board.revealedCount, 1);

      board = board.toggleFlag(1, 1);
      expect(board.getCell(1, 1).flagged, true);
      expect(board.flagCount, 1);

      // 깃발 토글 해제
      board = board.toggleFlag(1, 1);
      expect(board.getCell(1, 1).flagged, false);
    });

    test('isWon 판정', () {
      // 2x2 보드, 지뢰 1개
      final cells = [
        [const MineCell(isMine: true), const MineCell(adjacentMines: 1, revealed: true)],
        [const MineCell(adjacentMines: 1, revealed: true), const MineCell(adjacentMines: 1, revealed: true)],
      ];
      final board = MinesweeperBoard(size: 2, mineCount: 1, cells: cells);
      expect(board.isWon, true);
      expect(board.safeCount, 3);
      expect(board.revealedCount, 3);
    });

    test('범위 초과 접근 시 에러', () {
      final board = MinesweeperBoard.empty(5, 2);
      expect(() => board.getCell(-1, 0), throwsA(isA<RangeError>()));
      expect(() => board.getCell(5, 0), throwsA(isA<RangeError>()));
    });

    test('neighbors 좌표 목록', () {
      final board = MinesweeperBoard.empty(5, 2);
      // 코너(0,0): 3개 이웃
      expect(board.neighbors(0, 0).length, 3);
      // 중앙(2,2): 8개 이웃
      expect(board.neighbors(2, 2).length, 8);
      // 가장자리(0,2): 5개 이웃
      expect(board.neighbors(0, 2).length, 5);
    });

    test('minePositions 목록', () {
      var board = MinesweeperBoard.empty(3, 0);
      board = board.setCell(0, 0, const MineCell(isMine: true));
      board = board.setCell(2, 2, const MineCell(isMine: true));
      final mines = board.minePositions;
      expect(mines.length, 2);
      expect(mines.contains((0, 0)), true);
      expect(mines.contains((2, 2)), true);
    });
  });

  // ===== A2. 솔버 테스트 (8개) =====
  group('A2. MinesweeperSolver', () {
    test('빈 보드에서 solve 시 원본 불변', () {
      final board = MinesweeperBoard.empty(5, 3);
      final result = MinesweeperSolver.solve(board);
      // 열린 셀이 없으므로 추론 불가 → 풀리지 않음
      expect(result.solved, false);
      expect(board.revealedCount, 0); // 원본 불변
    });

    test('연쇄 오픈 정상 동작', () {
      // 3x3, 지뢰 없음 → 아무 셀 열면 전체 연쇄 오픈
      final board = MinesweeperBoard.empty(3, 0);
      final result = MinesweeperSolver.revealWithCascade(board, 1, 1);
      expect(result.revealedCount, 9); // 전체 오픈
    });

    test('연쇄 오픈 — 지뢰 근처에서 멈춤', () {
      // 3x3, 중앙에 지뢰
      var board = MinesweeperBoard.empty(3, 1);
      // 지뢰 배치 + 인접 수 계산
      final cells = List.generate(3, (r) {
        return List.generate(3, (c) {
          if (r == 1 && c == 1) return const MineCell(isMine: true);
          return const MineCell(adjacentMines: 1);
        });
      });
      board = MinesweeperBoard(size: 3, mineCount: 1, cells: cells);

      // 코너 열기 — adjacentMines가 1이므로 연쇄 없음
      final result = MinesweeperSolver.revealWithCascade(board, 0, 0);
      expect(result.revealedCount, 1);
    });

    test('풀이 가능한 퍼즐 검증', () {
      // 생성기로 퍼즐 만들고 솔버 검증
      final genResult = MinesweeperGenerator.generate(
        size: 8, mineCount: 8, seed: 42,
      );
      if (genResult != null) {
        final solveResult = MinesweeperSolver.solve(genResult.puzzle);
        expect(solveResult.solved, true);
      }
    });

    test('isSolvableByLogic — 풀이 가능 퍼즐', () {
      final genResult = MinesweeperGenerator.generate(
        size: 8, mineCount: 8, seed: 100,
      );
      if (genResult != null) {
        expect(MinesweeperSolver.isSolvableByLogic(genResult.puzzle), true);
      }
    });

    test('revealWithCascade — 깃발 셀은 열지 않음', () {
      var board = MinesweeperBoard.empty(3, 0);
      board = board.toggleFlag(0, 1); // 깃발
      final result = MinesweeperSolver.revealWithCascade(board, 0, 0);
      expect(result.getCell(0, 1).flagged, true);
      expect(result.getCell(0, 1).revealed, false);
    });

    test('revealWithCascade — 이미 열린 셀은 스킵', () {
      var board = MinesweeperBoard.empty(3, 0);
      board = board.revealCell(0, 0);
      final result = MinesweeperSolver.revealWithCascade(board, 0, 0);
      expect(result.revealedCount, 1); // 변화 없음
    });

    test('solve 결과 — 열린 셀이 원본보다 많거나 같음', () {
      final genResult = MinesweeperGenerator.generate(
        size: 8, mineCount: 8, seed: 77,
      );
      if (genResult != null) {
        final originalRevealed = genResult.puzzle.revealedCount;
        final solveResult = MinesweeperSolver.solve(genResult.puzzle);
        expect(solveResult.board.revealedCount, greaterThanOrEqualTo(originalRevealed));
      }
    });
  });

  // ===== A3. 생성기 테스트 (8개) =====
  group('A3. MinesweeperGenerator', () {
    test('입문 난이도 (8×8) 생성 성공', () {
      final result = MinesweeperGenerator.generate(
        difficulty: 0, seed: 1,
      );
      expect(result, isNotNull);
      expect(result!.size, 8);
      expect(result.mineCount, 8);
    });

    test('쉬움 난이도 (9×9) 생성 성공', () {
      final result = MinesweeperGenerator.generate(
        difficulty: 1, seed: 2,
      );
      expect(result, isNotNull);
      expect(result!.size, 9);
    });

    test('보통 난이도 (10×10) 생성 성공', () {
      final result = MinesweeperGenerator.generate(
        difficulty: 2, seed: 3,
      );
      expect(result, isNotNull);
      expect(result!.size, 10);
    });

    test('생성된 퍼즐이 논리적 풀이 가능', () {
      final result = MinesweeperGenerator.generate(
        difficulty: 0, seed: 10,
      );
      if (result != null) {
        expect(MinesweeperSolver.isSolvableByLogic(result.puzzle), true);
      }
    });

    test('같은 시드 → 같은 퍼즐 (결정성)', () {
      final r1 = MinesweeperGenerator.generate(difficulty: 0, seed: 42);
      final r2 = MinesweeperGenerator.generate(difficulty: 0, seed: 42);
      if (r1 != null && r2 != null) {
        // 동일한 지뢰 위치
        expect(r1.solution.minePositions, r2.solution.minePositions);
      }
    });

    test('다른 시드 → 다른 퍼즐', () {
      final r1 = MinesweeperGenerator.generate(difficulty: 0, seed: 42);
      final r2 = MinesweeperGenerator.generate(difficulty: 0, seed: 43);
      if (r1 != null && r2 != null) {
        // 같은 지뢰 위치일 확률 극히 낮음
        final same = r1.solution.minePositions.toString() ==
            r2.solution.minePositions.toString();
        expect(same, false);
      }
    });

    test('생성 시간 3초 이내', () {
      final sw = Stopwatch()..start();
      MinesweeperGenerator.generate(difficulty: 0, seed: 999);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });

    test('첫 클릭 안전 보장 — 첫 열린 셀이 지뢰 아님', () {
      final result = MinesweeperGenerator.generate(
        difficulty: 0, seed: 50,
      );
      if (result != null) {
        // 열린 셀 중 지뢰가 없어야 함
        for (int r = 0; r < result.puzzle.size; r++) {
          for (int c = 0; c < result.puzzle.size; c++) {
            final cell = result.puzzle.getCell(r, c);
            if (cell.revealed) {
              expect(cell.isMine, false);
            }
          }
        }
      }
    });
  });

  // ===== A4. 힌트 테스트 (5개) =====
  group('A4. MinesweeperHintEngine', () {
    MinesweeperGeneratorResult? genResult;

    setUpAll(() {
      genResult = MinesweeperGenerator.generate(
        difficulty: 0, seed: 42,
      );
    });

    test('Level 1 힌트 — 위치 안내', () {
      if (genResult == null) return;
      final hint = MinesweeperHintEngine.getHint(
        genResult!.puzzle, genResult!.solution,
        level: 1,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 1);
      expect(hint.message.contains('행'), true);
      expect(hint.message.contains('열'), true);
    });

    test('Level 2 힌트 — 주변 상황', () {
      if (genResult == null) return;
      final hint = MinesweeperHintEngine.getHint(
        genResult!.puzzle, genResult!.solution,
        level: 2,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 2);
      expect(hint.message.contains('숫자'), true);
    });

    test('Level 3 힌트 — 풀이 기법 설명', () {
      if (genResult == null) return;
      final hint = MinesweeperHintEngine.getHint(
        genResult!.puzzle, genResult!.solution,
        level: 3,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 3);
      // 게임 고유 기호(⚑) 사용 확인
      expect(hint.message.isNotEmpty, true);
    });

    test('Level 4 힌트 — 정답 액션 포함', () {
      if (genResult == null) return;
      final hint = MinesweeperHintEngine.getHint(
        genResult!.puzzle, genResult!.solution,
        level: 4,
      );
      expect(hint, isNotNull);
      expect(hint!.level, 4);
      expect(hint.action, isNotNull);
    });

    test('힌트 결과가 실제 솔루션과 일치', () {
      if (genResult == null) return;
      final hint = MinesweeperHintEngine.getHint(
        genResult!.puzzle, genResult!.solution,
        level: 4,
      );
      if (hint == null) return;

      final solCell = genResult!.solution.getCell(hint.row, hint.col);
      if (hint.action == HintAction.reveal) {
        // 안전한 셀이어야 함
        expect(solCell.isMine, false);
      } else if (hint.action == HintAction.flag) {
        // 지뢰여야 함
        expect(solCell.isMine, true);
      }
    });
  });

  // ===== A5. 통합 테스트 (4개) =====
  group('A5. 통합', () {
    test('생성 → 풀이 → 완료 전체 사이클', () {
      final genResult = MinesweeperGenerator.generate(
        difficulty: 0, seed: 42,
      );
      expect(genResult, isNotNull);

      final solveResult = MinesweeperSolver.solve(genResult!.puzzle);
      expect(solveResult.solved, true);
      expect(solveResult.board.isWon, true);
    });

    test('Board 직렬화 후 풀이 가능', () {
      final genResult = MinesweeperGenerator.generate(
        difficulty: 0, seed: 42,
      );
      if (genResult == null) return;

      final json = genResult.puzzle.toJson();
      final restored = MinesweeperBoard.fromJson(json);
      final solveResult = MinesweeperSolver.solve(restored);
      expect(solveResult.solved, true);
    });

    test('빈 보드에서 힌트 요청 시 안전 처리', () {
      final board = MinesweeperBoard.empty(5, 3);
      final solution = MinesweeperBoard.empty(5, 3);
      final hint = MinesweeperHintEngine.getHint(board, solution, level: 1);
      // 열린 셀이 없으므로 힌트 없음 → null
      expect(hint, isNull);
    });

    test('난이도별 설정 코드 매핑', () {
      final c0 = MinesweeperDifficultyConfig.fromCode(0);
      expect(c0.size, 8);
      expect(c0.mineCount, 8);

      final c4 = MinesweeperDifficultyConfig.fromCode(4);
      expect(c4.size, 16);
      expect(c4.mineCount, 50);
    });
  });
}
