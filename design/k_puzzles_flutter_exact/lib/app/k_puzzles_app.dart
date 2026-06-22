import 'package:flutter/material.dart';
import '../data/game_catalog.dart';
import '../screens/game_home_screen.dart';
import '../screens/game_hub_screen.dart';
import '../screens/play/sudoku_play_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';

class KPuzzlesApp extends StatelessWidget {
  const KPuzzlesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'K-퍼즐',
      theme: buildTheme(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        if (name == '/') return MaterialPageRoute(builder: (_) => const GameHubScreen(), settings: settings);
        if (name == '/settings') return MaterialPageRoute(builder: (_) => const SettingsScreen(), settings: settings);
        if (name == '/play/sudoku') return MaterialPageRoute(builder: (_) => const SudokuPlayScreen(), settings: settings);
        if (name.startsWith('/game/')) {
          final id = name.substring('/game/'.length);
          final game = gameCatalog.where((g) => g.id == id).firstOrNull;
          if (game != null) return MaterialPageRoute(builder: (_) => GameHomeScreen(game: game), settings: settings);
        }
        return MaterialPageRoute(builder: (_) => const GameHubScreen(), settings: settings);
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
