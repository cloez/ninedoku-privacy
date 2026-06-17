import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_generator.dart';
void main() {
  var sum = 0, max = 0, ok = 0;
  for (var seed = 1; seed <= 5; seed++) {
    final sw = Stopwatch()..start();
    final r = KillerSudokuGenerator.generate(difficulty: KillerDifficulty.master, seed: seed);
    sw.stop();
    final ms = sw.elapsedMilliseconds;
    sum += ms;
    if (ms > max) max = ms;
    if (r != null) ok++;
    print('killer master seed=$seed: ${ms}ms ${r != null ? "OK" : "FAIL"}');
  }
  print('killer master: avg=${sum ~/ 5}ms max=${max}ms ok=$ok/5');
}
