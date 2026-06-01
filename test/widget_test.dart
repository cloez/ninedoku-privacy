import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/main.dart';
import 'package:ninedoku/core/storage/storage_providers.dart';
import 'package:ninedoku/app/router.dart';

void main() {
  testWidgets('앱 기본 실행 스모크 테스트 — 게임 허브 표시', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'first_launch': false});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const NinedokuApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 게임 허브에 앱 타이틀 표시 확인
    expect(find.text('Ninedoku'), findsWidgets);
    // 게임 카드 표시 확인 (스도쿠)
    expect(find.text('스도쿠'), findsOneWidget);
  });

  testWidgets('앱 기본 실행 — 스도쿠 홈 직접 진입', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'first_launch': false});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          initialLocationProvider.overrideWithValue(AppRoutes.home),
        ],
        child: const NinedokuApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 스도쿠 홈 타이틀 표시 확인
    expect(find.text('스도쿠'), findsOneWidget);
    // 새 게임 버튼 존재 확인
    expect(find.text('새 게임'), findsOneWidget);
  });

  testWidgets('첫 실행 시 온보딩 화면 표시', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const NinedokuApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 온보딩 환영 텍스트 표시 확인
    expect(find.textContaining('환영합니다'), findsOneWidget);
  });
}
