import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../../../shared/widgets/line_complete_pulse.dart';
import '../kakuro_notifier.dart';
import '../kakuro_state.dart';
import '../engine/kakuro_board.dart';
import '../engine/kakuro_solver.dart';

/// 카쿠로 보드 위젯
/// 검은 셀에 대각선 분할 (왼상→우하 대각선, 위에 down 힌트, 아래에 across 힌트)
class KakuroBoardWidget extends ConsumerWidget {
  const KakuroBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(kakuroNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = gameState.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        final cellSize = (maxSide - 8) / size;

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
                width: size * cellSize,
                height: size * cellSize,
                child: CustomPaint(
                  painter: _KakuroBoardPainter(
                    state: gameState,
                    isDark: isDark,
                    cellSize: cellSize,
                  ),
                  child: _buildGestureOverlay(ref, gameState, cellSize, size),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 셀별 탭 감지 오버레이 (흰 셀만)
  Widget _buildGestureOverlay(
    WidgetRef ref,
    KakuroState state,
    double cellSize,
    int size,
  ) {
    return Stack(
      children: [
        for (var r = 0; r < size; r++)
          for (var c = 0; c < size; c++)
            if (state.current.getCell(r, c).type == KakuroCellType.white)
              Positioned(
                left: c * cellSize,
                top: r * cellSize,
                width: cellSize,
                height: cellSize,
                child: GestureDetector(
                  onTap: () {
                    ref.read(kakuroNotifierProvider.notifier).selectCell(r, c);
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
class _KakuroBoardPainter extends CustomPainter {
  final KakuroState state;
  final bool isDark;
  final double cellSize;

  _KakuroBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final size = state.size;

    // 셀 그리기
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        _drawCell(canvas, r, c, size);
      }
    }

    // 격자선 그리기
    _drawGridLines(canvas, size);
  }

  /// 셀 위치 계산
  Rect _cellRect(int row, int col) {
    return Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize);
  }

  /// 셀 그리기
  void _drawCell(Canvas canvas, int row, int col, int size) {
    final rect = _cellRect(row, col);
    final cell = state.current.getCell(row, col);

    if (cell.type == KakuroCellType.black) {
      _drawBlackCell(canvas, rect, cell);
    } else {
      _drawWhiteCell(canvas, rect, row, col, size);
    }
  }

  /// 검은 셀 그리기 (대각선 분할 + 힌트 숫자)
  void _drawBlackCell(Canvas canvas, Rect rect, KakuroCell cell) {
    // 검은 배경
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF2A2A2A) : const Color(0xFF3A3A3A);
    canvas.drawRect(rect, bgPaint);

    final hasAcross = cell.acrossHint != null;
    final hasDown = cell.downHint != null;

    if (!hasAcross && !hasDown) return;

    // 대각선 (왼상 → 우하)
    if (hasAcross || hasDown) {
      final diagonalPaint = Paint()
        ..color = isDark ? Colors.white24 : Colors.white38
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(rect.left, rect.top),
        Offset(rect.right, rect.bottom),
        diagonalPaint,
      );
    }

    final fontSize = cellSize * 0.28;

    // down 힌트 (오른쪽 위 삼각형 영역)  — 아래쪽 블록 합계
    if (hasDown) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${cell.downHint}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      // 오른쪽 위 영역 중앙
      final cx = rect.left + cellSize * 0.7;
      final cy = rect.top + cellSize * 0.3;
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }

    // across 힌트 (왼쪽 아래 삼각형 영역) — 오른쪽 블록 합계
    if (hasAcross) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${cell.acrossHint}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      // 왼쪽 아래 영역 중앙
      final cx = rect.left + cellSize * 0.3;
      final cy = rect.top + cellSize * 0.7;
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  /// 흰 셀 그리기 (배경 + 값/메모)
  void _drawWhiteCell(Canvas canvas, Rect rect, int row, int col, int size) {
    final idx = row * state.current.cols + col;
    final value = state.current.getValue(row, col);

    // 배경색 결정
    Color bgColor;
    final isSelected = state.selectedCell == (row, col);
    final isFixed = state.current.fixed.contains(idx);
    final hasConflict = value != 0 &&
        KakuroSolver.hasBlockConflict(state.current, row, col);
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
      bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    }

    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(rect, bgPaint);

    // 값 또는 메모 그리기
    if (value != 0) {
      _drawValue(canvas, rect, value, isFixed, hasConflict);
    } else if (state.current.notes.containsKey(idx)) {
      _drawNotes(canvas, rect, state.current.notes[idx]!);
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
  void _drawNotes(Canvas canvas, Rect rect, Set<int> notes) {
    const gridCols = 3;
    const gridRows = 3;
    final fontSize = cellSize / 4 * 0.7;

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
    final gridRect = Rect.fromLTWH(0, 0, size * cellSize, size * cellSize);
    canvas.drawRect(gridRect, boldPaint..style = PaintingStyle.stroke);

    // 내부 격자선
    for (var i = 1; i < size; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size * cellSize),
        linePaint,
      );
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size * cellSize, y),
        linePaint,
      );
    }
  }

  /// 힌트 강조 여부
  bool _isHintHighlighted(int row, int col) {
    final hint = state.lastHintResult;
    if (hint == null) return false;
    return hint.highlightCells.contains((row, col));
  }

  @override
  bool shouldRepaint(covariant _KakuroBoardPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
