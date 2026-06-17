import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/settings/settings_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../tutorial/screens/tutorial_screen_v2.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('home.newGame.warning.title')),
        content: Text(s('home.newGame.warning.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showModeBottomSheet(context);
            },
            child: Text(s('home.newGame.warning.confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final hasOngoingGame = gameState != null && !gameState.isCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStrings.get;

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
      body: SafeArea(
        child: SingleChildScrollView(
          // P1-1: vertical padding 16→24로 통일 (12개 신규 게임과 동일)
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_on_rounded,
                // P1-2: 아이콘 size 64→56 통일
                size: 56,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              // P1-3: 아이콘과 부제목 사이 12→8
              const SizedBox(height: 8),
              Text(
                s('home.subtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
              ),
              // P1-3: 부제목 후 40→32
              const SizedBox(height: 32),

              if (hasOngoingGame) ...[
                _ContinueCard(gameState: gameState),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 진행 중인 게임이 있으면 경고
                    if (hasOngoingGame) {
                      _showNewGameWarning(context);
                    } else {
                      _showModeBottomSheet(context);
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(s('home.newGame')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.dailyPuzzle),
                  icon: const Icon(Icons.today_rounded),
                  label: Text(s('home.todayPuzzle')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      // 스도쿠 탭이 자동 선택되도록 extra 전달 (다른 게임과 일관성)
                      onPressed: () => context.push(AppRoutes.statistics, extra: 'sudoku'),
                      icon: const Icon(Icons.bar_chart_rounded, size: 20),
                      label: Text(s('home.statistics')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.badges, extra: 'sudoku'),
                      icon: const Icon(Icons.emoji_events_rounded, size: 20),
                      label: Text(s('home.badges')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 게임 설명/규칙은 진행 중 게임 여부와 무관하게 항상 표시
              _EmptyStateHint(isDark: isDark),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// 이어하기 카드
class _ContinueCard extends ConsumerWidget {
  final GameState gameState;
  const _ContinueCard({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minutes = gameState.elapsedSeconds ~/ 60;
    final secs = gameState.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // 진행률 계산
    final totalCells = 81;
    final filledCells = totalCells - gameState.board.emptyCellCount;
    final fixedCount = _countFixed(gameState.board);
    final userFilled = filledCells - fixedCount;
    final totalToFill = totalCells - fixedCount;
    final progress = totalToFill > 0 ? userFilled / totalToFill : 0.0;

    return Card(
      child: InkWell(
        onTap: () {
          ref.read(gameProvider.notifier).resume();
          context.push(AppRoutes.game);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_filled_rounded,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.get('home.continue'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    timeText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ChipLabel(
                    text: gameState.mode.label,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ChipLabel(
                    text: gameState.difficulty.label,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 진행률 바
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}${AppStrings.get('home.progress')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
              ),
            ],
          ),
        ),
      ),
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

/// 작은 라벨 칩
class _ChipLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _ChipLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          // P1-8: 비나이로와 명도 통일 (white60 → white54)
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }
}

/// 스도쿠 규칙 + 빈 상태 안내 카드
class _EmptyStateHint extends StatelessWidget {
  final bool isDark;
  const _EmptyStateHint({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white70 : Colors.black87;
    final bodyColor = isDark ? Colors.white54 : Colors.black54;
    final ruleColor = isDark ? Colors.white54 : Colors.black54;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('sudoku.about.title'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.get('sudoku.about.desc'),
              style: TextStyle(fontSize: 13, color: bodyColor, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('sudoku.rules.title'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            _ruleRow('1', AppStrings.get('sudoku.rules.r1'), ruleColor),
            const SizedBox(height: 6),
            _ruleRow('2', AppStrings.get('sudoku.rules.r2'), ruleColor),
            const SizedBox(height: 6),
            _ruleRow('3', AppStrings.get('sudoku.rules.r3'), ruleColor),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppStrings.get('home.emptyHint'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleRow(String num, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(num, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: color, height: 1.4)),
        ),
      ],
    );
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
