import 'package:ninedoku/games/skyscrapers/engine/skyscrapers_generator.dart';
import 'package:ninedoku/games/skyscrapers/skyscrapers_state.dart';

void main(List<String> args) {
  final dIdx = int.parse(args[0]);
  final seed = int.parse(args[1]);
  final d = SkyscrapersDifficulty.values[dIdx];
  final sw = Stopwatch()..start();
  try {
    final r = SkyscrapersGenerator.generate(size: d.gridSize, difficulty: d.index, seed: seed);
    sw.stop();
    print('${d.name} seed=$seed: ${sw.elapsedMilliseconds}ms ${r != null ? "OK" : "NULL"}');
  } catch (e) {
    sw.stop();
    print('${d.name} seed=$seed: CRASH after ${sw.elapsedMilliseconds}ms: $e');
  }
}
