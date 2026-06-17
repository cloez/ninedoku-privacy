import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/motion_helper.dart';

/// 마지막 변경 셀 펄스 효과 — 공통 위젯
///
/// 사용법:
/// ```dart
/// LastChangePulse(
///   lastChangedCell: state.lastChangedCell,
///   cellSize: cellSize,
///   child: BoardWidget(...),
/// )
/// ```
///
/// `lastChangedCell`이 변경될 때마다 해당 셀 위치에 0.4초간 펄스가 표시됩니다.
class LastChangePulse extends StatefulWidget {
  /// 마지막 변경 셀 (row, col)
  final (int, int)? lastChangedCell;

  /// 셀 크기 (픽셀)
  final double cellSize;

  /// 보드 위젯
  final Widget child;

  /// 펄스 색상
  final Color? pulseColor;

  /// 보드 시작 X 오프셋 (가로 힌트 영역 있는 게임용)
  final double offsetX;

  /// 보드 시작 Y 오프셋 (세로 힌트 영역 있는 게임용)
  final double offsetY;

  const LastChangePulse({
    super.key,
    required this.lastChangedCell,
    required this.cellSize,
    required this.child,
    this.pulseColor,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  @override
  State<LastChangePulse> createState() => _LastChangePulseState();
}

class _LastChangePulseState extends State<LastChangePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(LastChangePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastChangedCell != null &&
        widget.lastChangedCell != oldWidget.lastChangedCell) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 디자인 리뷰: warning amber 토큰 (라이트 #C28A2C / 다크 #E5B968)
    final color = widget.pulseColor ??
        (isDark ? AppColors.warningDark : AppColors.warningLight);

    // 효과 줄이기/시스템 애니메이션 비활성화 시 펄스 스킵 (child만 표시)
    final scale = motionScale(context);
    if (scale == 0.0) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (widget.lastChangedCell != null)
          AnimatedBuilder(
            animation: _opacity,
            builder: (context, _) {
              if (_opacity.value <= 0.01) return const SizedBox.shrink();
              return Positioned(
                left: widget.offsetX +
                    widget.lastChangedCell!.$2 * widget.cellSize,
                top: widget.offsetY +
                    widget.lastChangedCell!.$1 * widget.cellSize,
                width: widget.cellSize,
                height: widget.cellSize,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: _opacity.value),
                      border: Border.all(
                        color: color.withValues(alpha: _opacity.value * 1.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
