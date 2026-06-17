import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 킬러 스도쿠 전용 — 힌트 없이 N게임 클리어 조건
class KillerNoHintGamesCondition extends BadgeCondition {
  final int count;
  const KillerNoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 킬러 스도쿠 전용 — 모든 난이도에서 각각 S등급 달성
class KillerAllDifficultiesSGrade extends BadgeCondition {
  final List<String> difficulties;
  const KillerAllDifficultiesSGrade(this.difficulties);

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

/// 킬러 스도쿠 배지 목록 (10개)
final killerSudokuBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'killer_first',
    name: '킬러 첫 걸음',
    description: '킬러 스도쿠 첫 완료',
    icon: '🎯',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'killer_10',
    name: '킬러 열정',
    description: '킬러 스도쿠 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 스피드 클리어 (입문 3분 이내)
  const BadgeDefinition(
    id: 'killer_speed',
    name: '킬러 스피드',
    description: '입문 난이도 3분 이내 완료',
    icon: '⚡',
    condition: TimeUnderCondition(180),
  ),

  // 4. 퍼펙트 (실수+힌트 0)
  const BadgeDefinition(
    id: 'killer_perfect',
    name: '킬러 퍼펙트',
    description: '실수와 힌트 없이 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임
  const BadgeDefinition(
    id: 'killer_nohint',
    name: '킬러 자력',
    description: '힌트 없이 10게임 완료',
    icon: '💡',
    condition: KillerNoHintGamesCondition(10),
  ),

  // 6. 오늘의 퍼즐 클리어
  const BadgeDefinition(
    id: 'killer_daily',
    name: '킬러 데일리',
    description: '킬러 오늘의 퍼즐 완료',
    icon: '📅',
    condition: GamesCompletedCondition(1), // dailyPuzzle 모드 체크는 별도
  ),

  // 7. 5일 연속 플레이
  const BadgeDefinition(
    id: 'killer_streak5',
    name: '킬러 꾸준함',
    description: '5일 연속 킬러 스도쿠 플레이',
    icon: '🗓️',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움 첫 클리어
  const BadgeDefinition(
    id: 'killer_hard',
    name: '킬러 도전자',
    description: '어려움 난이도 첫 클리어',
    icon: '🏔️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 마스터 첫 클리어
  const BadgeDefinition(
    id: 'killer_master',
    name: '킬러 마스터',
    description: '마스터 난이도 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'killer_100',
    name: '킬러 달인',
    description: '킬러 스도쿠 100게임 완료',
    icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
];
