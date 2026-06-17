import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/widgets/back_press_exit.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../../../shared/widgets/game_home_template.dart';
import '../../../features/tutorial/screens/tutorial_screen_v2.dart';
import '../light_up_notifier.dart';
import '../light_up_state.dart';

/// Light Up 홈 화면
class LightUpHomeScreen extends ConsumerStatefulWidget {
  const LightUpHomeScreen({super.key});

  @override
  ConsumerState<LightUpHomeScreen> createState() => _LightUpHomeScreenState();
}

class _LightUpHomeScreenState extends ConsumerState<LightUpHomeScreen> {
  @override
  void initState() {
    super.initState();
    // 라이트업 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.lightUp);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(lightUpNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;

    return BackPressExit(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('lightUp.title')),
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => context.go(AppRoutes.hub),
            tooltip: AppStrings.get('lightUp.backToHub'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showTutorialBottomSheet(context, 'lightUp'),
              tooltip: AppStrings.get('help.rules'),
            ),
          ],
        ),
        body: GameHomeTemplate(
          gameId: 'lightUp',
          emoji: '\u{1F4A1}',
          iconAsset: 'assets/icons/game-lightup.svg',
          tagline: AppStrings.get('lightUp.subtitle'),
          continueCard: hasOngoingGame ? _ContinueCard(gameState: gameState) : null,
          onNewGame: () {
            if (hasOngoingGame) {
              _showNewGameWarning(context);
            } else {
              _showDifficultyPicker(context);
            }
          },
          newGameLabel: AppStrings.get('lightUp.newGame'),
          onDailyPuzzle: () {
            ref.read(lightUpNotifierProvider.notifier).startDailyPuzzle();
            context.go(AppRoutes.lightUpGame);
          },
          dailyPuzzleLabel: AppStrings.get('lightUp.dailyPuzzle'),
          onStatistics: () => context.push(AppRoutes.statistics, extra: 'lightUp'),
          statisticsLabel: AppStrings.get('lightUp.statistics'),
          onBadges: () => context.push(AppRoutes.badges, extra: 'lightUp'),
          badgesLabel: AppStrings.get('lightUp.badges'),
          rulesCard: CasualRulesCard(
            aboutTitle: AppStrings.get('lightUp.about.title'),
            aboutDesc: AppStrings.get('lightUp.about.desc'),
            rulesTitle: AppStrings.get('lightUp.rules.title'),
            rules: [
              AppStrings.get('lightUp.rules.r1'),
              AppStrings.get('lightUp.rules.r2'),
              AppStrings.get('lightUp.rules.r3'),
              AppStrings.get('lightUp.rules.r4'),
            ],
            themeColor: AppColors.gameThemeColors['lightUp'] ?? const Color(0xFF5ECFCF),
          ),
        ),
      ),
    );
  }

  /// 새 게임 경고 (진행 중 게임 있을 때)
  void _showNewGameWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('lightUp.newGame.warning.title')),
        content: Text(AppStrings.get('lightUp.newGame.warning.message')),
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
            child: Text(AppStrings.get('lightUp.newGame.warning.confirm')),
          ),
        ],
      ),
    );
  }

  /// 난이도 선택 모달
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
                AppStrings.get('lightUp.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...LightUpDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DifficultyTile(
                      difficulty: diff,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref.read(lightUpNotifierProvider.notifier).startNewGame(
                              mode: LightUpGameMode.classic,
                              difficulty: diff,
                            );
                        context.go(AppRoutes.lightUpGame);
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

/// 이어하기 카드 (캐주얼)
class _ContinueCard extends ConsumerWidget {
  final LightUpState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // 진행률 (전구 배치 기준)
    final solutionBulbs = gameState.solution.bulbCount;
    final currentBulbs = gameState.current.bulbCount;
    final progress = solutionBulbs > 0 ? currentBulbs / solutionBulbs : 0.0;
    final themeColor = AppColors.gameThemeColors['lightUp'] ?? const Color(0xFF5ECFCF);

    return CasualContinueCard(
      onTap: () {
        ref.read(lightUpNotifierProvider.notifier).resume();
        context.go(AppRoutes.lightUpGame);
      },
      label: AppStrings.get('lightUp.continue'),
      timeText: timeText,
      chips: [gameState.mode.label, gameState.difficulty.label, '${gameState.size}x${gameState.size}'],
      progress: progress.clamp(0.0, 1.0),
      progressLabel: '${(progress * 100).toInt().clamp(0, 100)}%',
      themeColor: themeColor,
    );
  }
}

/// 난이도 타일
class _DifficultyTile extends StatelessWidget {
  final LightUpDifficulty difficulty;
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
      case LightUpDifficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case LightUpDifficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case LightUpDifficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case LightUpDifficulty.hard:
        return DifficultyTokens.hardColor(isDark);
      case LightUpDifficulty.master:
        return DifficultyTokens.masterColor(isDark);
    }
  }
}
