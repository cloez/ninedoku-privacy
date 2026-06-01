import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/engine/game_registry.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../app/router.dart';

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
        body: SafeArea(
          child: Column(
            children: [
              // 상단: 오늘의 퍼즐 진행 + 연속 스트릭
              _buildProgressSection(context, s, colorScheme),
              const SizedBox(height: 16),
              // 중앙: 게임 카드 그리드
              Expanded(
                child: _buildGameGrid(context, s, colorScheme),
              ),
              // 하단: 내비게이션 버튼
              _buildBottomNav(context, s, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  /// 상단 진행 상황 섹션
  Widget _buildProgressSection(
    BuildContext context,
    String Function(String) s,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 오늘의 퍼즐 진행
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.today_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s('hub.dailyProgress')
                          .replaceFirst('{completed}', '0')
                          .replaceFirst('{total}', '1'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              // 연속 플레이 스트릭
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s('hub.streak').replaceFirst('{days}', '0'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
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
  ) {
    final games = GameRegistry.games;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return _buildGameCard(context, game, s, colorScheme);
        },
      ),
    );
  }

  /// 개별 게임 카드
  Widget _buildGameCard(
    BuildContext context,
    GameInfo game,
    String Function(String) s,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => context.push(game.routePath),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 카드 본문
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 이모지 또는 아이콘
                  Text(
                    game.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  // 게임 이름
                  Text(
                    s(game.nameKey),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // 게임 설명 (한 줄)
                  Text(
                    s(game.descriptionKey),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // NEW 배지 (우상단)
            if (game.isNew)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s('hub.new'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onError,
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
