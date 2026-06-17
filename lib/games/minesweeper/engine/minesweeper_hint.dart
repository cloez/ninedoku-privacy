/// 지뢰찾기 힌트 엔진 — 4단계 점진적 힌트
///
/// Level 1: 어디를 봐야 하는지 (셀 위치)
/// Level 2: 무엇을 생각해야 하는지 (주변 상황)
/// Level 3: 왜 그런지 (풀이 기법 설명)
/// Level 4: 정답 공개 (자동 열기 또는 깃발)
library;

import 'minesweeper_board.dart';

/// 힌트 액션 유형
enum HintAction {
  reveal, // 셀 열기 (안전)
  flag,   // 깃발 배치 (지뢰)
}

/// 힌트 결과
class MinesweeperHintResult {
  /// 대상 셀 좌표
  final int row;
  final int col;

  /// 힌트 레벨 (1~4)
  final int level;

  /// 힌트 메시지
  final String message;

  /// Level 4에서의 액션
  final HintAction? action;

  /// 참조 셀 (근거가 되는 숫자 셀)
  final (int, int)? referenceCell;

  const MinesweeperHintResult({
    required this.row,
    required this.col,
    required this.level,
    required this.message,
    this.action,
    this.referenceCell,
  });
}

/// 힌트 엔진
class MinesweeperHintEngine {
  /// 힌트 제공
  /// [board]: 현재 보드 상태
  /// [solution]: 정답 보드
  /// [level]: 힌트 레벨 (1~4)
  static MinesweeperHintResult? getHint(
    MinesweeperBoard board,
    MinesweeperBoard solution, {
    int level = 1,
  }) {
    // 힌트 대상 셀 찾기 (논리적으로 다음에 확정할 수 있는 셀)
    final target = _findHintTarget(board, solution);
    if (target == null) return null;

    final (targetRow, targetCol, action, refRow, refCol) = target;

    switch (level) {
      case 1:
        return MinesweeperHintResult(
          row: targetRow,
          col: targetCol,
          level: 1,
          message: '행 ${targetRow + 1}, 열 ${targetCol + 1} 주변을 살펴보세요',
          referenceCell: (refRow, refCol),
        );

      case 2:
        final refCell = board.getCell(refRow, refCol);
        final nbrs = board.neighbors(refRow, refCol);
        final closedCount = nbrs.where((pos) {
          final c = board.getCell(pos.$1, pos.$2);
          return !c.revealed && !c.flagged;
        }).length;
        final flagCount = nbrs.where((pos) {
          final c = board.getCell(pos.$1, pos.$2);
          return c.flagged;
        }).length;

        return MinesweeperHintResult(
          row: targetRow,
          col: targetCol,
          level: 2,
          message: '숫자 ${refCell.adjacentMines} 주변에 '
              '닫힌 셀 $closedCount개, ⚑ $flagCount개가 있습니다',
          referenceCell: (refRow, refCol),
        );

      case 3:
        return _buildLevel3Hint(board, targetRow, targetCol, action, refRow, refCol);

      case 4:
        final actionMsg = action == HintAction.reveal
            ? '이 셀은 안전합니다 — 열었습니다'
            : '이 셀은 지뢰입니다 — ⚑를 세웠습니다';
        return MinesweeperHintResult(
          row: targetRow,
          col: targetCol,
          level: 4,
          message: actionMsg,
          action: action,
          referenceCell: (refRow, refCol),
        );

      default:
        return null;
    }
  }

