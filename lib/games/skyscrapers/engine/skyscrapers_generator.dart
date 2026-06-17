import 'dart:math';

import 'skyscrapers_board.dart';
import 'skyscrapers_solver.dart';

/// Skyscrapers 퍼즐 생성 결과
class SkyscrapersGenerateResult {
  final SkyscrapersBoard puzzle;
  final SkyscrapersBoard solution;

  const SkyscrapersGenerateResult({
    required this.puzzle,
    required this.solution,
  });
}

/// Skyscrapers 퍼즐 생성기
/// 시드 기반 결정론적 생성, 유일해 best-effort, 난이도 조절
class SkyscrapersGenerator {
  /// 전체 생성 시간 한도 (3초 미만 응답 보장)
  static const Duration _maxDuration = Duration(milliseconds: 2500);

  /// hasUniqueSolution 호출당 시간 한도
  static const Duration _uniqueTimeLimit = Duration(milliseconds: 800);

  /// 난이도별 외곽 힌트 비율
  static const List<(double, double)> _clueRatios = [
    (0.70, 0.90),
    (0.55, 0.70),
    (0.40, 0.55),
    (0.30, 0.45),
    (0.20, 0.35),
  ];

  /// 난이도별 셀 채움 비율
  static const List<(double, double)> _fillRatios = [
    (0.30, 0.45),
    (0.15, 0.30),
    (0.05, 0.15),
    (0.00, 0.10),
    (0.00, 0.05),
  ];

  /// 퍼즐 생성
  static SkyscrapersGenerateResult? generate({
    required int size,
    required int difficulty,
    required int seed,
  }) {
    assert(size >= 4 && size <= 8, '크기는 4~8 범위여야 합니다');
    assert(difficulty >= 0 && difficulty <= 4, '난이도는 0~4 범위여야 합니다');

    final random = Random(seed);
    final clampedDiff = difficulty.clamp(0, 4);
    final stopwatch = Stopwatch()..start();
    SkyscrapersGenerateResult? lastCandidate;

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

  /// 단일 생성 시도
  static (SkyscrapersGenerateResult?, SkyscrapersGenerateResult?)
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

    // 2. 외곽 힌트 계산
    final topClues = List<int>.filled(size, 0);
    final bottomClues = List<int>.filled(size, 0);
    final leftClues = List<int>.filled(size, 0);
    final rightClues = List<int>.filled(size, 0);

    for (var c = 0; c < size; c++) {
      final colLine = <int>[];
      for (var r = 0; r < size; r++) {
        colLine.add(solutionCells[r * size + c]);
      }
      topClues[c] = SkyscrapersSolver.visibleCount(colLine);
      bottomClues[c] =
          SkyscrapersSolver.visibleCount(colLine.reversed.toList());
    }

    for (var r = 0; r < size; r++) {
      final rowLine = <int>[];
      for (var c = 0; c < size; c++) {
        rowLine.add(solutionCells[r * size + c]);
      }
      leftClues[r] = SkyscrapersSolver.visibleCount(rowLine);
      rightClues[r] =
          SkyscrapersSolver.visibleCount(rowLine.reversed.toList());
    }

    // 3. 난이도에 따라 일부 힌트 제거
    final (minClueRatio, maxClueRatio) = _clueRatios[difficulty];
    final totalClues = size * 4;
    final targetClueCount = (totalClues *
            (minClueRatio + random.nextDouble() * (maxClueRatio - minClueRatio)))
        .round();

    final allClueIndices = List<int>.generate(totalClues, (i) => i);
    _shuffleList(allClueIndices, random);

    final removeCount = totalClues - targetClueCount;
    final removeSet = allClueIndices.take(removeCount).toSet();

    final pTopClues = List<int>.from(topClues);
    final pBottomClues = List<int>.from(bottomClues);
    final pLeftClues = List<int>.from(leftClues);
    final pRightClues = List<int>.from(rightClues);

    for (final idx in removeSet) {
      if (idx < size) {
        pTopClues[idx] = 0;
      } else if (idx < size * 2) {
        pBottomClues[idx - size] = 0;
      } else if (idx < size * 3) {
        pLeftClues[idx - size * 2] = 0;
      } else {
        pRightClues[idx - size * 3] = 0;
      }
    }

    final solution = SkyscrapersBoard(
      size: size,
      cells: solutionCells,
      topClues: topClues,
      bottomClues: bottomClues,
      leftClues: leftClues,
      rightClues: rightClues,
      fixed: {},
    );

    // 4. 셀 제거 (유일해 best-effort)
    final (puzzleCells, fixedIndices, uniqueOk) = _removeCells(
      solution: solutionCells,
      size: size,
      difficulty: difficulty,
      topClues: pTopClues,
      bottomClues: pBottomClues,
      leftClues: pLeftClues,
      rightClues: pRightClues,
      random: random,
      stopwatch: stopwatch,
    );

    final puzzle = SkyscrapersBoard(
      size: size,
      cells: puzzleCells,
      topClues: pTopClues,
      bottomClues: pBottomClues,
      leftClues: pLeftClues,
      rightClues: pRightClues,
      fixed: fixedIndices,
    );
    final candidate =
        SkyscrapersGenerateResult(puzzle: puzzle, solution: solution);

    if (uniqueOk) return (candidate, null);
    return (null, candidate);
  }

  /// 라틴 방진 생성
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

  /// 셀 제거 (유일해 best-effort)
  static (List<int>, Set<int>, bool) _removeCells({
    required List<int> solution,
    required int size,
    required int difficulty,
    required List<int> topClues,
    required List<int> bottomClues,
    required List<int> leftClues,
    required List<int> rightClues,
    required Random random,
    required Stopwatch stopwatch,
  }) {
    final puzzleCells = List<int>.from(solution);
    final totalCells = size * size;

    final (minFill, _) = _fillRatios[difficulty];
    final maxRemove = totalCells - (totalCells * minFill).round();

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

      final testBoard = SkyscrapersBoard(
        size: size,
        cells: puzzleCells,
        topClues: topClues,
        bottomClues: bottomClues,
        leftClues: leftClues,
        rightClues: rightClues,
        fixed: {},
      );

      bool unique;
      try {
        unique = SkyscrapersSolver.hasUniqueSolution(
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

  static void _shuffleList<T>(List<T> list, Random random) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
}
