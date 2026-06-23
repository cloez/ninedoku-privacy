import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// Skyscrapers 전용 — 힌트 없이 N게임 클리어 조건
class SkyNoHintGamesCondition extends BadgeCondition {
  final int count;
  const SkyNoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// Skyscrapers 전용 — 특정 난이도 + 시간 제한 조건
class SkyDifficultyTimeCondition extends BadgeCondition {
  final String difficulty;
  final int maxSeconds;
  const SkyDifficultyTimeCondition(this.difficulty, this.maxSeconds);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any(
        (r) => r.difficulty == difficulty && r.elapsedSeconds <= maxSeconds,
      );
}

/// Skyscrapers 전용 — 특정 모드 첫 클리어 조건
class SkyModeFirstClear extends BadgeCondition {
  final String mode;
  const SkyModeFirstClear(this.mode);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.mode == mode);
}

/// Skyscrapers 전용 — 모든 난이도에서 각각 S등급 달성 조건
class SkyAllDifficultiesSGrade extends BadgeCondition {
  final List<String> difficulties;
  const SkyAllDifficultiesSGrade(this.difficulties);

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

/// Skyscrapers 배지 목록 (10개)
final skyscrapersBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'sky_first',
    name: '빌딩 첫 걸음',
    description: '빌딩 첫 번째 퍼즐 완료',
    icon: '🏙️',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'sky_10',
    name: '빌딩 열정',
    description: '빌딩 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 4×4를 1분 이내 완료
  const BadgeDefinition(
    id: 'sky_speed',
    name: '빌딩 스피드',
    description: '4×4 퍼즐을 1분 이내에 완료',
    icon: '⚡',
    condition: SkyDifficultyTimeCondition('beginner', 60),
  ),

  // 4. 실수+힌트 0으로 완료 (퍼펙트)
  const BadgeDefinition(
    id: 'sky_perfect',
    name: '빌딩 퍼펙트',
    description: '실수와 힌트 없이 빌딩 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임 완료
  const BadgeDefinition(
    id: 'sky_nohint',
    name: '빌딩 자력',
    description: '힌트 없이 빌딩 완료',
    icon: '💡',
    condition: SkyNoHintGamesCondition(1),
  ),

  // 6. 오늘의 퍼즐 클리어
  const BadgeDefinition(
    id: 'sky_daily',
    name: '빌딩 일일 도전',
    description: '오늘의 퍼즐 첫 클리어',
    icon: '📅',
    condition: SkyModeFirstClear('dailyPuzzle'),
  ),

  // 7. 5일 연속 플레이
  const BadgeDefinition(
    id: 'sky_streak5',
    name: '빌딩 꾸준함',
    description: '5일 연속 빌딩 플레이',
    icon: '📆',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움(7×7) 첫 클리어
  const BadgeDefinition(
    id: 'sky_hard',
    name: '빌딩 도전자',
    description: '어려움 난이도(7×7) 첫 클리어',
    icon: '🎖️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 마스터(8×8) 첫 클리어
  const BadgeDefinition(
    id: 'sky_master',
    name: '빌딩 마스터',
    description: '마스터 난이도(8×8) 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'sky_100',
    name: '빌딩 레전드',
    description: '빌딩 100게임 완료',
    icon: '🌟',
    condition: GamesCompletedCondition(100),
  ),
];
