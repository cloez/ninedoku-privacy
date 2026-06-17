import 'dart:math';

import 'tents_board.dart';
import 'tents_solver.dart';

/// Tents 퍼즐 생성 결과
class TentsGenerateResult {
  /// 퍼즐 (나무 + 빈칸, 플레이어가 텐트/잔디 배치)
  final TentsBoard puzzle;

  /// 완성된 해답
  final TentsBoard solution;

  const TentsGenerateResult({
    required this.puzzle,
    required this.solution,
  });
}

/// Tents 퍼즐 생성기
/// 시드 기반 결정론적 생성, 유일해 보장
class TentsGenerator {
  /// 단일 시도 내부 타임아웃 (밀리초)
  static const int _timeoutMs = 5000;

  /// 전체 generation 시간 한도 (3초 미만 응답 보장 — 안전망)
  static const Duration _maxDuration = Duration(milliseconds: 2500);

  /// 최대 재시도 횟수
  static const int _maxRetries = 10;

  /// 난이도별 나무/텐트 밀도 (나무 수 / 전체 셀 수)
  /// difficulty: 0~4 (입문, 쉬움, 보통, 어려움, 마스터)
  static const List<double> _treeDensity = [
    0.20, // 입문 (6x6): 약 7개 나무
    0.18, // 쉬움 (8x8): 약 11개 나무
    0.16, // 보통 (10x10): 약 16개 나무
    0.15, // 어려움 (12x12): 약 21개 나무
    0.14, // 마스터 (12x12, 유일해 보장 강화): 약 20개 나무
  ];

  /// 퍼즐 생성
  static TentsGenerateResult? generate({
    required int size,
    required int difficulty,
    required int seed,
  }) {
    assert(size >= 6, '크기는 6 이상이어야 합니다');
    assert(difficulty >= 0 && difficulty <= 4, '난이도는 0~4');

    final random = Random(seed);
    final density = _treeDensity[difficulty.clamp(0, 4)];
    final targetTrees = (size * size * density).round().clamp(2, size * size ~/ 3);

    // 전체 시간 안전망: 2.5초 초과 시 중단
    final overall = Stopwatch()..start();
    for (var retry = 0; retry < _maxRetries; retry++) {
      if (overall.elapsed >= _maxDuration) break;
      final result = _tryGenerate(
        size: size,
        targetTrees: targetTrees,
        random: random,
      );
      if (result != null) return result;
    }
    return null;
  }

  /// 단일 생성 시도
  static TentsGenerateResult? _tryGenerate({
    required int size,
    required int targetTrees,
    required Random random,
  }) {
    final stopwatch = Stopwatch()..start();

    // 1단계: 텐트 위치를 먼저 결정 (8방향 인접 불가)
    final tentPositions = _placeTents(size, targetTrees, random, stopwatch);
    if (tentPositions == null) return null;

    // 2단계: 각 텐트에 인접한 나무 배치 (1:1 매칭)
    final treePositions =
        _placeTreesForTents(size, tentPositions, random, stopwatch);
    if (treePositions == null) return null;

    // 3단계: 해답 보드 구성
    final solutionCells = List<int>.filled(size * size, TentsBoard.grass);
    for (final idx in treePositions) {
      solutionCells[idx] = TentsBoard.tree;
    }
    for (final idx in tentPositions) {
      solutionCells[idx] = TentsBoard.tent;
    }

    // 행/열 힌트 계산
    final rowCounts = List<int>.filled(size, 0);
    final colCounts = List<int>.filled(size, 0);
    for (final idx in tentPositions) {
      rowCounts[idx ~/ size]++;
      colCounts[idx % size]++;
    }

    final solution = TentsBoard(
      size: size,
      cells: solutionCells,
      rowCounts: rowCounts,
      colCounts: colCounts,
      treePositions: treePositions,
    );

    // 4단계: 퍼즐 보드 (나무만 남기고 나머지 빈칸)
    final puzzleCells = List<int>.filled(size * size, TentsBoard.empty);
    for (final idx in treePositions) {
      puzzleCells[idx] = TentsBoard.tree;
    }

    final puzzle = TentsBoard(
      size: size,
      cells: puzzleCells,
      rowCounts: rowCounts,
      colCounts: colCounts,
      treePositions: treePositions,
    );

    // 5단계: 유일해 검증 (master 12 이하 모든 사이즈)
    if (size <= 12) {
      if (stopwatch.elapsedMilliseconds > _timeoutMs) return null;
      if (!TentsSolver.hasUniqueSolution(puzzle)) return null;
    }

    return TentsGenerateResult(puzzle: puzzle, solution: solution);
  }

  /// 텐트 위치 배치 (8방향 인접 불가 보장)
  static Set<int>? _placeTents(
    int size,
    int count,
    Random random,
    Stopwatch stopwatch,
  ) {
    final placed = <int>{};
    final blocked = <int>{}; // 8방향 인접으로 차단된 위치

    // 랜덤 순서로 셀 시도
    final candidates = List<int>.generate(size * size, (i) => i)
      ..shuffle(random);

    for (final idx in candidates) {
      if (stopwatch.elapsedMilliseconds > _timeoutMs) return null;
      if (placed.length >= count) break;
      if (blocked.contains(idx)) continue;

      placed.add(idx);
      // 8방향 인접 차단
      final row = idx ~/ size;
      final col = idx % size;
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = row + dr;
          final nc = col + dc;
          if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
            blocked.add(nr * size + nc);
          }
        }
      }
    }

    // 충분한 텐트를 배치하지 못했으면 실패
    if (placed.length < count) return null;
    return placed;
  }

  /// 각 텐트에 인접한 나무 배치 (1:1 매칭, 나무끼리 겹치지 않음)
  static Set<int>? _placeTreesForTents(
    int size,
    Set<int> tentPositions,
    Random random,
    Stopwatch stopwatch,
  ) {
    final treePositions = <int>{};
    final tentList = tentPositions.toList()..shuffle(random);

    for (final tentIdx in tentList) {
      if (stopwatch.elapsedMilliseconds > _timeoutMs) return null;

      final row = tentIdx ~/ size;
      final col = tentIdx % size;

      // 상하좌우 인접 셀 중 나무를 놓을 수 있는 위치
      final candidates = <int>[];
      for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
        final ni = nr * size + nc;
        // 다른 텐트 위치가 아니고, 이미 나무가 아닌 곳
        if (!tentPositions.contains(ni) && !treePositions.contains(ni)) {
          candidates.add(ni);
        }
      }

      if (candidates.isEmpty) return null; // 나무 배치 실패

      // 랜덤으로 하나 선택
      final treeIdx = candidates[random.nextInt(candidates.length)];
      treePositions.add(treeIdx);
    }

    return treePositions;
  }
}
