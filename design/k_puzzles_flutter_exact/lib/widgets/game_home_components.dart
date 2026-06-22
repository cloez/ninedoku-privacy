import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/game_definition.dart';
import '../theme/app_theme.dart';
import 'kp_background.dart';

class GameHeroCard extends StatelessWidget {
  const GameHeroCard({super.key, required this.game});
  final GameDefinition game;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 252,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [game.secondary, game.primary, Color.lerp(game.primary, Colors.white, .14)!],
        ),
        boxShadow: [BoxShadow(color: game.primary.withOpacity(.28), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 20, left: 22, child: Sparkle(size: 25, color: Colors.white.withOpacity(.75))),
          Positioned(top: 46, right: 26, child: Sparkle(size: 15, color: KPColors.gold)),
          Positioned(bottom: 56, left: 38, child: Sparkle(size: 11, color: Colors.white.withOpacity(.55))),
          Positioned(bottom: 28, right: 32, child: Sparkle(size: 28, color: KPColors.gold.withOpacity(.9))),
          Positioned(top: 36, left: 0, right: 0, child: _HeroIcon(game: game)),
          Positioned(left: 20, right: 20, bottom: 24, child: Text(
            game.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -.3),
          )),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.game});
  final GameDefinition game;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 126,
            height: 126,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(.7), width: 3),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: SvgPicture.asset(game.iconAsset),
          ),
          Positioned(right: -20, bottom: -12, child: _FriendlyStar(color: KPColors.gold)),
        ],
      ),
    );
  }
}

class _FriendlyStar extends StatelessWidget {
  const _FriendlyStar({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6))]),
      child: const Center(child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))),
    );
  }
}

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({super.key, required this.label, required this.iconAsset, required this.colors, this.onTap, this.foreground = Colors.white});
  final String label;
  final String iconAsset;
  final List<Color> colors;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: colors),
            boxShadow: KPShadow.button,
          ),
          child: Stack(
            children: [
              Positioned(right: 28, top: 15, child: Sparkle(size: 18, color: foreground.withOpacity(.75))),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 42, height: 42, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(.24), shape: BoxShape.circle), child: SvgPicture.asset(iconAsset)),
                    const SizedBox(width: 14),
                    Text(label, style: TextStyle(color: foreground, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniActionButton extends StatelessWidget {
  const MiniActionButton({super.key, required this.label, required this.iconAsset, required this.background, this.onTap});
  final String label;
  final String iconAsset;
  final Color background;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white), boxShadow: KPShadow.soft),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.asset(iconAsset, width: 30, height: 30),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KPColors.text)),
          ]),
        ),
      ),
    );
  }
}

class GameInfoCard extends StatelessWidget {
  const GameInfoCard({super.key, required this.game});
  final GameDefinition game;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.94), borderRadius: BorderRadius.circular(30), border: Border.all(color: game.primary.withOpacity(.13)), boxShadow: KPShadow.soft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: game.surface, shape: BoxShape.circle), child: SvgPicture.asset('assets/icons/puzzle.svg')),
          const SizedBox(width: 14),
          Expanded(child: Text('${game.title}란?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: KPColors.indigo))),
          Sparkle(size: 24, color: game.primary.withOpacity(.65)),
        ]),
        const SizedBox(height: 15),
        Text(game.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        const Text('규칙', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: KPColors.indigo)),
        const SizedBox(height: 12),
        ...game.rules.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: Color.lerp(game.surface, game.primary, .09), shape: BoxShape.circle), alignment: Alignment.center, child: Text('${entry.key + 1}', style: TextStyle(color: game.primary, fontWeight: FontWeight.w900))),
            const SizedBox(width: 12),
            Expanded(child: Padding(padding: const EdgeInsets.only(top: 5), child: Text(entry.value, style: const TextStyle(fontSize: 15, height: 1.45, color: KPColors.text)))),
          ]),
        )),
        Center(child: Padding(padding: const EdgeInsets.only(top: 4), child: Row(mainAxisSize: MainAxisSize.min, children: [
          Sparkle(size: 14, color: game.primary), const SizedBox(width: 8), Text('첫 게임을 시작해 보세요!', style: TextStyle(color: game.secondary, fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(width: 8), Sparkle(size: 14, color: game.primary),
        ]))),
      ]),
    );
  }
}
