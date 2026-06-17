import 'dart:math';

import 'futoshiki_board.dart';
import 'futoshiki_solver.dart';

/// 후토시키 퍼즐 생성 결과
class FutoshikiGenerateResult {
  /// 퍼즐 (빈칸 포함)
  final FutoshikiBoard puzzle;

  /// 완성된 해답
  final FutoshikiBoard solution;

  const FutoshikiGenerateResult({
    required this.puzzle,
    required this.solution,
  });
}

/// 후토시키 퍼즐 생성기
/// 시드 기반 결정론적 생성, 유일해 best-effort, 난이도 조절
class FutoshikiGenerator {
  /// 전체 생성 시간 한도 (3초 미만 응답 보장)
  static const Duration _maxDuration = Duration(milliseconds: 2500);

  /// hasUniqueSolution 호출당 시간 한도
  static const Duration _uniqueTimeLimit = Duration(milliseconds: 800);

  /// 난이도별 부등호 비율 범위
  static const List<(double, double)> _constraintRatios = [
    (0.50, 0.70), // 입문 (4x4)
    (0.40, 0.55), // 쉬움 (5x5)
    (0.30, 0.45), // 보통 (6x6)
    (0.25, 0.40), // 어려움 (7x7)
    (0.20, 0.35), // 마스터 (9x9)
  ];

  /// 난이도별 셀 채움 비율 범위
  static const List<(double, double)> _fillRatios = [
    (0.30, 0.45), // 입문
    (0.20, 0.30), // 쉬움
    (0.10, 0.20), // 보통
    (0.05, 0.15), // 어려움
    (0.00, 0.10), // 마스터
  ];

  /// 퍼즐 생성
  static FutoshikiGenerateResult? generate({
    required int size,
    required int difficulty,
    required int seed,
  }) {
    assert(size >= 4 && size <= 9, '크기는 4~9 범위여야 합니다');
    assert(difficulty >= 0 && difficulty <= 4, '난이도는 0~4 범위여야 합니다');

    final random = Random(seed);
    final clampedDiff = difficulty.clamp(0, 4);
    final stopwatch = Stopwatch()..start();
    FutoshikiGenerateResult? lastCandidate;

    while (stopwatch.elapsed < _maxDuration) {
      try {
        final (result, candidate) = _tryGenerateWithCandidate(
          size: size,
          difficulty: clampedDiff,
          random: random,
          stopwatch: stopwatch,
        );
        if (result != null) return result;
        if (candidate != null) lastCandidate = candidate;
      } catch (_) {
        continue;
      }
    }

    return lastCandidate;
  }

  /// 단일 생성 시도 (성공 결과 또는 fallback 후보 반환)
  static (FutoshikiGenerateResult?, FutoshikiGenerateResult?)
      _tryGenerateWithCandidate({
    required int size,
    required int difficulty,
    required Random random,
    required Stopwatch stopwatch,
  }) {
    // 1. 라틴 방진 생성
    final solutionCells = _generateLatinSquare(size, random, stopwatch);
    if (solutionCells == null) return (null, null);
    if (stopwatch.elapsed >= _maxDuration) return (null, null);

    // 2. 부등호 배치
    final (hConstraints, vConstraints) = _generateConstraints(
      solutionCells,
      size,
      difficulty,
      random,
    );

    final solution = FutoshikiBoard(
      size: size,
      cells: solutionCells,
      horizontalConstraints: hConstraints,
      verticalConstraints: vConstraints,
      fixed: {},
    );

    // 3. 셀 제거 (유일해 best-effort)
    final (puzzleCells, fixedIndices, uniqueOk) = _removeCells(
      solution: solutionCells,
      size: size,
      difficulty: difficulty,
      hConstraints: hConstraints,
      vConstraints: vConstraints,
      random: random,
      stopwatch: stopwatch,
    );

    final puzzle = FutoshikiBoard(
      size: size,
      cells: puzzleCells,
      horizontalConstraints: hConstraints,
      verticalConstraints: vConstraints,
      fixed: fixedIndices,
    );
    final candidate = FutoshikiGenerateResult(puzzle: puzzle, solution: solution);

    if (uniqueOk) return (candidate, null);
    return (null, candidate);
  }

  /// 유효한 라틴 방진 생성
  static List<int>? _generateLatinSquare(
    int size,
    Random random,
    Stopwatch stopwatch,
  ) {
    final cells = List<int>.filled(size * size, 0);
    if (_fillLatinSquare(cells, size, random, stopwatch)) {
      return cells;
    }
    return null;
  }

