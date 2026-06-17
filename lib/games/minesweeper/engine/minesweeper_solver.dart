/// 지뢰찾기 솔버 — 논리적 풀이 가능 여부 검증
///
/// 찍기 없는 지뢰찾기(No-guess Minesweeper)를 보장하기 위해,
/// 생성된 퍼즐이 순수 논리만으로 풀 수 있는지 검증한다.
library;

import 'minesweeper_board.dart';

/// 솔버 결과
class SolverResult {
  /// 풀이 성공 여부
  final bool solved;

  /// 풀이 완료된 보드
  final MinesweeperBoard board;

  /// 풀이 과정에서 적용한 단계 수
  final int steps;

  const SolverResult({
    required this.solved,
    required this.board,
    required this.steps,
  });
}

/// 지뢰찾기 솔버
class MinesweeperSolver {
  /// 논리적 풀이 시도
  /// [startRow], [startCol]: 첫 클릭 위치 (이미 열려 있어야 함)
  static SolverResult solve(MinesweeperBoard board) {
    var current = board.copyWith();
    int totalSteps = 0;
    bool changed = true;

    while (changed && !current.isWon) {
      changed = false;

      // 열린 숫자 셀 순회
      for (int r = 0; r < current.size; r++) {
        for (int c = 0; c < current.size; c++) {
          final cell = current.getCell(r, c);
          if (!cell.revealed || cell.isMine) continue;
          if (cell.adjacentMines == 0) continue;

          final nbrs = current.neighbors(r, c);

          // 주변 닫힌 셀과 깃발 수 계산
          int closedCount = 0;
          int flagCount = 0;
          final closedNbrs = <(int, int)>[];

          for (final (nr, nc) in nbrs) {
            final n = current.getCell(nr, nc);
            if (!n.revealed) {
              if (n.flagged) {
                flagCount++;
              } else {
                closedCount++;
                closedNbrs.add((nr, nc));
              }
            }
          }

          final remainingMines = cell.adjacentMines - flagCount;

          // 규칙 1: 남은 지뢰 수 == 닫힌 셀 수 → 모두 지뢰 (깃발)
          if (remainingMines == closedCount && closedCount > 0) {
            for (final (nr, nc) in closedNbrs) {
              current = current.toggleFlag(nr, nc);
              changed = true;
              totalSteps++;
            }
          }

          // 규칙 2: 남은 지뢰 수 == 0 → 닫힌 셀 모두 안전 (열기)
          if (remainingMines == 0 && closedCount > 0) {
            for (final (nr, nc) in closedNbrs) {
              current = _revealWithCascade(current, nr, nc);
              changed = true;
              totalSteps++;
            }
          }
        }
      }

      // 고급 논리: 두 숫자 셀의 영향 범위 교차 분석
      if (!changed && !current.isWon) {
        final advanced = _advancedLogic(current);
        if (advanced != null) {
          current = advanced;
          changed = true;
          totalSteps++;
        }
      }
    }

    return SolverResult(
      solved: current.isWon,
      board: current,
      steps: totalSteps,
    );
  }

  /// 연쇄 오픈 (빈 칸 → 주변 자동 오픈)
  static MinesweeperBoard _revealWithCascade(MinesweeperBoard board, int row, int col) {
    final cell = board.getCell(row, col);
    if (cell.revealed || cell.flagged || cell.isMine) return board;

    var current = board.revealCell(row, col);

    // 빈 칸(0)이면 주변 재귀 오픈
    if (cell.adjacentMines == 0) {
      for (final (nr, nc) in current.neighbors(row, col)) {
        final n = current.getCell(nr, nc);
        if (!n.revealed && !n.flagged) {
          current = _revealWithCascade(current, nr, nc);
        }
      }
    }

    return current;
  }

  /// 연쇄 오픈 (공개 API — Generator에서도 사용)
  static MinesweeperBoard revealWithCascade(MinesweeperBoard board, int row, int col) {
    return _revealWithCascade(board, row, col);
  }

  /// 고급 논리: 두 인접 숫자 셀의 제약 비교
  static MinesweeperBoard? _advancedLogic(MinesweeperBoard board) {
    for (int r = 0; r < board.size; r++) {
      for (int c = 0; c < board.size; c++) {
        final cell = board.getCell(r, c);
        if (!cell.revealed || cell.adjacentMines == 0) continue;

        final nbrs1 = board.neighbors(r, c);
        final closed1 = _getClosedUnflagged(board, nbrs1);
        final flags1 = _getFlagCount(board, nbrs1);
        final remaining1 = cell.adjacentMines - flags1;

        if (closed1.isEmpty || remaining1 < 0) continue;

        // 주변 열린 숫자 셀과 비교
        for (final (nr, nc) in nbrs1) {
          final neighbor = board.getCell(nr, nc);
          if (!neighbor.revealed || neighbor.adjacentMines == 0) continue;

          final nbrs2 = board.neighbors(nr, nc);
          final closed2 = _getClosedUnflagged(board, nbrs2);
          final flags2 = _getFlagCount(board, nbrs2);
          final remaining2 = neighbor.adjacentMines - flags2;

          if (closed2.isEmpty || remaining2 < 0) continue;

          // closed1 ⊂ closed2인 경우
          final set1 = closed1.toSet();
          final set2 = closed2.toSet();

          if (set1.length < set2.length && set2.containsAll(set1)) {
            final diff = set2.difference(set1);
            final diffMines = remaining2 - remaining1;

            // diff에 정확히 diffMines개의 지뢰
            if (diffMines == 0) {
              // diff 셀 모두 안전
              var current = board;
              for (final (dr, dc) in diff) {
                current = _revealWithCascade(current, dr, dc);
              }
              return current;
            } else if (diffMines == diff.length) {
              // diff 셀 모두 지뢰
              var current = board;
              for (final (dr, dc) in diff) {
                current = current.toggleFlag(dr, dc);
              }
              return current;
            }
          }

          // 반대도 확인: closed2 ⊂ closed1
          if (set2.length < set1.length && set1.containsAll(set2)) {
            final diff = set1.difference(set2);
            final diffMines = remaining1 - remaining2;

            if (diffMines == 0) {
              var current = board;
              for (final (dr, dc) in diff) {
                current = _revealWithCascade(current, dr, dc);
              }
              return current;
            } else if (diffMines == diff.length) {
              var current = board;
              for (final (dr, dc) in diff) {
                current = current.toggleFlag(dr, dc);
              }
              return current;
            }
          }
        }
      }
    }
    return null;
  }

  /// 닫힌 깃발 없는 이웃 목록
  static List<(int, int)> _getClosedUnflagged(
    MinesweeperBoard board,
    List<(int, int)> neighbors,
  ) {
    return neighbors.where((pos) {
      final cell = board.getCell(pos.$1, pos.$2);
      return !cell.revealed && !cell.flagged;
    }).toList();
  }

  /// 깃발 수
  static int _getFlagCount(
    MinesweeperBoard board,
    List<(int, int)> neighbors,
  ) {
    return neighbors.where((pos) {
      final cell = board.getCell(pos.$1, pos.$2);
      return cell.flagged;
    }).length;
  }

  /// 퍼즐이 논리적으로 풀리는지 검증
  /// (첫 클릭 후의 보드를 입력)
  static bool isSolvableByLogic(MinesweeperBoard board) {
    final result = solve(board);
    return result.solved;
  }
}
