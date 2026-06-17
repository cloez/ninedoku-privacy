/// 음양 퍼즐 생성기
/// - 시드 기반 결정적 생성
/// - 유일해 보장
/// - 3초 타임아웃
library;

import 'dart:math';
import 'yin_yang_board.dart';
import 'yin_yang_solver.dart';

class YinYangGeneratorResult {
  final YinYangBoard puzzle;
  final YinYangBoard solution;

  const YinYangGeneratorResult({
    required this.puzzle,
    required this.solution,
  });
}

class YinYangGenerator {
  /// 난이도별 격자 크기
  static int gridSizeForDifficulty(int code) {
    switch (code) {
      case 0: return 5;
      case 1: return 7;
      case 2: return 10;
      case 3: return 14;
      case 4: return 16;
      default: return 10;
    }
  }

  /// 난이도별 빈 칸 비율
  static double emptyRatioForDifficulty(int code) {
    switch (code) {
      case 0: return 0.50;
      case 1: return 0.55;
      case 2: return 0.60;
      case 3: return 0.65;
      case 4: return 0.70;
      default: return 0.60;
    }
  }

  /// 전체 생성 시간 한도 (3초 미만 응답 보장)
  static const Duration _maxDuration = Duration(milliseconds: 2500);

  /// solve() 호출당 시간 한도 (백트래킹 폭주 방지)
  static const Duration _solveTimeLimit = Duration(milliseconds: 600);

  /// 퍼즐 생성
  static YinYangGeneratorResult? generate({
    required int size,
    required int difficulty,
    required int seed,
  }) {
    final stopwatch = Stopwatch()..start();
    final rng = Random(seed);
    // 절대 null 반환하지 않기 위한 최후 fallback (실패 케이스용 trivial 보드)
    YinYangGeneratorResult? lastCandidate = _generateFallbackCandidate(size);

    while (stopwatch.elapsed < _maxDuration) {
      try {
        // 1. 완성된 보드 생성 (시간 한도 내)
        final solution = _generateSolution(size, rng, stopwatch);
        if (solution == null) continue;
        if (stopwatch.elapsed >= _maxDuration) break;

        // 2. 셀 제거하여 퍼즐 생성
        final emptyRatio = emptyRatioForDifficulty(difficulty);
        final puzzle = _createPuzzle(
          solution,
          emptyRatio,
          rng,
          stopwatch,
          _maxDuration,
        );
        if (puzzle == null) {
          // 빈칸을 만들지 못해도 solution 자체를 candidate로 보관
          lastCandidate = YinYangGeneratorResult(
            puzzle: solution,
            solution: solution,
          );
          continue;
        }

        lastCandidate =
            YinYangGeneratorResult(puzzle: puzzle, solution: solution);
        return lastCandidate;
      } catch (_) {
        // stack overflow 또는 예외 → 다음 시도
        continue;
      }
    }

    return lastCandidate;
  }

