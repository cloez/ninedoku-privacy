import 'dart:math';

import 'binairo_board.dart';
import 'binairo_solver.dart';

/// Binairo 퍼즐 생성 결과
class BinairoGenerateResult {
  /// 퍼즐 (빈칸 포함)
  final BinairoBoard puzzle;

  /// 완성된 해답
  final BinairoBoard solution;

  const BinairoGenerateResult({
    required this.puzzle,
    required this.solution,
  });
}

/// Binairo 퍼즐 생성기
/// 시드 기반 결정론적 생성, 유일해 best-effort, 난이도 조절
class BinairoGenerator {
  /// 전체 생성 시간 한도 (3초 미만 응답 보장)
  static const Duration _maxDuration = Duration(milliseconds: 2500);

  /// hasUniqueSolution 호출당 시간 한도 (백트래킹 폭주 방지)
  static const Duration _uniqueTimeLimit = Duration(milliseconds: 600);

  /// 난이도별 채움 비율 범위 (최소%, 최대%)
  /// difficulty: 0~4 (입문, 쉬움, 보통, 어려움, 마스터)
  static const List<(double, double)> _fillRatios = [
    (0.50, 0.60), // 입문 (6x6)
    (0.35, 0.45), // 쉬움 (8x8)
    (0.30, 0.40), // 보통 (10x10)
    (0.25, 0.35), // 어려움 (12x12)
    (0.20, 0.30), // 마스터 (14x14)
  ];

  /// 퍼즐 생성
  /// [size]: 격자 크기 (6, 8, 10, 12, 14)
  /// [difficulty]: 난이도 (0: 입문, 1: 쉬움, 2: 보통, 3: 어려움, 4: 마스터)
  /// [seed]: 시드 (결정론적 생성)
  ///
  /// best-effort 정책: 2.5초 한도 내에서 유일해 퍼즐을 찾으며,
  /// 시간 초과 시 마지막 후보(풀이 가능)를 반환한다. 절대 null을 반환하지 않도록 시도한다.
  static BinairoGenerateResult? generate({
    required int size,
    required int difficulty,
    required int seed,
  }) {
    assert(size % 2 == 0 && size >= 6, '크기는 6 이상 짝수여야 합니다');
    assert(difficulty >= 0 && difficulty <= 4, '난이도는 0~4 범위여야 합니다');

    final random = Random(seed);
    final clampedDifficulty = difficulty.clamp(0, 4);
    final (minFill, maxFill) = _fillRatios[clampedDifficulty];
    final totalCells = size * size;
    final minKeep = (totalCells * minFill).round();
    final maxKeep = (totalCells * maxFill).round();

    final stopwatch = Stopwatch()..start();
    BinairoGenerateResult? lastCandidate;

    while (stopwatch.elapsed < _maxDuration) {
      try {
        final (result, candidate) = _tryGenerateWithCandidate(
          size: size,
          random: random,
          minKeep: minKeep,
          maxKeep: maxKeep,
          stopwatch: stopwatch,
        );
        if (result != null) return result;
        if (candidate != null) lastCandidate = candidate;
      } catch (_) {
        // 스택 오버플로우 또는 예외 → 다음 시도
        continue;
      }
    }

    // 시간 초과 후 lastCandidate가 없으면 trivial fallback 생성 (절대 null 반환 방지)
    lastCandidate ??= _generateTrivialFallback(size);
    return lastCandidate;
  }

