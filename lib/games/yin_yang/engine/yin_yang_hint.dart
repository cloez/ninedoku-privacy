/// 음양 힌트 엔진 — 4단계 점진적 힌트
/// 연결성 + 2×2 금지 규칙 기반 추론
library;

import 'yin_yang_board.dart';

class YinYangHintResult {
  final int row;
  final int col;
  final int level;
  final String message;
  /// Level 4에서의 정답 값 (0: ●, 1: ○)
  final int? value;

  const YinYangHintResult({
    required this.row,
    required this.col,
    required this.level,
    required this.message,
    this.value,
  });
}

class YinYangHintEngine {
  /// 힌트 제공
  static YinYangHintResult? getHint(
    YinYangBoard board,
    YinYangBoard solution, {
    int level = 1,
  }) {
    // 정답과 다른 첫 번째 빈 셀 찾기
    final target = _findTarget(board, solution);
    if (target == null) return null;

    final (row, col, correctValue) = target;
    final symbol = correctValue == 0 ? '●' : '○';

    switch (level) {
      case 1:
        return YinYangHintResult(
          row: row, col: col, level: 1,
          message: '행 ${row + 1}, 열 ${col + 1} 주변을 살펴보세요',
        );

      case 2:
        final reason = _findReason(board, row, col, correctValue);
        return YinYangHintResult(
          row: row, col: col, level: 2,
          message: reason,
        );

      case 3:
        final explanation = _buildExplanation(board, row, col, correctValue);
        return YinYangHintResult(
          row: row, col: col, level: 3,
          message: explanation,
        );

      case 4:
        return YinYangHintResult(
          row: row, col: col, level: 4,
          message: '이 셀은 $symbol입니다',
          value: correctValue,
        );

      default:
        return null;
    }
  }

  /// 힌트 대상 셀 찾기: (row, col, correctValue)
  static (int, int, int)? _findTarget(YinYangBoard board, YinYangBoard solution) {
    // 2×2 금지로 확정 가능한 셀 우선
    for (int r = 0; r < board.size; r++) {
      for (int c = 0; c < board.size; c++) {
        if (board.getValue(r, c) != -1) continue;
        final correct = solution.getValue(r, c);

        // 솔루션 값이 빈 칸이면 건너뛰기
        if (correct == -1) continue;

        // 반대 값을 넣으면 2×2가 생기는지 확인
        final opposite = 1 - correct;
        final testBoard = board.setValue(r, c, opposite);
        if (_wouldCreate2x2(testBoard, r, c)) {
          return (r, c, correct);
        }
      }
    }

    // 연결성으로 확정 가능한 셀
    for (int r = 0; r < board.size; r++) {
      for (int c = 0; c < board.size; c++) {
        if (board.getValue(r, c) != -1) continue;
        final solVal = solution.getValue(r, c);
        if (solVal == -1) continue;
        return (r, c, solVal);
      }
    }

    return null;
  }

  /// 2×2 블록 생성 여부 확인
  static bool _wouldCreate2x2(YinYangBoard board, int row, int col) {
    final v = board.getValue(row, col);
    if (v == -1) return false;

    // (row, col)이 포함되는 4개의 2×2 영역 확인
    for (final (dr, dc) in [(0, 0), (0, -1), (-1, 0), (-1, -1)]) {
      final tr = row + dr;
      final tc = col + dc;
      if (tr < 0 || tr + 1 >= board.size || tc < 0 || tc + 1 >= board.size) continue;

      final v00 = board.getValue(tr, tc);
      final v01 = board.getValue(tr, tc + 1);
      final v10 = board.getValue(tr + 1, tc);
      final v11 = board.getValue(tr + 1, tc + 1);

      if (v00 != -1 && v00 == v01 && v01 == v10 && v10 == v11) {
        return true;
      }
    }
    return false;
  }

  /// Level 2: 간단한 이유
  static String _findReason(YinYangBoard board, int row, int col, int correctValue) {
    final opposite = 1 - correctValue;
    final oppSymbol = opposite == 0 ? '●' : '○';
    final testBoard = board.setValue(row, col, opposite);

    if (_wouldCreate2x2(testBoard, row, col)) {
      return '이 셀에 $oppSymbol을 놓으면 2×2 블록이 생깁니다';
    }
    return '주변 셀의 연결성을 확인해 보세요';
  }

  /// Level 3: 상세 설명
  static String _buildExplanation(YinYangBoard board, int row, int col, int correctValue) {
    final symbol = correctValue == 0 ? '●' : '○';
    final opposite = 1 - correctValue;
    final oppSymbol = opposite == 0 ? '●' : '○';
    final testBoard = board.setValue(row, col, opposite);

    if (_wouldCreate2x2(testBoard, row, col)) {
      return '이 셀에 $oppSymbol을 넣으면 2×2 $oppSymbol 블록이 만들어지므로, '
          '이 셀은 반드시 $symbol이어야 합니다';
    }

    return '연결성 규칙에 의해 이 셀은 $symbol이어야 합니다. '
        '$oppSymbol을 넣으면 $symbol 영역이 둘로 나뉘거나, '
        '$oppSymbol 영역에 2×2 블록이 생깁니다';
  }
}
