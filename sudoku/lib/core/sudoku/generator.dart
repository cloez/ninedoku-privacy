import '../utils/seeded_random.dart';
import 'solver.dart';
import 'difficulty.dart';
import 'technique_analyzer.dart';

/// 스도쿠 퍼즐 생성기
class SudokuGenerator {
  /// 생성 타임아웃 (밀리초)
  static const int _timeoutMs = 3000;

  /// 최대 재시도 횟수
  static const int _maxRetries = 5;

  /// 퍼즐 생성 결과
  static ({List<List<int>> puzzle, List<List<int>> solution})? generate({
    required Difficulty difficulty,
    int? seed,
  }) {
    final random = seed != null ? SeededRandom(seed) : SeededRandom(DateTime.now().millisecondsSinceEpoch);
    final targetRange = difficulty.emptyCellRange;
    // 고난도일수록 재시도 횟수 증가 (생성 실패율이 높음)
    final retries = difficulty.code >= 4 ? _maxRetries * 2 : _maxRetries;

    for (var retry = 0; retry < retries; retry++) {
      final result = _tryGenerate(random, targetRange.$1, targetRange.$2);
      if (result != null) {
        if (_isDifficultyAcceptable(result.puzzle, difficulty)) {
          return result;
        }
        continue;
      }
    }

    // 모든 재시도 실패 시 더 쉬운 조건으로 fallback (음수 방어)
    final fallbackMin = (targetRange.$1 - 5).clamp(1, 80);
    return _tryGenerate(random, fallbackMin, targetRange.$1);
  }

  /// 단일 생성 시도
  static ({List<List<int>> puzzle, List<List<int>> solution})? _tryGenerate(
    SeededRandom random,
    int minEmpty,
    int maxEmpty,
  ) {
    final stopwatch = Stopwatch()..start();

    // 1. 완성된 유효 보드 생성
    final solution = _generateCompletedBoard(random);
    if (solution == null) return null;

    // 2. 셀 제거하여 퍼즐 생성
    final puzzle = _removeNumbers(
      solution: solution,
      random: random,
      minEmpty: minEmpty,
      maxEmpty: maxEmpty,
      stopwatch: stopwatch,
    );
    if (puzzle == null) return null;

    return (puzzle: puzzle, solution: solution);
  }

  /// 유효한 완성 보드 생성
  static List<List<int>>? _generateCompletedBoard(SeededRandom random) {
    final board = List.generate(9, (_) => List.filled(9, 0));

    // 대각선 3x3 박스를 먼저 랜덤으로 채움 (서로 독립적)
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
    if (_fillBoard(board, random)) {
      return board;
    }
    return null;
  }

  /// 백트래킹으로 보드 완성 (랜덤 순서로 시도)
  static bool _fillBoard(List<List<int>> board, SeededRandom random) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          final candidates = _getCandidates(board, r, c);
          random.shuffle(candidates);
          for (final num in candidates) {
            board[r][c] = num;
            if (_fillBoard(board, random)) return true;
            board[r][c] = 0;
          }
          return false;
        }
      }
    }
    return true;
  }

  /// 셀을 하나씩 제거하면서 유일해답 유지
  static List<List<int>>? _removeNumbers({
    required List<List<int>> solution,
    required SeededRandom random,
    required int minEmpty,
    required int maxEmpty,
    required Stopwatch stopwatch,
  }) {
    final puzzle = List.generate(9, (r) => List<int>.from(solution[r]));

    // 제거 후보 셀 목록 (랜덤 순서)
    final cells = <(int, int)>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        cells.add((r, c));
      }
    }
    random.shuffle(cells);

    var emptyCells = 0;

    for (final (r, c) in cells) {
      if (stopwatch.elapsedMilliseconds > _timeoutMs) break;
      if (emptyCells >= maxEmpty) break;

      final backup = puzzle[r][c];
      puzzle[r][c] = 0;

      if (SudokuSolver.hasUniqueSolution(puzzle)) {
        emptyCells++;
      } else {
        puzzle[r][c] = backup;
      }
    }

    if (emptyCells < minEmpty) return null;
    return puzzle;
  }

  /// 기법 기반 난이도 검증
  static bool _isDifficultyAcceptable(List<List<int>> puzzle, Difficulty requested) {
    final evaluated = TechniqueAnalyzer.evaluateDifficulty(puzzle);
    // 마스터: 기법 평가가 expert 이상이어야 함 (쉬운 퍼즐 방지)
    if (requested == Difficulty.master) {
      return evaluated.code >= Difficulty.expert.code;
    }
    // 전문가: 기법 평가가 hard 이상이어야 함
    if (requested == Difficulty.expert) {
      return evaluated.code >= Difficulty.hard.code;
    }
    final diff = (evaluated.code - requested.code).abs();
    return diff <= 1;
  }

  /// 특정 셀의 후보 숫자
  static List<int> _getCandidates(List<List<int>> board, int row, int col) {
    final used = List.filled(10, false);
    for (var c = 0; c < 9; c++) {
      if (board[row][c] != 0) used[board[row][c]] = true;
    }
    for (var r = 0; r < 9; r++) {
      if (board[r][col] != 0) used[board[r][col]] = true;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] != 0) used[board[r][c]] = true;
      }
    }
    return [for (var n = 1; n <= 9; n++) if (!used[n]) n];
  }
}
