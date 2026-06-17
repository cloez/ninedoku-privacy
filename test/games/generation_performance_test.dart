/// 4게임(killer_sudoku/yin_yang/tents/nonograms) 생성 성능 회귀 테스트.
/// 모든 게임의 master 난이도는 3초 이내 응답 보장 (best-effort fallback 포함).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_generator.dart';
import 'package:ninedoku/games/nonograms/engine/nonogram_generator.dart';
import 'package:ninedoku/games/tents/engine/tents_generator.dart';
import 'package:ninedoku/games/yin_yang/engine/yin_yang_generator.dart';

void main() {
  // 한 케이스당 3초 한도 — fallback이라도 시간 내 반환되어야 함
  const int maxMs = 3000;

  group('생성 성능 < 3초 (best-effort fallback 포함)', () {
    test('killer_sudoku master 생성 시간 < 3초', () {
      for (int seed = 1; seed <= 3; seed++) {
        final sw = Stopwatch()..start();
        final result = KillerSudokuGenerator.generate(
          difficulty: KillerDifficulty.master,
          seed: seed,
        );
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(maxMs),
            reason: 'seed=$seed: ${sw.elapsedMilliseconds}ms');
        expect(result, isNotNull, reason: 'seed=$seed에서 fallback도 실패');
      }
    });

    test('killer_sudoku medium/hard 생성 시간 < 3초', () {
      for (final d in [KillerDifficulty.medium, KillerDifficulty.hard]) {
        for (int seed = 1; seed <= 3; seed++) {
          final sw = Stopwatch()..start();
          final result =
              KillerSudokuGenerator.generate(difficulty: d, seed: seed);
          sw.stop();
          expect(sw.elapsedMilliseconds, lessThan(maxMs),
              reason: '${d.name} seed=$seed: ${sw.elapsedMilliseconds}ms');
          expect(result, isNotNull);
        }
      }
    });

    test('yin_yang master(size=16) 생성 시간 < 3초', () {
      for (int seed = 1; seed <= 3; seed++) {
        final sw = Stopwatch()..start();
        final result = YinYangGenerator.generate(
          size: 16,
          difficulty: 4,
          seed: seed,
        );
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(maxMs),
            reason: 'seed=$seed: ${sw.elapsedMilliseconds}ms');
        expect(result, isNotNull, reason: 'seed=$seed에서 fallback도 실패');
      }
    });

    test('nonograms hard(size=20) 생성 시간 < 3초', () {
      for (int seed = 1; seed <= 3; seed++) {
        final sw = Stopwatch()..start();
        final result = NonogramGenerator.generate(
          size: 20,
          seed: seed,
          difficulty: 3,
        );
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(maxMs),
            reason: 'seed=$seed: ${sw.elapsedMilliseconds}ms');
        expect(result, isNotNull, reason: 'seed=$seed에서 fallback도 실패');
      }
    });

    test('tents master(size=12) 생성 시간 < 3초', () {
      for (int seed = 1; seed <= 3; seed++) {
        final sw = Stopwatch()..start();
        final result = TentsGenerator.generate(
          size: 12,
          difficulty: 4,
          seed: seed,
        );
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(maxMs),
            reason: 'seed=$seed: ${sw.elapsedMilliseconds}ms');
        expect(result, isNotNull);
      }
    });
  });
}
