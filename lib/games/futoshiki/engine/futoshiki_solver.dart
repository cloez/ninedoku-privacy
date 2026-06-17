import 'futoshiki_board.dart';

/// 후토시키 솔버
/// 라틴 방진 + 부등호 제약 검증, 백트래킹 기반
class FutoshikiSolver {
  /// 퍼즐을 풀고 해답 보드 반환 (풀 수 없으면 null)
  static FutoshikiBoard? solve(FutoshikiBoard board) {
    final cells = List<int>.from(board.cells);
    if (_solveRecursive(cells, board)) {
      return board.copyWith(cells: cells);
    }
    return null;
  }

  /// 해가 정확히 1개인지 검증
  static bool hasUniqueSolution(
    FutoshikiBoard board, {
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    return countSolutions(
          board,
          limit: 2,
          timeout: timeout,
          timeLimit: timeLimit,
        ) ==
        1;
  }

  /// 해답 개수 카운트 (limit에 도달하면 조기 종료)
  /// [timeout]/[timeLimit] 지정 시 시간 초과되면 즉시 중단 (best-effort)
  static int countSolutions(
    FutoshikiBoard board, {
    int limit = 2,
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    final cells = List<int>.from(board.cells);
    var count = 0;
    _countRecursive(
      cells,
      board,
      limit,
      (n) => count = n,
      count,
      timeout,
      timeLimit,
    );
    return count;
  }

  /// 현재 상태에서 규칙 위반 없는지 확인 (부분 검증 — 빈칸 허용)
  static bool isValid(FutoshikiBoard board) {
    return _checkLatinPartial(board.cells, board.size) &&
        _checkAllConstraints(board);
  }

  /// 모든 셀 채워졌고 모든 규칙 만족하는지
  static bool isComplete(FutoshikiBoard board) {
    if (!board.isComplete) return false;
    return _checkLatinComplete(board.cells, board.size) &&
        _checkAllConstraints(board);
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 풀이 로직
  // ──────────────────────────────────────────────────────────────────

  /// 재귀 백트래킹 풀이
  static bool _solveRecursive(List<int> cells, FutoshikiBoard board) {
    final idx = _findBestEmptyCell(cells, board);
    if (idx == -1) return true; // 모든 셀 채워짐
    if (idx == -2) return false; // 데드엔드

    final size = board.size;
    for (var v = 1; v <= size; v++) {
      cells[idx] = v;
      if (_isValidPlacement(cells, board, idx)) {
        if (_solveRecursive(cells, board)) return true;
      }
      cells[idx] = 0;
    }
    return false;
  }

  /// 해답 개수 카운팅용 재귀
  static void _countRecursive(
    List<int> cells,
    FutoshikiBoard board,
    int limit,
    void Function(int) updateCount,
    int currentCount,
    Stopwatch? timeout,
    Duration? timeLimit,
  ) {
    if (currentCount >= limit) return;
    if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
      return;
    }

    final idx = _findBestEmptyCell(cells, board);
    if (idx == -1) {
      updateCount(currentCount + 1);
      return;
    }
    if (idx == -2) return;

    final size = board.size;
    for (var v = 1; v <= size; v++) {
      if (currentCount >= limit) return;
      if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
        return;
      }
      cells[idx] = v;
      if (_isValidPlacement(cells, board, idx)) {
        _countRecursive(cells, board, limit, (n) {
          currentCount = n;
          updateCount(n);
        }, currentCount, timeout, timeLimit);
      }
      cells[idx] = 0;
    }
  }

  /// MRV 휴리스틱: 가능한 값이 가장 적은 빈 셀 찾기
  static int _findBestEmptyCell(List<int> cells, FutoshikiBoard board) {
    final size = board.size;
    int bestIdx = -1;
    int minOptions = size + 1;

    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != 0) continue;

      var options = 0;
      for (var v = 1; v <= size; v++) {
        cells[i] = v;
        if (_isValidPlacement(cells, board, i)) options++;
        cells[i] = 0;
      }

      if (options == 0) return -2; // 데드엔드
      if (options < minOptions) {
        minOptions = options;
        bestIdx = i;
        if (options == 1) return bestIdx; // 즉시 반환
      }
    }
    return bestIdx;
  }

  /// 특정 셀에 값을 놓았을 때 유효성 검사
  static bool _isValidPlacement(
      List<int> cells, FutoshikiBoard board, int idx) {
    final size = board.size;
    final row = idx ~/ size;
    final col = idx % size;
    final value = cells[idx];

    // 1) 행에서 중복 검사
    for (var c = 0; c < size; c++) {
      if (c != col && cells[row * size + c] == value) return false;
    }

    // 2) 열에서 중복 검사
    for (var r = 0; r < size; r++) {
      if (r != row && cells[r * size + col] == value) return false;
    }

    // 3) 부등호 제약 검사 (해당 셀 관련)
    // 왼쪽 부등호: (row, col-1) < > (row, col)
    if (col > 0) {
      final h = board.getHorizontalConstraint(row, col - 1);
      final leftVal = cells[row * size + col - 1];
      if (leftVal != 0 && h != 0) {
        if (h == 1 && !(leftVal < value)) return false; // 왼쪽 < 오른쪽
        if (h == 2 && !(leftVal > value)) return false; // 왼쪽 > 오른쪽
      }
    }

    // 오른쪽 부등호: (row, col) < > (row, col+1)
    if (col < size - 1) {
      final h = board.getHorizontalConstraint(row, col);
      final rightVal = cells[row * size + col + 1];
      if (rightVal != 0 && h != 0) {
        if (h == 1 && !(value < rightVal)) return false;
        if (h == 2 && !(value > rightVal)) return false;
      }
    }

    // 위쪽 부등호: (row-1, col) < > (row, col)
    if (row > 0) {
      final v = board.getVerticalConstraint(row - 1, col);
      final topVal = cells[(row - 1) * size + col];
      if (topVal != 0 && v != 0) {
        if (v == 1 && !(topVal < value)) return false; // 위 < 아래
        if (v == 2 && !(topVal > value)) return false; // 위 > 아래
      }
    }

    // 아래쪽 부등호: (row, col) < > (row+1, col)
    if (row < size - 1) {
      final v = board.getVerticalConstraint(row, col);
      final bottomVal = cells[(row + 1) * size + col];
      if (bottomVal != 0 && v != 0) {
        if (v == 1 && !(value < bottomVal)) return false;
        if (v == 2 && !(value > bottomVal)) return false;
      }
    }

    return true;
  }

  // ──────────────────────────────────────────────────────────────────
  // 규칙 검증
  // ──────────────────────────────────────────────────────────────────

  /// 라틴 방진 완전 검사 (모든 셀 채워진 상태)
  static bool _checkLatinComplete(List<int> cells, int size) {
    // 행 검사
    for (var r = 0; r < size; r++) {
      final seen = <int>{};
      for (var c = 0; c < size; c++) {
        final v = cells[r * size + c];
        if (v == 0 || !seen.add(v)) return false;
      }
    }
    // 열 검사
    for (var c = 0; c < size; c++) {
      final seen = <int>{};
      for (var r = 0; r < size; r++) {
        final v = cells[r * size + c];
        if (v == 0 || !seen.add(v)) return false;
      }
    }
    return true;
  }

  /// 라틴 방진 부분 검사 (빈칸 허용 — 중복만 검사)
  static bool _checkLatinPartial(List<int> cells, int size) {
    // 행 검사
    for (var r = 0; r < size; r++) {
      final seen = <int>{};
      for (var c = 0; c < size; c++) {
        final v = cells[r * size + c];
        if (v != 0 && !seen.add(v)) return false;
      }
    }
    // 열 검사
    for (var c = 0; c < size; c++) {
      final seen = <int>{};
      for (var r = 0; r < size; r++) {
        final v = cells[r * size + c];
        if (v != 0 && !seen.add(v)) return false;
      }
    }
    return true;
  }

  /// 모든 부등호 제약 검사 (채워진 셀만)
  static bool _checkAllConstraints(FutoshikiBoard board) {
    final size = board.size;

    // 수평 부등호 검사
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size - 1; c++) {
        final h = board.getHorizontalConstraint(r, c);
        if (h == 0) continue;
        final left = board.getValue(r, c);
        final right = board.getValue(r, c + 1);
        if (left == 0 || right == 0) continue; // 빈칸은 스킵
        if (h == 1 && !(left < right)) return false;
        if (h == 2 && !(left > right)) return false;
      }
    }

    // 수직 부등호 검사
    for (var r = 0; r < size - 1; r++) {
      for (var c = 0; c < size; c++) {
        final v = board.getVerticalConstraint(r, c);
        if (v == 0) continue;
        final top = board.getValue(r, c);
        final bottom = board.getValue(r + 1, c);
        if (top == 0 || bottom == 0) continue;
        if (v == 1 && !(top < bottom)) return false;
        if (v == 2 && !(top > bottom)) return false;
      }
    }

    return true;
  }

  /// 특정 셀의 행/열에서 중복이 있는지 검사 (UI 에러 표시용)
  static bool hasRowColConflict(FutoshikiBoard board, int row, int col) {
    final size = board.size;
    final value = board.getValue(row, col);
    if (value == 0) return false;

    // 행 중복
    for (var c = 0; c < size; c++) {
      if (c != col && board.getValue(row, c) == value) return true;
    }
    // 열 중복
    for (var r = 0; r < size; r++) {
      if (r != row && board.getValue(r, col) == value) return true;
    }
    return false;
  }

  /// 특정 셀이 부등호 위반이 있는지 검사 (UI 에러 표시용)
  static bool hasConstraintViolation(FutoshikiBoard board, int row, int col) {
    final size = board.size;
    final value = board.getValue(row, col);
    if (value == 0) return false;

    // 왼쪽
    if (col > 0) {
      final h = board.getHorizontalConstraint(row, col - 1);
      final left = board.getValue(row, col - 1);
      if (h != 0 && left != 0) {
        if (h == 1 && !(left < value)) return true;
        if (h == 2 && !(left > value)) return true;
      }
    }
    // 오른쪽
    if (col < size - 1) {
      final h = board.getHorizontalConstraint(row, col);
      final right = board.getValue(row, col + 1);
      if (h != 0 && right != 0) {
        if (h == 1 && !(value < right)) return true;
        if (h == 2 && !(value > right)) return true;
      }
    }
    // 위쪽
    if (row > 0) {
      final v = board.getVerticalConstraint(row - 1, col);
      final top = board.getValue(row - 1, col);
      if (v != 0 && top != 0) {
        if (v == 1 && !(top < value)) return true;
        if (v == 2 && !(top > value)) return true;
      }
    }
    // 아래쪽
    if (row < size - 1) {
      final v = board.getVerticalConstraint(row, col);
      final bottom = board.getValue(row + 1, col);
      if (v != 0 && bottom != 0) {
        if (v == 1 && !(value < bottom)) return true;
        if (v == 2 && !(value > bottom)) return true;
      }
    }

    return false;
  }
}
