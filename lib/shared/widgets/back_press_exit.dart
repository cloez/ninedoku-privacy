import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import 'casual_widgets.dart';

/// 게임 홈 화면용 — 백키 2번 누르면 앱 종료
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
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          }
          return;
        }

        _lastBackPress = now;
        showKPToast(
          context,
          AppStrings.get('backPress.exitMessage'),
          type: KPToastType.info,
        );
      },
      child: widget.child,
    );
  }
}
