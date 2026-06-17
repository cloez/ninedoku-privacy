import 'package:ninedoku/games/nonograms/engine/nonogram_generator.dart';
import 'package:ninedoku/games/nonograms/nonogram_state.dart';

void main() {
  print('=== Nonograms 성능 측정 ===');
  for (final d in NonogramDifficulty.values) {
    int total = 0;
    int max = 0;
    int success = 0;
    for (int seed = 1; seed <= 3; seed++) {
      final sw = Stopwatch()..start();
      try {
        final r = NonogramGenerator.generate(
          size: d.gridSize,
          difficulty: d.index,
          seed: seed,
        );
        sw.stop();
        if (r != null) success++;
      } catch (e) {
        sw.stop();
        print('  ${d.name} seed=$seed: CRASH $e');
        continue;
      }
      total += sw.elapsedMilliseconds;
      if (sw.elapsedMilliseconds > max) max = sw.elapsedMilliseconds;
      print('  ${d.name} seed=$seed: ${sw.elapsedMilliseconds}ms');
    }
    print('  ${d.name}: avg=${total ~/ 3}ms max=${max}ms ok=$success/3');
  }
}
