import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 지뢰찾기 전용 — 연속 노미스 클리어 조건
class ConsecutiveNoMistakeCondition extends BadgeCondition {
  final int count;
  const ConsecutiveNoMistakeCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) {
    if (records.length < count) return false;
    int streak = 0;
    for (final r in records) {
      if (r.mistakeCount == 0) {
        streak++;
        if (streak >= count) return true;
      } else {
        streak = 0;
      }
    }
    return false;
  }
}

/// 지뢰찾기 전용 — 특정 난이도 + S등급 조건
class DifficultySGrade extends BadgeCondition {
  final String difficulty;
  const DifficultySGrade(this.difficulty);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.difficulty == difficulty && r.grade == 'S');
}

/// 지뢰찾기 배지 목록 (10개)
final minesweeperBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 클리어 (쉬움)
  const BadgeDefinition(
    id: 'minesweeper_first_sweep',
    name: '첫 번째 소탕',
    description: '지뢰찾기 첫 번째 퍼즐 완료',
    icon: '🔰',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10판 클리어 (쉬움)
  const BadgeDefinition(
    id: 'minesweeper_mine_hunter',
    name: '지뢰 사냥꾼',
    description: '클래식 모드 10판 클리어',
    icon: '🎯',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 입문 30초 이내 (쉬움)
  const BadgeDefinition(
    id: 'minesweeper_speed_sweeper',
    name: '스피드 스위퍼',
    description: '입문 난이도를 30초 이내에 클리어',
    icon: '⚡',
    condition: TimeUnderCondition(30),
  ),

  // 4. 5판 연속 노미스 (보통)
  const BadgeDefinition(
    id: 'minesweeper_flag_master',
    name: '깃발의 달인',
    description: '실수 없이 5판 연속 클리어',
    icon: '⚑',
    condition: ConsecutiveNoMistakeCondition(5),
  ),

  // 5. 보통 이상 S등급 (보통)
  const BadgeDefinition(
    id: 'minesweeper_logic_expert',
    name: '논리 전문가',
    description: '보통 이상 난이도에서 S등급 달성',
    icon: '🧠',
    condition: DifficultySGrade('medium'),
  ),

  // 6. 오늘의 퍼즐 7일 연속 (보통)
  const BadgeDefinition(
    id: 'minesweeper_daily_sweeper',
    name: '데일리 스위퍼',
    description: '오늘의 퍼즐 7일 연속 클리어',
    icon: '📅',
    condition: StreakDaysCondition(7),
  ),

  // 7. 힌트 없이 10판 (보통)
  const BadgeDefinition(
    id: 'minesweeper_no_hint_10',
    name: '자력 해결사',
    description: '힌트 없이 10판 클리어',
    icon: '💪',
    condition: NoHintGamesCondition(10),
  ),

  // 8. 어려움 클리어 (어려움)
  const BadgeDefinition(
    id: 'minesweeper_hard_clear',
    name: '고난도 돌파',
    description: '어려움 난이도 첫 클리어',
    icon: '🏔️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 마스터 S등급 (어려움)
  const BadgeDefinition(
    id: 'minesweeper_master_sweep',
    name: '마스터 스위퍼',
    description: '마스터 난이도에서 S등급 달성',
    icon: '🏆',
    condition: DifficultySGrade('master'),
  ),

  // 10. 100판 클리어 (어려움)
  const BadgeDefinition(
    id: 'minesweeper_mine_100',
    name: '100판 클럽',
    description: '지뢰찾기 총 100판 클리어',
    icon: '💎',
    condition: GamesCompletedCondition(100),
  ),
];

/// 힌트 없이 N게임 클리어 (비나이로에서 재활용)
class NoHintGamesCondition extends BadgeCondition {
  final int count;
  const NoHintGamesCondition(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}
