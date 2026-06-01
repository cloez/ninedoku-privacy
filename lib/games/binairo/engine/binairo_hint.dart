import 'binairo_board.dart';

/// 값(0/1)을 원형 기호로 변환하는 헬퍼
String _symbol(int value) => value == 0 ? '●' : '○';

/// Binairo 힌트 결과
class BinairoHintResult {
  /// 힌트 단계 (1~4)
  final int level;

  /// 대상 셀 행
  final int row;

  /// 대상 셀 열
  final int col;

  /// 정답 값 (level 4에서만 사용, 0 또는 1)
  final int? value;

  /// 해당 셀에 가능한 후보 값 (level 2에서 사용)
  final List<int> candidates;

  /// 사용된 풀이 기법 설명 (level 3에서 사용)
  final String? technique;

  /// 강조할 행 인덱스 목록 (level 1에서 사용)
  final List<int> highlightRows;

  /// 강조할 열 인덱스 목록 (level 1에서 사용)
  final List<int> highlightCols;

  /// 힌트 설명 메시지
  final String message;

  const BinairoHintResult({
    required this.level,
    required this.row,
    required this.col,
    this.value,
    this.candidates = const [],
    this.technique,
    this.highlightRows = const [],
    this.highlightCols = const [],
    this.message = '',
  });
}

