import 'package:ninedoku/games/yin_yang/engine/yin_yang_generator.dart';
import 'package:ninedoku/games/yin_yang/yin_yang_state.dart';
import 'package:ninedoku/games/nonograms/engine/nonogram_generator.dart';
import 'package:ninedoku/games/nonograms/nonogram_state.dart';

void main() {
  print('=== yin_yang medium/hard/master ===');
  for (final d in [YinYangDifficulty.medium, YinYangDifficulty.hard, YinYangDifficulty.master]) {
    for (var seed = 1; seed <= 3; seed++) {
      final sw = Stopwatch()..start();
      final r = YinYangGenerator.generate(size: d.gridSize, difficulty: d.code, seed: seed);
      sw.stop();
      print('  ${d.name}(size=${d.gridSize}) seed=$seed: ${sw.elapsedMilliseconds}ms ${r != null ? "OK" : "FAIL"}');
    }
  }
  print('=== nonograms hard(20) ===');
  for (var seed = 1; seed <= 5; seed++) {
    final sw = Stopwatch()..start();
    final r = NonogramGenerator.generate(size: 20, seed: seed, difficulty: 3);
    sw.stop();
    print('  hard seed=$seed: ${sw.elapsedMilliseconds}ms ${r != null ? "OK" : "FAIL"}');
  }
}
