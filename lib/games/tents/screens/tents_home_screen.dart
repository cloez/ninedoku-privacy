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
    // 텐트 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.tents);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(tentsNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;

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
        body: GameHomeTemplate(
          gameId: 'tents',
          emoji: '⛺',
          iconAsset: 'assets/icons/game-tent.svg',
          tagline: AppStrings.get('tents.subtitle'),
          continueCard: hasOngoingGame ? _ContinueCard(gameState: gameState) : null,
          onNewGame: () {
            if (hasOngoingGame) {
              _showNewGameWarning(context);
            } else {
              _showDifficultyPicker(context);
            }
          },
          newGameLabel: AppStrings.get('tents.newGame'),
          onDailyPuzzle: () {
            ref.read(tentsNotifierProvider.notifier).startDailyPuzzle();
            context.go(AppRoutes.tentsGame);
          },
          dailyPuzzleLabel: AppStrings.get('tents.dailyPuzzle'),
          onStatistics: () => context.push(AppRoutes.statistics, extra: 'tents'),
          statisticsLabel: AppStrings.get('tents.statistics'),
          onBadges: () => context.push(AppRoutes.badges, extra: 'tents'),
          badgesLabel: AppStrings.get('tents.badges'),
          rulesCard: CasualRulesCard(
            aboutTitle: AppStrings.get('tents.about.title'),
            aboutDesc: AppStrings.get('tents.about.desc'),
            rulesTitle: AppStrings.get('tents.rules.title'),
            rules: [
              AppStrings.get('tents.rules.r1'),
              AppStrings.get('tents.rules.r2'),
              AppStrings.get('tents.rules.r3'),
              AppStrings.get('tents.rules.r4'),
            ],
            footerText: AppStrings.get('tents.rules.howToPlay'),
            themeColor: AppColors.gameThemeColors['tents'] ?? const Color(0xFFFF7A59),
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
        top: false, // 모달이라 상단 padding 불필요
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom, // 키보드/시스템바 대응
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

/// 이어하기 카드 (캐주얼)
class _ContinueCard extends ConsumerWidget {
  final TentsState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final totalToFill = gameState.current.playableCells;
    final filled = gameState.current.filledCellCount;
    final progress = totalToFill > 0 ? filled / totalToFill : 0.0;
    final themeColor = AppColors.gameThemeColors['tents'] ?? const Color(0xFFFF7A59);

    return CasualContinueCard(
      onTap: () {
        ref.read(tentsNotifierProvider.notifier).resume();
        context.go(AppRoutes.tentsGame);
      },
      label: AppStrings.get('tents.continue'),
      timeText: timeText,
      chips: [gameState.mode.label, gameState.difficulty.label, '${gameState.size}x${gameState.size}'],
      progress: progress,
      progressLabel: '${(progress * 100).toInt()}%',
      themeColor: themeColor,
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
