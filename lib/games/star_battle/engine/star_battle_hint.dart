import 'star_battle_board.dart';

/// Star Battle 힌트 결과
class StarBattleHintResult {
  /// 힌트 단계 (1~4)
  final int level;

  /// 대상 셀 행
  final int row;

  /// 대상 셀 열
  final int col;

  /// 정답 값 (level 4에서만 사용, 0(X) 또는 1(★))
  final int? value;

  /// 사용된 풀이 기법 설명 (level 3에서 사용)
  final String? technique;

  /// 강조할 행 인덱스 목록
  final List<int> highlightRows;

  /// 강조할 열 인덱스 목록
  final List<int> highlightCols;

  /// 강조할 영역 번호 목록
  final List<int> highlightRegions;

  /// 힌트 설명 메시지
  final String message;

  const StarBattleHintResult({
    required this.level,
    required this.row,
    required this.col,
    this.value,
    this.technique,
    this.highlightRows = const [],
    this.highlightCols = const [],
    this.highlightRegions = const [],
    this.message = '',
  });
}

/// Star Battle 힌트 엔진
/// 4단계 힌트를 제공하여 점진적으로 도움을 줌 (★ 기호 사용, 숫자 금지)
class StarBattleHintEngine {
  /// 힌트 제공
  /// [board]: 현재 보드 상태
  /// [solution]: 정답 보드
  /// [level]: 힌트 단계 (1~4)
  static StarBattleHintResult? getHint(
    StarBattleBoard board,
    StarBattleBoard solution, {
    int level = 1,
  }) {
    assert(level >= 1 && level <= 4, '힌트 레벨은 1~4 범위여야 합니다');

    // 힌트 대상 셀 찾기
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

  // ──────────────────────────────────────────────────────────────────
  // Level 1: 관련 영역/행/열 강조
  // ──────────────────────────────────────────────────────────────────

  static StarBattleHintResult _level1Hint(StarBattleBoard board, int row, int col) {
    final region = board.getRegion(row, col);
    return StarBattleHintResult(
      level: 1,
      row: row,
      col: col,
      highlightRows: [row],
      highlightCols: [col],
      highlightRegions: [region],
      message: '${row + 1}행, ${col + 1}열, 영역 ${region + 1}을 살펴보세요.',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 2: ★ 또는 X 여부 안내
  // ──────────────────────────────────────────────────────────────────

  static StarBattleHintResult _level2Hint(
    StarBattleBoard board,
    StarBattleBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final isStar = answer == 1;
    final region = board.getRegion(row, col);

    return StarBattleHintResult(
      level: 2,
      row: row,
      col: col,
      highlightRows: [row],
      highlightCols: [col],
      highlightRegions: [region],
      message: isStar
          ? '이 셀에는 ★를 배치해야 합니다.'
          : '이 셀에는 ★를 배치할 수 없습니다.',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 3: 풀이 기법 설명
  // ──────────────────────────────────────────────────────────────────

  static StarBattleHintResult _level3Hint(
    StarBattleBoard board,
    StarBattleBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final region = board.getRegion(row, col);
    final techniqueInfo = _detectTechnique(board, row, col, answer);

    return StarBattleHintResult(
      level: 3,
      row: row,
      col: col,
      value: answer,
      technique: techniqueInfo.technique,
      highlightRows: techniqueInfo.highlightRows,
      highlightCols: techniqueInfo.highlightCols,
      highlightRegions: [region],
      message: techniqueInfo.message,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 4: 정답 공개
  // ──────────────────────────────────────────────────────────────────

  static StarBattleHintResult _level4Hint(StarBattleBoard solution, int row, int col) {
    final answer = solution.getValue(row, col);
    return StarBattleHintResult(
      level: 4,
      row: row,
      col: col,
      value: answer,
      message: answer == 1 ? '정답은 ★ 입니다.' : '정답은 X 입니다.',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 유틸리티
  // ──────────────────────────────────────────────────────────────────

  /// 가장 쉬운 힌트 대상 셀 찾기
  static (int, int)? _findBestHintTarget(StarBattleBoard board, StarBattleBoard solution) {
    final size = board.size;

    // 1순위: 행/열/영역에서 별 수가 이미 충족되어 X를 확정할 수 있는 셀
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != -1) continue;
        if (_isForced(board, r, c) != null) return (r, c);
      }
    }

    // 2순위: 인접 제약으로 확정되는 셀
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != -1) continue;
        if (_isAdjacentForced(board, r, c)) return (r, c);
      }
    }

    // 3순위: 정답이 ★인 셀 우선
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != -1) continue;
        if (solution.getValue(r, c) == 1) return (r, c);
      }
    }

    // 4순위: 아무 빈칸
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) == -1) return (r, c);
      }
    }

    return null;
  }

  /// 강제 결정 가능 여부 (행/열/영역 별 수 충족 시 X 강제)
  static int? _isForced(StarBattleBoard board, int row, int col) {
    final size = board.size;
    final starCount = board.starCount;

    // 행에서 별 수가 이미 충족되면 X
    var rowStars = 0;
    for (var c = 0; c < size; c++) {
      if (board.getValue(row, c) == 1) rowStars++;
    }
    if (rowStars >= starCount) return 0;

    // 열에서 별 수가 이미 충족되면 X
    var colStars = 0;
    for (var r = 0; r < size; r++) {
      if (board.getValue(r, col) == 1) colStars++;
    }
    if (colStars >= starCount) return 0;

    // 영역에서 별 수가 이미 충족되면 X
    final region = board.getRegion(row, col);
    var regionStars = 0;
    for (var i = 0; i < board.cells.length; i++) {
      if (board.regions[i] == region && board.cells[i] == 1) regionStars++;
    }
    if (regionStars >= starCount) return 0;

    return null;
  }

  /// 인접 제약으로 강제되는지 (8방향 인접에 ★이 있으면 X)
  static bool _isAdjacentForced(StarBattleBoard board, int row, int col) {
    final size = board.size;
    for (final (dr, dc) in [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
      if (board.getValue(nr, nc) == 1) return true;
    }
    return false;
  }

  /// 기법 감지 및 설명 생성
  static _TechniqueInfo _detectTechnique(
    StarBattleBoard board, int row, int col, int answer,
  ) {
    final size = board.size;
    final starCount = board.starCount;
    final region = board.getRegion(row, col);

    if (answer == 0) {
      // X가 정답인 경우

      // 인접 ★ 때문
      if (_isAdjacentForced(board, row, col)) {
        return _TechniqueInfo(
          technique: '인접 제약',
          message: '이 셀의 8방향 인접 셀에 이미 ★가 있어서 ★를 배치할 수 없습니다.',
          highlightRows: [row],
          highlightCols: [col],
        );
      }

      // 행 충족
      var rowStars = 0;
      for (var c = 0; c < size; c++) {
        if (board.getValue(row, c) == 1) rowStars++;
      }
      if (rowStars >= starCount) {
        return _TechniqueInfo(
          technique: '행 ★ 충족',
          message: '${row + 1}행에 이미 ★가 $starCount개 있으므로 나머지는 모두 X입니다.',
          highlightRows: [row],
          highlightCols: [],
        );
      }

      // 열 충족
      var colStars = 0;
      for (var r = 0; r < size; r++) {
        if (board.getValue(r, col) == 1) colStars++;
      }
      if (colStars >= starCount) {
        return _TechniqueInfo(
          technique: '열 ★ 충족',
          message: '${col + 1}열에 이미 ★가 $starCount개 있으므로 나머지는 모두 X입니다.',
          highlightRows: [],
          highlightCols: [col],
        );
      }

      // 영역 충족
      var regionStars = 0;
      for (var i = 0; i < board.cells.length; i++) {
        if (board.regions[i] == region && board.cells[i] == 1) regionStars++;
      }
      if (regionStars >= starCount) {
        return _TechniqueInfo(
          technique: '영역 ★ 충족',
          message: '영역 ${region + 1}에 이미 ★가 $starCount개 있으므로 나머지는 모두 X입니다.',
          highlightRows: [],
          highlightCols: [],
        );
      }
    }

    // ★가 정답인 경우 또는 일반 추론
    return _TechniqueInfo(
      technique: '소거법',
      message: '행/열/영역의 제약을 모두 고려하면 이 셀은 ${answer == 1 ? "★" : "X"} 이어야 합니다.',
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
