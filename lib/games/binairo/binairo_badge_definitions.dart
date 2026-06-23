import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 비나이로 전용 — 힌트 없이 N게임 클리어 조건
class NoHintGamesCondition extends BadgeCondition {
  final int count;
  const NoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 비나이로 전용 — 특정 난이도 + 시간 제한 조건
class DifficultyTimeCondition extends BadgeCondition {
  final String difficulty;
  final int maxSeconds;
  const DifficultyTimeCondition(this.difficulty, this.maxSeconds);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any(
        (r) => r.difficulty == difficulty && r.elapsedSeconds <= maxSeconds,
      );
}

/// 비나이로 전용 — 특정 모드 첫 클리어 조건
class ModeFirstClear extends BadgeCondition {
  final String mode;
  const ModeFirstClear(this.mode);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.mode == mode);
}

/// 비나이로 전용 — 모든 난이도에서 각각 S등급 달성 조건
class AllDifficultiesSGrade extends BadgeCondition {
  final List<String> difficulties;
  const AllDifficultiesSGrade(this.difficulties);

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

/// 비나이로 배지 목록 (10개)
final binairoBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'binairo_first_clear',
    name: '비나이로 첫 걸음',
    description: '비나이로 첫 번째 퍼즐 완료',
    icon: '🎯',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'binairo_games_10',
    name: '비나이로 열정',
    description: '비나이로 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 50게임 완료
  const BadgeDefinition(
    id: 'binairo_games_50',
    name: '비나이로 베테랑',
    description: '비나이로 50게임 완료',
    icon: '⭐',
    condition: GamesCompletedCondition(50),
  ),

  // 4. 6×6을 1분 이내 완료
  const BadgeDefinition(
    id: 'binairo_speed',
    name: '비나이로 스피드',
    description: '6×6 퍼즐을 1분 이내에 완료',
    icon: '⚡',
    condition: DifficultyTimeCondition('beginner', 60),
  ),

  // 5. 실수+힌트 0으로 완료 (퍼펙트)
  const BadgeDefinition(
    id: 'binairo_perfect',
    name: '비나이로 퍼펙트',
    description: '실수와 힌트 없이 비나이로 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 6. 힌트 없이 10게임 완료
  const BadgeDefinition(
    id: 'binairo_no_hint',
    name: '비나이로 자력',
    description: '힌트 없이 비나이로 완료',
    icon: '💡',
    condition: NoHintGamesCondition(1),
  ),

  // 7. 14×14(마스터) 첫 클리어
  const BadgeDefinition(
    id: 'binairo_master',
    name: '비나이로 마스터',
    description: '마스터 난이도(14×14) 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),

  // 8. 도전 모드 클리어
  const BadgeDefinition(
    id: 'binairo_challenge',
    name: '비나이로 도전자',
    description: '도전 모드 첫 클리어',
    icon: '🎖️',
    condition: ModeFirstClear('challenge'),
  ),

  // 9. 3일 연속 비나이로 플레이
  const BadgeDefinition(
    id: 'binairo_streak_3',
    name: '비나이로 꾸준함',
    description: '3일 연속 비나이로 플레이',
    icon: '📅',
    condition: StreakDaysCondition(3),
  ),

  // 10. 모든 난이도 각 1회 S등급
  const BadgeDefinition(
    id: 'binairo_all_s',
    name: '비나이로 올클리어',
    description: '모든 난이도에서 각 1회 S등급 달성',
    icon: '🌟',
    condition: AllDifficultiesSGrade(
      ['beginner', 'easy', 'medium', 'hard', 'master'],
    ),
  ),
];
