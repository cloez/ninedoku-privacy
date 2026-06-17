import 'binairo_board.dart';

/// Binairo 솔버
/// 백트래킹 기반으로 풀이하며, 규칙 검증 기능 포함
class BinairoSolver {
  /// 퍼즐을 풀고 해답 보드 반환 (풀 수 없으면 null)
  static BinairoBoard? solve(BinairoBoard board) {
    final cells = List<int>.from(board.cells);
    if (_solveRecursive(cells, board.size)) {
      return BinairoBoard(
        size: board.size,
        cells: cells,
        fixed: board.fixed,
      );
    }
    return null;
  }

  /// 해가 정확히 1개인지 검증
  static bool hasUniqueSolution(
    BinairoBoard board, {
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
  /// [timeout]/[timeLimit] 지정 시, 시간 초과되면 즉시 중단하고 현재까지 카운트 반환 (best-effort)
  static int countSolutions(
    BinairoBoard board, {
    int limit = 2,
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    final cells = List<int>.from(board.cells);
    var count = 0;
    _countRecursive(
      cells,
      board.size,
      limit,
      (newCount) => count = newCount,
      count,
      timeout,
      timeLimit,
    );
    return count;
  }

  /// 현재 상태에서 규칙 위반 없는지 확인 (부분 검증 — 빈칸 허용)
  static bool isValid(BinairoBoard board) {
    return _checkNoTriple(board.cells, board.size) &&
        _checkBalancePartial(board.cells, board.size) &&
        _checkUniquePartial(board.cells, board.size);
  }

  /// 모든 셀 채워졌고 4가지 규칙 모두 만족하는지
  static bool isComplete(BinairoBoard board) {
    if (!board.isComplete) return false;
    return _checkNoTriple(board.cells, board.size) &&
        _checkBalance(board.cells, board.size) &&
        _checkUnique(board.cells, board.size);
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 풀이 로직
  // ──────────────────────────────────────────────────────────────────

  /// 재귀 백트래킹 풀이
  static bool _solveRecursive(List<int> cells, int size) {
    final idx = _findEmptyCell(cells, size);
    if (idx == -1) return true; // 모든 셀 채워짐
    if (idx == -2) return false; // 데드엔드 (놓을 값 없는 빈칸 존재)

    // 0, 1 순서로 시도
    for (var value = 0; value <= 1; value++) {
      cells[idx] = value;
      if (_isValidPlacement(cells, size, idx)) {
        if (_solveRecursive(cells, size)) return true;
      }
      cells[idx] = -1;
    }
    return false;
  }

  /// 해답 개수 카운팅용 재귀
  static void _countRecursive(
    List<int> cells,
    int size,
    int limit,
    void Function(int) updateCount,
    int currentCount,
    Stopwatch? timeout,
    Duration? timeLimit,
  ) {
    if (currentCount >= limit) return;
    // 시간 초과 시 즉시 중단 (best-effort)
    if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
      return;
    }

    final idx = _findEmptyCell(cells, size);
    if (idx == -1) {
      // 해답 발견
      updateCount(currentCount + 1);
      return;
    }
    if (idx == -2) return; // 데드엔드

    for (var value = 0; value <= 1; value++) {
      if (currentCount >= limit) return;
      if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
        return;
      }
      cells[idx] = value;
      if (_isValidPlacement(cells, size, idx)) {
        _countRecursive(cells, size, limit, (newCount) {
          currentCount = newCount;
          updateCount(newCount);
        }, currentCount, timeout, timeLimit);
      }
      cells[idx] = -1;
    }
  }

  /// 가장 제약이 많은 빈 셀 찾기 (MRV 휴리스틱)
  static int _findEmptyCell(List<int> cells, int size) {
    int bestIdx = -1;
    int minOptions = 3; // 최대 옵션은 2 (0 또는 1)

    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != -1) continue;

      var options = 0;
      // 0을 놓을 수 있는지
      cells[i] = 0;
      if (_isValidPlacement(cells, size, i)) options++;
      // 1을 놓을 수 있는지
      cells[i] = 1;
      if (_isValidPlacement(cells, size, i)) options++;
      cells[i] = -1;

      if (options == 0) return -2; // 데드엔드 표시 (사실상 풀이 실패)
      if (options < minOptions) {
        minOptions = options;
        bestIdx = i;
        if (options == 1) return bestIdx; // 즉시 반환
      }
    }
    return bestIdx;
  }

