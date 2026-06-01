import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'difficulty.dart';
import 'generator.dart';

/// 퍼즐 캐시 서비스 — 난이도별 퍼즐을 사전 생성하여 빠른 시작 지원
class PuzzleCacheService {
  static const _cachePrefix = 'puzzle_cache_';
  static const _maxPerDifficulty = 2;

  final SharedPreferences _prefs;

  PuzzleCacheService(this._prefs);

  /// 캐시에서 퍼즐 꺼내기 (없으면 null)
  ({List<List<int>> puzzle, List<List<int>> solution})? take(Difficulty difficulty) {
    final key = '$_cachePrefix${difficulty.name}';
    final raw = _prefs.getStringList(key);
    if (raw == null || raw.isEmpty) return null;

    // 첫 번째 항목 꺼내기
    final json = raw.removeAt(0);
    _prefs.setStringList(key, raw);

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final puzzle = (data['puzzle'] as List)
          .map((r) => (r as List).map((c) => c as int).toList())
          .toList();
      final solution = (data['solution'] as List)
          .map((r) => (r as List).map((c) => c as int).toList())
          .toList();
      return (puzzle: puzzle, solution: solution);
    } catch (_) {
      return null;
    }
  }

  /// 캐시에 퍼즐 추가
  void _add(Difficulty difficulty, List<List<int>> puzzle, List<List<int>> solution) {
    final key = '$_cachePrefix${difficulty.name}';
    final raw = _prefs.getStringList(key) ?? [];
    if (raw.length >= _maxPerDifficulty) return;

    final json = jsonEncode({'puzzle': puzzle, 'solution': solution});
    raw.add(json);
    _prefs.setStringList(key, raw);
  }

  /// 특정 난이도의 캐시 개수
  int count(Difficulty difficulty) {
    final key = '$_cachePrefix${difficulty.name}';
    return (_prefs.getStringList(key) ?? []).length;
  }

  /// 부족한 난이도의 퍼즐을 보충 생성
  Future<void> refillAll() async {
    for (final diff in Difficulty.values) {
      await refill(diff);
    }
  }

  /// 특정 난이도 캐시 보충
  Future<void> refill(Difficulty difficulty) async {
    final current = count(difficulty);
    if (current >= _maxPerDifficulty) return;

    final needed = _maxPerDifficulty - current;
    for (var i = 0; i < needed; i++) {
      final seed = DateTime.now().microsecondsSinceEpoch + i * 1000 + difficulty.code;
      final result = SudokuGenerator.generate(
        difficulty: difficulty,
        seed: seed,
      );
      if (result != null) {
        _add(difficulty, result.puzzle, result.solution);
      }
    }
  }
}
