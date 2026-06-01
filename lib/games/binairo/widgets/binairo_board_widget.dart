import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../binairo_notifier.dart';
import '../binairo_state.dart';

/// Binairo 보드 위젯
class BinairoBoardWidget extends ConsumerWidget {
  const BinairoBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(binairoNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = gameState.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 반응형 셀 크기 계산
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final boardSize = maxSide - 4; // 약간의 여백
        final cellSize = boardSize / size;

        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: CustomPaint(
              painter: _BinairoBoardPainter(
                state: gameState,
                isDark: isDark,
                cellSize: cellSize,
              ),
              child: _buildGestureGrid(ref, gameState, cellSize, size),
            ),
          ),
        );
      },
    );
  }

  /// 셀별 탭 감지 그리드
  Widget _buildGestureGrid(
    WidgetRef ref,
    BinairoState state,
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
            final notifier = ref.read(binairoNotifierProvider.notifier);
            // 입력 모드에 따라 즉시 동작 (선택 없이 바로 배치)
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
class _BinairoBoardPainter extends CustomPainter {
  final BinairoState state;
  final bool isDark;
  final double cellSize;

  _BinairoBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final size = state.size;

    // 셀 배경 그리기
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _drawCellBackground(canvas, row, col, size);
      }
    }

    // 선택 셀 강조 테두리 (사용자 피드백: 선택 셀 식별 강화)
    if (state.selectedCell != null) {
      final (selRow, selCol) = state.selectedCell!;
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

    // 격자선 그리기
    _drawGrid(canvas, size, canvasSize);

    // 셀 값 그리기
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _drawCellValue(canvas, row, col, size);
      }
    }
  }

  /// 셀 배경 그리기
  void _drawCellBackground(Canvas canvas, int row, int col, int size) {
    final rect = Rect.fromLTWH(
      col * cellSize,
      row * cellSize,
      cellSize,
      cellSize,
    );

    Color? bgColor;

    // 선택된 셀
    if (state.selectedCell == (row, col)) {
      bgColor = isDark ? AppColors.cellSelectedDark : AppColors.cellSelectedLight;
    }
    // 같은 값 하이라이트
    else if (_shouldHighlightSameValue(row, col)) {
      bgColor = isDark ? AppColors.cellHighlightDark : AppColors.cellHighlightLight;
    }
    // 3연속 위반 감지
    else if (_hasTripleViolation(row, col)) {
      bgColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade100;
    }
    // 힌트 행/열 강조
    else if (_isHintHighlighted(row, col)) {
      bgColor = isDark
          ? Colors.amber.shade900.withValues(alpha: 0.2)
          : Colors.amber.shade50;
    }

    if (bgColor != null) {
      canvas.drawRect(rect, Paint()..color = bgColor);
    }
  }

  /// 같은 값 하이라이트 여부
  bool _shouldHighlightSameValue(int row, int col) {
    if (state.selectedCell == null) return false;
    final (selRow, selCol) = state.selectedCell!;
    final selectedValue = state.current.getValue(selRow, selCol);
    if (selectedValue == -1) return false;

    final cellValue = state.current.getValue(row, col);
    return cellValue == selectedValue && (row != selRow || col != selCol);
  }

  /// 3연속 위반 감지
  bool _hasTripleViolation(int row, int col) {
    final value = state.current.getValue(row, col);
    if (value == -1) return false;

    final size = state.size;

    // 행 방향: 현재 셀이 3연속의 일부인지
    if (_checkTripleInDirection(row, col, 0, 1, value, size)) return true;
    // 열 방향: 현재 셀이 3연속의 일부인지
    if (_checkTripleInDirection(row, col, 1, 0, value, size)) return true;

    return false;
  }

  /// 특정 방향에서 3연속 확인
  bool _checkTripleInDirection(
    int row, int col, int dRow, int dCol, int value, int size,
  ) {
    // 현재 셀 기준 3개 연속 패턴 검사 (현재 셀이 첫/중/마지막 위치)
    for (var offset = -2; offset <= 0; offset++) {
      var count = 0;
      for (var i = 0; i < 3; i++) {
        final r = row + (offset + i) * dRow;
        final c = col + (offset + i) * dCol;
        if (r < 0 || r >= size || c < 0 || c >= size) break;
        if (state.current.getValue(r, c) == value) {
          count++;
        } else {
          break;
        }
      }
      if (count >= 3) return true;
    }
    return false;
  }

  /// 힌트 강조 여부
  bool _isHintHighlighted(int row, int col) {
    final hint = state.lastHintResult;
    if (hint == null) return false;
    if (hint.highlightRows.contains(row) && hint.highlightCols.contains(col)) {
      return true;
    }
    // 행 전체 또는 열 전체 강조
    if (hint.highlightRows.contains(row) && hint.highlightCols.isEmpty) {
      return true;
    }
    if (hint.highlightCols.contains(col) && hint.highlightRows.isEmpty) {
      return true;
    }
    return false;
  }

  /// 격자선 그리기
  void _drawGrid(Canvas canvas, int size, Size canvasSize) {
    final linePaint = Paint()
      ..color = isDark ? AppColors.boardLineDark : AppColors.boardLineLight
      ..strokeWidth = 0.5;

    final borderPaint = Paint()
      ..color = isDark ? AppColors.boardLineDark : AppColors.boardLineLight
      ..strokeWidth = 2.0;

    // 얇은 격자선
    for (var i = 1; i < size; i++) {
      final pos = i * cellSize;
      canvas.drawLine(
        Offset(pos, 0),
        Offset(pos, canvasSize.height),
        linePaint,
      );
      canvas.drawLine(
        Offset(0, pos),
        Offset(canvasSize.width, pos),
        linePaint,
      );
    }

    // 외곽 테두리
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      borderPaint..style = PaintingStyle.stroke,
    );
  }

  /// 셀 값 그리기 — 흑백 원형 디자인
  void _drawCellValue(Canvas canvas, int row, int col, int size) {
    final value = state.current.getValue(row, col);
    if (value == -1) return;

    // 원 중심점과 반지름 — 모든 원 동일 크기
    final cx = col * cellSize + cellSize / 2;
    final cy = row * cellSize + cellSize / 2;
    final radius = cellSize * 0.32;
    const strokeWidth = 2.5;

    // 규칙 위반(3연속) 시에만 빨간색 표시
    final isViolation = _hasTripleViolation(row, col);
    final circleColor = isViolation
        ? (isDark ? Colors.red.shade400 : Colors.red.shade600)
        : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87);

    if (value == 0) {
      // ● 검은 원 (채워진 원)
      final paint = Paint()
        ..color = circleColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    } else {
      // ○ 흰 원 (테두리 원) — 외곽 기준으로 검은 원과 동일 크기
      final strokePaint = Paint()
        ..color = circleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(Offset(cx, cy), radius - strokeWidth / 2, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BinairoBoardPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
