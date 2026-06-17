import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/motion_helper.dart';

/// 완성된 라인 정보 — game-agnostic
///
/// type:
///  - 'row': 행 완성 (index = row index)
///  - 'col': 열 완성 (index = col index)
///  - 'box': 3x3 박스 (스도쿠/킬러 — 9x9 가정)
///  - 'region': 불규칙 영역 (Jigsaw, Star Battle) — regionCells 필수
///  - 'cage': 케이지 (Killer) — regionCells 필수
///  - 'count': 카운트 충족 라인 (Tents) — row와 동일하게 표시
///  - 'all': 보드 전체 완성 (Yin Yang, Minesweeper, Light Up, Kakuro)
class CompletedLine {
  final String type;
  final int index;

  /// region/cage 타입에서 셀 좌표 목록
  final List<(int, int)>? regionCells;

  const CompletedLine(this.type, this.index, {this.regionCells});
}

/// 라인/박스/영역/케이지/카운트/전체 완성 시 다이내믹 펄스 오버레이.
class LineCompletePulse extends StatefulWidget {
  final List<CompletedLine> lines;
  final double cellSize;
  final Widget child;

  /// 보드 가로 셀 수 (기본 9)
  final int gridWidth;

  /// 보드 세로 셀 수 (기본 9)
  final int gridHeight;

  const LineCompletePulse({
    super.key,
    required this.lines,
    required this.cellSize,
    required this.child,
    this.gridWidth = 9,
    this.gridHeight = 9,
  });

  @override
  State<LineCompletePulse> createState() => _LineCompletePulseState();
}

class _LineCompletePulseState extends State<LineCompletePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<CompletedLine> _activeLines = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(LineCompletePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 새 완성 라인 감지
    final wasEmpty = oldWidget.lines.isEmpty;
    final isFilled = widget.lines.isNotEmpty;
    if (isFilled && (wasEmpty || widget.lines.length != oldWidget.lines.length)) {
      setState(() {
        _activeLines = List.of(widget.lines);
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 모션 감소 시 효과 스킵
    if (motionScale(context) == 0.0) return widget.child;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        if (_activeLines.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = _controller.value;
                  if (t >= 1.0) return const SizedBox.shrink();
                  return CustomPaint(
                    painter: _DynamicLinePulsePainter(
                      lines: _activeLines,
                      cellSize: widget.cellSize,
                      progress: t,
                      isDark: isDark,
                      gridWidth: widget.gridWidth,
                      gridHeight: widget.gridHeight,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _DynamicLinePulsePainter extends CustomPainter {
  final List<CompletedLine> lines;
  final double cellSize;
  final double progress;
  final bool isDark;
  final int gridWidth;
  final int gridHeight;

  _DynamicLinePulsePainter({
    required this.lines,
    required this.cellSize,
    required this.progress,
    required this.isDark,
    required this.gridWidth,
    required this.gridHeight,
  });

  static const double _staggerSpan = 0.4;

  double _cellAlpha(double cellProgress) {
    if (cellProgress <= 0 || cellProgress >= 1) return 0;
    if (cellProgress < 0.25) return cellProgress / 0.25;
    if (cellProgress < 0.6) return 1.0;
    return (1.0 - cellProgress) / 0.4;
  }

  Color _pulseColor(double t) {
    final cLight = isDark ? AppColors.jadeBloomLightDarkMode : AppColors.jadeBloomLight;
    final cMid = isDark ? AppColors.jadeBloomMidDarkMode : AppColors.jadeBloomMid;
    final cDark = isDark ? AppColors.jadeBloomDarkDarkMode : AppColors.jadeBloomDark;
    if (t < 0.4) {
      final f = t / 0.4;
      return Color.lerp(cLight, cMid, f)!;
    }
    final f = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    return Color.lerp(cMid, cDark, f)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final color = _pulseColor(progress);

    for (final line in lines) {
      final cells = _cellsOfLine(line);
      if (cells.isEmpty) continue;
      final denom = cells.length > 1 ? cells.length - 1 : 1;
      for (var i = 0; i < cells.length; i++) {
        final (r, c) = cells[i];
        final offset = (i / denom) * _staggerSpan;
        final cellProgress = ((progress - offset) / (1.0 - _staggerSpan))
            .clamp(0.0, 1.0);
        final alpha = _cellAlpha(cellProgress);
        if (alpha <= 0) continue;
        _paintCell(canvas, r, c, color, alpha);
      }
    }
  }

  void _paintCell(Canvas canvas, int row, int col, Color baseColor, double alpha) {
    final center = Offset(
      (col + 0.5) * cellSize,
      (row + 0.5) * cellSize,
    );
    final scale = 1.0 + 0.08 * alpha;
    final halfSize = cellSize * 0.5 * scale;
    final rect = Rect.fromCenter(
      center: center,
      width: halfSize * 2,
      height: halfSize * 2,
    );

    final glowPaint = Paint()
      ..color = baseColor.withValues(alpha: alpha * 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(2), const Radius.circular(6)),
      glowPaint,
    );

    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: alpha * 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      fillPaint,
    );

    final strokePaint = Paint()
      ..color = baseColor.withValues(alpha: alpha * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      strokePaint,
    );
  }

  List<(int, int)> _cellsOfLine(CompletedLine line) {
    switch (line.type) {
      case 'row':
      case 'count':
        return List.generate(gridWidth, (c) => (line.index, c));
      case 'col':
        return List.generate(gridHeight, (r) => (r, line.index));
      case 'box':
        // 9x9 — 3x3 박스
        final br = (line.index ~/ 3) * 3;
        final bc = (line.index % 3) * 3;
        final cells = <(int, int)>[];
        for (var r = 0; r < 3; r++) {
          for (var c = 0; c < 3; c++) {
            cells.add((br + r, bc + c));
          }
        }
        cells.sort((a, b) {
          final da = (a.$1 - br) + (a.$2 - bc);
          final db = (b.$1 - br) + (b.$2 - bc);
          return da.compareTo(db);
        });
        return cells;
      case 'region':
      case 'cage':
        if (line.regionCells == null) return const [];
        final cells = List<(int, int)>.from(line.regionCells!);
        cells.sort((a, b) {
          final da = a.$1 + a.$2;
          final db = b.$1 + b.$2;
          return da.compareTo(db);
        });
        return cells;
      case 'all':
        final cells = <(int, int)>[];
        for (var r = 0; r < gridHeight; r++) {
          for (var c = 0; c < gridWidth; c++) {
            cells.add((r, c));
          }
        }
        cells.sort((a, b) {
          final da = a.$1 + a.$2;
          final db = b.$1 + b.$2;
          return da.compareTo(db);
        });
        return cells;
      default:
        return const [];
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicLinePulsePainter old) =>
      old.progress != progress || old.lines != lines;
}
