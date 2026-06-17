import 'package:flutter/material.dart';

/// 앱 컬러 상수
///
/// 색상 시스템 v3 — Premium Casual 디자인 반영
/// - 브랜드 인디고/바이올렛 중심 캐주얼 팔레트
/// - 부드러운 파스텔 그라데이션
/// - WCAG AA 충족 유지
/// - 라이트/다크 동시 적용
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // 브랜드 컬러 (디자인 샘플 기반)
  // ---------------------------------------------------------------------------
  /// 브랜드 인디고 — 앱의 핵심 아이덴티티
  static const brandIndigo = Color(0xFF3F35B5);
  /// 프라이머리 블루
  static const brandBlue = Color(0xFF3978F6);
  /// 바이올렛
  static const brandViolet = Color(0xFF7A4DFF);
  /// 스카이 블루
  static const brandSkyBlue = Color(0xFF5EB9FF);
  /// 민트
  static const brandMint = Color(0xFF55D6BE);
  /// 골드
  static const brandGold = Color(0xFFFFC542);
  /// 코랄
  static const brandCoral = Color(0xFFFF7A59);

  // ---------------------------------------------------------------------------
  // Core Palette — 라이트 테마
  // ---------------------------------------------------------------------------
  /// 주조색: 브랜드 인디고
  static const primaryLight = Color(0xFF3F35B5);
  /// 배경: 소프트 라벤더
  static const backgroundLight = Color(0xFFFBFAFF);
  /// 표면: 화이트
  static const surfaceLight = Color(0xFFFFFFFF);
  /// 표면 변형 (보드 셀 베이스)
  static const surfaceVariantLight = Color(0xFFF8F7FC);
  /// 얇은 경계선
  static const outlineLight = Color(0xFFE6E7F0);
  /// 강한 경계선 (3x3 박스)
  static const outlineStrongLight = Color(0xFF4A4870);
  /// 보드 라인
  static const boardLineLight = outlineStrongLight;

  // 셀 강조 — 인디고/바이올렛 색군 명도 변주
  /// 같은 행/열/3x3 박스 강조 (가장 옅음)
  static const cellHighlightLight = Color(0xFFEEEDF8);
  /// 같은 숫자 강조
  static const cellSameNumberLight = Color(0xFFE2DEFF);
  /// 선택된 셀 (가장 진함)
  static const cellSelectedLight = Color(0xFFD2CCFF);

  // 숫자 색상
  static const fixedNumberLight = Color(0xFF1D2340);
  static const userNumberLight = Color(0xFF3F35B5);
  /// 오답 — 코랄 레드 (WCAG AA 5.4:1 충족)
  static const wrongNumberLight = Color(0xFFC8453C);
  static const noteNumberLight = Color(0xFF68708A);

  // ---------------------------------------------------------------------------
  // Core Palette — 다크 테마
  // ---------------------------------------------------------------------------
  static const primaryDark = Color(0xFFA99AFF);
  static const backgroundDark = Color(0xFF0F0E1A);
  static const surfaceDark = Color(0xFF17162A);
  static const surfaceVariantDark = Color(0xFF1E1D32);
  static const outlineDark = Color(0xFF2E2D48);
  static const outlineStrongDark = Color(0xFF8A88B0);
  static const boardLineDark = outlineStrongDark;

  /// 같은 행/열/3x3 박스 강조
  static const cellHighlightDark = Color(0xFF1F1E38);
  /// 같은 숫자 강조
  static const cellSameNumberDark = Color(0xFF2A2850);
  /// 선택된 셀
  static const cellSelectedDark = Color(0xFF353268);

  static const fixedNumberDark = Color(0xFFE8EAF0);
  static const userNumberDark = Color(0xFFBDB2FF);
  /// 오답 — 다크 모드 (WCAG AA 6.0:1 충족)
  static const wrongNumberDark = Color(0xFFFF7A6E);
  static const noteNumberDark = Color(0xFFA8AEBA);

  // ---------------------------------------------------------------------------
  // Semantic 토큰
  // ---------------------------------------------------------------------------
  /// 성공 (라이트) — Jade
  static const successLight = Color(0xFF57C77A);
  /// 성공 (다크)
  static const successDark = Color(0xFF6EDB90);

  /// 정보 (라이트) — 브랜드 인디고
  static const infoLight = primaryLight;
  /// 정보 (다크)
  static const infoDark = primaryDark;

  /// 경고 (라이트) — 골드
  static const warningLight = Color(0xFFF2A83B);
  /// 경고 (다크)
  static const warningDark = Color(0xFFFFC542);

  /// 오류 (라이트) — Rust red
  static const errorLight = wrongNumberLight;
  /// 오류 (다크)
  static const errorDark = wrongNumberDark;

  // ---------------------------------------------------------------------------
  // Jade Bloom — 라인 완성 효과 (옵션 B)
  // 의미: 성공/완성. 동일 채도 대역(60~70%)에서 명도만 이동
  // ---------------------------------------------------------------------------
  /// 라이트 jade — 민트 미스트 (페이드인 시작)
  static const jadeBloomLight = Color(0xFFBDE5D2);
  /// 미드 jade — 코어 제이드 (피크)
  static const jadeBloomMid = Color(0xFF3FBF8E);
  /// 딥 jade — 에메랄드 (페이드아웃 끝)
  static const jadeBloomDark = Color(0xFF0F7A57);

  /// 다크 모드용 jade 시퀀스 (전체 명도 +12)
  static const jadeBloomLightDarkMode = Color(0xFF9EE0C2);
  static const jadeBloomMidDarkMode = Color(0xFF4ED49C);
  static const jadeBloomDarkDarkMode = Color(0xFF1A9670);

  // ---------------------------------------------------------------------------
  // 추임새 색상
  // ---------------------------------------------------------------------------
  /// Good — 성공 jade
  static const encouragementGood = successLight;
  /// Excellent — 정보 slate
  static const encouragementExcellent = infoLight;
  /// Perfect — 디톤된 골드 (순금색 #FFD700 회피)
  static const encouragementPerfect = Color(0xFFC9963A);

  // ---------------------------------------------------------------------------
  // KP 디자인 시스템 컬러 (디자인 레퍼런스 기반)
  // ---------------------------------------------------------------------------
  static const kpText = Color(0xFF1D2340);
  static const kpMuted = Color(0xFF69718A);
  static const kpBorder = Color(0xFFE8E7F2);
  static const kpPaleViolet = Color(0xFFF1EDFF);
  static const kpGreen = Color(0xFF59C878);

  // ---------------------------------------------------------------------------
  // 허브/게임 메인 그라데이션
  // ---------------------------------------------------------------------------
  /// 허브 배경 그라데이션 (라이트) — KP 디자인
  static const hubGradientLight = [
    Color(0xFFF7F4FF),
    Color(0xFFFBFAFF),
    Color(0xFFFFFCF7),
  ];
  /// 허브 배경 그라데이션 (다크)
  static const hubGradientDark = [
    Color(0xFF1A1840),
    Color(0xFF151330),
    Color(0xFF0F0E1A),
  ];

  /// 진행률 카드 그라데이션 — KP 디자인
  static const progressGradientLight = [
    Color(0xFF5D52EF),
    Color(0xFF4A7AF8),
    Color(0xFF8C65F5),
  ];
  static const progressGradientDark = [
    Color(0xFF2A2470),
    Color(0xFF3055A8),
    Color(0xFF5535B5),
  ];

  // ---------------------------------------------------------------------------
  // 게임별 테마 컬러 (허브 카드 + 게임 메인 화면)
  // ---------------------------------------------------------------------------
  static const Map<String, Color> gameThemeColors = {
    'sudoku':       Color(0xFF3C8AF7),
    'binairo':      Color(0xFF45CDAE),
    'minesweeper':  Color(0xFF7557D9),
    'yinyang':      Color(0xFF8A4DFF),
    'nonogram':     Color(0xFFF49A3F),
    'killerSudoku': Color(0xFF4BA9F5),
    'starBattle':   Color(0xFFFFBE2E),
    'lightUp':      Color(0xFF17B8D6),
    'futoshiki':    Color(0xFF20A79A),
    'tents':        Color(0xFFF27A51),
    'jigsawSudoku': Color(0xFF60BE50),
    'skyscrapers':  Color(0xFF315E9A),
    'kakuro':       Color(0xFFE65072),
  };

  /// 게임별 파스텔 배경색 (카드 배경용) — 레퍼런스 기준 고채도
  static const Map<String, Color> gameCardBgColors = {
    'sudoku':       Color(0xFFC8D9FF),
    'binairo':      Color(0xFFC2EDE2),
    'minesweeper':  Color(0xFFDFCFFF),
    'yinyang':      Color(0xFFF0D5F2),
    'nonogram':     Color(0xFFFFE4C4),
    'killerSudoku': Color(0xFFCCE2FF),
    'starBattle':   Color(0xFFFFF0B8),
    'lightUp':      Color(0xFFCAE5F5),
    'futoshiki':    Color(0xFFC5EDE2),
    'tents':        Color(0xFFFFD5C5),
    'jigsawSudoku': Color(0xFFCCEEC8),
    'skyscrapers':  Color(0xFFC5DDF5),
    'kakuro':       Color(0xFFFFCDDB),
  };

  /// 게임별 보조색 (그라데이션 히어로 카드용) — KP 디자인 기반
  static const Map<String, Color> gameSecondaryColors = {
    'sudoku':       Color(0xFF6B54EE),
    'binairo':      Color(0xFF53627E),
    'minesweeper':  Color(0xFFFF7A59),
    'yinyang':      Color(0xFFE265C4),
    'nonogram':     Color(0xFF385276),
    'killerSudoku': Color(0xFF3F35B5),
    'starBattle':   Color(0xFF7251D6),
    'lightUp':      Color(0xFFFFCC46),
    'futoshiki':    Color(0xFFC79A31),
    'tents':        Color(0xFF3D9B69),
    'jigsawSudoku': Color(0xFF3978F6),
    'skyscrapers':  Color(0xFF5EB9FF),
    'kakuro':       Color(0xFF7350E8),
  };
}

