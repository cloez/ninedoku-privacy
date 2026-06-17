import 'skyscrapers_board.dart';

/// Skyscrapers 솔버
/// 라틴 방진 + 가시성 규칙 검증, 백트래킹 기반
class SkyscrapersSolver {
  /// 해당 방향에서 보이는 빌딩 수 계산
  static int visibleCount(List<int> line) {
    int count = 0, maxHeight = 0;
    for (final h in line) {
      if (h > maxHeight) {
        count++;
        maxHeight = h;
      }
    }
    return count;
  }

  /// 퍼즐을 풀고 해답 보드 반환 (풀 수 없으면 null)
  static SkyscrapersBoard? solve(SkyscrapersBoard board) {
    final cells = List<int>.from(board.cells);
    if (_solveRecursive(cells, board)) {
      return board.copyWith(cells: cells);
    }
    return null;
  }

  /// 해가 정확히 1개인지 검증
  static bool hasUniqueSolution(
    SkyscrapersBoard board, {
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
    SkyscrapersBoard board, {
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
  static bool isValid(SkyscrapersBoard board) {
    return _checkLatinPartial(board.cells, board.size) &&
        _checkCluesPartial(board);
  }

  /// 모든 셀 채워졌고 모든 규칙 만족하는지
  static bool isComplete(SkyscrapersBoard board) {
    if (!board.isComplete) return false;
    return _checkLatinComplete(board.cells, board.size) &&
        _checkAllClues(board);
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 풀이 로직
  // ──────────────────────────────────────────────────────────────────

  /// 재귀 백트래킹 풀이
  static bool _solveRecursive(List<int> cells, SkyscrapersBoard board) {
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
    SkyscrapersBoard board,
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
  static int _findBestEmptyCell(List<int> cells, SkyscrapersBoard board) {
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
      List<int> cells, SkyscrapersBoard board, int idx) {
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

    // 3) 가시성 힌트 검사 (행/열이 완성됐을 때만 완전 검사, 아니면 부분 검사)
    // 행 검사 (왼쪽/오른쪽 힌트)
    if (!_checkRowCluesPartial(cells, board, row)) return false;

    // 열 검사 (위쪽/아래쪽 힌트)
    if (!_checkColCluesPartial(cells, board, col)) return false;

    return true;
  }

  /// 행의 가시성 힌트 부분 검사
  static bool _checkRowCluesPartial(
      List<int> cells, SkyscrapersBoard board, int row) {
    final size = board.size;

    // 행이 완성됐는지 확인
    final rowLine = <int>[];
    var complete = true;
    for (var c = 0; c < size; c++) {
      final v = cells[row * size + c];
      rowLine.add(v);
      if (v == 0) complete = false;
    }

    if (complete) {
      // 완전 검사
      final leftClue = board.leftClues[row];
      if (leftClue != 0 && visibleCount(rowLine) != leftClue) return false;

      final rightClue = board.rightClues[row];
      if (rightClue != 0 && visibleCount(rowLine.reversed.toList()) != rightClue) {
        return false;
      }
    } else {
      // 부분 검사: 아직 다 안 채워져도 이미 위반 감지 가능한 경우
      // 왼쪽 힌트: 왼쪽부터 연속으로 채워진 부분의 가시성이 힌트보다 이미 크면 위반
      final leftClue = board.leftClues[row];
      if (leftClue != 0) {
        var visible = 0;
        var maxH = 0;
        for (var c = 0; c < size; c++) {
          final v = rowLine[c];
          if (v == 0) break;
          if (v > maxH) {
            visible++;
            maxH = v;
          }
        }
        if (visible > leftClue) return false;
      }

      // 오른쪽 힌트
      final rightClue = board.rightClues[row];
      if (rightClue != 0) {
        var visible = 0;
        var maxH = 0;
        for (var c = size - 1; c >= 0; c--) {
          final v = rowLine[c];
          if (v == 0) break;
          if (v > maxH) {
            visible++;
            maxH = v;
          }
        }
        if (visible > rightClue) return false;
      }
    }

    return true;
  }

  /// 열의 가시성 힌트 부분 검사
  static bool _checkColCluesPartial(
      List<int> cells, SkyscrapersBoard board, int col) {
    final size = board.size;

    // 열 데이터 추출
    final colLine = <int>[];
    var complete = true;
    for (var r = 0; r < size; r++) {
      final v = cells[r * size + col];
      colLine.add(v);
      if (v == 0) complete = false;
    }

    if (complete) {
      // 완전 검사
      final topClue = board.topClues[col];
      if (topClue != 0 && visibleCount(colLine) != topClue) return false;

      final bottomClue = board.bottomClues[col];
      if (bottomClue != 0 && visibleCount(colLine.reversed.toList()) != bottomClue) {
        return false;
      }
    } else {
      // 부분 검사
      final topClue = board.topClues[col];
      if (topClue != 0) {
        var visible = 0;
        var maxH = 0;
        for (var r = 0; r < size; r++) {
          final v = colLine[r];
          if (v == 0) break;
          if (v > maxH) {
            visible++;
            maxH = v;
          }
        }
        if (visible > topClue) return false;
      }

      final bottomClue = board.bottomClues[col];
      if (bottomClue != 0) {
        var visible = 0;
        var maxH = 0;
        for (var r = size - 1; r >= 0; r--) {
          final v = colLine[r];
          if (v == 0) break;
          if (v > maxH) {
            visible++;
            maxH = v;
          }
        }
        if (visible > bottomClue) return false;
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

  /// 완성 보드의 모든 외곽 힌트 검사
  static bool _checkAllClues(SkyscrapersBoard board) {
    final size = board.size;

    for (var r = 0; r < size; r++) {
      final rowLine = <int>[];
      for (var c = 0; c < size; c++) {
        rowLine.add(board.getValue(r, c));
      }

      final leftClue = board.leftClues[r];
      if (leftClue != 0 && visibleCount(rowLine) != leftClue) return false;

      final rightClue = board.rightClues[r];
      if (rightClue != 0 && visibleCount(rowLine.reversed.toList()) != rightClue) {
        return false;
      }
    }

    for (var c = 0; c < size; c++) {
      final colLine = <int>[];
      for (var r = 0; r < size; r++) {
        colLine.add(board.getValue(r, c));
      }

      final topClue = board.topClues[c];
      if (topClue != 0 && visibleCount(colLine) != topClue) return false;

      final bottomClue = board.bottomClues[c];
      if (bottomClue != 0 && visibleCount(colLine.reversed.toList()) != bottomClue) {
        return false;
      }
    }

    return true;
  }

  /// 부분 채움 상태에서 외곽 힌트 검사 (채워진 행/열만)
  static bool _checkCluesPartial(SkyscrapersBoard board) {
    final size = board.size;

    for (var r = 0; r < size; r++) {
      final rowLine = <int>[];
      var complete = true;
      for (var c = 0; c < size; c++) {
        final v = board.getValue(r, c);
        rowLine.add(v);
        if (v == 0) complete = false;
      }
      if (!complete) continue;

      final leftClue = board.leftClues[r];
      if (leftClue != 0 && visibleCount(rowLine) != leftClue) return false;

      final rightClue = board.rightClues[r];
      if (rightClue != 0 && visibleCount(rowLine.reversed.toList()) != rightClue) {
        return false;
      }
    }

    for (var c = 0; c < size; c++) {
      final colLine = <int>[];
      var complete = true;
      for (var r = 0; r < size; r++) {
        final v = board.getValue(r, c);
        colLine.add(v);
        if (v == 0) complete = false;
      }
      if (!complete) continue;

      final topClue = board.topClues[c];
      if (topClue != 0 && visibleCount(colLine) != topClue) return false;

      final bottomClue = board.bottomClues[c];
      if (bottomClue != 0 && visibleCount(colLine.reversed.toList()) != bottomClue) {
        return false;
      }
    }

    return true;
  }

  /// 특정 셀의 행/열에서 중복이 있는지 검사 (UI 에러 표시용)
  static bool hasRowColConflict(SkyscrapersBoard board, int row, int col) {
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

  /// 특정 셀이 관련된 행/열의 가시성 힌트를 위반하는지 (UI 에러 표시용)
  static bool hasClueViolation(SkyscrapersBoard board, int row, int col) {
    final size = board.size;

    // 해당 행이 완성됐을 때만 검사
    var rowComplete = true;
    final rowLine = <int>[];
    for (var c = 0; c < size; c++) {
      final v = board.getValue(row, c);
      rowLine.add(v);
      if (v == 0) rowComplete = false;
    }

    if (rowComplete) {
      final leftClue = board.leftClues[row];
      if (leftClue != 0 && visibleCount(rowLine) != leftClue) return true;
      final rightClue = board.rightClues[row];
      if (rightClue != 0 && visibleCount(rowLine.reversed.toList()) != rightClue) {
        return true;
      }
    }

    // 해당 열이 완성됐을 때만 검사
    var colComplete = true;
    final colLine = <int>[];
    for (var r = 0; r < size; r++) {
      final v = board.getValue(r, col);
      colLine.add(v);
      if (v == 0) colComplete = false;
    }

    if (colComplete) {
      final topClue = board.topClues[col];
      if (topClue != 0 && visibleCount(colLine) != topClue) return true;
      final bottomClue = board.bottomClues[col];
      if (bottomClue != 0 && visibleCount(colLine.reversed.toList()) != bottomClue) {
        return true;
      }
    }

    return false;
  }
}
