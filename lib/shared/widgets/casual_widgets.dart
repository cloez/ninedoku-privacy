import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 캐주얼 그라데이션 배경 — 허브/게임 홈에서 사용
class CasualGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const CasualGradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = colors ??
        (isDark ? AppColors.hubGradientDark : AppColors.hubGradientLight);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: child,
    );
  }
}

/// 반짝임 장식 — 허브/게임 홈 배경에 사용
class SparkleDecoration extends StatelessWidget {
  final double width;
  final double height;

  const SparkleDecoration({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sparkleColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.5);

    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparklePainter(color: sparkleColor),
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // 고정 위치에 작은 원과 별 모양 장식
    final positions = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.08),
      Offset(size.width * 0.7, size.height * 0.25),
      Offset(size.width * 0.2, size.height * 0.35),
      Offset(size.width * 0.9, size.height * 0.4),
      Offset(size.width * 0.05, size.height * 0.55),
      Offset(size.width * 0.6, size.height * 0.12),
    ];
    final sizes = [3.0, 2.5, 2.0, 1.5, 2.0, 1.5, 2.5];

    for (var i = 0; i < positions.length; i++) {
      canvas.drawCircle(positions[i], sizes[i], paint);
      // 4방향 작은 선으로 반짝임 표현
      if (i % 2 == 0) {
        final r = sizes[i] * 2;
        final c = positions[i];
        canvas.drawLine(
          Offset(c.dx - r, c.dy),
          Offset(c.dx + r, c.dy),
          paint..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(c.dx, c.dy - r),
          Offset(c.dx, c.dy + r),
          paint..strokeWidth = 0.8,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 그라데이션 버튼 — 새 게임 등 주요 CTA에 사용
class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final List<Color> colors;
  final double? width;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.colors,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: colors.first.withValues(alpha: 0.4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: const IconThemeData(color: Colors.white, size: 24),
                    child: icon,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 히어로 카드 — 게임 메인화면 상단에 사용
class GameHeroCard extends StatelessWidget {
  final String emoji;
  final String tagline;
  final Color themeColor;

  const GameHeroCard({
    super.key,
    required this.emoji,
    required this.tagline,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColors = isDark
        ? [themeColor.withValues(alpha: 0.3), themeColor.withValues(alpha: 0.1)]
        : [themeColor.withValues(alpha: 0.15), themeColor.withValues(alpha: 0.05)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: isDark ? 0.15 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 장식
          Positioned(
            top: -8,
            right: 10,
            child: Text(
              '✨',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          Positioned(
            bottom: -4,
            left: 20,
            child: Text(
              '⭐',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          Column(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 12),
              Text(
                '✦ $tagline ✦',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : themeColor.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 캐주얼 섹션 헤더 — 설정 화면 등에 사용
class CasualSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;

  const CasualSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = color ?? AppColors.brandIndigo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          if (icon != null) ...[
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? accentColor.withValues(alpha: 0.9) : accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 캐주얼 카드 래퍼 — 파스텔 테두리 + 소프트 그림자
class CasualCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CasualCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black26
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}
