import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../tents_notifier.dart';
import '../tents_state.dart';
import '../engine/tents_board.dart';
import '../engine/tents_solver.dart';

/// Tents 보드 위젯
class TentsBoardWidget extends ConsumerWidget {
  const TentsBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(tentsNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = gameState.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 행/열 힌트 영역 포함한 반응형 크기 계산
        // 왼쪽에 행 힌트, 상단에 열 힌트
        final hintAreaSize = 28.0;
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final boardSize = maxSide - hintAreaSize - 4;
        final cellSize = boardSize / size;

        return Center(
          // 힌트 영역만큼 offset 적용 — 보드 시작 위치에 맞춤
          child: LastChangePulse(
            lastChangedCell: gameState.selectedCell,
            cellSize: cellSize,
            offsetX: hintAreaSize,
            offsetY: hintAreaSize,
            child: SizedBox(
              width: boardSize + hintAreaSize,
              height: boardSize + hintAreaSize,
              child: CustomPaint(
                painter: _TentsBoardPainter(
                  state: gameState,
                  isDark: isDark,
                  cellSize: cellSize,
                  hintAreaSize: hintAreaSize,
                ),
                child: _buildGestureGrid(
                    ref, gameState, cellSize, size, hintAreaSize),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 셀별 탭 감지 그리드
  Widget _buildGestureGrid(
    WidgetRef ref,
    TentsState state,
    double cellSize,
    int size,
    double hintAreaSize,
  ) {
    return Stack(
      children: [
        // 보드 영역 (힌트 영역 오프셋)
        Positioned(
          left: hintAreaSize,
          top: hintAreaSize,
          width: cellSize * size,
          height: cellSize * size,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size,
            ),
            itemCount: size * size,
            itemBuilder: (context, index) {
              final row = index ~/ size;
              final col = index % size;
              return GestureDetector(
                onTap: () {
                  final notifier = ref.read(tentsNotifierProvider.notifier);
                  notifier.tapCell(row, col);
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 보드 그리기 Painter
class _TentsBoardPainter extends CustomPainter {
  final TentsState state;
  final bool isDark;
  final double cellSize;
  final double hintAreaSize;

  _TentsBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
    required this.hintAreaSize,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final size = state.size;
    final violations = TentsSolver.getAdjacentTentViolations(state.current);

    // 셀 배경 그리기
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _drawCellBackground(canvas, row, col, violations);
      }
    }

    // 격자선
    _drawGrid(canvas, size);

    // 셀 값 (나무, 텐트, 잔디)
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _drawCellValue(canvas, row, col, violations);
      }
    }

    // 행 힌트 (왼쪽)
    _drawRowHints(canvas, size);

    // 열 힌트 (상단)
    _drawColHints(canvas, size);
  }

  /// 셀 배경
  void _drawCellBackground(
      Canvas canvas, int row, int col, Set<int> violations) {
    final rect = Rect.fromLTWH(
      hintAreaSize + col * cellSize,
      hintAreaSize + row * cellSize,
      cellSize,
      cellSize,
    );

    Color? bgColor;
    final idx = row * state.size + col;

    if (state.selectedCell == (row, col)) {
      bgColor =
          isDark ? AppColors.cellSelectedDark : AppColors.cellSelectedLight;
    } else if (violations.contains(idx)) {
      bgColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade100;
    } else if (_isHintHighlighted(row, col)) {
      bgColor = isDark
          ? Colors.amber.shade900.withValues(alpha: 0.2)
          : Colors.amber.shade50;
    }

    if (bgColor != null) {
      canvas.drawRect(rect, Paint()..color = bgColor);
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

  /// 격자선
  void _drawGrid(Canvas canvas, int size) {
    final linePaint = Paint()
      ..color = isDark ? AppColors.boardLineDark : AppColors.boardLineLight
      ..strokeWidth = 0.5;

    final borderPaint = Paint()
      ..color = isDark ? AppColors.boardLineDark : AppColors.boardLineLight
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 얇은 격자선
    for (var i = 1; i < size; i++) {
      final xPos = hintAreaSize + i * cellSize;
      final yPos = hintAreaSize + i * cellSize;
      canvas.drawLine(
        Offset(xPos, hintAreaSize),
        Offset(xPos, hintAreaSize + size * cellSize),
        linePaint,
      );
      canvas.drawLine(
        Offset(hintAreaSize, yPos),
        Offset(hintAreaSize + size * cellSize, yPos),
        linePaint,
      );
    }

    // 외곽 테두리
    canvas.drawRect(
      Rect.fromLTWH(
          hintAreaSize, hintAreaSize, size * cellSize, size * cellSize),
      borderPaint,
    );
  }

  /// 셀 값 그리기
  void _drawCellValue(
      Canvas canvas, int row, int col, Set<int> violations) {
    final value = state.current.getValue(row, col);
    if (value == TentsBoard.empty) return;

    final cx = hintAreaSize + col * cellSize + cellSize / 2;
    final cy = hintAreaSize + row * cellSize + cellSize / 2;
    final idx = row * state.size + col;
    final isViolation = violations.contains(idx);

    if (value == TentsBoard.tree) {
      // 나무: 🌲 텍스트
      final tp = TextPainter(
        text: TextSpan(
          text: '🌲',
          style: TextStyle(fontSize: cellSize * 0.55),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    } else if (value == TentsBoard.tent) {
      // 텐트: ⛺ 텍스트
      final color = isViolation
          ? (isDark ? Colors.red.shade400 : Colors.red.shade600)
          : null;
      final tp = TextPainter(
        text: TextSpan(
          text: '⛺',
          style: TextStyle(
            fontSize: cellSize * 0.50,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    } else if (value == TentsBoard.grass) {
      // 잔디: ✕ 표시
      final paint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.2)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final offset = cellSize * 0.25;
      canvas.drawLine(
        Offset(cx - offset, cy - offset),
        Offset(cx + offset, cy + offset),
        paint,
      );
      canvas.drawLine(
        Offset(cx + offset, cy - offset),
        Offset(cx - offset, cy + offset),
        paint,
      );
    }
  }

  /// 행 힌트 (왼쪽)
  void _drawRowHints(Canvas canvas, int size) {
    for (var r = 0; r < size; r++) {
      final count = state.current.rowCounts[r];
      final currentTents = state.current.currentRowTents(r);
      final isFulfilled = currentTents == count;
      final isExceeded = currentTents > count;

      Color textColor;
      if (isExceeded) {
        textColor = isDark ? Colors.red.shade400 : Colors.red.shade600;
      } else if (isFulfilled) {
        textColor = isDark ? Colors.green.shade400 : Colors.green.shade600;
      } else {
        textColor = isDark ? Colors.white70 : Colors.black54;
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final cy = hintAreaSize + r * cellSize + cellSize / 2;
      tp.paint(
        canvas,
        Offset((hintAreaSize - tp.width) / 2, cy - tp.height / 2),
      );
    }
  }

  /// 열 힌트 (상단)
  void _drawColHints(Canvas canvas, int size) {
    for (var c = 0; c < size; c++) {
      final count = state.current.colCounts[c];
      final currentTents = state.current.currentColTents(c);
      final isFulfilled = currentTents == count;
      final isExceeded = currentTents > count;

      Color textColor;
      if (isExceeded) {
        textColor = isDark ? Colors.red.shade400 : Colors.red.shade600;
      } else if (isFulfilled) {
        textColor = isDark ? Colors.green.shade400 : Colors.green.shade600;
      } else {
        textColor = isDark ? Colors.white70 : Colors.black54;
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final cx = hintAreaSize + c * cellSize + cellSize / 2;
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, (hintAreaSize - tp.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TentsBoardPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
