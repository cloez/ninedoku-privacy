import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 라이트업 전용 — 힌트 없이 N게임 클리어 조건
class LightUpNoHintGamesCondition extends BadgeCondition {
  final int count;
  const LightUpNoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 라이트업 전용 — 특정 난이도 + 시간 제한 조건
class LightUpDifficultyTimeCondition extends BadgeCondition {
  final String difficulty;
  final int maxSeconds;
  const LightUpDifficultyTimeCondition(this.difficulty, this.maxSeconds);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any(
        (r) => r.difficulty == difficulty && r.elapsedSeconds <= maxSeconds,
      );
}

/// 라이트업 전용 — 특정 모드 첫 클리어 조건
class LightUpModeFirstClear extends BadgeCondition {
  final String mode;
  const LightUpModeFirstClear(this.mode);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.mode == mode);
}

/// 라이트업 배지 목록 (10개)
final lightUpBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'lightup_first',
    name: '💡 첫 걸음',
    description: '라이트업 첫 번째 퍼즐 완료',
    icon: '💡',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'lightup_10',
    name: '💡 열정',
    description: '라이트업 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 스피드 (7×7을 90초 이내)
  const BadgeDefinition(
    id: 'lightup_speed',
    name: '💡 스피드',
    description: '7×7 퍼즐을 90초 이내에 완료',
    icon: '⚡',
    condition: LightUpDifficultyTimeCondition('beginner', 90),
  ),

  // 4. 퍼펙트
  const BadgeDefinition(
    id: 'lightup_perfect',
    name: '💡 퍼펙트',
    description: '실수와 힌트 없이 라이트업 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임
  const BadgeDefinition(
    id: 'lightup_nohint',
    name: '💡 자력',
    description: '힌트 없이 10게임 완료',
    icon: '💪',
    condition: LightUpNoHintGamesCondition(10),
  ),

  // 6. 데일리 퍼즐 완료
  const BadgeDefinition(
    id: 'lightup_daily',
    name: '💡 데일리',
    description: '라이트업 오늘의 퍼즐 완료',
    icon: '📅',
    condition: LightUpModeFirstClear('dailyPuzzle'),
  ),

  // 7. 5일 연속 플레이
  const BadgeDefinition(
    id: 'lightup_streak5',
    name: '💡 꾸준함',
    description: '5일 연속 라이트업 플레이',
    icon: '🗓️',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움 난이도 첫 클리어
  const BadgeDefinition(
    id: 'lightup_hard',
    name: '💡 도전자',
    description: '어려움 난이도 첫 클리어',
    icon: '🎖️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 마스터 난이도 첫 클리어
  const BadgeDefinition(
    id: 'lightup_master',
    name: '💡 마스터',
    description: '마스터 난이도 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'lightup_100',
    name: '💡 달인',
    description: '라이트업 100게임 완료',
    icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
];
