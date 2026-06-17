import 'tents_board.dart';

/// Tents 솔버
/// 백트래킹 기반 풀이, 규칙 검증 포함
class TentsSolver {
  /// 퍼즐을 풀고 해답 보드 반환 (풀 수 없으면 null)
  static TentsBoard? solve(TentsBoard board) {
    final cells = List<int>.from(board.cells);
    if (_solveRecursive(cells, board)) {
      return TentsBoard(
        size: board.size,
        cells: cells,
        rowCounts: board.rowCounts,
        colCounts: board.colCounts,
        treePositions: board.treePositions,
      );
    }
    return null;
  }

  /// 해가 정확히 1개인지 검증
  static bool hasUniqueSolution(TentsBoard board) {
    return countSolutions(board, limit: 2) == 1;
  }

  /// 해답 개수 카운트 (limit에 도달하면 조기 종료)
  static int countSolutions(TentsBoard board, {int limit = 2}) {
    final cells = List<int>.from(board.cells);
    var count = 0;
    _countRecursive(cells, board, limit, (c) => count = c, count);
    return count;
  }

  /// 현재 상태에서 규칙 위반 없는지 확인 (부분 검증)
  static bool isValid(TentsBoard board) {
    return _checkNoAdjacentTents(board) &&
        _checkRowColCountsPartial(board) &&
        _checkTreeMatchingPartial(board);
  }

  /// 모든 규칙을 만족하고 완료 상태인지
  static bool isComplete(TentsBoard board) {
    // 모든 비나무 셀이 텐트 또는 잔디여야 함
    for (var i = 0; i < board.cells.length; i++) {
      if (!board.treePositions.contains(i) &&
          board.cells[i] != TentsBoard.tent &&
          board.cells[i] != TentsBoard.grass) {
        return false;
      }
    }
    return _checkNoAdjacentTents(board) &&
        _checkRowColCountsExact(board) &&
        _checkTreeMatchingComplete(board);
  }

  // ----------------------------------------------------------------
  // 내부 풀이 로직
  // ----------------------------------------------------------------

  /// 재귀 백트래킹 풀이
  static bool _solveRecursive(List<int> cells, TentsBoard board) {
    final idx = _findNextEmpty(cells, board);
    if (idx == -1) {
      // 모든 셀 채워짐 — 완료 검증
      final testBoard = TentsBoard(
        size: board.size,
        cells: cells,
        rowCounts: board.rowCounts,
        colCounts: board.colCounts,
        treePositions: board.treePositions,
      );
      return isComplete(testBoard);
    }

    // 텐트 또는 잔디 시도
    for (final value in [TentsBoard.tent, TentsBoard.grass]) {
      cells[idx] = value;
      final testBoard = TentsBoard(
        size: board.size,
        cells: cells,
        rowCounts: board.rowCounts,
        colCounts: board.colCounts,
        treePositions: board.treePositions,
      );
      if (_isValidPlacement(testBoard, idx)) {
        if (_solveRecursive(cells, board)) return true;
      }
      cells[idx] = TentsBoard.empty;
    }
    return false;
  }

  /// 해답 카운팅용 재귀
  static void _countRecursive(
    List<int> cells,
    TentsBoard board,
    int limit,
    void Function(int) updateCount,
    int currentCount,
  ) {
    if (currentCount >= limit) return;

    final idx = _findNextEmpty(cells, board);
    if (idx == -1) {
      final testBoard = TentsBoard(
        size: board.size,
        cells: cells,
        rowCounts: board.rowCounts,
        colCounts: board.colCounts,
        treePositions: board.treePositions,
      );
      if (isComplete(testBoard)) {
        updateCount(currentCount + 1);
      }
      return;
    }

    for (final value in [TentsBoard.tent, TentsBoard.grass]) {
      if (currentCount >= limit) return;
      cells[idx] = value;
      final testBoard = TentsBoard(
        size: board.size,
        cells: cells,
        rowCounts: board.rowCounts,
        colCounts: board.colCounts,
        treePositions: board.treePositions,
      );
      if (_isValidPlacement(testBoard, idx)) {
        _countRecursive(cells, board, limit, (c) {
          currentCount = c;
          updateCount(c);
        }, currentCount);
      }
      cells[idx] = TentsBoard.empty;
    }
  }

