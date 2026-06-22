import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KPBackground extends StatelessWidget {
  const KPBackground({super.key, required this.child, this.maxWidth = 560});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7F4FF), KPColors.background, Color(0xFFFFFCF7)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: 42, right: -38, child: _SoftBlob(size: 150, color: Color(0x228C73FF))),
          const Positioned(top: 220, left: -58, child: _SoftBlob(size: 130, color: Color(0x155EB9FF))),
          const Positioned(bottom: 80, right: -44, child: _SoftBlob(size: 120, color: Color(0x16FFC542))),
          Positioned.fill(
            child: SafeArea(
              child: Center(
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

class Sparkle extends StatelessWidget {
  const Sparkle({super.key, this.size = 16, this.color = KPColors.gold});
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
