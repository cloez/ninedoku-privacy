/// 노노그램 힌트 엔진 — 4단계 점진적 힌트
library;

import 'nonogram_board.dart';
import 'nonogram_solver.dart';

class NonogramHintResult {
  final int row;
  final int col;
  final int level;
  final String message;
  /// Level 4에서의 정답 값 (1: 채움, 0: 빈칸)
  final int? value;

  const NonogramHintResult({
    required this.row,
    required this.col,
    required this.level,
    required this.message,
    this.value,
  });
}

class NonogramHintEngine {
  static NonogramHintResult? getHint(
    NonogramBoard board,
    NonogramBoard solution, {
    int level = 1,
  }) {
    final target = _findTarget(board, solution);
    if (target == null) return null;

    final (row, col, correctValue) = target;
    final symbol = correctValue == 1 ? '■' : '✕';

    switch (level) {
      case 1:
        return NonogramHintResult(
          row: row, col: col, level: 1,
          message: '행 ${row + 1}을 살펴보세요',
        );

      case 2:
        final hints = board.rowHints[row];
        return NonogramHintResult(
          row: row, col: col, level: 2,
          message: '행 ${row + 1}의 힌트 $hints를 보면 일부 셀을 확정할 수 있습니다',
        );

      case 3:
        return NonogramHintResult(
          row: row, col: col, level: 3,
          message: _buildExplanation(board, row, col, correctValue),
        );

      case 4:
        return NonogramHintResult(
          row: row, col: col, level: 4,
          message: '이 셀은 $symbol입니다',
          value: correctValue,
        );

      default:
        return null;
    }
  }

  /// 힌트 대상 찾기 — 솔버로 확정 가능한 셀 우선
  static (int, int, int)? _findTarget(NonogramBoard board, NonogramBoard solution) {
    // 솔버로 한 단계 진행
    final solved = NonogramSolver.solve(board);
    if (solved != null) {
      for (int i = 0; i < board.cells.length; i++) {
        if (board.cells[i] == -1 && solved.cells[i] != -1) {
          return (i ~/ board.cols, i % board.cols, solved.cells[i]);
        }
      }
    }

    // 솔버로 못 찾으면 정답 기반
    for (int i = 0; i < board.cells.length; i++) {
      if (board.cells[i] == -1) {
        final solVal = solution.cells[i];
        if (solVal == -1) continue;
        return (i ~/ board.cols, i % board.cols, solVal);
      }
    }

    return null;
  }

  static String _buildExplanation(NonogramBoard board, int row, int col, int value) {
    final rowHints = board.rowHints[row];
    final colHints = board.colHints[col];
    final symbol = value == 1 ? '■' : '✕';

    if (value == 1) {
      return '행 힌트 $rowHints와 열 힌트 $colHints의 겹치는 영역에서 '
          '이 셀은 반드시 $symbol이어야 합니다';
    } else {
      return '행 힌트 $rowHints와 열 힌트 $colHints를 분석하면 '
          '이 위치에 ■을 놓을 수 없으므로 $symbol입니다';
    }
  }
}
