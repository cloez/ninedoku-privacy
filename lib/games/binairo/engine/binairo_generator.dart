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
/// 시드 기반 결정론적 생성, 유일해 보장, 난이도 조절
class BinairoGenerator {
  /// 생성 타임아웃 (밀리초)
  static const int _timeoutMs = 3000;

  /// 최대 재시도 횟수
  static const int _maxRetries = 5;

  /// 난이도별 채움 비율 범위 (최소%, 최대%)
  /// difficulty: 0~4 (입문, 쉬움, 보통, 어려움, 마스터)
  static const List<(double, double)> _fillRatios = [
    (0.50, 0.60), // 입문 (6x6): 50~60% 채움 유지
    (0.35, 0.45), // 쉬움 (8x8): 35~45%
    (0.30, 0.40), // 보통 (10x10): 30~40%
    (0.25, 0.35), // 어려움 (12x12): 25~35%
    (0.20, 0.30), // 마스터 (14x14): 20~30%
  ];

  /// 퍼즐 생성
  /// [size]: 격자 크기 (6, 8, 10, 12, 14)
  /// [difficulty]: 난이도 (0: 입문, 1: 쉬움, 2: 보통, 3: 어려움, 4: 마스터)
  /// [seed]: 시드 (결정론적 생성)
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
    // 유지할 셀 수 범위
    final minKeep = (totalCells * minFill).round();
    final maxKeep = (totalCells * maxFill).round();

    for (var retry = 0; retry < _maxRetries; retry++) {
      final result = _tryGenerate(
        size: size,
        random: random,
        minKeep: minKeep,
        maxKeep: maxKeep,
      );
      if (result != null) return result;
    }

    // 모든 재시도 실패 시 더 쉬운 조건으로 fallback
    final fallbackMaxKeep = (totalCells * maxFill * 1.2).round().clamp(0, totalCells);
    return _tryGenerate(
      size: size,
      random: random,
      minKeep: maxKeep,
      maxKeep: fallbackMaxKeep,
    );
  }

  /// 단일 생성 시도
  static BinairoGenerateResult? _tryGenerate({
    required int size,
    required Random random,
    required int minKeep,
    required int maxKeep,
  }) {
    final stopwatch = Stopwatch()..start();

    // 1. 완성 보드 생성 (백트래킹 + 랜덤 순서)
    final solutionCells = _generateCompletedBoard(size, random, stopwatch);
    if (solutionCells == null) return null;

    final solution = BinairoBoard(
      size: size,
      cells: solutionCells,
      fixed: {}, // 솔루션에는 고정 셀 개념 없음
    );

    // 2. 셀 제거하여 퍼즐 생성 (유일해 보장)
    final puzzleResult = _removeNumbers(
      solution: solutionCells,
      size: size,
      random: random,
      minKeep: minKeep,
      maxKeep: maxKeep,
      stopwatch: stopwatch,
    );
    if (puzzleResult == null) return null;

    final (puzzleCells, fixedIndices) = puzzleResult;
    final puzzle = BinairoBoard(
      size: size,
      cells: puzzleCells,
      fixed: fixedIndices,
    );

    return BinairoGenerateResult(puzzle: puzzle, solution: solution);
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
    // 타임아웃 검사
    if (stopwatch.elapsedMilliseconds > _timeoutMs) return false;

    final idx = _findNextEmpty(cells);
    if (idx == -1) return true; // 모든 셀 채워짐

    // 0, 1 순서를 랜덤으로 결정
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
    if (col >= 1 && col < size - 1 &&
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
    if (row >= 1 && row < size - 1 &&
        cells[(row - 1) * size + col] == value &&
        cells[(row + 1) * size + col] == value) {
      return false;
    }
    if (row < size - 2 &&
        cells[(row + 1) * size + col] == value &&
        cells[(row + 2) * size + col] == value) {
      return false;
    }

    // 3) 행 균형 (value 개수가 절반 초과하면 안 됨)
    var rowCount = 0;
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == value) rowCount++;
    }
    if (rowCount > half) return false;

    // 4) 열 균형 (value 개수가 절반 초과하면 안 됨)
    var colCount = 0;
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == value) colCount++;
    }
    if (colCount > half) return false;

    // 5) 행 유일성 검사 (현재 행이 완전히 채워졌으면 다른 완전한 행과 비교)
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

    // 6) 열 유일성 검사 (현재 열이 완전히 채워졌으면 다른 완전한 열과 비교)
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

  /// 행에 빈칸이 있는지 확인
  static bool _hasEmptyInRow(List<int> cells, int size, int row) {
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == -1) return true;
    }
    return false;
  }

  /// 열에 빈칸이 있는지 확인
  static bool _hasEmptyInCol(List<int> cells, int size, int col) {
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == -1) return true;
    }
    return false;
  }

  /// 셀을 하나씩 제거하면서 유일해 보장 검증
  /// 반환: (퍼즐 셀 배열, 고정 인덱스 집합) 또는 null
  static (List<int>, Set<int>)? _removeNumbers({
    required List<int> solution,
    required int size,
    required Random random,
    required int minKeep,
    required int maxKeep,
    required Stopwatch stopwatch,
  }) {
    final puzzleCells = List<int>.from(solution);
    final totalCells = size * size;

    // 제거 후보 셀 인덱스 (랜덤 순서)
    final indices = List<int>.generate(totalCells, (i) => i);
    _shuffleList(indices, random);

    var removedCount = 0;
    final maxRemove = totalCells - minKeep;

    for (final idx in indices) {
      // 타임아웃 검사
      if (stopwatch.elapsedMilliseconds > _timeoutMs) break;

      // 충분히 제거했으면 종료
      if (removedCount >= maxRemove) break;

      final backup = puzzleCells[idx];
      puzzleCells[idx] = -1;

      // 유일해 검증
      final testBoard = BinairoBoard(
        size: size,
        cells: puzzleCells,
        fixed: {},
      );

      if (BinairoSolver.hasUniqueSolution(testBoard)) {
        removedCount++;
      } else {
        puzzleCells[idx] = backup; // 복원
      }
    }

    // 최소 제거 개수 미달 시 실패
    final keepCount = totalCells - removedCount;
    if (keepCount > maxKeep) return null;

    // 고정 셀 인덱스 = 제거되지 않은 셀
    final fixedIndices = <int>{};
    for (var i = 0; i < totalCells; i++) {
      if (puzzleCells[i] != -1) fixedIndices.add(i);
    }

    return (puzzleCells, fixedIndices);
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
