import 'package:ninedoku/games/yin_yang/engine/yin_yang_generator.dart';

void main() {
  print('=== yin_yang quick test ===');
  for (int d = 0; d <= 4; d++) {
    int total = 0;
    int max = 0;
    int success = 0;
    for (int seed = 1; seed <= 3; seed++) {
      final sw = Stopwatch()..start();
      final size = YinYangGenerator.gridSizeForDifficulty(d);
      final result = YinYangGenerator.generate(size: size, difficulty: d, seed: seed);
      sw.stop();
      total += sw.elapsedMilliseconds;
      if (sw.elapsedMilliseconds > max) max = sw.elapsedMilliseconds;
      if (result != null) success++;
      print('  d=$d size=$size seed=$seed: ${sw.elapsedMilliseconds}ms ${result != null ? "OK" : "FAIL"}');
    }
    print('  d=$d: avg=${total ~/ 3}ms max=${max}ms ok=$success/3');
  }
}
