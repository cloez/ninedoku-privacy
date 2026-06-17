import 'jigsaw_sudoku_board.dart';
import 'jigsaw_sudoku_solver.dart';

/// 직소 스도쿠 힌트 결과
class JigsawSudokuHintResult {
  /// 힌트 단계 (1~4)
  final int level;

  /// 대상 셀 행
  final int row;

  /// 대상 셀 열
  final int col;

  /// 정답 값 (level 4에서 사용)
  final int? value;

  /// 후보 숫자 목록 (level 2~3에서 사용)
  final List<int> candidates;

  /// 힌트 메시지
  final String message;

  const JigsawSudokuHintResult({
    required this.level,
    required this.row,
    required this.col,
    this.value,
    this.candidates = const [],
    this.message = '',
  });
}

/// 직소 스도쿠 힌트 엔진 — 4단계 힌트
class JigsawSudokuHintEngine {
  /// 힌트 제공
  static JigsawSudokuHintResult? getHint(
    JigsawSudokuBoard board,
    int level,
  ) {
    assert(level >= 1 && level <= 4, '힌트 레벨은 1~4 범위여야 합니다');

    // 힌트 대상 셀 찾기
    final target = _findBestTarget(board);
    if (target == null) return null;

    final (row, col) = target;

    switch (level) {
      case 1:
        return _level1(board, row, col);
      case 2:
        return _level2(board, row, col);
      case 3:
        return _level3(board, row, col);
      case 4:
        return _level4(board, row, col);
      default:
        return null;
    }
  }

  /// Level 1: 영역/행/열 안내
  static JigsawSudokuHintResult _level1(
    JigsawSudokuBoard board,
    int row,
    int col,
  ) {
    final regionId = board.getRegion(row, col);
    return JigsawSudokuHintResult(
      level: 1,
      row: row,
      col: col,
      message: '영역 ${regionId + 1}의 ${row + 1}행 ${col + 1}열을 살펴보세요.',
    );
  }

  /// Level 2: 불가능한 숫자 안내
  static JigsawSudokuHintResult _level2(
    JigsawSudokuBoard board,
    int row,
    int col,
  ) {
    final candidates = JigsawSudokuSolver.getCandidates(
      board.cells,
      board.regions,
      row,
      col,
    );

    final excluded = <int>[];
    for (var v = 1; v <= 9; v++) {
      if (!candidates.contains(v)) excluded.add(v);
    }

    final message = excluded.isNotEmpty
        ? '이 셀에서 ${excluded.join(", ")}은(는) 불가능합니다.'
        : '이 셀의 후보를 확인하세요.';

    return JigsawSudokuHintResult(
      level: 2,
      row: row,
      col: col,
      candidates: candidates,
      message: message,
    );
  }

  /// Level 3: 구체적 후보 안내
  static JigsawSudokuHintResult _level3(
    JigsawSudokuBoard board,
    int row,
    int col,
  ) {
    final candidates = JigsawSudokuSolver.getCandidates(
      board.cells,
      board.regions,
      row,
      col,
    );

    return JigsawSudokuHintResult(
      level: 3,
      row: row,
      col: col,
      candidates: candidates,
      message: '${row + 1}행 ${col + 1}열은 ${candidates.join(", ")}만 가능합니다.',
    );
  }

  /// Level 4: 정답 자동 입력
  static JigsawSudokuHintResult _level4(
    JigsawSudokuBoard board,
    int row,
    int col,
  ) {
    final answer = board.solution[row][col];
    return JigsawSudokuHintResult(
      level: 4,
      row: row,
      col: col,
      value: answer,
      message: '정답은 $answer 입니다.',
    );
  }

  /// 최적 힌트 대상 셀 찾기 (후보가 적은 셀 우선)
  static (int, int)? _findBestTarget(JigsawSudokuBoard board) {
    int minCandidates = 10;
    (int, int)? best;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.cells[r][c] != 0) continue;
        final count = JigsawSudokuSolver.getCandidates(
          board.cells,
          board.regions,
          r,
          c,
        ).length;
        if (count > 0 && count < minCandidates) {
          minCandidates = count;
          best = (r, c);
          if (count == 1) return best;
        }
      }
    }
    return best;
  }
}
