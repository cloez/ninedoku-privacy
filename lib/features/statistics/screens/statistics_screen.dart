import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/game_storage_service.dart';
import '../../../core/storage/statistics_service.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';
import '../widgets/time_trend_chart.dart';

/// 통계 화면 (S-10) — 전체/스도쿠/비나이로/지뢰찾기/음양/노노그램 탭 지원
class StatisticsScreen extends ConsumerStatefulWidget {
  /// 초기 탭: null → 0(전체), 'sudoku' → 1, 'binairo' → 2, 'minesweeper' → 3, 'yinyang' → 4, 'nonogram' → 5
  final String? initialTab;

  const StatisticsScreen({super.key, this.initialTab});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  /// initialTab 문자열을 탭 인덱스로 변환
  int get _initialIndex {
    switch (widget.initialTab) {
      case 'sudoku':
        return 1;
      case 'binairo':
        return 2;
      case 'minesweeper':
        return 3;
      case 'yinyang':
        return 4;
      case 'nonogram':
        return 5;
      case 'killerSudoku':
        return 6;
      case 'starBattle':
        return 7;
      case 'lightUp':
        return 8;
      case 'futoshiki':
        return 9;
      case 'tents':
        return 10;
      case 'jigsawSudoku':
        return 11;
      case 'skyscrapers':
        return 12;
      case 'kakuro':
        return 13;
      default:
        return 0;
    }
  }

