// 유일해 보장 강화 4건 — 생성 성능 측정 스크립트
// 실행: dart run scripts/qa_performance_check.dart
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_generator.dart';
import 'package:ninedoku/games/yin_yang/engine/yin_yang_generator.dart';
import 'package:ninedoku/games/yin_yang/yin_yang_state.dart';
import 'package:ninedoku/games/tents/engine/tents_generator.dart';
import 'package:ninedoku/games/tents/tents_state.dart';
import 'package:ninedoku/games/nonograms/engine/nonogram_generator.dart';
import 'package:ninedoku/games/nonograms/nonogram_state.dart';

void main() {
  print('=== killer_sudoku ===');
  for (final d in KillerDifficulty.values) {
    var sum = 0, max = 0, ok = 0;
    for (var seed = 1; seed <= 5; seed++) {
      final sw = Stopwatch()..start();
      final r = KillerSudokuGenerator.generate(difficulty: d, seed: seed);
      sw.stop();
      final ms = sw.elapsedMilliseconds;
      sum += ms;
      if (ms > max) max = ms;
      if (r != null) ok++;
    }
    print('  ${d.name}: avg=${sum ~/ 5}ms max=${max}ms ok=$ok/5');
  }

  print('=== yin_yang (master=16) ===');
  for (final d in YinYangDifficulty.values) {
    var sum = 0, max = 0, ok = 0;
    for (var seed = 1; seed <= 5; seed++) {
      final sw = Stopwatch()..start();
      final r = YinYangGenerator.generate(
          size: d.gridSize, difficulty: d.code, seed: seed);
      sw.stop();
      final ms = sw.elapsedMilliseconds;
      sum += ms;
      if (ms > max) max = ms;
      if (r != null) ok++;
    }
    print('  ${d.name}(size=${d.gridSize}): avg=${sum ~/ 5}ms max=${max}ms ok=$ok/5');
  }

  print('=== tents (master=12) ===');
  for (final d in TentsDifficulty.values) {
    var sum = 0, max = 0, ok = 0;
    for (var seed = 1; seed <= 5; seed++) {
      final sw = Stopwatch()..start();
      final r = TentsGenerator.generate(
          size: d.gridSize, difficulty: d.code, seed: seed);
      sw.stop();
      final ms = sw.elapsedMilliseconds;
      sum += ms;
      if (ms > max) max = ms;
      if (r != null) ok++;
    }
    print('  ${d.name}(size=${d.gridSize}): avg=${sum ~/ 5}ms max=${max}ms ok=$ok/5');
  }

  print('=== nonograms (hard=20) ===');
  for (final d in NonogramDifficulty.values) {
    var sum = 0, max = 0, ok = 0;
    for (var seed = 1; seed <= 5; seed++) {
      final sw = Stopwatch()..start();
      final r = NonogramGenerator.generate(
          size: d.gridSize, seed: seed, difficulty: d.code);
      sw.stop();
      final ms = sw.elapsedMilliseconds;
      sum += ms;
      if (ms > max) max = ms;
      if (r != null) ok++;
    }
    print('  ${d.name}(size=${d.gridSize}): avg=${sum ~/ 5}ms max=${max}ms ok=$ok/5');
  }
}
