import 'board.dart';
import 'technique_analyzer.dart';

/// 힌트 단계
enum HintLevel {
  /// 1단계: 풀 수 있는 셀의 영역(행/열/박스) 강조
  highlightRegion,

  /// 2단계: 후보 숫자 안내
  showCandidates,

  /// 3단계: 풀이 기법 설명 (제외 이유)
  explainTechnique,

  /// 4단계: 정답 공개
  revealAnswer,
}

/// 힌트 결과
class HintResult {
  /// 힌트 대상 셀 좌표
  final int row;
  final int col;

  /// 힌트 단계
  final HintLevel level;

  /// 정답 값 (revealAnswer 단계에서만 사용)
  final int? answer;

  /// 후보 숫자 목록 (showCandidates 단계에서 사용)
  final Set<int> candidates;

  /// 강조할 영역 셀 목록 (highlightRegion 단계에서 사용)
  final List<(int, int)> highlightCells;

  /// 사용된 풀이 기법 (explainTechnique 단계에서 사용)
  final SolvingTechnique? technique;

  /// 힌트 설명 메시지
  final String message;

  const HintResult({
    required this.row,
    required this.col,
    required this.level,
    this.answer,
    this.candidates = const {},
    this.highlightCells = const [],
    this.technique,
    this.message = '',
  });
}

/// 힌트 엔진 (4단계 힌트 지원)
class HintEngine {
  /// 힌트 제공 (targetCell 지정 시 해당 셀에 대한 힌트, 미지정 시 가장 쉬운 셀)
  static HintResult? getHint({
    required SudokuBoard board,
    required HintLevel level,
    (int, int)? targetCell,
  }) {
    final (int, int)? target;
    if (targetCell != null && board.currentBoard[targetCell.$1][targetCell.$2] == 0) {
      target = targetCell;
    } else {
      target = _findEasiestEmptyCell(board);
    }
    if (target == null) return null;

    final (row, col) = target;

    switch (level) {
      case HintLevel.highlightRegion:
        return _highlightRegionHint(board, row, col);
      case HintLevel.showCandidates:
        return _showCandidatesHint(board, row, col);
      case HintLevel.explainTechnique:
        return _explainTechniqueHint(board, row, col);
      case HintLevel.revealAnswer:
        return _revealAnswerHint(board, row, col);
    }
  }

  /// 후보 숫자가 가장 적은 빈 셀 찾기
  static (int, int)? _findEasiestEmptyCell(SudokuBoard board) {
    int minCandidates = 10;
    (int, int)? bestCell;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.currentBoard[r][c] == 0) {
          final count = _getCandidateCount(board.currentBoard, r, c);
          if (count > 0 && count < minCandidates) {
            minCandidates = count;
            bestCell = (r, c);
            if (count == 1) return bestCell;
          }
        }
      }
    }
    return bestCell;
  }

  /// 특정 셀의 후보 숫자 개수
  static int _getCandidateCount(List<List<int>> board, int row, int col) {
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
    var count = 0;
    for (var n = 1; n <= 9; n++) {
      if (!used[n]) count++;
    }
    return count;
  }

  /// 1단계: 영역 강조 힌트
  static HintResult _highlightRegionHint(SudokuBoard board, int row, int col) {
    final cells = <(int, int)>[];
    // 같은 행
    for (var c = 0; c < 9; c++) {
      cells.add((row, c));
    }
    // 같은 열
    for (var r = 0; r < 9; r++) {
      if (r != row) cells.add((r, col));
    }
    // 같은 박스
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (r != row || c != col) {
          if (!cells.contains((r, c))) cells.add((r, c));
        }
      }
    }

    return HintResult(
      row: row,
      col: col,
      level: HintLevel.highlightRegion,
      highlightCells: cells,
      message: '이 셀의 행, 열, 박스를 살펴보세요',
    );
  }

  /// 2단계: 후보 숫자 안내 힌트
  static HintResult _showCandidatesHint(SudokuBoard board, int row, int col) {
    final candidates = _getCandidateSet(board.currentBoard, row, col);
    return HintResult(
      row: row,
      col: col,
      level: HintLevel.showCandidates,
      candidates: candidates,
      message: '이 셀에 가능한 숫자: ${candidates.toList()..sort()}',
    );
  }

  /// 3단계: 풀이 기법 설명 힌트 (대상 셀 일치 시 기법 설명, 불일치 시 가이드 제공)
  static HintResult _explainTechniqueHint(SudokuBoard board, int row, int col) {
    final techniqueResult = TechniqueAnalyzer.findNextTechnique(board.currentBoard);
    // 기법이 발견되고 대상 셀과 일치하는 경우 기법 힌트 제공
    if (techniqueResult != null &&
        techniqueResult.row == row &&
        techniqueResult.col == col) {
      return HintResult(
        row: row,
        col: col,
        level: HintLevel.explainTechnique,
        technique: techniqueResult.technique,
        candidates: techniqueResult.value != null ? {techniqueResult.value!} : {},
        message: techniqueResult.explanation,
      );
    }

    // 대상 셀에 해당하는 기법이 없으면 후보 기반 설명 + 더 쉬운 셀 안내
    final candidates = _getCandidateSet(board.currentBoard, row, col);
    if (candidates.length == 1) {
      return HintResult(
        row: row,
        col: col,
        level: HintLevel.explainTechnique,
        technique: SolvingTechnique.nakedSingle,
        candidates: candidates,
        message: '이 셀에 들어갈 수 있는 숫자가 ${candidates.first} 하나뿐입니다.',
      );
    }

    // 기법이 발견되었지만 다른 셀인 경우, 해당 셀을 안내
    if (techniqueResult != null) {
      return HintResult(
        row: row,
        col: col,
        level: HintLevel.explainTechnique,
        technique: techniqueResult.technique,
        candidates: candidates,
        message: '이 셀은 직접 풀기 어렵습니다. '
            '${techniqueResult.technique.label}을 (${techniqueResult.row + 1},${techniqueResult.col + 1})에서 먼저 적용해 보세요.',
      );
    }

    return HintResult(
      row: row,
      col: col,
      level: HintLevel.explainTechnique,
      candidates: candidates,
      message: '이 셀에 가능한 숫자: ${candidates.toList()..sort()}. '
          '행, 열, 박스의 숫자를 제외하면 답을 찾을 수 있습니다.',
    );
  }

  /// 4단계: 정답 공개 힌트
  static HintResult _revealAnswerHint(SudokuBoard board, int row, int col) {
    return HintResult(
      row: row,
      col: col,
      level: HintLevel.revealAnswer,
      answer: board.solution[row][col],
      message: '정답은 ${board.solution[row][col]}입니다',
    );
  }

  /// 특정 셀의 후보 숫자 집합
  static Set<int> _getCandidateSet(List<List<int>> board, int row, int col) {
    final used = <int>{};
    for (var i = 0; i < 9; i++) {
      if (board[row][i] > 0) used.add(board[row][i]);
      if (board[i][col] > 0) used.add(board[i][col]);
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] > 0) used.add(board[r][c]);
      }
    }
    return {for (var n = 1; n <= 9; n++) if (!used.contains(n)) n};
  }
}
