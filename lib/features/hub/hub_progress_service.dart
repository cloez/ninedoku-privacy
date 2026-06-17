import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 허브 화면 진행률 계산 서비스
///
/// 모든 게임의 완료 기록을 통합하여:
/// - 오늘 완료한 오늘의 퍼즐 수
/// - 연속 플레이 스트릭 (최대)
/// 을 계산한다.
class HubProgressService {
  /// 각 게임 ID → 진행 중 게임 SharedPreferences 키
  /// (notifier들이 현재 게임 상태를 직렬화 저장하는 키)
  static const Map<String, String> _inProgressKeys = {
    'sudoku': 'current_game',
    'binairo': 'binairo_current_game',
    'minesweeper': 'minesweeper_current_game',
    'yinyang': 'yinyang_current_game',
    'nonogram': 'nonogram_current_game',
    'killerSudoku': 'killer_sudoku_current_game',
    'starBattle': 'starbattle_current_game',
    'lightUp': 'lightup_current_game',
    'futoshiki': 'futoshiki_current_game',
    'tents': 'tents_current_game',
    'jigsawSudoku': 'jigsaw_sudoku_current_game',
    'skyscrapers': 'skyscrapers_current_game',
    'kakuro': 'kakuro_current_game',
  };

  /// 특정 게임의 진행 중 여부 — current_game 키가 SharedPreferences에 존재하는지
  /// 게임 ID는 GameRegistry.games[].id와 일치해야 한다
  static bool isGameInProgress(SharedPreferences prefs, String gameId) {
    try {
      final key = _inProgressKeys[gameId];
      if (key == null) return false;
      return prefs.containsKey(key);
    } catch (_) {
      return false;
    }
  }

  /// 모든 게임의 SharedPreferences 키 (CompletedGameRecord 저장 위치)
  static const List<String> allGameKeys = [
    'completed_games',              // 스도쿠
    'binairo_completed_games',
    'minesweeper_completed_games',
    'yinyang_completed_games',
    'nonogram_completed_games',
    'killer_sudoku_completed_games',
    'starbattle_completed_games',
    'lightup_completed_games',
    'futoshiki_completed_games',
    'tents_completed_games',
    'jigsaw_completed_games',
    'skyscrapers_completed_games',
    'kakuro_completed_games',
  ];

  /// 오늘의 퍼즐 진행률 — 오늘 daily 퍼즐을 완료한 게임 수
  ///
  /// 반환: (오늘 완료한 게임 수, 전체 게임 수)
  static (int, int) todayDailyProgress(SharedPreferences prefs) {
    final today = DateTime.now();
    int completedCount = 0;

    for (final key in allGameKeys) {
      final hasDaily = _hasDailyPuzzleToday(prefs, key, today);
      if (hasDaily) completedCount++;
    }

    return (completedCount, allGameKeys.length);
  }

  /// 특정 게임 키에서 오늘 daily 퍼즐을 완료했는지
  static bool _hasDailyPuzzleToday(
    SharedPreferences prefs,
    String key,
    DateTime today,
  ) {
    final json = prefs.getString(key);
    if (json == null) return false;
    try {
      final list = jsonDecode(json) as List<dynamic>;
      for (final item in list) {
        final record = item as Map<String, dynamic>;
        // mode가 'dailyPuzzle'이고 completedAt이 오늘인 경우
        final mode = record['mode'] as String?;
        if (mode != 'dailyPuzzle') continue;
        final completedAtStr = record['completedAt'] as String?;
        if (completedAtStr == null) continue;
        final completedAt = DateTime.tryParse(completedAtStr);
        if (completedAt == null) continue;
        if (_isSameDay(completedAt, today)) return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// 두 날짜가 같은 날인지 (시간 무시)
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 연속 플레이 스트릭 (오늘 또는 어제부터 역행하여 연속된 일수)
  ///
  /// "하루에 1개 이상 게임 완료" = 그날 플레이한 것으로 간주
  static int currentStreak(SharedPreferences prefs) {
    final playDates = _collectAllPlayDates(prefs);
    if (playDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayKey = _dateOnly(today);

    // 오늘 또는 어제부터 시작
    DateTime cursor;
    if (playDates.contains(todayKey)) {
      cursor = todayKey;
    } else {
      final yesterday = todayKey.subtract(const Duration(days: 1));
      if (playDates.contains(yesterday)) {
        cursor = yesterday;
      } else {
        return 0;
      }
    }

    int streak = 0;
    while (playDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 모든 게임에서 플레이한 날짜 집합 수집 (yyyy-MM-dd 단위)
  static Set<DateTime> _collectAllPlayDates(SharedPreferences prefs) {
    final dates = <DateTime>{};

    for (final key in allGameKeys) {
      final json = prefs.getString(key);
      if (json == null) continue;
      try {
        final list = jsonDecode(json) as List<dynamic>;
        for (final item in list) {
          final record = item as Map<String, dynamic>;
          final completedAtStr = record['completedAt'] as String?;
          if (completedAtStr == null) continue;
          final completedAt = DateTime.tryParse(completedAtStr);
          if (completedAt == null) continue;
          dates.add(_dateOnly(completedAt));
        }
      } catch (_) {
        continue;
      }
    }

    return dates;
  }

  /// 날짜만 추출 (시간 0으로)
  static DateTime _dateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }
}
