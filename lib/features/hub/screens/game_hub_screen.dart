import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/engine/game_registry.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../app/router.dart';
import '../hub_progress_service.dart';

/// 게임 허브 화면 — 앱의 메인 화면 (게임 선택)
class GameHubScreen extends ConsumerWidget {
  const GameHubScreen({super.key});

  /// 앱 종료 확인 다이얼로그
  Future<bool> _showExitConfirm(BuildContext context) async {
    final s = AppStrings.get;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('hub.exitTitle')),
        content: Text(s('hub.exitMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s('exit.quit')),
          ),
        ],
      ),
    );
    if (result == true) {
      SystemNavigator.pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.get;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // P1-6, P1-7: 다크모드 분기 위해 isDark 계산
    final isDark = theme.brightness == Brightness.dark;

    // 모든 게임의 오늘의 퍼즐 진행률 + 스트릭 동적 계산
    final prefs = ref.watch(sharedPreferencesProvider);
    final (todayCompleted, totalGames) = HubProgressService.todayDailyProgress(prefs);
    final streakDays = HubProgressService.currentStreak(prefs);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitConfirm(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            s('hub.title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.settings),
              tooltip: s('home.settings'),
            ),
          ],
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? AppColors.hubGradientDark
                  : AppColors.hubGradientLight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 상단: 오늘의 퍼즐 진행 + 연속 스트릭
                _buildProgressSection(
                  context, s, colorScheme,
                  todayCompleted: todayCompleted,
                  totalGames: totalGames,
                  streakDays: streakDays,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // 중앙: 게임 카드 그리드
                Expanded(
                  child: _buildGameGrid(context, s, colorScheme, ref, isDark),
                ),
                // 하단: 내비게이션 버튼
                _buildBottomNav(context, s, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 상단 진행 상황 섹션 — 그라데이션 카드 스타일
  Widget _buildProgressSection(
    BuildContext context,
    String Function(String) s,
    ColorScheme colorScheme, {
    required int todayCompleted,
    required int totalGames,
    required int streakDays,
    required bool isDark,
  }) {
    final gradientColors = isDark
        ? AppColors.progressGradientDark
        : AppColors.progressGradientLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              // 오늘의 퍼즐 진행
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.today_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$todayCompleted / $totalGames',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s('hub.dailyLabel'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // 구분선
              Container(
                width: 1,
                height: 48,
                color: Colors.white24,
              ),
              // 연속 스트릭
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: streakDays > 0
                          ? AppColors.brandGold
                          : Colors.white54,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$streakDays',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s('hub.streakLabel'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 게임 카드 그리드 (2열)
  Widget _buildGameGrid(
    BuildContext context,
    String Function(String) s,
    ColorScheme colorScheme,
    WidgetRef ref,
    bool isDark,
  ) {
    final games = GameRegistry.games;
    final prefs = ref.watch(sharedPreferencesProvider);
    // P1-11: 작은 화면(360dp 미만)에서 카드 비율 축소하여 설명 잘림 방지
    final width = MediaQuery.of(context).size.width;
    final aspectRatio = width < 360 ? 0.75 : 0.85;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          final inProgress = HubProgressService.isGameInProgress(prefs, game.id);
          return _buildGameCard(context, game, s, colorScheme, inProgress, isDark, ref);
        },
      ),
    );
  }

  /// 게임 카드 탭 분기 — 튜토리얼 미시청이면 튜토리얼 먼저 표시
  Future<void> _onGameTap(
      BuildContext context, WidgetRef ref, GameInfo game) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final settings = SettingsService(prefs);
      if (!settings.isTutorialSeen(game.id)) {
        // 튜토리얼 push → 종료 시 자동 저장 후 게임 home으로
        await context.push('/tutorial/${game.id}');
        await settings.setTutorialSeen(game.id, true);
      }
      if (!context.mounted) return;
      context.push(game.routePath);
    } catch (e) {
      // 실패 시에도 게임 진입은 가능하게
      if (context.mounted) context.push(game.routePath);
    }
  }

  /// 개별 게임 카드 — 게임별 파스텔 테마 적용
  Widget _buildGameCard(
    BuildContext context,
    GameInfo game,
    String Function(String) s,
    ColorScheme colorScheme,
    bool inProgress,
    bool isDark,
    WidgetRef ref,
  ) {
    final gameColor = AppColors.gameThemeColors[game.id] ?? colorScheme.primary;
    final cardBg = isDark
        ? gameColor.withValues(alpha: 0.12)
        : (AppColors.gameCardBgColors[game.id] ?? Colors.white);

    return GestureDetector(
      onTap: () => _onGameTap(context, ref, game),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black26
                  : gameColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 카드 본문
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 상단: 번호 + 이모지 + 이름
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 게임 번호 배지
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: gameColor.withValues(alpha: isDark ? 0.3 : 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${game.order + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? gameColor.withValues(alpha: 0.9) : gameColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        game.emoji,
                        style: const TextStyle(fontSize: 40),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s(game.nameKey),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1D2340),
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // 하단: 설명
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      s(game.descriptionKey),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : const Color(0xFF68708A),
                            height: 1.3,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 우상단 배지
            if (inProgress)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s('hub.inProgress'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF1D2340),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              )
            else if (game.isNew)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandCoral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s('hub.new'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 하단 내비게이션 버튼
  Widget _buildBottomNav(
    BuildContext context,
    String Function(String) s,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 통계
          _buildNavButton(
            context,
            icon: Icons.bar_chart_rounded,
            label: s('home.statistics'),
            onTap: () => context.push(AppRoutes.statistics),
          ),
          // 배지
          _buildNavButton(
            context,
            icon: Icons.emoji_events_rounded,
            label: s('home.badges'),
            onTap: () => context.push(AppRoutes.badges),
          ),
          // 설정
          _buildNavButton(
            context,
            icon: Icons.settings_rounded,
            label: s('home.settings'),
            onTap: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }

  /// 하단 내비게이션 개별 버튼
  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