/// 난이도별 색상 토큰 — 채도 -15% 정돈
/// 다크모드에서 흰 텍스트와의 대비 확보를 위해 명도 상향
class DifficultyTokens {
  DifficultyTokens._();

  /// 입문 (Beginner) — 초록 계열
  static Color beginnerColor(bool isDark) => isDark
      ? const Color(0xFF66BB6A)
      : const Color(0xFF4CAF50);

  /// 쉬움 (Easy) — 라이트 그린
  static Color easyColor(bool isDark) => isDark
      ? const Color(0xFF9CCC65)
      : const Color(0xFF8BC34A);

  /// 보통 (Medium) — 오렌지
  static Color mediumColor(bool isDark) => isDark
      ? const Color(0xFFFFB74D)
      : const Color(0xFFFF9800);

  /// 어려움 (Hard) — 딥 오렌지
  static Color hardColor(bool isDark) => isDark
      ? const Color(0xFFFF8A65)
      : const Color(0xFFFF5722);

  /// 전문가 (Expert) — Rust red (오답색과 통일)
  static Color expertColor(bool isDark) => isDark
      ? AppColors.errorDark
      : AppColors.errorLight;

  /// 마스터 (Master) — 퍼플
  static Color masterColor(bool isDark) => isDark
      ? const Color(0xFFCE93D8)
      : const Color(0xFF9C27B0);
}
