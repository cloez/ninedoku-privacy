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

  /// 힌트 설명 메시지 (하위 호환용 — UI는 messageKey 사용 권장)
  final String message;

  /// 기법 이름 다국어 키 (예: 'hint.technique.nakedSingle')
  final String? techniqueKey;

  /// 메시지 다국어 키 (예: 'hint.explain.hiddenSingle')
  final String? messageKey;

  /// 메시지 치환 파라미터 (예: {'n': '5', 'technique': 'Naked Single'})
  final Map<String, String>? messageParams;

  /// Level 1 영역 타입: 'row' | 'col' | 'box'
  final String? regionType;

  /// Level 1 영역 인덱스 (0~8)
  final int? regionIndex;

  // === R-Hint-2 신규 필드 ===

  /// L2 강조 대상 셀 목록 (Naked/Hidden Single은 1개, Pair는 2개 등)
  /// 보드 위젯이 초록 테두리로 강조 — H1.
  final List<(int, int)> keyCells;

  /// L3 자동 메모 — 셀별 잔존 후보 (회색 표시)
  /// key: (row, col), value: 해당 셀의 후보 숫자 집합 — H2.
  final Map<(int, int), Set<int>> autoMemo;

  /// L3 자동 메모 — 셀별 소거된 후보 (빨강 X 표시)
  final Map<(int, int), Set<int>> eliminated;

  /// L3/L4 정답 셀 좌표 (정답 표시용)
  final (int, int)? answerCell;

  /// L3/L4 정답 값 (정답 표시용)
  final int? answerValue;

  const HintResult({
    required this.row,
    required this.col,
    required this.level,
    this.answer,
    this.candidates = const {},
    this.highlightCells = const [],
    this.technique,
    this.message = '',
    this.techniqueKey,
    this.messageKey,
    this.messageParams,
    this.regionType,
    this.regionIndex,
    this.keyCells = const [],
    this.autoMemo = const {},
    this.eliminated = const {},
    this.answerCell,
    this.answerValue,
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

  /// 1단계: 영역 강조 힌트 — 가장 후보가 적은 단일 영역(박스 우선)을 선정
  static HintResult _highlightRegionHint(SudokuBoard board, int row, int col) {
    // 박스를 기본 영역으로 선택 (Naked/Hidden Single은 보통 박스에서 발견)
    final boxIdx = (row ~/ 3) * 3 + (col ~/ 3);
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    final cells = <(int, int)>[];
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        cells.add((r, c));
      }
    }
    return HintResult(
      row: row,
      col: col,
      level: HintLevel.highlightRegion,
      highlightCells: cells,
      message: '이 박스를 살펴보세요',
      messageKey: 'hint.level1.box',
      regionType: 'box',
      regionIndex: boxIdx,
    );
  }

  /// 기법 enum → 짧은 식별자 (예: 'nakedSingle')
  /// Level 2/3 메시지 키 조립용 (`hint.l2.{shortKey}`, `hint.l3.{shortKey}`)
  static String techniqueShortKeyOf(SolvingTechnique t) {
    switch (t) {
      case SolvingTechnique.nakedSingle:
        return 'nakedSingle';
      case SolvingTechnique.hiddenSingle:
        return 'hiddenSingle';
      case SolvingTechnique.nakedPair:
      case SolvingTechnique.nakedTriple:
        return 'nakedPair';
      case SolvingTechnique.hiddenPair:
        return 'hiddenPair';
      case SolvingTechnique.pointingPair:
        return 'pointingPair';
      case SolvingTechnique.boxLineReduction:
        return 'boxLine';
      case SolvingTechnique.xWing:
        return 'xWing';
    }
  }

  /// 기법 enum → 다국어 키 변환
  static String techniqueKeyOf(SolvingTechnique t) {
    switch (t) {
      case SolvingTechnique.nakedSingle:
        return 'hint.technique.nakedSingle';
      case SolvingTechnique.hiddenSingle:
        return 'hint.technique.hiddenSingle';
      case SolvingTechnique.nakedPair:
        return 'hint.technique.nakedPair';
      case SolvingTechnique.hiddenPair:
        return 'hint.technique.hiddenPair';
      case SolvingTechnique.pointingPair:
        return 'hint.technique.pointingPair';
      case SolvingTechnique.boxLineReduction:
        return 'hint.technique.boxLine';
      case SolvingTechnique.nakedTriple:
        return 'hint.technique.nakedPair'; // Triple은 Pair 설명 재사용
      case SolvingTechnique.xWing:
        return 'hint.technique.xWing';
    }
  }

  /// 기법 enum → Lv.2 안내(기법 소개) 다국어 키 변환
  static String l2KeyOf(SolvingTechnique t) {
    switch (t) {
      case SolvingTechnique.nakedSingle:
        return 'hint.l2.nakedSingle';
      case SolvingTechnique.hiddenSingle:
        return 'hint.l2.hiddenSingle';
      case SolvingTechnique.nakedPair:
      case SolvingTechnique.nakedTriple:
        return 'hint.l2.nakedPair';
      case SolvingTechnique.hiddenPair:
        return 'hint.l2.hiddenPair';
      case SolvingTechnique.pointingPair:
        return 'hint.l2.pointingPair';
      case SolvingTechnique.boxLineReduction:
        return 'hint.l2.boxLine';
      case SolvingTechnique.xWing:
        return 'hint.l2.xWing';
    }
  }

  /// 기법 enum → Lv.3 설명(상세 이유) 다국어 키 변환
  static String explainKeyOf(SolvingTechnique t) {
    switch (t) {
      case SolvingTechnique.nakedSingle:
        return 'hint.explain.nakedSingle';
      case SolvingTechnique.hiddenSingle:
        return 'hint.explain.hiddenSingle';
      case SolvingTechnique.nakedPair:
      case SolvingTechnique.nakedTriple:
        return 'hint.explain.nakedPair';
      case SolvingTechnique.hiddenPair:
        return 'hint.explain.hiddenPair';
      case SolvingTechnique.pointingPair:
        return 'hint.explain.pointingPair';
      case SolvingTechnique.boxLineReduction:
        return 'hint.explain.boxLine';
      case SolvingTechnique.xWing:
        return 'hint.explain.xWing';
    }
  }

  /// 2단계: 후보 숫자 안내 힌트 — 기법 이름 노출
  static HintResult _showCandidatesHint(SudokuBoard board, int row, int col) {
    final candidates = _getCandidateSet(board.currentBoard, row, col);
    // 기법 분석 시도 (Level 2부터 기법 이름 노출)
    final techniqueResult = TechniqueAnalyzer.findNextTechnique(board.currentBoard);
    SolvingTechnique? tech;
    if (techniqueResult != null &&
        techniqueResult.row == row &&
        techniqueResult.col == col) {
      tech = techniqueResult.technique;
    } else if (candidates.length == 1) {
      tech = SolvingTechnique.nakedSingle;
    }
    // H1: L2 핵심 셀 계산 (기법별)
    final keyCells = _computeKeyCells(board.currentBoard, row, col, tech);
    return HintResult(
      row: row,
      col: col,
      level: HintLevel.showCandidates,
      candidates: candidates,
      technique: tech,
      techniqueKey: tech != null ? techniqueKeyOf(tech) : null,
      // Lv.2는 기법 소개 메시지 (Lv.3의 상세 이유와 분리)
      messageKey: tech != null ? l2KeyOf(tech) : 'hint.level1.box',
      messageParams: candidates.length == 1
          ? {'n': candidates.first.toString()}
          : null,
      message: '이 셀에 가능한 숫자: ${candidates.toList()..sort()}',
      keyCells: keyCells,
    );
  }

  /// H1: L2 단계 핵심 셀 계산 — 기법별로 강조할 셀 좌표 리스트 반환
  /// Single 계열은 [targetCell] 1개, Pair는 두 셀, X-Wing은 4개 코너 등.
  static List<(int, int)> _computeKeyCells(
    List<List<int>> board,
    int row,
    int col,
    SolvingTechnique? tech,
  ) {
    if (tech == null) return [(row, col)];
    switch (tech) {
      case SolvingTechnique.nakedSingle:
      case SolvingTechnique.hiddenSingle:
        return [(row, col)];
      case SolvingTechnique.nakedPair:
      case SolvingTechnique.nakedTriple:
      case SolvingTechnique.hiddenPair:
      case SolvingTechnique.pointingPair:
      case SolvingTechnique.boxLineReduction:
      case SolvingTechnique.xWing:
        // 다중 셀 기법은 별도 분석이 필요 — 안전 폴백: 타깃 셀만 강조.
        // 후속 사이클에서 정확한 셀 추적 추가 예정.
        return [(row, col)];
    }
  }

  /// H2: L3 자동 메모/소거 계산 — 대상 셀과 같은 박스의 빈 셀들의 후보를 채움
  /// 정답 숫자는 정답 셀에서 초록, 같은 박스 다른 빈 셀에서 빨강 X로 시각화.
  static ({Map<(int, int), Set<int>> autoMemo, Map<(int, int), Set<int>> eliminated})
      _computeAutoMemo(
    List<List<int>> board,
    int targetRow,
    int targetCol,
    int? answerValue,
  ) {
    final autoMemo = <(int, int), Set<int>>{};
    final eliminated = <(int, int), Set<int>>{};
    final boxRow = (targetRow ~/ 3) * 3;
    final boxCol = (targetCol ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] != 0) continue;
        final cands = _getCandidateSet(board, r, c);
        if (cands.isEmpty) continue;
        // 정답 숫자가 후보에 있고, 대상 셀이 아니면 → 소거 처리
        if (answerValue != null &&
            (r != targetRow || c != targetCol) &&
            cands.contains(answerValue)) {
          eliminated[(r, c)] = {answerValue};
          // 잔존 후보 = 전체 - 소거된 것
          final remain = Set<int>.from(cands)..remove(answerValue);
          autoMemo[(r, c)] = remain;
        } else {
          autoMemo[(r, c)] = cands;
        }
      }
    }
    return (autoMemo: autoMemo, eliminated: eliminated);
  }

  /// 3단계: 풀이 기법 설명 힌트 (대상 셀 일치 시 기법 설명, 불일치 시 가이드 제공)
  static HintResult _explainTechniqueHint(SudokuBoard board, int row, int col) {
    final techniqueResult = TechniqueAnalyzer.findNextTechnique(board.currentBoard);
    final candidates = _getCandidateSet(board.currentBoard, row, col);

    // 정답 값 (보드 솔루션 기반)
    final answer = board.solution[row][col];
    // H2: L3 자동 메모/소거 계산
    final memo = _computeAutoMemo(board.currentBoard, row, col, answer);

    // 기법이 발견되고 대상 셀과 일치하는 경우 기법 힌트 제공
    if (techniqueResult != null &&
        techniqueResult.row == row &&
        techniqueResult.col == col) {
      final t = techniqueResult.technique;
      final n = techniqueResult.value ?? (candidates.length == 1 ? candidates.first : null);
      return HintResult(
        row: row,
        col: col,
        level: HintLevel.explainTechnique,
        technique: t,
        candidates: techniqueResult.value != null ? {techniqueResult.value!} : candidates,
        techniqueKey: techniqueKeyOf(t),
        messageKey: explainKeyOf(t),
        messageParams: n != null ? {'n': n.toString()} : null,
        message: techniqueResult.explanation,
        autoMemo: memo.autoMemo,
        eliminated: memo.eliminated,
        answerCell: (row, col),
        answerValue: answer,
      );
    }

    // 대상 셀에 해당하는 기법이 없으면 후보 기반 설명
    if (candidates.length == 1) {
      return HintResult(
        row: row,
        col: col,
        level: HintLevel.explainTechnique,
        technique: SolvingTechnique.nakedSingle,
        candidates: candidates,
        techniqueKey: 'hint.technique.nakedSingle',
        messageKey: 'hint.explain.nakedSingle',
        messageParams: {'n': candidates.first.toString()},
        message: '이 셀에 들어갈 수 있는 숫자가 ${candidates.first} 하나뿐입니다.',
        autoMemo: memo.autoMemo,
        eliminated: memo.eliminated,
        answerCell: (row, col),
        answerValue: answer,
      );
    }

    // 기법이 다른 셀에 있으면 그 기법 이름만 안내
    if (techniqueResult != null) {
      final t = techniqueResult.technique;
      return HintResult(
        row: row,
        col: col,
        level: HintLevel.explainTechnique,
        technique: t,
        candidates: candidates,
        techniqueKey: techniqueKeyOf(t),
        messageKey: explainKeyOf(t),
        message: '이 셀은 직접 풀기 어렵습니다. '
            '${techniqueResult.technique.label}을 (${techniqueResult.row + 1},${techniqueResult.col + 1})에서 먼저 적용해 보세요.',
        autoMemo: memo.autoMemo,
        eliminated: memo.eliminated,
        answerCell: (row, col),
        answerValue: answer,
      );
    }

    return HintResult(
      row: row,
      col: col,
      level: HintLevel.explainTechnique,
      candidates: candidates,
      messageKey: 'hint.explain.nakedSingle',
      message: '이 셀에 가능한 숫자: ${candidates.toList()..sort()}.',
      autoMemo: memo.autoMemo,
      eliminated: memo.eliminated,
      answerCell: (row, col),
      answerValue: answer,
    );
  }

  /// 4단계: 정답 공개 힌트
  static HintResult _revealAnswerHint(SudokuBoard board, int row, int col) {
    final answer = board.solution[row][col];
    // 사용된 기법 추정
    final techniqueResult = TechniqueAnalyzer.findNextTechnique(board.currentBoard);
    final candidates = _getCandidateSet(board.currentBoard, row, col);
    SolvingTechnique tech = SolvingTechnique.nakedSingle;
    if (techniqueResult != null &&
        techniqueResult.row == row &&
        techniqueResult.col == col) {
      tech = techniqueResult.technique;
    } else if (candidates.length == 1) {
      tech = SolvingTechnique.nakedSingle;
    }
    return HintResult(
      row: row,
      col: col,
      level: HintLevel.revealAnswer,
      answer: answer,
      technique: tech,
      techniqueKey: techniqueKeyOf(tech),
      messageKey: 'hint.answer',
      messageParams: {
        'n': answer.toString(),
        'technique': tech.label,
      },
      message: '정답은 $answer입니다',
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
