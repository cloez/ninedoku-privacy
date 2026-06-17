import 'star_battle_board.dart';

/// Star Battle 솔버
/// 행/열/영역별 별 수 검증 + 인접 금지(8방향) 검증, 백트래킹 풀이
class StarBattleSolver {
  /// 8방향 오프셋 (상, 하, 좌, 우, 대각선 4)
  static const directions = [
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1),           (0, 1),
    (1, -1),  (1, 0),  (1, 1),
  ];

  /// 퍼즐을 풀고 해답 보드 반환 (풀 수 없으면 null)
  static StarBattleBoard? solve(StarBattleBoard board) {
    final cells = List<int>.from(board.cells);
    if (_solveRecursive(cells, board.size, board.regions, board.starCount, 0)) {
      // 빈칸을 X로 채움
      for (var i = 0; i < cells.length; i++) {
        if (cells[i] == -1) cells[i] = 0;
      }
      return StarBattleBoard(
        size: board.size,
        cells: cells,
        regions: board.regions,
        starCount: board.starCount,
        fixed: board.fixed,
      );
    }
    return null;
  }

  /// 해가 정확히 1개인지 검증
  static bool hasUniqueSolution(StarBattleBoard board) {
    return countSolutions(board, limit: 2) == 1;
  }

  /// 해답 개수 카운트 (limit에 도달하면 조기 종료)
  static int countSolutions(StarBattleBoard board, {int limit = 2}) {
    final cells = List<int>.from(board.cells);
    var count = 0;
    _countRecursive(
      cells, board.size, board.regions, board.starCount, 0, limit,
      () => count++, () => count,
    );
    return count;
  }

  /// 현재 상태가 규칙 위반 없는지 확인 (부분 검증 — 빈칸 허용)
  static bool isValid(StarBattleBoard board) {
    return _checkPartialValidity(board.cells, board.size, board.regions, board.starCount);
  }

  /// 모든 별이 올바르게 배치됐는지 (완료 판정)
  static bool isComplete(StarBattleBoard board) {
    final size = board.size;
    final starCount = board.starCount;
    final cells = board.cells;
    final regions = board.regions;

    // 총 별 수 확인
    final totalStars = cells.where((v) => v == 1).length;
    if (totalStars != size * starCount) return false;

    // 행별 별 수 확인
    for (var r = 0; r < size; r++) {
      var count = 0;
      for (var c = 0; c < size; c++) {
        if (cells[r * size + c] == 1) count++;
      }
      if (count != starCount) return false;
    }

    // 열별 별 수 확인
    for (var c = 0; c < size; c++) {
      var count = 0;
      for (var r = 0; r < size; r++) {
        if (cells[r * size + c] == 1) count++;
      }
      if (count != starCount) return false;
    }

    // 영역별 별 수 확인
    final regionCounts = List<int>.filled(size, 0);
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == 1) regionCounts[regions[i]]++;
    }
    for (var count in regionCounts) {
      if (count != starCount) return false;
    }

    // 인접 금지 확인
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (cells[r * size + c] != 1) continue;
        for (final (dr, dc) in directions) {
          final nr = r + dr;
          final nc = c + dc;
          if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
          if (cells[nr * size + nc] == 1) return false;
        }
      }
    }

    return true;
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 풀이 로직
  // ──────────────────────────────────────────────────────────────────

  /// 재귀 백트래킹 풀이 — 셀 단위로 ★ 또는 스킵
  static bool _solveRecursive(
    List<int> cells, int size, List<int> regions, int starCount, int idx,
  ) {
    // 다음 빈 셀 찾기
    while (idx < cells.length && cells[idx] != -1) idx++;
    if (idx >= cells.length) {
      // 모든 셀 처리 완료 — 별 수 검증
      return _isSolutionComplete(cells, size, regions, starCount);
    }

    final row = idx ~/ size;
    final col = idx % size;

    // 별 배치 시도
    if (_canPlaceStar(cells, size, regions, starCount, row, col)) {
      cells[idx] = 1;
      if (_solveRecursive(cells, size, regions, starCount, idx + 1)) return true;
      cells[idx] = -1;
    }

    // 별 배치 안 함 (빈칸 유지 → 최종적으로 X)
    if (_canSkipCell(cells, size, regions, starCount, row, col)) {
      if (_solveRecursive(cells, size, regions, starCount, idx + 1)) return true;
    }

    return false;
  }

  /// 해답 개수 카운팅용 재귀
  static void _countRecursive(
    List<int> cells, int size, List<int> regions, int starCount,
    int idx, int limit,
    void Function() incrementCount,
    int Function() getCount,
  ) {
    if (getCount() >= limit) return;

    while (idx < cells.length && cells[idx] != -1) idx++;
    if (idx >= cells.length) {
      if (_isSolutionComplete(cells, size, regions, starCount)) {
        incrementCount();
      }
      return;
    }

    final row = idx ~/ size;
    final col = idx % size;

    // 별 배치 시도
    if (_canPlaceStar(cells, size, regions, starCount, row, col)) {
      cells[idx] = 1;
      _countRecursive(cells, size, regions, starCount, idx + 1, limit, incrementCount, getCount);
      cells[idx] = -1;
      if (getCount() >= limit) return;
    }

    // 스킵 시도
    if (_canSkipCell(cells, size, regions, starCount, row, col)) {
      _countRecursive(cells, size, regions, starCount, idx + 1, limit, incrementCount, getCount);
    }
  }

  /// 별 배치 가능 여부 (행/열/영역 상한 + 인접 금지)
  static bool _canPlaceStar(
    List<int> cells, int size, List<int> regions, int starCount,
    int row, int col,
  ) {
    // 행 별 수 상한 확인
    var rowStars = 0;
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == 1) rowStars++;
    }
    if (rowStars >= starCount) return false;

    // 열 별 수 상한 확인
    var colStars = 0;
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == 1) colStars++;
    }
    if (colStars >= starCount) return false;

    // 영역 별 수 상한 확인
    final region = regions[row * size + col];
    var regionStars = 0;
    for (var i = 0; i < cells.length; i++) {
      if (regions[i] == region && cells[i] == 1) regionStars++;
    }
    if (regionStars >= starCount) return false;

    // 8방향 인접 확인
    for (final (dr, dc) in directions) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
      if (cells[nr * size + nc] == 1) return false;
    }

    return true;
  }

  /// 셀 스킵 가능 여부 (남은 빈칸으로 행/열/영역 별 수 채울 수 있는지)
  static bool _canSkipCell(
    List<int> cells, int size, List<int> regions, int starCount,
    int row, int col,
  ) {
    // 이 셀 이후 해당 행의 남은 빈칸 수 확인
    var rowStars = 0;
    var rowRemaining = 0;
    for (var c = 0; c < size; c++) {
      final v = cells[row * size + c];
      if (v == 1) rowStars++;
      else if (v == -1 && c > col) rowRemaining++;
    }
    if (rowStars + rowRemaining < starCount) return false;

    // 이 셀 이후 해당 열의 남은 빈칸 수 확인
    var colStars = 0;
    var colRemaining = 0;
    for (var r = 0; r < size; r++) {
      final v = cells[r * size + col];
      if (v == 1) colStars++;
      else if (v == -1 && r * size + col > row * size + col) colRemaining++;
    }
    if (colStars + colRemaining < starCount) return false;

    // 이 셀 이후 해당 영역의 남은 빈칸 수 확인
    final region = regions[row * size + col];
    var regionStars = 0;
    var regionRemaining = 0;
    for (var i = 0; i < cells.length; i++) {
      if (regions[i] != region) continue;
      if (cells[i] == 1) regionStars++;
      else if (cells[i] == -1 && i > row * size + col) regionRemaining++;
    }
    if (regionStars + regionRemaining < starCount) return false;

    return true;
  }

  /// 솔루션 완료 검증 (모든 행/열/영역 별 수가 정확한지)
  static bool _isSolutionComplete(
    List<int> cells, int size, List<int> regions, int starCount,
  ) {
    // 행별 확인
    for (var r = 0; r < size; r++) {
      var count = 0;
      for (var c = 0; c < size; c++) {
        if (cells[r * size + c] == 1) count++;
      }
      if (count != starCount) return false;
    }
    // 열별 확인
    for (var c = 0; c < size; c++) {
      var count = 0;
      for (var r = 0; r < size; r++) {
        if (cells[r * size + c] == 1) count++;
      }
      if (count != starCount) return false;
    }
    // 영역별 확인
    final regionCounts = List<int>.filled(size, 0);
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == 1) regionCounts[regions[i]]++;
    }
    for (var count in regionCounts) {
      if (count != starCount) return false;
    }
    return true;
  }

  /// 부분 유효성 검사 (빈칸 허용)
  static bool _checkPartialValidity(
    List<int> cells, int size, List<int> regions, int starCount,
  ) {
    // 행/열/영역별 별 초과 확인
    for (var r = 0; r < size; r++) {
      var count = 0;
      for (var c = 0; c < size; c++) {
        if (cells[r * size + c] == 1) count++;
      }
      if (count > starCount) return false;
    }
    for (var c = 0; c < size; c++) {
      var count = 0;
      for (var r = 0; r < size; r++) {
        if (cells[r * size + c] == 1) count++;
      }
      if (count > starCount) return false;
    }
    final regionCounts = List<int>.filled(size, 0);
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == 1) regionCounts[regions[i]]++;
    }
    for (var count in regionCounts) {
      if (count > starCount) return false;
    }
    // 인접 확인
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (cells[r * size + c] != 1) continue;
        for (final (dr, dc) in directions) {
          final nr = r + dr;
          final nc = c + dc;
          if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
          if (cells[nr * size + nc] == 1) return false;
        }
      }
    }
    return true;
  }
}
