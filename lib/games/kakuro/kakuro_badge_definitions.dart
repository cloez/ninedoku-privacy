import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 카쿠로 전용 — 힌트 없이 N게임 클리어 조건
class KakuroNoHintGamesCondition extends BadgeCondition {
  final int count;
  const KakuroNoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 카쿠로 전용 — 특정 난이도 + 시간 제한 조건
class KakuroDifficultyTimeCondition extends BadgeCondition {
  final String difficulty;
  final int maxSeconds;
  const KakuroDifficultyTimeCondition(this.difficulty, this.maxSeconds);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any(
        (r) => r.difficulty == difficulty && r.elapsedSeconds <= maxSeconds,
      );
}

/// 카쿠로 전용 — 특정 모드 첫 클리어 조건
class KakuroModeFirstClear extends BadgeCondition {
  final String mode;
  const KakuroModeFirstClear(this.mode);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.mode == mode);
}

/// 카쿠로 전용 — 모든 난이도에서 각각 S등급 달성 조건
class KakuroAllDifficultiesSGrade extends BadgeCondition {
  final List<String> difficulties;
  const KakuroAllDifficultiesSGrade(this.difficulties);

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

/// 카쿠로 배지 목록 (10개)
final kakuroBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'kakuro_first',
    name: '카쿠로 첫 걸음',
    description: '카쿠로 첫 번째 퍼즐 완료',
    icon: '🔢',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'kakuro_10',
    name: '카쿠로 열정',
    description: '카쿠로 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 6×6를 2분 이내 완료
  const BadgeDefinition(
    id: 'kakuro_speed',
    name: '카쿠로 스피드',
    description: '6×6 퍼즐을 2분 이내에 완료',
    icon: '⚡',
    condition: KakuroDifficultyTimeCondition('beginner', 120),
  ),

  // 4. 실수+힌트 0으로 완료 (퍼펙트)
  const BadgeDefinition(
    id: 'kakuro_perfect',
    name: '카쿠로 퍼펙트',
    description: '실수와 힌트 없이 카쿠로 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임 완료
  const BadgeDefinition(
    id: 'kakuro_nohint',
    name: '카쿠로 자력',
    description: '힌트 없이 카쿠로 완료',
    icon: '💡',
    condition: KakuroNoHintGamesCondition(1),
  ),

  // 6. 오늘의 퍼즐 클리어
  const BadgeDefinition(
    id: 'kakuro_daily',
    name: '카쿠로 일일 도전',
    description: '오늘의 퍼즐 첫 클리어',
    icon: '📅',
    condition: KakuroModeFirstClear('dailyPuzzle'),
  ),

  // 7. 5일 연속 플레이
  const BadgeDefinition(
    id: 'kakuro_streak5',
    name: '카쿠로 꾸준함',
    description: '5일 연속 카쿠로 플레이',
    icon: '📆',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움(12×12) 첫 클리어
  const BadgeDefinition(
    id: 'kakuro_hard',
    name: '카쿠로 도전자',
    description: '어려움 난이도(12×12) 첫 클리어',
    icon: '🎖️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 모든 난이도 S등급
  const BadgeDefinition(
    id: 'kakuro_master',
    name: '카쿠로 마스터',
    description: '모든 난이도에서 S등급 달성',
    icon: '💎',
    condition: KakuroAllDifficultiesSGrade(
      ['beginner', 'easy', 'medium', 'hard'],
    ),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'kakuro_100',
    name: '카쿠로 레전드',
    description: '카쿠로 100게임 완료',
    icon: '🌟',
    condition: GamesCompletedCondition(100),
  ),
];
