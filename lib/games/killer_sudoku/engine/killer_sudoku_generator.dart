import '../../../core/utils/seeded_random.dart';
import 'killer_sudoku_board.dart';
import 'killer_sudoku_solver.dart';

/// 킬러 스도쿠 난이도
enum KillerDifficulty {
  beginner, // 일부 셀 미리 제공 + 작은 케이지
  easy, // 소수 힌트 + 보통 케이지
  medium, // 힌트 없음 + 케이지만으로
  hard, // 큰 케이지
  master, // 복합 케이지
}

/// 킬러 스도쿠 생성 결과
class KillerSudokuGeneratorResult {
  final KillerSudokuBoard board;
  final List<List<int>> solution;
  final List<Cage> cages;

  const KillerSudokuGeneratorResult({
    required this.board,
    required this.solution,
    required this.cages,
  });
}

/// 킬러 스도쿠 퍼즐 생성기
class KillerSudokuGenerator {
  /// 전체 생성 시간 한도 (3초 미만 응답 보장)
  static const Duration _maxDuration = Duration(milliseconds: 2500);

  /// countSolutions 호출당 시간 한도 (백트래킹 폭주 방지)
  static const Duration _countTimeLimit = Duration(milliseconds: 800);

  /// 퍼즐 생성
  static KillerSudokuGeneratorResult? generate({
    required KillerDifficulty difficulty,
    int? seed,
  }) {
    final random = SeededRandom(
      seed ?? DateTime.now().millisecondsSinceEpoch,
    );
    final stopwatch = Stopwatch()..start();

    // 1. 완성된 스도쿠 보드 생성
    final solution = _generateCompletedBoard(random);
    if (solution == null) return null;

    // 2. 케이지 분할 + 힌트 배치 + 유일해 검증
    // 시간 기반 재시도: 전체 2.5초 한도 내에서 유일해 후보를 찾는다.
    // 시간 초과 시 마지막 후보를 그대로 사용 (best-effort fallback)
    // — 유일해 보장은 best-effort이며, 풀이 가능한 퍼즐은 반드시 반환.
    final cageConfig = _cageConfigForDifficulty(difficulty);
    final hintCount = _hintCountForDifficulty(difficulty);
    List<Cage>? cages;
    List<List<int>>? bestCells;
    List<List<bool>>? bestFixed;

    while (stopwatch.elapsed < _maxDuration) {
      final candidateCages = _generateCages(solution, random, cageConfig);
      if (candidateCages == null) continue;

      // 힌트 셀을 우선 결정 (검증에도 사용)
      final isFixed = List.generate(9, (_) => List.filled(9, false));
      final cells = List.generate(9, (_) => List.filled(9, 0));
      if (hintCount > 0) {
        final allPositions = <(int, int)>[];
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            allPositions.add((r, c));
          }
        }
        random.shuffle(allPositions);
        for (var i = 0; i < hintCount && i < allPositions.length; i++) {
          final (r, c) = allPositions[i];
          cells[r][c] = solution[r][c];
          isFixed[r][c] = true;
        }
      }

      // 마지막 후보 백업 (fallback)
      bestCells = cells;
      bestFixed = isFixed;
      cages = candidateCages;

      // 남은 시간이 부족하면 검증 생략하고 마지막 후보 사용
      final remaining = _maxDuration - stopwatch.elapsed;
      if (remaining <= Duration.zero) break;

