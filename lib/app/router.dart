import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/hub/screens/game_hub_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/game/screens/game_screen.dart';
import '../features/home/screens/mode_select_screen.dart';
import '../features/home/screens/difficulty_select_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/statistics/screens/statistics_screen.dart';
import '../features/badges/screens/badges_screen.dart';
import '../features/daily_puzzle/screens/daily_puzzle_screen.dart';
import '../features/daily_puzzle/screens/daily_calendar_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/tutorial/screens/tutorial_screen.dart';
import '../features/tutorial/screens/tutorial_screen_v2.dart';
import '../games/binairo/screens/binairo_home_screen.dart';
import '../games/binairo/screens/binairo_game_screen.dart';
import '../games/minesweeper/screens/minesweeper_home_screen.dart';
import '../games/minesweeper/screens/minesweeper_game_screen.dart';
import '../games/yin_yang/screens/yin_yang_home_screen.dart';
import '../games/yin_yang/screens/yin_yang_game_screen.dart';
import '../games/nonograms/screens/nonogram_home_screen.dart';
import '../games/nonograms/screens/nonogram_game_screen.dart';
import '../games/killer_sudoku/screens/killer_sudoku_home_screen.dart';
import '../games/killer_sudoku/screens/killer_sudoku_game_screen.dart';
import '../games/star_battle/screens/star_battle_home_screen.dart';
import '../games/star_battle/screens/star_battle_game_screen.dart';
import '../games/light_up/screens/light_up_home_screen.dart';
import '../games/light_up/screens/light_up_game_screen.dart';
import '../games/futoshiki/screens/futoshiki_home_screen.dart';
import '../games/futoshiki/screens/futoshiki_game_screen.dart';
import '../games/tents/screens/tents_home_screen.dart';
import '../games/tents/screens/tents_game_screen.dart';
import '../games/jigsaw_sudoku/screens/jigsaw_sudoku_home_screen.dart';
import '../games/jigsaw_sudoku/screens/jigsaw_sudoku_game_screen.dart';
import '../games/skyscrapers/screens/skyscrapers_home_screen.dart';
import '../games/skyscrapers/screens/skyscrapers_game_screen.dart';
import '../games/kakuro/screens/kakuro_home_screen.dart';
import '../games/kakuro/screens/kakuro_game_screen.dart';

/// 라우트 경로 상수
class AppRoutes {
  static const splash = '/splash';
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
  static const minesweeper = '/minesweeper';
  static const minesweeperGame = '/minesweeper/game';
  static const yinYang = '/yin-yang';
  static const yinYangGame = '/yin-yang/game';
  static const nonograms = '/nonograms';
  static const nonogramsGame = '/nonograms/game';
  static const killerSudoku = '/killer-sudoku';
  static const killerSudokuGame = '/killer-sudoku/game';
  static const starBattle = '/star-battle';
  static const starBattleGame = '/star-battle/game';
  static const lightUp = '/light-up';
  static const lightUpGame = '/light-up/game';
  static const futoshiki = '/futoshiki';
  static const futoshikiGame = '/futoshiki/game';
  static const tents = '/tents';
  static const tentsGame = '/tents/game';
  static const jigsawSudoku = '/jigsaw-sudoku';
  static const jigsawSudokuGame = '/jigsaw-sudoku/game';
  static const skyscrapers = '/skyscrapers';
  static const skyscrapersGame = '/skyscrapers/game';
  static const kakuro = '/kakuro';
  static const kakuroGame = '/kakuro/game';

  /// gameId → home 라우트 매핑 (GameRegistry.id와 일치)
  static String homeRouteOf(String gameId) {
    switch (gameId) {
      case 'sudoku':
        return home;
      case 'binairo':
        return binairo;
      case 'minesweeper':
        return minesweeper;
      case 'yinyang':
        return yinYang;
      case 'nonogram':
        return nonograms;
      case 'killerSudoku':
        return killerSudoku;
      case 'starBattle':
        return starBattle;
      case 'lightUp':
        return lightUp;
      case 'futoshiki':
        return futoshiki;
      case 'tents':
        return tents;
      case 'jigsawSudoku':
        return jigsawSudoku;
      case 'skyscrapers':
        return skyscrapers;
      case 'kakuro':
        return kakuro;
      default:
        return hub;
    }
  }
}

/// 초기 위치 오버라이드 (테스트용)
final initialLocationProvider = Provider<String?>((ref) => null);

