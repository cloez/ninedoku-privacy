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
import '../skyscrapers_notifier.dart';
import '../skyscrapers_state.dart';

/// Skyscrapers 홈 화면
class SkyscrapersHomeScreen extends ConsumerStatefulWidget {
  const SkyscrapersHomeScreen({super.key});

  @override
  ConsumerState<SkyscrapersHomeScreen> createState() =>
      _SkyscrapersHomeScreenState();
}

class _SkyscrapersHomeScreenState extends ConsumerState<SkyscrapersHomeScreen> {
  @override
  void initState() {
    super.initState();
    // 빌딩 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.skyscrapers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(skyscrapersNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackPressExit(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('skyscrapers.title')),
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => context.go(AppRoutes.hub),
            tooltip: AppStrings.get('skyscrapers.backToHub'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showTutorialBottomSheet(context, 'skyscrapers'),
              tooltip: AppStrings.get('help.rules'),
            ),
          ],
        ),
        body: GameHomeTemplate(
          gameId: 'skyscrapers',
          emoji: '🏙️',
          iconAsset: 'assets/icons/game-building.svg',
          tagline: AppStrings.get('skyscrapers.subtitle'),
          continueCard: hasOngoingGame ? _ContinueCard(gameState: gameState) : null,
          onNewGame: () {
            if (hasOngoingGame) {
              _showNewGameWarning(context);
            } else {
              _showDifficultyPicker(context);
            }
          },
          newGameLabel: AppStrings.get('skyscrapers.newGame'),
          onDailyPuzzle: () {
            ref.read(skyscrapersNotifierProvider.notifier).startDailyPuzzle();
            context.go(AppRoutes.skyscrapersGame);
          },
          dailyPuzzleLabel: AppStrings.get('skyscrapers.dailyPuzzle'),
          onStatistics: () => context.push(AppRoutes.statistics, extra: 'skyscrapers'),
          statisticsLabel: AppStrings.get('skyscrapers.statistics'),
          onBadges: () => context.push(AppRoutes.badges, extra: 'skyscrapers'),
          badgesLabel: AppStrings.get('skyscrapers.badges'),
          rulesCard: CasualRulesCard(
            aboutTitle: AppStrings.get('skyscrapers.about.title'),
            aboutDesc: AppStrings.get('skyscrapers.about.desc'),
            rulesTitle: AppStrings.get('skyscrapers.rules.title'),
            rules: [
              AppStrings.get('skyscrapers.rules.r1'),
              AppStrings.get('skyscrapers.rules.r2'),
              AppStrings.get('skyscrapers.rules.r3'),
            ],
            themeColor: AppColors.gameThemeColors['skyscrapers'] ?? const Color(0xFF3F51B5),
          ),
        ),
      ),
    );
  }

  /// 새 게임 경고
  void _showNewGameWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('skyscrapers.newGame.warning.title')),
        content: Text(AppStrings.get('skyscrapers.newGame.warning.message')),
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
            child: Text(AppStrings.get('skyscrapers.newGame.warning.confirm')),
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
                AppStrings.get('skyscrapers.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...SkyscrapersDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DifficultyTile(
                      difficulty: diff,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref
                            .read(skyscrapersNotifierProvider.notifier)
                            .startNewGame(
                              mode: SkyscrapersGameMode.classic,
                              difficulty: diff,
                            );
                        context.go(AppRoutes.skyscrapersGame);
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
  final SkyscrapersState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final totalCells = gameState.size * gameState.size;
    final fixedCount = gameState.current.fixed.length;
    final filledCount = gameState.current.filledCellCount;
    final userFilled = filledCount - fixedCount;
    final totalToFill = totalCells - fixedCount;
    final progress = totalToFill > 0 ? userFilled / totalToFill : 0.0;
    final themeColor = AppColors.gameThemeColors['skyscrapers'] ?? const Color(0xFF3F51B5);

    return CasualContinueCard(
      onTap: () {
        ref.read(skyscrapersNotifierProvider.notifier).resume();
        context.go(AppRoutes.skyscrapersGame);
      },
      label: AppStrings.get('skyscrapers.continue'),
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
  final SkyscrapersDifficulty difficulty;
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
      case SkyscrapersDifficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case SkyscrapersDifficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case SkyscrapersDifficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case SkyscrapersDifficulty.hard:
        return DifficultyTokens.hardColor(isDark);
      case SkyscrapersDifficulty.master:
        return DifficultyTokens.masterColor(isDark);
    }
  }
}
