import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';
import 'package:ninedoku/core/storage/statistics_service.dart';
import 'package:ninedoku/features/badges/badge_definitions.dart';
import 'package:ninedoku/features/badges/badge_service.dart';
import 'package:ninedoku/features/daily_puzzle/daily_puzzle_service.dart';

void main() {
  // ============================================================
  // StatisticsService 추가 QA 테스트
  // ============================================================
  group('StatisticsService - QA 추가 테스트', () {
    test('단일 레코드 통계 정확성', () {
      final records = [
        _makeRecord(DateTime(2026, 5, 26), elapsedSeconds: 180),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.totalGames, 1);
      expect(stats.avgTime, 180.0);
      expect(stats.bestTime, 180);
      expect(stats.avgMistakes, 0.0);
      expect(stats.avgHints, 0.0);
    });

    test('난이도별 통계에서 avgHints 포함 확인 (수정된 버그)', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 1,
          hintCount: 2,
          grade: 'B',
          completedAt: DateTime(2026, 5, 20),
        ),
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 300,
          mistakeCount: 0,
          hintCount: 4,
          grade: 'C',
          completedAt: DateTime(2026, 5, 21),
        ),
      ];

      final easyStats = StatisticsService(records).getStatsByDifficulty('easy');
      // avgHints 가 (2+4)/2 = 3.0이어야 함
      expect(easyStats.avgHints, closeTo(3.0, 0.01));
      expect(easyStats.avgMistakes, closeTo(0.5, 0.01));
    });

    test('존재하지 않는 난이도 필터링시 빈 통계 반환', () {
      final records = [
        _makeRecord(DateTime(2026, 5, 20)),
      ];

      final stats =
          StatisticsService(records).getStatsByDifficulty('nonexistent');
      expect(stats.totalGames, 0);
      expect(stats.avgTime, 0);
      expect(stats.bestTime, 0);
    });

    test('currentStreak - 오늘 플레이한 경우', () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final records = [
        _makeRecord(todayDate.subtract(const Duration(days: 2))),
        _makeRecord(todayDate.subtract(const Duration(days: 1))),
        _makeRecord(todayDate),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });

    test('currentStreak - 어제까지 플레이한 경우', () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final records = [
        _makeRecord(todayDate.subtract(const Duration(days: 3))),
        _makeRecord(todayDate.subtract(const Duration(days: 2))),
        _makeRecord(todayDate.subtract(const Duration(days: 1))),
      ];

      final stats = StatisticsService(records).getOverallStats();
      // 어제가 마지막이면 daysDiff == 1이므로 currentStreak 유지
      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });

    test('currentStreak - 이틀 전까지만 플레이한 경우 (끊김)', () {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final records = [
        _makeRecord(todayDate.subtract(const Duration(days: 4))),
        _makeRecord(todayDate.subtract(const Duration(days: 3))),
        _makeRecord(todayDate.subtract(const Duration(days: 2))),
      ];

      final stats = StatisticsService(records).getOverallStats();
      // 2일 전이 마지막이면 daysDiff == 2이므로 currentStreak = 0
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 3);
    });

    test('longestStreak - 여러 streak 중 가장 긴 것 선택', () {
      final records = [
        // 첫 번째 streak: 4일
        _makeRecord(DateTime(2026, 5, 1)),
        _makeRecord(DateTime(2026, 5, 2)),
        _makeRecord(DateTime(2026, 5, 3)),
        _makeRecord(DateTime(2026, 5, 4)),
        // 중단
        // 두 번째 streak: 2일
        _makeRecord(DateTime(2026, 5, 10)),
        _makeRecord(DateTime(2026, 5, 11)),
        // 중단
        // 세 번째 streak: 3일
        _makeRecord(DateTime(2026, 5, 15)),
        _makeRecord(DateTime(2026, 5, 16)),
        _makeRecord(DateTime(2026, 5, 17)),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.longestStreak, 4);
    });

    test('perfectCount - grade S만 카운트', () {
      final records = [
        _makeRecord(DateTime(2026, 5, 20), grade: 'S'),
        _makeRecord(DateTime(2026, 5, 21), grade: 'A'),
        _makeRecord(DateTime(2026, 5, 22), grade: 'S'),
        _makeRecord(DateTime(2026, 5, 23), grade: 'C'),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.perfectCount, 2);
    });

    test('bestTime - 여러 레코드 중 최소값', () {
      final records = [
        _makeRecord(DateTime(2026, 5, 20), elapsedSeconds: 500),
        _makeRecord(DateTime(2026, 5, 21), elapsedSeconds: 120),
        _makeRecord(DateTime(2026, 5, 22), elapsedSeconds: 300),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.bestTime, 120);
    });

    test('같은 날 여러 게임은 streak 1일로 카운트', () {
      final records = [
        _makeRecord(DateTime(2026, 5, 20, 9, 0)),
        _makeRecord(DateTime(2026, 5, 20, 12, 0)),
        _makeRecord(DateTime(2026, 5, 20, 18, 0)),
      ];

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.longestStreak, 1);
    });
  });

  // ============================================================
  // BadgeCondition 추가 QA 테스트
  // ============================================================
  group('BadgeCondition - QA 추가 테스트', () {
    test('NoHintClear - 힌트 0인 레코드가 있으면 true', () {
      const cond = NoHintClear();
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 3,
          hintCount: 0,
          grade: 'C',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      expect(cond.evaluate(records), true);
    });

    test('NoHintClear - 모든 레코드에 힌트가 있으면 false', () {
      const cond = NoHintClear();
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 1,
          grade: 'A',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      expect(cond.evaluate(records), false);
    });

    test('NoMistakeClear - 실수 0인 레코드가 있으면 true', () {
      const cond = NoMistakeClear();
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 3,
          grade: 'C',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      expect(cond.evaluate(records), true);
    });

    test('NoMistakeClear - 모든 레코드에 실수가 있으면 false', () {
      const cond = NoMistakeClear();
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 2,
          hintCount: 0,
          grade: 'B',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      expect(cond.evaluate(records), false);
    });

    test('PerfectClear - grade S 레코드가 있으면 true', () {
      const cond = PerfectClear();
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      expect(cond.evaluate(records), true);
    });

    test('PerfectClear - grade S가 없으면 false', () {
      const cond = PerfectClear();
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'A',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      expect(cond.evaluate(records), false);
    });

    test('DifficultyFirstClear - 해당 난이도 레코드가 있으면 true', () {
      const cond = DifficultyFirstClear('hard');
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'hard',
          elapsedSeconds: 600,
          mistakeCount: 2,
          hintCount: 1,
          grade: 'C',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      expect(cond.evaluate(records), true);
    });

    test('DifficultyFirstClear - 다른 난이도만 있으면 false', () {
      const cond = DifficultyFirstClear('hard');
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      expect(cond.evaluate(records), false);
    });

    test('GamesCompletedCondition - 경계값: 정확히 count와 같을 때 true', () {
      const cond = GamesCompletedCondition(10);
      final records =
          List.generate(10, (i) => _makeRecord(DateTime(2026, 5, i + 1)));
      expect(cond.evaluate(records), true);
    });

    test('GamesCompletedCondition - 경계값: count-1이면 false', () {
      const cond = GamesCompletedCondition(10);
      final records =
          List.generate(9, (i) => _makeRecord(DateTime(2026, 5, i + 1)));
      expect(cond.evaluate(records), false);
    });

    test('GamesCompletedCondition - 빈 목록이면 false', () {
      const cond = GamesCompletedCondition(1);
      expect(cond.evaluate([]), false);
    });

    test('TimeUnderCondition - 경계값: 정확히 maxSeconds이면 true', () {
      const cond = TimeUnderCondition(300);
      final records = [_makeRecord(DateTime.now(), elapsedSeconds: 300)];
      expect(cond.evaluate(records), true);
    });

    test('TimeUnderCondition - 경계값: maxSeconds+1이면 false', () {
      const cond = TimeUnderCondition(300);
      final records = [_makeRecord(DateTime.now(), elapsedSeconds: 301)];
      expect(cond.evaluate(records), false);
    });

    test('StreakDaysCondition - 빈 목록이면 false', () {
      const cond = StreakDaysCondition(1);
      expect(cond.evaluate([]), false);
    });

    test('StreakDaysCondition - 단일 날짜: 1일 조건 충족', () {
      const cond = StreakDaysCondition(1);
      final records = [_makeRecord(DateTime(2026, 5, 20))];
      expect(cond.evaluate(records), true);
    });

    test('StreakDaysCondition - 같은 날 여러 게임은 1일로 카운트', () {
      const cond = StreakDaysCondition(2);
      final records = [
        _makeRecord(DateTime(2026, 5, 20, 9, 0)),
        _makeRecord(DateTime(2026, 5, 20, 12, 0)),
        _makeRecord(DateTime(2026, 5, 20, 18, 0)),
      ];
      expect(cond.evaluate(records), false);
    });
  });

  // ============================================================
  // BadgeService 추가 QA 테스트
  // ============================================================
  group('BadgeService - QA 추가 테스트', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('10게임 배지 경계값', () {
      final service = BadgeService(prefs);
      final records =
          List.generate(10, (i) => _makeRecord(DateTime(2026, 5, i + 1)));

      final newBadges = service.evaluateNewBadges(records);
      expect(newBadges.any((b) => b.id == 'games_10'), true);
    });

    test('9게임으로는 games_10 배지 미획득', () {
      final service = BadgeService(prefs);
      final records =
          List.generate(9, (i) => _makeRecord(DateTime(2026, 5, i + 1)));

      final newBadges = service.evaluateNewBadges(records);
      expect(newBadges.any((b) => b.id == 'games_10'), false);
    });

    test('연속 3일 배지', () {
      final service = BadgeService(prefs);
      final records = [
        _makeRecord(DateTime(2026, 5, 20)),
        _makeRecord(DateTime(2026, 5, 21)),
        _makeRecord(DateTime(2026, 5, 22)),
      ];

      final newBadges = service.evaluateNewBadges(records);
      expect(newBadges.any((b) => b.id == 'streak_3'), true);
    });

    test('연속 2일로는 streak_3 배지 미획득', () {
      final service = BadgeService(prefs);
      final records = [
        _makeRecord(DateTime(2026, 5, 20)),
        _makeRecord(DateTime(2026, 5, 21)),
      ];

      final newBadges = service.evaluateNewBadges(records);
      expect(newBadges.any((b) => b.id == 'streak_3'), false);
    });

    test('잘못된 JSON에서 복구 (acquired_badges)', () async {
      // 잘못된 JSON 저장
      await prefs.setString('acquired_badges', 'invalid_json{{{');
      final service = BadgeService(prefs);
      // 오류 없이 빈 Set 반환
      expect(service.getAcquiredBadgeIds(), isEmpty);
    });

    test('getAllBadges 목록 개수가 badgeDefinitions와 동일', () {
      final service = BadgeService(prefs);
      final all = service.getAllBadges();
      expect(all.length, badgeDefinitions.length);
      expect(all.length, 14); // MVP 14개 배지 (전문가/마스터 배지 추가)
    });

    test('배지 ID 중복 없음', () {
      final ids = badgeDefinitions.map((b) => b.id).toSet();
      expect(ids.length, badgeDefinitions.length);
    });

    test('여러 번 evaluateNewBadges 호출 시 누적 저장', () {
      final service = BadgeService(prefs);

      // 첫 번째 평가: 1게임
      final records1 = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 1,
          hintCount: 1,
          grade: 'B',
          completedAt: DateTime(2026, 5, 20),
        ),
      ];
      final first = service.evaluateNewBadges(records1);
      expect(first.any((b) => b.id == 'first_clear'), true);

      // 두 번째 평가: 퍼펙트 추가
      final records2 = [
        ...records1,
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 200,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime(2026, 5, 21),
        ),
      ];
      final second = service.evaluateNewBadges(records2);
      // first_clear은 이미 획득했으므로 포함되지 않아야 함
      expect(second.any((b) => b.id == 'first_clear'), false);
      // 퍼펙트, 노힌트, 노미스테이크 배지 새로 획득
      expect(second.any((b) => b.id == 'perfect'), true);
    });
  });

  // ============================================================
  // DailyPuzzleService 추가 QA 테스트
  // ============================================================
  group('DailyPuzzleService - QA 추가 테스트', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('seed 고유성: 연속 날짜들의 seed가 모두 다름', () {
      final seeds = <int>{};
      for (var i = 0; i < 365; i++) {
        final date = DateTime(2026, 1, 1).add(Duration(days: i));
        seeds.add(DailyPuzzleService.seedForDate(date));
      }
      expect(seeds.length, 365);
    });

    test('같은 날 재완료 시 상태 덮어쓰기', () async {
      final service = DailyPuzzleService(prefs);
      final date = DateTime(2026, 5, 26);

      // 일반 완료
      await service.markCompleted(date);
      expect(service.isCompleted(date), true);
      expect(service.isPerfect(date), false);

      // 퍼펙트로 재완료
      await service.markCompleted(date, perfect: true);
      expect(service.isPerfect(date), true);
    });

    test('퍼펙트에서 일반으로 덮어쓰기', () async {
      final service = DailyPuzzleService(prefs);
      final date = DateTime(2026, 5, 26);

      // 퍼펙트 완료
      await service.markCompleted(date, perfect: true);
      expect(service.isPerfect(date), true);

      // 일반으로 재완료 (등급 하락)
      await service.markCompleted(date, perfect: false);
      expect(service.isPerfect(date), false);
      expect(service.isCompleted(date), true);
    });

    test('잘못된 JSON에서 복구 (daily_puzzle_records)', () async {
      await prefs.setString('daily_puzzle_records', '{{invalid');
      final service = DailyPuzzleService(prefs);

      // 오류 없이 동작
      expect(service.isCompleted(DateTime(2026, 5, 26)), false);
      expect(service.totalCompleted, 0);
      expect(service.getMonthRecords(2026, 5), isEmpty);
    });

    test('다른 연도/월의 기록이 섞이지 않음', () async {
      final service = DailyPuzzleService(prefs);

      await service.markCompleted(DateTime(2025, 12, 31));
      await service.markCompleted(DateTime(2026, 1, 1));
      await service.markCompleted(DateTime(2026, 1, 15));

      final dec2025 = service.getMonthRecords(2025, 12);
      expect(dec2025.length, 1);
      expect(dec2025.containsKey(31), true);

      final jan2026 = service.getMonthRecords(2026, 1);
      expect(jan2026.length, 2);
      expect(jan2026.containsKey(1), true);
      expect(jan2026.containsKey(15), true);

      // 다른 월에는 기록 없음
      expect(service.getMonthRecords(2026, 2), isEmpty);
    });

    test('totalCompleted 정확성', () async {
      final service = DailyPuzzleService(prefs);

      await service.markCompleted(DateTime(2026, 5, 1));
      await service.markCompleted(DateTime(2026, 5, 2));
      await service.markCompleted(DateTime(2026, 5, 3), perfect: true);
      expect(service.totalCompleted, 3);

      // 같은 날 덮어쓰기는 totalCompleted 변경 안 됨
      await service.markCompleted(DateTime(2026, 5, 1), perfect: true);
      expect(service.totalCompleted, 3);
    });

    test('dateKey - 한 자릿수 월/일에 패딩 검증', () {
      expect(DailyPuzzleService.dateKey(DateTime(2026, 1, 1)), '20260101');
      expect(DailyPuzzleService.dateKey(DateTime(2026, 9, 9)), '20260909');
      expect(DailyPuzzleService.dateKey(DateTime(2026, 10, 10)), '20261010');
    });

    test('seedForDate - 알려진 값 검증', () {
      // 2026*10000 + 5*100 + 26 = 20260526
      expect(DailyPuzzleService.seedForDate(DateTime(2026, 5, 26)), 20260526);
      expect(DailyPuzzleService.seedForDate(DateTime(2000, 1, 1)), 20000101);
    });

    test('미완료 날짜의 isPerfect는 false', () {
      final service = DailyPuzzleService(prefs);
      expect(service.isPerfect(DateTime(2026, 5, 26)), false);
    });
  });

  // ============================================================
  // 배지 정의 무결성 테스트
  // ============================================================
  group('Badge Definitions - 무결성', () {
    test('모든 배지에 필수 필드가 채워져 있음', () {
      for (final badge in badgeDefinitions) {
        expect(badge.id.isNotEmpty, true, reason: '배지 ID가 비어있음');
        expect(badge.name.isNotEmpty, true, reason: '${badge.id}: name이 비어있음');
        expect(badge.description.isNotEmpty, true,
            reason: '${badge.id}: description이 비어있음');
        expect(badge.icon.isNotEmpty, true, reason: '${badge.id}: icon이 비어있음');
      }
    });

    test('14개 배지 정의', () {
      expect(badgeDefinitions.length, 14);
    });

    test('조건 클래스 타입 다양성', () {
      final conditionTypes =
          badgeDefinitions.map((b) => b.condition.runtimeType).toSet();
      // 7개 조건 클래스 중 일부가 사용되어야 함
      expect(conditionTypes.length, greaterThanOrEqualTo(5));
    });
  });

  // ============================================================
  // GameStatistics 기본값 테스트
  // ============================================================
  group('GameStatistics - 기본값', () {
    test('기본 생성자 모든 필드 0', () {
      const stats = GameStatistics();
      expect(stats.totalGames, 0);
      expect(stats.totalByDifficulty, 0);
      expect(stats.avgTime, 0);
      expect(stats.bestTime, 0);
      expect(stats.avgMistakes, 0);
      expect(stats.avgHints, 0);
      expect(stats.perfectCount, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
    });
  });

  // ============================================================
  // 통합 시나리오 테스트
  // ============================================================
  group('통합 시나리오', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('게임 완료 → 배지 획득 → 통계 반영 시나리오', () {
      // 퍼펙트 게임 레코드
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'easy',
          elapsedSeconds: 180,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime.now(),
        ),
      ];

      // 배지 평가
      final badgeService = BadgeService(prefs);
      final newBadges = badgeService.evaluateNewBadges(records);

      // 기대 배지: first_clear, no_hint, no_mistake, perfect, speed_5min
      final badgeIds = newBadges.map((b) => b.id).toSet();
      expect(badgeIds.contains('first_clear'), true);
      expect(badgeIds.contains('no_hint'), true);
      expect(badgeIds.contains('no_mistake'), true);
      expect(badgeIds.contains('perfect'), true);
      expect(badgeIds.contains('speed_5min'), true);

      // 통계 확인
      final stats = StatisticsService(records).getOverallStats();
      expect(stats.totalGames, 1);
      expect(stats.perfectCount, 1);
      expect(stats.bestTime, 180);
    });

    test('오늘의 퍼즐 완료 → 캘린더 기록 반영 시나리오', () async {
      final dailyService = DailyPuzzleService(prefs);
      final today = DateTime.now();

      // 오늘의 퍼즐 완료
      await dailyService.markCompleted(today, perfect: true);

      // 캘린더에서 확인
      final monthRecords =
          dailyService.getMonthRecords(today.year, today.month);
      expect(monthRecords.containsKey(today.day), true);
      expect(monthRecords[today.day], 'perfect');

      // 총 완료 수 확인
      expect(dailyService.totalCompleted, 1);
    });

    test('대량 레코드 통계 계산 성능', () {
      // 1000개의 레코드로 통계 계산이 정상 동작하는지 확인
      final records = List.generate(
        1000,
        (i) => CompletedGameRecord(
          mode: 'classic',
          difficulty: i % 4 == 0
              ? 'easy'
              : i % 4 == 1
                  ? 'medium'
                  : i % 4 == 2
                      ? 'hard'
                      : 'beginner',
          elapsedSeconds: 100 + i,
          mistakeCount: i % 5,
          hintCount: i % 3,
          grade: i % 10 == 0 ? 'S' : 'A',
          completedAt: DateTime(2026, 1, 1).add(Duration(days: i ~/ 3)),
        ),
      );

      final stats = StatisticsService(records).getOverallStats();
      expect(stats.totalGames, 1000);
      expect(stats.avgTime, greaterThan(0));
      expect(stats.bestTime, 100);
      expect(stats.perfectCount, 100); // 매 10번째 = 100개
    });

    test('대량 레코드 배지 평가 성능', () {
      final records = List.generate(
        100,
        (i) => _makeRecord(
          DateTime(2026, 1, 1).add(Duration(days: i)),
          elapsedSeconds: 200,
        ),
      );

      final badgeService = BadgeService(prefs);
      final newBadges = badgeService.evaluateNewBadges(records);

      // 100게임 완료 → games_100 배지 획득
      expect(newBadges.any((b) => b.id == 'games_100'), true);
      expect(newBadges.any((b) => b.id == 'games_50'), true);
      expect(newBadges.any((b) => b.id == 'games_10'), true);
    });
  });
}

/// 테스트용 기록 생성 헬퍼
CompletedGameRecord _makeRecord(
  DateTime completedAt, {
  int elapsedSeconds = 200,
  String grade = 'A',
  int mistakeCount = 0,
  int hintCount = 0,
}) {
  return CompletedGameRecord(
    mode: 'classic',
    difficulty: 'easy',
    elapsedSeconds: elapsedSeconds,
    mistakeCount: mistakeCount,
    hintCount: hintCount,
    grade: grade,
    completedAt: completedAt,
  );
}
