/// 지뢰찾기 퍼즐 생성기
///
/// - 시드 기반 결정적 생성 (같은 시드 → 같은 퍼즐)
/// - 첫 클릭 안전 보장 (첫 셀 + 주변 8칸에 지뢰 없음)
/// - 논리적 풀이 가능 보장 (No-guess Minesweeper)
/// - 3초 타임아웃 + 재시도
library;

import 'dart:math';
import 'minesweeper_board.dart';
import 'minesweeper_solver.dart';

/// 생성 결과
class MinesweeperGeneratorResult {
  /// 초기 퍼즐 (첫 클릭 후 연쇄 오픈된 상태)
  final MinesweeperBoard puzzle;

  /// 정답 (모든 지뢰 위치가 표시된 보드)
  final MinesweeperBoard solution;

  /// 격자 크기
  final int size;

  /// 지뢰 수
  final int mineCount;

  const MinesweeperGeneratorResult({
    required this.puzzle,
    required this.solution,
    required this.size,
    required this.mineCount,
  });
}

/// 난이도별 설정
class MinesweeperDifficultyConfig {
  final int size;
  final int mineCount;

  const MinesweeperDifficultyConfig({
    required this.size,
    required this.mineCount,
  });

  /// 난이도 코드(0~4)에 따른 설정
  static MinesweeperDifficultyConfig fromCode(int code) {
    switch (code) {
      case 0:
        return const MinesweeperDifficultyConfig(size: 8, mineCount: 8);
      case 1:
        return const MinesweeperDifficultyConfig(size: 9, mineCount: 12);
      case 2:
        return const MinesweeperDifficultyConfig(size: 10, mineCount: 18);
      case 3:
        return const MinesweeperDifficultyConfig(size: 12, mineCount: 30);
      case 4:
        return const MinesweeperDifficultyConfig(size: 16, mineCount: 50);
      default:
        return const MinesweeperDifficultyConfig(size: 10, mineCount: 18);
    }
  }
}

/// 지뢰찾기 생성기
class MinesweeperGenerator {
  /// 퍼즐 생성
  /// [size]: 격자 크기
  /// [mineCount]: 지뢰 수
  /// [seed]: 시드 값 (재현 가능성 보장)
  /// [difficulty]: 난이도 코드 (0~4), size/mineCount 대신 사용 가능
  static MinesweeperGeneratorResult? generate({
    int? size,
    int? mineCount,
    required int seed,
    int? difficulty,
  }) {
    // 난이도 코드로 설정 적용
    final config = difficulty != null
        ? MinesweeperDifficultyConfig.fromCode(difficulty)
        : null;
    final gridSize = size ?? config?.size ?? 10;
    final mines = mineCount ?? config?.mineCount ?? 18;

    final stopwatch = Stopwatch()..start();
    const timeout = Duration(seconds: 3);
    final rng = Random(seed);

    // 최대 재시도 횟수
    const maxAttempts = 100;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (stopwatch.elapsed >= timeout) break;

      // 첫 클릭 위치 결정 (시드 기반)
      final firstRow = rng.nextInt(gridSize);
      final firstCol = rng.nextInt(gridSize);

      // 첫 클릭 안전 영역 (본인 + 주변 8칸)
      final safeZone = <int>{};
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final nr = firstRow + dr;
          final nc = firstCol + dc;
          if (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
            safeZone.add(nr * gridSize + nc);
          }
        }
      }

      // 지뢰 배치 가능 위치
      final candidates = <int>[];
      for (int i = 0; i < gridSize * gridSize; i++) {
        if (!safeZone.contains(i)) candidates.add(i);
      }

      if (candidates.length < mines) continue;

      // 지뢰 배치 (Fisher-Yates 셔플)
      for (int i = candidates.length - 1; i > 0; i--) {
        final j = rng.nextInt(i + 1);
        final tmp = candidates[i];
        candidates[i] = candidates[j];
        candidates[j] = tmp;
      }
      final minePositions = candidates.sublist(0, mines).toSet();

      // 보드 구성
      var board = _buildBoard(gridSize, mines, minePositions);

      // 정답 보드 저장 (모든 안전한 셀이 열린 상태)
      final solution = _buildSolutionBoard(board);

      // 첫 클릭 적용 (연쇄 오픈)
      board = MinesweeperSolver.revealWithCascade(board, firstRow, firstCol);

      // 논리적 풀이 가능 여부 검증
      if (MinesweeperSolver.isSolvableByLogic(board)) {
        return MinesweeperGeneratorResult(
          puzzle: board,
          solution: solution,
          size: gridSize,
          mineCount: mines,
        );
      }
    }

    // 타임아웃 또는 최대 시도 초과 → null 반환
    return null;
  }

  /// 보드 구성 (지뢰 배치 + 인접 지뢰 수 계산)
  static MinesweeperBoard _buildBoard(
    int size,
    int mineCount,
    Set<int> minePositions,
  ) {
    final cells = List.generate(size, (r) {
      return List.generate(size, (c) {
        final idx = r * size + c;
        final isMine = minePositions.contains(idx);
        return MineCell(isMine: isMine);
      });
    });

    // 인접 지뢰 수 계산
    final board = MinesweeperBoard(size: size, mineCount: mineCount, cells: cells);

    final updatedCells = List.generate(size, (r) {
      return List.generate(size, (c) {
        if (cells[r][c].isMine) return cells[r][c];

        int count = 0;
        for (final (nr, nc) in board.neighbors(r, c)) {
          if (cells[nr][nc].isMine) count++;
        }
        return MineCell(adjacentMines: count);
      });
    });

    return MinesweeperBoard(size: size, mineCount: mineCount, cells: updatedCells);
  }

  /// 정답 보드 구성 (지뢰가 아닌 모든 셀이 열린 상태)
  static MinesweeperBoard _buildSolutionBoard(MinesweeperBoard board) {
    final cells = List.generate(board.size, (r) {
      return List.generate(board.size, (c) {
        final cell = board.getCell(r, c);
        if (cell.isMine) {
          return cell.copyWith(flagged: true);
        }
        return cell.copyWith(revealed: true);
      });
    });
    return MinesweeperBoard(
      size: board.size,
      mineCount: board.mineCount,
      cells: cells,
    );
  }
}
