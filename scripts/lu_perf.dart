import 'package:ninedoku/games/light_up/engine/light_up_generator.dart';

void main() {
  print('=== Light Up 성능 측정 ===');
  // 난이도별 사이즈: 7, 8, 10, 12, 14
  const sizes = [7, 8, 10, 12, 14];
  for (int d = 0; d <= 4; d++) {
    int total = 0;
    int max = 0;
    int success = 0;
    for (int seed = 1; seed <= 3; seed++) {
      final sw = Stopwatch()..start();
      final result = LightUpGenerator.generate(
        size: sizes[d], difficulty: d, seed: seed,
      );
      sw.stop();
      total += sw.elapsedMilliseconds;
      if (sw.elapsedMilliseconds > max) max = sw.elapsedMilliseconds;
      if (result != null) success++;
      print('  d=$d size=${sizes[d]} seed=$seed: ${sw.elapsedMilliseconds}ms ${result != null ? "OK" : "FAIL"}');
    }
    print('  d=$d: avg=${total ~/ 3}ms max=${max}ms ok=$success/3');
  }
}
