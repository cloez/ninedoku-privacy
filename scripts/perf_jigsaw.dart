import 'package:ninedoku/games/jigsaw_sudoku/engine/jigsaw_sudoku_generator.dart';

void main() {
  print('=== Jigsaw Sudoku 성능 측정 ===');
  for (final d in JigsawDifficulty.values) {
    int total = 0;
    int max = 0;
    int success = 0;
    for (int seed = 1; seed <= 3; seed++) {
      final sw = Stopwatch()..start();
      try {
        final r = JigsawSudokuGenerator.generate(
          difficulty: d,
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
