import 'dart:math';

import 'kakuro_board.dart';
import 'kakuro_solver.dart';

/// 카쿠로 퍼즐 생성 결과
class KakuroGenerateResult {
  /// 퍼즐 (빈칸 포함, 힌트 있음)
  final KakuroBoard puzzle;

  /// 완성된 해답
  final KakuroBoard solution;

  const KakuroGenerateResult({
    required this.puzzle,
    required this.solution,
  });
}

/// 카쿠로 퍼즐 생성기
/// 시드 기반 결정론적 생성, 유일해 best-effort, 난이도 조절
class KakuroGenerator {
  /// 전체 생성 시간 한도 (3초 미만 응답 보장)
  static const Duration _maxDuration = Duration(milliseconds: 2500);

  /// hasUniqueSolution 호출당 시간 한도
  static const Duration _uniqueTimeLimit = Duration(milliseconds: 1200);

  /// 난이도별 격자 크기 (작게 조정해 무거운 검증을 피한다)
  /// beginner: 6x6, easy: 7x7, medium: 8x8, hard: 9x9
  static const List<int> _difficultySizes = [6, 7, 8, 9];

  /// 난이도별 검은 셀 비율 (최소, 최대)
  static const List<(double, double)> _blackCellRatios = [
    (0.45, 0.55),
    (0.40, 0.50),
    (0.35, 0.45),
    (0.30, 0.40),
  ];