  /// 특정 셀에 값을 놓았을 때 해당 행/열 규칙 위반 여부 (부분 검증)
  static bool _isValidPlacement(List<int> cells, int size, int idx) {
    final row = idx ~/ size;
    final col = idx % size;
    final value = cells[idx];
    final half = size ~/ 2;

    // 1) 3연속 검사 (해당 행)
    if (!_checkNoTripleInRow(cells, size, row)) return false;

    // 2) 3연속 검사 (해당 열)
    if (!_checkNoTripleInCol(cells, size, col)) return false;

    // 3) 행 균형 검사 (채워진 셀만)
    var rowCount = 0;
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == value) rowCount++;
    }
    if (rowCount > half) return false;

    // 4) 열 균형 검사 (채워진 셀만)
    var colCount = 0;
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == value) colCount++;
    }
    if (colCount > half) return false;

    return true;
  }

  /// 행에서 3연속 검사
  static bool _checkNoTripleInRow(List<int> cells, int size, int row) {
    for (var c = 0; c < size - 2; c++) {
      final a = cells[row * size + c];
      final b = cells[row * size + c + 1];
      final cVal = cells[row * size + c + 2];
      if (a != -1 && a == b && b == cVal) return false;
    }
    return true;
  }

  /// 열에서 3연속 검사
  static bool _checkNoTripleInCol(List<int> cells, int size, int col) {
    for (var r = 0; r < size - 2; r++) {
      final a = cells[r * size + col];
      final b = cells[(r + 1) * size + col];
      final cVal = cells[(r + 2) * size + col];
      if (a != -1 && a == b && b == cVal) return false;
    }
    return true;
  }

  // ──────────────────────────────────────────────────────────────────
  // 규칙 검증 (전체)
  // ──────────────────────────────────────────────────────────────────

  /// 가로/세로 3연속 검사 (빈칸은 무시)
  static bool _checkNoTriple(List<int> cells, int size) {
    // 행 검사
    for (var r = 0; r < size; r++) {
      if (!_checkNoTripleInRow(cells, size, r)) return false;
    }
    // 열 검사
    for (var c = 0; c < size; c++) {
      if (!_checkNoTripleInCol(cells, size, c)) return false;
    }
    return true;
  }

  /// 행/열별 0, 1 개수 균등 검사 (완전히 채워진 보드용)
  static bool _checkBalance(List<int> cells, int size) {
    final half = size ~/ 2;
    // 행별 검사
    for (var r = 0; r < size; r++) {
      var zeros = 0;
      var ones = 0;
      for (var c = 0; c < size; c++) {
        final v = cells[r * size + c];
        if (v == 0) zeros++;
        if (v == 1) ones++;
      }
      if (zeros != half || ones != half) return false;
    }
    // 열별 검사
    for (var c = 0; c < size; c++) {
      var zeros = 0;
      var ones = 0;
      for (var r = 0; r < size; r++) {
        final v = cells[r * size + c];
        if (v == 0) zeros++;
        if (v == 1) ones++;
      }
      if (zeros != half || ones != half) return false;
    }
    return true;
  }

  /// 행/열별 0, 1 개수 부분 검사 (빈칸 허용 — 초과만 검증)
  static bool _checkBalancePartial(List<int> cells, int size) {
    final half = size ~/ 2;
    // 행별 검사
    for (var r = 0; r < size; r++) {
      var zeros = 0;
      var ones = 0;
      for (var c = 0; c < size; c++) {
        final v = cells[r * size + c];
        if (v == 0) zeros++;
        if (v == 1) ones++;
      }
      if (zeros > half || ones > half) return false;
    }
    // 열별 검사
    for (var c = 0; c < size; c++) {
      var zeros = 0;
      var ones = 0;
      for (var r = 0; r < size; r++) {
        final v = cells[r * size + c];
        if (v == 0) zeros++;
        if (v == 1) ones++;
      }
      if (zeros > half || ones > half) return false;
    }
    return true;
  }

  /// 동일 행/열 없는지 검사 (완전히 채워진 보드용)
  static bool _checkUnique(List<int> cells, int size) {
    // 행 중복 검사
    for (var r1 = 0; r1 < size; r1++) {
      for (var r2 = r1 + 1; r2 < size; r2++) {
        var same = true;
        for (var c = 0; c < size; c++) {
          if (cells[r1 * size + c] != cells[r2 * size + c]) {
            same = false;
            break;
          }
        }
        if (same) return false;
      }
    }
    // 열 중복 검사
    for (var c1 = 0; c1 < size; c1++) {
      for (var c2 = c1 + 1; c2 < size; c2++) {
        var same = true;
        for (var r = 0; r < size; r++) {
          if (cells[r * size + c1] != cells[r * size + c2]) {
            same = false;
            break;
          }
        }
        if (same) return false;
      }
    }
    return true;
  }

  /// 동일 행/열 부분 검사 (완전히 채워진 행/열만 비교)
  static bool _checkUniquePartial(List<int> cells, int size) {
    // 완전히 채워진 행만 비교
    final completeRows = <int>[];
    for (var r = 0; r < size; r++) {
      var isFull = true;
      for (var c = 0; c < size; c++) {
        if (cells[r * size + c] == -1) {
          isFull = false;
          break;
        }
      }
      if (isFull) completeRows.add(r);
    }
    for (var i = 0; i < completeRows.length; i++) {
      for (var j = i + 1; j < completeRows.length; j++) {
        var same = true;
        for (var c = 0; c < size; c++) {
          if (cells[completeRows[i] * size + c] != cells[completeRows[j] * size + c]) {
            same = false;
            break;
          }
        }
        if (same) return false;
      }
    }

    // 완전히 채워진 열만 비교
    final completeCols = <int>[];
    for (var c = 0; c < size; c++) {
      var isFull = true;
      for (var r = 0; r < size; r++) {
        if (cells[r * size + c] == -1) {
          isFull = false;
          break;
        }
      }
      if (isFull) completeCols.add(c);
    }
    for (var i = 0; i < completeCols.length; i++) {
      for (var j = i + 1; j < completeCols.length; j++) {
        var same = true;
        for (var r = 0; r < size; r++) {
          if (cells[r * size + completeCols[i]] != cells[r * size + completeCols[j]]) {
            same = false;
            break;
          }
        }
        if (same) return false;
      }
    }
    return true;
  }
}
