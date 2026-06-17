import 'package:ninedoku/games/kakuro/engine/kakuro_generator.dart';

void main() {
  print('=== Kakuro 성능 측정 ===');
  // 카쿠로는 난이도 0~3 (4단계)
  const names = ['beginner', 'easy', 'medium', 'hard'];
  for (int d = 0; d <= 3; d++) {
    int total = 0;
    int max = 0;
    int success = 0;
    for (int seed = 1; seed <= 3; seed++) {
      final sw = Stopwatch()..start();
      try {
        final r = KakuroGenerator.generate(difficulty: d, seed: seed);
        sw.stop();
        if (r != null) success++;
      } catch (e) {
        sw.stop();
        print('  ${names[d]} seed=$seed: CRASH $e');
        continue;
      }
      total += sw.elapsedMilliseconds;
      if (sw.elapsedMilliseconds > max) max = sw.elapsedMilliseconds;
      print('  ${names[d]} seed=$seed: ${sw.elapsedMilliseconds}ms');
    }
    print('  ${names[d]}: avg=${total ~/ 3}ms max=${max}ms ok=$success/3');
  }
}
