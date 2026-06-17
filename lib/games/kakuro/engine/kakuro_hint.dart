import 'kakuro_board.dart';
import 'kakuro_solver.dart';

/// 카쿠로 힌트 결과
class KakuroHintResult {
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

  /// 강조할 블록 셀 좌표
  final List<(int, int)> highlightCells;

  /// 힌트 설명 메시지
  final String message;

  const KakuroHintResult({
    required this.level,
    required this.row,
    required this.col,
    this.value,
    this.candidates = const [],
    this.technique,
    this.highlightCells = const [],
    this.message = '',
  });
}

/// 카쿠로 힌트 엔진
/// 4단계 힌트를 제공하여 점진적으로 도움을 줌
class KakuroHintEngine {
  /// 힌트 제공
  static KakuroHintResult? getHint(
    KakuroBoard board,
    KakuroBoard solution, {
    int level = 1,
  }) {
    assert(level >= 1 && level <= 4, '힌트 레벨은 1~4 범위여야 합니다');

    final target = _findBestHintTarget(board, solution);
    if (target == null) return null;

    final (row, col) = target;

    switch (level) {
      case 1:
        return _level1Hint(board, row, col);
      case 2:
        return _level2Hint(board, row, col);
      case 3:
        return _level3Hint(board, solution, row, col);
      case 4:
        return _level4Hint(solution, row, col);
      default:
        return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 1: 풀 수 있는 셀의 블록 강조
  // ──────────────────────────────────────────────────────────────────

  static KakuroHintResult _level1Hint(KakuroBoard board, int row, int col) {
    // 이 셀이 속한 블록 셀들을 모두 강조
    final cellBlocks = board.blocksForCell(row, col);
    final highlightCells = <(int, int)>{};
    for (final block in cellBlocks) {
      highlightCells.addAll(block.cells);
    }

    return KakuroHintResult(
      level: 1,
      row: row,
      col: col,
      highlightCells: highlightCells.toList(),
      message: '${row + 1}행, ${col + 1}열의 블록을 살펴보세요.',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 2: 해당 셀에 가능한 값 표시
  // ──────────────────────────────────────────────────────────────────

  static KakuroHintResult _level2Hint(KakuroBoard board, int row, int col) {
    final candidates = KakuroSolver.getCandidates(board, row, col);
    final candidateStr = candidates.join(', ');

    final cellBlocks = board.blocksForCell(row, col);
    final highlightCells = <(int, int)>{};
    for (final block in cellBlocks) {
      highlightCells.addAll(block.cells);
    }

    return KakuroHintResult(
      level: 2,
      row: row,
      col: col,
      candidates: candidates,
      highlightCells: highlightCells.toList(),
      message: '이 셀에 가능한 값: $candidateStr',
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 3: 사용된 풀이 기법 설명
  // ──────────────────────────────────────────────────────────────────

  static KakuroHintResult _level3Hint(
    KakuroBoard board,
    KakuroBoard solution,
    int row,
    int col,
  ) {
    final answer = solution.getValue(row, col);
    final candidates = KakuroSolver.getCandidates(board, row, col);
    final techniqueInfo = _detectTechnique(board, row, col, answer);

    return KakuroHintResult(
      level: 3,
      row: row,
      col: col,
      value: answer,
      candidates: candidates,
      technique: techniqueInfo.technique,
      highlightCells: techniqueInfo.highlightCells,
      message: techniqueInfo.message,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Level 4: 정답 공개
  // ──────────────────────────────────────────────────────────────────

  static KakuroHintResult _level4Hint(KakuroBoard solution, int row, int col) {
    final answer = solution.getValue(row, col);
    return KakuroHintResult(
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
    KakuroBoard board,
    KakuroBoard solution,
  ) {
    // 1순위: 후보가 1개인 셀
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final cell = board.getCell(r, c);
        if (cell.type != KakuroCellType.white || cell.value != 0) continue;
        final candidates = KakuroSolver.getCandidates(board, r, c);
        if (candidates.length == 1) return (r, c);
      }
    }

    // 2순위: 후보가 2개인 셀
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final cell = board.getCell(r, c);
        if (cell.type != KakuroCellType.white || cell.value != 0) continue;
        final candidates = KakuroSolver.getCandidates(board, r, c);
        if (candidates.length == 2) return (r, c);
      }
    }

    // 3순위: 아무 빈 흰 셀
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        final cell = board.getCell(r, c);
        if (cell.type == KakuroCellType.white && cell.value == 0) return (r, c);
      }
    }

    return null;
  }

  /// 기법 감지 및 설명 생성
  static _TechniqueInfo _detectTechnique(
    KakuroBoard board,
    int row,
    int col,
    int answer,
  ) {
    final candidates = KakuroSolver.getCandidates(board, row, col);
    final cellBlocks = board.blocksForCell(row, col);
    final highlightCells = <(int, int)>{};
    for (final block in cellBlocks) {
      highlightCells.addAll(block.cells);
    }

    // 1. 후보가 1개 — 소거법
    if (candidates.length == 1) {
      return _TechniqueInfo(
        technique: '소거법',
        message: '블록 합계와 중복 규칙을 적용하면 $answer만 가능합니다.',
        highlightCells: highlightCells.toList(),
      );
    }

    // 2. 유일 조합 — 합계를 만들 수 있는 조합이 하나뿐
    for (final block in cellBlocks) {
      final emptyCount = block.cells.where((pos) =>
          board.getValue(pos.$1, pos.$2) == 0).length;
      if (emptyCount <= 2) {
        return _TechniqueInfo(
          technique: '조합 분석',
          message: '합계 ${block.sum}을 만들 수 있는 조합을 분석하면 $answer이(가) 정답입니다.',
          highlightCells: highlightCells.toList(),
        );
      }
    }

    // 3. 일반 추론
    return _TechniqueInfo(
      technique: '합계 추론',
      message: '블록 합계와 중복 제거를 조합하면 $answer이(가) 정답입니다.',
      highlightCells: highlightCells.toList(),
    );
  }
}

/// 기법 감지 결과 (내부용)
class _TechniqueInfo {
  final String technique;
  final String message;
  final List<(int, int)> highlightCells;

  const _TechniqueInfo({
    required this.technique,
    required this.message,
    this.highlightCells = const [],
  });
}
