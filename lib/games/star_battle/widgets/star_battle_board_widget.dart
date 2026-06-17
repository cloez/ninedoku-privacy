import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../../../shared/widgets/line_complete_pulse.dart';
import '../star_battle_notifier.dart';
import '../star_battle_state.dart';

/// 영역별 배경 색상 팔레트 (라이트/다크 모드)
const _regionColorsLight = [
  Color(0xFFE3F2FD), // 연한 파랑
  Color(0xFFFCE4EC), // 연한 분홍
  Color(0xFFE8F5E9), // 연한 초록
  Color(0xFFFFF3E0), // 연한 주황
  Color(0xFFF3E5F5), // 연한 보라
  Color(0xFFE0F7FA), // 연한 시안
  Color(0xFFFFF9C4), // 연한 노랑
  Color(0xFFEFEBE9), // 연한 갈색
  Color(0xFFE8EAF6), // 연한 인디고
  Color(0xFFF1F8E9), // 연한 라임
];

const _regionColorsDark = [
  Color(0xFF1A237E), // 어두운 파랑
  Color(0xFF880E4F), // 어두운 분홍
  Color(0xFF1B5E20), // 어두운 초록
  Color(0xFFE65100), // 어두운 주황
  Color(0xFF4A148C), // 어두운 보라
  Color(0xFF006064), // 어두운 시안
  Color(0xFFF57F17), // 어두운 노랑
  Color(0xFF3E2723), // 어두운 갈색
  Color(0xFF283593), // 어두운 인디고
  Color(0xFF33691E), // 어두운 라임
];

/// Star Battle 보드 위젯
class StarBattleBoardWidget extends ConsumerWidget {
  const StarBattleBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(starBattleNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = gameState.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 반응형 셀 크기 계산
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
                  painter: _StarBattleBoardPainter(
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
    StarBattleState state,
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
            final notifier = ref.read(starBattleNotifierProvider.notifier);
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
class _StarBattleBoardPainter extends CustomPainter {
  final StarBattleState state;
  final bool isDark;
  final double cellSize;

  _StarBattleBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final size = state.size;

    // 영역 배경 그리기
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _drawRegionBackground(canvas, row, col);
      }
    }

    // 선택 셀 강조
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

    // 얇은 격자선 그리기
    _drawGrid(canvas, size, canvasSize);

    // 영역 경계선 굵게 그리기
    _drawRegionBorders(canvas, size, canvasSize);

    // 셀 값 그리기 (★/X)
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _drawCellValue(canvas, row, col);
      }
    }
  }

  /// 영역 배경색 그리기
  void _drawRegionBackground(Canvas canvas, int row, int col) {
    final region = state.current.getRegion(row, col);
    final colors = isDark ? _regionColorsDark : _regionColorsLight;
    final color = colors[region % colors.length];

    final rect = Rect.fromLTWH(
      col * cellSize,
      row * cellSize,
      cellSize,
      cellSize,
    );

    // 힌트 강조 여부에 따라 배경 조정
    Color bgColor = color;
    if (_isHintHighlighted(row, col)) {
      bgColor = isDark
          ? Colors.amber.shade900.withValues(alpha: 0.4)
          : Colors.amber.shade100;
    }

    canvas.drawRect(rect, Paint()..color = bgColor);
  }

  /// 힌트 강조 여부
  bool _isHintHighlighted(int row, int col) {
    final hint = state.lastHintResult;
    if (hint == null) return false;

    // 힌트 대상 셀 직접 강조
    if (hint.row == row && hint.col == col) return true;

    // 영역 강조
    if (hint.highlightRegions.isNotEmpty) {
      final region = state.current.getRegion(row, col);
      if (hint.highlightRegions.contains(region) &&
          hint.highlightRows.isEmpty && hint.highlightCols.isEmpty) {
        return false; // 영역만 강조는 배경으로 충분
      }
    }

    return false;
  }

  /// 얇은 격자선 그리기
  void _drawGrid(Canvas canvas, int size, Size canvasSize) {
    final linePaint = Paint()
      ..color = isDark ? AppColors.boardLineDark.withValues(alpha: 0.3) : AppColors.boardLineLight.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (var i = 1; i < size; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, canvasSize.height), linePaint);
      canvas.drawLine(Offset(0, pos), Offset(canvasSize.width, pos), linePaint);
    }
  }

  /// 영역 경계선 굵게 그리기
  void _drawRegionBorders(Canvas canvas, int size, Size canvasSize) {
    final borderPaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black87
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // 각 셀에 대해 인접 셀과 영역이 다르면 경계선 그리기
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final region = state.current.getRegion(row, col);
        final x = col * cellSize;
        final y = row * cellSize;

        // 오른쪽 이웃과 영역이 다름
        if (col < size - 1 && state.current.getRegion(row, col + 1) != region) {
          canvas.drawLine(
            Offset(x + cellSize, y),
            Offset(x + cellSize, y + cellSize),
            borderPaint,
          );
        }
        // 아래 이웃과 영역이 다름
        if (row < size - 1 && state.current.getRegion(row + 1, col) != region) {
          canvas.drawLine(
            Offset(x, y + cellSize),
            Offset(x + cellSize, y + cellSize),
            borderPaint,
          );
        }
      }
    }

    // 외곽 테두리
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      borderPaint,
    );
  }

  /// 셀 값 그리기 — ★ 또는 X
  void _drawCellValue(Canvas canvas, int row, int col) {
    final value = state.current.getValue(row, col);
    if (value == -1) return;

    final cx = col * cellSize + cellSize / 2;
    final cy = row * cellSize + cellSize / 2;

    // 위반 감지 (인접 별 또는 초과)
    final isViolation = value == 1 && _hasViolation(row, col);

    if (value == 1) {
      // ★ 별 그리기
      final color = isViolation
          ? (isDark ? Colors.red.shade400 : Colors.red.shade600)
          : (isDark ? Colors.amber.shade300 : Colors.amber.shade700);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '★',
          style: TextStyle(
            fontSize: cellSize * 0.6,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
      );
    } else if (value == 0) {
      // X 그리기
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

  /// 별 위반 감지 (인접 별 또는 행/열/영역 초과)
  bool _hasViolation(int row, int col) {
    final size = state.size;
    final starCount = state.starCount;
    final cells = state.current.cells;
    final regions = state.current.regions;

    // 인접 확인
    for (final (dr, dc) in [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]) {
      final nr = row + dr;
      final nc = col + dc;
      if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
      if (cells[nr * size + nc] == 1) return true;
    }

    // 행 초과
    var rowStars = 0;
    for (var c = 0; c < size; c++) {
      if (cells[row * size + c] == 1) rowStars++;
    }
    if (rowStars > starCount) return true;

    // 열 초과
    var colStars = 0;
    for (var r = 0; r < size; r++) {
      if (cells[r * size + col] == 1) colStars++;
    }
    if (colStars > starCount) return true;

    // 영역 초과
    final region = regions[row * size + col];
    var regionStars = 0;
    for (var i = 0; i < cells.length; i++) {
      if (regions[i] == region && cells[i] == 1) regionStars++;
    }
    if (regionStars > starCount) return true;

    return false;
  }

  @override
  bool shouldRepaint(covariant _StarBattleBoardPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
