import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/l10n/app_strings.dart';
import '../badge_definitions.dart';
import '../badge_service.dart';

/// 배지 화면 (S-11) — 전체/스도쿠/비나이로 탭 지원
class BadgesScreen extends ConsumerStatefulWidget {
  /// 초기 탭: null → 0(전체), 'sudoku' → 1, 'binairo' → 2
  final String? initialTab;

  const BadgesScreen({super.key, this.initialTab});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  // 스도쿠 배지 ID → 로컬라이즈 키 매핑
  static const _sudokuBadgeKeyMap = {
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

  /// 비나이로 배지 ID 목록
  static const _binairoBadgeIds = [
    'binairo_first_clear',
    'binairo_games_10',
    'binairo_games_50',
    'binairo_speed',
    'binairo_perfect',
    'binairo_no_hint',
    'binairo_master',
    'binairo_challenge',
    'binairo_streak_3',
    'binairo_all_s',
  ];

  /// 비나이로 배지 임시 이모지 매핑
  static const _binairoIcons = {
    'binairo_first_clear': '🎯',
    'binairo_games_10': '🔥',
    'binairo_games_50': '⭐',
    'binairo_speed': '⚡',
    'binairo_perfect': '🏆',
    'binairo_no_hint': '💡',
    'binairo_master': '💎',
    'binairo_challenge': '🎖️',
    'binairo_streak_3': '📅',
    'binairo_all_s': '🌟',
  };

  /// 초기 탭 인덱스 변환
  int get _initialIndex {
    switch (widget.initialTab) {
      case 'sudoku':
        return 1;
      case 'binairo':
        return 2;
      default:
        return 0;
    }
  }

  /// SharedPreferences에서 비나이로 획득 배지 ID 로드
  Set<String> _loadBinairoAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('binairo_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 비나이로 배지 아이템 리스트 생성
  List<_BadgeItem> _buildBinairoBadgeItems(Set<String> acquiredIds) {
    return _binairoBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _binairoIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'binairo',
      );
    }).toList();
  }

  /// 스도쿠 배지 아이템 리스트 생성
  List<_BadgeItem> _buildSudokuBadgeItems(BadgeService badgeService) {
    final allBadges = badgeService.getAllBadges();
    return allBadges.map((item) {
      final key = _sudokuBadgeKeyMap[item.badge.id];
      return _BadgeItem(
        id: item.badge.id,
        name: key != null ? AppStrings.get('badge.$key') : item.badge.name,
        description: key != null ? AppStrings.get('badge.$key.desc') : item.badge.description,
        icon: item.badge.icon,
        acquired: item.acquired,
        gameType: 'sudoku',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final badgeService = BadgeService(prefs);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 스도쿠 배지
    final sudokuBadges = _buildSudokuBadgeItems(badgeService);
    // 비나이로 배지
    final binairoAcquired = _loadBinairoAcquiredIds(prefs);
    final binairoBadges = _buildBinairoBadgeItems(binairoAcquired);
    // 전체 배지
    final allBadges = [...sudokuBadges, ...binairoBadges];

    return DefaultTabController(
      length: 3,
      initialIndex: _initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('badges.title')),
          bottom: TabBar(
            tabs: [
              Tab(text: AppStrings.get('badge.tab.all')),
              Tab(text: AppStrings.get('badge.tab.sudoku')),
              Tab(text: AppStrings.get('badge.tab.binairo')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 전체 탭
            _BadgesContent(badges: allBadges, isDark: isDark),
            // 스도쿠 탭
            _BadgesContent(badges: sudokuBadges, isDark: isDark),
            // 비나이로 탭
            _BadgesContent(badges: binairoBadges, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

/// 내부 배지 데이터 모델 (스도쿠/비나이로 공통)
class _BadgeItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool acquired;
  final String gameType; // 'sudoku' 또는 'binairo'

  const _BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.acquired,
    required this.gameType,
  });
}

/// 배지 콘텐츠 (각 탭에서 재사용)
class _BadgesContent extends StatelessWidget {
  final List<_BadgeItem> badges;
  final bool isDark;

  const _BadgesContent({required this.badges, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final acquiredCount = badges.where((b) => b.acquired).length;

    return Column(
      children: [
        // 획득 요약
        _AcquiredSummary(
          acquired: acquiredCount,
          total: badges.length,
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
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final item = badges[index];
              return _BadgeTile(
                badge: item,
                isDark: isDark,
                onTap: () => _showBadgeDetail(context, item, isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 배지 상세 다이얼로그
  void _showBadgeDetail(BuildContext context, _BadgeItem badge, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge.acquired ? badge.icon : '🔒',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.acquired
                  ? AppStrings.get('badges.acquiredDone')
                  : AppStrings.get('badges.notAcquired'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: badge.acquired ? Colors.green : Colors.grey,
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
  final _BadgeItem badge;
  final bool isDark;
  final VoidCallback onTap;

  const _BadgeTile({
    required this.badge,
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
          opacity: badge.acquired ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.acquired ? badge.icon : '🔒',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  badge.name,
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
