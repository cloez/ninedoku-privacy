import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/custom_theme.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/game_storage_service.dart';
import '../../../shared/l10n/app_strings.dart';

/// 테마 선택 화면 (S-12)
class ThemeSelectScreen extends ConsumerWidget {
  const ThemeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currentTheme = settings.customTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 게임 기록 가져오기 (해금 조건 판정용)
    GameStorageService? storage;
    try {
      storage = ref.read(gameStorageProvider);
    } catch (_) {}

    final records = storage?.loadCompletedGames() ?? [];
    final totalGames = records.length;
    final difficultyGameCounts = <String, int>{};
    for (final record in records) {
      difficultyGameCounts[record.difficulty] =
          (difficultyGameCounts[record.difficulty] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('theme.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: CustomThemeType.values.map((type) {
          final isSelected = type.name == currentTheme;
          final isUnlocked = type.isFree ||
              (CustomThemeData.unlockConditions[type]?.isMet(
                    totalGames: totalGames,
                    difficultyGameCounts: difficultyGameCounts,
                  ) ??
                  true);

          return _ThemeCard(
            type: type,
            isSelected: isSelected,
            isUnlocked: isUnlocked,
            isDark: isDark,
            totalGames: totalGames,
            difficultyGameCounts: difficultyGameCounts,
            onTap: isUnlocked
                ? () async {
                    await settings.setCustomTheme(type.name);
                    ref.invalidate(settingsProvider);
                  }
                : null,
          );
        }).toList(),
      ),
    );
  }
}

/// 테마 카드
class _ThemeCard extends StatelessWidget {
  final CustomThemeType type;
  final bool isSelected;
  final bool isUnlocked;
  final bool isDark;
  final int totalGames;
  final Map<String, int> difficultyGameCounts;
  final VoidCallback? onTap;

  const _ThemeCard({
    required this.type,
    required this.isSelected,
    required this.isUnlocked,
    required this.isDark,
    required this.totalGames,
    required this.difficultyGameCounts,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = CustomThemeData.getColors(type);
    final condition = CustomThemeData.unlockConditions[type];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 테마 미리보기 (색상 팔레트)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.boardLine, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        '9',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.fixedNumber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.get('theme.${type.name}'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check_circle_rounded,
                                  size: 18, color: Theme.of(context).colorScheme.primary),
                            ],
                            if (!isUnlocked) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.lock_rounded, size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (!isUnlocked && condition != null)
                          Text(
                            _unlockDescription(condition),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                          )
                        else
                          Text(
                            AppStrings.get('theme.${type.name}.desc'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _unlockDescription(ThemeUnlockCondition condition) {
    if (condition.gamesCompleted != null) {
      return '${AppStrings.get('theme.unlock.games')} $totalGames/${condition.gamesCompleted}';
    }
    if (condition.difficultyClears != null) {
      final (diff, count) = condition.difficultyClears!;
      final current = difficultyGameCounts[diff] ?? 0;
      return '${AppStrings.get('difficulty.$diff')} ${AppStrings.get('theme.unlock.clears')} $current/$count';
    }
    return '';
  }
}