  /// 퍼즐 생성
  /// [difficulty]: 0=입문, 1=쉬움, 2=보통, 3=어려움
  /// [seed]: 시드
  ///
  /// best-effort 정책: 2.5초 한도 내에서 유일해 퍼즐을 찾으며,
  /// 시간 초과 시 마지막 후보(풀이 가능)를 반환. 절대 null을 반환하지 않도록 시도.
  static KakuroGenerateResult? generate({
    required int difficulty,
    required int seed,
  }) {
    assert(difficulty >= 0 && difficulty <= 3, '난이도는 0~3 범위여야 합니다');

    final random = Random(seed);
    final size = _difficultySizes[difficulty.clamp(0, 3)];
    final clampedDiff = difficulty.clamp(0, 3);

    final stopwatch = Stopwatch()..start();
    KakuroGenerateResult? lastCandidate;

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

  /// 단일 생성 시도 (성공 또는 fallback 후보)
  static (KakuroGenerateResult?, KakuroGenerateResult?)
      _tryGenerateWithCandidate({
    required int size,
    required int difficulty,
    required Random random,
    required Stopwatch stopwatch,
  }) {
    // 1. 격자 구조 생성
    final structure =
        _generateStructure(size, difficulty, random, stopwatch);
    if (structure == null) return (null, null);
    if (stopwatch.elapsed >= _maxDuration) return (null, null);

    // 2. 흰 셀 값 채우기
    final filled = _fillValues(structure, size, random, stopwatch);
    if (filled == null) return (null, null);
    if (stopwatch.elapsed >= _maxDuration) return (null, null);

    // 3. 힌트 합계 계산
    final solution = _computeHints(filled, size);

    // 4. 퍼즐 (흰 셀의 값 모두 제거)
    final puzzleCells = <KakuroCell>[];
    for (final cell in solution.cells) {
      if (cell.type == KakuroCellType.white) {
        puzzleCells.add(const KakuroCell.white(value: 0));
      } else {
        puzzleCells.add(cell);
      }
    }

    final puzzle = KakuroBoard(
      rows: size,
      cols: size,
      cells: puzzleCells,
      fixed: {},
    );
    final candidate = KakuroGenerateResult(puzzle: puzzle, solution: solution);

    // 5. 유일해 검증 (시간 한도)
    final remaining = _maxDuration - stopwatch.elapsed;
    if (remaining <= Duration.zero) return (null, candidate);
    final perCall = remaining < _uniqueTimeLimit ? remaining : _uniqueTimeLimit;

    bool unique;
    try {
      unique = KakuroSolver.hasUniqueSolution(
        puzzle,
        timeout: stopwatch,
        timeLimit: stopwatch.elapsed + perCall,
      );
    } catch (_) {
      unique = false;
    }

    if (unique) return (candidate, null);
    return (null, candidate);
  }

  /// 격자 구조 생성 (대칭적 black/white 패턴)
  static List<KakuroCell>? _generateStructure(
    int size,
    int difficulty,
    Random random,
    Stopwatch stopwatch,
  ) {
    if (stopwatch.elapsed >= _maxDuration) return null;

    final totalCells = size * size;
    final (minRatio, maxRatio) = _blackCellRatios[difficulty.clamp(0, 3)];
    final targetBlackCount = (totalCells *
            (minRatio + random.nextDouble() * (maxRatio - minRatio)))
        .round();

    final isBlack = List<bool>.filled(totalCells, false);

    // 첫 행, 첫 열은 모두 검은 셀
    for (var c = 0; c < size; c++) {
      isBlack[c] = true;
    }
    for (var r = 0; r < size; r++) {
      isBlack[r * size] = true;
    }

    var currentBlack = isBlack.where((b) => b).length;
    final candidates = <int>[];
    for (var r = 1; r < size; r++) {
      for (var c = 1; c < size; c++) {
        candidates.add(r * size + c);
      }
    }
    _shuffleList(candidates, random);

    for (final idx in candidates) {
      if (stopwatch.elapsed >= _maxDuration) return null;
      if (currentBlack >= targetBlackCount) break;

      final r = idx ~/ size;
      final c = idx % size;
      final symR = size - 1 - r;
      final symC = size - 1 - c;
      final symIdx = symR * size + symC;

      if (isBlack[idx] || isBlack[symIdx]) continue;

      isBlack[idx] = true;
      isBlack[symIdx] = true;

      if (!_validateStructure(isBlack, size)) {
        isBlack[idx] = false;
        isBlack[symIdx] = false;
        continue;
      }

      currentBlack += (idx == symIdx) ? 1 : 2;
    }

    if (!_validateStructure(isBlack, size)) return null;

    final cells = <KakuroCell>[];
    for (var i = 0; i < totalCells; i++) {
      cells.add(
        isBlack[i] ? const KakuroCell.black() : const KakuroCell.white(),
      );
    }
    return cells;
  }

  /// 구조 유효성 검사
  static bool _validateStructure(List<bool> isBlack, int size) {
    // 가로 블록 검사
    for (var r = 0; r < size; r++) {
      var runLength = 0;
      for (var c = 0; c < size; c++) {
        if (!isBlack[r * size + c]) {
          runLength++;
        } else {
          if (runLength == 1) return false;
          runLength = 0;
        }
      }
      if (runLength == 1) return false;
    }

    // 세로 블록 검사
    for (var c = 0; c < size; c++) {
      var runLength = 0;
      for (var r = 0; r < size; r++) {
        if (!isBlack[r * size + c]) {
          runLength++;
        } else {
          if (runLength == 1) return false;
          runLength = 0;
        }
      }
      if (runLength == 1) return false;
    }

    // 블록 최대 길이 9
    for (var r = 0; r < size; r++) {
      var runLength = 0;
      for (var c = 0; c < size; c++) {
        if (!isBlack[r * size + c]) {
          runLength++;
          if (runLength > 9) return false;
        } else {
          runLength = 0;
        }
      }
    }
    for (var c = 0; c < size; c++) {
      var runLength = 0;
      for (var r = 0; r < size; r++) {
        if (!isBlack[r * size + c]) {
          runLength++;
          if (runLength > 9) return false;
        } else {
          runLength = 0;
        }
      }
    }

    // 모든 흰 셀이 가로/세로 블록에 속하는지
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (isBlack[r * size + c]) continue;

        var hasAcrossClue = false;
        for (var cc = c - 1; cc >= 0; cc--) {
          if (isBlack[r * size + cc]) {
            hasAcrossClue = true;
            break;
          }
        }
        if (!hasAcrossClue) return false;

        var hasDownClue = false;
        for (var rr = r - 1; rr >= 0; rr--) {
          if (isBlack[rr * size + c]) {
            hasDownClue = true;
            break;
          }
        }
        if (!hasDownClue) return false;
      }
    }