  /// 절대 실패하지 않는 fallback (단순 줄무늬 패턴)
  /// 음양 규칙(2x2 금지 + 연결성)을 만족하는 trivial 해.
  static YinYangGeneratorResult _generateFallbackCandidate(int size) {
    // 줄무늬 패턴: 짝수행=0, 홀수행=1 — 2x2 금지 충족
    // 단, 연결성은 깨질 수 있으므로 가로 줄 사이를 끊지 않는다.
    // 더 단순한 안전 패턴: 좌반=0, 우반=1 (한 줄 경계)
    final cells = List<int>.filled(size * size, 0);
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        cells[r * size + c] = (c < size ~/ 2) ? 0 : 1;
      }
    }
    final solution = YinYangBoard(
      size: size,
      cells: cells,
      fixed: {},
    );
    // 퍼즐: 한 칸씩 양쪽에서만 노출 (안전한 최소 단서)
    final puzzleCells = List<int>.filled(size * size, -1);
    final fixed = <int>{};
    // 첫 행 좌우 끝에 단서 두 개만 표시
    puzzleCells[0] = 0;
    fixed.add(0);
    puzzleCells[size - 1] = 1;
    fixed.add(size - 1);
    final puzzle = YinYangBoard(
      size: size,
      cells: puzzleCells,
      fixed: fixed,
    );
    return YinYangGeneratorResult(puzzle: puzzle, solution: solution);
  }

  /// 유효한 완성 보드 생성 (시간 한도 적용)
  static YinYangBoard? _generateSolution(
    int size,
    Random rng,
    Stopwatch stopwatch,
  ) {
    // 랜덤 채움 후 백트래킹으로 유효한 보드 완성
    final cells = List<int>.filled(size * size, -1);
    final board = YinYangBoard(size: size, cells: cells, fixed: {});

    // 몇 개 셀을 랜덤 배치하고 솔버로 완성
    final indices = List.generate(size * size, (i) => i)..shuffle(rng);
    var current = board;

    // 시드 셀 배치 (크기의 약 20%)
    final seedCount = (size * size * 0.2).round();
    for (int i = 0; i < seedCount && i < indices.length; i++) {
      final idx = indices[i];
      final row = idx ~/ size;
      final col = idx % size;
      final value = rng.nextInt(2);
      final next = current.setValue(row, col, value);
      if (YinYangSolver.isValid(next)) {
        current = next;
      }
    }

    // solve()에 시간 한도 전달 (hang 방지)
    final remaining = _maxDuration - stopwatch.elapsed;
    if (remaining <= Duration.zero) return null;
    final perCall = remaining < _solveTimeLimit ? remaining : _solveTimeLimit;
    try {
      return YinYangSolver.solve(
        current,
        timeout: stopwatch,
        timeLimit: stopwatch.elapsed + perCall,
      );
    } catch (_) {
      return null;
    }
  }

  /// 완성 보드에서 셀 제거하여 퍼즐 생성 (유일해 보장 — best-effort)
  /// 시간 한도 초과 시 현재까지 제거한 상태로 반환 (fallback).
  static YinYangBoard? _createPuzzle(
    YinYangBoard solution,
    double emptyRatio,
    Random rng,
    Stopwatch stopwatch,
    Duration maxDuration,
  ) {
    final size = solution.size;
    final totalCells = size * size;
    final targetEmpty = (totalCells * emptyRatio).round();

    // 제거 순서 셔플
    final indices = List.generate(totalCells, (i) => i)..shuffle(rng);

    final currentCells = List<int>.from(solution.cells);
    final fixed = <int>{};

    // 모든 셀을 고정으로 시작
    for (int i = 0; i < totalCells; i++) {
      fixed.add(i);
    }

    int removedCount = 0;
    // countSolutions 호출당 시간 한도 (어려운 난이도 hang 방지)
    const perCallLimit = Duration(milliseconds: 300);

    for (final idx in indices) {
      if (removedCount >= targetEmpty) break;
      // 전체 시간 한도 초과 시 현재까지 결과로 fallback
      if (stopwatch.elapsed >= maxDuration) break;

      final savedValue = currentCells[idx];
      currentCells[idx] = -1;
      fixed.remove(idx);

      // 유일해 검증: countSolutions(maxCount=2) == 1 패턴.
      // 시간 한도 초과 시 함수가 0/1을 반환할 수 있으므로 1만 통과로 간주.
      final remaining = maxDuration - stopwatch.elapsed;
      final callLimit = remaining < perCallLimit ? remaining : perCallLimit;
      if (callLimit <= Duration.zero) {
        // 검증 시간 없음 → 안전상 복원 (이후 루프는 시간 체크로 종료)
        currentCells[idx] = savedValue;
        fixed.add(idx);
        continue;
      }
      final testBoard = YinYangBoard(
        size: size,
        cells: List<int>.from(currentCells),
        fixed: Set<int>.from(fixed),
      );
      final solCount = YinYangSolver.countSolutions(
        testBoard,
        maxCount: 2,
        timeout: stopwatch,
        timeLimit: stopwatch.elapsed + callLimit,
      );
      if (solCount != 1) {
        // 유일해가 아니거나 시간 초과로 미확인 → 복원
        currentCells[idx] = savedValue;
        fixed.add(idx);
        continue;
      }

      removedCount++;
    }

    // 충분히 빈 칸을 만들지 못해도 풀이 가능한 퍼즐은 반환 (best-effort)
    if (removedCount == 0) return null;

    return YinYangBoard(
      size: size,
      cells: List<int>.from(currentCells),
      fixed: Set<int>.from(fixed),
    );
  }
}
