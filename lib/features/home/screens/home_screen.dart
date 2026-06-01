import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../game/game_notifier.dart';
import '../../game/game_state.dart';
import '../../../core/sudoku/board.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/storage/storage_providers.dart';

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
              context.push(AppRoutes.modeSelect);
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

    // 하드웨어 백키 → 게임 허브로 이동
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // 게임 메인에서는 하드웨어 백키 무시 (허브 이동은 아이콘으로만)
      },
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
            onPressed: () => context.push(AppRoutes.tutorial),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.grid_on_rounded,
                size: 64,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                s('home.subtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
              ),
              const SizedBox(height: 40),

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
                      context.push(AppRoutes.modeSelect);
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
                      onPressed: () => context.push(AppRoutes.statistics),
                      icon: const Icon(Icons.bar_chart_rounded, size: 20),
                      label: Text(s('home.statistics')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.badges),
                      icon: const Icon(Icons.emoji_events_rounded, size: 20),
                      label: Text(s('home.badges')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (!hasOngoingGame)
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
          color: isDark ? Colors.white60 : Colors.black54,
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
