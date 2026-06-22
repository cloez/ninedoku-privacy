import 'package:flutter/material.dart';
import '../models/game_definition.dart';
import '../theme/app_theme.dart';
import '../widgets/game_home_components.dart';
import '../widgets/kp_background.dart';
import '../widgets/kp_icon_button.dart';

class GameHomeScreen extends StatelessWidget {
  const GameHomeScreen({super.key, required this.game});
  final GameDefinition game;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KPBackground(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
              sliver: SliverList.list(children: [
                Row(children: [
                  KPIconButton(asset: 'assets/icons/grid.svg', onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false)),
                  Expanded(child: Text(game.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium)),
                  KPIconButton(asset: 'assets/icons/help.svg', onTap: () {}),
                  const SizedBox(width: 10),
                  KPIconButton(asset: 'assets/icons/gear.svg', onTap: () => Navigator.pushNamed(context, '/settings')),
                ]),
                const SizedBox(height: 18),
                GameHeroCard(game: game),
                const SizedBox(height: 20),
                GradientActionButton(
                  label: '새 게임', iconAsset: 'assets/icons/play.svg',
                  colors: [game.primary, game.secondary],
                  onTap: game.id == 'sudoku' ? () => Navigator.pushNamed(context, '/play/sudoku') : () => _showComingSoon(context),
                ),
                const SizedBox(height: 14),
                GradientActionButton(
                  label: '오늘의 퍼즐', iconAsset: 'assets/icons/calendar.svg',
                  colors: [game.surface, const Color(0xFFF3ECFF)], foreground: KPColors.indigo,
                  onTap: () => _showComingSoon(context),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: MiniActionButton(label: '통계', iconAsset: 'assets/icons/chart.svg', background: const Color(0xFFEAFBF6), onTap: () {})),
                  const SizedBox(width: 14),
                  Expanded(child: MiniActionButton(label: '배지', iconAsset: 'assets/icons/trophy.svg', background: const Color(0xFFFFF6D9), onTap: () {})),
                ]),
                const SizedBox(height: 20),
                GameInfoCard(game: game),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${game.title} 플레이 화면은 동일한 공통 플레이 프레임에 연결하면 됩니다.')));
  }
}
