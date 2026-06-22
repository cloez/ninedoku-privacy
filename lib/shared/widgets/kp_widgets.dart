import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

// ---------------------------------------------------------------------------
// KP 그림자 스타일
// ---------------------------------------------------------------------------
/// KP 디자인 시스템 그림자
abstract final class KPShadow {
  static const soft = [
    BoxShadow(color: Color(0x163F35B5), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static const button = [
    BoxShadow(color: Color(0x254B54F7), blurRadius: 20, offset: Offset(0, 9)),
  ];
}

// ---------------------------------------------------------------------------
// KP 배경 — 그라데이션 + 소프트 블롭
// ---------------------------------------------------------------------------
/// KP 디자인 배경 (그라데이션 + 장식 블롭)
class KPBackground extends StatelessWidget {
  const KPBackground({super.key, required this.child, this.maxWidth = 560});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? AppColors.hubGradientDark
              : AppColors.hubGradientLight,
        ),
      ),
      child: Stack(
        children: [
          if (!isDark) ...[
            const Positioned(top: 42, right: -38, child: _SoftBlob(size: 150, color: Color(0x228C73FF))),
            const Positioned(top: 220, left: -58, child: _SoftBlob(size: 130, color: Color(0x155EB9FF))),
            const Positioned(bottom: 80, right: -44, child: _SoftBlob(size: 120, color: Color(0x16FFC542))),
          ],
          Positioned.fill(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 소프트 블롭 — 배경 장식용 반투명 원
class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: math.pi / 8,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * .35)),
    ),
  );
}

// ---------------------------------------------------------------------------
// KP 스파클 — 4점 별 장식
// ---------------------------------------------------------------------------
/// 4점 별 커스텀 페인터
class KPSparkle extends StatelessWidget {
  const KPSparkle({super.key, this.size = 16, this.color = AppColors.brandGold});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SparklePainter(color));
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width * .63, size.height * .37)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width * .63, size.height * .63)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width * .37, size.height * .63)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width * .37, size.height * .37)
      ..close();
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// KP 아이콘 버튼 — 흰색 라운드 박스
// ---------------------------------------------------------------------------
/// KP 디자인 아이콘 버튼
class KPIconButton extends StatelessWidget {
  const KPIconButton({super.key, required this.asset, this.onTap, this.size = 50});
  final String asset;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.outlineDark : AppColors.kpBorder),
            boxShadow: isDark ? null : KPShadow.soft,
          ),
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(asset, colorFilter: isDark ? const ColorFilter.mode(Colors.white70, BlendMode.srcIn) : null),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KP 그라데이션 액션 버튼
// ---------------------------------------------------------------------------
/// KP 디자인 그라데이션 CTA 버튼
class KPGradientButton extends StatelessWidget {
  const KPGradientButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.colors,
    this.onTap,
    this.foreground = Colors.white,
    this.colorfulIcon = false,
  });
  final String label;
  final String iconAsset;
  final List<Color> colors;
  final Color foreground;
  final VoidCallback? onTap;
  /// true면 SVG 원래 색상 유지 (colorFilter 미적용)
  final bool colorfulIcon;

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
              // 우상단 스파클
              Positioned(right: 28, top: 14, child: KPSparkle(size: 18, color: foreground.withValues(alpha: 0.7))),
              // 우하단 작은 스파클
              Positioned(right: 48, bottom: 14, child: KPSparkle(size: 11, color: foreground.withValues(alpha: 0.4))),
              // + 아이콘 (우측)
              Positioned(
                right: 16, top: 0, bottom: 0,
                child: Center(child: Icon(Icons.add_rounded, color: foreground.withValues(alpha: 0.45), size: 22)),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42, height: 42,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.24), shape: BoxShape.circle),
                      child: SvgPicture.asset(
                        iconAsset,
                        colorFilter: colorfulIcon ? null : ColorFilter.mode(foreground, BlendMode.srcIn),
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// KP 미니 액션 버튼
// ---------------------------------------------------------------------------
/// KP 디자인 미니 버튼 (통계, 배지 등)
class KPMiniButton extends StatelessWidget {
  const KPMiniButton({super.key, required this.label, required this.iconAsset, required this.background, this.onTap});
  final String label;
  final String iconAsset;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 64,
          decoration: BoxDecoration(
            color: isDark ? background.withValues(alpha: 0.15) : background,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: isDark ? Colors.white12 : Colors.white),
            boxShadow: isDark ? null : KPShadow.soft,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(iconAsset, width: 30, height: 30),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.kpText,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
