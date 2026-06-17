import '../../shared/l10n/app_strings.dart';

/// 난이도 정의
enum Difficulty {
  beginner(code: 0, labelKey: 'difficulty.beginner', emptyCellRange: (30, 35)),
  easy(code: 1, labelKey: 'difficulty.easy', emptyCellRange: (36, 40)),
  medium(code: 2, labelKey: 'difficulty.medium', emptyCellRange: (41, 46)),
  hard(code: 3, labelKey: 'difficulty.hard', emptyCellRange: (47, 52)),
  expert(code: 4, labelKey: 'difficulty.expert', emptyCellRange: (53, 58)),
  master(code: 5, labelKey: 'difficulty.master', emptyCellRange: (59, 62));

  const Difficulty({
    required this.code,
    required this.labelKey,
    required this.emptyCellRange,
  });

  /// 난이도 코드 (seed 생성용)
  final int code;

  /// 다국어 라벨 키
  final String labelKey;

  /// 현재 언어에 맞는 라벨 (다국어)
  String get label => AppStrings.get(labelKey);

  /// 빈 칸 개수 범위 (최소, 최대)
  final (int, int) emptyCellRange;

  /// MVP 난이도 (입문~어려움)
  static List<Difficulty> get mvpDifficulties =>
      [beginner, easy, medium, hard];
}

/// 빈 칸 개수 기반 간이 난이도 평가기
class DifficultyEvaluator {
  /// 빈 칸 개수로 난이도 분류
  static Difficulty evaluate(List<List<int>> puzzle) {
    var emptyCount = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (puzzle[r][c] == 0) emptyCount++;
      }
    }
    return evaluateByEmptyCount(emptyCount);
  }

  /// 빈 칸 개수로 직접 분류
  static Difficulty evaluateByEmptyCount(int emptyCount) {
    if (emptyCount <= 35) return Difficulty.beginner;
    if (emptyCount <= 40) return Difficulty.easy;
    if (emptyCount <= 46) return Difficulty.medium;
    if (emptyCount <= 52) return Difficulty.hard;
    if (emptyCount <= 58) return Difficulty.expert;
    return Difficulty.master;
  }
}
