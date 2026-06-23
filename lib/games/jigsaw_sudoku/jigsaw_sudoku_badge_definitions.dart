import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 직소 스도쿠 전용 — 힌트 없이 N게임 클리어 조건
class JigsawNoHintGamesCondition extends BadgeCondition {
  final int count;
  const JigsawNoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 직소 스도쿠 배지 목록 (10개)
final jigsawSudokuBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'jigsaw_first',
    name: '직소 첫 걸음',
    description: '직소 스도쿠 첫 완료',
    icon: '🧩',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'jigsaw_10',
    name: '직소 열정',
    description: '직소 스도쿠 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 스피드 클리어 (입문 3분 이내)
  const BadgeDefinition(
    id: 'jigsaw_speed',
    name: '직소 스피드',
    description: '입문 난이도 3분 이내 완료',
    icon: '⚡',
    condition: TimeUnderCondition(180),
  ),

  // 4. 퍼펙트 (실수+힌트 0)
  const BadgeDefinition(
    id: 'jigsaw_perfect',
    name: '직소 퍼펙트',
    description: '실수와 힌트 없이 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임
  const BadgeDefinition(
    id: 'jigsaw_nohint',
    name: '직소 자력',
    description: '힌트 없이 완료',
    icon: '💡',
    condition: JigsawNoHintGamesCondition(1),
  ),

  // 6. 오늘의 퍼즐 클리어
  const BadgeDefinition(
    id: 'jigsaw_daily',
    name: '직소 데일리',
    description: '직소 오늘의 퍼즐 완료',
    icon: '📅',
    condition: GamesCompletedCondition(1),
  ),

  // 7. 5일 연속 플레이
  const BadgeDefinition(
    id: 'jigsaw_streak5',
    name: '직소 꾸준함',
    description: '5일 연속 직소 스도쿠 플레이',
    icon: '🗓️',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움 첫 클리어
  const BadgeDefinition(
    id: 'jigsaw_hard',
    name: '직소 도전자',
    description: '어려움 난이도 첫 클리어',
    icon: '🏔️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 마스터 첫 클리어
  const BadgeDefinition(
    id: 'jigsaw_master',
    name: '직소 마스터',
    description: '마스터 난이도 첫 클리어',
    icon: '💎',
    condition: DifficultyFirstClear('master'),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'jigsaw_100',
    name: '직소 달인',
    description: '직소 스도쿠 100게임 완료',
    icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
];
