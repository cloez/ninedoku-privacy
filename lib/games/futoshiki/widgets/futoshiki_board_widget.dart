import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../../../shared/widgets/line_complete_pulse.dart';
import '../futoshiki_notifier.dart';
import '../futoshiki_state.dart';
import '../engine/futoshiki_solver.dart';

/// 후토시키 보드 위젯
/// 셀 사이에 부등호 기호(< > ∧ ∨)를 표시
class FutoshikiBoardWidget extends ConsumerWidget {
  const FutoshikiBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(futoshikiNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = gameState.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 보드 크기 = 셀 + 부등호 영역
        // 셀 N개 + 부등호 (N-1)개 공간
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        // 부등호 영역은 셀 크기의 0.35배
        // totalWidth = size * cellSize + (size-1) * gapSize
        // gapSize = cellSize * 0.35
        // totalWidth = cellSize * (size + (size-1) * 0.35)
        final factor = size + (size - 1) * 0.35;
        final cellSize = (maxSide - 4) / factor;
        final gapSize = cellSize * 0.35;
        final boardSize = size * cellSize + (size - 1) * gapSize;

        // 게임 완료 시 보드 전체 펄스
        final completedLines = gameState.isCompleted
            ? const [CompletedLine('all', 0)]
            : const <CompletedLine>[];
        return Center(
          // 부등호 gap 고려: pulse의 cellSize에 (cellSize + gapSize)를 넘겨
          // 행/열별 시작 위치를 맞춘다. 셀 크기는 약간 크게 보이나 시각적 OK.
          child: LastChangePulse(
            lastChangedCell: gameState.selectedCell,
            cellSize: cellSize + gapSize,
            child: LineCompletePulse(
              lines: completedLines,
              cellSize: cellSize + gapSize,
              gridWidth: size,
              gridHeight: size,
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: CustomPaint(
                  painter: _FutoshikiBoardPainter(
                    state: gameState,
                    isDark: isDark,
                    cellSize: cellSize,
                    gapSize: gapSize,
                  ),
                  child: _buildGestureOverlay(
                      ref, gameState, cellSize, gapSize, size),
                ),
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
    FutoshikiState state,
    double cellSize,
    double gapSize,
    int size,
  ) {
    return Stack(
      children: [
        for (var r = 0; r < size; r++)
          for (var c = 0; c < size; c++)
            Positioned(
              left: c * (cellSize + gapSize),
              top: r * (cellSize + gapSize),
              width: cellSize,
              height: cellSize,
              child: GestureDetector(
                onTap: () {
                  ref.read(futoshikiNotifierProvider.notifier).selectCell(r, c);
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
class _FutoshikiBoardPainter extends CustomPainter {
  final FutoshikiState state;
  final bool isDark;
  final double cellSize;
  final double gapSize;

  _FutoshikiBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
    required this.gapSize,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final size = state.size;

    // 셀 배경 + 값 그리기
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        _drawCell(canvas, r, c, size);
      }
    }

    // 부등호 그리기
    _drawConstraints(canvas, size);
  }

  /// 셀 위치 계산
  Rect _cellRect(int row, int col) {
    final x = col * (cellSize + gapSize);
    final y = row * (cellSize + gapSize);
    return Rect.fromLTWH(x, y, cellSize, cellSize);
  }

  /// 셀 그리기 (배경 + 테두리 + 값)
  void _drawCell(Canvas canvas, int row, int col, int size) {
    final rect = _cellRect(row, col);
    final idx = row * size + col;
    final value = state.current.getValue(row, col);

    // 배경색 결정
    Color bgColor;
    final isSelected = state.selectedCell == (row, col);
    final isFixed = state.current.fixed.contains(idx);
    final hasConflict = value != 0 &&
        (FutoshikiSolver.hasRowColConflict(state.current, row, col) ||
            FutoshikiSolver.hasConstraintViolation(state.current, row, col));
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
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white;
    }

    // 배경
    final bgPaint = Paint()..color = bgColor;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, bgPaint);

    // 테두리
    final borderColor = isSelected
        ? (isDark ? Colors.blue.shade300 : Colors.blue.shade600)
        : (isDark ? Colors.white24 : Colors.black26);
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.0;
    canvas.drawRRect(rrect, borderPaint);

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

    final textPainter = TextPainter(
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
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  /// 메모(후보 숫자) 그리기
  void _drawNotes(Canvas canvas, Rect rect, Set<int> notes, int size) {
    // 3x3 그리드로 메모 표시 (9까지 지원)
    final gridCols = size <= 4 ? 2 : 3;
    final gridRows = (size / gridCols).ceil();
    final noteSize = cellSize / (gridCols + 0.5);
    final fontSize = noteSize * 0.7;

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

  /// 부등호 제약 그리기
  void _drawConstraints(Canvas canvas, int size) {
    // 수평 부등호 (셀 사이)
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size - 1; c++) {
        final h = state.current.getHorizontalConstraint(r, c);
        if (h == 0) continue;

        // 부등호 위치: 왼쪽 셀과 오른쪽 셀 사이
        final leftRect = _cellRect(r, c);
        final cx = leftRect.right + gapSize / 2;
        final cy = leftRect.center.dy;

        // 부등호 위반 여부 체크
        final leftVal = state.current.getValue(r, c);
        final rightVal = state.current.getValue(r, c + 1);
        final isViolated = leftVal != 0 && rightVal != 0 &&
            ((h == 1 && !(leftVal < rightVal)) ||
                (h == 2 && !(leftVal > rightVal)));

        final symbol = h == 1 ? '<' : '>';
        _drawConstraintSymbol(canvas, cx, cy, symbol, isViolated);
      }
    }

    // 수직 부등호 (셀 사이)
    for (var r = 0; r < size - 1; r++) {
      for (var c = 0; c < size; c++) {
        final v = state.current.getVerticalConstraint(r, c);
        if (v == 0) continue;

        final topRect = _cellRect(r, c);
        final cx = topRect.center.dx;
        final cy = topRect.bottom + gapSize / 2;

        // 부등호 위반 여부 체크
        final topVal = state.current.getValue(r, c);
        final bottomVal = state.current.getValue(r + 1, c);
        final isViolated = topVal != 0 && bottomVal != 0 &&
            ((v == 1 && !(topVal < bottomVal)) ||
                (v == 2 && !(topVal > bottomVal)));

        final symbol = v == 1 ? '∧' : '∨';
        _drawConstraintSymbol(canvas, cx, cy, symbol, isViolated);
      }
    }
  }

  /// 부등호 기호 그리기
  void _drawConstraintSymbol(
      Canvas canvas, double cx, double cy, String symbol, bool isViolated) {
    final color = isViolated
        ? (isDark ? Colors.red.shade400 : Colors.red.shade600)
        : (isDark ? Colors.white60 : Colors.black54);

    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: gapSize * 0.9,
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
  bool shouldRepaint(covariant _FutoshikiBoardPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
