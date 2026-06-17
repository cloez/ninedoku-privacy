import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/motion_helper.dart';

/// 셀 입력 / 실수 시 스케일 + shake 애니메이션을 주는 래퍼.
///
/// - [pulseKey] 가 바뀔 때마다 펄스(스케일 1.0 → 1.08 → 1.0)
/// - [shakeKey] 가 바뀔 때마다 좌우 흔들림 (cellSize × 0.08, clamp 2~6px)
class AnimatedCell extends StatefulWidget {
  const AnimatedCell({
    super.key,
    required this.child,
    required this.cellSize,
    this.pulseKey,
    this.shakeKey,
    this.prefs,
  });

  final Widget child;
  final double cellSize;
  final Object? pulseKey;
  final Object? shakeKey;
  final SharedPreferences? prefs;

  @override
  State<AnimatedCell> createState() => _AnimatedCellState();
}

class _AnimatedCellState extends State<AnimatedCell>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseKey != null && widget.pulseKey != oldWidget.pulseKey) {
      _runPulse();
    }
    if (widget.shakeKey != null && widget.shakeKey != oldWidget.shakeKey) {
      _runShake();
    }
  }

  void _runPulse() {
    final scale = motionScale(context, prefs: widget.prefs);
    if (scale == 0.0) return;
    _pulseCtrl.duration = Duration(milliseconds: (150 * scale).round());
    _pulseCtrl.forward(from: 0.0);
  }

  void _runShake() {
    final scale = motionScale(context, prefs: widget.prefs);
    if (scale == 0.0) return;
    _shakeCtrl.duration = Duration(milliseconds: (200 * scale).round());
    _shakeCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // shake 진폭: cellSize × 0.08, clamp 2~6
    final amplitude = (widget.cellSize * 0.08).clamp(2.0, 6.0);
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _shakeCtrl]),
      builder: (context, child) {
        // 펄스: 1.0 → 1.08 → 1.0
        final pulseT = _pulseCtrl.value;
        final scale = 1.0 + math.sin(pulseT * math.pi) * 0.08;

        // shake: sin(t * π * 3) * amplitude * (1 - t)
        final shakeT = _shakeCtrl.value;
        final dx = shakeT == 0
            ? 0.0
            : math.sin(shakeT * math.pi * 3) * amplitude * (1 - shakeT);

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
