import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/motion_helper.dart';

/// L4 정답 공개 시 글로우 + scale 애니메이션 — game-agnostic
class HintRevealPulse extends StatefulWidget {
  final Widget child;
  final bool active;

  const HintRevealPulse({
    super.key,
    required this.child,
    required this.active,
  });

  @override
  State<HintRevealPulse> createState() => _HintRevealPulseState();
}

class _HintRevealPulseState extends State<HintRevealPulse>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.active) _startAnimations();
  }

  @override
  void didUpdateWidget(covariant HintRevealPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    _scaleCtrl
      ..reset()
      ..forward();
    _glowCtrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final scale = motionScale(context);
    if (scale == 0.0) return widget.child;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleCtrl, _glowCtrl]),
      builder: (context, child) {
        final t = _scaleCtrl.value;
        final scaleValue = t < 0.5
            ? 0.5 + (1.2 - 0.5) * (t / 0.5)
            : 1.2 + (1.0 - 1.2) * ((t - 0.5) / 0.5);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final glowStart = isDark
            ? AppColors.jadeBloomMidDarkMode
            : AppColors.jadeBloomMid;
        final glowEnd = isDark
            ? AppColors.jadeBloomDarkDarkMode
            : AppColors.jadeBloomDark;
        final g = _glowCtrl.value;
        final glowColor = Color.lerp(glowStart, glowEnd, g)!;
        final alpha = 0.5 * (1.0 - g);
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: alpha),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Transform.scale(
            scale: scaleValue,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
