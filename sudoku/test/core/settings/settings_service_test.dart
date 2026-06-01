import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/core/settings/settings_service.dart';

/// 설정 서비스 테스트
void main() {
  late SharedPreferences prefs;
  late SettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
  });

  group('테마 설정', () {
    test('기본값은 system', () {
      expect(settings.themeMode, ThemeMode.system);
    });

    test('라이트 테마 설정/조회', () async {
      await settings.setThemeMode(ThemeMode.light);
      expect(settings.themeMode, ThemeMode.light);
    });

    test('다크 테마 설정/조회', () async {
      await settings.setThemeMode(ThemeMode.dark);
      expect(settings.themeMode, ThemeMode.dark);
    });
  });

  group('게임 설정', () {
    test('실수 표시 기본값 true', () {
      expect(settings.showMistakes, true);
    });

    test('실수 표시 토글', () async {
      await settings.setShowMistakes(false);
      expect(settings.showMistakes, false);
    });

    test('타이머 표시 기본값 true', () {
      expect(settings.showTimer, true);
    });

    test('사운드 기본값 true', () {
      expect(settings.soundEnabled, true);
    });

    test('진동 기본값 true', () {
      expect(settings.vibrationEnabled, true);
    });
  });

  group('글자 크기', () {
    test('기본값 1.0', () {
      expect(settings.fontScale, 1.0);
    });

    test('1.3x 설정', () async {
      await settings.setFontScale(1.3);
      expect(settings.fontScale, 1.3);
    });

    test('1.6x 설정', () async {
      await settings.setFontScale(1.6);
      expect(settings.fontScale, 1.6);
    });
  });

  group('첫 실행', () {
    test('최초 실행 여부 true', () {
      expect(settings.isFirstLaunch, true);
    });

    test('첫 실행 완료 후 false', () async {
      await settings.setFirstLaunchDone();
      expect(settings.isFirstLaunch, false);
    });
  });
}
