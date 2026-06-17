import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';

/// 게임 홈 화면용 — 백키 2번 누르면 앱 종료
///
/// 첫 번째 백키: 토스트 메시지 표시
/// 2초 이내 두 번째 백키: 앱 종료
class BackPressExit extends StatefulWidget {
  final Widget child;

  const BackPressExit({super.key, required this.child});

  @override
  State<BackPressExit> createState() => _BackPressExitState();
}

class _BackPressExitState extends State<BackPressExit> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          // 2초 이내 두 번째 → 앱 종료
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          }
          return;
        }

        _lastBackPress = now;

        // 토스트 메시지 표시
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('backPress.exitMessage')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
          ),
        );
      },
      child: widget.child,
    );
  }
}
