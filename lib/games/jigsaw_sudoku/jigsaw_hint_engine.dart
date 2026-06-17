// Jigsaw Sudoku 힌트 엔진 — 스도쿠 TechniqueAnalyzer 어댑터 골격.
//
// 본 파일은 Phase 3 일부 — Jigsaw가 스도쿠 분석기를 거의 그대로 재사용할 수
// 있다는 GD 평가(LOW 난이도)에 따라 적용한 어댑터 스텁이다.
//
// 핵심 아이디어:
//  - 스도쿠는 9x9 행/열/3x3 박스 제약을 사용한다.
//  - Jigsaw는 9x9 행/열은 동일, 박스 자리에 불규칙 9영역(jigsaw region)을 둔다.
//  - 따라서 TechniqueAnalyzer가 box 검사에 사용하는 좌표 산출을 jigsaw region
//    좌표로 치환만 하면 분석기 본체는 그대로 재사용 가능.
//
// 현 단계: 골격(인터페이스)만 정의. 실제 어댑터 구현은 후속 Phase에서 진행.

import '../../core/sudoku/board.dart';
import '../../core/sudoku/technique_analyzer.dart';
import 'engine/jigsaw_sudoku_board.dart';

/// 직소 스도쿠 힌트 결과 (스도쿠 HintResult를 재사용해도 되지만,
/// 여기선 영역 정보가 box 인덱스가 아닌 region 인덱스라는 점을 명시).
class JigsawHintResult {
  /// 힌트 대상 셀
  final int row;
  final int col;

  /// 정답 값 (revealAnswer 단계)
  final int? answer;

  /// 강조 영역 셀 좌표 (불규칙 region — Jigsaw 9개 region 중 하나)
  final List<(int, int)> regionCells;

  /// 사용된 풀이 기법 (스도쿠와 공유)
  final SolvingTechnique? technique;

  /// 메시지 다국어 키
  final String? messageKey;
  final Map<String, String>? messageParams;

  const JigsawHintResult({
    required this.row,
    required this.col,
    this.answer,
    this.regionCells = const [],
    this.technique,
    this.messageKey,
    this.messageParams,
  });
}

/// Jigsaw 힌트 엔진 — 스도쿠 TechniqueAnalyzer 어댑터.
class JigsawHintEngine {
  /// 현재 보드에서 다음 힌트 후보를 찾는다.
  ///
  /// 어댑터 전략:
  ///  - 스도쿠 TechniqueAnalyzer는 box 좌표를 (br..br+3, bc..bc+3) 식으로 산출.
  ///  - Jigsaw에서는 [JigsawSudokuBoard.regionOf(r, c)]로 region 인덱스를 얻고
  ///    그 region에 속한 셀 목록으로 box 검사를 치환한다.
  ///
  /// 이번 커밋에서는 스도쿠 메시지 키(`hint.l2.*`, `hint.l3.*`)를 그대로
  /// 재사용한다. 영역 표현만 'region'으로 둔다.
  static JigsawHintResult? analyzeNext({
    required JigsawSudokuBoard board,
    required SudokuBoard solution,
  }) {
    // 후속 Phase에서 TechniqueAnalyzer를 어댑터로 감싸 box 검사를 region 검사로
    // 치환하는 본 구현을 추가한다. 현 단계에서는 골격만 둔다.
    return null;
  }
}