    return true;
  }

  /// 흰 셀 값 채우기 (백트래킹)
  static List<KakuroCell>? _fillValues(
    List<KakuroCell> structure,
    int size,
    Random random,
    Stopwatch stopwatch,
  ) {
    final cells = List<KakuroCell>.from(structure);
    final whiteIndices = <int>[];
    for (var i = 0; i < cells.length; i++) {
      if (cells[i].type == KakuroCellType.white) whiteIndices.add(i);
    }

    final cellsWithHints = _addTemporaryHints(cells, size);
    final boardForBlocks =
        KakuroBoard(rows: size, cols: size, cells: cellsWithHints);
    final blocks = boardForBlocks.blocks;

    if (_fillRecursive(
        cells, size, whiteIndices, 0, blocks, random, stopwatch)) {
      return cells;
    }
    return null;
  }

  /// 검은 셀에 임시 힌트 추가 (블록 추출용)
  static List<KakuroCell> _addTemporaryHints(
      List<KakuroCell> cells, int size) {
    final result = List<KakuroCell>.from(cells);
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final idx = r * size + c;
        if (cells[idx].type != KakuroCellType.black) continue;

        int? acrossHint;
        int? downHint;

        if (c + 1 < size &&
            cells[r * size + c + 1].type == KakuroCellType.white) {
          acrossHint = 999;
        }
        if (r + 1 < size &&
            cells[(r + 1) * size + c].type == KakuroCellType.white) {
          downHint = 999;
        }

        if (acrossHint != null || downHint != null) {
          result[idx] =
              KakuroCell.black(acrossHint: acrossHint, downHint: downHint);
        }
      }
    }
    return result;
  }

  /// 백트래킹 값 채우기
  static bool _fillRecursive(
    List<KakuroCell> cells,
    int size,
    List<int> whiteIndices,
    int pos,
    List<KakuroBlock> blocks,
    Random random,
    Stopwatch stopwatch,
  ) {
    if (stopwatch.elapsed >= _maxDuration) return false;
    if (pos >= whiteIndices.length) return true;

    final idx = whiteIndices[pos];
    final row = idx ~/ size;
    final col = idx % size;

    final values = List<int>.generate(9, (i) => i + 1);
    _shuffleList(values, random);

    for (final v in values) {
      cells[idx] = KakuroCell.white(value: v);

      if (_isValidFillPlacement(cells, size, blocks, row, col)) {
        if (_fillRecursive(
            cells, size, whiteIndices, pos + 1, blocks, random, stopwatch)) {
          return true;
        }
      }

      cells[idx] = const KakuroCell.white(value: 0);
    }
    return false;
  }

  /// 채우기 시 유효성 검사 (블록 내 중복 불가)
  static bool _isValidFillPlacement(
    List<KakuroCell> cells,
    int size,
    List<KakuroBlock> blocks,
    int row,
    int col,
  ) {
    final value = cells[row * size + col].value;
    if (value == 0) return true;

    for (final block in blocks) {
      if (!block.cells.contains((row, col))) continue;

      final usedValues = <int>{};
      for (final (r, c) in block.cells) {
        final v = cells[r * size + c].value;
        if (v != 0) {
          if (!usedValues.add(v)) return false;
        }
      }
    }
    return true;
  }

  /// 힌트 합계 계산
  static KakuroBoard _computeHints(List<KakuroCell> filledCells, int size) {
    final result = List<KakuroCell>.from(filledCells);

    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final idx = r * size + c;
        if (filledCells[idx].type != KakuroCellType.black) continue;

        int? acrossHint;
        int? downHint;

        if (c + 1 < size &&
            filledCells[r * size + c + 1].type == KakuroCellType.white) {
          var sum = 0;
          for (var cc = c + 1; cc < size; cc++) {
            if (filledCells[r * size + cc].type != KakuroCellType.white) break;
            sum += filledCells[r * size + cc].value;
          }
          acrossHint = sum;
        }

        if (r + 1 < size &&
            filledCells[(r + 1) * size + c].type == KakuroCellType.white) {
          var sum = 0;
          for (var rr = r + 1; rr < size; rr++) {
            if (filledCells[rr * size + c].type != KakuroCellType.white) break;
            sum += filledCells[rr * size + c].value;
          }
          downHint = sum;
        }

        if (acrossHint != null || downHint != null) {
          result[idx] =
              KakuroCell.black(acrossHint: acrossHint, downHint: downHint);
        }
      }
    }

    return KakuroBoard(rows: size, cols: size, cells: result);
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
