// Killer Sudoku 힌트 엔진 — 스도쿠 분석기 + 케이지 합 추론 골격.
//
// Phase 3 일부. Killer는 일반 스도쿠 제약(행/열/박스) + 케이지 합 제약을 가진다.
// GD 평가(M 난이도): 스도쿠 8종 기법은 그대로 재사용 가능, 케이지 합 분해만
// 추가 분석기로 작성하면 된다.
//
// 본 파일은 골격으로:
//  - `analyzeNext`: 스도쿠 분석기를 먼저 적용 → 결과가 없으면 케이지 합 분석.
//  - 케이지 합 분석 메시지는 다국어 키 `hint.l2.cageSum` / `hint.l3.cageSum` 사용.

import '../../core/sudoku/technique_analyzer.dart';
import 'engine/killer_sudoku_board.dart';

/// Killer 힌트 결과
class KillerHintResult {
  final int row;
  final int col;
  final int? answer;

  /// 강조 대상 cage cell 좌표 (케이지 추론에 사용)
  final List<(int, int)> cageCells;

  /// 케이지 합 (UI 메시지 파라미터에 사용)
  final int? cageSum;

  /// 사용된 기법 (스도쿠 분석 결과면 SolvingTechnique, 케이지 분석이면 null)
  final SolvingTechnique? technique;

  /// 메시지 다국어 키:
  ///  - 스도쿠 기법: 'hint.l2.nakedSingle' 등 (재사용)
  ///  - 케이지 합: 'hint.l2.cageSum' / 'hint.l3.cageSum'
  final String? messageKey;
  final Map<String, String>? messageParams;

  const KillerHintResult({
    required this.row,
    required this.col,
    this.answer,
    this.cageCells = const [],
    this.cageSum,
    this.technique,
    this.messageKey,
    this.messageParams,
  });
}

class KillerHintEngine {
  /// 1) 스도쿠 분석기 우선 적용 → 없으면 2) 케이지 합 분해.
  ///
  /// 어댑터 전략:
  ///  - 스도쿠 분석기는 9x9 SudokuBoard에 의존하므로 KillerSudokuBoard에서
  ///    동일 형태로 currentBoard를 노출하여 그대로 호출.
  ///  - 케이지 합 분해는 후속 Phase에서 본 구현 추가.
  static KillerHintResult? analyzeNext({
    required KillerSudokuBoard board,
  }) {
    // 후속 Phase에서:
    //  1) TechniqueAnalyzer.analyze(board.toSudokuBoard()) — 스도쿠 분석 재사용
    //  2) 케이지별 합 분해 (uniqueCombos)로 후보 좁히기 → cageSum 메시지 키 출력
    return null;
  }
}
