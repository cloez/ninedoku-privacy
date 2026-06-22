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
import '../jigsaw_sudoku_notifier.dart';
import '../jigsaw_sudoku_state.dart';
import '../engine/jigsaw_sudoku_generator.dart';

/// 직소 스도쿠 홈 화면
class JigsawSudokuHomeScreen extends ConsumerStatefulWidget {
  const JigsawSudokuHomeScreen({super.key});

  @override
  ConsumerState<JigsawSudokuHomeScreen> createState() =>
      _JigsawSudokuHomeScreenState();
}

class _JigsawSudokuHomeScreenState
    extends ConsumerState<JigsawSudokuHomeScreen> {
  @override
  void initState() {
    super.initState();
    // 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.jigsawSudoku);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(jigsawSudokuNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;

    return BackPressExit(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('jigsawSudoku.title')),
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => context.go(AppRoutes.hub),
            tooltip: AppStrings.get('jigsawSudoku.backToHub'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showTutorialBottomSheet(context, 'jigsawSudoku'),
              tooltip: AppStrings.get('help.rules'),
            ),
          ],
        ),
        body: GameHomeTemplate(
          gameId: 'jigsawSudoku',
          emoji: '🧩',
          iconAsset: 'assets/icons/game-jigsaw-sudoku.svg',
          tagline: AppStrings.get('jigsawSudoku.subtitle'),
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
          newGameLabel: AppStrings.get('jigsawSudoku.newGame'),
          onDailyPuzzle: () {
            ref
                .read(jigsawSudokuNotifierProvider.notifier)
                .startDailyPuzzle();
            context.go(AppRoutes.jigsawSudokuGame);
          },
          dailyPuzzleLabel: AppStrings.get('jigsawSudoku.dailyPuzzle'),
          onStatistics: () => context.push(
            AppRoutes.statistics,
            extra: 'jigsawSudoku',
          ),
          statisticsLabel: AppStrings.get('jigsawSudoku.statistics'),
          onBadges: () => context.push(
            AppRoutes.badges,
            extra: 'jigsawSudoku',
          ),
          badgesLabel: AppStrings.get('jigsawSudoku.badges'),
          rulesCard: CasualRulesCard(
            aboutTitle: AppStrings.get('jigsawSudoku.about.title'),
            aboutDesc: AppStrings.get('jigsawSudoku.about.desc'),
            rulesTitle: AppStrings.get('jigsawSudoku.rules.title'),
            rules: [
              AppStrings.get('jigsawSudoku.rules.r1'),
              AppStrings.get('jigsawSudoku.rules.r2'),
              AppStrings.get('jigsawSudoku.rules.r3'),
            ],
            themeColor: AppColors.gameThemeColors['jigsawSudoku'] ??
                const Color(0xFF66BB6A),
          ),
        ),
      ),
    );
  }

  /// 새 게임 경고
  void _showNewGameWarning(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('jigsawSudoku.newGame.warning.title'),
      content: AppStrings.get('jigsawSudoku.newGame.warning.message'),
      confirmLabel: AppStrings.get('jigsawSudoku.newGame.warning.confirm'),
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
                AppStrings.get('jigsawSudoku.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...JigsawDifficulty.values.map(
                (diff) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DifficultyTile(
                    difficulty: diff,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref
                          .read(jigsawSudokuNotifierProvider.notifier)
                          .startNewGame(
                            mode: JigsawSudokuGameMode.classic,
                            difficulty: diff,
                          );
                      context.go(AppRoutes.jigsawSudokuGame);
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
  final JigsawSudokuState gameState;
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
    final themeColor =
        AppColors.gameThemeColors['jigsawSudoku'] ?? const Color(0xFF66BB6A);

    return CasualContinueCard(
      onTap: () {
        ref.read(jigsawSudokuNotifierProvider.notifier).resume();
        context.go(AppRoutes.jigsawSudokuGame);
      },
      label: AppStrings.get('jigsawSudoku.continue'),
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
  final JigsawDifficulty difficulty;
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
      case JigsawDifficulty.beginner:
        return AppStrings.get('difficulty.beginner');
      case JigsawDifficulty.easy:
        return AppStrings.get('difficulty.easy');
      case JigsawDifficulty.medium:
        return AppStrings.get('difficulty.medium');
      case JigsawDifficulty.hard:
        return AppStrings.get('difficulty.hard');
      case JigsawDifficulty.master:
        return AppStrings.get('difficulty.master');
    }
  }

  String _difficultyDesc() {
    switch (difficulty) {
      case JigsawDifficulty.beginner:
        return '9x9 많은 힌트';
      case JigsawDifficulty.easy:
        return '9x9 적당한 힌트';
      case JigsawDifficulty.medium:
        return '9x9 보통';
      case JigsawDifficulty.hard:
        return '9x9 적은 힌트';
      case JigsawDifficulty.master:
        return '9x9 최소 힌트';
    }
  }

  Color _difficultyColor() {
    switch (difficulty) {
      case JigsawDifficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case JigsawDifficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case JigsawDifficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case JigsawDifficulty.hard:
        return DifficultyTokens.hardColor(isDark);
      case JigsawDifficulty.master:
        return DifficultyTokens.masterColor(isDark);
    }
  }
}
