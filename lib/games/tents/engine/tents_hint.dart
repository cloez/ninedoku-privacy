import 'tents_board.dart';

/// Tents 힌트 결과
class TentsHintResult {
  /// 힌트 단계 (1~4)
  final int level;

  /// 대상 셀 행
  final int row;

  /// 대상 셀 열
  final int col;

  /// 정답 값 (level 4에서 사용, tent=2 또는 grass=3)
  final int? value;

  /// 강조할 행 인덱스 목록
  final List<int> highlightRows;

  /// 강조할 열 인덱스 목록
  final List<int> highlightCols;

  /// 힌트 설명 메시지
  final String message;

  /// 사용된 풀이 기법 설명 (level 3)
  final String? technique;

  const TentsHintResult({
    required this.level,
    required this.row,
    required this.col,
    this.value,
    this.highlightRows = const [],
    this.highlightCols = const [],
    this.message = '',
    this.technique,
  });
}

/// Tents 힌트 엔진
/// 4단계 힌트를 제공하여 점진적으로 도움
class TentsHintEngine {
  /// 힌트 제공
  static TentsHintResult? getHint(
    TentsBoard board,
    TentsBoard solution, {
    int level = 1,
  }) {
    assert(level >= 1 && level <= 4, '힌트 레벨은 1~4');

    final target = _findBestHintTarget(board, solution);
    if (target == null) return null;

    final (row, col) = target;

    switch (level) {
      case 1:
        return _level1Hint(board, row, col);
      case 2:
        return _level2Hint(board, solution, row, col);
      case 3:
        return _level3Hint(board, solution, row, col);
      case 4:
        return _level4Hint(solution, row, col);
      default:
        return null;
    }
  }

  // Level 1: 위치 강조
  static TentsHintResult _level1Hint(TentsBoard board, int row, int col) {
    return TentsHintResult(
      level: 1,
      row: row,
      col: col,
      highlightRows: [row],
      highlightCols: [col],
      message: '${row + 1}행, ${col + 1}열을 살펴보세요.',
    );
  }

  // Level 2: 가능한 값 힌트
  static TentsHintResult _level2Hint(
    TentsBoard board,
    TentsBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final symbol = answer == TentsBoard.tent ? '⛺' : '✕';
    return TentsHintResult(
      level: 2,
      row: row,
      col: col,
      highlightRows: [row],
      highlightCols: [col],
      message: '이 셀에는 $symbol을(를) 배치해야 합니다.',
    );
  }

  // Level 3: 풀이 기법 설명
  static TentsHintResult _level3Hint(
    TentsBoard board,
    TentsBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final techniqueInfo = _detectTechnique(board, row, col, answer);

    return TentsHintResult(
      level: 3,
      row: row,
      col: col,
      value: answer,
      technique: techniqueInfo.technique,
      highlightRows: techniqueInfo.highlightRows,
      highlightCols: techniqueInfo.highlightCols,
      message: techniqueInfo.message,
    );
  }

  // Level 4: 정답 공개 + 자동 입력
  static TentsHintResult _level4Hint(TentsBoard solution, int row, int col) {
    final answer = solution.getValue(row, col);
    final symbol = answer == TentsBoard.tent ? '⛺ 텐트' : '✕ 잔디';
    return TentsHintResult(
      level: 4,
      row: row,
      col: col,
      value: answer,
      message: '정답은 $symbol입니다.',
    );
  }

