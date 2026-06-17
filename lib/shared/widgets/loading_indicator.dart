import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// P1-4: 게임 로딩 인디케이터
/// generator가 1~2초 걸리는 경우 무미한 스피너 대신 "퍼즐 생성 중" 텍스트 표시
class GameLoadingScreen extends StatelessWidget {
  const GameLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('loading.generating'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
