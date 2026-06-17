import 'skyscrapers_board.dart';
import 'skyscrapers_solver.dart';

/// Skyscrapers 힌트 결과
class SkyscrapersHintResult {
  /// 힌트 단계 (1~4)
  final int level;

  /// 대상 셀 행
  final int row;

  /// 대상 셀 열
  final int col;

  /// 정답 값 (level 4에서만 사용)
  final int? value;

  /// 해당 셀에 가능한 후보 값 (level 2에서 사용)
  final List<int> candidates;

  /// 사용된 풀이 기법 설명 (level 3에서 사용)
  final String? technique;

  /// 강조할 행 인덱스 목록
  final List<int> highlightRows;

  /// 강조할 열 인덱스 목록
  final List<int> highlightCols;

  /// 힌트 설명 메시지
  final String message;

  const SkyscrapersHintResult({
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

/// Skyscrapers 힌트 엔진
/// 4단계 힌트를 제공하여 점진적으로 도움을 줌
class SkyscrapersHintEngine {
  /// 힌트 제공
  static SkyscrapersHintResult? getHint(
    SkyscrapersBoard board,
    SkyscrapersBoard solution, {
    int level = 1,
  }) {
    assert(level >= 1 && level <= 4, '힌트 레벨은 1~4 범위여야 합니다');

    // 풀 수 있는 셀 찾기
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
  // Level 1: 풀 수 있는 셀의 행/열 강조
  // ──────────────────────────────────────────────────────────────────

  static SkyscrapersHintResult _level1Hint(
      SkyscrapersBoard board, int row, int col) {
    return SkyscrapersHintResult(
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

  static SkyscrapersHintResult _level2Hint(
    SkyscrapersBoard board,
    SkyscrapersBoard solution,
    int row,
    int col,
  ) {
    final candidates = getCandidates(board, row, col);
    final candidateStr = candidates.join(', ');

    return SkyscrapersHintResult(
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

  static SkyscrapersHintResult _level3Hint(
    SkyscrapersBoard board,
    SkyscrapersBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final candidates = getCandidates(board, row, col);
    final techniqueInfo = _detectTechnique(board, row, col, answer);

    return SkyscrapersHintResult(
      level: 3,
      row: row,
      col: col,
      value: answer,
      candidates: candidates,
      technique: techniqueInfo.technique,
      highlightRows: techniqueInfo.highlightRows,
      highlightCols: techniqueInfo.highlightCols,
      message: techniqueInfo.message,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 4: 정답 공개
  // ──────────────────────────────────────────────────────────────────

  static SkyscrapersHintResult _level4Hint(
      SkyscrapersBoard solution, int row, int col) {
    final answer = solution.getValue(row, col);
    return SkyscrapersHintResult(
      level: 4,
      row: row,
      col: col,
      value: answer,
      message: '정답은 $answer 입니다.',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 내부 유틸리티
  // ──────────────────────────────────────────────────────────────────

  /// 가장 쉬운 힌트 대상 셀 찾기
  static (int, int)? _findBestHintTarget(
      SkyscrapersBoard board, SkyscrapersBoard solution) {
    final size = board.size;

    // 1순위: 후보가 1개인 셀
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != 0) continue;
        final candidates = getCandidates(board, r, c);
        if (candidates.length == 1) return (r, c);
      }
    }

    // 2순위: 후보가 2개인 셀
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) != 0) continue;
        final candidates = getCandidates(board, r, c);
        if (candidates.length == 2) return (r, c);
      }
    }

    // 3순위: 아무 빈칸
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (board.getValue(r, c) == 0) return (r, c);
      }
    }

    return null;
  }

  /// 해당 셀에 놓을 수 있는 후보 값 (행/열 중복 + 가시성 소거)
  static List<int> getCandidates(SkyscrapersBoard board, int row, int col) {
    final size = board.size;
    final candidates = <int>[];

    for (var v = 1; v <= size; v++) {
      if (_canPlace(board, row, col, v)) {
        candidates.add(v);
      }
    }
    return candidates;
  }

  /// 특정 값을 놓을 수 있는지 검사
  static bool _canPlace(SkyscrapersBoard board, int row, int col, int value) {
    final size = board.size;

    // 행 중복
    for (var c = 0; c < size; c++) {
      if (c != col && board.getValue(row, c) == value) return false;
    }

    // 열 중복
    for (var r = 0; r < size; r++) {
      if (r != row && board.getValue(r, col) == value) return false;
    }

    // 임시로 값을 넣고 가시성 검사
    final testBoard = board.copyWith(
      cells: List<int>.from(board.cells)..[row * size + col] = value,
    );

    // 행 가시성 검사 (완성됐을 때만)
    final rowLine = <int>[];
    var rowComplete = true;
    for (var c = 0; c < size; c++) {
      final v = testBoard.getValue(row, c);
      rowLine.add(v);
      if (v == 0) rowComplete = false;
    }

    if (rowComplete) {
      final leftClue = board.leftClues[row];
      if (leftClue != 0 && SkyscrapersSolver.visibleCount(rowLine) != leftClue) {
        return false;
      }
      final rightClue = board.rightClues[row];
      if (rightClue != 0 &&
          SkyscrapersSolver.visibleCount(rowLine.reversed.toList()) != rightClue) {
        return false;
      }
    }

    // 열 가시성 검사 (완성됐을 때만)
    final colLine = <int>[];
    var colComplete = true;
    for (var r = 0; r < size; r++) {
      final v = testBoard.getValue(r, col);
      colLine.add(v);
      if (v == 0) colComplete = false;
    }

    if (colComplete) {
      final topClue = board.topClues[col];
      if (topClue != 0 && SkyscrapersSolver.visibleCount(colLine) != topClue) {
        return false;
      }
      final bottomClue = board.bottomClues[col];
      if (bottomClue != 0 &&
          SkyscrapersSolver.visibleCount(colLine.reversed.toList()) != bottomClue) {
        return false;
      }
    }

    return true;
  }

  /// 기법 감지 및 설명 생성
  static _TechniqueInfo _detectTechnique(
    SkyscrapersBoard board,
    int row,
    int col,
    int answer,
  ) {
    final candidates = getCandidates(board, row, col);
    final size = board.size;

    // 1. 후보가 1개 — 소거법
    if (candidates.length == 1) {
      return _TechniqueInfo(
        technique: '소거법',
        message: '행/열 중복과 가시성 규칙을 적용하면 $answer만 가능합니다.',
        highlightRows: [row],
        highlightCols: [col],
      );
    }

    // 2. 가시성 힌트로 추론
    final hasClue = board.topClues[col] != 0 ||
        board.bottomClues[col] != 0 ||
        board.leftClues[row] != 0 ||
        board.rightClues[row] != 0;

    if (hasClue) {
      // N이 보이면 첫 셀은 N (1이 보이면 첫 셀은 size)
      if (answer == size) {
        return _TechniqueInfo(
          technique: '가시성 추론',
          message: '외곽 힌트를 분석하면 이 위치에는 가장 높은 빌딩($size)이 와야 합니다.',
          highlightRows: [row],
          highlightCols: [col],
        );
      }

      return _TechniqueInfo(
        technique: '가시성 추론',
        message: '외곽 힌트와 행/열 규칙을 함께 고려하면 $answer이(가) 정답입니다.',
        highlightRows: [row],
        highlightCols: [col],
      );
    }

    // 3. 라틴 방진 규칙
    return _TechniqueInfo(
      technique: '라틴 방진',
      message: '행과 열에 이미 들어간 숫자를 소거하면 $answer만 남습니다.',
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
