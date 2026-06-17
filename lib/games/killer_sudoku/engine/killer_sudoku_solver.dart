import 'killer_sudoku_board.dart';

/// 킬러 스도쿠 솔버 — 스도쿠 규칙 + 케이지 합계 + 케이지 내 중복 금지
class KillerSudokuSolver {
  /// 퍼즐을 풀고 정답 반환 (풀 수 없으면 null)
  static List<List<int>>? solve(List<List<int>> puzzle, List<Cage> cages) {
    final board = _copyBoard(puzzle);
    if (_solveRecursive(board, cages)) {
      return board;
    }
    return null;
  }

  /// 유일해 여부 확인
  static bool hasUniqueSolution(List<List<int>> puzzle, List<Cage> cages) {
    return countSolutions(puzzle, cages, limit: 2) == 1;
  }

  /// 해답 개수 카운트
  /// [timeout]/[timeLimit] 지정 시, 백트래킹 도중 시간 초과되면 즉시 중단하고
  /// 현재까지 카운트된 값을 반환한다 (best-effort).
  static int countSolutions(
    List<List<int>> puzzle,
    List<Cage> cages, {
    int limit = 2,
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    final board = _copyBoard(puzzle);
    var count = 0;
    _countRecursive(
      board,
      cages,
      limit,
      (n) => count = n,
      count,
      timeout,
      timeLimit,
    );
    return count;
  }

  /// 보드가 완성되고 모든 규칙을 만족하는지 확인
  static bool isComplete(List<List<int>> board, List<Cage> cages) {
    // 빈칸 확인
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) return false;
      }
    }
    // 스도쿠 규칙 확인
    if (!_isValidSudoku(board)) return false;
    // 케이지 합계 확인
    if (!_allCagesSatisfied(board, cages)) return false;
    return true;
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

  /// 특정 셀에 값을 놓을 수 있는지 확인 (스도쿠 규칙 + 케이지)
  static bool canPlace(
    List<List<int>> board,
    List<Cage> cages,
    int row,
    int col,
    int value,
  ) {
    // 스도쿠 규칙 검증
    if (!_canPlaceSudoku(board, row, col, value)) return false;
    // 케이지 규칙 검증
    if (!_canPlaceCage(board, cages, row, col, value)) return false;
    return true;
  }

  /// 해당 셀에 놓을 수 있는 후보 숫자 목록
  static List<int> getCandidates(
    List<List<int>> board,
    List<Cage> cages,
    int row,
    int col,
  ) {
    final candidates = <int>[];
    for (var v = 1; v <= 9; v++) {
      if (canPlace(board, cages, row, col, v)) {
        candidates.add(v);
      }
    }
    return candidates;
  }

  // === 재귀 풀이 ===

  static bool _solveRecursive(List<List<int>> board, List<Cage> cages) {
    final cell = _findBestCell(board, cages);
    if (cell == null) return true; // 모든 셀 채움

    final (row, col) = cell;
    final candidates = getCandidates(board, cages, row, col);

    for (final v in candidates) {
      board[row][col] = v;
      if (_solveRecursive(board, cages)) return true;
      board[row][col] = 0;
    }
    return false;
  }

  static void _countRecursive(
    List<List<int>> board,
    List<Cage> cages,
    int limit,
    void Function(int) update,
    int current,
    Stopwatch? timeout,
    Duration? timeLimit,
  ) {
    if (current >= limit) return;
    // 시간 한도 초과 시 즉시 중단 (best-effort)
    if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
      return;
    }

    final cell = _findBestCell(board, cages);
    if (cell == null) {
      update(current + 1);
      return;
    }

    final (row, col) = cell;
    final candidates = getCandidates(board, cages, row, col);

    for (final v in candidates) {
      if (current >= limit) return;
      if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
        return;
      }
      board[row][col] = v;
      _countRecursive(board, cages, limit, (n) {
        current = n;
        update(n);
      }, current, timeout, timeLimit);
      board[row][col] = 0;
    }
  }

  /// MRV 휴리스틱: 후보 수가 가장 적은 빈 셀 찾기
  static (int, int)? _findBestCell(List<List<int>> board, List<Cage> cages) {
    int minCandidates = 10;
    (int, int)? best;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          final count = getCandidates(board, cages, r, c).length;
          if (count < minCandidates) {
            minCandidates = count;
            best = (r, c);
            if (count == 1) return best; // 즉시 반환
          }
        }
      }
    }
    return best;
  }

  // === 스도쿠 규칙 검증 ===

  static bool _canPlaceSudoku(
    List<List<int>> board,
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
    // 3x3 박스 검사
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] == value) return false;
      }
    }
    return true;
  }

  /// 케이지 규칙 검증: 중복 금지 + 합계 초과 방지
  static bool _canPlaceCage(
    List<List<int>> board,
    List<Cage> cages,
    int row,
    int col,
    int value,
  ) {
    // 해당 셀이 속한 케이지 찾기
    Cage? targetCage;
    for (final cage in cages) {
      for (final cell in cage.cells) {
        if (cell.$1 == row && cell.$2 == col) {
          targetCage = cage;
          break;
        }
      }
      if (targetCage != null) break;
    }
    if (targetCage == null) return true; // 케이지가 없으면 통과

    // 케이지 내 중복 검사
    var currentSum = 0;
    var filledCount = 0;
    for (final cell in targetCage.cells) {
      final v = board[cell.$1][cell.$2];
      if (cell.$1 == row && cell.$2 == col) continue;
      if (v != 0) {
        if (v == value) return false; // 중복
        currentSum += v;
        filledCount++;
      }
    }

    // 합계 검증: 현재합 + 새 값이 케이지 합을 초과하면 안 됨
    final newSum = currentSum + value;
    if (newSum > targetCage.sum) return false;

    // 모든 셀이 채워지면 합이 정확히 일치해야 함
    if (filledCount + 1 == targetCage.cells.length) {
      if (newSum != targetCage.sum) return false;
    }

    // 남은 빈칸이 있을 때: 남은 합을 남은 셀 수로 채울 수 있는지 확인
    final remaining = targetCage.cells.length - filledCount - 1;
    if (remaining > 0) {
      final remainingSum = targetCage.sum - newSum;
      // 최소 가능 합: 사용되지 않은 가장 작은 숫자들의 합
      // 최대 가능 합: 사용되지 않은 가장 큰 숫자들의 합
      final usedValues = <int>{value};
      for (final cell in targetCage.cells) {
        final v = board[cell.$1][cell.$2];
        if (v != 0) usedValues.add(v);
      }
      final available = <int>[];
      for (var i = 1; i <= 9; i++) {
        if (!usedValues.contains(i)) available.add(i);
      }
      if (available.length < remaining) return false;

      // 최소합
      var minSum = 0;
      for (var i = 0; i < remaining && i < available.length; i++) {
        minSum += available[i];
      }
      if (remainingSum < minSum) return false;

      // 최대합
      var maxSum = 0;
      for (var i = available.length - 1;
          i >= available.length - remaining && i >= 0;
          i--) {
        maxSum += available[i];
      }
      if (remainingSum > maxSum) return false;
    }

    return true;
  }

  /// 완성된 스도쿠 보드 유효성 검증
  static bool _isValidSudoku(List<List<int>> board) {
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
    // 3x3 박스 검사
    for (var br = 0; br < 3; br++) {
      for (var bc = 0; bc < 3; bc++) {
        final seen = <int>{};
        for (var r = br * 3; r < br * 3 + 3; r++) {
          for (var c = bc * 3; c < bc * 3 + 3; c++) {
            if (!seen.add(board[r][c])) return false;
          }
        }
      }
    }
    return true;
  }

  /// 모든 케이지 합계 만족 여부
  static bool _allCagesSatisfied(List<List<int>> board, List<Cage> cages) {
    for (final cage in cages) {
      var sum = 0;
      final seen = <int>{};
      for (final cell in cage.cells) {
        final v = board[cell.$1][cell.$2];
        if (v == 0) return false;
        if (!seen.add(v)) return false; // 케이지 내 중복
        sum += v;
      }
      if (sum != cage.sum) return false;
    }
    return true;
  }

  static List<List<int>> _copyBoard(List<List<int>> board) {
    return List.generate(9, (r) => List<int>.from(board[r]));
  }
}
