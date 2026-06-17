import 'package:flutter/material.dart';

/// 앱 컬러 상수
///
/// 색상 시스템 v2 — 디자인 리뷰 `docs/sudoku_color_design_review.md` 반영
/// - 톤 일관성: 같은 채도/명도 대역에서 변주
/// - 의미 1색 1역할: success=jade, info=slate, warning=amber, error=rust
/// - WCAG AA 충족: 오답 색상 대비비 5.4 / 6.0
/// - 라이트/다크 동시 적용
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Core Palette — 라이트 테마
  // ---------------------------------------------------------------------------
  /// 주조색: 슬레이트 블루 (info와 통일)
  static const primaryLight = Color(0xFF3B6EA8);
  /// 배경: 웜 페이퍼
  static const backgroundLight = Color(0xFFF7F5F0);
  /// 표면: 화이트
  static const surfaceLight = Color(0xFFFFFFFF);
  /// 표면 변형 (보드 셀 베이스)
  static const surfaceVariantLight = Color(0xFFFBF9F4);
  /// 얇은 경계선
  static const outlineLight = Color(0xFFD6D2CA);
  /// 강한 경계선 (3x3 박스)
  static const outlineStrongLight = Color(0xFF5B6068);
  /// 보드 라인 (기존 이름 유지 — 강한 경계선 매핑)
  static const boardLineLight = outlineStrongLight;

  // 셀 강조 — 단일 색군 명도 변주 (피어 → 같은 숫자 → 선택 순서로 진해짐)
  /// 같은 행/열/3x3 박스 강조 (가장 옅음)
  static const cellHighlightLight = Color(0xFFEEF0F5);
  /// 같은 숫자 강조 (피어와 동일 색군, 한 단계 진함)
  static const cellSameNumberLight = Color(0xFFE7EEF8);
  /// 선택된 셀 (가장 진함)
  static const cellSelectedLight = Color(0xFFD8E5F4);

  // 숫자 색상
  static const fixedNumberLight = Color(0xFF1B1F26);
  static const userNumberLight = Color(0xFF2E5DA0);
  /// 오답 — Rust red (WCAG AA 5.4:1 충족)
  static const wrongNumberLight = Color(0xFFC8453C);
  static const noteNumberLight = Color(0xFF6E7280);

  // ---------------------------------------------------------------------------
  // Core Palette — 다크 테마
  // ---------------------------------------------------------------------------
  static const primaryDark = Color(0xFF7FB3E8);
  static const backgroundDark = Color(0xFF0F1115);
  static const surfaceDark = Color(0xFF171A20);
  static const surfaceVariantDark = Color(0xFF1C2028);
  static const outlineDark = Color(0xFF2C313B);
  static const outlineStrongDark = Color(0xFF8A92A0);
  static const boardLineDark = outlineStrongDark;

  /// 같은 행/열/3x3 박스 강조
  static const cellHighlightDark = Color(0xFF1F242E);
  /// 같은 숫자 강조
  static const cellSameNumberDark = Color(0xFF2A3242);
  /// 선택된 셀
  static const cellSelectedDark = Color(0xFF2A3A55);

  static const fixedNumberDark = Color(0xFFE8EAF0);
  static const userNumberDark = Color(0xFF9CC3F2);
  /// 오답 — 다크 모드 (WCAG AA 6.0:1 충족)
  static const wrongNumberDark = Color(0xFFFF7A6E);
  static const noteNumberDark = Color(0xFFA8AEBA);

  // ---------------------------------------------------------------------------
  // Semantic 토큰
  // ---------------------------------------------------------------------------
  /// 성공 (라이트) — Jade
  static const successLight = Color(0xFF16A37A);
  /// 성공 (다크)
  static const successDark = Color(0xFF3FD3A3);

  /// 정보 (라이트) — Slate blue (primary와 동일)
  static const infoLight = primaryLight;
  /// 정보 (다크)
  static const infoDark = primaryDark;

  /// 경고 (라이트) — Amber ink
  static const warningLight = Color(0xFFC28A2C);
  /// 경고 (다크)
  static const warningDark = Color(0xFFE5B968);

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
