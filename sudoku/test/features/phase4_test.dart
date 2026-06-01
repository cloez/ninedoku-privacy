import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';
import 'package:ninedoku/core/storage/statistics_service.dart';
import 'package:ninedoku/features/badges/badge_definitions.dart';
import 'package:ninedoku/features/badges/badge_service.dart';
import 'package:ninedoku/features/daily_puzzle/daily_puzzle_service.dart';

void main() {
  group('StatisticsService', () {
    test('빈 기록에서 기본값 반환', () {
      final stats = StatisticsService([]).getOverallStats();
      expect(stats.totalGames, 0);
      expect(stats.avgTime, 0);
      expect(stats.bestTime, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
    });

    test('전체 통계 정확한 집계', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 120,
          mistakeCount: 1,
          hintCount: 0,
          grade: 'A',
          completedAt: DateTime(2026, 5, 20),
        ),
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'medium',
          elapsedSeconds: 300,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime(2026, 5, 21),
        ),
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'hard',
          elapsedSeconds: 600,
          mistakeCount: 2,
          hintCount: 1,
          grade: 'C',
          completedAt: DateTime(2026, 5, 22),
        ),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.totalGames, 3);
      expect(stats.avgTime, closeTo(340, 1));
      expect(stats.bestTime, 120);
      expect(stats.avgMistakes, closeTo(1.0, 0.01));
      expect(stats.avgHints, closeTo(0.33, 0.01));
      expect(stats.perfectCount, 1);
    });

    test('난이도별 통계 필터링', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 100,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime(2026, 5, 20),
        ),
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'hard',
          elapsedSeconds: 500,
          mistakeCount: 3,
          hintCount: 2,
          grade: 'C',
          completedAt: DateTime(2026, 5, 21),
        ),
      ];

      final easyStats = StatisticsService(records).getStatsByDifficulty('easy');
      expect(easyStats.totalGames, 1);
      expect(easyStats.bestTime, 100);

      final hardStats = StatisticsService(records).getStatsByDifficulty('hard');
      expect(hardStats.totalGames, 1);
      expect(hardStats.avgMistakes, 3.0);
    });

    test('연속 일수 계산 (연속 3일)', () {
      final records = [
        _makeRecord(DateTime(2026, 5, 20)),
        _makeRecord(DateTime(2026, 5, 21)),
        _makeRecord(DateTime(2026, 5, 22)),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.longestStreak, 3);
    });

    test('연속 일수 — 중간에 끊긴 경우', () {
      final records = [
        _makeRecord(DateTime(2026, 5, 20)),
        _makeRecord(DateTime(2026, 5, 21)),
        // 22일 빠짐
        _makeRecord(DateTime(2026, 5, 23)),
        _makeRecord(DateTime(2026, 5, 24)),
        _makeRecord(DateTime(2026, 5, 25)),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.longestStreak, 3);
    });

    test('같은 날 여러 게임은 한 날로 취급', () {
      final records = [
        _makeRecord(DateTime(2026, 5, 20, 10, 0)),
        _makeRecord(DateTime(2026, 5, 20, 15, 0)),
        _makeRecord(DateTime(2026, 5, 21)),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.longestStreak, 2);
    });
  });

  group('BadgeService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('초기 상태: 획득 배지 없음', () {
      final service = BadgeService(prefs);
      expect(service.getAcquiredBadgeIds(), isEmpty);
    });

    test('첫 게임 완료 시 first_clear 배지 획득', () {
      final service = BadgeService(prefs);
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 1,
          hintCount: 1,
          grade: 'B',
          completedAt: DateTime.now(),
        ),
      ];

      final newBadges = service.evaluateNewBadges(records);
      expect(newBadges.any((b) => b.id == 'first_clear'), true);
    });

    test('노힌트 클리어 배지', () {
      final service = BadgeService(prefs);
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 1,
          hintCount: 0,
          grade: 'A',
          completedAt: DateTime.now(),
        ),
      ];

      final newBadges = service.evaluateNewBadges(records);
      expect(newBadges.any((b) => b.id == 'no_hint'), true);
    });

    test('퍼펙트 클리어 배지', () {
      final service = BadgeService(prefs);
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime.now(),
        ),
      ];

      final newBadges = service.evaluateNewBadges(records);
      final badgeIds = newBadges.map((b) => b.id).toSet();
      expect(badgeIds.contains('perfect'), true);
      expect(badgeIds.contains('no_hint'), true);
      expect(badgeIds.contains('no_mistake'), true);
      expect(badgeIds.contains('first_clear'), true);
    });

    test('이미 획득한 배지는 재평가되지 않음', () {
      final service = BadgeService(prefs);
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime.now(),
        ),
      ];

      // 첫 평가
      final first = service.evaluateNewBadges(records);
      expect(first.isNotEmpty, true);

      // 두 번째 평가 — 동일 기록이면 새 배지 없음
      final second = service.evaluateNewBadges(records);
      expect(second, isEmpty);
    });

    test('getAllBadges 획득 여부 포함', () {
      final service = BadgeService(prefs);
      service.evaluateNewBadges([
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime.now(),
        ),
      ]);

      final all = service.getAllBadges();
      expect(all.length, badgeDefinitions.length);
      expect(all.any((b) => b.badge.id == 'first_clear' && b.acquired), true);
      expect(all.any((b) => b.badge.id == 'games_10' && !b.acquired), true);
    });

    test('스피드러너 배지 (5분 이내)', () {
      final service = BadgeService(prefs);
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 250, // 4분 10초
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime.now(),
        ),
      ];

      final newBadges = service.evaluateNewBadges(records);
      expect(newBadges.any((b) => b.id == 'speed_5min'), true);
    });

    test('어려움 난이도 첫 클리어 배지', () {
      final service = BadgeService(prefs);
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'hard',
          elapsedSeconds: 600,
          mistakeCount: 2,
          hintCount: 1,
          grade: 'C',
          completedAt: DateTime.now(),
        ),
      ];

      final newBadges = service.evaluateNewBadges(records);
      expect(newBadges.any((b) => b.id == 'diff_hard'), true);
    });
  });

  group('BadgeCondition', () {
    test('GamesCompletedCondition', () {
      final cond = const GamesCompletedCondition(3);
      expect(cond.evaluate([_makeRecord(DateTime.now())]), false);
      expect(cond.evaluate(List.generate(3, (_) => _makeRecord(DateTime.now()))), true);
    });

    test('StreakDaysCondition', () {
      final cond = const StreakDaysCondition(3);
      final records = [
        _makeRecord(DateTime(2026, 5, 20)),
        _makeRecord(DateTime(2026, 5, 21)),
        _makeRecord(DateTime(2026, 5, 22)),
      ];
      expect(cond.evaluate(records), true);

      final broken = [
        _makeRecord(DateTime(2026, 5, 20)),
        _makeRecord(DateTime(2026, 5, 22)),
      ];
      expect(cond.evaluate(broken), false);
    });

    test('TimeUnderCondition', () {
      final cond = const TimeUnderCondition(300);
      final fast = [_makeRecord(DateTime.now(), elapsedSeconds: 200)];
      final slow = [_makeRecord(DateTime.now(), elapsedSeconds: 400)];
      expect(cond.evaluate(fast), true);
      expect(cond.evaluate(slow), false);
    });
  });

  group('DailyPuzzleService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('seed 결정성: 같은 날짜는 같은 seed', () {
      final d1 = DailyPuzzleService.seedForDate(DateTime(2026, 5, 26));
      final d2 = DailyPuzzleService.seedForDate(DateTime(2026, 5, 26));
      expect(d1, d2);
    });

    test('다른 날짜는 다른 seed', () {
      final d1 = DailyPuzzleService.seedForDate(DateTime(2026, 5, 26));
      final d2 = DailyPuzzleService.seedForDate(DateTime(2026, 5, 27));
      expect(d1, isNot(d2));
    });

    test('완료 기록 저장 및 조회', () async {
      final service = DailyPuzzleService(prefs);
      final date = DateTime(2026, 5, 26);

      expect(service.isCompleted(date), false);

      await service.markCompleted(date);
      expect(service.isCompleted(date), true);
      expect(service.isPerfect(date), false);
    });

    test('퍼펙트 완료 기록', () async {
      final service = DailyPuzzleService(prefs);
      final date = DateTime(2026, 5, 26);

      await service.markCompleted(date, perfect: true);
      expect(service.isPerfect(date), true);
    });

    test('월간 기록 조회', () async {
      final service = DailyPuzzleService(prefs);
      await service.markCompleted(DateTime(2026, 5, 10));
      await service.markCompleted(DateTime(2026, 5, 15), perfect: true);
      await service.markCompleted(DateTime(2026, 6, 1));

      final may = service.getMonthRecords(2026, 5);
      expect(may.length, 2);
      expect(may[10], 'completed');
      expect(may[15], 'perfect');

      final june = service.getMonthRecords(2026, 6);
      expect(june.length, 1);
    });

    test('totalCompleted', () async {
      final service = DailyPuzzleService(prefs);
      expect(service.totalCompleted, 0);

      await service.markCompleted(DateTime(2026, 5, 10));
      await service.markCompleted(DateTime(2026, 5, 11));
      expect(service.totalCompleted, 2);
    });

    test('dateKey 형식 검증', () {
      expect(DailyPuzzleService.dateKey(DateTime(2026, 1, 5)), '20260105');
      expect(DailyPuzzleService.dateKey(DateTime(2026, 12, 25)), '20261225');
    });
  });
}

/// 테스트용 기록 생성 헬퍼
CompletedGameRecord _makeRecord(
  DateTime completedAt, {
  int elapsedSeconds = 200,
  String grade = 'A',
}) {
  return CompletedGameRecord(
    mode: 'classic',
    difficulty: 'easy',
    elapsedSeconds: elapsedSeconds,
    mistakeCount: 0,
    hintCount: 0,
    grade: grade,
    completedAt: completedAt,
  );
}
