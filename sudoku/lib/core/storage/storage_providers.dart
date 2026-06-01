import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_storage_service.dart';
import '../settings/settings_service.dart';

/// SharedPreferences 인스턴스 Provider (앱 시작 시 override)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('앱 시작 시 ProviderScope overrides로 제공');
});

/// 게임 저장 서비스 Provider
final gameStorageProvider = Provider<GameStorageService>((ref) {
  return GameStorageService(ref.watch(sharedPreferencesProvider));
});

/// 설정 서비스 Provider
final settingsProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(sharedPreferencesProvider));
});