      // countSolutions에 시간 한도를 전달하여 백트래킹 폭주 방지.
      // 시간 초과 시 함수는 현재까지 카운트된 값(0 또는 1)을 반환하므로,
      // 우연히 1이 반환되면 유일해로 간주하고 종료 (best-effort).
      final perCallLimit =
          remaining < _countTimeLimit ? remaining : _countTimeLimit;
      final solutionCount = KillerSudokuSolver.countSolutions(
        cells,
        candidateCages,
        limit: 2,
        timeout: stopwatch,
        timeLimit: stopwatch.elapsed + perCallLimit,
      );
      if (solutionCount == 1) {
        break;
      }
    }
    if (cages == null || bestCells == null || bestFixed == null) return null;

    final cells = bestCells;
    final isFixed = bestFixed;

    final board = KillerSudokuBoard(
      cells: cells,
      solution: solution,
      cages: cages,
      isFixed: isFixed,
    );

    return KillerSudokuGeneratorResult(
      board: board,
      solution: solution,
      cages: cages,
    );
  }

  /// 완성된 유효 보드 생성 (스도쿠 규칙)
  static List<List<int>>? _generateCompletedBoard(SeededRandom random) {
    final board = List.generate(9, (_) => List.filled(9, 0));

    // 대각선 3x3 박스를 먼저 랜덤으로 채움
    for (var box = 0; box < 3; box++) {
      final nums = [1, 2, 3, 4, 5, 6, 7, 8, 9];
      random.shuffle(nums);
      var idx = 0;
      for (var r = box * 3; r < box * 3 + 3; r++) {
        for (var c = box * 3; c < box * 3 + 3; c++) {
          board[r][c] = nums[idx++];
        }
      }
    }

    // 나머지를 풀이기로 채움
    if (_fillBoard(board, random)) return board;
    return null;
  }

  /// 백트래킹으로 보드 채우기
  static bool _fillBoard(List<List<int>> board, SeededRandom random) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != 0) continue;

        final candidates = <int>[];
        for (var v = 1; v <= 9; v++) {
          if (_canPlaceSudoku(board, r, c, v)) {
            candidates.add(v);
          }
        }
        random.shuffle(candidates);

        for (final v in candidates) {
          board[r][c] = v;
          if (_fillBoard(board, random)) return true;
          board[r][c] = 0;
        }
        return false;
      }
    }
    return true;
  }

  /// 스도쿠 규칙으로 값 배치 가능 여부
  static bool _canPlaceSudoku(
    List<List<int>> board,
    int row,
    int col,
    int value,
  ) {
    for (var c = 0; c < 9; c++) {
      if (board[row][c] == value) return false;
    }
    for (var r = 0; r < 9; r++) {
      if (board[r][col] == value) return false;
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = br; r < br + 3; r++) {
      for (var c = bc; c < bc + 3; c++) {
        if (board[r][c] == value) return false;
      }
    }
    return true;
  }

  /// 케이지 생성 (랜덤 분할)
  static List<Cage>? _generateCages(
    List<List<int>> solution,
    SeededRandom random,
    ({int minSize, int maxSize}) config,
  ) {
    final assigned = List.generate(9, (_) => List.filled(9, false));
    final cages = <Cage>[];

    // 모든 셀을 순회하며 케이지 할당
    final allCells = <(int, int)>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        allCells.add((r, c));
      }
    }
    random.shuffle(allCells);

    for (final start in allCells) {
      if (assigned[start.$1][start.$2]) continue;

      // BFS로 인접 셀 확장하여 케이지 생성
      final targetSize =
          config.minSize + random.nextInt(config.maxSize - config.minSize + 1);
      final cageCells = <(int, int)>[start];
      assigned[start.$1][start.$2] = true;

      final frontier = <(int, int)>[];
      _addNeighbors(start, frontier, assigned);

      while (cageCells.length < targetSize && frontier.isNotEmpty) {
        // 랜덤 선택
        final idx = random.nextInt(frontier.length);
        final next = frontier[idx];
        frontier.removeAt(idx);

        if (assigned[next.$1][next.$2]) continue;

        // 케이지 내 중복 값 방지
        final nextVal = solution[next.$1][next.$2];
        final hasDup = cageCells.any(
          (c) => solution[c.$1][c.$2] == nextVal,
        );
        if (hasDup) continue;

        cageCells.add(next);
        assigned[next.$1][next.$2] = true;
        _addNeighbors(next, frontier, assigned);
      }

      // 케이지 합계 계산
      var sum = 0;
      for (final cell in cageCells) {
        sum += solution[cell.$1][cell.$2];
      }
      cages.add(Cage(cells: cageCells, sum: sum));
    }

    // 모든 셀이 할당되었는지 확인
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (!assigned[r][c]) return null;
      }
    }

    return cages;
  }

  /// 인접 셀을 프론티어에 추가
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

  /// 난이도별 케이지 크기 설정
  static ({int minSize, int maxSize}) _cageConfigForDifficulty(
    KillerDifficulty difficulty,
  ) {
    switch (difficulty) {
      case KillerDifficulty.beginner:
        return (minSize: 2, maxSize: 3);
      case KillerDifficulty.easy:
        return (minSize: 2, maxSize: 3);
      case KillerDifficulty.medium:
        return (minSize: 2, maxSize: 4);
      case KillerDifficulty.hard:
        return (minSize: 2, maxSize: 5);
      case KillerDifficulty.master:
        return (minSize: 3, maxSize: 5);
    }
  }

  /// 난이도별 힌트 셀 수
  static int _hintCountForDifficulty(KillerDifficulty difficulty) {
    switch (difficulty) {
      case KillerDifficulty.beginner:
        return 15; // 일부 셀 미리 제공
      case KillerDifficulty.easy:
        return 8; // 소수 힌트
      case KillerDifficulty.medium:
        return 0; // 힌트 없음
      case KillerDifficulty.hard:
        return 0;
      case KillerDifficulty.master:
        return 0;
    }
  }
}