/// go_router Provider
final routerProvider = Provider<GoRouter>((ref) {
  final locationOverride = ref.read(initialLocationProvider);

  // 항상 스플래시부터 시작
  // 스플래시 종료 후 SplashScreen이 settings(isFirstLaunch/lastGameRoute) 기준으로 다음 라우트를 push 함
  final effectiveInitial = locationOverride ?? AppRoutes.splash;

  return GoRouter(
    initialLocation: effectiveInitial,
    // 온보딩 제거 — 첫 진입도 곧바로 hub로
    // 튜토리얼 분기는 GameHubScreen 카드 onTap에서 처리한다
    redirect: (context, state) => null,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.hub,
        builder: (context, state) => const GameHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      // 온보딩 라우트 제거 (롤백 대비 폴더는 유지)
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
      // 게임별 튜토리얼 (v2) — /tutorial/:gameId
      GoRoute(
        path: '/tutorial/:gameId',
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return TutorialScreenV2(gameId: gameId);
        },
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
      // 지뢰찾기 홈
      GoRoute(
        path: AppRoutes.minesweeper,
        builder: (context, state) => const MinesweeperHomeScreen(),
      ),
      // 지뢰찾기 게임 플레이
      GoRoute(
        path: AppRoutes.minesweeperGame,
        builder: (context, state) => const MinesweeperGameScreen(),
      ),
      // 음양 홈
      GoRoute(
        path: AppRoutes.yinYang,
        builder: (context, state) => const YinYangHomeScreen(),
      ),
      // 음양 게임 플레이
      GoRoute(
        path: AppRoutes.yinYangGame,
        builder: (context, state) => const YinYangGameScreen(),
      ),
      // 노노그램 홈
      GoRoute(
        path: AppRoutes.nonograms,
        builder: (context, state) => const NonogramHomeScreen(),
      ),
      // 노노그램 게임 플레이
      GoRoute(
        path: AppRoutes.nonogramsGame,
        builder: (context, state) => const NonogramGameScreen(),
      ),
      // 킬러 스도쿠 홈
      GoRoute(
        path: AppRoutes.killerSudoku,
        builder: (context, state) => const KillerSudokuHomeScreen(),
      ),
      // 킬러 스도쿠 게임 플레이
      GoRoute(
        path: AppRoutes.killerSudokuGame,
        builder: (context, state) => const KillerSudokuGameScreen(),
      ),
      // 스타 배틀 홈
      GoRoute(
        path: AppRoutes.starBattle,
        builder: (context, state) => const StarBattleHomeScreen(),
      ),
      // 스타 배틀 게임 플레이
      GoRoute(
        path: AppRoutes.starBattleGame,
        builder: (context, state) => const StarBattleGameScreen(),
      ),
      // 라이트업 홈
      GoRoute(
        path: AppRoutes.lightUp,
        builder: (context, state) => const LightUpHomeScreen(),
      ),
      // 라이트업 게임 플레이
      GoRoute(
        path: AppRoutes.lightUpGame,
        builder: (context, state) => const LightUpGameScreen(),
      ),
      // 후토시키 홈
      GoRoute(
        path: AppRoutes.futoshiki,
        builder: (context, state) => const FutoshikiHomeScreen(),
      ),
      // 후토시키 게임 플레이
      GoRoute(
        path: AppRoutes.futoshikiGame,
        builder: (context, state) => const FutoshikiGameScreen(),
      ),
      // 텐트 홈
      GoRoute(
        path: AppRoutes.tents,
        builder: (context, state) => const TentsHomeScreen(),
      ),
      // 텐트 게임 플레이
      GoRoute(
        path: AppRoutes.tentsGame,
        builder: (context, state) => const TentsGameScreen(),
      ),
      // 직소 스도쿠 홈
      GoRoute(
        path: AppRoutes.jigsawSudoku,
        builder: (context, state) => const JigsawSudokuHomeScreen(),
      ),
      // 직소 스도쿠 게임 플레이
      GoRoute(
        path: AppRoutes.jigsawSudokuGame,
        builder: (context, state) => const JigsawSudokuGameScreen(),
      ),
      // 빌딩 홈
      GoRoute(
        path: AppRoutes.skyscrapers,
        builder: (context, state) => const SkyscrapersHomeScreen(),
      ),
      // 빌딩 게임 플레이
      GoRoute(
        path: AppRoutes.skyscrapersGame,
        builder: (context, state) => const SkyscrapersGameScreen(),
      ),
      // 카쿠로 홈
      GoRoute(
        path: AppRoutes.kakuro,
        builder: (context, state) => const KakuroHomeScreen(),
      ),
      // 카쿠로 게임 플레이
      GoRoute(
        path: AppRoutes.kakuroGame,
        builder: (context, state) => const KakuroGameScreen(),
      ),
    ],
  );
});
