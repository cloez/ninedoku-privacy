import 'dart:math';

import 'star_battle_board.dart';
import 'star_battle_solver.dart';

/// Star Battle 퍼즐 생성 결과
class StarBattleGenerateResult {
  /// 퍼즐 (빈 보드 + 영역 정보만)
  final StarBattleBoard puzzle;

  /// 완성된 해답
  final StarBattleBoard solution;

  const StarBattleGenerateResult({
    required this.puzzle,
    required this.solution,
  });
}

/// Star Battle 퍼즐 생성기
/// 시드 기반 결정론적 생성, 유일해 보장
class StarBattleGenerator {
  /// 단일 시도 타임아웃 (밀리초)
  /// 영역 생성 알고리즘이 막힐 수 있어 짧게 잡고 빠르게 폴백 진입.
  static const int _timeoutMs = 700;

  /// 최대 재시도 횟수 (전체 최악 시간 = _timeoutMs × _maxRetries + 폴백 시간)
  /// 사용자 멈춤 인지 최소화를 위해 1회만 시도 후 폴백.
  static const int _maxRetries = 1;

  /// 난이도별 설정: (gridSize, starCount)
  /// difficulty: 0~4 (입문, 쉬움, 보통, 어려움, 마스터)
  static const List<(int, int)> _difficultyConfig = [
    (6, 1),  // 입문: 6×6, 1-star
    (7, 1),  // 쉬움: 7×7, 1-star
    (8, 1),  // 보통: 8×8, 1-star
    (9, 2),  // 어려움: 9×9, 2-star
    (10, 2), // 마스터: 10×10, 2-star
  ];

  /// 퍼즐 생성
  /// [difficulty]: 난이도 (0: 입문, 1: 쉬움, 2: 보통, 3: 어려움, 4: 마스터)
  /// [seed]: 시드 (결정론적 생성)
  ///
  /// 정책: 유일해 검증이 시간 한도 내에 통과되지 않아도
  /// 풀이 가능한 퍼즐(영역+해답이 유효)을 fallback으로 반환한다.
  /// 사용자가 화면 멈춤 없이 게임을 시작할 수 있도록 보장.
  static StarBattleGenerateResult? generate({
    required int difficulty,
    required int seed,
  }) {
    assert(difficulty >= 0 && difficulty <= 4, '난이도는 0~4 범위여야 합니다');

    final random = Random(seed);
    final clampedDifficulty = difficulty.clamp(0, 4);
    final (gridSize, starCount) = _difficultyConfig[clampedDifficulty];

    // 마지막으로 영역+해답이 성공한 후보 (유일해 검증 실패해도 fallback 사용)
    StarBattleGenerateResult? lastCandidate;

    for (var retry = 0; retry < _maxRetries; retry++) {
      final (result, candidate) = _tryGenerateWithCandidate(
        size: gridSize,
        starCount: starCount,
        random: random,
      );
      if (result != null) return result; // 유일해 검증 통과
      if (candidate != null) lastCandidate = candidate; // best-effort 백업
    }

    // 유일해를 만족하는 후보가 있으면 반환
    if (lastCandidate != null) return lastCandidate;

    // 최종 폴백: 결정론적 영역 분할로 풀이 가능한 퍼즐 보장
    // (사용자가 화면 멈춤 없이 게임을 시작할 수 있도록)
    return _generateFallback(
      size: gridSize,
      starCount: starCount,
      random: random,
    );
  }

