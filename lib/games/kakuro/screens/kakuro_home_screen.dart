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
import '../kakuro_notifier.dart';
import '../kakuro_state.dart';

/// 카쿠로 홈 화면 — 캐주얼 디자인 위젯 적용
class KakuroHomeScreen extends ConsumerStatefulWidget {
  const KakuroHomeScreen({super.key});

  @override
  ConsumerState<KakuroHomeScreen> createState() => _KakuroHomeScreenState();
}

class _KakuroHomeScreenState extends ConsumerState<KakuroHomeScreen> {
  @override
  void initState() {
    super.initState();
    // 카쿠로 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute(AppRoutes.kakuro);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(kakuroNotifierProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;
    final themeColor =
        AppColors.gameThemeColors['kakuro'] ?? const Color(0xFFE57373);

    return BackPressExit(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('kakuro.title')),
          leading: IconButton(
            icon: const Icon(Icons.apps_rounded),
            onPressed: () => context.go(AppRoutes.hub),
            tooltip: AppStrings.get('kakuro.backToHub'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showTutorialBottomSheet(context, 'kakuro'),
              tooltip: AppStrings.get('help.rules'),
            ),
          ],
        ),
        body: GameHomeTemplate(
          gameId: 'kakuro',
          emoji: '➕',
          iconAsset: 'assets/icons/game-kakuro.svg',
          tagline: AppStrings.get('kakuro.subtitle'),
          // 이어하기 카드 — CasualContinueCard 사용
          continueCard: hasOngoingGame
              ? _buildContinueCard(gameState!, themeColor)
              : null,
          // 새 게임 버튼
          onNewGame: () {
            if (hasOngoingGame) {
              _showNewGameWarning(context);
            } else {
              _showDifficultyPicker(context);
            }
          },
          newGameLabel: AppStrings.get('kakuro.newGame'),
          // 오늘의 퍼즐
          onDailyPuzzle: () {
            ref.read(kakuroNotifierProvider.notifier).startDailyPuzzle();
            context.go(AppRoutes.kakuroGame);
          },
          dailyPuzzleLabel: AppStrings.get('kakuro.dailyPuzzle'),
          // 통계
          onStatistics: () =>
              context.push(AppRoutes.statistics, extra: 'kakuro'),
          statisticsLabel: AppStrings.get('kakuro.statistics'),
          // 배지
          onBadges: () => context.push(AppRoutes.badges, extra: 'kakuro'),
          badgesLabel: AppStrings.get('kakuro.badges'),
          // 규칙 카드 — CasualRulesCard 사용
          rulesCard: CasualRulesCard(
            aboutTitle: AppStrings.get('kakuro.about.title'),
            aboutDesc: AppStrings.get('kakuro.about.desc'),
            rulesTitle: AppStrings.get('kakuro.rules.title'),
            rules: [
              AppStrings.get('kakuro.rules.r1'),
              AppStrings.get('kakuro.rules.r2'),
              AppStrings.get('kakuro.rules.r3'),
            ],
            themeColor: themeColor,
          ),
        ),
      ),
    );
  }

  /// 이어하기 카드 빌드 — CasualContinueCard 위젯으로 변환
  Widget _buildContinueCard(KakuroState gameState, Color themeColor) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final totalCells = gameState.current.totalWhiteCells;
    final filledCount = gameState.current.filledCellCount;
    final progress = totalCells > 0 ? filledCount / totalCells : 0.0;

    return CasualContinueCard(
      onTap: () {
        ref.read(kakuroNotifierProvider.notifier).resume();
        context.go(AppRoutes.kakuroGame);
      },
      label: AppStrings.get('kakuro.continue'),
      timeText: timeText,
      chips: [
        gameState.mode.label,
        gameState.difficulty.label,
        '${gameState.size}x${gameState.size}',
      ],
      progress: progress,
      progressLabel: '${(progress * 100).toInt()}%',
      themeColor: themeColor,
    );
  }

  /// 새 게임 경고 다이얼로그
  void _showNewGameWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('kakuro.newGame.warning.title')),
        content: Text(AppStrings.get('kakuro.newGame.warning.message')),
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
            child: Text(AppStrings.get('kakuro.newGame.warning.confirm')),
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
                AppStrings.get('kakuro.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...KakuroDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DifficultyTile(
                      difficulty: diff,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref
                            .read(kakuroNotifierProvider.notifier)
                            .startNewGame(
                              mode: KakuroGameMode.classic,
                              difficulty: diff,
                            );
                        context.go(AppRoutes.kakuroGame);
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

/// 난이도 타일
class _DifficultyTile extends StatelessWidget {
  final KakuroDifficulty difficulty;
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
      case KakuroDifficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case KakuroDifficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case KakuroDifficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case KakuroDifficulty.hard:
        return DifficultyTokens.hardColor(isDark);
    }
  }
}