  /// 가장 쉬운 힌트 대상 셀 찾기
  static (int, int)? _findBestHintTarget(
    TentsBoard board,
    TentsBoard solution,
  ) {
    final size = board.size;

    // 1순위: 행/열 힌트 0인 곳의 빈칸 → 잔디 확정
    for (var r = 0; r < size; r++) {
      if (board.rowCounts[r] == 0) {
        for (var c = 0; c < size; c++) {
          if (_isPlayableEmpty(board, r, c)) return (r, c);
        }
      }
    }
    for (var c = 0; c < size; c++) {
      if (board.colCounts[c] == 0) {
        for (var r = 0; r < size; r++) {
          if (_isPlayableEmpty(board, r, c)) return (r, c);
        }
      }
    }

    // 2순위: 행/열 텐트 수가 이미 충족된 곳의 빈칸 → 잔디 확정
    for (var r = 0; r < size; r++) {
      if (board.currentRowTents(r) >= board.rowCounts[r]) {
        for (var c = 0; c < size; c++) {
          if (_isPlayableEmpty(board, r, c)) return (r, c);
        }
      }
    }
    for (var c = 0; c < size; c++) {
      if (board.currentColTents(c) >= board.colCounts[c]) {
        for (var r = 0; r < size; r++) {
          if (_isPlayableEmpty(board, r, c)) return (r, c);
        }
      }
    }

    // 3순위: 나무 옆이 아닌 빈칸 → 잔디 확정
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (!_isPlayableEmpty(board, r, c)) continue;
        if (!_hasAdjacentTree(board, r, c)) return (r, c);
      }
    }

    // 4순위: 아무 빈칸
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_isPlayableEmpty(board, r, c)) return (r, c);
      }
    }

    return null;
  }

  /// 플레이 가능한 빈칸인지
  static bool _isPlayableEmpty(TentsBoard board, int row, int col) {
    final idx = row * board.size + col;
    return !board.treePositions.contains(idx) &&
        board.cells[idx] == TentsBoard.empty;
  }

  /// 인접 나무 존재 여부
  static bool _hasAdjacentTree(TentsBoard board, int row, int col) {
    for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr >= 0 && nr < board.size && nc >= 0 && nc < board.size) {
        if (board.cells[nr * board.size + nc] == TentsBoard.tree) return true;
      }
    }
    return false;
  }

  /// 기법 감지
  static _TechniqueInfo _detectTechnique(
    TentsBoard board,
    int row,
    int col,
    int answer,
  ) {
    // 1. 행/열 힌트가 0 → 잔디 확정
    if (board.rowCounts[row] == 0 || board.colCounts[col] == 0) {
      return _TechniqueInfo(
        technique: '힌트 수 0',
        message: '이 행 또는 열의 텐트 수가 0이므로 잔디(✕)를 배치합니다.',
        highlightRows: [row],
        highlightCols: [col],
      );
    }

    // 2. 행/열 텐트 수 충족 → 잔디
    if (answer == TentsBoard.grass) {
      if (board.currentRowTents(row) >= board.rowCounts[row]) {
        return _TechniqueInfo(
          technique: '행 텐트 충족',
          message: '${row + 1}행에 이미 ${board.rowCounts[row]}개 텐트가 있으므로 나머지는 잔디(✕)입니다.',
          highlightRows: [row],
          highlightCols: [],
        );
      }
      if (board.currentColTents(col) >= board.colCounts[col]) {
        return _TechniqueInfo(
          technique: '열 텐트 충족',
          message: '${col + 1}열에 이미 ${board.colCounts[col]}개 텐트가 있으므로 나머지는 잔디(✕)입니다.',
          highlightRows: [],
          highlightCols: [col],
        );
      }
      if (!_hasAdjacentTree(board, row, col)) {
        return _TechniqueInfo(
          technique: '나무 미인접',
          message: '이 셀 주변(상하좌우)에 나무가 없으므로 텐트를 놓을 수 없습니다.',
          highlightRows: [row],
          highlightCols: [col],
        );
      }
    }

    // 3. 텐트 배치
    if (answer == TentsBoard.tent) {
      return _TechniqueInfo(
        technique: '나무 매칭',
        message: '인접한 나무(🌲)와 매칭하여 텐트(⛺)를 배치합니다.',
        highlightRows: [row],
        highlightCols: [col],
      );
    }

    // 기본
    return _TechniqueInfo(
      technique: '논리 추론',
      message: '행/열 힌트와 인접 규칙을 종합하면 이 셀의 값을 결정할 수 있습니다.',
      highlightRows: [row],
      highlightCols: [col],
    );
  }
}

/// 기법 감지 결과 (내부용)
class _TechniqueInfo {
  final String technique;
  final String message;
  final List<int> highlightRows;
  final List<int> highlightCols;

  const _TechniqueInfo({
    required this.technique,
    required this.message,
    this.highlightRows = const [],
    this.highlightCols = const [],
  });
}
