import 'package:ninedoku/games/star_battle/engine/star_battle_generator.dart';

void main() {
  print('=== Star Battle 성능 측정 ===');
  for (int d = 0; d <= 4; d++) {
    int total = 0;
    int max = 0;
    int success = 0;
    for (int seed = 1; seed <= 3; seed++) {
      final sw = Stopwatch()..start();
      final result = StarBattleGenerator.generate(difficulty: d, seed: seed);
      sw.stop();
      total += sw.elapsedMilliseconds;
      if (sw.elapsedMilliseconds > max) max = sw.elapsedMilliseconds;
      if (result != null) success++;
      print('  d=$d seed=$seed: ${sw.elapsedMilliseconds}ms ${result != null ? "OK" : "FAIL"}');
    }
    print('  d=$d: avg=${total ~/ 3}ms max=${max}ms ok=$success/3');
  }
}
