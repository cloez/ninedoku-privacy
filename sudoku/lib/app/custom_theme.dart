import 'package:flutter/material.dart';
import '../shared/constants/app_colors.dart';

/// 커스텀 테마 종류
enum CustomThemeType {
  light,
  dark,
  cafe,
  paper,
  focus,
  highContrast;

  /// 기본 제공 테마인지 (해금 불필요)
  bool get isFree => this == light || this == dark || this == highContrast;
}

/// 테마 해금 조건
class ThemeUnlockCondition {
  /// 해금에 필요한 게임 완료 횟수
  final int? gamesCompleted;

  /// 해금에 필요한 특정 난이도 완료 횟수 (난이도 이름, 횟수)
  final (String, int)? difficultyClears;

  const ThemeUnlockCondition({
    this.gamesCompleted,
    this.difficultyClears,
  });

  /// 해금 조건에 도달했는지
  bool isMet({required int totalGames, required Map<String, int> difficultyGameCounts}) {
    if (gamesCompleted != null && totalGames < gamesCompleted!) return false;
    if (difficultyClears != null) {
      final (diff, count) = difficultyClears!;
      if ((difficultyGameCounts[diff] ?? 0) < count) return false;
    }
    return true;
  }
}

/// 커스텀 테마 데이터 확장
class CustomThemeData {
  static const Map<CustomThemeType, ThemeUnlockCondition> unlockConditions = {
    CustomThemeType.cafe: ThemeUnlockCondition(gamesCompleted: 20),
    CustomThemeType.paper: ThemeUnlockCondition(gamesCompleted: 30),
    CustomThemeType.focus: ThemeUnlockCondition(difficultyClears: ('hard', 5)),
  };

  static ThemeData getTheme(CustomThemeType type) {
    switch (type) {
      case CustomThemeType.light:
        return _lightTheme;
      case CustomThemeType.dark:
        return _darkTheme;
      case CustomThemeType.cafe:
        return _cafeTheme;
      case CustomThemeType.paper:
        return _paperTheme;
      case CustomThemeType.focus:
        return _focusTheme;
      case CustomThemeType.highContrast:
        return _highContrastTheme;
    }
  }

  /// 테마별 보드 색상
  static AppColorSet getColors(CustomThemeType type) {
    switch (type) {
      case CustomThemeType.light:
        return AppColorSet.light;
      case CustomThemeType.dark:
        return AppColorSet.dark;
      case CustomThemeType.cafe:
        return AppColorSet.cafe;
      case CustomThemeType.paper:
        return AppColorSet.paper;
      case CustomThemeType.focus:
        return AppColorSet.focus;
      case CustomThemeType.highContrast:
        return AppColorSet.highContrast;
    }
  }

  static ThemeData get _lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static ThemeData get _darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static ThemeData get _cafeTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF6D4C41),
    scaffoldBackgroundColor: const Color(0xFFFFF8E1),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static ThemeData get _paperTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF5D4037),
    scaffoldBackgroundColor: const Color(0xFFF5F0E8),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static ThemeData get _focusTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF1A237E),
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static ThemeData get _highContrastTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// 테마별 보드 색상 세트
class AppColorSet {
  final Color primary;
  final Color background;
  final Color boardLine;
  final Color cellSelected;
  final Color cellHighlight;
  final Color cellSameNumber;
  final Color fixedNumber;
  final Color userNumber;
  final Color wrongNumber;
  final Color noteNumber;

  const AppColorSet({
    required this.primary,
    required this.background,
    required this.boardLine,
    required this.cellSelected,
    required this.cellHighlight,
    required this.cellSameNumber,
    required this.fixedNumber,
    required this.userNumber,
    required this.wrongNumber,
    required this.noteNumber,
  });

  static const light = AppColorSet(
    primary: AppColors.primaryLight,
    background: AppColors.backgroundLight,
    boardLine: AppColors.boardLineLight,
    cellSelected: AppColors.cellSelectedLight,
    cellHighlight: AppColors.cellHighlightLight,
    cellSameNumber: AppColors.cellSameNumberLight,
    fixedNumber: AppColors.fixedNumberLight,
    userNumber: AppColors.userNumberLight,
    wrongNumber: AppColors.wrongNumberLight,
    noteNumber: AppColors.noteNumberLight,
  );

  static const dark = AppColorSet(
    primary: AppColors.primaryDark,
    background: AppColors.backgroundDark,
    boardLine: AppColors.boardLineDark,
    cellSelected: AppColors.cellSelectedDark,
    cellHighlight: AppColors.cellHighlightDark,
    cellSameNumber: AppColors.cellSameNumberDark,
    fixedNumber: AppColors.fixedNumberDark,
    userNumber: AppColors.userNumberDark,
    wrongNumber: AppColors.wrongNumberDark,
    noteNumber: AppColors.noteNumberDark,
  );

  static const cafe = AppColorSet(
    primary: Color(0xFF6D4C41),
    background: Color(0xFFFFF8E1),
    boardLine: Color(0xFF4E342E),
    cellSelected: Color(0xFFD7CCC8),
    cellHighlight: Color(0xFFEFEBE9),
    cellSameNumber: Color(0xFFC8E6C9),
    fixedNumber: Color(0xFF3E2723),
    userNumber: Color(0xFF6D4C41),
    wrongNumber: Color(0xFFD32F2F),
    noteNumber: Color(0xFF8D6E63),
  );

  static const paper = AppColorSet(
    primary: Color(0xFF5D4037),
    background: Color(0xFFF5F0E8),
    boardLine: Color(0xFF5D4037),
    cellSelected: Color(0xFFE0D8CC),
    cellHighlight: Color(0xFFEDE7DF),
    cellSameNumber: Color(0xFFD5E8D4),
    fixedNumber: Color(0xFF3E2723),
    userNumber: Color(0xFF4E342E),
    wrongNumber: Color(0xFFC62828),
    noteNumber: Color(0xFF795548),
  );

  static const focus = AppColorSet(
    primary: Color(0xFF5C6BC0),
    background: Color(0xFF0D1B2A),
    boardLine: Color(0xFF7986CB),
    cellSelected: Color(0xFF1A237E),
    cellHighlight: Color(0xFF283593),
    cellSameNumber: Color(0xFF1B5E20),
    fixedNumber: Color(0xFFE8EAF6),
    userNumber: Color(0xFF9FA8DA),
    wrongNumber: Color(0xFFEF5350),
    noteNumber: Color(0xFF7986CB),
  );

  static const highContrast = AppColorSet(
    primary: Colors.black,
    background: Colors.white,
    boardLine: Colors.black,
    cellSelected: Color(0xFFFFFF00),
    cellHighlight: Color(0xFFE0E0E0),
    cellSameNumber: Color(0xFFCCFFCC),
    fixedNumber: Colors.black,
    userNumber: Color(0xFF0000CC),
    wrongNumber: Colors.red,
    noteNumber: Color(0xFF444444),
  );
}
