import 'dart:math';

import 'light_up_board.dart';
import 'light_up_solver.dart';

/// Light Up 퍼즐 생성 결과
class LightUpGenerateResult {
  /// 퍼즐 (벽 + 빈 흰 칸)
  final LightUpBoard puzzle;

  /// 완성된 해답 (전구 배치됨)
  final LightUpBoard solution;

  const LightUpGenerateResult({
    required this.puzzle,
    required this.solution,
  });
}

/// Light Up 퍼즐 생성기
/// 벽 배치 → 전구 배치 → 벽에서 전구 제거 → 유일해 검증
class LightUpGenerator {
  /// 생성 타임아웃 (밀리초) — 사용자 멈춤 인지 최소화
  static const int _timeoutMs = 1000;

  /// 최대 재시도 횟수 (최악 시간 = _timeoutMs × _maxRetries)
  static const int _maxRetries = 2;

  /// 난이도별 벽 비율
  static const List<double> _wallRatios = [
    0.15, // 입문 (7x7)
    0.18, // 쉬움 (8x8)
    0.20, // 보통 (10x10)
    0.22, // 어려움 (12x12)
    0.25, // 마스터 (14x14)
  ];

  /// 퍼즐 생성
  ///
  /// 정책: 유일해 검증이 시간 한도 내 통과되지 않거나
  /// solver가 stack overflow를 일으켜도 풀이 가능한 퍼즐(벽+전구 배치 유효)을
  /// best-effort fallback으로 반환한다. 사용자가 화면 멈춤 없이 게임을 시작할 수 있도록 보장.
  static LightUpGenerateResult? generate({
    required int size,
    required int difficulty,
    required int seed,
  }) {
    assert(size >= 7, '크기는 7 이상이어야 합니다');
    assert(difficulty >= 0 && difficulty <= 4, '난이도는 0~4');

    final random = Random(seed);
    final wallRatio = _wallRatios[difficulty.clamp(0, 4)];

    LightUpGenerateResult? lastCandidate;

    for (var retry = 0; retry < _maxRetries; retry++) {
      final (result, candidate) = _tryGenerateWithCandidate(
        size: size,
        random: random,
        wallRatio: wallRatio,
        difficulty: difficulty,
      );
      if (result != null) return result; // 유일해 검증 통과
      if (candidate != null) lastCandidate = candidate; // best-effort 백업
    }

    return lastCandidate;
  }

  /// 단일 생성 시도
  /// 반환: (유일해 검증까지 통과한 결과, 풀이 가능한 후보)
  static (LightUpGenerateResult?, LightUpGenerateResult?) _tryGenerateWithCandidate({
    required int size,
    required Random random,
    required double wallRatio,
    required int difficulty,
  }) {
    final stopwatch = Stopwatch()..start();
    final totalCells = size * size;
    final wallCount = (totalCells * wallRatio).round();

    // 1. 벽 배치 (대칭적으로)
    final cells = List<int>.filled(totalCells, LightUpBoard.empty);
    final wallIndices = _placeWalls(cells, size, wallCount, random);

    // 2. 전구 배치 (모든 흰 칸을 비추도록)
    final solutionCells = List<int>.from(cells);
    if (!_placeBulbs(solutionCells, size, random, stopwatch)) {
      return (null, null);
    }

    // 3. 벽 숫자 부여 (인접 전구 수 기록)
    _assignWallNumbers(solutionCells, cells, size, wallIndices, random, difficulty);

    // 고정 셀 = 벽 위치
    final fixed = <int>{};
    for (var i = 0; i < totalCells; i++) {
      final v = cells[i];
      if (v == LightUpBoard.wallBlank || (v >= 0 && v <= 4)) {
        fixed.add(i);
      }
    }

    // 퍼즐 보드 = 벽만 있고 전구 없음
    final puzzleCells = List<int>.from(cells);
    final puzzle = LightUpBoard(size: size, cells: puzzleCells, fixed: fixed);
    final solution = LightUpBoard(size: size, cells: solutionCells, fixed: fixed);

    final candidate = LightUpGenerateResult(puzzle: puzzle, solution: solution);

    // 4. 유일해 검증 — 시간 한도 초과 또는 stack overflow 방어
    if (stopwatch.elapsedMilliseconds > _timeoutMs) {
      return (null, candidate); // 시간 초과 → candidate 반환
    }

    // 솔버가 stack overflow를 일으킬 수 있으므로 try-catch로 가드
    try {
      if (!LightUpSolver.hasUniqueSolution(puzzle)) {
        return (null, candidate); // 유일해가 아니면 candidate 반환
      }
    } catch (_) {
      // 솔버 재귀 깊이 초과 등의 오류 → candidate를 best-effort로 반환
      return (null, candidate);
    }

    return (candidate, null); // 유일해 검증 통과
  }

