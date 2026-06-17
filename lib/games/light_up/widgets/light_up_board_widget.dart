import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../../../shared/widgets/line_complete_pulse.dart';
import '../light_up_notifier.dart';
import '../light_up_state.dart';
import '../engine/light_up_board.dart';

/// Light Up 보드 위젯
class LightUpBoardWidget extends ConsumerWidget {
  const LightUpBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(lightUpNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = gameState.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final boardSize = maxSide - 4;
        final cellSize = boardSize / size;

        // 게임 완료 시 보드 전체 펄스
        final completedLines = gameState.isCompleted
            ? const [CompletedLine('all', 0)]
            : const <CompletedLine>[];
        return Center(
          child: LastChangePulse(
            lastChangedCell: gameState.selectedCell,
            cellSize: cellSize,
            child: LineCompletePulse(
              lines: completedLines,
              cellSize: cellSize,
              gridWidth: size,
              gridHeight: size,
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: CustomPaint(
                  painter: _LightUpBoardPainter(
                    state: gameState,
                    isDark: isDark,
                    cellSize: cellSize,
                  ),
                  child: _buildGestureGrid(ref, gameState, cellSize, size),
                ),
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
    LightUpState state,
    double cellSize,
    int size,
  ) {
    return GridView.builder(
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
            final notifier = ref.read(lightUpNotifierProvider.notifier);
            notifier.tapCell(row, col);
          },
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/// 보드 그리기 Painter
class _LightUpBoardPainter extends CustomPainter {
  final LightUpState state;
  final bool isDark;
  final double cellSize;

  _LightUpBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final size = state.size;
    final litCells = state.current.getLitCells();

    // 셀 배경 그리기
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _drawCellBackground(canvas, row, col, litCells);
      }
    }

    // 선택 셀 강조
    if (state.selectedCell != null) {
      final (selRow, selCol) = state.selectedCell!;
      if (!state.current.isWall(selRow, selCol)) {
        final selRect = Rect.fromLTWH(
          selCol * cellSize + 1, selRow * cellSize + 1,
          cellSize - 2, cellSize - 2,
        );
        final selPaint = Paint()
          ..color = isDark ? Colors.blue.shade300 : Colors.blue.shade600
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawRect(selRect, selPaint);
      }
    }

    // 격자선 그리기
    _drawGrid(canvas, size, canvasSize);

    // 셀 값 그리기 (전구/X/벽 숫자)
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _drawCellValue(canvas, row, col);
      }
    }
  }

  /// 셀 배경색 그리기
  void _drawCellBackground(Canvas canvas, int row, int col, Set<int> litCells) {
    final rect = Rect.fromLTWH(
      col * cellSize, row * cellSize, cellSize, cellSize,
    );

    Color bgColor;
    if (state.current.isWall(row, col)) {
      // 벽: 검은색/어두운 회색
      bgColor = isDark ? const Color(0xFF333333) : const Color(0xFF2D2D2D);
    } else if (_isHintHighlighted(row, col)) {
      // 힌트 강조
      bgColor = isDark
          ? Colors.amber.shade900.withValues(alpha: 0.4)
          : Colors.amber.shade100;
    } else if (litCells.contains(row * state.size + col)) {
      // 빛이 비추는 영역: 밝은 노란색
      bgColor = isDark
          ? const Color(0xFF3A3520) // 어두운 노란
          : const Color(0xFFFFF9C4); // 밝은 노란
    } else {
      // 비춰지지 않은 흰 칸
      bgColor = isDark
          ? const Color(0xFF1A1A2E)
          : Colors.white;
    }

    canvas.drawRect(rect, Paint()..color = bgColor);
  }

  /// 힌트 강조 여부
  bool _isHintHighlighted(int row, int col) {
    final hint = state.lastHintResult;
    if (hint == null) return false;
    return hint.row == row && hint.col == col;
  }

  /// 격자선 그리기
  void _drawGrid(Canvas canvas, int size, Size canvasSize) {
    final linePaint = Paint()
      ..color = isDark
          ? AppColors.boardLineDark.withValues(alpha: 0.5)
          : AppColors.boardLineLight.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (var i = 0; i <= size; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, canvasSize.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(canvasSize.width, pos), linePaint);
    }

    // 외곽 테두리
    final borderPaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black87
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      borderPaint,
    );
  }

  /// 셀 값 그리기
  void _drawCellValue(Canvas canvas, int row, int col) {
    final value = state.current.getValue(row, col);
    final cx = col * cellSize + cellSize / 2;
    final cy = row * cellSize + cellSize / 2;

    // 벽 숫자 표시
    final wallNum = state.current.getWallNumber(row, col);
    if (wallNum >= 0) {
      // 벽 숫자 충족 여부 색상
      final adjBulbs = state.current.adjacentBulbCount(row, col);
      Color numColor;
      if (adjBulbs > wallNum) {
        numColor = Colors.red.shade400; // 초과
      } else if (adjBulbs == wallNum) {
        numColor = isDark ? Colors.green.shade300 : Colors.green.shade600; // 충족
      } else {
        numColor = isDark ? Colors.white70 : Colors.white; // 미충족
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$wallNum',
          style: TextStyle(
            fontSize: cellSize * 0.5,
            fontWeight: FontWeight.bold,
            color: numColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
      return;
    }

    // 숫자 없는 벽은 배경만
    if (value == LightUpBoard.wallBlank) return;

    // 전구 💡
    if (value == LightUpBoard.bulb) {
      final hasConflict = state.current.hasBulbConflict(row, col);
      final color = hasConflict
          ? (isDark ? Colors.red.shade400 : Colors.red.shade600)
          : (isDark ? Colors.amber.shade300 : Colors.amber.shade700);

      // 전구 아이콘 배경 원
      final circlePaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), cellSize * 0.35, circlePaint);

      // 전구 텍스트
      final textPainter = TextPainter(
        text: TextSpan(
          text: '💡',
          style: TextStyle(fontSize: cellSize * 0.5),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
      return;
    }

    // X 표시
    if (value == LightUpBoard.cross) {
      final xColor = isDark ? Colors.white38 : Colors.black26;
      final xPaint = Paint()
        ..color = xColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final margin = cellSize * 0.3;
      canvas.drawLine(
        Offset(cx - margin, cy - margin),
        Offset(cx + margin, cy + margin),
        xPaint,
      );
      canvas.drawLine(
        Offset(cx + margin, cy - margin),
        Offset(cx - margin, cy + margin),
        xPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LightUpBoardPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