  /// 다음 빈 셀 (나무 제외)
  static int _findNextEmpty(List<int> cells, TentsBoard board) {
    for (var i = 0; i < cells.length; i++) {
      if (!board.treePositions.contains(i) && cells[i] == TentsBoard.empty) {
        return i;
      }
    }
    return -1;
  }

  /// 특정 셀 배치 유효성 (부분 검증)
  static bool _isValidPlacement(TentsBoard board, int idx) {
    final row = idx ~/ board.size;
    final col = idx % board.size;
    final value = board.cells[idx];

    if (value == TentsBoard.tent) {
      // 1) 텐트끼리 8방향 인접 불가
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = row + dr;
          final nc = col + dc;
          if (nr < 0 || nr >= board.size || nc < 0 || nc >= board.size) {
            continue;
          }
          if (board.cells[nr * board.size + nc] == TentsBoard.tent) {
            return false;
          }
        }
      }

      // 2) 행/열 텐트 수 초과 불가
      if (board.currentRowTents(row) > board.rowCounts[row]) return false;
      if (board.currentColTents(col) > board.colCounts[col]) return false;

      // 3) 텐트는 나무 옆(상하좌우)에만 배치 가능
      if (!_hasAdjacentTree(board, row, col)) return false;
    }

    // 4) 행의 남은 빈칸으로 행 힌트를 달성 가능한지 확인
    final rowTents = board.currentRowTents(row);
    var rowEmpty = 0;
    for (var c = 0; c < board.size; c++) {
      final ci = row * board.size + c;
      if (!board.treePositions.contains(ci) &&
          board.cells[ci] == TentsBoard.empty) {
        rowEmpty++;
      }
    }
    if (rowTents + rowEmpty < board.rowCounts[row]) return false;

    // 5) 열의 남은 빈칸으로 열 힌트를 달성 가능한지 확인
    final colTents = board.currentColTents(col);
    var colEmpty = 0;
    for (var r = 0; r < board.size; r++) {
      final ci = r * board.size + col;
      if (!board.treePositions.contains(ci) &&
          board.cells[ci] == TentsBoard.empty) {
        colEmpty++;
      }
    }
    if (colTents + colEmpty < board.colCounts[col]) return false;

    return true;
  }

  /// 인접(상하좌우) 나무 존재 여부
  static bool _hasAdjacentTree(TentsBoard board, int row, int col) {
    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    for (final (dr, dc) in dirs) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr >= 0 && nr < board.size && nc >= 0 && nc < board.size) {
        if (board.cells[nr * board.size + nc] == TentsBoard.tree) return true;
      }
    }
    return false;
  }

  // ----------------------------------------------------------------
  // 규칙 검증
  // ----------------------------------------------------------------

  /// 텐트끼리 8방향 인접 불가
  static bool _checkNoAdjacentTents(TentsBoard board) {
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        if (board.cells[r * board.size + c] != TentsBoard.tent) continue;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final nr = r + dr;
            final nc = c + dc;
            if (nr < 0 || nr >= board.size || nc < 0 || nc >= board.size) {
              continue;
            }
            if (board.cells[nr * board.size + nc] == TentsBoard.tent) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  /// 행/열 텐트 수 부분 검증 (초과만 확인)
  static bool _checkRowColCountsPartial(TentsBoard board) {
    for (var r = 0; r < board.size; r++) {
      if (board.currentRowTents(r) > board.rowCounts[r]) return false;
    }
    for (var c = 0; c < board.size; c++) {
      if (board.currentColTents(c) > board.colCounts[c]) return false;
    }
    return true;
  }

  /// 행/열 텐트 수 정확히 일치 검증
  static bool _checkRowColCountsExact(TentsBoard board) {
    for (var r = 0; r < board.size; r++) {
      if (board.currentRowTents(r) != board.rowCounts[r]) return false;
    }
    for (var c = 0; c < board.size; c++) {
      if (board.currentColTents(c) != board.colCounts[c]) return false;
    }
    return true;
  }

  /// 나무-텐트 1:1 매칭 부분 검증
  static bool _checkTreeMatchingPartial(TentsBoard board) {
    // 각 텐트가 인접 나무를 갖는지만 확인 (부분)
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        if (board.cells[r * board.size + c] == TentsBoard.tent) {
          if (!_hasAdjacentTree(board, r, c)) return false;
        }
      }
    }
    return true;
  }

  /// 나무-텐트 1:1 완전 매칭 검증
  static bool _checkTreeMatchingComplete(TentsBoard board) {
    // 이분 매칭으로 1:1 대응 확인
    final treeIndices = board.treePositions.toList()..sort();
    final tentIndices = <int>[];
    for (var i = 0; i < board.cells.length; i++) {
      if (board.cells[i] == TentsBoard.tent) tentIndices.add(i);
    }

    // 나무와 텐트 수가 같아야 함
    if (treeIndices.length != tentIndices.length) return false;

    // 이분 매칭 (Hungarian 대신 간단한 DFS 기반)
    final n = treeIndices.length;
    if (n == 0) return true;

    // 나무 인덱스 → 인접 텐트 인덱스 매핑
    final adj = <int, List<int>>{};
    for (var ti = 0; ti < n; ti++) {
      adj[ti] = [];
      final treeIdx = treeIndices[ti];
      final treeRow = treeIdx ~/ board.size;
      final treeCol = treeIdx % board.size;
      for (var ai = 0; ai < tentIndices.length; ai++) {
        final tentIdx = tentIndices[ai];
        final tentRow = tentIdx ~/ board.size;
        final tentCol = tentIdx % board.size;
        // 상하좌우 인접
        if ((treeRow == tentRow && (treeCol - tentCol).abs() == 1) ||
            (treeCol == tentCol && (treeRow - tentRow).abs() == 1)) {
          adj[ti]!.add(ai);
        }
      }
    }

    // DFS 기반 이분 매칭
    final match = List<int>.filled(tentIndices.length, -1);
    var matched = 0;
    for (var ti = 0; ti < n; ti++) {
      final visited = List<bool>.filled(tentIndices.length, false);
      if (_dfsMatch(ti, adj, match, visited)) matched++;
    }
    return matched == n;
  }

  /// DFS 기반 이분 매칭 헬퍼
  static bool _dfsMatch(
    int treeIdx,
    Map<int, List<int>> adj,
    List<int> match,
    List<bool> visited,
  ) {
    for (final tentIdx in adj[treeIdx]!) {
      if (visited[tentIdx]) continue;
      visited[tentIdx] = true;
      if (match[tentIdx] == -1 ||
          _dfsMatch(match[tentIdx], adj, match, visited)) {
        match[tentIdx] = treeIdx;
        return true;
      }
    }
    return false;
  }

  /// 텐트끼리 인접한 셀 쌍 반환 (위반 표시용)
  static Set<int> getAdjacentTentViolations(TentsBoard board) {
    final violations = <int>{};
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        final idx = r * board.size + c;
        if (board.cells[idx] != TentsBoard.tent) continue;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final nr = r + dr;
            final nc = c + dc;
            if (nr < 0 || nr >= board.size || nc < 0 || nc >= board.size) {
              continue;
            }
            if (board.cells[nr * board.size + nc] == TentsBoard.tent) {
              violations.add(idx);
              violations.add(nr * board.size + nc);
            }
          }
        }
      }
    }
    return violations;
  }
}
