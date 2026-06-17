import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/utils/motion_helper.dart';

/// 힌트 Level 1 영역 펄스 (박스/행/열 강조)
///
/// region이 변경될 때마다 1초간 옅은 노랑 펄스 애니메이션을 보여준다.
class HintRegionPulse extends StatefulWidget {
  /// 영역 정보: type='box'|'row'|'col', index=0~8
  /// (box는 0~8 박스 인덱스: 좌상단 0, 우하단 8)
  final ({String type, int index})? region;
  final double cellSize;
  final Widget child;

  const HintRegionPulse({
    super.key,
    required this.region,
    required this.cellSize,
    required this.child,
  });

  @override
  State<HintRegionPulse> createState() => _HintRegionPulseState();
}

class _HintRegionPulseState extends State<HintRegionPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // 초기 region이 지정되어 있으면 즉시 펄스
    if (widget.region != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(HintRegionPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    // region이 새로 지정되거나 바뀐 경우 펄스 재시작
    if (widget.region != null && widget.region != oldWidget.region) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 모션 감소 시 펄스 스킵
    if (motionScale(context) == 0) return widget.child;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 힌트 L1 영역 펄스 — warning(amber ink) 토큰
    final pulseColor = isDark ? AppColors.warningDark : AppColors.warningLight;
    return Stack(
      children: [
        widget.child,
        if (widget.region != null)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              if (t >= 1.0) return const SizedBox.shrink();
              // 0~0.5: 페이드인, 0.5~1.0: 페이드아웃
              final opacity = t < 0.5 ? (t * 2) * 0.3 : ((1 - t) * 2) * 0.3;
              return IgnorePointer(
                child: CustomPaint(
                  size: Size(widget.cellSize * 9, widget.cellSize * 9),
                  painter: _RegionPainter(
                    region: widget.region!,
                    cellSize: widget.cellSize,
                    opacity: opacity,
                    color: pulseColor,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// 영역 사각형 페인터 (박스/행/열 warning 토큰 오버레이)
class _RegionPainter extends CustomPainter {
  final ({String type, int index}) region;
  final double cellSize;
  final double opacity;
  final Color color;

  _RegionPainter({
    required this.region,
    required this.cellSize,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: opacity);
    switch (region.type) {
      case 'row':
        canvas.drawRect(
          Rect.fromLTWH(0, region.index * cellSize, cellSize * 9, cellSize),
          paint,
        );
      case 'col':
        canvas.drawRect(
          Rect.fromLTWH(region.index * cellSize, 0, cellSize, cellSize * 9),
          paint,
        );
      case 'box':
        final br = (region.index ~/ 3) * 3;
        final bc = (region.index % 3) * 3;
        canvas.drawRect(
          Rect.fromLTWH(
            bc * cellSize,
            br * cellSize,
            cellSize * 3,
            cellSize * 3,
          ),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _RegionPainter old) =>
      old.opacity != opacity || old.region != region || old.color != color;
}
