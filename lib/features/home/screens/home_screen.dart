import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/back_press_exit.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../game/game_notifier.dart';
import '../../game/game_state.dart';
import '../../../core/sudoku/board.dart';
import '../../../core/sudoku/difficulty.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../tutorial/screens/tutorial_screen_v2.dart';
import '../../../shared/widgets/game_home_template.dart';
import '../../../shared/widgets/kp_widgets.dart';

/// 홈 화면 (S-02) — 스도쿠 전용 홈
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 스도쿠 진입 시 마지막 게임 경로 저장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(sharedPreferencesProvider);
      SettingsService(prefs).setLastGameRoute('/');
    });
  }

  /// 이전 플레이 난이도 기반 가중치 랜덤 난이도 선택 (빠른 게임용)
  /// 마지막 난이도 50%, 인접 25%씩, 나머지 균등 분배
  Difficulty _weightedRandomDifficulty() {
    final mvp = Difficulty.mvpDifficulties;
    String lastDiffName = 'easy';
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      lastDiffName = SettingsService(prefs).lastDifficulty;
    } catch (_) {}

    final lastIdx = mvp.indexWhere((d) => d.name == lastDiffName);
    if (lastIdx < 0) return mvp[Random().nextInt(mvp.length)];

    final weights = List<double>.filled(mvp.length, 1.0);
    weights[lastIdx] = 6.0;
    if (lastIdx > 0) weights[lastIdx - 1] = 3.0;
    if (lastIdx < mvp.length - 1) weights[lastIdx + 1] = 3.0;

    final total = weights.reduce((a, b) => a + b);
    var roll = Random().nextDouble() * total;
    for (var i = 0; i < mvp.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return mvp[i];
    }
    return mvp.last;
  }

  /// 모드 선택 BottomSheet (스도쿠)
  void _showModeBottomSheet(BuildContext context) {
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
                AppStrings.get('mode.title'),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _ModeTile(
                icon: Icons.workspace_premium_rounded,
                title: AppStrings.get('mode.classic'),
                description: AppStrings.get('mode.classic.desc'),
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDifficultyBottomSheet(context, GameMode.classic);
                },
              ),
              const SizedBox(height: 8),
              _ModeTile(
                icon: Icons.spa_rounded,
                title: AppStrings.get('mode.relax'),
                description: AppStrings.get('mode.relax.desc'),
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDifficultyBottomSheet(context, GameMode.relax);
                },
              ),
              const SizedBox(height: 8),
              _ModeTile(
                icon: Icons.bolt_rounded,
                title: AppStrings.get('mode.quickPlay'),
                description: AppStrings.get('mode.quickPlay.desc'),
                isDark: isDark,
                onTap: () {
                  // 가중치 랜덤 난이도로 즉시 게임 시작
                  Navigator.of(ctx).pop();
                  final difficulty = _weightedRandomDifficulty();
                  ref.read(gameProvider.notifier).startNewGame(
                        mode: GameMode.quickPlay,
                        difficulty: difficulty,
                      );
                  context.go(AppRoutes.game);
                },
              ),
              const SizedBox(height: 8),
              _ModeTile(
                icon: Icons.local_fire_department_rounded,
                title: AppStrings.get('mode.challenge'),
                description: AppStrings.get('mode.challenge.desc'),
                isDark: isDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDifficultyBottomSheet(context, GameMode.challenge);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 난이도 선택 BottomSheet (스도쿠)
  void _showDifficultyBottomSheet(BuildContext context, GameMode gameMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 모드별 허용 난이도 필터링
    final List<Difficulty> availableDifficulties;
    if (gameMode == GameMode.relax) {
      // 릴렉스: 입문~어려움
      availableDifficulties = Difficulty.values
          .where((d) => d.code <= Difficulty.hard.code)
          .toList();
    } else if (gameMode == GameMode.challenge) {
      // 도전: 보통~마스터
      availableDifficulties = Difficulty.values
          .where((d) => d.code >= Difficulty.medium.code)
          .toList();
    } else {
      availableDifficulties = Difficulty.values;
    }

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
                '${AppStrings.get('difficulty.title')} - ${AppStrings.get('mode.${gameMode.name}')}',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...availableDifficulties.map(
                (diff) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SudokuDifficultyTile(
                    difficulty: diff,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ref.read(gameProvider.notifier).startNewGame(
                            mode: gameMode,
                            difficulty: diff,
                          );
                      context.go(AppRoutes.game);
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

  /// 진행 중 게임이 있을 때 새 게임 시작 경고
  void _showNewGameWarning(BuildContext context) {
    final s = AppStrings.get;
    showKPDialog(
      context: context,
      title: s('home.newGame.warning.title'),
      content: s('home.newGame.warning.message'),
      confirmLabel: s('home.newGame.warning.confirm'),
      cancelLabel: s('cancel'),
      isDanger: true,
      onConfirm: () => _showModeBottomSheet(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;
    final s = AppStrings.get;

    final themeColor = AppColors.gameThemeColors['sudoku'] ?? AppColors.brandBlue;
    final secondary = AppColors.gameSecondaryColors['sudoku'] ?? themeColor;

    return BackPressExit(
      child: Scaffold(
      appBar: AppBar(
        title: Text(s('game.sudoku.name')),
        leading: IconButton(
          icon: const Icon(Icons.apps_rounded),
          onPressed: () => context.go(AppRoutes.hub),
          tooltip: AppStrings.get('hub.title'),
        ),
        actions: [
          IconButton(
            onPressed: () => showTutorialBottomSheet(context, 'sudoku'),
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: s('home.tutorial'),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_rounded),
            tooltip: s('home.settings'),
          ),
        ],
      ),
      body: KPBackground(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // KP 히어로 카드 — 공유 디자인
                  KPHeroCard(
                    gameId: 'sudoku',
                    tagline: s('home.subtitle'),
                    primary: themeColor,
                    secondary: secondary,
                  ),
                  const SizedBox(height: 24),

                  if (hasOngoingGame) ...[
                    _ContinueCard(gameState: gameState, themeColor: themeColor),
                    const SizedBox(height: 16),
                  ],

                  // 새 게임 (KP 그라데이션 CTA)
                  KPGradientButton(
                    onTap: () {
                      if (hasOngoingGame) {
                        _showNewGameWarning(context);
                      } else {
                        _showModeBottomSheet(context);
                      }
                    },
                    iconAsset: 'assets/icons/new-game.svg',
                    label: s('home.newGame'),
                    colors: [themeColor, secondary],
                    colorfulIcon: true,
                  ),
                  const SizedBox(height: 12),

                  // 오늘의 퍼즐 — 밝은 배경
                  KPGradientButton(
                    onTap: () => context.push(AppRoutes.dailyPuzzle),
                    iconAsset: 'assets/icons/daily-puzzle.svg',
                    label: s('home.todayPuzzle'),
                    colors: [
                      AppColors.kpPaleViolet,
                      const Color(0xFFF8F5FF),
                    ],
                    foreground: AppColors.kpText,
                    colorfulIcon: true,
                  ),
                  const SizedBox(height: 20),

                  // 통계 + 배지 (KP 미니 버튼)
                  Row(
                    children: [
                      Expanded(
                        child: KPMiniButton(
                          iconAsset: 'assets/icons/chart.svg',
                          label: s('home.statistics'),
                          background: const Color(0xFFE0F5EC),
                          onTap: () => context.push(AppRoutes.statistics, extra: 'sudoku'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KPMiniButton(
                          iconAsset: 'assets/icons/trophy.svg',
                          label: s('home.badges'),
                          background: const Color(0xFFFFF3D6),
                          onTap: () => context.push(AppRoutes.badges, extra: 'sudoku'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 규칙 카드 (캐주얼)
                  CasualRulesCard(
                    aboutTitle: s('sudoku.about.title'),
                    aboutDesc: s('sudoku.about.desc'),
                    rulesTitle: s('sudoku.rules.title'),
                    rules: [
                      s('sudoku.rules.r1'),
                      s('sudoku.rules.r2'),
                      s('sudoku.rules.r3'),
                    ],
                    footerText: s('home.emptyHint'),
                    themeColor: themeColor,
                  ),
                ]),
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
  final GameState gameState;
  final Color themeColor;
  const _ContinueCard({required this.gameState, required this.themeColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final totalCells = 81;
    final filledCells = totalCells - gameState.board.emptyCellCount;
    final fixedCount = _countFixed(gameState.board);
    final userFilled = filledCells - fixedCount;
    final totalToFill = totalCells - fixedCount;
    final progress = totalToFill > 0 ? userFilled / totalToFill : 0.0;

    return CasualContinueCard(
      onTap: () {
        ref.read(gameProvider.notifier).resume();
        context.push(AppRoutes.game);
      },
      label: AppStrings.get('home.continue'),
      timeText: timeText,
      chips: [gameState.mode.label, gameState.difficulty.label],
      progress: progress,
      progressLabel: '${(progress * 100).toInt()}${AppStrings.get('home.progress')}',
      themeColor: themeColor,
    );
  }

  int _countFixed(SudokuBoard board) {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.isFixed[r][c]) count++;
      }
    }
    return count;
  }
}

/// 모드 타일 (BottomSheet 내부용)
class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 스도쿠 난이도 타일 (BottomSheet 내부용)
class _SudokuDifficultyTile extends StatelessWidget {
  final Difficulty difficulty;
  final bool isDark;
  final VoidCallback onTap;

  const _SudokuDifficultyTile({
    required this.difficulty,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor();
    final isExpertOrMaster =
        difficulty == Difficulty.expert || difficulty == Difficulty.master;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: diffColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('difficulty.${difficulty.name}'),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.get('difficulty.emptyCells.prefix')}${difficulty.emptyCellRange.$1}~${difficulty.emptyCellRange.$2}${AppStrings.get('difficulty.emptyCells.suffix')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                    ),
                    if (isExpertOrMaster) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.get('difficulty.${difficulty.name}.desc'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: difficulty == Difficulty.master
                                  ? Colors.purple.shade300
                                  : Colors.red.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// P1-5: DifficultyTokens 사용으로 다크모드 명도 개선
  Color _difficultyColor() {
    switch (difficulty) {
      case Difficulty.beginner:
        return DifficultyTokens.beginnerColor(isDark);
      case Difficulty.easy:
        return DifficultyTokens.easyColor(isDark);
      case Difficulty.medium:
        return DifficultyTokens.mediumColor(isDark);
      case Difficulty.hard:
        return DifficultyTokens.hardColor(isDark);
      case Difficulty.expert:
        return DifficultyTokens.expertColor(isDark);
      case Difficulty.master:
        return DifficultyTokens.masterColor(isDark);
    }
  }
}
