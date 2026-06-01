import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/sudoku/difficulty.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../game/game_notifier.dart';
import '../../game/game_state.dart';
import '../daily_puzzle_service.dart';

/// 오늘의 퍼즐 화면 (S-08)
class DailyPuzzleScreen extends ConsumerWidget {
  const DailyPuzzleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final service = DailyPuzzleService(prefs);
    final today = DateTime.now();
    final isCompletedToday = service.isCompleted(today);
    final isPerfectToday = service.isPerfect(today);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('daily.title')),
        actions: [
          // 캘린더 보기
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => context.push(AppRoutes.dailyCalendar),
            tooltip: AppStrings.get('daily.calendar'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 날짜 표시
              Text(
                '${today.year}${AppStrings.get('daily.year')} ${today.month}${AppStrings.get('daily.month')} ${today.day}${AppStrings.get('daily.day')}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.get('daily.weekdayName.${today.weekday}'),
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 40),

              // 상태 아이콘
              Icon(
                isCompletedToday
                    ? (isPerfectToday
                        ? Icons.emoji_events_rounded
                        : Icons.check_circle_rounded)
                    : Icons.today_rounded,
                size: 80,
                color: isCompletedToday
                    ? (isPerfectToday ? const Color(0xFFFFD700) : Colors.green)
                    : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
              ),
              const SizedBox(height: 20),

              // 상태 텍스트
              Text(
                isCompletedToday
                    ? (isPerfectToday ? AppStrings.get('daily.perfectClear') : AppStrings.get('daily.completedToday'))
                    : AppStrings.get('daily.challenge'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isCompletedToday
                    ? AppStrings.get('daily.tomorrowNew')
                    : AppStrings.get('daily.dailyNew'),
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 12),
              // 난이도 안내
              Text(
                AppStrings.get('daily.difficultyMedium'),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 32),

              // 시작 버튼
              if (!isCompletedToday)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final seed = DailyPuzzleService.seedForDate(today);
                      ref.read(gameProvider.notifier).startNewGame(
                            mode: GameMode.dailyPuzzle,
                            difficulty: Difficulty.medium,
                            seed: seed * 10 + 2,
                          );
                      context.push(AppRoutes.game);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(AppStrings.get('daily.start')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

              // 총 완료 수
              const SizedBox(height: 24),
              Text(
                '${AppStrings.get('daily.totalPrefix')}${service.totalCompleted}${AppStrings.get('daily.totalSuffix')}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
