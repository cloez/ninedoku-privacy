import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/utils/seeded_random.dart';

void main() {
  group('SeededRandom', () {
    test('동일 seed는 동일 시퀀스를 생성한다', () {
      final rng1 = SeededRandom(42);
      final rng2 = SeededRandom(42);

      for (var i = 0; i < 100; i++) {
        expect(rng1.nextInt(1000), equals(rng2.nextInt(1000)));
      }
    });

    test('다른 seed는 다른 시퀀스를 생성한다', () {
      final rng1 = SeededRandom(42);
      final rng2 = SeededRandom(43);

      var sameCount = 0;
      for (var i = 0; i < 100; i++) {
        if (rng1.nextInt(1000) == rng2.nextInt(1000)) sameCount++;
      }
      // 우연히 같을 수 있지만 대부분 달라야 함
      expect(sameCount, lessThan(20));
    });

    test('shuffle이 결정적이다', () {
      final rng1 = SeededRandom(100);
      final rng2 = SeededRandom(100);

      final list1 = [1, 2, 3, 4, 5, 6, 7, 8, 9];
      final list2 = [1, 2, 3, 4, 5, 6, 7, 8, 9];

      rng1.shuffle(list1);
      rng2.shuffle(list2);

      expect(list1, equals(list2));
    });

    test('nextInt 범위가 올바르다', () {
      final rng = SeededRandom(999);
      for (var i = 0; i < 1000; i++) {
        final value = rng.nextInt(10);
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(10));
      }
    });

    test('seedFromDate가 결정적이다', () {
      final date = DateTime(2026, 5, 26);
      final seed1 = SeededRandom.seedFromDate(date, 1);
      final seed2 = SeededRandom.seedFromDate(date, 1);
      expect(seed1, equals(seed2));
      expect(seed1, equals(202605261)); // yyyyMMdd * 10 + code
    });

    test('날짜별 seed가 다르다', () {
      final date1 = DateTime(2026, 5, 26);
      final date2 = DateTime(2026, 5, 27);
      expect(
        SeededRandom.seedFromDate(date1, 0),
        isNot(equals(SeededRandom.seedFromDate(date2, 0))),
      );
    });
  });
}
