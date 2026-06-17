import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/theme.dart';
import 'app/router.dart';
import 'core/storage/storage_providers.dart';
import 'core/settings/settings_service.dart';
import 'core/sudoku/puzzle_cache_service.dart';
import 'shared/l10n/app_strings.dart';
import 'shared/services/sound_manager.dart';
import 'shared/utils/motion_helper.dart' as motion_helper;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // 저장된 언어 설정 복원
  final settingsService = SettingsService(prefs);
  AppStrings.setLanguage(AppLanguage.fromCode(settingsService.language));

  // 사운드 매니저: 사용자 설정 반영 + 백그라운드 preload (silent fail)
  SoundManager().setEnabled(settingsService.soundEnabled);
  unawaited(SoundManager().preload());

  // 모션 감소 플래그를 글로벌에 반영 (공통 위젯이 prefs 없이도 동작하도록)
  motion_helper.setReduceEffects(settingsService.reduceEffects);

  // 퍼즐 캐시 백그라운드 보충 (비동기, 앱 시작 차단 없음)
  PuzzleCacheService(prefs).refillAll();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const KPuzzlesApp(),
    ),
  );
}

/// K-Puzzles 앱 루트
class KPuzzlesApp extends ConsumerWidget {
  const KPuzzlesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    // 글자 크기 배율 적용
    final fontScale = settings.fontScale;

    // 언어가 바뀌면 MaterialApp을 통째로 새 key로 재구성하여
    // 화면에 캐시된 옛 언어 Text가 남아있지 않게 한다.
    // (AppStrings는 static 캐시라 watch가 안 되므로 ValueKey로 강제 rebuild)
    final language = settings.language;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(fontScale),
      ),
      child: MaterialApp.router(
        key: ValueKey('app-$language'),
        // 앱 타이틀 (다국어) — OS task switcher / 최근 앱에서 표시
        title: AppStrings.get('appTitle'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        routerConfig: router,
      ),
    );
  }
}
