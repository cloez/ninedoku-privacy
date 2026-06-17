/// 노노그램 솔버 — 행/열 교차 논리
///
/// 각 행/열에 대해 가능한 모든 배치를 열거하고,
/// 모든 배치에서 동일한 값을 가지는 셀을 확정한다.
library;

import 'nonogram_board.dart';

class NonogramSolver {
  /// 해답 개수 카운트 (백트래킹 + 라인 추론).
  /// maxCount에 도달하면 즉시 중단.
  /// [timeout]/[timeLimit] 지정 시, 시간 초과되면 즉시 중단하고
  /// 현재까지 카운트된 값을 반환한다 (best-effort).
  /// 0: 해 없음, 1: 유일해, 2 이상: 다중해.
  static int countSolutions(
    NonogramBoard board, {
    int maxCount = 2,
    Stopwatch? timeout,
    Duration? timeLimit,
  }) {
    final counter = _SolutionCounter(maxCount, timeout, timeLimit);
    _countRecursive(board, counter);
    return counter.count;
  }

  static void _countRecursive(NonogramBoard board, _SolutionCounter counter) {
    if (counter.reached || counter.timedOut) return;

    // 라인 추론으로 가능한 만큼 채움
    var current = board.copyWith();
    bool changed = true;

    while (changed) {
      changed = false;

      for (int r = 0; r < current.rows; r++) {
        final line = current.getRow(r);
        final hints = current.rowHints[r];
        final result = _solveLine(line, hints);
        if (result == null) return; // 모순
        for (int c = 0; c < current.cols; c++) {
          if (line[c] == -1 && result[c] != -1) {
            current = current.setValue(r, c, result[c]);
            changed = true;
          }
        }
      }

      for (int c = 0; c < current.cols; c++) {
        final line = current.getCol(c);
        final hints = current.colHints[c];
        final result = _solveLine(line, hints);
        if (result == null) return;
        for (int r = 0; r < current.rows; r++) {
          if (line[r] == -1 && result[r] != -1) {
            current = current.setValue(r, c, result[r]);
            changed = true;
          }
        }
      }
    }

    if (current.isComplete) {
      counter.increment();
      return;
    }

    // 첫 미결정 셀에 대해 0/1 분기
    for (int i = 0; i < current.cells.length; i++) {
      if (current.cells[i] != -1) continue;
      final r = i ~/ current.cols;
      final c = i % current.cols;

      for (final value in [1, 0]) {
        if (counter.reached || counter.timedOut) return;
        final trial = current.setValue(r, c, value);
        _countRecursive(trial, counter);
      }
      return; // 첫 미결정 셀만 처리, 재귀가 나머지 처리
    }
  }

  /// 풀이
  static NonogramBoard? solve(NonogramBoard board) {
    var current = board.copyWith();
    bool changed = true;

    while (changed) {
      changed = false;

      // 행 처리
      for (int r = 0; r < current.rows; r++) {
        final line = current.getRow(r);
        final hints = current.rowHints[r];
        final result = _solveLine(line, hints);
        if (result == null) return null; // 모순
        for (int c = 0; c < current.cols; c++) {
          if (line[c] == -1 && result[c] != -1) {
            current = current.setValue(r, c, result[c]);
            changed = true;
          }
        }
      }

      // 열 처리
      for (int c = 0; c < current.cols; c++) {
        final line = current.getCol(c);
        final hints = current.colHints[c];
        final result = _solveLine(line, hints);
        if (result == null) return null;
        for (int r = 0; r < current.rows; r++) {
          if (line[r] == -1 && result[r] != -1) {
            current = current.setValue(r, c, result[r]);
            changed = true;
          }
        }
      }
    }

    if (current.isComplete) return current;

    // 백트래킹: 첫 번째 미결정 셀에 대해 시도
    for (int i = 0; i < current.cells.length; i++) {
      if (current.cells[i] != -1) continue;
      final r = i ~/ current.cols;
      final c = i % current.cols;

      for (final value in [1, 0]) {
        final trial = current.setValue(r, c, value);
        final result = solve(trial);
        if (result != null) return result;
      }
      return null; // 두 값 모두 실패
    }

    return current;
  }

  /// 단일 행/열 풀이 — 가능한 모든 배치의 교집합
  static List<int>? _solveLine(List<int> line, List<int> hints) {
    final len = line.length;

    // 빈 힌트 (전부 비어야 함)
    if (hints.isEmpty || (hints.length == 1 && hints[0] == 0)) {
      final result = List<int>.from(line);
      for (int i = 0; i < len; i++) {
        if (result[i] == 1) return null; // 이미 채워진 셀이 있으면 모순
        result[i] = 0;
      }
      return result;
    }

    // 가능한 모든 배치 생성
    final arrangements = _generateArrangements(hints, len, line);
    if (arrangements.isEmpty) return null;

    // 교집합 계산
    final result = List<int>.from(line);
    for (int i = 0; i < len; i++) {
      if (result[i] != -1) continue;

      bool allFilled = true;
      bool allEmpty = true;
      for (final arr in arrangements) {
        if (arr[i] != 1) allFilled = false;
        if (arr[i] != 0) allEmpty = false;
      }

      if (allFilled) {
        result[i] = 1;
      } else if (allEmpty) {
        result[i] = 0;
      }
    }

    return result;
  }

