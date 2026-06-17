import 'light_up_board.dart';

/// Light Up 힌트 결과
class LightUpHintResult {
  /// 힌트 단계 (1~4)
  final int level;

  /// 대상 셀 행
  final int row;

  /// 대상 셀 열
  final int col;

  /// 정답 값 (level 4에서만 사용)
  final int? value;

  /// 사용된 풀이 기법 설명 (level 3)
  final String? technique;

  /// 강조할 행 인덱스 목록
  final List<int> highlightRows;

  /// 강조할 열 인덱스 목록
  final List<int> highlightCols;

  /// 힌트 설명 메시지
  final String message;

  const LightUpHintResult({
    required this.level,
    required this.row,
    required this.col,
    this.value,
    this.technique,
    this.highlightRows = const [],
    this.highlightCols = const [],
    this.message = '',
  });
}

/// Light Up 힌트 엔진
/// 4단계 힌트로 점진적 도움 제공
class LightUpHintEngine {
  /// 힌트 제공
  static LightUpHintResult? getHint(
    LightUpBoard board,
    LightUpBoard solution, {
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

  // Level 1: 위치 힌트 — 풀 수 있는 셀 영역 강조
  static LightUpHintResult _level1Hint(LightUpBoard board, int row, int col) {
    return LightUpHintResult(
      level: 1,
      row: row,
      col: col,
      highlightRows: [row],
      highlightCols: [col],
      message: '${row + 1}행, ${col + 1}열을 살펴보세요.',
    );
  }

  // Level 2: 가능한 값 힌트
  static LightUpHintResult _level2Hint(
    LightUpBoard board,
    LightUpBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final isBulbNeeded = answer == LightUpBoard.bulb;

    return LightUpHintResult(
      level: 2,
      row: row,
      col: col,
      highlightRows: [row],
      highlightCols: [col],
      message: isBulbNeeded
          ? '이 셀에 💡 전구가 필요합니다.'
          : '이 셀은 비워두어야 합니다 (다른 전구가 비출 것입니다).',
    );
  }

  // Level 3: 풀이 기법 설명
  static LightUpHintResult _level3Hint(
    LightUpBoard board,
    LightUpBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final techniqueInfo = _detectTechnique(board, row, col, answer);

    return LightUpHintResult(
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
  static LightUpHintResult _level4Hint(LightUpBoard solution, int row, int col) {
    final answer = solution.getValue(row, col);
    final symbol = answer == LightUpBoard.bulb ? '💡 전구' : '빈 칸';

    return LightUpHintResult(
      level: 4,
      row: row,
      col: col,
      value: answer,
      message: '정답은 $symbol입니다.',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 유틸리티
  // ──────────────────────────────────────────────────────────────────

  /// 가장 쉬운 힌트 대상 셀 찾기
  static (int, int)? _findBestHintTarget(
      LightUpBoard board, LightUpBoard solution) {
    final size = board.size;

    // 1순위: 숫자 벽 인접에서 강제되는 전구 위치
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final num = board.getWallNumber(r, c);
        if (num < 0) continue;

        // 인접 빈 칸과 전구 수 계산
        var adjBulbs = 0;
        var adjEmpty = 0;
        final emptyAdj = <(int, int)>[];

        for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
          final nr = r + dr;
          final nc = c + dc;
          if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
          if (board.isBulb(nr, nc)) {
            adjBulbs++;
          } else if (board.getValue(nr, nc) == LightUpBoard.empty) {
            adjEmpty++;
            emptyAdj.add((nr, nc));
          }
        }

        // 남은 칸 = 필요 전구 수 → 모두 전구
        if (adjEmpty > 0 && adjBulbs + adjEmpty == num) {
          return emptyAdj.first;
        }

        // 전구 수 충족 → 나머지는 빈칸 (X)
        if (adjEmpty > 0 && adjBulbs == num) {
          return emptyAdj.first;
        }
      }
    }

    // 2순위: 비춰지지 않은 칸 중 전구가 필요한 곳
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != LightUpBoard.empty) continue;
        if (solution.getValue(r, c) == LightUpBoard.bulb) return (r, c);
      }
    }

    // 3순위: 아무 빈 칸
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) == LightUpBoard.empty) return (r, c);
      }
    }

    return null;
  }

  /// 기법 감지
  static _TechniqueInfo _detectTechnique(
    LightUpBoard board,
    int row,
    int col,
    int answer,
  ) {
    final size = board.size;

    // 1. 숫자 벽 인접 강제
    for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final wr = row + dr;
      final wc = col + dc;
      if (wr < 0 || wr >= size || wc < 0 || wc >= size) continue;
      final num = board.getWallNumber(wr, wc);
      if (num < 0) continue;

      var adjBulbs = board.adjacentBulbCount(wr, wc);
      var adjEmpty = 0;
      for (final (dr2, dc2) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nr = wr + dr2;
        final nc = wc + dc2;
        if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
        if (board.getValue(nr, nc) == LightUpBoard.empty) adjEmpty++;
      }

      if (answer == LightUpBoard.bulb && adjBulbs + adjEmpty == num) {
        return _TechniqueInfo(
          technique: '벽 숫자 강제',
          message: '인접 벽($num)의 남은 빈 칸이 필요 전구 수와 같으므로 💡를 놓아야 합니다.',
          highlightRows: [wr],
          highlightCols: [wc],
        );
      }

      if (answer != LightUpBoard.bulb && adjBulbs == num) {
        return _TechniqueInfo(
          technique: '벽 숫자 충족',
          message: '인접 벽($num)에 이미 전구가 충분합니다. 이 칸은 비워야 합니다.',
          highlightRows: [wr],
          highlightCols: [wc],
        );
      }
    }

    // 2. 비춰지지 않은 칸 도달 불가
    if (answer == LightUpBoard.bulb) {
      if (!board.isLit(row, col)) {
        return _TechniqueInfo(
          technique: '미조명 셀 전구 필요',
          message: '이 칸은 다른 전구로 비출 수 없어 직접 💡를 놓아야 합니다.',
          highlightRows: [row],
          highlightCols: [col],
        );
      }
    }

    // 3. 충돌 방지
    if (answer != LightUpBoard.bulb) {
      return _TechniqueInfo(
        technique: '충돌 방지',
        message: '이 칸에 💡를 놓으면 다른 전구와 충돌합니다. 비워두세요.',
        highlightRows: [row],
        highlightCols: [col],
      );
    }

    // 4. 기본
    return _TechniqueInfo(
      technique: '논리 추론',
      message: answer == LightUpBoard.bulb
          ? '전체 규칙을 분석하면 이 셀에 💡가 필요합니다.'
          : '전체 규칙을 분석하면 이 셀은 비워야 합니다.',
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
