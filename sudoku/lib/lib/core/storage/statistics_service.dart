import 'game_storage_service.dart';

/// 통계 집계 결과
class GameStatistics {
  final int totalGames;
  final int totalByDifficulty;
  final double avgTime;
  final int bestTime;
  final double avgMistakes;
  final double avgHints;
  final int perfectCount;
  final int currentStreak;
  final int longestStreak;

  const GameStatistics({
    this.totalGames = 0,
    this.totalByDifficulty = 0,
    this.avgTime = 0,
    this.bestTime = 0,
    this.avgMistakes = 0,
    this.avgHints = 0,
    this.perfectCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });
}

/// 통계 서비스
class StatisticsService {
  final List<CompletedGameRecord> _records;

  StatisticsService(this._records);

  /// 전체 통계
  GameStatistics getOverallStats() {
    if (_records.isEmpty) return const GameStatistics();

    final times = _records.map((r) => r.elapsedSeconds).toList();
    final avgTime = times.reduce((a, b) => a + b) / times.length;
    final bestTime = times.reduce((a, b) => a < b ? a : b);
    final avgMistakes =
        _records.map((r) => r.mistakeCount).reduce((a, b) => a + b) /
            _records.length;
    final avgHints =
        _records.map((r) => r.hintCount).reduce((a, b) => a + b) /
            _records.length;
    final perfectCount = _records.where((r) => r.grade == 'S').length;

    // 연속 일수 계산
    final streaks = _calcStreaks();

    return GameStatistics(
      totalGames: _records.length,
      avgTime: avgTime,
      bestTime: bestTime,
      avgMistakes: avgMistakes,
      avgHints: avgHints,
      perfectCount: perfectCount,
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
    );
  }

  /// 난이도별 통계
  GameStatistics getStatsByDifficulty(String difficulty) {
    final filtered = _records.where((r) => r.difficulty == difficulty).toList();
    if (filtered.isEmpty) {
      return const GameStatistics();
    }

    final times = filtered.map((r) => r.elapsedSeconds).toList();
    final avgTime = times.reduce((a, b) => a + b) / times.length;
    final bestTime = times.reduce((a, b) => a < b ? a : b);
    final avgMistakes =
        filtered.map((r) => r.mistakeCount).reduce((a, b) => a + b) /
            filtered.length;
    final avgHints =
        filtered.map((r) => r.hintCount).reduce((a, b) => a + b) /
            filtered.length;

    return GameStatistics(
      totalGames: filtered.length,
      totalByDifficulty: filtered.length,
      avgTime: avgTime,
      bestTime: bestTime,
      avgMistakes: avgMistakes,
      avgHints: avgHints,
    );
  }

  /// 연속 플레이 일수 (현재, 최장)
  (int, int) _calcStreaks() {
    if (_records.isEmpty) return (0, 0);

    // 날짜별 그룹화
    final dates = _records
        .map((r) => DateTime(
              r.completedAt.year,
              r.completedAt.month,
              r.completedAt.day,
            ))
        .toSet()
        .toList()
      ..sort();

    if (dates.isEmpty) return (0, 0);

    var currentStreak = 1;
    var longestStreak = 1;
    var streak = 1;

    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        streak++;
        if (streak > longestStreak) longestStreak = streak;
      } else if (diff > 1) {
        streak = 1;
      }
    }

    // 루프 종료 후 마지막 streak가 최장일 수 있으므로 최종 비교
    if (streak > longestStreak) longestStreak = streak;

    // 현재 연속: 오늘 또는 어제가 마지막 날짜인 경우
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDate = dates.last;
    final daysDiff = todayDate.difference(lastDate).inDays;

    if (daysDiff <= 1) {
      currentStreak = streak;
    } else {
      currentStreak = 0;
    }

    return (currentStreak, longestStreak);
  }
}
