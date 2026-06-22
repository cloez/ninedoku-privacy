import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'casual_widgets.dart';

/// 게임 규칙 안내 다이얼로그
///
/// 각 게임 홈 화면 AppBar의 도움말 아이콘에서 호출.
/// `{gameKey}.about.title`, `{gameKey}.about.desc`,
/// `{gameKey}.rules.title`, `{gameKey}.rules.r1~r3` 다국어 키를 사용한다.
class GameRulesDialog {
  /// 다이얼로그 표시
  /// [gameKey] 예: 'binairo', 'minesweeper', 'yinyang', 'killerSudoku' 등
  static void show(BuildContext context, String gameKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : const Color(0xFF4A4A5A);

    showKPDialog<void>(
      context: context,
      title: AppStrings.get('$gameKey.about.title'),
      confirmLabel: AppStrings.get('close'),
      contentWidget: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.get('$gameKey.about.desc'),
              style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('$gameKey.rules.title'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF2D2D3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. ${AppStrings.get('$gameKey.rules.r1')}',
              style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              '2. ${AppStrings.get('$gameKey.rules.r2')}',
              style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              '3. ${AppStrings.get('$gameKey.rules.r3')}',
              style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
