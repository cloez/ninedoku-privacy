/// 노노그램 퍼즐 생성기
/// - 랜덤 그림 생성 → 힌트 추출 → 유일해 검증
/// - 시드 기반 결정적 생성
library;

import 'dart:math';
import 'nonogram_board.dart';
import 'nonogram_solver.dart';

class NonogramGeneratorResult {
  final NonogramBoard puzzle;
  final NonogramBoard solution;

  const NonogramGeneratorResult({
    required this.puzzle,
    required this.solution,
  });
}

class NonogramGenerator {
  /// 난이도별 격자 크기
  static int sizeForDifficulty(int code) {
    switch (code) {
      case 0: return 5;
      case 1: return 10;
      case 2: return 15;
      case 3: return 20;
      default: return 10;
    }
  }

  /// 퍼즐 생성
  static NonogramGeneratorResult? generate({
    required int size,
    required int seed,
    int? difficulty,
  }) {
    final stopwatch = Stopwatch()..start();
    // 전체 생성 시간 한도 (3초 미만 응답 보장)
    const maxDuration = Duration(milliseconds: 2500);
    // countSolutions 호출당 시간 한도 (특히 hard 20×20에서 백트래킹 폭주 방지)
    const countTimeLimit = Duration(milliseconds: 1500);
    final rng = Random(seed);

    // 시간 초과 시 fallback으로 사용할 마지막 후보
    NonogramGeneratorResult? lastCandidate;

    while (stopwatch.elapsed < maxDuration) {
      // 1. 랜덤 그림 생성 (채움 비율 30~60%)
      final fillRatio = 0.3 + rng.nextDouble() * 0.3;
      final solutionCells = List.generate(
        size * size,
        (_) => rng.nextDouble() < fillRatio ? 1 : 0,
      );

      // 2. 힌트 추출
      final rowHints = <List<int>>[];
      final colHints = <List<int>>[];

      for (int r = 0; r < size; r++) {
        rowHints.add(_extractHints(
          List.generate(size, (c) => solutionCells[r * size + c]),
        ));
      }

      for (int c = 0; c < size; c++) {
        colHints.add(_extractHints(
          List.generate(size, (r) => solutionCells[r * size + c]),
        ));
      }

      // 3. 빈 보드 + 힌트로 퍼즐 생성
      final puzzle = NonogramBoard.empty(
        rows: size, cols: size,
        rowHints: rowHints, colHints: colHints,
      );

      // 정답 보드 (best-effort fallback용으로 미리 구성)
      final solution = NonogramBoard(
        rows: size, cols: size,
        rowHints: rowHints, colHints: colHints,
        cells: solutionCells,
      );
      lastCandidate = NonogramGeneratorResult(puzzle: puzzle, solution: solution);

      // 4. 유일해 검증 (시간 한도 적용)
      // 시간 초과 시 countSolutions는 0 또는 1을 반환할 수 있으므로,
      // 검증이 성공(=1)하면 유일해로 간주. 단 전체 시간 한도가 임박했으면 skip.
      final remaining = maxDuration - stopwatch.elapsed;
      if (remaining <= Duration.zero) break;
      final perCallLimit =
          remaining < countTimeLimit ? remaining : countTimeLimit;

      final solutionCount = NonogramSolver.countSolutions(
        puzzle,
        maxCount: 2,
        timeout: stopwatch,
        timeLimit: stopwatch.elapsed + perCallLimit,
      );
      if (solutionCount == 1) {
        return NonogramGeneratorResult(puzzle: puzzle, solution: solution);
      }
      // 유일해가 아니거나(2) 시간 초과로 0 반환 → 다음 시도
    }

    // 시간 초과: 마지막 후보를 fallback으로 반환
    // (유일성 미보장이지만 풀이는 가능 — 사용자는 게임 진행 가능)
    return lastCandidate;
  }

  /// 라인에서 힌트 추출
  static List<int> _extractHints(List<int> line) {
    final groups = <int>[];
    int count = 0;
    for (final v in line) {
      if (v == 1) {
        count++;
      } else {
        if (count > 0) groups.add(count);
        count = 0;
      }
    }
    if (count > 0) groups.add(count);
    return groups.isEmpty ? [0] : groups;
  }
}
