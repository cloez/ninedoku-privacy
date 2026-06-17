import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 후토시키 전용 — 힌트 없이 N게임 클리어 조건
class FutoshikiNoHintCondition extends BadgeCondition {
  final int count;
  const FutoshikiNoHintCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 후토시키 전용 — 특정 난이도 + 시간 제한 조건
class FutoshikiDiffTimeCondition extends BadgeCondition {
  final String difficulty;
  final int maxSeconds;
  const FutoshikiDiffTimeCondition(this.difficulty, this.maxSeconds);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any(
        (r) => r.difficulty == difficulty && r.elapsedSeconds <= maxSeconds,
      );
}

/// 후토시키 전용 — 특정 모드 첫 클리어 조건
class FutoshikiModeFirstClear extends BadgeCondition {
  final String mode;
  const FutoshikiModeFirstClear(this.mode);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.mode == mode);
}

/// 후토시키 배지 목록 (10개)
final futoshikiBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'futoshiki_first',
    name: '후토시키 첫 걸음',
    description: '후토시키 첫 번째 퍼즐 완료',
    icon: '⚖️',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'futoshiki_10',
    name: '후토시키 열정',
    description: '후토시키 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 스피드 (4×4를 60초 이내)
  const BadgeDefinition(
    id: 'futoshiki_speed',
    name: '후토시키 스피드',
    description: '4×4 퍼즐을 60초 이내에 완료',
    icon: '⚡',
    condition: FutoshikiDiffTimeCondition('beginner', 60),
  ),

  // 4. 퍼펙트 (실수+힌트 0)
  const BadgeDefinition(
    id: 'futoshiki_perfect',
    name: '후토시키 퍼펙트',
    description: '실수와 힌트 없이 후토시키 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임
  const BadgeDefinition(
    id: 'futoshiki_nohint',
    name: '후토시키 자력',
    description: '힌트 없이 후토시키 10게임 완료',
    icon: '💡',
    condition: FutoshikiNoHintCondition(10),
  ),

  // 6. 데일리 퍼즐 클리어
  const BadgeDefinition(
    id: 'futoshiki_daily',
    name: '후토시키 데일리',
    description: '후토시키 오늘의 퍼즐 완료',
    icon: '📅',
    condition: FutoshikiModeFirstClear('dailyPuzzle'),
  ),

  // 7. 5일 연속 플레이
  const BadgeDefinition(
    id: 'futoshiki_streak5',
    name: '후토시키 꾸준함',
    description: '5일 연속 후토시키 플레이',
    icon: '🗓️',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움 첫 클리어
  const BadgeDefinition(
    id: 'futoshiki_hard',
    name: '후토시키 도전자',
    description: '어려움 난이도 첫 클리어',
    icon: '🎖️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 마스터 첫 클리어
  const BadgeDefinition(
    id: 'futoshiki_master',
    name: '후토시키 마스터',
    description: '마스터 난이도(9×9) 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'futoshiki_100',
    name: '후토시키 달인',
    description: '후토시키 100게임 완료',
    icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
];