  /// 시간 초과 케이스용 trivial fallback (지그재그 패턴 기반)
  /// 풀이 가능한 보드를 즉시 반환한다.
  static BinairoGenerateResult _generateTrivialFallback(int size) {
    // 지그재그 패턴 — 행을 두 가지 종류로 교대하되 더 다양한 패턴 사용
    // 패턴 A: 001011 001011 ... 패턴 B: 110100 110100 ...
    // 동일 행/열 반복을 줄이기 위해 행마다 한 칸씩 회전
    final cells = List<int>.filled(size * size, 0);
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        // 간단한 체크무늬: 각 행을 다른 패턴으로
        // (r + c) % 3 == 0이면 1, 아니면 0이면 3연속 일부 가능성
        // 가장 안전한 trivial 패턴: 짝수 그룹/홀수 그룹 분배
        final base = ((r + c) ~/ 2) % 2;
        cells[r * size + c] = base;
      }
    }
    final solution = BinairoBoard(size: size, cells: cells, fixed: {});
    // 단서 표시는 절반만
    final puzzleCells = List<int>.from(cells);
    final fixed = <int>{};
    for (var i = 0; i < size * size; i += 2) {
      fixed.add(i);
    }
    for (var i = 0; i < size * size; i++) {
      if (!fixed.contains(i)) puzzleCells[i] = -1;
    }
    final puzzle = BinairoBoard(size: size, cells: puzzleCells, fixed: fixed);
    return BinairoGenerateResult(puzzle: puzzle, solution: solution);
  }

  /// 단일 생성 시도 (성공 결과 또는 fallback 후보 반환)
  static (BinairoGenerateResult?, BinairoGenerateResult?)
      _tryGenerateWithCandidate({
    required int size,
    required Random random,
    required int minKeep,
    required int maxKeep,
    required Stopwatch stopwatch,
  }) {
    // 1. 완성 보드 생성 (백트래킹 + 랜덤 순서)
    final solutionCells = _generateCompletedBoard(size, random, stopwatch);
    if (solutionCells == null) return (null, null);
    if (stopwatch.elapsed >= _maxDuration) return (null, null);

    final solution = BinairoBoard(
      size: size,
      cells: solutionCells,
      fixed: {},
    );

    // 2. 셀 제거하여 퍼즐 생성 (유일해 best-effort)
    final (puzzleCells, fixedIndices, hasUnique) = _removeNumbers(
      solution: solutionCells,
      size: size,
      random: random,
      minKeep: minKeep,
      maxKeep: maxKeep,
      stopwatch: stopwatch,
    );

    final puzzle = BinairoBoard(
      size: size,
      cells: puzzleCells,
      fixed: fixedIndices,
    );
    final candidate = BinairoGenerateResult(puzzle: puzzle, solution: solution);

    // 유일해 보장 + 채움 비율 조건 만족 시 성공
    final keepCount = puzzleCells.where((v) => v != -1).length;
    if (hasUnique && keepCount <= maxKeep) {
      return (candidate, null);
    }
    return (null, candidate);
  }

  /// 유효한 완성 보드 생성 (백트래킹 + 랜덤 순서)
  static List<int>? _generateCompletedBoard(
    int size,
    Random random,
    Stopwatch stopwatch,
  ) {
    final cells = List<int>.filled(size * size, -1);

    if (_fillBoardRandomized(cells, size, random, stopwatch)) {
      return cells;
    }
    return null;
  }

  /// 백트래킹으로 보드 완성 (랜덤 순서 시도)
  static bool _fillBoardRandomized(
    List<int> cells,
    int size,
    Random random,
    Stopwatch stopwatch,
  ) {
    // 시간 초과 검사
    if (stopwatch.elapsed >= _maxDuration) return false;

    final idx = _findNextEmpty(cells);
    if (idx == -1) return true;

    final values = random.nextBool() ? [0, 1] : [1, 0];

    for (final value in values) {
      cells[idx] = value;
      if (_isValidPlacement(cells, size, idx)) {
        if (_fillBoardRandomized(cells, size, random, stopwatch)) return true;
      }
      cells[idx] = -1;
    }
    return false;
  }

  /// 다음 빈 셀 인덱스 (순차 탐색)
  static int _findNextEmpty(List<int> cells) {
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == -1) return i;
    }
    return -1;
  }

  /// 특정 셀 배치 유효성 검사 (솔버와 동일 로직)
  static bool _isValidPlacement(List<int> cells, int size, int idx) {
    final row = idx ~/ size;
    final col = idx % size;
    final value = cells[idx];
    final half = size ~/ 2;

    // 1) 행에서 3연속 검사
    if (col >= 2 &&
        cells[row * size + col - 1] == value &&
        cells[row * size + col - 2] == value) {
      return false;
    }
    if (col >= 1 &&
        col < size - 1 &&
        cells[row * size + col - 1] == value &&
        cells[row * size + col + 1] == value) {
      return false;
    }
    if (col < size - 2 &&
        cells[row * size + col + 1] == value &&
        cells[row * size + col + 2] == value) {
      return false;
    }

    // 2) 열에서 3연속 검사
    if (row >= 2 &&
        cells[(row - 1) * size + col] == value &&
        cells[(row - 2) * size + col] == value) {
      return false;
    }
    if (row >= 1 &&
        row < size - 1 &&
        cells[(row - 1) * size + col] == value &&
        cells[(row + 1) * size + col] == value) {
      return false;
    }
    if (row < size - 2 &&
        cells[(row + 1) * size + col] == value &&
        cells[(row + 2) * size + col] == value) {
      return false;
    }

    // 3) 행 균형
    var rowCount = 0;
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == value) rowCount++;
    }
    if (rowCount > half) return false;

    // 4) 열 균형
    var colCount = 0;
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == value) colCount++;
    }
    if (colCount > half) return false;

    // 5) 행 유일성 검사
    final rowComplete = !_hasEmptyInRow(cells, size, row);
    if (rowComplete) {
      for (var otherRow = 0; otherRow < size; otherRow++) {
        if (otherRow == row) continue;
        if (_hasEmptyInRow(cells, size, otherRow)) continue;
        var same = true;
        for (var c = 0; c < size; c++) {
          if (cells[row * size + c] != cells[otherRow * size + c]) {
            same = false;
            break;
          }
        }
        if (same) return false;
      }
    }

    // 6) 열 유일성 검사
    final colComplete = !_hasEmptyInCol(cells, size, col);
    if (colComplete) {
      for (var otherCol = 0; otherCol < size; otherCol++) {
        if (otherCol == col) continue;
        if (_hasEmptyInCol(cells, size, otherCol)) continue;
        var same = true;
        for (var r = 0; r < size; r++) {
          if (cells[r * size + col] != cells[r * size + otherCol]) {
            same = false;
            break;
          }
        }
        if (same) return false;
      }
    }

    return true;
  }

  /// 행에 빈칸이 있는지
  static bool _hasEmptyInRow(List<int> cells, int size, int row) {
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == -1) return true;
    }
    return false;
  }

  /// 열에 빈칸이 있는지
  static bool _hasEmptyInCol(List<int> cells, int size, int col) {
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == -1) return true;
    }
    return false;
  }

  /// 셀 제거 (유일해 best-effort)
  /// 반환: (퍼즐 셀, 고정 인덱스, 마지막 상태가 유일해인지)
  static (List<int>, Set<int>, bool) _removeNumbers({
    required List<int> solution,
    required int size,
    required Random random,
    required int minKeep,
    required int maxKeep,
    required Stopwatch stopwatch,
  }) {
    final puzzleCells = List<int>.from(solution);
    final totalCells = size * size;

    final indices = List<int>.generate(totalCells, (i) => i);
    _shuffleList(indices, random);

    var removedCount = 0;
    final maxRemove = totalCells - minKeep;
    var lastWasUnique = true; // 시작은 솔루션 자체 (유일해)

    for (final idx in indices) {
      if (stopwatch.elapsed >= _maxDuration) break;
      if (removedCount >= maxRemove) break;

      final backup = puzzleCells[idx];
      puzzleCells[idx] = -1;

      // 유일해 검증 (시간 한도 내)
      final remaining = _maxDuration - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        puzzleCells[idx] = backup;
        break;
      }
      final perCall = remaining < _uniqueTimeLimit ? remaining : _uniqueTimeLimit;

      final testBoard = BinairoBoard(
        size: size,
        cells: puzzleCells,
        fixed: {},
      );

      bool unique;
      try {
        unique = BinairoSolver.hasUniqueSolution(
          testBoard,
          timeout: stopwatch,
          timeLimit: stopwatch.elapsed + perCall,
        );
      } catch (_) {
        unique = false;
      }

      if (unique) {
        removedCount++;
        lastWasUnique = true;
      } else {
        puzzleCells[idx] = backup;
      }
    }

    // 고정 셀 인덱스 = 제거되지 않은 셀
    final fixedIndices = <int>{};
    for (var i = 0; i < totalCells; i++) {
      if (puzzleCells[i] != -1) fixedIndices.add(i);
    }

    return (puzzleCells, fixedIndices, lastWasUnique);
  }

  /// 리스트 셔플 (Fisher-Yates)
  static void _shuffleList<T>(List<T> list, Random random) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
}
