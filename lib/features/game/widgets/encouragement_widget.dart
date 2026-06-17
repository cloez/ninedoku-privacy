import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../game_notifier.dart';
import '../game_state.dart';

/// 추임새 오버레이 위젯 — 정답 입력 시 화면에 애니메이션 텍스트 표시
class EncouragementWidget extends ConsumerStatefulWidget {
  const EncouragementWidget({super.key});

  @override
  ConsumerState<EncouragementWidget> createState() => _EncouragementWidgetState();
}

class _EncouragementWidgetState extends ConsumerState<EncouragementWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;
  Encouragement? _currentEncouragement;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(gameProvider.notifier).clearEncouragement();
        setState(() => _currentEncouragement = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 추임새 변화 감지
    ref.listen<GameState?>(gameProvider, (prev, next) {
      if (next?.lastEncouragement != null &&
          next!.lastEncouragement != _currentEncouragement) {
        _currentEncouragement = next.lastEncouragement;
        _controller.forward(from: 0.0);
        setState(() {});
      }
    });

    if (_currentEncouragement == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: _buildText(context),
          ),
        );
      },
    );
  }

  Widget _buildText(BuildContext context) {
    final (color, icon) = _styleForEncouragement(_currentEncouragement!);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 6),
        Text(
          _currentEncouragement!.message,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
            ],
          ),
        ),
      ],
    );
  }

  (Color, String) _styleForEncouragement(Encouragement e) {
    // 디자인 리뷰: 추임새 톤 일관성 (다크 모드는 명도 상향 토큰)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (e) {
      case Encouragement.good:
        // success jade
        return (isDark ? AppColors.successDark : AppColors.successLight, '👍');
      case Encouragement.excellent:
        // info slate
        return (isDark ? AppColors.infoDark : AppColors.infoLight, '⭐');
      case Encouragement.perfect:
        // 디톤된 골드 (순금색 회피)
        return (AppColors.encouragementPerfect, '🔥');
    }
  }
}