  /// SharedPreferences에서 빌딩 완료 기록 로드
  List<CompletedGameRecord> _loadSkyscrapersRecords(SharedPreferences prefs) {
    final json = prefs.getString('skyscrapers_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 카쿠로 완료 기록 로드
  List<CompletedGameRecord> _loadKakuroRecords(SharedPreferences prefs) {
    final json = prefs.getString('kakuro_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 직소 스도쿠 완료 기록 로드
  List<CompletedGameRecord> _loadJigsawSudokuRecords(SharedPreferences prefs) {
    final json = prefs.getString('jigsaw_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 텐트 완료 기록 로드
  List<CompletedGameRecord> _loadTentsRecords(SharedPreferences prefs) {
    final json = prefs.getString('tents_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 후토시키 완료 기록 로드
  List<CompletedGameRecord> _loadFutoshikiRecords(SharedPreferences prefs) {
    final json = prefs.getString('futoshiki_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 라이트업 완료 기록 로드
  List<CompletedGameRecord> _loadLightUpRecords(SharedPreferences prefs) {
    final json = prefs.getString('lightup_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 스타 배틀 완료 기록 로드
  List<CompletedGameRecord> _loadStarBattleRecords(SharedPreferences prefs) {
    final json = prefs.getString('starbattle_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 킬러 스도쿠 완료 기록 로드
  List<CompletedGameRecord> _loadKillerSudokuRecords(SharedPreferences prefs) {
    final json = prefs.getString('killer_sudoku_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 지뢰찾기 완료 기록 로드
  List<CompletedGameRecord> _loadMinesweeperRecords(SharedPreferences prefs) {
    final json = prefs.getString('minesweeper_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 음양 완료 기록 로드
  List<CompletedGameRecord> _loadYinYangRecords(SharedPreferences prefs) {
    final json = prefs.getString('yinyang_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 노노그램 완료 기록 로드
  List<CompletedGameRecord> _loadNonogramRecords(SharedPreferences prefs) {
    final json = prefs.getString('nonogram_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// SharedPreferences에서 비나이로 완료 기록 로드
  List<CompletedGameRecord> _loadBinairoRecords(SharedPreferences prefs) {
    final json = prefs.getString('binairo_completed_games');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(gameStorageProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final sudokuRecords = storage.loadCompletedGames();
    final binairoRecords = _loadBinairoRecords(prefs);
    final minesweeperRecords = _loadMinesweeperRecords(prefs);
    final yinyangRecords = _loadYinYangRecords(prefs);
    final nonogramRecords = _loadNonogramRecords(prefs);
    final killerSudokuRecords = _loadKillerSudokuRecords(prefs);
    final starBattleRecords = _loadStarBattleRecords(prefs);
    final lightUpRecords = _loadLightUpRecords(prefs);
    final futoshikiRecords = _loadFutoshikiRecords(prefs);
    final tentsRecords = _loadTentsRecords(prefs);
    final jigsawSudokuRecords = _loadJigsawSudokuRecords(prefs);
    final skyscrapersRecords = _loadSkyscrapersRecords(prefs);
    final kakuroRecords = _loadKakuroRecords(prefs);
    final allRecords = [...sudokuRecords, ...binairoRecords, ...minesweeperRecords, ...yinyangRecords, ...nonogramRecords, ...killerSudokuRecords, ...starBattleRecords, ...lightUpRecords, ...futoshikiRecords, ...tentsRecords, ...jigsawSudokuRecords, ...skyscrapersRecords, ...kakuroRecords];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 14,
      initialIndex: _initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('stats.title')),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: AppStrings.get('stats.tab.all')),
              Tab(text: AppStrings.get('stats.tab.sudoku')),
              Tab(text: AppStrings.get('stats.tab.binairo')),
              Tab(text: AppStrings.get('stats.tab.minesweeper')),
              Tab(text: AppStrings.get('stats.tab.yinyang')),
              Tab(text: AppStrings.get('stats.tab.nonogram')),
              Tab(text: AppStrings.get('stats.tab.killerSudoku')),
              Tab(text: AppStrings.get('stats.tab.starBattle')),
              Tab(text: AppStrings.get('stats.tab.lightUp')),
              Tab(text: AppStrings.get('stats.tab.futoshiki')),
              Tab(text: AppStrings.get('stats.tab.tents')),
              Tab(text: AppStrings.get('stats.tab.jigsawSudoku')),
              Tab(text: AppStrings.get('stats.tab.skyscrapers')),
              Tab(text: AppStrings.get('stats.tab.kakuro')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 전체 탭
            _StatsContent(records: allRecords, isDark: isDark),
            // 스도쿠 탭
            _StatsContent(records: sudokuRecords, isDark: isDark),
            // 비나이로 탭
            _StatsContent(records: binairoRecords, isDark: isDark),
            // 지뢰찾기 탭
            _StatsContent(records: minesweeperRecords, isDark: isDark),
            // 음양 탭
            _StatsContent(records: yinyangRecords, isDark: isDark),
            // 노노그램 탭
            _StatsContent(records: nonogramRecords, isDark: isDark),
            // 킬러 스도쿠 탭
            _StatsContent(records: killerSudokuRecords, isDark: isDark),
            // 스타 배틀 탭
            _StatsContent(records: starBattleRecords, isDark: isDark),
            // 라이트업 탭
            _StatsContent(records: lightUpRecords, isDark: isDark),
            // 후토시키 탭
            _StatsContent(records: futoshikiRecords, isDark: isDark),
            // 텐트 탭
            _StatsContent(records: tentsRecords, isDark: isDark),
            // 직소 스도쿠 탭
            _StatsContent(records: jigsawSudokuRecords, isDark: isDark),
            // 빌딩 탭
            _StatsContent(records: skyscrapersRecords, isDark: isDark),
            // 카쿠로 탭
            _StatsContent(records: kakuroRecords, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

/// 통계 콘텐츠 (각 탭에서 재사용)
class _StatsContent extends StatelessWidget {
  final List<CompletedGameRecord> records;
  final bool isDark;

  const _StatsContent({required this.records, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _EmptyStats(isDark: isDark);
    }

    final stats = StatisticsService(records).getOverallStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          _SummaryRow(stats: stats, isDark: isDark),
          const SizedBox(height: 24),
          // 상세 통계
          Text(
            AppStrings.get('stats.detail'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _DetailCard(
            items: [
              _DetailItem(
                icon: Icons.timer_outlined,
                label: AppStrings.get('stats.avgTime'),
                value: _formatTime(stats.avgTime.round()),
              ),
              _DetailItem(
                icon: Icons.speed_rounded,
                label: AppStrings.get('stats.bestTime'),
                value: _formatTime(stats.bestTime),
              ),
              _DetailItem(
                icon: Icons.close_rounded,
                label: AppStrings.get('stats.avgMistakes'),
                value: stats.avgMistakes.toStringAsFixed(1),
              ),
              _DetailItem(
                icon: Icons.lightbulb_outline,
                label: AppStrings.get('stats.avgHints'),
                value: stats.avgHints.toStringAsFixed(1),
              ),
              _DetailItem(
                icon: Icons.emoji_events_rounded,
                label: AppStrings.get('stats.perfectCount'),
                value: '${stats.perfectCount}${AppStrings.get('stats.count.suffix')}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 시간 추이 차트
          Text(
            AppStrings.get('stats.timeTrend'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TimeTrendChart(records: records),
          const SizedBox(height: 24),
          // 난이도별 통계
          Text(
            AppStrings.get('stats.byDifficulty'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _DifficultyStatsTable(
            service: StatisticsService(records),
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          // 연속 플레이
          Text(
            AppStrings.get('stats.streakTitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StreakCard(
                  label: AppStrings.get('stats.current'),
                  days: stats.currentStreak,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StreakCard(
                  label: AppStrings.get('stats.longest'),
                  days: stats.longestStreak,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// 빈 통계 상태
class _EmptyStats extends StatelessWidget {
  final bool isDark;
  const _EmptyStats({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.get('stats.empty'),
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('stats.emptyHint'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

/// 요약 행
class _SummaryRow extends StatelessWidget {
  final GameStatistics stats;
  final bool isDark;
  const _SummaryRow({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            value: '${stats.totalGames}',
            label: AppStrings.get('stats.completed'),
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            value: '${stats.perfectCount}',
            label: AppStrings.get('stats.perfect'),
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            value: '${stats.currentStreak}${AppStrings.get('stats.days.suffix')}',
            label: AppStrings.get('stats.streak'),
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

/// 요약 카드
class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// 상세 통계 카드
class _DetailCard extends StatelessWidget {
  final List<_DetailItem> items;
  const _DetailCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                Row(
                  children: [
                    Icon(item.icon, size: 20),
                    const SizedBox(width: 12),
                    Text(item.label),
                    const Spacer(),
                    Text(
                      item.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (!isLast) const Divider(height: 20),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

/// 연속 플레이 카드
class _StreakCard extends StatelessWidget {
  final String label;
  final int days;
  final bool isDark;
  const _StreakCard({
    required this.label,
    required this.days,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$days',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
            ),
            Text('$label ${AppStrings.get('stats.streakDays')}'),
          ],
        ),
      ),
    );
  }
}

/// 난이도별 통계 테이블
class _DifficultyStatsTable extends StatelessWidget {
  final StatisticsService service;
  final bool isDark;

  const _DifficultyStatsTable({
    required this.service,
    required this.isDark,
  });

  List<(String, String)> get _localizedDifficulties => [
    (AppStrings.get('difficulty.beginner'), 'beginner'),
    (AppStrings.get('difficulty.easy'), 'easy'),
    (AppStrings.get('difficulty.medium'), 'medium'),
    (AppStrings.get('difficulty.hard'), 'hard'),
    (AppStrings.get('difficulty.expert'), 'expert'),
    (AppStrings.get('difficulty.master'), 'master'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.2),
          },
          children: [
            // 헤더
            TableRow(
              children: [
                _headerCell(AppStrings.get('stats.headerDifficulty')),
                _headerCell(AppStrings.get('stats.headerCompleted')),
                _headerCell(AppStrings.get('stats.headerAvgTime')),
                _headerCell(AppStrings.get('stats.headerBestTime')),
              ],
            ),
            // 각 난이도별 행
            for (final (label, key) in _localizedDifficulties)
              _buildRow(label, service.getStatsByDifficulty(key)),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _buildRow(String label, GameStatistics stats) {
    return TableRow(
      children: [
        _dataCell(label),
        _dataCell(stats.totalGames > 0 ? '${stats.totalGames}' : '-'),
        _dataCell(stats.totalGames > 0 ? _formatTime(stats.avgTime.round()) : '-'),
        _dataCell(stats.totalGames > 0 ? _formatTime(stats.bestTime) : '-'),
      ],
    );
  }

  Widget _dataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
