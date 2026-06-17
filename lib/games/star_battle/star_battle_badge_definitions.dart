import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 스타 배틀 전용 — 힌트 없이 N게임 클리어 조건
class StarBattleNoHintGamesCondition extends BadgeCondition {
  final int count;
  const StarBattleNoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 스타 배틀 전용 — 특정 난이도 + 시간 제한 조건
class StarBattleDifficultyTimeCondition extends BadgeCondition {
  final String difficulty;
  final int maxSeconds;
  const StarBattleDifficultyTimeCondition(this.difficulty, this.maxSeconds);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any(
        (r) => r.difficulty == difficulty && r.elapsedSeconds <= maxSeconds,
      );
}

/// 스타 배틀 전용 — 특정 모드 첫 클리어 조건
class StarBattleModeFirstClear extends BadgeCondition {
  final String mode;
  const StarBattleModeFirstClear(this.mode);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.mode == mode);
}

/// 스타 배틀 전용 — 모든 난이도에서 각각 S등급 달성 조건
class StarBattleAllDifficultiesSGrade extends BadgeCondition {
  final List<String> difficulties;
  const StarBattleAllDifficultiesSGrade(this.difficulties);

  @override
  bool evaluate(List<CompletedGameRecord> records) {
    for (final diff in difficulties) {
      final hasS = records.any(
        (r) => r.difficulty == diff && r.grade == 'S',
      );
      if (!hasS) return false;
    }
    return true;
  }
}

/// 스타 배틀 배지 목록 (10개)
final starBattleBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'star_first',
    name: '★ 첫 걸음',
    description: '스타 배틀 첫 번째 퍼즐 완료',
    icon: '⭐',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'star_10',
    name: '★ 열정',
    description: '스타 배틀 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 스피드 — 입문(6×6)을 1분 이내
  const BadgeDefinition(
    id: 'star_speed',
    name: '★ 스피드',
    description: '6×6 퍼즐을 1분 이내에 완료',
    icon: '⚡',
    condition: StarBattleDifficultyTimeCondition('beginner', 60),
  ),

  // 4. 퍼펙트
  const BadgeDefinition(
    id: 'star_perfect',
    name: '★ 퍼펙트',
    description: '실수와 힌트 없이 스타 배틀 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임 완료
  const BadgeDefinition(
    id: 'star_nohint',
    name: '★ 자력',
    description: '힌트 없이 스타 배틀 10게임 완료',
    icon: '💡',
    condition: StarBattleNoHintGamesCondition(10),
  ),

  // 6. 데일리 퍼즐 완료
  const BadgeDefinition(
    id: 'star_daily',
    name: '★ 데일리',
    description: '스타 배틀 오늘의 퍼즐 완료',
    icon: '📅',
    condition: StarBattleModeFirstClear('dailyPuzzle'),
  ),

  // 7. 5일 연속 플레이
  const BadgeDefinition(
    id: 'star_streak5',
    name: '★ 꾸준함',
    description: '5일 연속 스타 배틀 플레이',
    icon: '🗓️',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움(9×9, 2-star) 첫 클리어
  const BadgeDefinition(
    id: 'star_hard',
    name: '★ 도전자',
    description: '어려움 난이도(9×9, 2-star) 첫 클리어',
    icon: '🎖️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 마스터(10×10, 2-star) 첫 클리어
  const BadgeDefinition(
    id: 'star_master',
    name: '★ 마스터',
    description: '마스터 난이도(10×10, 2-star) 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'star_100',
    name: '★ 달인',
    description: '스타 배틀 100게임 완료',
    icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
];
