import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 설정 서비스 (SharedPreferences 기반)
class SettingsService {
  static const _keyThemeMode = 'theme_mode';
  static const _keyShowMistakes = 'show_mistakes';
  static const _keyShowTimer = 'show_timer';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyFontScale = 'font_scale';
  static const _keyFirstLaunch = 'first_launch';
  static const _keyLanguage = 'language';
  static const _keyCustomTheme = 'custom_theme';
  static const _keyLastDifficulty = 'last_difficulty';
  static const _keyAutoComplete = 'auto_complete';
  static const _keyLastGameRoute = 'last_game_route';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // 테마 모드
  ThemeMode get themeMode {
    final value = _prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  // 실수 표시
  bool get showMistakes => _prefs.getBool(_keyShowMistakes) ?? true;
  Future<void> setShowMistakes(bool value) async {
    await _prefs.setBool(_keyShowMistakes, value);
  }

  // 타이머 표시
  bool get showTimer => _prefs.getBool(_keyShowTimer) ?? true;
  Future<void> setShowTimer(bool value) async {
    await _prefs.setBool(_keyShowTimer, value);
  }

  // 사운드
  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_keySoundEnabled, value);
  }

  // 진동
  bool get vibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  Future<void> setVibrationEnabled(bool value) async {
    await _prefs.setBool(_keyVibrationEnabled, value);
  }

  // 글자 크기 배율 (1.0, 1.3, 1.6)
  double get fontScale => _prefs.getDouble(_keyFontScale) ?? 1.0;
  Future<void> setFontScale(double value) async {
    await _prefs.setDouble(_keyFontScale, value);
  }

  // 언어 설정 (ko, en, ja, zh)
  String get language => _prefs.getString(_keyLanguage) ?? 'ko';
  Future<void> setLanguage(String langCode) async {
    await _prefs.setString(_keyLanguage, langCode);
  }

  // 마지막 플레이 난이도 (빠른 게임 가중치용)
  String get lastDifficulty => _prefs.getString(_keyLastDifficulty) ?? 'easy';
  Future<void> setLastDifficulty(String diff) async {
    await _prefs.setString(_keyLastDifficulty, diff);
  }

  // 자동 완성 (빈 칸이 적고 모두 확정일 때 자동 채움)
  bool get autoComplete => _prefs.getBool(_keyAutoComplete) ?? true;
  Future<void> setAutoComplete(bool value) async {
    await _prefs.setBool(_keyAutoComplete, value);
  }

  // 커스텀 테마
  String get customTheme => _prefs.getString(_keyCustomTheme) ?? 'light';
  Future<void> setCustomTheme(String themeKey) async {
    await _prefs.setString(_keyCustomTheme, themeKey);
  }

  // 첫 실행 여부
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;
  Future<void> setFirstLaunchDone() async {
    await _prefs.setBool(_keyFirstLaunch, false);
  }

  // 마지막 게임 경로 (앱 재시작 시 자동 복귀용)
  String? get lastGameRoute => _prefs.getString(_keyLastGameRoute);
  Future<void> setLastGameRoute(String route) async {
    await _prefs.setString(_keyLastGameRoute, route);
  }
  Future<void> clearLastGameRoute() async {
    await _prefs.remove(_keyLastGameRoute);
  }
}
