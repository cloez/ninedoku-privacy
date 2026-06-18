import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'kp_widgets.dart';

/// 게임 홈 공통 템플릿 — 13개 게임 홈 화면에서 공유
/// 레퍼런스 디자인 기반: 3D 아이콘 히어로 + 별 캐릭터 + 퍼즐 장식
class GameHomeTemplate extends StatelessWidget {
  final String gameId;
  final String emoji;
  final String tagline;
  final String iconAsset; // 하위 호환 유지
  final Color? secondaryColor;
  final Widget? continueCard;
  final VoidCallback onNewGame;
  final String newGameLabel;
  final VoidCallback onDailyPuzzle;
  final String dailyPuzzleLabel;
  final VoidCallback onStatistics;
  final String statisticsLabel;
  final VoidCallback onBadges;
  final String badgesLabel;
  final Widget? rulesCard;

  const GameHomeTemplate({
    super.key,
    required this.gameId,
    required this.emoji,
    required this.tagline,
    required this.iconAsset,
    this.secondaryColor,
    this.continueCard,
    required this.onNewGame,
    required this.newGameLabel,
    required this.onDailyPuzzle,
    required this.dailyPuzzleLabel,
    required this.onStatistics,
    required this.statisticsLabel,
    required this.onBadges,
    required this.badgesLabel,
    this.rulesCard,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor =
        AppColors.gameThemeColors[gameId] ?? AppColors.brandIndigo;
    final secondary = secondaryColor ??
        AppColors.gameSecondaryColors[gameId] ??
        themeColor;

    return KPBackground(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 히어로 카드 — 3D PNG 아이콘 + 그라데이션
                KPHeroCard(
                  gameId: gameId,
                  tagline: tagline,
                  primary: themeColor,
                  secondary: secondary,
                ),
                const SizedBox(height: 24),

                // 이어하기 카드
                if (continueCard != null) ...[
                  continueCard!,
                  const SizedBox(height: 16),
                ],

                // 새 게임 (그라데이션 CTA)
                KPGradientButton(
                  onTap: onNewGame,
                  iconAsset: 'assets/icons/play.svg',
                  label: newGameLabel,
                  colors: [themeColor, secondary],
                ),
                const SizedBox(height: 12),

                // 오늘의 퍼즐
                KPGradientButton(
                  onTap: onDailyPuzzle,
                  iconAsset: 'assets/icons/play.svg',
                  label: dailyPuzzleLabel,
                  colors: [
                    AppColors.kpPaleViolet,
                    const Color(0xFFF8F5FF),
                  ],
                  foreground: AppColors.kpText,
                ),
                const SizedBox(height: 20),

                // 통계 + 배지 (민트/골드 배경)
                Row(
                  children: [
                    Expanded(
                      child: KPMiniButton(
                        iconAsset: 'assets/icons/chart.svg',
                        label: statisticsLabel,
                        background: const Color(0xFFE0F5EC),
                        onTap: onStatistics,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KPMiniButton(
                        iconAsset: 'assets/icons/trophy.svg',
                        label: badgesLabel,
                        background: const Color(0xFFFFF3D6),
                        onTap: onBadges,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 규칙 카드
                if (rulesCard != null) rulesCard!,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KP 히어로 카드 — 3D PNG 아이콘 + 그라데이션 + 장식
// ---------------------------------------------------------------------------
/// 게임 메인화면 상단 히어로 카드
class KPHeroCard extends StatelessWidget {
  final String gameId;
  final String tagline;
  final Color primary;
  final Color secondary;

  const KPHeroCard({
    super.key,
    required this.gameId,
    required this.tagline,
    required this.primary,
    required this.secondary,
  });

  // 게임별 3D 허브 아이콘
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
    final hubIconPath = _hubIcon[gameId] ?? 'assets/icons/hub-sudoku.png';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [secondary.withValues(alpha: 0.5), primary.withValues(alpha: 0.5)]
              : [secondary, primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.2 : 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // 하단 웨이브 장식
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 50),
              painter: _HeroWavePainter(primary),
            ),
          ),
          // 장식: 좌측 별
          Positioned(
            top: 40, left: 12,
            child: KPSparkle(size: 28, color: Colors.white.withValues(alpha: 0.5)),
          ),
          // 장식: 우상단 핑크 점
          Positioned(
            top: 18, right: 30,
            child: Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9EC6).withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 장식: 좌하단 큐브
          Positioned(
            bottom: 55, left: 30,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          // 스파클 장식들
          Positioned(top: 65, right: 20, child: KPSparkle(size: 14, color: Colors.white.withValues(alpha: 0.4))),
          Positioned(bottom: 70, left: 55, child: KPSparkle(size: 10, color: Colors.white.withValues(alpha: 0.3))),
          Positioned(bottom: 35, right: 60, child: KPSparkle(size: 12, color: Colors.white.withValues(alpha: 0.35))),
          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                // 3D 아이콘 + 별 캐릭터
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      hubIconPath,
                      width: 140, height: 140,
                      filterQuality: FilterQuality.medium,
                    ),
                    // 별 캐릭터 장식
                    Positioned(
                      bottom: -4, right: -12,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.brandGold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandGold.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.star_rounded, size: 22, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 태그라인
                Text(
                  '• $tagline •',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 히어로 카드 하단 웨이브 장식
class _HeroWavePainter extends CustomPainter {
  _HeroWavePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.18);
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..cubicTo(
        size.width * 0.25, size.height * 0.2,
        size.width * 0.75, size.height * 0.9,
        size.width, size.height * 0.35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 캐주얼 규칙 카드 — 퍼즐 장식 + 점선 구분
// ---------------------------------------------------------------------------
class CasualRulesCard extends StatelessWidget {
  final String aboutTitle;
  final String aboutDesc;
  final String rulesTitle;
  final List<String> rules;
  final String? footerText;
  final Color themeColor;

  const CasualRulesCard({
    super.key,
    required this.aboutTitle,
    required this.aboutDesc,
    required this.rulesTitle,
    required this.rules,
    this.footerText,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.kpText;
    final bodyColor = isDark ? Colors.white60 : AppColors.kpMuted;
    final borderColor = isDark
        ? themeColor.withValues(alpha: 0.25)
        : themeColor.withValues(alpha: 0.22);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isDark ? null : KPShadow.soft,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 퍼즐 조각 장식 — 우상단
          if (!isDark)
            const Positioned(
              top: -6, right: -2,
              child: Text('🧩', style: TextStyle(fontSize: 22)),
            ),
          // 퍼즐 조각 장식 — 좌하단
          if (!isDark)
            Positioned(
              bottom: -4, left: -2,
              child: Transform.rotate(
                angle: -0.5,
                child: Opacity(
                  opacity: 0.6,
                  child: const Text('🧩', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 퍼즐 아이콘 + 타이틀
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🧩', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      aboutTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                aboutDesc,
                style: TextStyle(fontSize: 13.5, color: bodyColor, height: 1.6),
              ),
              const SizedBox(height: 18),
              Text(
                rulesTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              // 번호 규칙 목록 + 점선 구분
              ...List.generate(rules.length, (i) {
                return Column(
                  children: [
                    // 점선 구분 (첫 항목 제외)
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 36, bottom: 10, top: 2),
                        child: _DashedLine(
                          color: themeColor.withValues(alpha: 0.2),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 번호 배지
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: themeColor.withValues(
                                alpha: isDark ? 0.25 : 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                rules[i],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: bodyColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              // 하단 CTA
              if (footerText != null) ...[
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    '✦  $footerText  ✦',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? themeColor.withValues(alpha: 0.7)
                          : themeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 점선 구분선
class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            dashCount,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: dashSpace),
              color: color,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 캐주얼 이어하기 카드 — KP 디자인
// ---------------------------------------------------------------------------
class CasualContinueCard extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final String timeText;
  final List<String> chips;
  final double progress;
  final String progressLabel;
  final Color themeColor;

  const CasualContinueCard({
    super.key,
    required this.onTap,
    required this.label,
    required this.timeText,
    required this.chips,
    required this.progress,
    required this.progressLabel,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.3),
            ),
            boxShadow: isDark ? null : KPShadow.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_filled_rounded,
                    color: themeColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.kpText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeText,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.kpMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: chips
                    .map(
                      (chip) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: themeColor
                              .withValues(alpha: isDark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          chip,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? themeColor.withValues(alpha: 0.9)
                                : themeColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white12
                      : Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(themeColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progressLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
