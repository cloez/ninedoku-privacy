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
import '../killer_sudoku_notifier.dart';
import '../killer_sudoku_state.dart';
import '../engine/killer_sudoku_generator.dart';

/// 킬러 스도쿠 홈 화면
class KillerSudokuHomeScreen extends ConsumerStatefulWidget {
  const KillerSudokuHomeScreen({super.key});

  @override
  ConsumerState<KillerSudokuHomeScreen> createState() =>
      _KillerSudokuHomeScreenState();
}

class _KillerSudokuHomeScreenState
    extends ConsumerState<KillerSudokuHomeScreen> {
  @override
  void initState() {
    super.initState();
    // 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.killerSudoku);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(killerSudokuNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;

    return BackPressExit(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('killerSudoku.title')),
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => context.go(AppRoutes.hub),
            tooltip: AppStrings.get('killerSudoku.backToHub'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showTutorialBottomSheet(context, 'killerSudoku'),
              tooltip: AppStrings.get('help.rules'),
            ),
          ],
        ),
        body: GameHomeTemplate(
          gameId: 'killerSudoku',
          emoji: '🗡️',
          iconAsset: 'assets/icons/game-killer-sudoku.svg',
          tagline: AppStrings.get('killerSudoku.subtitle'),
          continueCard: hasOngoingGame
              ? _ContinueCard(gameState: gameState)
              : null,
          onNewGame: () {
            if (hasOngoingGame) {
              _showNewGameWarning(context);
            } else {
              _showDifficultyPicker(context);
            }
          },
          newGameLabel: AppStrings.get('killerSudoku.newGame'),
          onDailyPuzzle: () {
            ref
                .read(killerSudokuNotifierProvider.notifier)
                .startDailyPuzzle();
            context.go(AppRoutes.killerSudokuGame);
          },
          dailyPuzzleLabel: AppStrings.get('killerSudoku.dailyPuzzle'),
          onStatistics: () =>
              context.push(AppRoutes.statistics, extra: 'killerSudoku'),
          statisticsLabel: AppStrings.get('killerSudoku.statistics'),
          onBadges: () =>
              context.push(AppRoutes.badges, extra: 'killerSudoku'),
          badgesLabel: AppStrings.get('killerSudoku.badges'),
          rulesCard: CasualRulesCard(
            aboutTitle: AppStrings.get('killerSudoku.about.title'),
            aboutDesc: AppStrings.get('killerSudoku.about.desc'),
            rulesTitle: AppStrings.get('killerSudoku.rules.title'),
            rules: [
              AppStrings.get('killerSudoku.rules.r1'),
              AppStrings.get('killerSudoku.rules.r2'),
              AppStrings.get('killerSudoku.rules.r3'),
            ],
            themeColor: AppColors.gameThemeColors['killerSudoku'] ??
                const Color(0xFF5EB9FF),
          ),
        ),
      ),
    );
  }

  /// 새 게임 경고
  void _showNewGameWarning(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('killerSudoku.newGame.warning.title'),
      content: AppStrings.get('killerSudoku.newGame.warning.message'),
      confirmLabel: AppStrings.get('killerSudoku.newGame.warning.confirm'),
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
                AppStrings.get('killerSudoku.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...KillerDifficulty.values.map(
                (diff) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DifficultyTile(
                    difficulty: diff,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref
                          .read(killerSudokuNotifierProvider.notifier)
                          .startNewGame(
                            mode: KillerSudokuGameMode.classic,
                            difficulty: diff,
                          );
                      context.go(AppRoutes.killerSudokuGame);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 이어하기 카드 (캐주얼)
class _ContinueCard extends ConsumerWidget {
  final KillerSudokuState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // 진행률 계산
    final totalToFill = 81 - gameState.board.fixedCount;
    final userFilled = gameState.board.userFilledCount;
    final progress = totalToFill > 0 ? userFilled / totalToFill : 0.0;
    final themeColor = AppColors.gameThemeColors['killerSudoku'] ??
        const Color(0xFF5EB9FF);

    return CasualContinueCard(
      onTap: () {
        ref.read(killerSudokuNotifierProvider.notifier).resume();
        context.go(AppRoutes.killerSudokuGame);
      },
      label: AppStrings.get('killerSudoku.continue'),
      timeText: timeText,
      chips: [gameState.mode.label, gameState.difficultyLabel, '9x9'],
      progress: progress,
      progressLabel: '${(progress * 100).toInt()}%',
      themeColor: themeColor,
    );
  }
}

/// 난이도 타일
class _DifficultyTile extends StatelessWidget {
  final KillerDifficulty difficulty;
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
          _difficultyLabel(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_difficultyDesc()),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  String _difficultyLabel() {
    switch (difficulty) {
      case KillerDifficulty.beginner:
        return AppStrings.get('difficulty.beginner');
      case KillerDifficulty.easy:
        return AppStrings.get('difficulty.easy');
      case KillerDifficulty.medium:
        return AppStrings.get('difficulty.medium');
      case KillerDifficulty.hard:
        return AppStrings.get('difficulty.hard');
      case KillerDifficulty.master:
        return AppStrings.get('difficulty.master');
    }
  }

  String _difficultyDesc() {
    switch (difficulty) {
      case KillerDifficulty.beginner:
        return '9x9 + 힌트 셀';
      case KillerDifficulty.easy:
        return '9x9 + 소수 힌트';
      case KillerDifficulty.medium:
        return '9x9 케이지만';
      case KillerDifficulty.hard:
        return '9x9 큰 케이지';
      case KillerDifficulty.master:
        return '9x9 복합 케이지';
    }
  }

  Color _difficultyColor() {
    switch (difficulty) {
      case KillerDifficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case KillerDifficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case KillerDifficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case KillerDifficulty.hard:
        return DifficultyTokens.hardColor(isDark);
      case KillerDifficulty.master:
        return DifficultyTokens.masterColor(isDark);
    }
  }
}