  /// 벽 배치 (반대칭 패턴)
  static List<int> _placeWalls(
      List<int> cells, int size, int wallCount, Random random) {
    final wallIndices = <int>[];
    final candidates = <int>[];

    // 중심 대칭 후보 생성
    for (var i = 0; i < size * size; i++) {
      candidates.add(i);
    }
    _shuffleList(candidates, random);

    var placed = 0;
    for (final idx in candidates) {
      if (placed >= wallCount) break;

      final row = idx ~/ size;
      final col = idx % size;
      // 대칭 위치
      final symIdx = (size - 1 - row) * size + (size - 1 - col);

      if (cells[idx] == LightUpBoard.empty) {
        cells[idx] = LightUpBoard.wallBlank;
        wallIndices.add(idx);
        placed++;

        // 대칭 위치도 벽 배치
        if (symIdx != idx && cells[symIdx] == LightUpBoard.empty && placed < wallCount) {
          cells[symIdx] = LightUpBoard.wallBlank;
          wallIndices.add(symIdx);
          placed++;
        }
      }
    }

    return wallIndices;
  }

  /// 전구 배치 (그리디 — 비춰지지 않은 칸부터)
  static bool _placeBulbs(
      List<int> cells, int size, Random random, Stopwatch stopwatch) {
    // 비춰지지 않은 흰 칸이 있으면 전구 배치
    final board = LightUpBoard(
      size: size,
      cells: cells,
      fixed: _wallFixedSet(cells),
    );

    // 전구 배치 가능한 흰 칸 목록
    final whiteCells = <int>[];
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == LightUpBoard.empty) whiteCells.add(i);
    }
    _shuffleList(whiteCells, random);

    // 그리디: 아직 비춰지지 않은 칸에 전구 배치 시도
    var changed = true;
    while (changed) {
      if (stopwatch.elapsedMilliseconds > _timeoutMs) return false;

      changed = false;
      final currentBoard = LightUpBoard(
        size: size,
        cells: cells,
        fixed: _wallFixedSet(cells),
      );
      final litCells = currentBoard.getLitCells();

      for (final idx in whiteCells) {
        if (cells[idx] != LightUpBoard.empty) continue;
        if (litCells.contains(idx)) continue;

        // 전구 놓기 시도
        cells[idx] = LightUpBoard.bulb;
        final testBoard = LightUpBoard(
          size: size,
          cells: cells,
          fixed: _wallFixedSet(cells),
        );
        final row = idx ~/ size;
        final col = idx % size;

        if (testBoard.hasBulbConflict(row, col)) {
          cells[idx] = LightUpBoard.empty; // 충돌하면 되돌리기
          continue;
        }

        changed = true;
        break;
      }
    }

    // 모든 흰 칸이 비춰지는지 최종 확인
    final finalBoard = LightUpBoard(
      size: size,
      cells: cells,
      fixed: _wallFixedSet(cells),
    );
    final finalLit = finalBoard.getLitCells();
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == LightUpBoard.empty && !finalLit.contains(i)) {
        return false; // 비춰지지 않은 칸 존재
      }
    }

    return true;
  }

  /// 벽에 숫자 부여
  static void _assignWallNumbers(
    List<int> solutionCells,
    List<int> puzzleCells,
    int size,
    List<int> wallIndices,
    Random random,
    int difficulty,
  ) {
    // 난이도에 따라 숫자 벽 비율 조절
    final numberRatio = switch (difficulty) {
      0 => 0.7, // 입문: 벽의 70%에 숫자
      1 => 0.6,
      2 => 0.5,
      3 => 0.4,
      _ => 0.3, // 마스터: 30%만
    };

    final shuffledWalls = List<int>.from(wallIndices);
    _shuffleList(shuffledWalls, random);

    final numberCount = (shuffledWalls.length * numberRatio).round();
    var assigned = 0;

    for (final idx in shuffledWalls) {
      if (assigned >= numberCount) break;

      final row = idx ~/ size;
      final col = idx % size;

      // 인접 전구 수 계산 (솔루션 기준)
      var adjBulbs = 0;
      for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nr = row + dr;
        final nc = col + dc;
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
        if (solutionCells[nr * size + nc] == LightUpBoard.bulb) adjBulbs++;
      }

      // 퍼즐 보드에 숫자 기록
      puzzleCells[idx] = adjBulbs;
      solutionCells[idx] = adjBulbs;
      assigned++;
    }
  }

  /// 벽 셀의 고정 인덱스 집합
  static Set<int> _wallFixedSet(List<int> cells) {
    final fixed = <int>{};
    for (var i = 0; i < cells.length; i++) {
      final v = cells[i];
      if (v == LightUpBoard.wallBlank || (v >= 0 && v <= 4)) {
        fixed.add(i);
      }
    }
    return fixed;
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
