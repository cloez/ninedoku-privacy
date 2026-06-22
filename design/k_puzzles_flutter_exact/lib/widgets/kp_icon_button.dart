import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

class KPIconButton extends StatelessWidget {
  const KPIconButton({super.key, required this.asset, this.onTap, this.size = 50});
  final String asset;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KPColors.border),
            boxShadow: KPShadow.soft,
          ),
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(asset),
        ),
      ),
    );
  }
}