  /// 힌트 대상 셀 찾기: (row, col, action, refRow, refCol)
  static (int, int, HintAction, int, int)? _findHintTarget(
    MinesweeperBoard board,
    MinesweeperBoard solution,
  ) {
    // 열린 숫자 셀 순회하면서 확정 가능한 셀 찾기
    for (int r = 0; r < board.size; r++) {
      for (int c = 0; c < board.size; c++) {
        final cell = board.getCell(r, c);
        if (!cell.revealed || cell.adjacentMines == 0) continue;

        final nbrs = board.neighbors(r, c);
        int closedCount = 0;
        int flagCount = 0;
        final closedNbrs = <(int, int)>[];

        for (final (nr, nc) in nbrs) {
          final n = board.getCell(nr, nc);
          if (!n.revealed) {
            if (n.flagged) {
              flagCount++;
            } else {
              closedCount++;
              closedNbrs.add((nr, nc));
            }
          }
        }

        if (closedNbrs.isEmpty) continue;
        final remaining = cell.adjacentMines - flagCount;

        // 모든 닫힌 셀이 지뢰
        if (remaining == closedCount && closedCount > 0) {
          final target = closedNbrs.first;
          return (target.$1, target.$2, HintAction.flag, r, c);
        }

        // 남은 지뢰 0 → 모든 닫힌 셀 안전
        if (remaining == 0 && closedCount > 0) {
          final target = closedNbrs.first;
          return (target.$1, target.$2, HintAction.reveal, r, c);
        }
      }
    }

    // 기본 논리로 찾지 못했으면 정답 보드에서 안전한 셀 찾기
    for (int r = 0; r < board.size; r++) {
      for (int c = 0; c < board.size; c++) {
        final cell = board.getCell(r, c);
        final sol = solution.getCell(r, c);
        if (!cell.revealed && !cell.flagged) {
          if (sol.revealed) {
            // 안전한 셀 — 가장 가까운 열린 숫자 셀 참조
            final ref = _findNearestNumberCell(board, r, c);
            return (r, c, HintAction.reveal, ref.$1, ref.$2);
          }
        }
      }
    }

    return null;
  }

  /// Level 3 힌트 메시지 생성 (풀이 기법 설명)
  static MinesweeperHintResult _buildLevel3Hint(
    MinesweeperBoard board,
    int targetRow,
    int targetCol,
    HintAction action,
    int refRow,
    int refCol,
  ) {
    final refCell = board.getCell(refRow, refCol);
    final nbrs = board.neighbors(refRow, refCol);
    final flagCount = nbrs.where((pos) {
      final c = board.getCell(pos.$1, pos.$2);
      return c.flagged;
    }).length;
    final closedCount = nbrs.where((pos) {
      final c = board.getCell(pos.$1, pos.$2);
      return !c.revealed && !c.flagged;
    }).length;
    final remaining = refCell.adjacentMines - flagCount;

    String message;
    if (action == HintAction.flag) {
      message = '숫자 ${refCell.adjacentMines}에서 ⚑가 $flagCount개이므로 '
          '남은 지뢰는 $remaining개입니다. '
          '닫힌 셀이 $closedCount개이므로 모두 지뢰(⚑)입니다';
    } else {
      if (remaining == 0) {
        message = '숫자 ${refCell.adjacentMines} 주변의 ⚑가 이미 '
            '${refCell.adjacentMines}개이므로, '
            '남은 닫힌 셀은 모두 안전합니다';
      } else {
        message = '이 셀은 정답 기준으로 안전합니다. 열어보세요';
      }
    }

    return MinesweeperHintResult(
      row: targetRow,
      col: targetCol,
      level: 3,
      message: message,
      referenceCell: (refRow, refCol),
    );
  }

  /// 가장 가까운 열린 숫자 셀 찾기
  static (int, int) _findNearestNumberCell(MinesweeperBoard board, int row, int col) {
    int bestDist = board.size * 2;
    var best = (0, 0);

    for (int r = 0; r < board.size; r++) {
      for (int c = 0; c < board.size; c++) {
        final cell = board.getCell(r, c);
        if (cell.revealed && cell.adjacentMines > 0) {
          final dist = (r - row).abs() + (c - col).abs();
          if (dist < bestDist) {
            bestDist = dist;
            best = (r, c);
          }
        }
      }
    }

    return best;
  }
}
