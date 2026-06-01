import '../../core/storage/game_storage_service.dart';

/// 배지 정의
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeCondition condition;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.condition,
  });
}

/// 배지 달성 조건
abstract class BadgeCondition {
  const BadgeCondition();
  bool evaluate(List<CompletedGameRecord> records);
}

/// 게임 완료 횟수 조건
class GamesCompletedCondition extends BadgeCondition {
  final int count;
  const GamesCompletedCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.length >= count;
}

/// 특정 난이도 첫 클리어
class DifficultyFirstClear extends BadgeCondition {
  final String difficulty;
  const DifficultyFirstClear(this.difficulty);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.difficulty == difficulty);
}

/// 노힌트 클리어
class NoHintClear extends BadgeCondition {
  const NoHintClear();

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.hintCount == 0);
}

/// 노미스테이크 클리어
class NoMistakeClear extends BadgeCondition {
  const NoMistakeClear();

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.mistakeCount == 0);
}

/// 퍼펙트 (노힌트 + 노미스테이크)
class PerfectClear extends BadgeCondition {
  const PerfectClear();

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.grade == 'S');
}

/// 시간 내 클리어
class TimeUnderCondition extends BadgeCondition {
  final int maxSeconds;
  const TimeUnderCondition(this.maxSeconds);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.elapsedSeconds <= maxSeconds);
}

/// 연속 일수 조건
class StreakDaysCondition extends BadgeCondition {
  final int days;
  const StreakDaysCondition(this.days);

  @override
  bool evaluate(List<CompletedGameRecord> records) {
    if (records.isEmpty) return false;
    final dates = records
        .map((r) => DateTime(
              r.completedAt.year,
              r.completedAt.month,
              r.completedAt.day,
            ))
        .toSet()
        .toList()
      ..sort();

    var maxStreak = 1;
    var streak = 1;
    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        streak++;
        if (streak > maxStreak) maxStreak = streak;
      } else {
        streak = 1;
      }
    }
    return maxStreak >= days;
  }
}

/// MVP 배지 목록 (12개)
final badgeDefinitions = <BadgeDefinition>[
  const BadgeDefinition(
    id: 'first_clear',
    name: '첫 걸음',
    description: '첫 번째 퍼즐 완료',
    icon: '🎯',
    condition: GamesCompletedCondition(1),
  ),
  const BadgeDefinition(
    id: 'no_hint',
    name: '독립 해결사',
    description: '힌트 없이 퍼즐 완료',
    icon: '💡',
    condition: NoHintClear(),
  ),
  const BadgeDefinition(
    id: 'no_mistake',
    name: '완벽주의자',
    description: '실수 없이 퍼즐 완료',
    icon: '✨',
    condition: NoMistakeClear(),
  ),
  const BadgeDefinition(
    id: 'perfect',
    name: '퍼펙트',
    description: '실수와 힌트 없이 퍼즐 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),
  const BadgeDefinition(
    id: 'speed_5min',
    name: '스피드러너',
    description: '5분 이내에 퍼즐 완료',
    icon: '⚡',
    condition: TimeUnderCondition(300),
  ),
  const BadgeDefinition(
    id: 'games_10',
    name: '열정 플레이어',
    description: '10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),
  const BadgeDefinition(
    id: 'games_50',
    name: '베테랑',
    description: '50게임 완료',
    icon: '⭐',
    condition: GamesCompletedCondition(50),
  ),
  const BadgeDefinition(
    id: 'games_100',
    name: '마스터',
    description: '100게임 완료',
    icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
  const BadgeDefinition(
    id: 'streak_3',
    name: '꾸준한 시작',
    description: '3일 연속 플레이',
    icon: '📅',
    condition: StreakDaysCondition(3),
  ),
  const BadgeDefinition(
    id: 'streak_7',
    name: '일주일 챌린지',
    description: '7일 연속 플레이',
    icon: '🗓️',
    condition: StreakDaysCondition(7),
  ),
  const BadgeDefinition(
    id: 'diff_hard',
    name: '도전자',
    description: '어려움 난이도 첫 클리어',
    icon: '🎖️',
    condition: DifficultyFirstClear('hard'),
  ),
  const BadgeDefinition(
    id: 'diff_expert',
    name: '전문가 정복',
    description: '전문가 난이도 첫 클리어',
    icon: '🏅',
    condition: DifficultyFirstClear('expert'),
  ),
  const BadgeDefinition(
    id: 'diff_master',
    name: '마스터 정복',
    description: '마스터 난이도 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),
  const BadgeDefinition(
    id: 'streak_30',
    name: '한 달의 습관',
    description: '30일 연속 플레이',
    icon: '🌟',
    condition: StreakDaysCondition(30),
  ),
];
