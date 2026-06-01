import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/l10n/app_strings.dart';
import '../game_notifier.dart';
import '../game_state.dart';
import '../../../shared/constants/app_colors.dart';

/// 게임 상단 정보 바 (난이도, 실수, 타이머)
class GameInfoBar extends ConsumerWidget {
  const GameInfoBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRelax = gameState.mode == GameMode.relax;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: isLandscape
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 난이도
          _InfoChip(
            label: AppStrings.get('difficulty.${gameState.difficulty.name}'),
            isDark: isDark,
          ),
          // 남은 빈 칸 수
          _InfoChip(
            icon: Icons.grid_view_rounded,
            label: '${gameState.board.emptyCellCount}',
            isDark: isDark,
          ),
          // 실수 카운트 (릴렉스 모드에서는 숨김)
          if (gameState.showMistakes)
            _InfoChip(
              icon: Icons.close,
              label: gameState.maxMistakes != null
                  ? '${AppStrings.get('game.mistakes')} ${gameState.mistakeCount}/${gameState.maxMistakes}'
                  : '${AppStrings.get('game.mistakes')} ${gameState.mistakeCount}',
              isWarning: gameState.mistakeCount > 0,
              isDark: isDark,
            ),
          // 타이머 (릴렉스 모드에서는 숨김)
          if (!isRelax)
            _TimerDisplay(
              seconds: gameState.elapsedSeconds,
              isPaused: gameState.isPaused,
              isDark: isDark,
              onPause: () => ref.read(gameProvider.notifier).pause(),
            ),
        ],
      ),
    );
  }
}

/// 정보 칩 (난이도, 실수)
class _InfoChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isWarning;
  final bool isDark;

  const _InfoChip({
    this.icon,
    required this.label,
    this.isWarning = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? (isDark ? AppColors.wrongNumberDark : AppColors.wrongNumberLight)
        : (isDark ? Colors.white70 : Colors.black54);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 2),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 타이머 표시
class _TimerDisplay extends StatelessWidget {
  final int seconds;
  final bool isPaused;
  final bool isDark;
  final VoidCallback onPause;

  const _TimerDisplay({
    required this.seconds,
    required this.isPaused,
    required this.isDark,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeText = '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final color = isDark ? Colors.white70 : Colors.black54;

    return Semantics(
      button: true,
      label: isPaused ? AppStrings.get('a11y.timer.resume') : AppStrings.get('a11y.timer.pause'),
      child: GestureDetector(
        onTap: onPause,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