  /// 백트래킹으로 라틴 방진 완성
  static bool _fillLatinSquare(
    List<int> cells,
    int size,
    Random random,
    Stopwatch stopwatch,
  ) {
    if (stopwatch.elapsed >= _maxDuration) return false;

    var idx = -1;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == 0) {
        idx = i;
        break;
      }
    }
    if (idx == -1) return true;

    final row = idx ~/ size;
    final col = idx % size;
    final values = List<int>.generate(size, (i) => i + 1);
    _shuffleList(values, random);

    for (final v in values) {
      if (_hasInRow(cells, size, row, v)) continue;
      if (_hasInCol(cells, size, col, v)) continue;
      cells[idx] = v;
      if (_fillLatinSquare(cells, size, random, stopwatch)) return true;
      cells[idx] = 0;
    }
    return false;
  }

  static bool _hasInRow(List<int> cells, int size, int row, int value) {
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == value) return true;
    }
    return false;
  }

  static bool _hasInCol(List<int> cells, int size, int col, int value) {
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == value) return true;
    }
    return false;
  }

  /// 부등호 제약 생성
  static (List<int>, List<int>) _generateConstraints(
    List<int> cells,
    int size,
    int difficulty,
    Random random,
  ) {
    final (minRatio, maxRatio) = _constraintRatios[difficulty];
    final hTotal = size * (size - 1);
    final vTotal = (size - 1) * size;
    final hConstraints = List<int>.filled(hTotal, 0);
    final vConstraints = List<int>.filled(vTotal, 0);
    final totalPossible = hTotal + vTotal;
    final targetCount =
        (totalPossible * (minRatio + random.nextDouble() * (maxRatio - minRatio)))
            .round();

    final positions = <(bool, int)>[];
    for (var i = 0; i < hTotal; i++) {
      positions.add((true, i));
    }
    for (var i = 0; i < vTotal; i++) {
      positions.add((false, i));
    }
    _shuffleList(positions, random);

    var placed = 0;
    for (final (isHorizontal, idx) in positions) {
      if (placed >= targetCount) break;
      if (isHorizontal) {
        final row = idx ~/ (size - 1);
        final col = idx % (size - 1);
        final left = cells[row * size + col];
        final right = cells[row * size + col + 1];
        hConstraints[idx] = left < right ? 1 : 2;
      } else {
        final row = idx ~/ size;
        final col = idx % size;
        final top = cells[row * size + col];
        final bottom = cells[(row + 1) * size + col];
        vConstraints[idx] = top < bottom ? 1 : 2;
      }
      placed++;
    }

    return (hConstraints, vConstraints);
  }

  /// 셀 제거 (유일해 best-effort)
  /// 반환: (퍼즐 셀, 고정 인덱스, 마지막이 유일해인지)
  static (List<int>, Set<int>, bool) _removeCells({
    required List<int> solution,
    required int size,
    required int difficulty,
    required List<int> hConstraints,
    required List<int> vConstraints,
    required Random random,
    required Stopwatch stopwatch,
  }) {
    final puzzleCells = List<int>.from(solution);
    final totalCells = size * size;
    final (minFill, _) = _fillRatios[difficulty];
    final minKeep = (totalCells * minFill).round();
    final maxRemove = totalCells - minKeep;

    final indices = List<int>.generate(totalCells, (i) => i);
    _shuffleList(indices, random);

    var removedCount = 0;
    var lastUnique = true;

    for (final idx in indices) {
      if (stopwatch.elapsed >= _maxDuration) break;
      if (removedCount >= maxRemove) break;

      final backup = puzzleCells[idx];
      puzzleCells[idx] = 0;

      final remaining = _maxDuration - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        puzzleCells[idx] = backup;
        break;
      }
      final perCall = remaining < _uniqueTimeLimit ? remaining : _uniqueTimeLimit;

      final testBoard = FutoshikiBoard(
        size: size,
        cells: puzzleCells,
        horizontalConstraints: hConstraints,
        verticalConstraints: vConstraints,
        fixed: {},
      );

      bool unique;
      try {
        unique = FutoshikiSolver.hasUniqueSolution(
          testBoard,
          timeout: stopwatch,
          timeLimit: stopwatch.elapsed + perCall,
        );
      } catch (_) {
        unique = false;
      }

      if (unique) {
        removedCount++;
        lastUnique = true;
      } else {
        puzzleCells[idx] = backup;
      }
    }

    final fixedIndices = <int>{};
    for (var i = 0; i < totalCells; i++) {
      if (puzzleCells[i] != 0) fixedIndices.add(i);
    }

    return (puzzleCells, fixedIndices, lastUnique);
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
