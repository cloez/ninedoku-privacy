import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/widgets/back_press_exit.dart';
import '../../../features/tutorial/screens/tutorial_screen_v2.dart';
import '../tents_notifier.dart';
import '../tents_state.dart';

/// Tents 홈 화면
class TentsHomeScreen extends ConsumerStatefulWidget {
  const TentsHomeScreen({super.key});

  @override
  ConsumerState<TentsHomeScreen> createState() => _TentsHomeScreenState();
}

class _TentsHomeScreenState extends ConsumerState<TentsHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.tents);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(tentsNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackPressExit(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('tents.title')),
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => context.go(AppRoutes.hub),
            tooltip: AppStrings.get('tents.backToHub'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showTutorialBottomSheet(context, 'tents'),
              tooltip: AppStrings.get('help.rules'),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.park_rounded,
                  size: 56,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('tents.subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 이어하기 카드
                if (hasOngoingGame) ...[
                  _ContinueCard(gameState: gameState),
                  const SizedBox(height: 20),
                ],

                // 새 게임 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (hasOngoingGame) {
                        _showNewGameWarning(context);
                      } else {
                        _showDifficultyPicker(context);
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(AppStrings.get('tents.newGame')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 오늘의 퍼즐
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(tentsNotifierProvider.notifier).startDailyPuzzle();
                      context.go(AppRoutes.tentsGame);
                    },
                    icon: const Icon(Icons.today_rounded),
                    label: Text(AppStrings.get('tents.dailyPuzzle')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 통계/배지 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push(AppRoutes.statistics, extra: 'tents'),
                        icon: const Icon(Icons.bar_chart_rounded, size: 20),
                        label: Text(AppStrings.get('tents.statistics')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push(AppRoutes.badges, extra: 'tents'),
                        icon: const Icon(Icons.emoji_events_rounded, size: 20),
                        label: Text(AppStrings.get('tents.badges')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 게임 설명/규칙은 진행 중 게임 여부와 무관하게 항상 표시
                _RulesHint(isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewGameWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('tents.newGame.warning.title')),
        content: Text(AppStrings.get('tents.newGame.warning.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showDifficultyPicker(context);
            },
            child: Text(AppStrings.get('tents.newGame.warning.confirm')),
          ),
        ],
      ),
    );
  }

  void _showDifficultyPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 컨텐츠 전체 크기 사용 (하단 잘림 방지)
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 시각적 핸들 (BottomSheet 힌트)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                AppStrings.get('tents.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...TentsDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DifficultyTile(
                      difficulty: diff,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref.read(tentsNotifierProvider.notifier).startNewGame(
                              mode: TentsGameMode.classic,
                              difficulty: diff,
                            );
                        context.go(AppRoutes.tentsGame);
                      },
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// 이어하기 카드
class _ContinueCard extends ConsumerWidget {
  final TentsState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final totalToFill = gameState.current.playableCells;
    final filled = gameState.current.filledCellCount;
    final progress = totalToFill > 0 ? filled / totalToFill : 0.0;

    return Card(
      child: InkWell(
        onTap: () {
          ref.read(tentsNotifierProvider.notifier).resume();
          context.go(AppRoutes.tentsGame);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_filled_rounded,
                    color:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.get('tents.continue'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ChipLabel(text: gameState.mode.label, isDark: isDark),
                  const SizedBox(width: 8),
                  _ChipLabel(text: gameState.difficulty.label, isDark: isDark),
                  const SizedBox(width: 8),
                  _ChipLabel(
                    text: '${gameState.size}x${gameState.size}',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 난이도 타일
class _DifficultyTile extends StatelessWidget {
  final TentsDifficulty difficulty;
  final bool isDark;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.difficulty,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: _difficultyColor(),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          difficulty.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${difficulty.gridSize}x${difficulty.gridSize}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Color _difficultyColor() {
    switch (difficulty) {
      case TentsDifficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case TentsDifficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case TentsDifficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case TentsDifficulty.hard:
        return DifficultyTokens.hardColor(isDark);
      case TentsDifficulty.master:
        return DifficultyTokens.masterColor(isDark);
    }
  }
}

/// 작은 라벨 칩
class _ChipLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _ChipLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white10
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }
}

/// 게임 소개 + 규칙 카드
class _RulesHint extends StatelessWidget {
  final bool isDark;
  const _RulesHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white70 : Colors.black87;
    final bodyColor = isDark ? Colors.white54 : Colors.black54;
    final ruleColor = isDark ? Colors.white54 : Colors.black54;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('tents.about.title'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('tents.about.desc'),
              style:
                  TextStyle(fontSize: 13, color: bodyColor, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('tents.rules.title'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            _ruleRow('1', AppStrings.get('tents.rules.r1'), ruleColor),
            const SizedBox(height: 6),
            _ruleRow('2', AppStrings.get('tents.rules.r2'), ruleColor),
            const SizedBox(height: 6),
            _ruleRow('3', AppStrings.get('tents.rules.r3'), ruleColor),
            const SizedBox(height: 6),
            _ruleRow('4', AppStrings.get('tents.rules.r4'), ruleColor),
            const SizedBox(height: 12),
            Text(
              AppStrings.get('tents.rules.howToPlay'),
              style:
                  TextStyle(fontSize: 12, color: bodyColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleRow(String num, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(num,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: color, height: 1.4)),
        ),
      ],
    );
  }
}
