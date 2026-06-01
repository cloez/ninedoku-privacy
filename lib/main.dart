import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'core/storage/storage_providers.dart';
import 'core/settings/settings_service.dart';
import 'core/sudoku/puzzle_cache_service.dart';
import 'shared/l10n/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // 저장된 언어 설정 복원
  final savedLang = SettingsService(prefs).language;
  AppStrings.setLanguage(AppLanguage.fromCode(savedLang));

  // 퍼즐 캐시 백그라운드 보충 (비동기, 앱 시작 차단 없음)
  PuzzleCacheService(prefs).refillAll();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NinedokuApp(),
    ),
  );
}

/// Ninedoku 앱 루트
class NinedokuApp extends ConsumerWidget {
  const NinedokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    // 글자 크기 배율 적용
    final fontScale = settings.fontScale;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(fontScale),
      ),
      child: MaterialApp.router(
        title: 'Ninedoku',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        routerConfig: router,
      ),
    );
  }
}
