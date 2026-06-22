import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'casual_widgets.dart';

/// 체크포인트 버튼 — 공통 위젯
///
/// - 탭: 체크포인트 없으면 저장, 있으면 복원 + 자동 클리어
class CheckpointButton extends StatelessWidget {
  final bool hasCheckpoint;
  final VoidCallback onTap;
  final bool disabled;

  const CheckpointButton({
    super.key,
    required this.hasCheckpoint,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = disabled
        ? (isDark ? Colors.white24 : Colors.black26)
        : (hasCheckpoint
            ? (isDark ? Colors.amber.shade300 : Colors.amber.shade700)
            : (isDark ? Colors.white70 : Colors.black87));

    return IconButton(
      onPressed: disabled ? null : onTap,
      icon: Icon(
        hasCheckpoint ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: color,
      ),
      tooltip: hasCheckpoint
          ? AppStrings.get('checkpoint.restore')
          : AppStrings.get('checkpoint.save'),
    );
  }
}

/// 체크포인트 토스트 표시 헬퍼 (캐주얼 디자인)
void showCheckpointToast(BuildContext context, String messageKey) {
  final type = messageKey.contains('restored')
      ? KPToastType.success
      : messageKey.contains('saved')
          ? KPToastType.info
          : KPToastType.warning;
  showKPToast(context, AppStrings.get(messageKey), type: type);
}
