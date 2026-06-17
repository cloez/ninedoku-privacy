/// 음양 솔버 — 연결성(BFS) + 2×2 금지 규칙 검증
library;

import 'dart:collection';
import 'yin_yang_board.dart';

class YinYangSolver {
  /// 보드가 유효한지 검증 (부분 채움 상태에서도)
  static bool isValid(YinYangBoard board) {
    return !_has2x2Block(board) && _isConnectedPartial(board);
  }

  /// 보드가 완성되고 규칙을 충족하는지
  static bool isComplete(YinYangBoard board) {
    if (!board.isComplete) return false;
    if (_has2x2Block(board)) return false;
    if (!_isConnected(board, 0)) return false;
    if (!_isConnected(board, 1)) return false;
    return true;
  }

  /// 2×2 같은 색 블록 존재 여부
  static bool _has2x2Block(YinYangBoard board) {
    for (int r = 0; r < board.size - 1; r++) {
      for (int c = 0; c < board.size - 1; c++) {
        final v = board.getValue(r, c);
        if (v == -1) continue;
        if (v == board.getValue(r, c + 1) &&
            v == board.getValue(r + 1, c) &&
            v == board.getValue(r + 1, c + 1)) {
          return true;
        }
      }
    }
    return false;
  }

  /// 특정 색의 셀이 모두 연결되어 있는지 (BFS)
  static bool _isConnected(YinYangBoard board, int color) {
    // 첫 번째 해당 색 셀 찾기
    int startIdx = -1;
    int totalCount = 0;
    for (int i = 0; i < board.cells.length; i++) {
      if (board.cells[i] == color) {
        totalCount++;
        if (startIdx == -1) startIdx = i;
      }
    }
    if (totalCount == 0) return true;

    // BFS
    final visited = <int>{startIdx};
    final queue = Queue<int>()..add(startIdx);

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      final row = idx ~/ board.size;
      final col = idx % board.size;

      for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= board.size || nc < 0 || nc >= board.size) continue;
        final nIdx = nr * board.size + nc;
        if (visited.contains(nIdx)) continue;
        if (board.cells[nIdx] == color) {
          visited.add(nIdx);
          queue.add(nIdx);
        }
      }
    }

    return visited.length == totalCount;
  }

  /// 부분 채움 상태에서 연결 가능성 검증 (빈칸을 다리로 허용)
  static bool _isConnectedPartial(YinYangBoard board) {
    for (final color in [0, 1]) {
      if (!_isConnectedWithEmpty(board, color)) return false;
    }
    return true;
  }

  /// 빈 칸을 통해서도 연결 가능한지 검증
  static bool _isConnectedWithEmpty(YinYangBoard board, int color) {
    int startIdx = -1;
    int totalCount = 0;
    for (int i = 0; i < board.cells.length; i++) {
      if (board.cells[i] == color) {
        totalCount++;
        if (startIdx == -1) startIdx = i;
      }
    }
    if (totalCount <= 1) return true;

    // BFS — 해당 색 또는 빈칸을 통해 이동 가능
    final visited = <int>{startIdx};
    final colorReached = <int>{startIdx};
    final queue = Queue<int>()..add(startIdx);

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      final row = idx ~/ board.size;
      final col = idx % board.size;

      for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= board.size || nc < 0 || nc >= board.size) continue;
        final nIdx = nr * board.size + nc;
        if (visited.contains(nIdx)) continue;
        final val = board.cells[nIdx];
        if (val == color || val == -1) {
          visited.add(nIdx);
          if (val == color) colorReached.add(nIdx);
          queue.add(nIdx);
        }
      }
    }

    return colorReached.length == totalCount;
  }

  /// 풀이 (백트래킹)
  /// [timeout]/[timeLimit] 지정 시 시간 초과되면 즉시 중단하고 null 반환 (best-effort)
  static YinYangBoard? solve(
    YinYangBoard board, {
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    final copy = board.copyWith();
    final result = _solveRecursive(copy, timeout, timeLimit);
    return result;
  }

  static YinYangBoard? _solveRecursive(
    YinYangBoard board,
    Stopwatch? timeout,
    Duration? timeLimit,
  ) {
    // 시간 초과 시 즉시 중단 (best-effort)
    if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
      return null;
    }

    // 첫 번째 빈 셀 찾기
    int emptyIdx = -1;
    for (int i = 0; i < board.cells.length; i++) {
      if (board.cells[i] == -1) {
        emptyIdx = i;
        break;
      }
    }

    if (emptyIdx == -1) {
      return isComplete(board) ? board : null;
    }

    final row = emptyIdx ~/ board.size;
    final col = emptyIdx % board.size;

    for (final value in [0, 1]) {
      if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
        return null;
      }
      final newBoard = board.setValue(row, col, value);
      // 조기 가지치기: 2×2 체크, 연결 가능성 체크
      if (!_has2x2Block(newBoard) &&
          _isConnectedWithEmpty(newBoard, 0) &&
          _isConnectedWithEmpty(newBoard, 1)) {
        final result = _solveRecursive(newBoard, timeout, timeLimit);
        if (result != null) return result;
      }
    }

    return null;
  }

  /// 유일해 검증
  static bool hasUniqueSolution(YinYangBoard board) {
    return countSolutions(board, maxCount: 2) == 1;
  }

  /// 해답 개수 카운트 (백트래킹 + 조기 가지치기)
  /// [maxCount]에 도달하면 즉시 중단.
  /// [timeout]/[timeLimit] 지정 시, 시간 초과되면 즉시 중단하고
  /// 현재까지 카운트된 값을 반환한다 (best-effort).
  static int countSolutions(
    YinYangBoard board, {
    int maxCount = 2,
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    // 카운터를 캡처 가능한 객체로 관리 (closure 누적 결함 회피)
    final counter = _CountState();

    void recurse(YinYangBoard b) {
      if (counter.value >= maxCount) return;
      // 시간 한도 초과 시 즉시 중단 (best-effort)
      if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
        return;
      }

      // 첫 빈 셀 찾기
      int emptyIdx = -1;
      for (int i = 0; i < b.cells.length; i++) {
        if (b.cells[i] == -1) {
          emptyIdx = i;
          break;
        }
      }

      if (emptyIdx == -1) {
        if (isComplete(b)) counter.value++;
        return;
      }

      final r = emptyIdx ~/ b.size;
      final c = emptyIdx % b.size;
      for (final value in [0, 1]) {
        if (counter.value >= maxCount) return;
        if (timeout != null &&
            timeLimit != null &&
            timeout.elapsed > timeLimit) {
          return;
        }
        final next = b.setValue(r, c, value);
        // 조기 가지치기
        if (!_has2x2Block(next) &&
            _isConnectedWithEmpty(next, 0) &&
            _isConnectedWithEmpty(next, 1)) {
          recurse(next);
        }
      }
    }

    recurse(board);
    return counter.value;
  }
}

/// 카운터 캡처용 변경 가능 상태 (closure 누적 결함 회피)
class _CountState {
  int value = 0;
}
