import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/games/killer_sudoku/engine/killer_sudoku_board.dart';
import 'package:ninedoku/games/killer_sudoku/widgets/cage_palette.dart';

void main() {
  group('CagePalette', () {
    test('인접 케이지는 다른 색', () {
      // 두 케이지가 서로 인접 (0,1)과 (0,2)가 맞닿음
      final cages = [
        const Cage(cells: [(0, 0), (0, 1)], sum: 5),
        const Cage(cells: [(0, 2), (1, 2)], sum: 8),
      ];
      final colors = CagePalette.assignColors(cages);
      expect(colors.length, 2);
      expect(colors[0] != colors[1], true);
    });

    test('비인접 케이지는 색이 같아도 OK', () {
      final cages = [
        const Cage(cells: [(0, 0)], sum: 5),
        const Cage(cells: [(5, 5)], sum: 8), // 멀리 떨어진 케이지
      ];
      final colors = CagePalette.assignColors(cages);
      expect(colors.length, 2);
      // 둘 다 색 인덱스 0..7 범위 내
      expect(colors[0] >= 0 && colors[0] < 8, true);
      expect(colors[1] >= 0 && colors[1] < 8, true);
    });

    test('모든 케이지에 색 할당됨 (-1 없음)', () {
      // 9x9 보드 위에 1셀짜리 케이지 20개 분포
      final cages = List.generate(
        20,
        (i) => Cage(cells: [(i ~/ 9, i % 9)], sum: 1),
      );
      final colors = CagePalette.assignColors(cages);
      expect(colors.length, 20);
      expect(colors.every((c) => c >= 0 && c < 8), true);
    });

    test('8색 인덱스 범위 내', () {
      expect(CagePalette.mainColors.length, 8);
    });

    test('빈 케이지 리스트 처리', () {
      final colors = CagePalette.assignColors(const []);
      expect(colors, isEmpty);
    });

    test('인접한 여러 케이지 모두 서로 다른 색', () {
      // 십자 모양: 중앙 + 상하좌우 4개 케이지가 모두 중앙과 인접
      final cages = [
        const Cage(cells: [(2, 2)], sum: 5), // 중앙
        const Cage(cells: [(1, 2)], sum: 3), // 위
        const Cage(cells: [(3, 2)], sum: 4), // 아래
        const Cage(cells: [(2, 1)], sum: 6), // 왼쪽
        const Cage(cells: [(2, 3)], sum: 7), // 오른쪽
      ];
      final colors = CagePalette.assignColors(cages);
      // 중앙은 4개 모두와 인접 → 4개 색과 달라야 함
      final center = colors[0];
      for (int i = 1; i < 5; i++) {
        expect(colors[i] != center, true,
            reason: '중앙(idx 0)과 인접 케이지(idx $i)의 색이 같으면 안 됨');
      }
    });

    test('배경/점선/합계 색상 함수 반환 일관성', () {
      // 라이트/다크 모두 동일 색상 인덱스로 호출 시 유효한 Color 반환
      for (int idx = 0; idx < 8; idx++) {
        for (final isDark in [false, true]) {
          expect(CagePalette.backgroundColor(idx, isDark), isNotNull);
          expect(CagePalette.dashColor(idx, isDark), isNotNull);
          expect(CagePalette.sumTextColor(idx, isDark), isNotNull);
        }
      }
    });
  });
}
