import 'killer_sudoku_board.dart';
import 'killer_sudoku_solver.dart';

/// 킬러 스도쿠 힌트 결과
class KillerSudokuHintResult {
  /// 힌트 단계 (1~4)
  final int level;

  /// 대상 셀 행
  final int row;

  /// 대상 셀 열
  final int col;

  /// 정답 값 (level 4에서 사용)
  final int? value;

  /// 후보 숫자 목록 (level 2~3에서 사용)
  final List<int> candidates;

  /// 관련 케이지
  final Cage? cage;

  /// 힌트 메시지
  final String message;

  const KillerSudokuHintResult({
    required this.level,
    required this.row,
    required this.col,
    this.value,
    this.candidates = const [],
    this.cage,
    this.message = '',
  });
}

/// 킬러 스도쿠 힌트 엔진 — 4단계 힌트
class KillerSudokuHintEngine {
  /// 힌트 제공
  static KillerSudokuHintResult? getHint(
    KillerSudokuBoard board,
    int level,
  ) {
    assert(level >= 1 && level <= 4, '힌트 레벨은 1~4 범위여야 합니다');

    // 힌트 대상 셀 찾기
    final target = _findBestTarget(board);
    if (target == null) return null;

    final (row, col) = target;

    switch (level) {
      case 1:
        return _level1(board, row, col);
      case 2:
        return _level2(board, row, col);
      case 3:
        return _level3(board, row, col);
      case 4:
        return _level4(board, row, col);
      default:
        return null;
    }
  }

  /// Level 1: 케이지 합계 안내
  static KillerSudokuHintResult _level1(
    KillerSudokuBoard board,
    int row,
    int col,
  ) {
    final cage = board.getCageAt(row, col);
    final sumText = cage != null ? '(합계 ${cage.sum})' : '';
    return KillerSudokuHintResult(
      level: 1,
      row: row,
      col: col,
      cage: cage,
      message: '케이지${sumText}를 살펴보세요.',
    );
  }

  /// Level 2: 가능한 조합 안내
  static KillerSudokuHintResult _level2(
    KillerSudokuBoard board,
    int row,
    int col,
  ) {
    final cage = board.getCageAt(row, col);
    final candidates = KillerSudokuSolver.getCandidates(
      board.cells,
      board.cages,
      row,
      col,
    );

    String message;
    if (cage != null && cage.cells.length <= 3) {
      // 작은 케이지면 조합 안내
      final combos = _getPossibleCombinations(board, cage);
      if (combos.isNotEmpty) {
        final comboStr = combos
            .map((c) => c.join('+'))
            .join(', ');
        message = '합계 ${cage.sum}의 ${cage.cells.length}셀 케이지에서 '
            '가능한 조합: $comboStr';
      } else {
        message = '이 셀에 가능한 숫자: ${candidates.join(", ")}';
      }
    } else {
      message = '이 셀에 가능한 숫자: ${candidates.join(", ")}';
    }

    return KillerSudokuHintResult(
      level: 2,
      row: row,
      col: col,
      candidates: candidates,
      cage: cage,
      message: message,
    );
  }

  /// Level 3: 구체적 후보 안내
  static KillerSudokuHintResult _level3(
    KillerSudokuBoard board,
    int row,
    int col,
  ) {
    final candidates = KillerSudokuSolver.getCandidates(
      board.cells,
      board.cages,
      row,
      col,
    );

    return KillerSudokuHintResult(
      level: 3,
      row: row,
      col: col,
      candidates: candidates,
      message: '이 케이지에서 ${row + 1}행 ${col + 1}열은 '
          '${candidates.join(", ")}만 가능합니다.',
    );
  }

  /// Level 4: 정답 자동 입력
  static KillerSudokuHintResult _level4(
    KillerSudokuBoard board,
    int row,
    int col,
  ) {
    final answer = board.solution[row][col];
    return KillerSudokuHintResult(
      level: 4,
      row: row,
      col: col,
      value: answer,
      message: '정답은 $answer 입니다.',
    );
  }

  /// 최적 힌트 대상 셀 찾기 (후보가 적은 셀 우선)
  static (int, int)? _findBestTarget(KillerSudokuBoard board) {
    int minCandidates = 10;
    (int, int)? best;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.cells[r][c] != 0) continue;
        final count = KillerSudokuSolver.getCandidates(
          board.cells,
          board.cages,
          r,
          c,
        ).length;
        if (count > 0 && count < minCandidates) {
          minCandidates = count;
          best = (r, c);
          if (count == 1) return best;
        }
      }
    }
    return best;
  }

  /// 케이지의 가능한 조합 계산
  static List<List<int>> _getPossibleCombinations(
    KillerSudokuBoard board,
    Cage cage,
  ) {
    // 이미 채워진 값 수집
    final usedValues = <int>{};
    var remainingSum = cage.sum;
    final emptyCells = <(int, int)>[];

    for (final cell in cage.cells) {
      final v = board.cells[cell.$1][cell.$2];
      if (v != 0) {
        usedValues.add(v);
        remainingSum -= v;
      } else {
        emptyCells.add(cell);
      }
    }

    if (emptyCells.isEmpty) return [];

    // 가능한 조합 탐색
    final result = <List<int>>[];
    _findCombinations(
      remainingSum,
      emptyCells.length,
      1,
      usedValues,
      [],
      result,
    );
    return result;
  }

  /// 조합 탐색 재귀
  static void _findCombinations(
    int targetSum,
    int cellCount,
    int startValue,
    Set<int> used,
    List<int> current,
    List<List<int>> result,
  ) {
    if (current.length == cellCount) {
      final sum = current.fold(0, (a, b) => a + b);
      if (sum == targetSum) {
        result.add(List<int>.from(current));
      }
      return;
    }

    final remaining = cellCount - current.length;
    for (var v = startValue; v <= 9; v++) {
      if (used.contains(v)) continue;
      // 가지치기: 현재합 + v가 이미 목표를 초과
      final currentSum = current.fold(0, (a, b) => a + b) + v;
      if (currentSum > targetSum) break;
      // 남은 슬롯에 최소값을 채워도 목표에 못 미치면 스킵
      var minRemaining = 0;
      var nextMin = v + 1;
      for (var i = 0; i < remaining - 1; i++) {
        while (used.contains(nextMin)) {
          nextMin++;
        }
        if (nextMin > 9) break;
        minRemaining += nextMin;
        nextMin++;
      }
      if (currentSum + minRemaining > targetSum) {
        // 너무 크면 계속 진행
      }

      current.add(v);
      used.add(v);
      _findCombinations(targetSum, cellCount, v + 1, used, current, result);
      current.removeLast();
      used.remove(v);
    }
  }
}
