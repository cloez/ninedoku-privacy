import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../skyscrapers_notifier.dart';
import '../skyscrapers_state.dart';
import '../engine/skyscrapers_solver.dart';

/// Skyscrapers 보드 위젯
/// 격자 외곽 4면에 힌트 숫자를 표시
class SkyscrapersBoardWidget extends ConsumerWidget {
  const SkyscrapersBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(skyscrapersNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = gameState.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        // 힌트 영역 + 격자 영역 계산
        // 힌트 영역: 셀 크기 * 0.6 (위/아래/왼쪽/오른쪽 각 1개)
        // 격자: size * cellSize + (size+1) * border
        // 전체: 2 * clueWidth + gridSize
        final clueRatio = 0.55;
        final totalFactor = size + 2 * clueRatio;
        final cellSize = (maxSide - 8) / totalFactor;
        final clueWidth = cellSize * clueRatio;
        final gridSize = size * cellSize;
        final totalSize = gridSize + 2 * clueWidth;

        return Center(
          // 4면 단서 영역만큼 offset
          child: LastChangePulse(
            lastChangedCell: gameState.selectedCell,
            cellSize: cellSize,
            offsetX: clueWidth,
            offsetY: clueWidth,
            child: SizedBox(
              width: totalSize,
              height: totalSize,
              child: CustomPaint(
                painter: _SkyscrapersBoardPainter(
                  state: gameState,
                  isDark: isDark,
                  cellSize: cellSize,
                  clueWidth: clueWidth,
                ),
                child: _buildGestureOverlay(
                    ref, gameState, cellSize, clueWidth, size),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 셀별 탭 감지 오버레이
  Widget _buildGestureOverlay(
    WidgetRef ref,
    SkyscrapersState state,
    double cellSize,
    double clueWidth,
    int size,
  ) {
    return Stack(
      children: [
        for (var r = 0; r < size; r++)
          for (var c = 0; c < size; c++)
            Positioned(
              left: clueWidth + c * cellSize,
              top: clueWidth + r * cellSize,
              width: cellSize,
              height: cellSize,
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(skyscrapersNotifierProvider.notifier)
                      .selectCell(r, c);
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
      ],
    );
  }
}

/// 보드 그리기 Painter
class _SkyscrapersBoardPainter extends CustomPainter {
  final SkyscrapersState state;
  final bool isDark;
  final double cellSize;
  final double clueWidth;

  _SkyscrapersBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
    required this.clueWidth,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final size = state.size;

    // 외곽 힌트 그리기
    _drawClues(canvas, size);

    // 격자 배경
    final gridRect = Rect.fromLTWH(clueWidth, clueWidth, size * cellSize, size * cellSize);
    final gridBgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50;
    canvas.drawRRect(
      RRect.fromRectAndRadius(gridRect, const Radius.circular(4)),
      gridBgPaint,
    );

    // 셀 그리기
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        _drawCell(canvas, r, c, size);
      }
    }

    // 격자선 그리기
    _drawGridLines(canvas, size);
  }

  /// 외곽 힌트 그리기
  void _drawClues(Canvas canvas, int size) {
    final clueColor = isDark ? Colors.white70 : Colors.black54;

    // 위쪽 힌트
    for (var c = 0; c < size; c++) {
      final clue = state.current.topClues[c];
      if (clue == 0) continue;
      _drawClueNumber(
        canvas,
        clueWidth + c * cellSize + cellSize / 2,
        clueWidth / 2,
        clue,
        clueColor,
      );
    }

    // 아래쪽 힌트
    for (var c = 0; c < size; c++) {
      final clue = state.current.bottomClues[c];
      if (clue == 0) continue;
      _drawClueNumber(
        canvas,
        clueWidth + c * cellSize + cellSize / 2,
        clueWidth + size * cellSize + clueWidth / 2,
        clue,
        clueColor,
      );
    }

    // 왼쪽 힌트
    for (var r = 0; r < size; r++) {
      final clue = state.current.leftClues[r];
      if (clue == 0) continue;
      _drawClueNumber(
        canvas,
        clueWidth / 2,
        clueWidth + r * cellSize + cellSize / 2,
        clue,
        clueColor,
      );
    }

    // 오른쪽 힌트
    for (var r = 0; r < size; r++) {
      final clue = state.current.rightClues[r];
      if (clue == 0) continue;
      _drawClueNumber(
        canvas,
        clueWidth + size * cellSize + clueWidth / 2,
        clueWidth + r * cellSize + cellSize / 2,
        clue,
        clueColor,
      );
    }
  }

  /// 힌트 숫자 그리기
  void _drawClueNumber(
      Canvas canvas, double cx, double cy, int number, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          fontSize: clueWidth * 0.65,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2),
    );
  }

  /// 셀 위치 계산
  Rect _cellRect(int row, int col) {
    final x = clueWidth + col * cellSize;
    final y = clueWidth + row * cellSize;
    return Rect.fromLTWH(x, y, cellSize, cellSize);
  }

  /// 셀 그리기 (배경 + 값)
  void _drawCell(Canvas canvas, int row, int col, int size) {
    final rect = _cellRect(row, col);
    final idx = row * size + col;
    final value = state.current.getValue(row, col);

    // 배경색 결정
    Color bgColor;
    final isSelected = state.selectedCell == (row, col);
    final isFixed = state.current.fixed.contains(idx);
    final hasConflict = value != 0 &&
        (SkyscrapersSolver.hasRowColConflict(state.current, row, col) ||
            SkyscrapersSolver.hasClueViolation(state.current, row, col));
    final isHintHighlighted = _isHintHighlighted(row, col);

    if (isSelected) {
      bgColor = isDark ? AppColors.cellSelectedDark : AppColors.cellSelectedLight;
    } else if (hasConflict) {
      bgColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade100;
    } else if (isHintHighlighted) {
      bgColor = isDark
          ? Colors.amber.shade900.withValues(alpha: 0.2)
          : Colors.amber.shade50;
    } else {
      bgColor = Colors.transparent;
    }

    // 배경
    if (bgColor != Colors.transparent) {
      final bgPaint = Paint()..color = bgColor;
      canvas.drawRect(rect, bgPaint);
    }

    // 값 또는 메모 그리기
    if (value != 0) {
      _drawValue(canvas, rect, value, isFixed, hasConflict);
    } else if (state.current.notes.containsKey(idx)) {
      _drawNotes(canvas, rect, state.current.notes[idx]!, size);
    }
  }

  /// 셀 값 그리기
  void _drawValue(
      Canvas canvas, Rect rect, int value, bool isFixed, bool hasConflict) {
    Color textColor;
    if (hasConflict) {
      textColor = isDark ? Colors.red.shade400 : Colors.red.shade600;
    } else if (isFixed) {
      textColor = isDark ? Colors.white : Colors.black87;
    } else {
      textColor = isDark ? Colors.blue.shade200 : Colors.blue.shade700;
    }

    final tp = TextPainter(
      text: TextSpan(
        text: '$value',
        style: TextStyle(
          fontSize: cellSize * 0.5,
          fontWeight: isFixed ? FontWeight.bold : FontWeight.w500,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        rect.center.dx - tp.width / 2,
        rect.center.dy - tp.height / 2,
      ),
    );
  }

  /// 메모(후보 숫자) 그리기
  void _drawNotes(Canvas canvas, Rect rect, Set<int> notes, int size) {
    final gridCols = size <= 4 ? 2 : 3;
    final gridRows = (size / gridCols).ceil();
    final fontSize = cellSize / (gridCols + 0.5) * 0.7;

    for (final n in notes) {
      final gridCol = (n - 1) % gridCols;
      final gridRow = (n - 1) ~/ gridCols;

      final x = rect.left + (gridCol + 0.5) * (cellSize / gridCols);
      final y = rect.top + (gridRow + 0.5) * (cellSize / gridRows);

      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(
            fontSize: fontSize,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  /// 격자선 그리기
  void _drawGridLines(Canvas canvas, int size) {
    final linePaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black26
      ..strokeWidth = 1.0;

    final boldPaint = Paint()
      ..color = isDark ? Colors.white38 : Colors.black38
      ..strokeWidth = 2.0;

    // 외곽 테두리
    final gridRect = Rect.fromLTWH(clueWidth, clueWidth, size * cellSize, size * cellSize);
    canvas.drawRect(gridRect, boldPaint..style = PaintingStyle.stroke);

    // 내부 격자선
    for (var i = 1; i < size; i++) {
      // 수직선
      final x = clueWidth + i * cellSize;
      canvas.drawLine(
        Offset(x, clueWidth),
        Offset(x, clueWidth + size * cellSize),
        linePaint,
      );
      // 수평선
      final y = clueWidth + i * cellSize;
      canvas.drawLine(
        Offset(clueWidth, y),
        Offset(clueWidth + size * cellSize, y),
        linePaint,
      );
    }
  }

  /// 힌트 강조 여부
  bool _isHintHighlighted(int row, int col) {
    final hint = state.lastHintResult;
    if (hint == null) return false;
    if (hint.highlightRows.contains(row) && hint.highlightCols.contains(col)) {
      return true;
    }
    if (hint.highlightRows.contains(row) && hint.highlightCols.isEmpty) {
      return true;
    }
    if (hint.highlightCols.contains(col) && hint.highlightRows.isEmpty) {
      return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _SkyscrapersBoardPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
