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
import '../nonogram_notifier.dart';
import '../nonogram_state.dart';

/// 노노그램 홈 화면
class NonogramHomeScreen extends ConsumerStatefulWidget {
  const NonogramHomeScreen({super.key});

  @override
  ConsumerState<NonogramHomeScreen> createState() => _NonogramHomeScreenState();
}

class _NonogramHomeScreenState extends ConsumerState<NonogramHomeScreen> {
  @override
  void initState() {
    super.initState();
    // 노노그램 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.nonograms);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(nonogramNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;

    return BackPressExit(
      child: Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('nonogram.title')),
        leading: IconButton(
          icon: const Icon(Icons.apps_rounded),
          onPressed: () => context.go(AppRoutes.hub),
          tooltip: AppStrings.get('nonogram.backToHub'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => showTutorialBottomSheet(context, 'nonogram'),
            tooltip: AppStrings.get('help.rules'),
          ),
        ],
      ),
      body: GameHomeTemplate(
        gameId: 'nonogram',
        emoji: '🎨',
        iconAsset: 'assets/icons/game-nonogram.svg',
        tagline: AppStrings.get('nonogram.subtitle'),
        continueCard: hasOngoingGame ? _ContinueCard(gameState: gameState) : null,
        onNewGame: () {
          if (hasOngoingGame) {
            _showNewGameWarning(context);
          } else {
            _showDifficultyPicker(context);
          }
        },
        newGameLabel: AppStrings.get('nonogram.newGame'),
        onDailyPuzzle: () {
          ref.read(nonogramNotifierProvider.notifier).startDailyPuzzle();
          context.go(AppRoutes.nonogramsGame);
        },
        dailyPuzzleLabel: AppStrings.get('nonogram.dailyPuzzle'),
        onStatistics: () => context.push(AppRoutes.statistics, extra: 'nonogram'),
        statisticsLabel: AppStrings.get('nonogram.statistics'),
        onBadges: () => context.push(AppRoutes.badges, extra: 'nonogram'),
        badgesLabel: AppStrings.get('nonogram.badges'),
        rulesCard: CasualRulesCard(
          aboutTitle: AppStrings.get('nonogram.about.title'),
          aboutDesc: AppStrings.get('nonogram.about.desc'),
          rulesTitle: AppStrings.get('nonogram.rules.title'),
          rules: [
            AppStrings.get('nonogram.rules.r1'),
            AppStrings.get('nonogram.rules.r2'),
            AppStrings.get('nonogram.rules.r3'),
          ],
          themeColor: AppColors.gameThemeColors['nonogram'] ?? const Color(0xFFFF9A5C),
        ),
      ),
    ),
    );
  }

  /// 새 게임 경고 (진행 중 게임 있을 때)
  void _showNewGameWarning(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('nonogram.newGame.warning.title'),
      content: AppStrings.get('nonogram.newGame.warning.message'),
      confirmLabel: AppStrings.get('nonogram.newGame.warning.confirm'),
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
                AppStrings.get('nonogram.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...NonogramDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DifficultyTile(
                      difficulty: diff,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref.read(nonogramNotifierProvider.notifier).startNewGame(
                              mode: NonogramGameMode.classic,
                              difficulty: diff,
                            );
                        context.go(AppRoutes.nonogramsGame);
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
  final NonogramState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // 진행률: 채워진 셀(1) + 크로스(0) / 전체 셀
    final totalCells = gameState.current.rows * gameState.current.cols;
    final decidedCount = totalCells - gameState.current.undecidedCount;
    final progress = totalCells > 0 ? decidedCount / totalCells : 0.0;
    final themeColor = AppColors.gameThemeColors['nonogram'] ?? const Color(0xFFFF9A5C);

    return CasualContinueCard(
      onTap: () {
        ref.read(nonogramNotifierProvider.notifier).resume();
        context.go(AppRoutes.nonogramsGame);
      },
      label: AppStrings.get('nonogram.continue'),
      timeText: timeText,
      chips: [
        gameState.mode.label,
        gameState.difficulty.label,
        '${gameState.current.rows}x${gameState.current.cols}',
      ],
      progress: progress,
      progressLabel: '${(progress * 100).toInt()}%',
      themeColor: themeColor,
    );
  }
}

/// 난이도 타일
class _DifficultyTile extends StatelessWidget {
  final NonogramDifficulty difficulty;
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
      case NonogramDifficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case NonogramDifficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case NonogramDifficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case NonogramDifficulty.hard:
        return DifficultyTokens.hardColor(isDark);
    }
  }
}
