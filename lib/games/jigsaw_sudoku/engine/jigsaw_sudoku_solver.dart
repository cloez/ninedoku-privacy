/// 직소 스도쿠 솔버 — 행/열/불규칙 영역 규칙 검증 + 백트래킹
class JigsawSudokuSolver {
  /// 퍼즐을 풀고 정답 반환 (풀 수 없으면 null)
  static List<List<int>>? solve(
    List<List<int>> puzzle,
    List<List<int>> regions,
  ) {
    final board = _copyBoard(puzzle);
    if (_solveRecursive(board, regions)) {
      return board;
    }
    return null;
  }

  /// 유일해 여부 확인
  static bool hasUniqueSolution(
    List<List<int>> puzzle,
    List<List<int>> regions, {
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    return countSolutions(
          puzzle,
          regions,
          limit: 2,
          timeout: timeout,
          timeLimit: timeLimit,
        ) ==
        1;
  }

  /// 해답 개수 카운트
  /// [timeout]/[timeLimit] 지정 시 시간 초과되면 즉시 중단 (best-effort)
  static int countSolutions(
    List<List<int>> puzzle,
    List<List<int>> regions, {
    int limit = 2,
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    final board = _copyBoard(puzzle);
    var count = 0;
    _countRecursive(
      board,
      regions,
      limit,
      (n) => count = n,
      count,
      timeout,
      timeLimit,
    );
    return count;
  }

  /// 보드가 완성되고 모든 규칙을 만족하는지 확인
  static bool isComplete(List<List<int>> board, List<List<int>> regions) {
    // 빈칸 확인
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) return false;
      }
    }
    return _isValid(board, regions);
  }

  /// 현재 보드가 정답과 일치하는지 확인
  static bool matchesSolution(
    List<List<int>> current,
    List<List<int>> solution,
  ) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (current[r][c] != 0 && current[r][c] != solution[r][c]) {
          return false;
        }
      }
    }
    return true;
  }

  /// 특정 셀에 값을 놓을 수 있는지 확인
  static bool canPlace(
    List<List<int>> board,
    List<List<int>> regions,
    int row,
    int col,
    int value,
  ) {
    // 행 검사
    for (var c = 0; c < 9; c++) {
      if (board[row][c] == value) return false;
    }
    // 열 검사
    for (var r = 0; r < 9; r++) {
      if (board[r][col] == value) return false;
    }
    // 영역 검사
    final region = regions[row][col];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (regions[r][c] == region && board[r][c] == value) return false;
      }
    }
    return true;
  }

  /// 해당 셀에 놓을 수 있는 후보 숫자 목록
  static List<int> getCandidates(
    List<List<int>> board,
    List<List<int>> regions,
    int row,
    int col,
  ) {
    final candidates = <int>[];
    for (var v = 1; v <= 9; v++) {
      if (canPlace(board, regions, row, col, v)) {
        candidates.add(v);
      }
    }
    return candidates;
  }

  // === 재귀 풀이 ===

  static bool _solveRecursive(
    List<List<int>> board,
    List<List<int>> regions,
  ) {
    final cell = _findBestCell(board, regions);
    if (cell == null) return true; // 모든 셀 채움

    final (row, col) = cell;
    final candidates = getCandidates(board, regions, row, col);

    for (final v in candidates) {
      board[row][col] = v;
      if (_solveRecursive(board, regions)) return true;
      board[row][col] = 0;
    }
    return false;
  }

  static void _countRecursive(
    List<List<int>> board,
    List<List<int>> regions,
    int limit,
    void Function(int) update,
    int current,
    Stopwatch? timeout,
    Duration? timeLimit,
  ) {
    if (current >= limit) return;
    if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
      return;
    }

    final cell = _findBestCell(board, regions);
    if (cell == null) {
      update(current + 1);
      return;
    }

    final (row, col) = cell;
    final candidates = getCandidates(board, regions, row, col);

    for (final v in candidates) {
      if (current >= limit) return;
      if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
        return;
      }
      board[row][col] = v;
      _countRecursive(board, regions, limit, (n) {
        current = n;
        update(n);
      }, current, timeout, timeLimit);
      board[row][col] = 0;
    }
  }

  /// MRV 휴리스틱: 후보 수가 가장 적은 빈 셀 찾기
  static (int, int)? _findBestCell(
    List<List<int>> board,
    List<List<int>> regions,
  ) {
    int minCandidates = 10;
    (int, int)? best;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          final count = getCandidates(board, regions, r, c).length;
          if (count < minCandidates) {
            minCandidates = count;
            best = (r, c);
            if (count == 1) return best;
          }
        }
      }
    }
    return best;
  }

  /// 완성된 보드 유효성 검증
  static bool _isValid(List<List<int>> board, List<List<int>> regions) {
    // 행 검사
    for (var r = 0; r < 9; r++) {
      final seen = <int>{};
      for (var c = 0; c < 9; c++) {
        final v = board[r][c];
        if (v < 1 || v > 9 || !seen.add(v)) return false;
      }
    }
    // 열 검사
    for (var c = 0; c < 9; c++) {
      final seen = <int>{};
      for (var r = 0; r < 9; r++) {
        if (!seen.add(board[r][c])) return false;
      }
    }
    // 영역 검사
    for (var region = 0; region < 9; region++) {
      final seen = <int>{};
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (regions[r][c] == region) {
            if (!seen.add(board[r][c])) return false;
          }
        }
      }
    }
    return true;
  }

  static List<List<int>> _copyBoard(List<List<int>> board) {
    return List.generate(9, (r) => List<int>.from(board[r]));
  }
}
