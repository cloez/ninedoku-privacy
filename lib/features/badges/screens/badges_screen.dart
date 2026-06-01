import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/l10n/app_strings.dart';
import '../badge_definitions.dart';
import '../badge_service.dart';

/// 배지 화면 (S-11)
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  // 배지 ID → 로컬라이즈 키 매핑
  static const _badgeKeyMap = {
    'first_clear': 'firstClear',
    'no_hint': 'noHint',
    'no_mistake': 'noMistake',
    'perfect': 'perfect',
    'speed_5min': 'speed5min',
    'games_10': 'games10',
    'games_50': 'games50',
    'games_100': 'games100',
    'streak_3': 'streak3',
    'streak_7': 'streak7',
    'diff_hard': 'diffHard',
    'diff_expert': 'diffExpert',
    'diff_master': 'diffMaster',
    'streak_30': 'streak30',
  };

  /// 배지 이름을 로컬라이즈하여 반환
  static String _badgeName(BadgeDefinition badge) {
    final key = _badgeKeyMap[badge.id];
    return key != null ? AppStrings.get('badge.$key') : badge.name;
  }

  /// 배지 설명을 로컬라이즈하여 반환
  static String _badgeDesc(BadgeDefinition badge) {
    final key = _badgeKeyMap[badge.id];
    return key != null ? AppStrings.get('badge.$key.desc') : badge.description;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final badgeService = BadgeService(prefs);
    final allBadges = badgeService.getAllBadges();
    final acquiredCount = allBadges.where((b) => b.acquired).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('badges.title'))),
      body: Column(
        children: [
          // 획득 요약
          _AcquiredSummary(
            acquired: acquiredCount,
            total: allBadges.length,
            isDark: isDark,
          ),
          // 배지 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: allBadges.length,
              itemBuilder: (context, index) {
                final item = allBadges[index];
                return _BadgeTile(
                  badge: item.badge,
                  acquired: item.acquired,
                  isDark: isDark,
                  onTap: () => _showBadgeDetail(context, item.badge, item.acquired, isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 배지 상세 다이얼로그
  void _showBadgeDetail(
    BuildContext context,
    BadgeDefinition badge,
    bool acquired,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              acquired ? badge.icon : '🔒',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              _badgeName(badge),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _badgeDesc(badge),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              acquired ? AppStrings.get('badges.acquiredDone') : AppStrings.get('badges.notAcquired'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: acquired ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('confirm')),
          ),
        ],
      ),
    );
  }
}

/// 획득 요약 헤더
class _AcquiredSummary extends StatelessWidget {
  final int acquired;
  final int total;
  final bool isDark;

  const _AcquiredSummary({
    required this.acquired,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? acquired / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '$acquired / $total',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.get('badges.acquired'),
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 배지 타일
class _BadgeTile extends StatelessWidget {
  final BadgeDefinition badge;
  final bool acquired;
  final bool isDark;
  final VoidCallback onTap;

  const _BadgeTile({
    required this.badge,
    required this.acquired,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: acquired ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                acquired ? badge.icon : '🔒',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  BadgesScreen._badgeName(badge),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