  /// 가능한 배치 열거 (기존 셀 상태와 호환되는 것만)
  static List<List<int>> _generateArrangements(
    List<int> hints,
    int length,
    List<int> current,
  ) {
    final results = <List<int>>[];
    _generateRecursive(hints, 0, length, List<int>.filled(length, 0), 0, current, results);
    return results;
  }

  static void _generateRecursive(
    List<int> hints,
    int hintIdx,
    int length,
    List<int> arrangement,
    int pos,
    List<int> current,
    List<List<int>> results,
  ) {
    // 결과 제한 (성능)
    if (results.length >= 10000) return;

    if (hintIdx == hints.length) {
      // 나머지 모두 비어야 함
      for (int i = pos; i < length; i++) {
        if (current[i] == 1) return; // 채워진 셀이 있으면 불가
      }
      // 호환성 확인
      final arr = List<int>.from(arrangement);
      for (int i = pos; i < length; i++) {
        arr[i] = 0;
      }
      if (_isCompatible(arr, current)) {
        results.add(arr);
      }
      return;
    }

    final hint = hints[hintIdx];
    final remainingHints = hints.sublist(hintIdx + 1);
    final minRemainingSpace = remainingHints.isEmpty
        ? 0
        : remainingHints.reduce((a, b) => a + b) + remainingHints.length;

    final maxStart = length - hint - minRemainingSpace;

    for (int start = pos; start <= maxStart; start++) {
      // start 이전은 비어야 함
      bool valid = true;
      for (int i = pos; i < start; i++) {
        if (current[i] == 1) {
          valid = false;
          break;
        }
      }
      if (!valid) break; // 이후로도 불가

      // hint 블록 배치
      bool blockValid = true;
      for (int i = start; i < start + hint; i++) {
        if (current[i] == 0) {
          blockValid = false;
          break;
        }
      }
      if (!blockValid) continue;

      // 블록 다음 칸은 비어야 함 (마지막 힌트가 아닌 경우)
      if (hintIdx < hints.length - 1 && start + hint < length) {
        if (current[start + hint] == 1) continue;
      }

      // 배치 적용
      final newArr = List<int>.from(arrangement);
      for (int i = pos; i < start; i++) {
        newArr[i] = 0;
      }
      for (int i = start; i < start + hint; i++) {
        newArr[i] = 1;
      }
      if (start + hint < length && hintIdx < hints.length - 1) {
        newArr[start + hint] = 0;
      }

      final nextPos = start + hint + (hintIdx < hints.length - 1 ? 1 : 0);
      _generateRecursive(hints, hintIdx + 1, length, newArr, nextPos, current, results);
    }
  }

  /// 배치가 현재 셀 상태와 호환되는지
  static bool _isCompatible(List<int> arrangement, List<int> current) {
    for (int i = 0; i < arrangement.length; i++) {
      if (current[i] != -1 && current[i] != arrangement[i]) return false;
    }
    return true;
  }

  /// 보드 완료 검증
  static bool isComplete(NonogramBoard board) {
    // 노노그램은 사용자가 X(0)를 일일이 표시할 필요가 없다.
    // 채움(1)만으로 모든 행/열의 힌트와 일치하면 완료된 것이다.
    // 빈칸(-1)은 자동으로 비어있는 것으로 간주된다.

    // 모든 행 검증 (빈칸과 X는 동일하게 "안 채움"으로 취급)
    for (int r = 0; r < board.rows; r++) {
      if (!_lineMatchesHints(board.getRow(r), board.rowHints[r])) return false;
    }

    // 모든 열 검증
    for (int c = 0; c < board.cols; c++) {
      if (!_lineMatchesHints(board.getCol(c), board.colHints[c])) return false;
    }

    return true;
  }

  /// 행/열이 힌트와 일치하는지
  static bool _lineMatchesHints(List<int> line, List<int> hints) {
    final groups = <int>[];
    int count = 0;
    for (final v in line) {
      if (v == 1) {
        count++;
      } else {
        if (count > 0) groups.add(count);
        count = 0;
      }
    }
    if (count > 0) groups.add(count);

    if (hints.isEmpty || (hints.length == 1 && hints[0] == 0)) {
      return groups.isEmpty;
    }

    if (groups.length != hints.length) return false;
    for (int i = 0; i < groups.length; i++) {
      if (groups[i] != hints[i]) return false;
    }
    return true;
  }

  /// 특정 행이 힌트를 만족하는지 (UI에서 완성 표시용)
  static bool isRowSatisfied(NonogramBoard board, int row) {
    final line = board.getRow(row);
    if (line.contains(-1)) return false;
    return _lineMatchesHints(line, board.rowHints[row]);
  }

  /// 특정 열이 힌트를 만족하는지
  static bool isColSatisfied(NonogramBoard board, int col) {
    final line = board.getCol(col);
    if (line.contains(-1)) return false;
    return _lineMatchesHints(line, board.colHints[col]);
  }
}

/// 해답 카운팅용 헬퍼 (조기 중단 + 시간 한도 지원)
class _SolutionCounter {
  final int maxCount;
  final Stopwatch? timeout;
  final Duration? timeLimit;
  int count = 0;

  _SolutionCounter(this.maxCount, [this.timeout, this.timeLimit]);

  bool get reached => count >= maxCount;

  /// 시간 한도가 지정되어 있고 초과된 경우 true
  bool get timedOut {
    if (timeout == null || timeLimit == null) return false;
    return timeout!.elapsed > timeLimit!;
  }

  void increment() {
    count++;
  }
}
