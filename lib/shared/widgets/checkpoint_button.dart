import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// 체크포인트 버튼 — 공통 위젯
///
/// - 탭: 체크포인트 없으면 저장, 있으면 복원
/// - 길게 누르기: 체크포인트 삭제 (있을 때만)
class CheckpointButton extends StatelessWidget {
  /// 체크포인트가 저장되어 있는지
  final bool hasCheckpoint;

  /// 저장/복원 콜백
  final VoidCallback onTap;

  /// 삭제 콜백 (선택)
  final VoidCallback? onLongPress;

  /// 비활성화 여부
  final bool disabled;

  const CheckpointButton({
    super.key,
    required this.hasCheckpoint,
    required this.onTap,
    this.onLongPress,
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

    return GestureDetector(
      onLongPress: hasCheckpoint && !disabled ? onLongPress : null,
      child: IconButton(
        onPressed: disabled ? null : onTap,
        icon: Icon(
          hasCheckpoint ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: color,
        ),
        tooltip: hasCheckpoint
            ? AppStrings.get('checkpoint.restore')
            : AppStrings.get('checkpoint.save'),
      ),
    );
  }
}

/// 체크포인트 토스트 표시 헬퍼
void showCheckpointToast(BuildContext context, String messageKey) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppStrings.get(messageKey)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
    ),
  );
}
