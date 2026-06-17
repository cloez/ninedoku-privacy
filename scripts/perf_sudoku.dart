import 'package:ninedoku/core/sudoku/generator.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';

// 스도쿠 generator 성능 측정
void main() {
  print('=== Sudoku 성능 측정 ===');
  for (final d in Difficulty.values) {
    int total = 0;
    int max = 0;
    int success = 0;
    for (int seed = 1; seed <= 3; seed++) {
      final sw = Stopwatch()..start();
      try {
        final r = SudokuGenerator.generate(difficulty: d, seed: seed);
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
