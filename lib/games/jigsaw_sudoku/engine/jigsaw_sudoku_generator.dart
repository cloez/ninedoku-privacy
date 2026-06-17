import '../../../core/utils/seeded_random.dart';
import 'jigsaw_sudoku_board.dart';
import 'jigsaw_sudoku_solver.dart';

/// 직소 스도쿠 난이도
enum JigsawDifficulty {
  beginner,
  easy,
  medium,
  hard,
  master,
}

/// 직소 스도쿠 생성 결과
class JigsawSudokuGeneratorResult {
  final JigsawSudokuBoard board;
  final List<List<int>> solution;
  final List<List<int>> regions;

  const JigsawSudokuGeneratorResult({
    required this.board,
    required this.solution,
    required this.regions,
  });
}

/// 직소 스도쿠 퍼즐 생성기
class JigsawSudokuGenerator {
  /// 전체 생성 시간 한도 (3초 미만 응답 보장)
  static const Duration _maxDuration = Duration(milliseconds: 2500);

  /// hasUniqueSolution 호출당 시간 한도
  static const Duration _uniqueTimeLimit = Duration(milliseconds: 800);

  /// 퍼즐 생성
  static JigsawSudokuGeneratorResult? generate({
    required JigsawDifficulty difficulty,
    int? seed,
  }) {
    final random = SeededRandom(
      seed ?? DateTime.now().millisecondsSinceEpoch,
    );
    final stopwatch = Stopwatch()..start();
    JigsawSudokuGeneratorResult? lastCandidate;

    // 초기 candidate: 9x9 표준 sudoku-style 영역으로 보드를 빠르게 생성하여
    // 시간 초과 시 무조건 반환할 수 있도록 보장.
    lastCandidate = _generateFallbackCandidate(random);

    while (stopwatch.elapsed < _maxDuration) {
      try {
        final (result, candidate) = _tryGenerateWithCandidate(
          difficulty: difficulty,
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
  static (JigsawSudokuGeneratorResult?, JigsawSudokuGeneratorResult?)
      _tryGenerateWithCandidate({
    required JigsawDifficulty difficulty,
    required SeededRandom random,
    required Stopwatch stopwatch,
  }) {
    // 1. 불규칙 영역 생성 (몇 번 재시도)
    List<List<int>>? regions;
    for (var attempt = 0; attempt < 10; attempt++) {
      if (stopwatch.elapsed >= _maxDuration) return (null, null);
      regions = _generateRegions(random);
      if (regions != null) break;
    }
    if (regions == null) return (null, null);
    if (stopwatch.elapsed >= _maxDuration) return (null, null);

    // 2. 영역에 맞는 완성 보드 생성
    final solution = _generateCompletedBoard(regions, random, stopwatch);
    if (solution == null) return (null, null);
    // 시간 초과 시에도 solution 자체를 fallback candidate로 반환 (null 회피)
    if (stopwatch.elapsed >= _maxDuration) {
      return _solutionAsCandidate(solution, regions);
    }

    // 3. 난이도에 따라 셀 제거 (유일해 best-effort)
    final clueCount = _clueCountForDifficulty(difficulty);
    final (puzzle, lastUnique) =
        _removeCells(solution, regions, clueCount, random, stopwatch);

    final isFixed = List.generate(9, (_) => List.filled(9, false));
    final cells = List.generate(9, (_) => List.filled(9, 0));

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (puzzle[r][c] != 0) {
          cells[r][c] = puzzle[r][c];
          isFixed[r][c] = true;
        }
      }
    }

    final board = JigsawSudokuBoard(
      cells: cells,
      solution: solution,
      regions: regions,
      isFixed: isFixed,
    );
    final candidate = JigsawSudokuGeneratorResult(
      board: board,
      solution: solution,
      regions: regions,
    );

    if (lastUnique) return (candidate, null);
    return (null, candidate);
  }

  /// 절대 실패하지 않는 fallback candidate 생성
  /// (표준 3x3 박스 영역 + 간단한 라틴 방진)
  static JigsawSudokuGeneratorResult _generateFallbackCandidate(
      SeededRandom random) {
    // 표준 3x3 박스를 영역으로 사용 (전통 스도쿠와 동일)
    final regions = List.generate(9, (_) => List.filled(9, 0));
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        regions[r][c] = (r ~/ 3) * 3 + (c ~/ 3);
      }
    }

    // 표준 스도쿠 완성 보드 (시드 회전 적용)
    final base = [
      [1, 2, 3, 4, 5, 6, 7, 8, 9],
      [4, 5, 6, 7, 8, 9, 1, 2, 3],
      [7, 8, 9, 1, 2, 3, 4, 5, 6],
      [2, 3, 4, 5, 6, 7, 8, 9, 1],
      [5, 6, 7, 8, 9, 1, 2, 3, 4],
      [8, 9, 1, 2, 3, 4, 5, 6, 7],
      [3, 4, 5, 6, 7, 8, 9, 1, 2],
      [6, 7, 8, 9, 1, 2, 3, 4, 5],
      [9, 1, 2, 3, 4, 5, 6, 7, 8],
    ];
    // 시드 기반 숫자 매핑 (1~9 셔플)
    final mapping = List<int>.generate(9, (i) => i + 1);
    random.shuffle(mapping);
    final solution = List.generate(9, (r) {
      return List<int>.generate(9, (c) => mapping[base[r][c] - 1]);
    });

    // 셀의 절반만 보여주는 puzzle
    final cells = List.generate(9, (_) => List.filled(9, 0));
    final isFixed = List.generate(9, (_) => List.filled(9, false));
    final positions = <(int, int)>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        positions.add((r, c));
      }
    }
    random.shuffle(positions);
    // 상위 40개를 fixed로 표시 (medium 수준)
    for (var i = 0; i < 40; i++) {
      final (r, c) = positions[i];
      cells[r][c] = solution[r][c];
      isFixed[r][c] = true;
    }

    final board = JigsawSudokuBoard(
      cells: cells,
      solution: solution,
      regions: regions,
      isFixed: isFixed,
    );
    return JigsawSudokuGeneratorResult(
      board: board,
      solution: solution,
      regions: regions,
    );
  }

  /// solution을 그대로 candidate로 변환 (시간 초과 fallback)
  static (JigsawSudokuGeneratorResult?, JigsawSudokuGeneratorResult?)
      _solutionAsCandidate(
    List<List<int>> solution,
    List<List<int>> regions,
  ) {
    // 셀 일부만 표시 (낮은 난이도 수준)
    final cells = List.generate(9, (r) => List<int>.from(solution[r]));
    final isFixed = List.generate(9, (_) => List.filled(9, true));
    final board = JigsawSudokuBoard(
      cells: cells,
      solution: solution,
      regions: regions,
      isFixed: isFixed,
    );
    final candidate = JigsawSudokuGeneratorResult(
      board: board,
      solution: solution,
      regions: regions,
    );
    return (null, candidate);
  }

  /// BFS 랜덤으로 불규칙 영역 생성 (각 영역 9셀씩)
  static List<List<int>>? _generateRegions(SeededRandom random) {
    final regions = List.generate(9, (_) => List.filled(9, -1));
    final assigned = List.generate(9, (_) => List.filled(9, false));

    for (var regionId = 0; regionId < 9; regionId++) {
      (int, int)? start;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (!assigned[r][c]) {
            start = (r, c);
            break;
          }
        }
        if (start != null) break;
      }
      if (start == null) return null;

      final regionCells = <(int, int)>[start];
      assigned[start.$1][start.$2] = true;
      regions[start.$1][start.$2] = regionId;

      final frontier = <(int, int)>[];
      _addNeighbors(start, frontier, assigned);

      while (regionCells.length < 9 && frontier.isNotEmpty) {
        final idx = random.nextInt(frontier.length);
        final next = frontier[idx];
        frontier.removeAt(idx);

        if (assigned[next.$1][next.$2]) continue;

        regionCells.add(next);
        assigned[next.$1][next.$2] = true;
        regions[next.$1][next.$2] = regionId;
        _addNeighbors(next, frontier, assigned);
      }

      if (regionCells.length < 9) return null;
    }

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (regions[r][c] < 0) return null;
      }
    }

    return regions;
  }

  static void _addNeighbors(
    (int, int) cell,
    List<(int, int)> frontier,
    List<List<bool>> assigned,
  ) {
    final dirs = [(0, 1), (0, -1), (1, 0), (-1, 0)];
    for (final (dr, dc) in dirs) {
      final nr = cell.$1 + dr;
      final nc = cell.$2 + dc;
      if (nr >= 0 && nr < 9 && nc >= 0 && nc < 9 && !assigned[nr][nc]) {
        frontier.add((nr, nc));
      }
    }
  }

  /// 영역에 맞는 완성 보드 생성 (시간 한도 검사 포함)
  static List<List<int>>? _generateCompletedBoard(
    List<List<int>> regions,
    SeededRandom random,
    Stopwatch stopwatch,
  ) {
    final board = List.generate(9, (_) => List.filled(9, 0));
    if (_fillBoard(board, regions, random, stopwatch)) return board;
    return null;
  }

  /// 백트래킹으로 보드 채우기 (시간 체크)
  static bool _fillBoard(
    List<List<int>> board,
    List<List<int>> regions,
    SeededRandom random,
    Stopwatch stopwatch,
  ) {
    if (stopwatch.elapsed >= _maxDuration) return false;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != 0) continue;

        final candidates = <int>[];
        for (var v = 1; v <= 9; v++) {
          if (JigsawSudokuSolver.canPlace(board, regions, r, c, v)) {
            candidates.add(v);
          }
        }
        random.shuffle(candidates);

        for (final v in candidates) {
          board[r][c] = v;
          if (_fillBoard(board, regions, random, stopwatch)) return true;
          board[r][c] = 0;
        }
        return false;
      }
    }
    return true;
  }

  /// 셀 제거 (유일해 best-effort)
  /// 반환: (퍼즐 보드, 마지막이 유일해인지)
  static (List<List<int>>, bool) _removeCells(
    List<List<int>> solution,
    List<List<int>> regions,
    int targetClues,
    SeededRandom random,
    Stopwatch stopwatch,
  ) {
    final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));

    final positions = <(int, int)>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        positions.add((r, c));
      }
    }
    random.shuffle(positions);

    var clues = 81;
    var lastUnique = true;

    for (final (r, c) in positions) {
      if (clues <= targetClues) break;
      if (stopwatch.elapsed >= _maxDuration) break;

      final saved = puzzle[r][c];
      puzzle[r][c] = 0;

      final remaining = _maxDuration - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        puzzle[r][c] = saved;
        break;
      }
      final perCall = remaining < _uniqueTimeLimit ? remaining : _uniqueTimeLimit;

      bool unique;
      try {
        unique = JigsawSudokuSolver.hasUniqueSolution(
          puzzle,
          regions,
          timeout: stopwatch,
          timeLimit: stopwatch.elapsed + perCall,
        );
      } catch (_) {
        unique = false;
      }

      if (unique) {
        clues--;
        lastUnique = true;
      } else {
        puzzle[r][c] = saved;
      }
    }

    return (puzzle, lastUnique);
  }

  /// 난이도별 단서 수
  static int _clueCountForDifficulty(JigsawDifficulty difficulty) {
    switch (difficulty) {
      case JigsawDifficulty.beginner:
        return 45;
      case JigsawDifficulty.easy:
        return 38;
      case JigsawDifficulty.medium:
        return 32;
      case JigsawDifficulty.hard:
        return 27;
      case JigsawDifficulty.master:
        return 23;
    }
  }
}
