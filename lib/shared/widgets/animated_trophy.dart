import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/motion_helper.dart';

/// 배지/트로피 등장 애니메이션 — 스케일 + 회전 + 글로우.
///
/// 500ms easeOutBack 스케일, easeOut 회전(살짝).
class AnimatedTrophy extends StatefulWidget {
  const AnimatedTrophy({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFFFD54F),
    this.durationMs = 500,
    this.prefs,
  });

  final Widget child;
  final Color glowColor;
  final int durationMs;
  final SharedPreferences? prefs;

  @override
  State<AnimatedTrophy> createState() => _AnimatedTrophyState();
}

class _AnimatedTrophyState extends State<AnimatedTrophy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scale = motionScale(context, prefs: widget.prefs);
    if (scale == 0.0) {
      _ctrl.value = 1.0;
    } else {
      _ctrl.duration =
          Duration(milliseconds: (widget.durationMs * scale).round());
      if (!_ctrl.isAnimating && _ctrl.value == 0.0) {
        _ctrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        // easeOutBack 스케일 0 → 1.0 (오버슈트 살짝)
        final scaleCurve = Curves.easeOutBack.transform(t);
        // 회전: -0.15 → 0
        final rot = (1 - t) * -0.15;
        // 글로우 alpha: 0 → 0.6 → 0
        final glowAlpha = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.6;
        return Stack(
          alignment: Alignment.center,
          children: [
            // 글로우
            IgnorePointer(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: glowAlpha),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Transform.rotate(
              angle: rot,
              child: Transform.scale(
                scale: scaleCurve,
                child: child,
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
