import 'package:flutter/material.dart';

abstract final class KPColors {
  static const background = Color(0xFFFBFAFF);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF1D2340);
  static const muted = Color(0xFF69718A);
  static const indigo = Color(0xFF3F35B5);
  static const blue = Color(0xFF3978F6);
  static const violet = Color(0xFF7A4DFF);
  static const sky = Color(0xFF65B8FF);
  static const mint = Color(0xFF58D3B7);
  static const gold = Color(0xFFFFC648);
  static const coral = Color(0xFFFF7B61);
  static const green = Color(0xFF59C878);
  static const border = Color(0xFFE8E7F2);
  static const paleViolet = Color(0xFFF1EDFF);
}

abstract final class KPSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class KPRadius {
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 34.0;
}

abstract final class KPShadow {
  static const soft = [
    BoxShadow(color: Color(0x163F35B5), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const button = [
    BoxShadow(color: Color(0x254B54F7), blurRadius: 20, offset: Offset(0, 9)),
  ];
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: KPColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: KPColors.indigo),
    fontFamilyFallback: const ['Pretendard', 'SUIT', 'Noto Sans KR', 'sans-serif'],
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: KPColors.indigo, letterSpacing: -0.8),
      headlineSmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: KPColors.text, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: KPColors.text),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: KPColors.text),
      bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: KPColors.text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.55, color: KPColors.muted),
    ),
  );
}
