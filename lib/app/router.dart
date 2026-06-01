import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/storage_providers.dart';
import '../features/hub/screens/game_hub_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/game/screens/game_screen.dart';
import '../features/home/screens/mode_select_screen.dart';
import '../features/home/screens/difficulty_select_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/statistics/screens/statistics_screen.dart';
import '../features/badges/screens/badges_screen.dart';
import '../features/daily_puzzle/screens/daily_puzzle_screen.dart';
import '../features/daily_puzzle/screens/daily_calendar_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/tutorial/screens/tutorial_screen.dart';
import '../games/binairo/screens/binairo_home_screen.dart';
import '../games/binairo/screens/binairo_game_screen.dart';

/// 라우트 경로 상수
class AppRoutes {
  static const hub = '/hub';
  static const home = '/';
  static const onboarding = '/onboarding';
  static const modeSelect = '/mode-select';
  static const difficultySelect = '/difficulty-select';
  static const game = '/game';
  static const statistics = '/statistics';
  static const badges = '/badges';
  static const dailyPuzzle = '/daily-puzzle';
  static const dailyCalendar = '/daily-calendar';
  static const settings = '/settings';
  static const tutorial = '/tutorial';
  static const binairo = '/binairo';
  static const binairoGame = '/binairo/game';
}

/// 초기 위치 오버라이드 (테스트용)
final initialLocationProvider = Provider<String?>((ref) => null);

/// go_router Provider
final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.read(settingsProvider);
  final locationOverride = ref.read(initialLocationProvider);

  // 마지막 게임 경로로 자동 복귀 (온보딩 완료 후에만)
  final lastGameRoute = settings.lastGameRoute;
  final effectiveInitial = locationOverride
      ?? ((!settings.isFirstLaunch && lastGameRoute != null) ? lastGameRoute : AppRoutes.hub);

  return GoRouter(
    initialLocation: effectiveInitial,
    redirect: (context, state) {
      // 첫 실행 시 온보딩으로 리다이렉트
      if (settings.isFirstLaunch && state.matchedLocation == AppRoutes.hub) {
        return AppRoutes.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.hub,
        builder: (context, state) => const GameHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.modeSelect,
        builder: (context, state) => const ModeSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.difficultySelect,
        builder: (context, state) {
          final mode = state.extra as String? ?? 'classic';
          return DifficultySelectScreen(mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (context, state) => StatisticsScreen(initialTab: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.badges,
        builder: (context, state) => BadgesScreen(initialTab: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.dailyPuzzle,
        builder: (context, state) => const DailyPuzzleScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyCalendar,
        builder: (context, state) => const DailyCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (context, state) => const TutorialScreen(),
      ),
      // 비나이로 홈
      GoRoute(
        path: AppRoutes.binairo,
        builder: (context, state) => const BinairoHomeScreen(),
      ),
      // 비나이로 게임 플레이
      GoRoute(
        path: AppRoutes.binairoGame,
        builder: (context, state) => const BinairoGameScreen(),
      ),
    ],
  );
});
