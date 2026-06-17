import 'light_up_board.dart';

/// Light Up 솔버 — 유효성 검증 + 백트래킹 풀이
class LightUpSolver {
  /// 퍼즐 풀이 (해답 반환, 풀 수 없으면 null)
  static LightUpBoard? solve(LightUpBoard board) {
    final cells = List<int>.from(board.cells);
    if (_solveRecursive(cells, board.size, board.fixed)) {
      return LightUpBoard(size: board.size, cells: cells, fixed: board.fixed);
    }
    return null;
  }

  /// 해가 정확히 1개인지 검증
  static bool hasUniqueSolution(LightUpBoard board) {
    return countSolutions(board, limit: 2) == 1;
  }

  /// 해답 개수 카운트 (limit 도달 시 조기 종료)
  static int countSolutions(LightUpBoard board, {int limit = 2}) {
    final cells = List<int>.from(board.cells);
    var count = 0;
    _countRecursive(cells, board.size, board.fixed, limit,
        (c) => count = c, count);
    return count;
  }

  /// 현재 보드가 완성 상태인지 (모든 흰 칸 비춤 + 규칙 만족)
  static bool isComplete(LightUpBoard board) {
    return _isCompleteRaw(board.cells, board.size, board.fixed);
  }

  /// 현재 상태에서 규칙 위반이 없는지 (부분 검증 — 빈칸 허용)
  static bool isValid(LightUpBoard board) {
    final size = board.size;
    final cells = board.cells;

    // 전구 충돌 검사
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (cells[r * size + c] == LightUpBoard.bulb &&
            _hasBulbConflictRaw(cells, size, r, c)) return false;
      }
    }

    // 벽 숫자 제약 (초과만 검사)
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final num = _getWallNumberRaw(cells, size, r, c);
        if (num < 0) continue;
        final adjBulbs = _adjacentBulbCountRaw(cells, size, r, c);
        if (adjBulbs > num) return false;

        var adjEmpty = 0;
        for (final (dr, dc) in _dirs) {
          final nr = r + dr;
          final nc = c + dc;
          if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
          if (cells[nr * size + nc] == LightUpBoard.empty) adjEmpty++;
        }
        if (adjBulbs + adjEmpty < num) return false;
      }
    }

    return true;
  }

  // ──────────────────────────────────────────────────────────────────
  // 원시 배열 기반 유틸리티 (성능 최적화)
  // ──────────────────────────────────────────────────────────────────

  static const _dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

  /// 벽인지 확인
  static bool _isWallRaw(List<int> cells, int size, int r, int c) {
    final v = cells[r * size + c];
    return v == LightUpBoard.wallBlank || (v >= 0 && v <= 4);
  }

  /// 벽 숫자 (-1이면 숫자 없음)
  static int _getWallNumberRaw(List<int> cells, int size, int r, int c) {
    final v = cells[r * size + c];
    if (v >= 0 && v <= 4) return v;
    return -1;
  }

  /// 전구 충돌 검사 (원시 배열)
  static bool _hasBulbConflictRaw(List<int> cells, int size, int row, int col) {
    for (final (dr, dc) in _dirs) {
      var nr = row + dr;
      var nc = col + dc;
      while (nr >= 0 && nr < size && nc >= 0 && nc < size) {
        if (_isWallRaw(cells, size, nr, nc)) break;
        if (cells[nr * size + nc] == LightUpBoard.bulb) return true;
        nr += dr;
        nc += dc;
      }
    }
    return false;
  }

  /// 인접 전구 수 (원시 배열)
  static int _adjacentBulbCountRaw(List<int> cells, int size, int row, int col) {
    var count = 0;
    for (final (dr, dc) in _dirs) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
      if (cells[nr * size + nc] == LightUpBoard.bulb) count++;
    }
    return count;
  }

  /// 특정 셀이 비춰지는지 (원시 배열)
  static bool _isLitRaw(List<int> cells, int size, int row, int col) {
    if (cells[row * size + col] == LightUpBoard.bulb) return true;
    for (final (dr, dc) in _dirs) {
      var nr = row + dr;
      var nc = col + dc;
      while (nr >= 0 && nr < size && nc >= 0 && nc < size) {
        if (_isWallRaw(cells, size, nr, nc)) break;
        if (cells[nr * size + nc] == LightUpBoard.bulb) return true;
        nr += dr;
        nc += dc;
      }
    }
    return false;
  }

  /// 완성 검사 (원시 배열)
  static bool _isCompleteRaw(List<int> cells, int size, Set<int> fixed) {
    // 1. 전구 충돌 검사
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (cells[r * size + c] == LightUpBoard.bulb &&
            _hasBulbConflictRaw(cells, size, r, c)) return false;
      }
    }

    // 2. 벽 숫자 제약 검사
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final num = _getWallNumberRaw(cells, size, r, c);
        if (num < 0) continue;
        if (_adjacentBulbCountRaw(cells, size, r, c) != num) return false;
      }
    }

    // 3. 모든 흰 칸이 비춰지는지
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final v = cells[r * size + c];
        // 흰 칸 (empty, bulb, cross)
        if (v == LightUpBoard.empty || v == LightUpBoard.bulb || v == LightUpBoard.cross) {
          if (!_isLitRaw(cells, size, r, c)) return false;
        }
      }
    }

    return true;
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 풀이 로직
  // ──────────────────────────────────────────────────────────────────

  /// 재귀 백트래킹 풀이
  static bool _solveRecursive(List<int> cells, int size, Set<int> fixed) {
    final idx = _findBestCell(cells, size, fixed);
    if (idx == -1) {
      return _isCompleteRaw(cells, size, fixed);
    }

    // 전구 배치 시도
    cells[idx] = LightUpBoard.bulb;
    if (_isValidPartialRaw(cells, size, idx)) {
      if (_solveRecursive(cells, size, fixed)) return true;
    }

    // 전구 미배치
    cells[idx] = LightUpBoard.empty;
    if (_solveRecursive(cells, size, fixed)) return true;

    cells[idx] = LightUpBoard.empty;
    return false;
  }

  /// 해답 개수 카운팅
  static void _countRecursive(
    List<int> cells,
    int size,
    Set<int> fixed,
    int limit,
    void Function(int) updateCount,
    int currentCount,
  ) {
    if (currentCount >= limit) return;

    final idx = _findBestCell(cells, size, fixed);
    if (idx == -1) {
      if (_isCompleteRaw(cells, size, fixed)) {
        updateCount(currentCount + 1);
      }
      return;
    }

    // 전구 배치
    cells[idx] = LightUpBoard.bulb;
    if (_isValidPartialRaw(cells, size, idx)) {
      _countRecursive(cells, size, fixed, limit, (c) {
        currentCount = c;
        updateCount(c);
      }, currentCount);
    }

    if (currentCount >= limit) {
      cells[idx] = LightUpBoard.empty;
      return;
    }

    // 빈칸으로 유지
    cells[idx] = LightUpBoard.empty;
    _countRecursive(cells, size, fixed, limit, (c) {
      currentCount = c;
      updateCount(c);
    }, currentCount);

    cells[idx] = LightUpBoard.empty;
  }

  /// 가장 제약이 많은 빈 흰 칸 찾기
  static int _findBestCell(List<int> cells, int size, Set<int> fixed) {
    for (var i = 0; i < cells.length; i++) {
      if (fixed.contains(i)) continue;
      if (cells[i] != LightUpBoard.empty) continue;
      return i;
    }
    return -1;
  }

  /// 부분 유효성 검사 (원시 배열 — Board 객체 생성 없음)
  static bool _isValidPartialRaw(List<int> cells, int size, int idx) {
    final row = idx ~/ size;
    final col = idx % size;

    // 전구 충돌 검사
    if (cells[idx] == LightUpBoard.bulb &&
        _hasBulbConflictRaw(cells, size, row, col)) {
      return false;
    }

    // 인접 벽 숫자 제약 확인
    for (final (dr, dc) in _dirs) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
      final num = _getWallNumberRaw(cells, size, nr, nc);
      if (num < 0) continue;

      final adjBulbs = _adjacentBulbCountRaw(cells, size, nr, nc);
      if (adjBulbs > num) return false;

      var adjEmpty = 0;
      for (final (dr2, dc2) in _dirs) {
        final nr2 = nr + dr2;
        final nc2 = nc + dc2;
        if (nr2 < 0 || nr2 >= size || nc2 < 0 || nc2 >= size) continue;
        if (cells[nr2 * size + nc2] == LightUpBoard.empty) adjEmpty++;
      }
      if (adjBulbs + adjEmpty < num) return false;
    }

    return true;
  }
}
