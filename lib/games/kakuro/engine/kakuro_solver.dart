import 'kakuro_board.dart';

/// 카쿠로 솔버
/// 블록 합계 + 블록 내 중복 불가 규칙 검증, 백트래킹 기반
class KakuroSolver {
  /// 퍼즐을 풀고 해답 보드 반환 (풀 수 없으면 null)
  static KakuroBoard? solve(KakuroBoard board) {
    final cells = List<KakuroCell>.from(board.cells);
    final blocks = board.blocks;
    if (_solveRecursive(cells, board, blocks)) {
      return board.copyWith(cells: cells);
    }
    return null;
  }

  /// 해가 정확히 1개인지 검증
  static bool hasUniqueSolution(
    KakuroBoard board, {
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
    KakuroBoard board, {
    int limit = 2,
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    final cells = List<KakuroCell>.from(board.cells);
    final blocks = board.blocks;
    var count = 0;
    _countRecursive(
      cells,
      board,
      blocks,
      limit,
      (n) => count = n,
      count,
      timeout,
      timeLimit,
    );
    return count;
  }

  /// 현재 상태에서 모든 규칙 만족하는지 (완성 보드)
  static bool isComplete(KakuroBoard board) {
    if (!board.isComplete) return false;
    return _checkAllBlocks(board);
  }

  /// 부분 검증 (빈칸 허용 — 현재까지 위반 없는지)
  static bool isValid(KakuroBoard board) {
    return _checkPartial(board);
  }

  /// 특정 셀이 속한 블록에서 중복이나 합계 위반이 있는지 (UI 에러 표시용)
  static bool hasBlockConflict(KakuroBoard board, int row, int col) {
    final value = board.getValue(row, col);
    if (value == 0) return false;

    final cellBlocks = board.blocksForCell(row, col);
    for (final block in cellBlocks) {
      // 중복 검사
      final values = <int>{};
      for (final (r, c) in block.cells) {
        final v = board.getValue(r, c);
        if (v != 0) {
          if (!values.add(v)) return true; // 중복 발견
        }
      }

      // 합계 검사 (모든 셀이 채워진 블록만)
      final allFilled = block.cells.every((pos) => board.getValue(pos.$1, pos.$2) != 0);
      if (allFilled) {
        var sum = 0;
        for (final (r, c) in block.cells) {
          sum += board.getValue(r, c);
        }
        if (sum != block.sum) return true;
      } else {
        // 부분 합계가 이미 목표를 초과하면 위반
        var partialSum = 0;
        for (final (r, c) in block.cells) {
          partialSum += board.getValue(r, c);
        }
        if (partialSum >= block.sum) return true;
      }
    }
    return false;
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 풀이 로직
  // ──────────────────────────────────────────────────────────────────

  /// 재귀 백트래킹 풀이
  static bool _solveRecursive(
    List<KakuroCell> cells,
    KakuroBoard board,
    List<KakuroBlock> blocks,
  ) {
    final idx = _findBestEmptyCell(cells, board, blocks);
    if (idx == -1) return true; // 모든 셀 채워짐
    if (idx == -2) return false; // 데드엔드

    final row = idx ~/ board.cols;
    final col = idx % board.cols;

    for (var v = 1; v <= 9; v++) {
      cells[idx] = KakuroCell.white(value: v);
      if (_isValidPlacement(cells, board, blocks, row, col)) {
        if (_solveRecursive(cells, board, blocks)) return true;
      }
      cells[idx] = const KakuroCell.white(value: 0);
    }
    return false;
  }

  /// 해답 개수 카운팅용 재귀
  static void _countRecursive(
    List<KakuroCell> cells,
    KakuroBoard board,
    List<KakuroBlock> blocks,
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

    final idx = _findBestEmptyCell(cells, board, blocks);
    if (idx == -1) {
      updateCount(currentCount + 1);
      return;
    }
    if (idx == -2) return;

    final row = idx ~/ board.cols;
    final col = idx % board.cols;

    for (var v = 1; v <= 9; v++) {
      if (currentCount >= limit) return;
      if (timeout != null && timeLimit != null && timeout.elapsed > timeLimit) {
        return;
      }
      cells[idx] = KakuroCell.white(value: v);
      if (_isValidPlacement(cells, board, blocks, row, col)) {
        _countRecursive(cells, board, blocks, limit, (n) {
          currentCount = n;
          updateCount(n);
        }, currentCount, timeout, timeLimit);
      }
      cells[idx] = const KakuroCell.white(value: 0);
    }
  }

  /// MRV 휴리스틱: 가능한 값이 가장 적은 빈 흰 셀 찾기
  static int _findBestEmptyCell(
    List<KakuroCell> cells,
    KakuroBoard board,
    List<KakuroBlock> blocks,
  ) {
    int bestIdx = -1;
    int minOptions = 10;

    for (var i = 0; i < cells.length; i++) {
      if (cells[i].type != KakuroCellType.white || cells[i].value != 0) continue;

      final row = i ~/ board.cols;
      final col = i % board.cols;
      var options = 0;
      for (var v = 1; v <= 9; v++) {
        cells[i] = KakuroCell.white(value: v);
        if (_isValidPlacement(cells, board, blocks, row, col)) options++;
        cells[i] = const KakuroCell.white(value: 0);
      }

      if (options == 0) return -2; // 데드엔드
      if (options < minOptions) {
        minOptions = options;
        bestIdx = i;
        if (options == 1) return bestIdx;
      }
    }
    return bestIdx;
  }

  /// 특정 셀에 값을 놓았을 때 유효성 검사
  static bool _isValidPlacement(
    List<KakuroCell> cells,
    KakuroBoard board,
    List<KakuroBlock> blocks,
    int row,
    int col,
  ) {
    final value = cells[row * board.cols + col].value;
    if (value == 0) return true;

    // 해당 셀이 속한 블록들에 대해 검사
    for (final block in blocks) {
      if (!block.cells.contains((row, col))) continue;

      final usedValues = <int>{};
      var partialSum = 0;
      var emptyCells = 0;

      for (final (r, c) in block.cells) {
        final v = cells[r * board.cols + c].value;
        if (v != 0) {
          if (!usedValues.add(v)) return false; // 중복
          partialSum += v;
        } else {
          emptyCells++;
        }
      }

      // 부분 합계가 이미 목표 합계를 초과하면 무효
      if (partialSum > block.sum) return false;

      // 남은 셀이 0이면 합계 정확히 일치해야 함
      if (emptyCells == 0 && partialSum != block.sum) return false;

      // 남은 셀로 목표 합계 달성 가능한지 간단 검사
      if (emptyCells > 0) {
        final remaining = block.sum - partialSum;
        // 남은 셀에 넣을 수 있는 최솟값 합 (사용 안 된 가장 작은 숫자들)
        final minPossible = _minSum(emptyCells, usedValues);
        // 남은 셀에 넣을 수 있는 최댓값 합 (사용 안 된 가장 큰 숫자들)
        final maxPossible = _maxSum(emptyCells, usedValues);
        if (remaining < minPossible || remaining > maxPossible) return false;
      }
    }
    return true;
  }

  /// N개 셀에 넣을 수 있는 최소 합 (usedValues 제외)
  static int _minSum(int n, Set<int> usedValues) {
    var sum = 0;
    var count = 0;
    for (var v = 1; v <= 9 && count < n; v++) {
      if (!usedValues.contains(v)) {
        sum += v;
        count++;
      }
    }
    return sum;
  }

  /// N개 셀에 넣을 수 있는 최대 합 (usedValues 제외)
  static int _maxSum(int n, Set<int> usedValues) {
    var sum = 0;
    var count = 0;
    for (var v = 9; v >= 1 && count < n; v--) {
      if (!usedValues.contains(v)) {
        sum += v;
        count++;
      }
    }
    return sum;
  }

  /// 모든 블록이 규칙을 만족하는지 (완성 보드 전용)
  static bool _checkAllBlocks(KakuroBoard board) {
    for (final block in board.blocks) {
      final values = <int>{};
      var sum = 0;
      for (final (r, c) in block.cells) {
        final v = board.getValue(r, c);
        if (v == 0) return false;
        if (!values.add(v)) return false; // 중복
        sum += v;
      }
      if (sum != block.sum) return false;
    }
    return true;
  }

  /// 부분 검증 (채워진 부분만 위반 검사)
  static bool _checkPartial(KakuroBoard board) {
    for (final block in board.blocks) {
      final values = <int>{};
      var partialSum = 0;
      for (final (r, c) in block.cells) {
        final v = board.getValue(r, c);
        if (v != 0) {
          if (!values.add(v)) return false;
          partialSum += v;
        }
      }
      if (partialSum > block.sum) return false;
    }
    return true;
  }

  /// 특정 셀에 놓을 수 있는 후보 값 (블록 규칙 기반)
  static List<int> getCandidates(KakuroBoard board, int row, int col) {
    if (board.getCell(row, col).type != KakuroCellType.white) return [];

    final cellBlocks = board.blocksForCell(row, col);
    var candidates = <int>{1, 2, 3, 4, 5, 6, 7, 8, 9};

    for (final block in cellBlocks) {
      final usedValues = <int>{};
      var partialSum = 0;
      var otherEmptyCells = 0; // 현재 셀 제외 빈 셀 수

      for (final (r, c) in block.cells) {
        if (r == row && c == col) continue; // 현재 셀 건너뜀
        final v = board.getValue(r, c);
        if (v != 0) {
          usedValues.add(v);
          partialSum += v;
        } else {
          otherEmptyCells++;
        }
      }

      // 이미 사용된 값 제거
      candidates = candidates.difference(usedValues);

      // 남은 합계 범위 검사
      final remaining = block.sum - partialSum;
      candidates.removeWhere((v) {
        if (v > remaining) return true; // 이 값만으로도 초과
        if (otherEmptyCells == 0) {
          // 이 셀이 블록의 마지막 빈 셀
          return v != remaining;
        }
        // 이 값을 넣은 후 나머지로 달성 가능한지
        final afterUsed = {...usedValues, v};
        final afterRemaining = remaining - v;
        final afterMinSum = _minSum(otherEmptyCells, afterUsed);
        final afterMaxSum = _maxSum(otherEmptyCells, afterUsed);
        return afterRemaining < afterMinSum || afterRemaining > afterMaxSum;
      });
    }

    return candidates.toList()..sort();
  }
}
