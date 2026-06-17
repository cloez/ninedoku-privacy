import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// 게임 규칙 안내 다이얼로그
///
/// 각 게임 홈 화면 AppBar의 도움말 아이콘에서 호출.
/// `{gameKey}.about.title`, `{gameKey}.about.desc`,
/// `{gameKey}.rules.title`, `{gameKey}.rules.r1~r3` 다국어 키를 사용한다.
class GameRulesDialog {
  /// 다이얼로그 표시
  /// [gameKey] 예: 'binairo', 'minesweeper', 'yinyang', 'killerSudoku' 등
  static void show(BuildContext context, String gameKey) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('$gameKey.about.title')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 게임 소개
              Text(AppStrings.get('$gameKey.about.desc')),
              const SizedBox(height: 16),
              // 규칙 제목
              Text(
                AppStrings.get('$gameKey.rules.title'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 규칙 항목 1~3
              Text('1. ${AppStrings.get('$gameKey.rules.r1')}'),
              const SizedBox(height: 4),
              Text('2. ${AppStrings.get('$gameKey.rules.r2')}'),
              const SizedBox(height: 4),
              Text('3. ${AppStrings.get('$gameKey.rules.r3')}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('close')),
          ),
        ],
      ),
    );
  }
}
