import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/motion_helper.dart';

/// 4단계 점진적 힌트 배너 — game-agnostic
class HintBanner extends StatelessWidget {
  final int level;
  final String? technique;
  final String message;
  final String? hintFooter;
  final VoidCallback onClose;
  final VoidCallback? onTechniqueTap;

  const HintBanner({
    super.key,
    required this.level,
    this.technique,
    required this.message,
    required this.onClose,
    this.hintFooter,
    this.onTechniqueTap,
  });

  @override
  Widget build(BuildContext context) {
    if (level == 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = [
      Colors.transparent,
      const Color(0xFFEBF1F8),
      const Color(0xFFC9DCEF),
      const Color(0xFF7FA8D4),
      const Color(0xFFBDE5D2),
    ];
    final accentColors = [
      Colors.transparent,
      AppColors.infoLight.withValues(alpha: 0.6),
      AppColors.infoLight,
      const Color(0xFF2A5388),
      AppColors.successLight,
    ];
    final darkBgs = [
      Colors.transparent,
      const Color(0xFF1E2733),
      const Color(0xFF243349),
      const Color(0xFF2F4769),
      const Color(0xFF1A3A2E),
    ];
    final darkAccents = [
      Colors.transparent,
      AppColors.infoDark.withValues(alpha: 0.7),
      AppColors.infoDark,
      AppColors.infoDark,
      AppColors.successDark,
    ];

    final bgColor = isDark ? darkBgs[level] : colors[level];
    final accent = isDark ? darkAccents[level] : accentColors[level];

    return AnimatedSize(
      duration: scaledDuration(context, 200),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lv.$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (technique != null) ...[
                    GestureDetector(
                      onTap: onTechniqueTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              technique!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accent,
                                decoration: onTechniqueTap != null
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            ),
                          ),
                          if (onTechniqueTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline, size: 12, color: accent),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (hintFooter != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      hintFooter!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
