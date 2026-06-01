/// 플랫폼 독립적인 결정론적 PRNG (Xoshiro128**)
/// 동일 seed에서 항상 동일한 시퀀스를 보장
///
/// 알고리즘 출처: David Blackman & Sebastiano Vigna (2018)
/// 원문: https://prng.di.unimi.it/xoshiro128starstar.c
/// 라이센스: Public Domain (CC0 1.0)
class SeededRandom {
  int _s0;
  int _s1;
  int _s2;
  int _s3;

  SeededRandom(int seed)
      : _s0 = _splitmix32(seed),
        _s1 = _splitmix32(seed + 1),
        _s2 = _splitmix32(seed + 2),
        _s3 = _splitmix32(seed + 3);

  /// SplitMix32로 초기 상태 생성
  static int _splitmix32(int seed) {
    seed = (seed + 0x9e3779b9) & 0xFFFFFFFF;
    seed = ((seed ^ (seed >> 16)) * 0x85ebca6b) & 0xFFFFFFFF;
    seed = ((seed ^ (seed >> 13)) * 0xc2b2ae35) & 0xFFFFFFFF;
    return (seed ^ (seed >> 16)) & 0xFFFFFFFF;
  }

  /// 32비트 왼쪽 회전
  static int _rotl(int x, int k) {
    return ((x << k) | ((x & 0xFFFFFFFF) >> (32 - k))) & 0xFFFFFFFF;
  }

  /// 다음 32비트 난수
  int _next() {
    final result = (_rotl((_s1 * 5) & 0xFFFFFFFF, 7) * 9) & 0xFFFFFFFF;
    final t = (_s1 << 9) & 0xFFFFFFFF;

    _s2 ^= _s0;
    _s3 ^= _s1;
    _s1 ^= _s2;
    _s0 ^= _s3;
    _s2 ^= t;
    _s3 = _rotl(_s3, 11);

    return result;
  }

  /// 0 이상 max 미만 정수 반환
  int nextInt(int max) {
    assert(max > 0);
    return (_next() & 0x7FFFFFFF) % max;
  }

  /// 리스트 셔플 (Fisher-Yates)
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  /// 날짜 + 난이도 코드로 seed 생성
  static int seedFromDate(DateTime date, int difficultyCode) {
    final dateInt = date.year * 10000 + date.month * 100 + date.day;
    return dateInt * 10 + difficultyCode;
  }
}