/// Binairo 힌트 엔진
/// 4단계 힌트를 제공하여 점진적으로 도움을 줌
class BinairoHintEngine {
  /// 힌트 제공
  /// [board]: 현재 보드 상태
  /// [solution]: 정답 보드
  /// [level]: 힌트 단계 (1~4)
  static BinairoHintResult? getHint(
    BinairoBoard board,
    BinairoBoard solution, {
    int level = 1,
  }) {
    assert(level >= 1 && level <= 4, '힌트 레벨은 1~4 범위여야 합니다');

    // 풀 수 있는 셀 찾기 (기법 기반 우선, 없으면 아무 빈칸)
    final target = _findBestHintTarget(board, solution);
    if (target == null) return null; // 빈칸 없음

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
  // Level 1: 풀 수 있는 셀의 행/열 강조
  // ──────────────────────────────────────────────────────────────────

  static BinairoHintResult _level1Hint(BinairoBoard board, int row, int col) {
    return BinairoHintResult(
      level: 1,
      row: row,
      col: col,
      highlightRows: [row],
      highlightCols: [col],
      message: '${row + 1}행, ${col + 1}열을 살펴보세요.',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 2: 해당 셀에 가능한 값 표시
  // ──────────────────────────────────────────────────────────────────

  static BinairoHintResult _level2Hint(
    BinairoBoard board,
    BinairoBoard solution,
    int row,
    int col,
  ) {
    final candidates = _getCandidates(board, row, col);
    final candidateStr = candidates.map((v) => _symbol(v)).join(', ');

    return BinairoHintResult(
      level: 2,
      row: row,
      col: col,
      candidates: candidates,
      highlightRows: [row],
      highlightCols: [col],
      message: '이 셀에 가능한 값: $candidateStr',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 3: 사용된 풀이 기법 설명
  // ──────────────────────────────────────────────────────────────────

  static BinairoHintResult _level3Hint(
    BinairoBoard board,
    BinairoBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final techniqueInfo = _detectTechnique(board, row, col, answer);

    return BinairoHintResult(
      level: 3,
      row: row,
      col: col,
      value: answer,
      candidates: _getCandidates(board, row, col),
      technique: techniqueInfo.technique,
      highlightRows: techniqueInfo.highlightRows,
      highlightCols: techniqueInfo.highlightCols,
      message: techniqueInfo.message,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 4: 정답 공개
  // ──────────────────────────────────────────────────────────────────

  static BinairoHintResult _level4Hint(BinairoBoard solution, int row, int col) {
    final answer = solution.getValue(row, col);
    return BinairoHintResult(
      level: 4,
      row: row,
      col: col,
      value: answer,
      message: '정답은 ${_symbol(answer)} 입니다.',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 유틸리티
  // ──────────────────────────────────────────────────────────────────

  /// 가장 쉬운 힌트 대상 셀 찾기
  /// 기법으로 풀 수 있는 셀 우선, 없으면 첫 빈칸
  static (int, int)? _findBestHintTarget(BinairoBoard board, BinairoBoard solution) {
    final size = board.size;

    // 1순위: 3연속 규칙으로 즉시 결정 가능한 셀
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != -1) continue;
        final forced = _checkTripleForced(board, r, c);
        if (forced != null) return (r, c);
      }
    }

    // 2순위: 균형 규칙으로 즉시 결정 가능한 셀
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != -1) continue;
        final forced = _checkBalanceForced(board, r, c);
        if (forced != null) return (r, c);
      }
    }

    // 3순위: 후보가 1개인 셀
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != -1) continue;
        final candidates = _getCandidates(board, r, c);
        if (candidates.length == 1) return (r, c);
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

  /// 해당 셀에 놓을 수 있는 후보 값 (규칙 기반 소거)
  static List<int> _getCandidates(BinairoBoard board, int row, int col) {
    final size = board.size;
    final half = size ~/ 2;
    final candidates = <int>[];

    for (var v = 0; v <= 1; v++) {
      var valid = true;

      // 3연속 검사 (행)
      // 왼쪽 2개가 같은 값
      if (col >= 2 &&
          board.getValue(row, col - 1) == v &&
          board.getValue(row, col - 2) == v) {
        valid = false;
      }
      // 양쪽이 같은 값
      if (valid && col >= 1 && col < size - 1 &&
          board.getValue(row, col - 1) == v &&
          board.getValue(row, col + 1) == v) {
        valid = false;
      }
      // 오른쪽 2개가 같은 값
      if (valid && col < size - 2 &&
          board.getValue(row, col + 1) == v &&
          board.getValue(row, col + 2) == v) {
        valid = false;
      }

      // 3연속 검사 (열)
      if (valid && row >= 2 &&
          board.getValue(row - 1, col) == v &&
          board.getValue(row - 2, col) == v) {
        valid = false;
      }
      if (valid && row >= 1 && row < size - 1 &&
          board.getValue(row - 1, col) == v &&
          board.getValue(row + 1, col) == v) {
        valid = false;
      }
      if (valid && row < size - 2 &&
          board.getValue(row + 1, col) == v &&
          board.getValue(row + 2, col) == v) {
        valid = false;
      }

      // 균형 검사 (행에서 v 개수가 이미 절반이면 불가)
      if (valid) {
        var rowCount = 0;
        for (var c = 0; c < size; c++) {
          if (board.getValue(row, c) == v) rowCount++;
        }
        if (rowCount >= half) valid = false;
      }

      // 균형 검사 (열에서 v 개수가 이미 절반이면 불가)
      if (valid) {
        var colCount = 0;
        for (var r = 0; r < size; r++) {
          if (board.getValue(r, col) == v) colCount++;
        }
        if (colCount >= half) valid = false;
      }

      if (valid) candidates.add(v);
    }
    return candidates;
  }

  /// 3연속 규칙으로 강제 결정되는 값 확인
  /// XX. → 반대 값 / X.X → 반대 값 / .XX → 반대 값
  static int? _checkTripleForced(BinairoBoard board, int row, int col) {
    final size = board.size;

    // 행 방향 검사
    // 왼쪽 2개 같은 값 → 반대 값 강제
    if (col >= 2) {
      final a = board.getValue(row, col - 2);
      final b = board.getValue(row, col - 1);
      if (a != -1 && a == b) return 1 - a;
    }
    // 양쪽 같은 값 → 반대 값 강제
    if (col >= 1 && col < size - 1) {
      final left = board.getValue(row, col - 1);
      final right = board.getValue(row, col + 1);
      if (left != -1 && left == right) return 1 - left;
    }
    // 오른쪽 2개 같은 값 → 반대 값 강제
    if (col < size - 2) {
      final a = board.getValue(row, col + 1);
      final b = board.getValue(row, col + 2);
      if (a != -1 && a == b) return 1 - a;
    }

    // 열 방향 검사
    if (row >= 2) {
      final a = board.getValue(row - 2, col);
      final b = board.getValue(row - 1, col);
      if (a != -1 && a == b) return 1 - a;
    }
    if (row >= 1 && row < size - 1) {
      final up = board.getValue(row - 1, col);
      final down = board.getValue(row + 1, col);
      if (up != -1 && up == down) return 1 - up;
    }
    if (row < size - 2) {
      final a = board.getValue(row + 1, col);
      final b = board.getValue(row + 2, col);
      if (a != -1 && a == b) return 1 - a;
    }

    return null;
  }

  /// 균형 규칙으로 강제 결정되는 값 확인
  /// 행/열에서 한쪽 값이 이미 절반이면 반대 값 강제
  static int? _checkBalanceForced(BinairoBoard board, int row, int col) {
    final size = board.size;
    final half = size ~/ 2;

    // 행 검사
    var rowZeros = 0;
    var rowOnes = 0;
    for (var c = 0; c < size; c++) {
      final v = board.getValue(row, c);
      if (v == 0) rowZeros++;
      if (v == 1) rowOnes++;
    }
    if (rowZeros >= half) return 1; // 0이 충분 → 1만 가능
    if (rowOnes >= half) return 0; // 1이 충분 → 0만 가능

    // 열 검사
    var colZeros = 0;
    var colOnes = 0;
    for (var r = 0; r < size; r++) {
      final v = board.getValue(r, col);
      if (v == 0) colZeros++;
      if (v == 1) colOnes++;
    }
    if (colZeros >= half) return 1;
    if (colOnes >= half) return 0;

    return null;
  }

  /// 기법 감지 및 설명 생성
  static _TechniqueInfo _detectTechnique(
    BinairoBoard board,
    int row,
    int col,
    int answer,
  ) {
    final size = board.size;

    // 1. 3연속 회피 기법
    final tripleForced = _checkTripleForced(board, row, col);
    if (tripleForced != null) {
      return _TechniqueInfo(
        technique: '3연속 회피',
        message: '이 셀 주변에 같은 원이 2개 연속입니다. '
            '3연속을 방지하려면 ${_symbol(answer)}을(를) 넣어야 합니다.',
        highlightRows: [row],
        highlightCols: [col],
      );
    }

    // 2. 균형 규칙 기법
    final balanceForced = _checkBalanceForced(board, row, col);
    if (balanceForced != null) {
      final half = size ~/ 2;
      final isRowForced = _isRowBalanceForced(board, row);
      final isColForced = _isColBalanceForced(board, col);

      if (isRowForced && isColForced) {
        return _TechniqueInfo(
          technique: '행/열 균형',
          message: '${row + 1}행과 ${col + 1}열 모두에서 ${_symbol(1 - answer)}이(가) 이미 $half개입니다. '
              '${_symbol(answer)}만 가능합니다.',
          highlightRows: [row],
          highlightCols: [col],
        );
      } else if (isRowForced) {
        return _TechniqueInfo(
          technique: '행 균형',
          message: '${row + 1}행에서 ${_symbol(1 - answer)}이(가) 이미 $half개입니다. '
              '이 셀은 ${_symbol(answer)} 이어야 합니다.',
          highlightRows: [row],
          highlightCols: [],
        );
      } else {
        return _TechniqueInfo(
          technique: '열 균형',
          message: '${col + 1}열에서 ${_symbol(1 - answer)}이(가) 이미 $half개입니다. '
              '이 셀은 ${_symbol(answer)} 이어야 합니다.',
          highlightRows: [],
          highlightCols: [col],
        );
      }
    }

    // 3. 소거법 (두 규칙 조합)
    final candidates = _getCandidates(board, row, col);
    if (candidates.length == 1) {
      return _TechniqueInfo(
        technique: '소거법',
        message: '3연속 규칙과 균형 규칙을 모두 적용하면 ${_symbol(answer)}만 가능합니다.',
        highlightRows: [row],
        highlightCols: [col],
      );
    }

    // 4. 고급 추론 (유일성 등)
    return _TechniqueInfo(
      technique: '고급 추론',
      message: '행/열의 패턴을 분석하면 이 셀은 ${_symbol(answer)} 이어야 합니다. '
          '유일성 규칙(동일 행/열 불가)을 고려해 보세요.',
      highlightRows: [row],
      highlightCols: [col],
    );
  }

  /// 행에서 균형 규칙으로 강제되는지
  static bool _isRowBalanceForced(BinairoBoard board, int row) {
    final size = board.size;
    final half = size ~/ 2;
    var zeros = 0;
    var ones = 0;
    for (var c = 0; c < size; c++) {
      final v = board.getValue(row, c);
      if (v == 0) zeros++;
      if (v == 1) ones++;
    }
    return zeros >= half || ones >= half;
  }

  /// 열에서 균형 규칙으로 강제되는지
  static bool _isColBalanceForced(BinairoBoard board, int col) {
    final size = board.size;
    final half = size ~/ 2;
    var zeros = 0;
    var ones = 0;
    for (var r = 0; r < size; r++) {
      final v = board.getValue(r, col);
      if (v == 0) zeros++;
      if (v == 1) ones++;
    }
    return zeros >= half || ones >= half;
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
