import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/constants/app_colors.dart';
import '../../game/game_notifier.dart';
import '../../game/game_state.dart';
import '../../../core/sudoku/difficulty.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/settings/settings_service.dart';

/// 모드 선택 화면 (S-03)
class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('mode.title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _ModeCard(
                icon: Icons.workspace_premium_rounded,
                title: AppStrings.get('mode.classic'),
                description: AppStrings.get('mode.classic.desc'),
                onTap: () => context.push(
                  AppRoutes.difficultySelect,
                  extra: 'classic',
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _ModeCard(
                icon: Icons.spa_rounded,
                title: AppStrings.get('mode.relax'),
                description: AppStrings.get('mode.relax.desc'),
                onTap: () => context.push(
                  AppRoutes.difficultySelect,
                  extra: 'relax',
                ),
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _ModeCard(
                icon: Icons.bolt_rounded,
                title: AppStrings.get('mode.quickPlay'),
                description: AppStrings.get('mode.quickPlay.desc'),
                onTap: () {
                  // 이전 난이도 기반 가중치 랜덤 선택
                  final difficulty = _weightedRandomDifficulty(ref);
                  ref.read(gameProvider.notifier).startNewGame(
                    mode: GameMode.quickPlay,
                    difficulty: difficulty,
                  );
                  context.push(AppRoutes.game);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _ModeCard(
                icon: Icons.local_fire_department_rounded,
                title: AppStrings.get('mode.challenge'),
                description: AppStrings.get('mode.challenge.desc'),
                onTap: () => context.push(
                  AppRoutes.difficultySelect,
                  extra: 'challenge',
                ),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이전 플레이 난이도를 기반으로 가중치 랜덤 난이도 선택
  /// 마지막 난이도에 50% 가중치, 인접 난이도에 나머지 분배
  Difficulty _weightedRandomDifficulty(WidgetRef ref) {
    final mvp = Difficulty.mvpDifficulties;
    String lastDiffName = 'easy';
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      lastDiffName = SettingsService(prefs).lastDifficulty;
    } catch (_) {}

    final lastIdx = mvp.indexWhere((d) => d.name == lastDiffName);
    if (lastIdx < 0) return mvp[Random().nextInt(mvp.length)];

    // 가중치 배열: 마지막 난이도 50%, 인접 25%씩, 나머지 균등 분배
    final weights = List<double>.filled(mvp.length, 1.0);
    weights[lastIdx] = 6.0; // 주요 가중치
    if (lastIdx > 0) weights[lastIdx - 1] = 3.0;
    if (lastIdx < mvp.length - 1) weights[lastIdx + 1] = 3.0;

    final total = weights.reduce((a, b) => a + b);
    var roll = Random().nextDouble() * total;
    for (var i = 0; i < mvp.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return mvp[i];
    }
    return mvp.last;
  }
}

/// 모드 카드
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool isLocked;
  final bool isDark;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.isLocked = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isLocked ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Card(
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (isLocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Coming Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!isLocked)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
