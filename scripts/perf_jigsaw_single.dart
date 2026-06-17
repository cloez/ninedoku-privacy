import 'package:ninedoku/games/jigsaw_sudoku/engine/jigsaw_sudoku_generator.dart';

// 인자: difficulty index seed
void main(List<String> args) {
  final dIdx = int.parse(args[0]);
  final seed = int.parse(args[1]);
  final d = JigsawDifficulty.values[dIdx];
  final sw = Stopwatch()..start();
  try {
    final r = JigsawSudokuGenerator.generate(difficulty: d, seed: seed);
    sw.stop();
    print('${d.name} seed=$seed: ${sw.elapsedMilliseconds}ms ${r != null ? "OK" : "NULL"}');
  } catch (e) {
    sw.stop();
    print('${d.name} seed=$seed: CRASH after ${sw.elapsedMilliseconds}ms: $e');
  }
}
