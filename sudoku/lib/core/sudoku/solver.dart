/// 백트래킹 기반 스도쿠 풀이기
class SudokuSolver {
  /// 퍼즐을 풀고 솔루션 반환 (풀 수 없으면 null)
  static List<List<int>>? solve(List<List<int>> puzzle) {
    final board = _copyBoard(puzzle);
    if (_solveRecursive(board)) {
      return board;
    }
    return null;
  }

  /// 유일해답 여부 확인 (해답이 정확히 1개인지)
  static bool hasUniqueSolution(List<List<int>> puzzle) {
    return countSolutions(puzzle, limit: 2) == 1;
  }

  /// 해답 개수 카운트 (limit에 도달하면 조기 종료)
  static int countSolutions(List<List<int>> puzzle, {int limit = 2}) {
    final board = _copyBoard(puzzle);
    var count = 0;
    _countRecursive(board, count, limit, (newCount) => count = newCount);
    return count;
  }

  /// 재귀 풀이
  static bool _solveRecursive(List<List<int>> board) {
    final emptyCell = _findEmptyCell(board);
    if (emptyCell == null) return true;

    final (row, col) = emptyCell;
    // MRV(최소 남은 값) 휴리스틱: 가능한 값만 시도
    final candidates = _getCandidates(board, row, col);

    for (final num in candidates) {
      board[row][col] = num;
      if (_solveRecursive(board)) return true;
      board[row][col] = 0;
    }
    return false;
  }

  /// 해답 개수 카운팅용 재귀
  static void _countRecursive(
    List<List<int>> board,
    int currentCount,
    int limit,
    void Function(int) updateCount,
  ) {
    if (currentCount >= limit) return;

    final emptyCell = _findEmptyCell(board);
    if (emptyCell == null) {
      updateCount(currentCount + 1);
      return;
    }

    final (row, col) = emptyCell;
    final candidates = _getCandidates(board, row, col);

    for (final num in candidates) {
      if (currentCount >= limit) return;
      board[row][col] = num;
      _countRecursive(board, currentCount, limit, (newCount) {
        currentCount = newCount;
        updateCount(newCount);
      });
      board[row][col] = 0;
    }
  }

  /// 비어있는 셀 찾기 (MRV: 후보 수가 가장 적은 셀 우선)
  static (int, int)? _findEmptyCell(List<List<int>> board) {
    int minCandidates = 10;
    (int, int)? bestCell;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          final count = _getCandidates(board, r, c).length;
          if (count < minCandidates) {
            minCandidates = count;
            bestCell = (r, c);
            if (count == 1) return bestCell;
          }
        }
      }
    }
    return bestCell;
  }

  /// 특정 셀에 넣을 수 있는 후보 숫자 목록
  static List<int> _getCandidates(List<List<int>> board, int row, int col) {
    final used = <bool>[false, ...List.filled(9, false)]; // 인덱스 1~9

    // 행 체크
    for (var c = 0; c < 9; c++) {
      if (board[row][c] != 0) used[board[row][c]] = true;
    }
    // 열 체크
    for (var r = 0; r < 9; r++) {
      if (board[r][col] != 0) used[board[r][col]] = true;
    }
    // 박스 체크
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] != 0) used[board[r][c]] = true;
      }
    }

    final candidates = <int>[];
    for (var n = 1; n <= 9; n++) {
      if (!used[n]) candidates.add(n);
    }
    return candidates;
  }

  /// 보드 유효성 검증 (현재 상태가 규칙을 위반하지 않는지)
  static bool isValid(List<List<int>> board) {
    // 행 검증
    for (var r = 0; r < 9; r++) {
      if (!_isGroupValid(board[r])) return false;
    }
    // 열 검증
    for (var c = 0; c < 9; c++) {
      final col = List.generate(9, (r) => board[r][c]);
      if (!_isGroupValid(col)) return false;
    }
    // 박스 검증
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final box = <int>[];
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            box.add(board[r][c]);
          }
        }
        if (!_isGroupValid(box)) return false;
      }
    }
    return true;
  }

  /// 그룹(행/열/박스) 유효성: 0이 아닌 숫자 중 중복이 없어야 함
  static bool _isGroupValid(List<int> group) {
    final seen = <int>{};
    for (final n in group) {
      if (n != 0) {
        if (seen.contains(n)) return false;
        seen.add(n);
      }
    }
    return true;
  }

  static List<List<int>> _copyBoard(List<List<int>> board) {
    return List.generate(9, (r) => List<int>.from(board[r]));
  }
}
