import 'package:flutter/material.dart';
import '../engine/killer_sudoku_board.dart';

/// 케이지 색상 팔레트 (8색)
/// - Material Design 기반 8색 메인 컬러
/// - 인접 케이지는 서로 다른 색상으로 할당 (그리디 알고리즘)
class CagePalette {
  /// 8색 메인 컬러
  static const List<Color> mainColors = [
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00897B), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFFFFB300), // Amber
    Color(0xFF3949AB), // Indigo
  ];

  /// 배경 색상 (라이트 9% / 다크 13%)
  static Color backgroundColor(int colorIdx, bool isDark) {
    final base = mainColors[colorIdx % mainColors.length];
    return base.withValues(alpha: isDark ? 0.13 : 0.09);
  }

  /// 점선 색상 (라이트 55% / 다크 65%)
  static Color dashColor(int colorIdx, bool isDark) {
    final base = mainColors[colorIdx % mainColors.length];
    return base.withValues(alpha: isDark ? 0.65 : 0.55);
  }

  /// 합계 텍스트 색상 (다크 모드에서는 약간 밝게)
  static Color sumTextColor(int colorIdx, bool isDark) {
    final base = mainColors[colorIdx % mainColors.length];
    return isDark ? _lighten(base, 0.15) : base;
  }

  /// HSL 기반 밝기 조정
  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// 인접 케이지 색상 회피 — 그리디 색칠 알고리즘
  /// 각 케이지에 8색 중 하나를 할당하되, 인접한 케이지는 다른 색을 가지도록.
  /// 모두 충돌하는 극단적인 경우(8개 이상 인접)에는 0번 색을 폴백으로 사용.
  static List<int> assignColors(List<Cage> cages) {
    final colors = List<int>.filled(cages.length, -1);

    try {
      // 1) 인접 그래프 사전 계산 (성능 최적화)
      final adjacency = List.generate(cages.length, (_) => <int>{});
      for (int i = 0; i < cages.length; i++) {
        for (int j = i + 1; j < cages.length; j++) {
          if (_areAdjacent(cages[i], cages[j])) {
            adjacency[i].add(j);
            adjacency[j].add(i);
          }
        }
      }

      // 2) 그리디 색 할당
      for (int i = 0; i < cages.length; i++) {
        final usedColors = <int>{};
        for (final j in adjacency[i]) {
          if (colors[j] != -1) usedColors.add(colors[j]);
        }
        // 8색 중 사용되지 않은 첫 번째 색 선택
        for (int c = 0; c < mainColors.length; c++) {
          if (!usedColors.contains(c)) {
            colors[i] = c;
            break;
          }
        }
        // 모두 충돌하는 극단적 케이스 폴백
        if (colors[i] == -1) colors[i] = 0;
      }
    } catch (_) {
      // 예상치 못한 에러 시 모두 0번으로 폴백 (시각만 영향)
      for (int i = 0; i < colors.length; i++) {
        if (colors[i] == -1) colors[i] = 0;
      }
    }

    return colors;
  }

  /// 두 케이지가 인접한지 (셀이 상하좌우로 맞닿음)
  static bool _areAdjacent(Cage a, Cage b) {
    for (final (ar, ac) in a.cells) {
      for (final (br, bc) in b.cells) {
        if ((ar - br).abs() + (ac - bc).abs() == 1) return true;
      }
    }
    return false;
  }
}
