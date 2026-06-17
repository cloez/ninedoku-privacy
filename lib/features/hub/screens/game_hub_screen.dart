import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/engine/game_registry.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/kp_widgets.dart';
import '../../../app/router.dart';
import '../hub_progress_service.dart';

/// 게임 허브 화면 — KP 디자인 시스템
class GameHubScreen extends ConsumerWidget {
  const GameHubScreen({super.key});

  Future<bool> _showExitConfirm(BuildContext context) async {
    final s = AppStrings.get;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('hub.exitTitle')),
        content: Text(s('hub.exitMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s('exit.quit')),
          ),
        ],
      ),
    );
    if (result == true) SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.get;
    final prefs = ref.watch(sharedPreferencesProvider);
    final (todayCompleted, totalGames) = HubProgressService.todayDailyProgress(prefs);
    final streakDays = HubProgressService.currentStreak(prefs);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitConfirm(context);
      },
      child: Scaffold(
        body: KPBackground(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                sliver: SliverList.list(children: [
                  Row(children: [
                    const SizedBox(width: 50),
                    Expanded(
                      child: Text(
                        s('hub.title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 30, fontWeight: FontWeight.w900,
                          color: AppColors.brandIndigo, letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    KPIconButton(
                      asset: 'assets/icons/gear.svg',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _DailyStatusCard(
                    todayCompleted: todayCompleted,
                    totalGames: totalGames,
                    streakDays: streakDays,
                    s: s,
                  ),
                  const SizedBox(height: 18),
                ]),
              ),
              // 2열 그리드 — 홀수 개면 마지막 카드는 전체 너비로 분리
            SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: GameRegistry.games.length.isOdd
                      ? GameRegistry.games.length - 1
                      : GameRegistry.games.length,
                  itemBuilder: (context, index) {
                    final game = GameRegistry.games[index];
                    return _GameCard(
                      game: game,
                      inProgress: HubProgressService.isGameInProgress(prefs, game.id),
                      onTap: () => _onGameTap(context, ref, game),
                    );
                  },
                ),
              ),
              // 홀수 개일 때 마지막 카드 전체 너비 표시
              if (GameRegistry.games.length.isOdd)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: _GameCard(
                        game: GameRegistry.games.last,
                        inProgress: HubProgressService.isGameInProgress(prefs, GameRegistry.games.last.id),
                        onTap: () => _onGameTap(context, ref, GameRegistry.games.last),
                        isFullWidth: true,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
                sliver: SliverToBoxAdapter(child: _BottomBar(s: s)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onGameTap(BuildContext context, WidgetRef ref, GameInfo game) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final settings = SettingsService(prefs);
      if (!settings.isTutorialSeen(game.id)) {
        await context.push('/tutorial/${game.id}');
        await settings.setTutorialSeen(game.id, true);
      }
      if (!context.mounted) return;
      context.push(game.routePath);
    } catch (e) {
      if (context.mounted) context.push(game.routePath);
    }
  }
}

class _DailyStatusCard extends StatelessWidget {
  const _DailyStatusCard({
    required this.todayCompleted,
    required this.totalGames,
    required this.streakDays,
    required this.s,
  });
  final int todayCompleted, totalGames, streakDays;
  final String Function(String) s;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.progressGradientDark : AppColors.progressGradientLight;
    return Container(
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: colors),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.33), blurRadius: 28, offset: const Offset(0, 13))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        // 퍼즐 조각 장식 (우상단, 약간 기울어진 형태)
        Positioned(
          top: -8, right: 16,
          child: Transform.rotate(
            angle: 0.3,
            child: const Text('🧩', style: TextStyle(fontSize: 38)),
          ),
        ),
        // 좌상단 노란 별빛 장식
        const Positioned(top: 8, left: 16, child: Text('✦', style: TextStyle(color: Color(0xFFFFC542), fontSize: 14))),
        // 중앙 우측 작은 스파클
        const Positioned(top: 40, right: 60, child: Text('✧', style: TextStyle(color: Colors.white60, fontSize: 10))),
        // 우하단 하늘색 스파클
        const Positioned(bottom: 8, right: 28, child: Text('✦', style: TextStyle(color: Color(0xFF80DDFF), fontSize: 12))),
        // 좌하단 은은한 스파클
        const Positioned(bottom: 14, left: 40, child: Text('✧', style: TextStyle(color: Colors.white38, fontSize: 16))),
        // 기존 Row 레이아웃 유지
        Row(children: [
          Expanded(child: _StatusItem(icon: 'assets/icons/hub-daily-calendar.png', label: s('hub.dailyLabel'), value: '$todayCompleted/$totalGames')),
          Container(width: 1, height: 72, color: Colors.white24),
          Expanded(child: _StatusItem(icon: 'assets/icons/hub-streak-flame.png', label: s('hub.streakLabel'), value: '$streakDays${s('hub.streakDaySuffix')}')),
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
      Container(
        width: 48, height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)),
        child: Image.asset(icon, filterQuality: FilterQuality.medium),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        ]),
      ),
    ]),
  );
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.inProgress,
    required this.onTap,
    this.isFullWidth = false,
  });
  final GameInfo game;
  final bool inProgress;
  final VoidCallback onTap;
  final bool isFullWidth;

  // 게임 이름 텍스트 색상 — 밝은 색상은 어둡게 조정해 가독성 확보
  static Color _nameColor(Color primary, bool isDark) {
    if (isDark) return Colors.white;
    final hsl = HSLColor.fromColor(primary);
    // 밝은 색상 (lightness > 0.45)은 어둡게 보정
    if (hsl.lightness > 0.45) {
      return hsl.withLightness(0.35).withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0)).toColor();
    }
    return primary;
  }

  // 허브 카드 전용 3D 아이콘 에셋 경로
  static const _hubIcon = <String, String>{
    'sudoku': 'assets/icons/hub-sudoku.png',
    'binairo': 'assets/icons/hub-binairo.png',
    'minesweeper': 'assets/icons/hub-minesweeper.png',
    'yinyang': 'assets/icons/hub-yinyang.png',
    'nonogram': 'assets/icons/hub-nonogram.png',
    'killerSudoku': 'assets/icons/hub-killerSudoku.png',
    'starBattle': 'assets/icons/hub-starBattle.png',
    'lightUp': 'assets/icons/hub-lightUp.png',
    'futoshiki': 'assets/icons/hub-futoshiki.png',
    'tents': 'assets/icons/hub-tents.png',
    'jigsawSudoku': 'assets/icons/hub-jigsawSudoku.png',
    'skyscrapers': 'assets/icons/hub-skyscrapers.png',
    'kakuro': 'assets/icons/hub-kakuro.png',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.gameThemeColors[game.id] ?? AppColors.brandIndigo;
    final bgColor = isDark
        ? primary.withValues(alpha: 0.1)
        : (AppColors.gameCardBgColors[game.id] ?? Colors.white);
    final s = AppStrings.get;
    // Figma 디자인 토큰: 통일된 보라 그림자
    const shadowColor = Color(0xFF3F35B5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: isDark
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bgColor, Color.lerp(bgColor, Colors.white, 0.15)!],
                  ),
            color: isDark ? bgColor : null,
            // Figma: 컬러 보더 + 화이트 이너 보더 효과
            border: Border.all(
              color: isDark ? primary.withValues(alpha: 0.20) : (AppColors.gameSecondaryColors[game.id] ?? primary.withValues(alpha: 0.2)),
              width: 1.5,
            ),
            // Figma: 통일 퍼플 그림자
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(color: shadowColor.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 8)),
                    BoxShadow(color: shadowColor.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
          ),
          child: Stack(clipBehavior: Clip.hardEdge, children: [
            // Figma: 대각선 글로스 (cardGloss) + 화이트 이너 보더
            if (!isDark)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment(-1.0, -1.0),
                        end: Alignment(0.3, 0.3),
                        colors: [Color(0x55FFFFFF), Color(0x18FFFFFF), Color(0x00FFFFFF)],
                      ),
                      border: Border.all(color: const Color(0xD9FFFFFF), width: 1.5),
                      borderRadius: BorderRadius.circular(8.5),
                    ),
                  ),
                ),
              ),
            // Figma: 우하단 코너 하이라이트 웨이브
            if (!isDark)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.5),
                  child: CustomPaint(painter: _CornerWavePainter(primary)),
                ),
              ),
            // Figma: 화이트 스파클 장식 3개 (크게 + 중간 + 작게)
            if (!isDark) ...[
              Positioned(
                top: isFullWidth ? 10 : 6, right: isFullWidth ? 48 : 36,
                child: _Sparkle(size: isFullWidth ? 18 : 14, opacity: 0.95),
              ),
              Positioned(
                top: isFullWidth ? 38 : 28, right: isFullWidth ? 18 : 12,
                child: _Sparkle(size: isFullWidth ? 12 : 9, opacity: 0.8),
              ),
              Positioned(
                bottom: isFullWidth ? 18 : 14, right: isFullWidth ? 32 : 22,
                child: _Sparkle(size: isFullWidth ? 14 : 11, opacity: 0.65),
              ),
            ],
            // 번호 탭 배지 — 확대 (레퍼런스 매칭)
            Positioned(
              top: 0, left: 0,
              child: PhysicalShape(
                clipper: _TabBadgeClipper(),
                color: primary,
                elevation: 4,
                shadowColor: const Color(0xFF2A205E),
                child: SizedBox(
                  width: isFullWidth ? 56 : 50, height: isFullWidth ? 34 : 32,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Text(
                        (game.order + 1).toString().padLeft(2, '0'),
                        style: TextStyle(color: Colors.white, fontSize: isFullWidth ? 15 : 13, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // NEW 배지 — 초록색, 오른쪽 상단
            if (game.isNew)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF59C878),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: const Color(0xFF59C878).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ),
            // 진행중 배지
            if (inProgress && !game.isNew)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandGold,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: AppColors.brandGold.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(s('hub.inProgress'), style: const TextStyle(color: Color(0xFF1D2340), fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
            // 하단 컬러 악센트 바 (프리미엄)
            Positioned(
              left: 16, right: 16, bottom: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primary.withValues(alpha: 0.0),
                    primary.withValues(alpha: isDark ? 0.4 : 0.22),
                    primary.withValues(alpha: 0.0),
                  ]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 메인 콘텐츠 — 대형 아이콘 + 큰 텍스트
            Padding(
              padding: EdgeInsets.fromLTRB(
                isFullWidth ? 12 : 4,
                isFullWidth ? 14 : 30,
                isFullWidth ? 10 : 6,
                isFullWidth ? 14 : 4,
              ),
              child: Row(children: [
                // 3D 아이콘 — 카드의 주인공
                SizedBox(
                  width: isFullWidth ? 110 : 68,
                  child: Transform.rotate(
                    angle: -0.05,
                    child: Image.asset(
                      _hubIcon[game.id] ?? 'assets/icons/hub-sudoku.png',
                      width: isFullWidth ? 100 : 62,
                      height: isFullWidth ? 100 : 62,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                SizedBox(width: isFullWidth ? 10 : 2),
                // 텍스트 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s(game.nameKey),
                        maxLines: isFullWidth ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isFullWidth ? 24 : 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          color: _nameColor(primary, isDark),
                        ),
                      ),
                      SizedBox(height: isFullWidth ? 6 : 3),
                      Text(
                        s(game.descriptionKey),
                        maxLines: isFullWidth ? 3 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isFullWidth ? 14 : 12,
                          height: 1.35,
                          color: isDark ? Colors.white54 : AppColors.kpMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Figma 코너 웨이브 — 우하단 곡선 장식
class _CornerWavePainter extends CustomPainter {
  _CornerWavePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color.withValues(alpha: 0.13);
    final path = Path()
      ..moveTo(w * 0.78, h)
      ..cubicTo(w * 0.80, h * 0.70, w * 0.88, h * 0.68, w, h * 0.55)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, paint);
    // 하이라이트 곡선
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final linePath = Path()
      ..moveTo(w * 0.80, h)
      ..cubicTo(w * 0.83, h * 0.76, w * 0.89, h * 0.73, w, h * 0.62);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Figma 스파클 (4각 별)
class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _SparklePainter(opacity),
  );
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.opacity);
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.24, cy - r * 0.24)
      ..lineTo(cx + r, cy)
      ..lineTo(cx + r * 0.24, cy + r * 0.24)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.24, cy + r * 0.24)
      ..lineTo(cx - r, cy)
      ..lineTo(cx - r * 0.24, cy - r * 0.24)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Figma 탭 배지 클리퍼 — 좌측 직각, 우하단 둥근 형태
class _TabBadgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final r = size.height * 0.30;
    return Path()
      // 좌상단 카드 radius와 맞춤
      ..moveTo(0, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.s});
  final String Function(String) s;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isDark ? null : KPShadow.soft,
        border: isDark ? Border.all(color: AppColors.outlineDark) : null,
      ),
      child: Row(children: [
        Expanded(child: _BottomItem(icon: 'assets/icons/chart.svg', label: s('home.statistics'), active: true, onTap: () => context.push(AppRoutes.statistics))),
        Expanded(child: _BottomItem(icon: 'assets/icons/trophy.svg', label: s('home.badges'), onTap: () => context.push(AppRoutes.badges))),
        Expanded(child: _BottomItem(icon: 'assets/icons/gear.svg', label: s('home.settings'), onTap: () => context.push(AppRoutes.settings))),
      ]),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.icon, required this.label, this.active = false, this.onTap});
  final String icon, label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? (isDark ? AppColors.primaryDark : AppColors.brandIndigo)
        : (isDark ? Colors.white54 : AppColors.kpMuted);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? (isDark ? AppColors.brandIndigo.withValues(alpha: 0.2) : AppColors.kpPaleViolet) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset(icon, width: 26, height: 26, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
