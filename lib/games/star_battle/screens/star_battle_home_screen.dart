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
import '../star_battle_notifier.dart';
import '../star_battle_state.dart';

/// Star Battle 홈 화면
class StarBattleHomeScreen extends ConsumerStatefulWidget {
  const StarBattleHomeScreen({super.key});

  @override
  ConsumerState<StarBattleHomeScreen> createState() => _StarBattleHomeScreenState();
}

class _StarBattleHomeScreenState extends ConsumerState<StarBattleHomeScreen> {
  @override
  void initState() {
    super.initState();
    // 스타 배틀 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.starBattle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(starBattleNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;

    return BackPressExit(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('starBattle.title')),
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => context.go(AppRoutes.hub),
            tooltip: AppStrings.get('starBattle.backToHub'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showTutorialBottomSheet(context, 'starBattle'),
              tooltip: AppStrings.get('help.rules'),
            ),
          ],
        ),
        body: GameHomeTemplate(
          gameId: 'starBattle',
          emoji: '⭐',
          iconAsset: 'assets/icons/game-star-battle.svg',
          tagline: AppStrings.get('starBattle.subtitle'),
          continueCard: hasOngoingGame ? _ContinueCard(gameState: gameState) : null,
          onNewGame: () {
            if (hasOngoingGame) {
              _showNewGameWarning(context);
            } else {
              _showDifficultyPicker(context);
            }
          },
          newGameLabel: AppStrings.get('starBattle.newGame'),
          onDailyPuzzle: () {
            ref.read(starBattleNotifierProvider.notifier).startDailyPuzzle();
            context.go(AppRoutes.starBattleGame);
          },
          dailyPuzzleLabel: AppStrings.get('starBattle.dailyPuzzle'),
          onStatistics: () => context.push(AppRoutes.statistics, extra: 'starBattle'),
          statisticsLabel: AppStrings.get('starBattle.statistics'),
          onBadges: () => context.push(AppRoutes.badges, extra: 'starBattle'),
          badgesLabel: AppStrings.get('starBattle.badges'),
          rulesCard: CasualRulesCard(
            aboutTitle: AppStrings.get('starBattle.about.title'),
            aboutDesc: AppStrings.get('starBattle.about.desc'),
            rulesTitle: AppStrings.get('starBattle.rules.title'),
            rules: [
              AppStrings.get('starBattle.rules.r1'),
              AppStrings.get('starBattle.rules.r2'),
              AppStrings.get('starBattle.rules.r3'),
            ],
            themeColor: AppColors.gameThemeColors['starBattle'] ?? const Color(0xFFFFC542),
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
        title: Text(AppStrings.get('starBattle.newGame.warning.title')),
        content: Text(AppStrings.get('starBattle.newGame.warning.message')),
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
            child: Text(AppStrings.get('starBattle.newGame.warning.confirm')),
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
                AppStrings.get('starBattle.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...StarBattleDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DifficultyTile(
                      difficulty: diff,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref.read(starBattleNotifierProvider.notifier).startNewGame(
                              mode: StarBattleGameMode.classic,
                              difficulty: diff,
                            );
                        context.go(AppRoutes.starBattleGame);
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
  final StarBattleState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // 진행률 (별 배치 기준)
    final totalStars = gameState.size * gameState.starCount;
    final placedStars = gameState.current.starCellCount;
    final progress = totalStars > 0 ? placedStars / totalStars : 0.0;
    final themeColor = AppColors.gameThemeColors['starBattle'] ?? const Color(0xFFFFC542);

    return CasualContinueCard(
      onTap: () {
        ref.read(starBattleNotifierProvider.notifier).resume();
        context.go(AppRoutes.starBattleGame);
      },
      label: AppStrings.get('starBattle.continue'),
      timeText: timeText,
      chips: [
        gameState.mode.label,
        gameState.difficulty.label,
        '${gameState.size}x${gameState.size} ${gameState.starCount}-star',
      ],
      progress: progress,
      progressLabel: '${(progress * 100).toInt()}%',
      themeColor: themeColor,
    );
  }
}

/// 난이도 타일
class _DifficultyTile extends StatelessWidget {
  final StarBattleDifficulty difficulty;
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
        subtitle: Text('${difficulty.gridSize}x${difficulty.gridSize}, ${difficulty.starCount}-star'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Color _difficultyColor() {
    switch (difficulty) {
      case StarBattleDifficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case StarBattleDifficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case StarBattleDifficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case StarBattleDifficulty.hard:
        return DifficultyTokens.hardColor(isDark);
      case StarBattleDifficulty.master:
        return DifficultyTokens.masterColor(isDark);
    }
  }
}
