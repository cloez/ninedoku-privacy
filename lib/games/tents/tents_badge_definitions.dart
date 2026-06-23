import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 텐트 전용 -- 힌트 없이 N게임 클리어 조건
class TentsNoHintGamesCondition extends BadgeCondition {
  final int count;
  const TentsNoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 텐트 전용 -- 특정 난이도 + 시간 제한 조건
class TentsDifficultyTimeCondition extends BadgeCondition {
  final String difficulty;
  final int maxSeconds;
  const TentsDifficultyTimeCondition(this.difficulty, this.maxSeconds);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any(
        (r) => r.difficulty == difficulty && r.elapsedSeconds <= maxSeconds,
      );
}

/// 텐트 전용 -- 특정 모드 첫 클리어 조건
class TentsModeFirstClear extends BadgeCondition {
  final String mode;
  const TentsModeFirstClear(this.mode);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.mode == mode);
}

/// 텐트 배지 목록 (10개)
final tentsBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'tents_first',
    name: '텐트 첫 걸음',
    description: '텐트 첫 번째 퍼즐 완료',
    icon: '⛺',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'tents_10',
    name: '텐트 열정',
    description: '텐트 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 6x6을 60초 이내 완료
  const BadgeDefinition(
    id: 'tents_speed',
    name: '텐트 스피드',
    description: '6x6 퍼즐을 60초 이내에 완료',
    icon: '⚡',
    condition: TentsDifficultyTimeCondition('beginner', 60),
  ),

  // 4. 실수+힌트 0으로 완료 (퍼펙트)
  const BadgeDefinition(
    id: 'tents_perfect',
    name: '텐트 퍼펙트',
    description: '실수와 힌트 없이 텐트 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임 완료
  const BadgeDefinition(
    id: 'tents_nohint',
    name: '텐트 자력',
    description: '힌트 없이 텐트 완료',
    icon: '💡',
    condition: TentsNoHintGamesCondition(1),
  ),

  // 6. 오늘의 퍼즐 클리어
  const BadgeDefinition(
    id: 'tents_daily',
    name: '텐트 데일리',
    description: '텐트 오늘의 퍼즐 완료',
    icon: '📅',
    condition: TentsModeFirstClear('dailyPuzzle'),
  ),

  // 7. 5일 연속 텐트 플레이
  const BadgeDefinition(
    id: 'tents_streak5',
    name: '텐트 꾸준함',
    description: '5일 연속 텐트 플레이',
    icon: '🗓️',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움 난이도 첫 클리어
  const BadgeDefinition(
    id: 'tents_hard',
    name: '텐트 도전자',
    description: '어려움 난이도 첫 클리어',
    icon: '🎖️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 마스터 난이도 첫 클리어
  const BadgeDefinition(
    id: 'tents_master',
    name: '텐트 마스터',
    description: '마스터 난이도 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'tents_100',
    name: '텐트 달인',
    description: '텐트 100게임 완료',
    icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
];