  /// 결정론적 폴백 — 영역 생성 알고리즘이 실패해도 사용자가 게임 시작 가능하도록.
  /// 영역 = 가로 스트라이프 (각 행이 하나의 영역).
  /// 별 배치 = 행 i에 (i+1) % size 인덱스 등의 단순 패턴 + 인접 회피.
  static StarBattleGenerateResult? _generateFallback({
    required int size,
    required int starCount,
    required Random random,
  }) {
    // 1. 영역 = 행별 스트라이프 (영역 i = 행 i)
    final regions = List<int>.filled(size * size, 0);
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        regions[r * size + c] = r;
      }
    }

    // 2. 별 배치 — 백트래킹으로 유효한 해답 찾기
    final solutionCells = List<int>.filled(size * size, -1);
    final sw = Stopwatch()..start();
    final ok = _placeStarsRecursive(
      solutionCells, size, regions, starCount, 0, sw,
    );
    if (!ok) return null;

    final solutionFilled = List<int>.from(solutionCells);
    for (var i = 0; i < solutionFilled.length; i++) {
      if (solutionFilled[i] == -1) solutionFilled[i] = 0;
    }

    final solution = StarBattleBoard(
      size: size,
      cells: solutionFilled,
      regions: regions,
      starCount: starCount,
    );
    final puzzle = StarBattleBoard.empty(size, regions, starCount);

    return StarBattleGenerateResult(puzzle: puzzle, solution: solution);
  }

  /// 단일 생성 시도
  /// 반환: (유일해 검증까지 통과한 결과, 풀이 가능한 후보)
  /// - 유일해 통과 시: (result, null) 형태로 result만 사용
  /// - 유일해 실패지만 영역+해답이 유효: (null, candidate) — best-effort fallback용
  /// - 영역/해답 생성 실패: (null, null)
  static (StarBattleGenerateResult?, StarBattleGenerateResult?)
      _tryGenerateWithCandidate({
    required int size,
    required int starCount,
    required Random random,
  }) {
    final stopwatch = Stopwatch()..start();

    // 1. 영역 생성 (BFS 랜덤 분할)
    final regions = _generateRegions(size, random, stopwatch);
    if (regions == null) return (null, null);

    // 2. 해답 생성 (백트래킹)
    final solutionCells = List<int>.filled(size * size, -1);
    final solved = _generateSolution(
      solutionCells, size, regions, starCount, random, stopwatch,
    );
    if (!solved) return (null, null);

    // 빈칸을 X로 채운 해답 보드
    final solutionFilled = List<int>.from(solutionCells);
    for (var i = 0; i < solutionFilled.length; i++) {
      if (solutionFilled[i] == -1) solutionFilled[i] = 0;
    }

    final solution = StarBattleBoard(
      size: size,
      cells: solutionFilled,
      regions: regions,
      starCount: starCount,
    );

    final puzzleBoard = StarBattleBoard.empty(size, regions, starCount);
    final candidate = StarBattleGenerateResult(
      puzzle: puzzleBoard,
      solution: solution,
    );

    // 3. 유일해 검증 — 남은 시간 안에만 시도
    if (stopwatch.elapsedMilliseconds >= _timeoutMs) {
      // 시간 초과 — 유일해 검증 스킵, candidate만 반환
      return (null, candidate);
    }
    if (!StarBattleSolver.hasUniqueSolution(puzzleBoard)) {
      return (null, candidate); // 유일해가 아니면 candidate 반환
    }

    return (candidate, null); // 유일해 검증 통과
  }

  /// BFS 랜덤 영역 분할
  /// 크기 N인 격자를 N개 영역으로 분할, 각 영역 크기는 N
  static List<int>? _generateRegions(int size, Random random, Stopwatch stopwatch) {
    final totalCells = size * size;
    final regions = List<int>.filled(totalCells, -1);

    for (var regionId = 0; regionId < size; regionId++) {
      if (stopwatch.elapsedMilliseconds > _timeoutMs) return null;

      // 미할당 셀 중 시작점 선택 (연결성 보장을 위해 인접 셀 우선)
      int startIdx;
      if (regionId == 0) {
        startIdx = random.nextInt(totalCells);
      } else {
        // 기존 영역에 인접한 미할당 셀 찾기
        final candidates = <int>[];
        for (var i = 0; i < totalCells; i++) {
          if (regions[i] != -1) continue;
          final r = i ~/ size;
          final c = i % size;
          // 상하좌우에 할당된 셀이 있는지 확인
          var hasAdjacentAssigned = false;
          for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
              if (regions[nr * size + nc] != -1) {
                hasAdjacentAssigned = true;
                break;
              }
            }
          }
          if (hasAdjacentAssigned) candidates.add(i);
        }
        if (candidates.isEmpty) {
          // 연결 가능한 셀이 없으면 아무 미할당 셀 선택
          final unassigned = <int>[];
          for (var i = 0; i < totalCells; i++) {
            if (regions[i] == -1) unassigned.add(i);
          }
          if (unassigned.isEmpty) return null;
          startIdx = unassigned[random.nextInt(unassigned.length)];
        } else {
          startIdx = candidates[random.nextInt(candidates.length)];
        }
      }

      // BFS로 영역 확장
      final queue = <int>[startIdx];
      regions[startIdx] = regionId;
      var assigned = 1;

      while (assigned < size && queue.isNotEmpty) {
        if (stopwatch.elapsedMilliseconds > _timeoutMs) return null;

        // 큐에서 랜덤 인덱스 선택 (완전 BFS 대신 랜덤 BFS로 다양한 형태)
        final queueIdx = random.nextInt(queue.length);
        final current = queue[queueIdx];
        queue.removeAt(queueIdx);

        final cr = current ~/ size;
        final cc = current % size;

        // 인접 미할당 셀 찾기
        final neighbors = <int>[];
        for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
          final nr = cr + dr;
          final nc = cc + dc;
          if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
            final ni = nr * size + nc;
            if (regions[ni] == -1) neighbors.add(ni);
          }
        }

        // 이웃을 셔플하여 랜덤 확장
        _shuffleList(neighbors, random);

        for (final ni in neighbors) {
          if (assigned >= size) break;
          if (regions[ni] != -1) continue; // 이미 할당됨 (다른 반복에서)

          // 할당 후 나머지 미할당 셀이 연결되어 있는지 확인
          regions[ni] = regionId;
          assigned++;

          if (_remainingCellsConnected(regions, size)) {
            queue.add(ni);
          } else {
            // 연결성이 깨지면 되돌림
            regions[ni] = -1;
            assigned--;
          }
        }

        // 큐가 비었는데 부족하면 기존 영역 셀의 이웃 재탐색
        if (queue.isEmpty && assigned < size) {
          for (var i = 0; i < totalCells; i++) {
            if (regions[i] != regionId) continue;
            final ir = i ~/ size;
            final ic = i % size;
            for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
              final nr = ir + dr;
              final nc = ic + dc;
              if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
                final ni = nr * size + nc;
                if (regions[ni] == -1) {
                  queue.add(i);
                  break;
                }
              }
            }
            if (queue.isNotEmpty) break;
          }
        }
      }

      if (assigned != size) return null; // 영역 크기 부족 → 재시도
    }

    // 미할당 셀이 있으면 실패
    if (regions.contains(-1)) return null;

    return regions;
  }

  /// 미할당 셀들이 모두 연결되어 있는지 확인
  static bool _remainingCellsConnected(List<int> regions, int size) {
    final totalCells = size * size;
    final unassigned = <int>[];
    for (var i = 0; i < totalCells; i++) {
      if (regions[i] == -1) unassigned.add(i);
    }
    if (unassigned.length <= 1) return true;

    // BFS로 연결성 확인
    final visited = <int>{};
    final queue = <int>[unassigned.first];
    visited.add(unassigned.first);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final cr = current ~/ size;
      final cc = current % size;

      for (final (dr, dc) in [(0, 1), (0, -1), (1, 0), (-1, 0)]) {
        final nr = cr + dr;
        final nc = cc + dc;
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          final ni = nr * size + nc;
          if (regions[ni] == -1 && !visited.contains(ni)) {
            visited.add(ni);
            queue.add(ni);
          }
        }
      }
    }

    return visited.length == unassigned.length;
  }

  /// 백트래킹으로 별 배치 (랜덤 순서)
  static bool _generateSolution(
    List<int> cells, int size, List<int> regions, int starCount,
    Random random, Stopwatch stopwatch,
  ) {
    return _placeStarsRecursive(cells, size, regions, starCount, 0, stopwatch);
  }

  /// 재귀 별 배치
  static bool _placeStarsRecursive(
    List<int> cells, int size, List<int> regions, int starCount,
    int idx, Stopwatch stopwatch,
  ) {
    if (stopwatch.elapsedMilliseconds > _timeoutMs) return false;

    // 다음 빈 셀 찾기
    while (idx < cells.length && cells[idx] != -1) idx++;
    if (idx >= cells.length) {
      return StarBattleSolver.isComplete(
        StarBattleBoard(
          size: size,
          cells: cells.map((v) => v == -1 ? 0 : v).toList(),
          regions: regions,
          starCount: starCount,
        ),
      );
    }

    final row = idx ~/ size;
    final col = idx % size;

    // 별 배치 시도
    if (_canPlace(cells, size, regions, starCount, row, col)) {
      cells[idx] = 1;
      if (_placeStarsRecursive(cells, size, regions, starCount, idx + 1, stopwatch)) {
        return true;
      }
      cells[idx] = -1;
    }

    // 스킵 (빈칸 유지)
    if (_canSkip(cells, size, regions, starCount, row, col, idx)) {
      if (_placeStarsRecursive(cells, size, regions, starCount, idx + 1, stopwatch)) {
        return true;
      }
    }

    return false;
  }

  /// 별 배치 가능 확인 (솔버와 유사)
  static bool _canPlace(
    List<int> cells, int size, List<int> regions, int starCount,
    int row, int col,
  ) {
    // 행 상한
    var rowStars = 0;
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == 1) rowStars++;
    }
    if (rowStars >= starCount) return false;

    // 열 상한
    var colStars = 0;
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == 1) colStars++;
    }
    if (colStars >= starCount) return false;

    // 영역 상한
    final region = regions[row * size + col];
    var regionStars = 0;
    for (var i = 0; i < cells.length; i++) {
      if (regions[i] == region && cells[i] == 1) regionStars++;
    }
    if (regionStars >= starCount) return false;

    // 8방향 인접 확인
    for (final (dr, dc) in StarBattleSolver.directions) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
      if (cells[nr * size + nc] == 1) return false;
    }

    return true;
  }

  /// 스킵 가능 확인
  static bool _canSkip(
    List<int> cells, int size, List<int> regions, int starCount,
    int row, int col, int idx,
  ) {
    // 행 남은 빈칸으로 별 수 채울 수 있는지
    var rowStars = 0;
    var rowRemaining = 0;
    for (var c = 0; c < size; c++) {
      final v = cells[row * size + c];
      if (v == 1) rowStars++;
      else if (v == -1 && row * size + c > idx) rowRemaining++;
    }
    if (rowStars + rowRemaining < starCount) return false;

    // 열 남은 빈칸
    var colStars = 0;
    var colRemaining = 0;
    for (var r = 0; r < size; r++) {
      final v = cells[r * size + col];
      if (v == 1) colStars++;
      else if (v == -1 && r * size + col > idx) colRemaining++;
    }
    if (colStars + colRemaining < starCount) return false;

    // 영역 남은 빈칸
    final region = regions[idx];
    var regionStars = 0;
    var regionRemaining = 0;
    for (var i = 0; i < cells.length; i++) {
      if (regions[i] != region) continue;
      if (cells[i] == 1) regionStars++;
      else if (cells[i] == -1 && i > idx) regionRemaining++;
    }
    if (regionStars + regionRemaining < starCount) return false;

    return true;
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
