import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/motion_helper.dart';

/// 게임 보드 상단에 표시되는 4px 진행률 바.
///
/// - [progress] 0.0 ~ 1.0
/// - 부드러운 트윈 (300ms × motionScale)
class BoardProgressBar extends StatelessWidget {
  const BoardProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 4.0,
    this.prefs,
  });

  final double progress;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final SharedPreferences? prefs;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: clamped, end: clamped),
      duration: scaledDuration(context, 300, prefs: prefs),
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}
