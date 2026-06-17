import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';

/// 노노그램 전용 — 힌트 없이 N게임 클리어 조건
class NoHintGamesNono extends BadgeCondition {
  final int count;
  const NoHintGamesNono(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.where((r) => r.hintCount == 0).length >= count;
}

/// 노노그램 전용 — 연속 노미스테이크 N게임 조건
class ConsecutiveNoMistakeNono extends BadgeCondition {
  final int count;
  const ConsecutiveNoMistakeNono(this.count);

  @override
  bool evaluate(List<CompletedGameRecord> records) {
    if (records.length < count) return false;
    int consecutive = 0;
    for (final r in records) {
      if (r.mistakeCount == 0) {
        consecutive++;
        if (consecutive >= count) return true;
      } else {
        consecutive = 0;
      }
    }
    return false;
  }
}

/// 노노그램 전용 — 특정 난이도에서 S등급 달성 조건
class DifficultySGradeNono extends BadgeCondition {
  final String difficulty;
  const DifficultySGradeNono(this.difficulty);

  @override
  bool evaluate(List<CompletedGameRecord> records) =>
      records.any((r) => r.difficulty == difficulty && r.grade == 'S');
}

/// 노노그램 배지 목록 (10개)
final nonogramBadgeDefinitions = <BadgeDefinition>[
  // 1. 첫 완료
  const BadgeDefinition(
    id: 'nono_first',
    name: '노노그램 첫 걸음',
    description: '노노그램 첫 번째 퍼즐 완료',
    icon: '🎯',
    condition: GamesCompletedCondition(1),
  ),

  // 2. 10게임 완료
  const BadgeDefinition(
    id: 'nono_10',
    name: '노노그램 열정',
    description: '노노그램 10게임 완료',
    icon: '🔥',
    condition: GamesCompletedCondition(10),
  ),

  // 3. 입문(5×5) 스피드 클리어 (1분 이내)
  const BadgeDefinition(
    id: 'nono_speed',
    name: '노노그램 스피드',
    description: '5×5 퍼즐을 1분 이내에 완료',
    icon: '⚡',
    condition: TimeUnderCondition(60),
  ),

  // 4. 실수+힌트 0으로 완료 (퍼펙트)
  const BadgeDefinition(
    id: 'nono_perfect',
    name: '노노그램 퍼펙트',
    description: '실수와 힌트 없이 노노그램 완료',
    icon: '🏆',
    condition: PerfectClear(),
  ),

  // 5. 힌트 없이 10게임 완료
  const BadgeDefinition(
    id: 'nono_nohint',
    name: '노노그램 자력',
    description: '힌트 없이 노노그램 10게임 완료',
    icon: '💡',
    condition: NoHintGamesNono(10),
  ),

  // 6. 데일리 퍼즐 첫 완료
  const BadgeDefinition(
    id: 'nono_daily',
    name: '노노그램 일일 도전',
    description: '오늘의 퍼즐 첫 완료',
    icon: '📅',
    condition: DifficultyFirstClear('easy'), // 데일리는 easy 난이도
  ),

  // 7. 5일 연속 플레이
  const BadgeDefinition(
    id: 'nono_streak5',
    name: '노노그램 꾸준함',
    description: '5일 연속 노노그램 플레이',
    icon: '🗓️',
    condition: StreakDaysCondition(5),
  ),

  // 8. 어려움(20×20) 첫 클리어
  const BadgeDefinition(
    id: 'nono_hard',
    name: '노노그램 도전자',
    description: '어려움 난이도(20×20) 첫 클리어',
    icon: '🎖️',
    condition: DifficultyFirstClear('hard'),
  ),

  // 9. 연속 노미스테이크 15게임
  const BadgeDefinition(
    id: 'nono_master15',
    name: '노노그램 장인',
    description: '연속 15게임 실수 없이 완료',
    icon: '💎',
    condition: ConsecutiveNoMistakeNono(15),
  ),

  // 10. 100게임 완료
  const BadgeDefinition(
    id: 'nono_100',
    name: '노노그램 마스터',
    description: '노노그램 100게임 완료',
    icon: '👑',
    condition: GamesCompletedCondition(100),
  ),
];
