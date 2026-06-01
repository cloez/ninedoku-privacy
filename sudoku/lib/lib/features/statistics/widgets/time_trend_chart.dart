import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/storage/game_storage_service.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';

/// 완료 시간 추이 차트 (최근 20게임)
class TimeTrendChart extends StatefulWidget {
  final List<CompletedGameRecord> records;

  const TimeTrendChart({super.key, required this.records});

  @override
  State<TimeTrendChart> createState() => _TimeTrendChartState();
}

class _TimeTrendChartState extends State<TimeTrendChart> {
  String _selectedFilter = 'all';

  static const _filters = ['all', 'beginner', 'easy', 'medium', 'hard', 'expert', 'master'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filterRecords();

    if (filtered.isEmpty) {
      return _buildEmptyChart(isDark);
    }

    // 최근 20게임만 표시
    final recent = filtered.length > 20
        ? filtered.sublist(filtered.length - 20)
        : filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필터 탭
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final filter = _filters[i];
              final isActive = filter == _selectedFilter;
              final label = filter == 'all'
                  ? AppStrings.get('stats.all')
                  : AppStrings.get('difficulty.$filter');
              return ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: isActive,
                onSelected: (_) => setState(() => _selectedFilter = filter),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // 차트
        SizedBox(
          height: 200,
          child: LineChart(
            _buildChartData(recent, isDark),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '${AppStrings.get('stats.recentGames.prefix')}${recent.length}${AppStrings.get('stats.recentGames.suffix')}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      ],
    );
  }

  List<CompletedGameRecord> _filterRecords() {
    if (_selectedFilter == 'all') return widget.records;
    return widget.records
        .where((r) => r.difficulty == _selectedFilter)
        .toList();
  }

  LineChartData _buildChartData(List<CompletedGameRecord> records, bool isDark) {
    final spots = records.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.elapsedSeconds / 60.0, // 분 단위
      );
    }).toList();

    // 엣지케이스: spots가 비어있거나 모든 값이 0이면 기본 maxY 사용
    final rawMaxY = spots.isEmpty
        ? 0.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = rawMaxY < 1.0 ? 5.0 : rawMaxY; // 최소 5분 스케일
    final chartMaxY = ((maxY / 5).ceil() * 5 + 5).toDouble();

    final lineColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: chartMaxY > 20 ? 10 : 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDark ? Colors.white10 : Colors.black12,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: chartMaxY > 20 ? 10 : 5,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}${AppStrings.get('stats.minutes.suffix')}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              );
            },
          ),
        ),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      // 레코드 1개일 때 maxX가 0이면 차트가 비정상이므로 최소 1 보장
      maxX: records.length <= 1 ? 1.0 : (records.length - 1).toDouble(),
      minY: 0,
      maxY: chartMaxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: lineColor,
          barWidth: 2.5,
          dotData: FlDotData(
            show: records.length <= 10,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: lineColor,
                strokeWidth: 0,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withValues(alpha: 0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final record = records[spot.spotIndex];
              final minutes = record.elapsedSeconds ~/ 60;
              final secs = record.elapsedSeconds % 60;
              return LineTooltipItem(
                '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                TextStyle(
                  color: lineColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyChart(bool isDark) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Text(
          AppStrings.get('stats.noRecord'),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ),
    );
  }
}
