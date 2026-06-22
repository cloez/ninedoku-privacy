import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/game_catalog.dart';
import '../models/game_definition.dart';
import '../theme/app_theme.dart';
import '../widgets/kp_background.dart';
import '../widgets/kp_icon_button.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KPBackground(
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            sliver: SliverList.list(children: [
              Row(children: [
                const SizedBox(width: 50),
                Expanded(child: Text('K-퍼즐', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium)),
                KPIconButton(asset: 'assets/icons/gear.svg', onTap: () => Navigator.pushNamed(context, '/settings')),
              ]),
              const SizedBox(height: 16),
              const _DailyStatusCard(),
              const SizedBox(height: 18),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .88),
              itemCount: gameCatalog.length,
              itemBuilder: (context, index) => _GameCard(game: gameCatalog[index]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
            sliver: SliverToBoxAdapter(child: _BottomBar(onSettings: () => Navigator.pushNamed(context, '/settings'))),
          ),
        ]),
      ),
    );
  }
}

class _DailyStatusCard extends StatelessWidget {
  const _DailyStatusCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [Color(0xFF5D52EF), Color(0xFF4A7AF8), Color(0xFF8C65F5)]),
        boxShadow: const [BoxShadow(color: Color(0x334A68F2), blurRadius: 28, offset: Offset(0, 13))],
      ),
      child: Stack(children: [
        const Positioned(top: 16, right: 30, child: Text('✦', style: TextStyle(color: Colors.white, fontSize: 22))),
        const Positioned(bottom: 12, left: 22, child: Text('✧', style: TextStyle(color: Colors.white70, fontSize: 18))),
        Row(children: [
          Expanded(child: _StatusItem(icon: 'assets/icons/calendar.svg', label: '오늘의 퍼즐', value: '0/13')),
          Container(width: 1, height: 72, color: Colors.white24),
          Expanded(child: _StatusItem(icon: 'assets/icons/flame.svg', label: '연속', value: '0일')),
        ]),
      ]),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.icon, required this.label, required this.value});
  final String icon, label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 44, height: 44, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(15)), child: SvgPicture.asset(icon)),
      const SizedBox(width: 10),
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
      ]),
    ]),
  );
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final GameDefinition game;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/game/${game.id}'),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [game.surface, Colors.white]),
            border: Border.all(color: game.primary.withOpacity(.12)),
            boxShadow: KPShadow.soft,
          ),
          child: Stack(children: [
            Positioned(right: -18, top: -18, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: game.primary.withOpacity(.08)))),
            if (game.isNew) Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE94E5B), borderRadius: BorderRadius.circular(999)), child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)))),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(color: game.primary.withOpacity(.18), borderRadius: BorderRadius.circular(10)), child: Text(game.order.toString().padLeft(2, '0'), style: TextStyle(color: game.primary, fontSize: 11, fontWeight: FontWeight.w900))),
                  const Spacer(),
                  const Text('✦', style: TextStyle(color: KPColors.gold, fontSize: 18)),
                ]),
                const Spacer(),
                Center(child: Container(width: 70, height: 70, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: KPShadow.soft), child: SvgPicture.asset(game.iconAsset))),
                const Spacer(),
                Text(game.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KPColors.text)),
                const SizedBox(height: 5),
                Text(game.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.35, color: KPColors.muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onSettings});
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: KPShadow.soft),
    child: Row(children: [
      const Expanded(child: _BottomItem(icon: 'assets/icons/chart.svg', label: '통계', active: true)),
      const Expanded(child: _BottomItem(icon: 'assets/icons/trophy.svg', label: '배지')),
      Expanded(child: GestureDetector(onTap: onSettings, child: const _BottomItem(icon: 'assets/icons/gear.svg', label: '설정'))),
    ]),
  );
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.icon, required this.label, this.active = false});
  final String icon, label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: active ? KPColors.paleViolet : Colors.transparent, borderRadius: BorderRadius.circular(18)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset(icon, width: 26, height: 26), const SizedBox(height: 5), Text(label, style: TextStyle(color: active ? KPColors.indigo : KPColors.muted, fontWeight: FontWeight.w800))]),
  );
}
