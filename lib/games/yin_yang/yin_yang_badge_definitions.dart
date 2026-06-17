import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 음양 전용 — 연속 노미스 클리어
class ConsecutiveNoMistakeYY extends BadgeCondition {
  final int count;
  const ConsecutiveNoMistakeYY(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) {
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

/// 음양 전용 — 힌트 없이 N게임
class NoHintGamesYY extends BadgeCondition {
  final int count;
  const NoHintGamesYY(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 음양 전용 — 특정 난이도 S등급
class DifficultySGradeYY extends BadgeCondition {
  final String difficulty;
  const DifficultySGradeYY(this.difficulty);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.difficulty == difficulty && r.grade == 'S');
}

/// 음양 배지 목록 (10개)
final yinYangBadgeDefinitions = <BadgeDefinition>[
  const BadgeDefinition(
    id: 'yinyang_first', name: '음양의 시작',
    description: '음양 첫 번째 퍼즐 완료', icon: '☯️',
    condition: GamesCompletedCondition(1),
  ),
  const BadgeDefinition(
    id: 'yinyang_10', name: '균형 탐구자',
    description: '음양 10판 클리어', icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),
  const BadgeDefinition(
    id: 'yinyang_speed', name: '순간 균형',
    description: '입문 난이도 45초 이내 클리어', icon: '⚡',
    condition: TimeUnderCondition(45),
  ),
  const BadgeDefinition(
    id: 'yinyang_perfect', name: '완벽한 조화',
    description: '실수와 힌트 없이 S등급 달성', icon: '🏆',
    condition: PerfectClear(),
  ),
  const BadgeDefinition(
    id: 'yinyang_nohint', name: '직관의 달인',
    description: '힌트 없이 10판 클리어', icon: '💡',
    condition: NoHintGamesYY(10),
  ),
  const BadgeDefinition(
    id: 'yinyang_daily', name: '매일의 균형',
    description: '7일 연속 데일리 퍼즐 클리어', icon: '📅',
    condition: StreakDaysCondition(7),
  ),
  const BadgeDefinition(
    id: 'yinyang_streak5', name: '연승 기록',
    description: '실수 없이 5판 연속 클리어', icon: '💪',
    condition: ConsecutiveNoMistakeYY(5),
  ),
  const BadgeDefinition(
    id: 'yinyang_hard', name: '고난도 균형',
    description: '어려움 난이도 첫 클리어', icon: '🏔️',
    condition: DifficultyFirstClear('hard'),
  ),
  const BadgeDefinition(
    id: 'yinyang_master', name: '음양 마스터',
    description: '마스터 난이도 S등급 달성', icon: '💎',
    condition: DifficultySGradeYY('master'),
  ),
  const BadgeDefinition(
    id: 'yinyang_100', name: '100판 클럽',
    description: '음양 총 100판 클리어', icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
];
