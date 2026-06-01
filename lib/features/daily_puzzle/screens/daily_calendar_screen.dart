import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';
import '../daily_puzzle_service.dart';

/// 월간 캘린더 화면 (S-09)
class DailyCalendarScreen extends ConsumerStatefulWidget {
  const DailyCalendarScreen({super.key});

  @override
  ConsumerState<DailyCalendarScreen> createState() => _DailyCalendarScreenState();
}

class _DailyCalendarScreenState extends ConsumerState<DailyCalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    // 현재 월보다 미래로는 이동 불가
    if (nextMonth.isAfter(DateTime(now.year, now.month, 1))) return;
    setState(() {
      _currentMonth = nextMonth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = DailyPuzzleService(prefs);
    final records = service.getMonthRecords(_currentMonth.year, _currentMonth.month);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('daily.calendar'))),
      body: Column(
        children: [
          // 월 네비게이션
          _MonthNavigation(
            currentMonth: _currentMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          // 요일 헤더
          _WeekdayHeader(isDark: isDark),
          // 날짜 그리드
          Expanded(
            child: _CalendarGrid(
              currentMonth: _currentMonth,
              records: records,
              today: now,
              isDark: isDark,
            ),
          ),
          // 범례
          _Legend(isDark: isDark),
        ],
      ),
    );
  }
}

/// 월 네비게이션 바
class _MonthNavigation extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNavigation({
    required this.currentMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            '${currentMonth.year}${AppStrings.get('daily.year')} ${currentMonth.month}${AppStrings.get('daily.month')}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// 요일 헤더
class _WeekdayHeader extends StatelessWidget {
  final bool isDark;
  const _WeekdayHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final weekdays = [
      AppStrings.get('daily.weekday.sun'),
      AppStrings.get('daily.weekday.mon'),
      AppStrings.get('daily.weekday.tue'),
      AppStrings.get('daily.weekday.wed'),
      AppStrings.get('daily.weekday.thu'),
      AppStrings.get('daily.weekday.fri'),
      AppStrings.get('daily.weekday.sat'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: weekdays.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final isSunday = index == 0;
          final isSaturday = index == 6;
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSunday
                      ? Colors.red.shade300
                      : isSaturday
                          ? Colors.blue.shade300
                          : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 캘린더 그리드
class _CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final Map<int, String> records;
  final DateTime today;
  final bool isDark;

  const _CalendarGrid({
    required this.currentMonth,
    required this.records,
    required this.today,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday % 7;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: firstWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return const SizedBox.shrink();
        }

        final day = index - firstWeekday + 1;
        final date = DateTime(currentMonth.year, currentMonth.month, day);
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isFuture = date.isAfter(today);
        final status = records[day];

        return _DayCell(
          day: day,
          isToday: isToday,
          isFuture: isFuture,
          status: status,
          isDark: isDark,
        );
      },
    );
  }
}

/// 날짜 셀
class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isFuture;
  final String? status;
  final bool isDark;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = isDark ? Colors.white70 : Colors.black87;

    if (isFuture) {
      textColor = isDark ? Colors.white24 : Colors.black26;
    } else if (status == 'perfect') {
      bgColor = const Color(0xFFFFD700).withValues(alpha: 0.3);
    } else if (status == 'completed') {
      bgColor = Colors.green.withValues(alpha: 0.3);
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                width: 2,
              )
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            if (status != null)
              Icon(
                status == 'perfect' ? Icons.star_rounded : Icons.check_rounded,
                size: 12,
                color: status == 'perfect'
                    ? const Color(0xFFFFD700)
                    : Colors.green,
              ),
          ],
        ),
      ),
    );
  }
}

/// 범례
class _Legend extends StatelessWidget {
  final bool isDark;
  const _Legend({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(
            color: Colors.green.withValues(alpha: 0.3),
            label: AppStrings.get('daily.legend.completed'),
            isDark: isDark,
          ),
          const SizedBox(width: 24),
          _LegendItem(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            label: AppStrings.get('daily.legend.perfect'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

/// 범례 아이템
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
