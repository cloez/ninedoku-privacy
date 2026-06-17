import 'package:flutter/material.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../engine/nonogram_board.dart';
import '../engine/nonogram_solver.dart';

/// 노노그램 보드 위젯 — CustomPaint 기반
///
/// 행/열 힌트 영역이 있는 특수 레이아웃:
/// ┌───┬──────────────┐
/// │   │ 열 힌트 영역   │ ← 각 열의 숫자 리스트 (위→아래)
/// │행 ├──────────────┤
/// │힌 │              │
/// │트 │  게임 격자     │ ← 채우기/X/빈칸
/// │   │              │
/// └───┴──────────────┘
class NonogramBoardWidget extends StatelessWidget {
  final NonogramBoard board;
  final NonogramBoard? solution;
  final (int, int)? selectedCell;
  final (int, int)? hintTargetCell;
  final bool isCompleted;
  final void Function(int row, int col)? onCellTap;
  final void Function(int row, int col)? onCellLongPress;

  const NonogramBoardWidget({
    super.key,
    required this.board,
    this.solution,
    this.selectedCell,
    this.hintTargetCell,
    this.isCompleted = false,
    this.onCellTap,
    this.onCellLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 힌트 영역 크기 계산
        final maxRowHintCount = _maxHintLength(board.rowHints);
        final maxColHintCount = _maxHintLength(board.colHints);

        // 사용 가능 공간에서 셀 크기 산정
        final availWidth = constraints.maxWidth;
        final availHeight = constraints.maxHeight;

        // 힌트 영역 비율 포함한 셀 크기 계산
        final cellSizeW = availWidth / (board.cols + maxRowHintCount);
        final cellSizeH = availHeight / (board.rows + maxColHintCount);
        final cellSize = (cellSizeW < cellSizeH ? cellSizeW : cellSizeH).floorToDouble();

        // 최소/최대 셀 크기 제한
        final clampedCellSize = cellSize.clamp(12.0, 48.0);

        final rowHintWidth = clampedCellSize * maxRowHintCount;
        final colHintHeight = clampedCellSize * maxColHintCount;
        final gridWidth = clampedCellSize * board.cols;
        final gridHeight = clampedCellSize * board.rows;
        final totalWidth = rowHintWidth + gridWidth;
        final totalHeight = colHintHeight + gridHeight;

        return Center(
          // 행/열 힌트 영역 offset 적용
          child: LastChangePulse(
            lastChangedCell: selectedCell,
            cellSize: clampedCellSize,
            offsetX: rowHintWidth,
            offsetY: colHintHeight,
            child: SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: GestureDetector(
              onTapUp: (details) {
                if (onCellTap == null) return;
                final cell = _hitTest(details.localPosition, rowHintWidth, colHintHeight, clampedCellSize);
                if (cell != null) onCellTap!(cell.$1, cell.$2);
              },
              onLongPressStart: (details) {
                if (onCellLongPress == null) return;
                final cell = _hitTest(details.localPosition, rowHintWidth, colHintHeight, clampedCellSize);
                if (cell != null) onCellLongPress!(cell.$1, cell.$2);
              },
              child: CustomPaint(
                size: Size(totalWidth, totalHeight),
                painter: _NonogramBoardPainter(
                  board: board,
                  cellSize: clampedCellSize,
                  rowHintWidth: rowHintWidth,
                  colHintHeight: colHintHeight,
                  maxRowHintCount: maxRowHintCount,
                  maxColHintCount: maxColHintCount,
                  isDark: isDark,
                  selectedCell: selectedCell,
                  hintTargetCell: hintTargetCell,
                  isCompleted: isCompleted,
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  /// 힌트 리스트 중 최대 길이 (최소 1)
  int _maxHintLength(List<List<int>> hints) {
    int max = 1;
    for (final h in hints) {
      if (h.length > max) max = h.length;
    }
    return max;
  }

  /// 좌표 → 셀 인덱스 변환 (힌트 영역 제외)
  (int, int)? _hitTest(Offset pos, double rowHintWidth, double colHintHeight, double cellSize) {
    final x = pos.dx - rowHintWidth;
    final y = pos.dy - colHintHeight;
    if (x < 0 || y < 0) return null;
    final col = (x / cellSize).floor();
    final row = (y / cellSize).floor();
    if (row >= 0 && row < board.rows && col >= 0 && col < board.cols) {
      return (row, col);
    }
    return null;
  }
}

class _NonogramBoardPainter extends CustomPainter {
  final NonogramBoard board;
  final double cellSize;
  final double rowHintWidth;
  final double colHintHeight;
  final int maxRowHintCount;
  final int maxColHintCount;
  final bool isDark;
  final (int, int)? selectedCell;
  final (int, int)? hintTargetCell;
  final bool isCompleted;

  _NonogramBoardPainter({
    required this.board,
    required this.cellSize,
    required this.rowHintWidth,
    required this.colHintHeight,
    required this.maxRowHintCount,
    required this.maxColHintCount,
    required this.isDark,
    this.selectedCell,
    this.hintTargetCell,
    this.isCompleted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 힌트 영역 배경
    _drawHintBackground(canvas, size);

    // 행 힌트 (격자 왼쪽, 우측 정렬)
    for (int r = 0; r < board.rows; r++) {
      _drawRowHints(canvas, r);
    }

    // 열 힌트 (격자 위쪽, 하단 정렬)
    for (int c = 0; c < board.cols; c++) {
      _drawColHints(canvas, c);
    }

    // 격자 셀
    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        _drawCell(canvas, r, c);
      }
    }

    // 격자선
    _drawGrid(canvas, size);

    // 선택/힌트 강조 (행/열 전체)
    _drawHighlights(canvas);
  }

  /// 힌트 영역 배경
  void _drawHintBackground(Canvas canvas, Size size) {
    final hintBg = Paint()
      ..color = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);

    // 행 힌트 영역 배경
    canvas.drawRect(
      Rect.fromLTWH(0, colHintHeight, rowHintWidth, board.rows * cellSize),
      hintBg,
    );

    // 열 힌트 영역 배경
    canvas.drawRect(
      Rect.fromLTWH(rowHintWidth, 0, board.cols * cellSize, colHintHeight),
      hintBg,
    );

    // 좌상단 코너
    canvas.drawRect(
      Rect.fromLTWH(0, 0, rowHintWidth, colHintHeight),
      hintBg,
    );
  }

  /// 행 힌트 그리기 (우측 정렬)
  void _drawRowHints(Canvas canvas, int row) {
    final hints = board.rowHints[row];
    final isSatisfied = NonogramSolver.isRowSatisfied(board, row);
    final y = colHintHeight + row * cellSize;

    for (int i = 0; i < hints.length; i++) {
      // 우측 정렬: 맨 오른쪽부터 배치
      final x = rowHintWidth - (hints.length - i) * cellSize;
      final rect = Rect.fromLTWH(x, y, cellSize, cellSize);

      _drawHintNumber(canvas, rect, '${hints[i]}', isSatisfied);
    }
  }

  /// 열 힌트 그리기 (하단 정렬)
  void _drawColHints(Canvas canvas, int col) {
    final hints = board.colHints[col];
    final isSatisfied = NonogramSolver.isColSatisfied(board, col);
    final x = rowHintWidth + col * cellSize;

    for (int i = 0; i < hints.length; i++) {
      // 하단 정렬: 맨 아래부터 배치
      final y = colHintHeight - (hints.length - i) * cellSize;
      final rect = Rect.fromLTWH(x, y, cellSize, cellSize);

      _drawHintNumber(canvas, rect, '${hints[i]}', isSatisfied);
    }
  }

  /// 힌트 숫자 그리기
  void _drawHintNumber(Canvas canvas, Rect rect, String text, bool isSatisfied) {
    final color = isSatisfied
        ? (isDark ? Colors.white24 : Colors.black26) // 완성된 행/열: 회색
        : (isDark ? Colors.white70 : Colors.black87); // 미완성: 진하게

    final fontSize = cellSize * 0.45;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        rect.center.dx - tp.width / 2,
        rect.center.dy - tp.height / 2,
      ),
    );
  }

  /// 셀 그리기
  void _drawCell(Canvas canvas, int r, int c) {
    final value = board.getValue(r, c);
    final x = rowHintWidth + c * cellSize;
    final y = colHintHeight + r * cellSize;
    final rect = Rect.fromLTWH(x, y, cellSize, cellSize);

    // 배경색
    Color bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

    // 선택된 셀 강조
    if (selectedCell != null && selectedCell!.$1 == r && selectedCell!.$2 == c) {
      bgColor = isDark ? const Color(0xFF1565C0) : const Color(0xFFBBDEFB);
    }

    // 힌트 대상 셀 강조
    if (hintTargetCell != null && hintTargetCell!.$1 == r && hintTargetCell!.$2 == c) {
      bgColor = isDark ? const Color(0xFF827717) : const Color(0xFFFFF9C4);
    }

    canvas.drawRect(rect, Paint()..color = bgColor);

    // 셀 내용
    if (value == 1) {
      // ■ 채움: 검정 사각형
      final fillRect = Rect.fromLTWH(
        x + cellSize * 0.15,
        y + cellSize * 0.15,
        cellSize * 0.7,
        cellSize * 0.7,
      );
      final fillColor = isDark ? Colors.white : Colors.black;
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, Radius.circular(cellSize * 0.08)),
        Paint()..color = fillColor,
      );
    } else if (value == 0) {
      // ✕ 크로스: X 마크
      final crossColor = isDark ? Colors.white38 : Colors.black38;
      final crossPaint = Paint()
        ..color = crossColor
        ..strokeWidth = cellSize * 0.08
        ..strokeCap = StrokeCap.round;

      final margin = cellSize * 0.25;
      canvas.drawLine(
        Offset(x + margin, y + margin),
        Offset(x + cellSize - margin, y + cellSize - margin),
        crossPaint,
      );
      canvas.drawLine(
        Offset(x + cellSize - margin, y + margin),
        Offset(x + margin, y + cellSize - margin),
        crossPaint,
      );
    }
    // -1: 빈칸 — 아무것도 그리지 않음
  }

  /// 격자선 그리기
  void _drawGrid(Canvas canvas, Size size) {
    final thinPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..strokeWidth = 0.5;

    final thickPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black26
      ..strokeWidth = 1.5;

    // 격자 영역 세로선
    for (int c = 0; c <= board.cols; c++) {
      final x = rowHintWidth + c * cellSize;
      final paint = (c % 5 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(
        Offset(x, colHintHeight),
        Offset(x, colHintHeight + board.rows * cellSize),
        paint,
      );
    }

    // 격자 영역 가로선
    for (int r = 0; r <= board.rows; r++) {
      final y = colHintHeight + r * cellSize;
      final paint = (r % 5 == 0) ? thickPaint : thinPaint;
      canvas.drawLine(
        Offset(rowHintWidth, y),
        Offset(rowHintWidth + board.cols * cellSize, y),
        paint,
      );
    }

    // 힌트 영역 경계선
    final borderPaint = Paint()
      ..color = isDark ? Colors.white30 : Colors.black38
      ..strokeWidth = 2;

    // 행 힌트 / 격자 경계 (세로선)
    canvas.drawLine(
      Offset(rowHintWidth, 0),
      Offset(rowHintWidth, colHintHeight + board.rows * cellSize),
      borderPaint,
    );

    // 열 힌트 / 격자 경계 (가로선)
    canvas.drawLine(
      Offset(0, colHintHeight),
      Offset(rowHintWidth + board.cols * cellSize, colHintHeight),
      borderPaint,
    );

    // 외곽선
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint..style = PaintingStyle.stroke,
    );
  }

  /// 선택된 셀의 행/열 강조
  void _drawHighlights(Canvas canvas) {
    final target = selectedCell ?? hintTargetCell;
    if (target == null) return;

    final highlightPaint = Paint()
      ..color = isDark
          ? Colors.blue.withValues(alpha: 0.08)
          : Colors.blue.withValues(alpha: 0.06);

    // 행 강조 (격자 영역)
    canvas.drawRect(
      Rect.fromLTWH(
        rowHintWidth,
        colHintHeight + target.$1 * cellSize,
        board.cols * cellSize,
        cellSize,
      ),
      highlightPaint,
    );

    // 열 강조 (격자 영역)
    canvas.drawRect(
      Rect.fromLTWH(
        rowHintWidth + target.$2 * cellSize,
        colHintHeight,
        cellSize,
        board.rows * cellSize,
      ),
      highlightPaint,
    );

    // 행 힌트 영역 강조
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        colHintHeight + target.$1 * cellSize,
        rowHintWidth,
        cellSize,
      ),
      highlightPaint,
    );

    // 열 힌트 영역 강조
    canvas.drawRect(
      Rect.fromLTWH(
        rowHintWidth + target.$2 * cellSize,
        0,
        cellSize,
        colHintHeight,
      ),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NonogramBoardPainter oldDelegate) => true;
}
