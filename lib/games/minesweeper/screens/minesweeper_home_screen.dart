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
import '../minesweeper_notifier.dart';
import '../minesweeper_state.dart';

/// 지뢰찾기 홈 화면
class MinesweeperHomeScreen extends ConsumerStatefulWidget {
  const MinesweeperHomeScreen({super.key});

  @override
  ConsumerState<MinesweeperHomeScreen> createState() => _MinesweeperHomeScreenState();
}

class _MinesweeperHomeScreenState extends ConsumerState<MinesweeperHomeScreen> {
  @override
  void initState() {
    super.initState();
    // 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.minesweeper);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(minesweeperNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;

    return BackPressExit(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('minesweeper.title')),
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => context.go(AppRoutes.hub),
            tooltip: AppStrings.get('minesweeper.backToHub'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showTutorialBottomSheet(context, 'minesweeper'),
              tooltip: AppStrings.get('help.rules'),
            ),
          ],
        ),
        body: GameHomeTemplate(
          gameId: 'minesweeper',
          emoji: '💣',
          iconAsset: 'assets/icons/game-minesweeper.svg',
          tagline: AppStrings.get('minesweeper.subtitle'),
          continueCard: hasOngoingGame ? _ContinueCard(gameState: gameState) : null,
          onNewGame: () {
            if (hasOngoingGame) {
              _showNewGameWarning(context);
            } else {
              _showDifficultyPicker(context);
            }
          },
          newGameLabel: AppStrings.get('minesweeper.newGame'),
          onDailyPuzzle: () {
            ref.read(minesweeperNotifierProvider.notifier).startDailyPuzzle();
            context.go(AppRoutes.minesweeperGame);
          },
          dailyPuzzleLabel: AppStrings.get('minesweeper.dailyPuzzle'),
          onStatistics: () => context.push(AppRoutes.statistics, extra: 'minesweeper'),
          statisticsLabel: AppStrings.get('minesweeper.statistics'),
          onBadges: () => context.push(AppRoutes.badges, extra: 'minesweeper'),
          badgesLabel: AppStrings.get('minesweeper.badges'),
          rulesCard: CasualRulesCard(
            aboutTitle: AppStrings.get('minesweeper.about.title'),
            aboutDesc: AppStrings.get('minesweeper.about.desc'),
            rulesTitle: AppStrings.get('minesweeper.rules.title'),
            rules: [
              AppStrings.get('minesweeper.rules.r1'),
              AppStrings.get('minesweeper.rules.r2'),
              AppStrings.get('minesweeper.rules.r3'),
            ],
            themeColor: AppColors.gameThemeColors['minesweeper'] ?? AppColors.brandViolet,
          ),
        ),
      ),
    );
  }

  /// 새 게임 경고 (진행 중 게임 있을 때)
  void _showNewGameWarning(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('minesweeper.newGame.warning.title'),
      content: AppStrings.get('minesweeper.newGame.warning.message'),
      confirmLabel: AppStrings.get('minesweeper.newGame.warning.confirm'),
      cancelLabel: AppStrings.get('cancel'),
      isDanger: true,
      onConfirm: () => _showDifficultyPicker(context),
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
                AppStrings.get('minesweeper.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...MinesweeperDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DifficultyTile(
                      difficulty: diff,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref.read(minesweeperNotifierProvider.notifier).startNewGame(
                              mode: MinesweeperGameMode.classic,
                              difficulty: diff,
                            );
                        context.go(AppRoutes.minesweeperGame);
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
  final MinesweeperState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // 진행률 계산: 안전 칸 중 열린 칸 비율
    final progress = gameState.current.safeCount > 0
        ? gameState.current.revealedCount / gameState.current.safeCount
        : 0.0;
    final themeColor = AppColors.gameThemeColors['minesweeper'] ?? AppColors.brandViolet;

    return CasualContinueCard(
      onTap: () {
        ref.read(minesweeperNotifierProvider.notifier).resume();
        context.go(AppRoutes.minesweeperGame);
      },
      label: AppStrings.get('minesweeper.continue'),
      timeText: timeText,
      chips: [
        gameState.difficulty.label,
        '${gameState.size}×${gameState.size}',
        '💣 ${gameState.remainingMines}',
      ],
      progress: progress,
      progressLabel: '${(progress * 100).toInt()}%',
      themeColor: themeColor,
    );
  }
}

/// 난이도 타일
class _DifficultyTile extends StatelessWidget {
  final MinesweeperDifficulty difficulty;
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
          width: 4, height: 36,
          decoration: BoxDecoration(
            color: _difficultyColor(),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(difficulty.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${difficulty.gridSize}×${difficulty.gridSize}  💣${difficulty.mineCount}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  Color _difficultyColor() {
    switch (difficulty) {
      case MinesweeperDifficulty.beginner: return DifficultyTokens.beginnerColor(isDark);
      case MinesweeperDifficulty.easy: return DifficultyTokens.easyColor(isDark);
      case MinesweeperDifficulty.medium: return DifficultyTokens.mediumColor(isDark);
      case MinesweeperDifficulty.hard: return DifficultyTokens.hardColor(isDark);
      case MinesweeperDifficulty.master: return DifficultyTokens.masterColor(isDark);
    }
  }
}
