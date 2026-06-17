import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/motion_helper.dart';

/// 0 → [value] 로 카운트업하는 텍스트.
///
/// - 800ms easeOutCubic
/// - motionScale 적용 (0이면 즉시 최종값)
/// - 탭 시 즉시 종료 (선택)
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.formatter,
    this.style,
    this.durationMs = 800,
    this.prefs,
    this.onTapSkip = true,
  });

  final int value;
  final String Function(int v)? formatter;
  final TextStyle? style;
  final int durationMs;
  final SharedPreferences? prefs;
  final bool onTapSkip;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
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
  void didUpdateWidget(covariant CountUpText old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final current = (widget.value * _anim.value).round();
        final str = widget.formatter?.call(current) ?? current.toString();
        return Text(str, style: widget.style);
      },
    );
    if (!widget.onTapSkip) return text;
    return GestureDetector(
      onTap: () => _ctrl.value = 1.0,
      behavior: HitTestBehavior.translucent,
      child: text,
    );
  }
}
