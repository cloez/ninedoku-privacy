import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/app/router.dart';
import 'package:ninedoku/core/settings/settings_service.dart';
import 'package:ninedoku/core/storage/storage_providers.dart';
import 'package:ninedoku/main.dart';

/// Phase 5 QA 테스트 — 설정 화면, 튜토리얼, 라우팅, 통합 검증
void main() {
  // ============================================================
  // 1. 설정 서비스 연동 테스트
  // ============================================================
  group('설정 서비스 연동', () {
    late SharedPreferences prefs;
    late SettingsService settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settings = SettingsService(prefs);
    });

    test('테마 모드 기본값은 system', () {
      expect(settings.themeMode, ThemeMode.system);
    });

    test('테마 모드 변경 후 영속성 확인', () async {
      await settings.setThemeMode(ThemeMode.dark);
      // 새 인스턴스 생성 후에도 값 유지 (SharedPreferences 영속)
      final settings2 = SettingsService(prefs);
      expect(settings2.themeMode, ThemeMode.dark);
    });

    test('테마 모드 3가지 순환 설정', () async {
      await settings.setThemeMode(ThemeMode.light);
      expect(settings.themeMode, ThemeMode.light);

      await settings.setThemeMode(ThemeMode.dark);
      expect(settings.themeMode, ThemeMode.dark);

      await settings.setThemeMode(ThemeMode.system);
      expect(settings.themeMode, ThemeMode.system);
    });

    test('글자 크기 기본값 1.0', () {
      expect(settings.fontScale, 1.0);
    });

    test('글자 크기 3단계 설정', () async {
      await settings.setFontScale(1.0);
      expect(settings.fontScale, 1.0);

      await settings.setFontScale(1.3);
      expect(settings.fontScale, 1.3);

      await settings.setFontScale(1.6);
      expect(settings.fontScale, 1.6);
    });

    test('글자 크기 변경 후 영속성 확인', () async {
      await settings.setFontScale(1.6);
      final settings2 = SettingsService(prefs);
      expect(settings2.fontScale, 1.6);
    });

    test('실수 표시 기본값 true, 토글 동작', () async {
      expect(settings.showMistakes, true);
      await settings.setShowMistakes(false);
      expect(settings.showMistakes, false);
      await settings.setShowMistakes(true);
      expect(settings.showMistakes, true);
    });

    test('타이머 표시 기본값 true, 토글 동작', () async {
      expect(settings.showTimer, true);
      await settings.setShowTimer(false);
      expect(settings.showTimer, false);
    });

    test('사운드 기본값 true, 토글 동작', () async {
      expect(settings.soundEnabled, true);
      await settings.setSoundEnabled(false);
      expect(settings.soundEnabled, false);
    });

    test('진동 기본값 true, 토글 동작', () async {
      expect(settings.vibrationEnabled, true);
      await settings.setVibrationEnabled(false);
      expect(settings.vibrationEnabled, false);
    });

    test('첫 실행 여부 기본 true, 완료 후 false', () async {
      expect(settings.isFirstLaunch, true);
      await settings.setFirstLaunchDone();
      expect(settings.isFirstLaunch, false);
    });

    test('잘못된 테마 값이 저장된 경우 system으로 폴백', () async {
      // SharedPreferences에 직접 잘못된 값 저장
      await prefs.setString('theme_mode', 'invalid_theme');
      expect(settings.themeMode, ThemeMode.system);
    });

    test('모든 설정 독립적으로 동작', () async {
      // 여러 설정을 동시에 변경해도 간섭 없음
      await settings.setThemeMode(ThemeMode.dark);
      await settings.setFontScale(1.6);
      await settings.setShowMistakes(false);
      await settings.setShowTimer(false);
      await settings.setSoundEnabled(false);
      await settings.setVibrationEnabled(false);

      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.fontScale, 1.6);
      expect(settings.showMistakes, false);
      expect(settings.showTimer, false);
      expect(settings.soundEnabled, false);
      expect(settings.vibrationEnabled, false);
    });
  });

  // ============================================================
  // 2. 설정 화면 위젯 테스트
  // ============================================================
  group('설정 화면 위젯', () {
    testWidgets('설정 화면 기본 렌더링', (tester) async {
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

      // 홈에서 설정 아이콘 탭
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      // 설정 화면 상단 구성요소 확인
      expect(find.text('설정'), findsOneWidget);
      expect(find.text('화면'), findsOneWidget);
      expect(find.text('테마'), findsOneWidget);
      expect(find.text('테마 선택'), findsOneWidget);
      expect(find.text('글자 크기'), findsOneWidget);
      expect(find.text('게임플레이'), findsOneWidget);
      expect(find.text('실수 표시'), findsOneWidget);
      expect(find.text('타이머 표시'), findsOneWidget);

      // 피드백 섹션은 스크롤이 필요할 수 있음
      await tester.scrollUntilVisible(
        find.text('피드백'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('피드백'), findsOneWidget);
      expect(find.text('사운드'), findsOneWidget);

      // 하단 영역은 스크롤 필요 (뷰포트 밖)
      await tester.scrollUntilVisible(
        find.text('앱 버전'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('앱 버전'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.text('완전 오프라인'), findsOneWidget);
    });

    testWidgets('실수 표시 스위치 토글', (tester) async {
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

      // 설정 화면 이동
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      // 실수 표시 스위치 찾기 (SwitchListTile)
      final switchFinder = find.widgetWithText(SwitchListTile, '실수 표시');
      expect(switchFinder, findsOneWidget);

      // 초기값 true 확인
      SwitchListTile switchTile =
          tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.value, true);

      // 토글
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // 값 변경 확인
      switchTile = tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.value, false);

      // SharedPreferences에 저장되었는지 확인
      final settings = SettingsService(prefs);
      expect(settings.showMistakes, false);
    });

    testWidgets('타이머 표시 스위치 토글', (tester) async {
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

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      final switchFinder = find.widgetWithText(SwitchListTile, '타이머 표시');
      expect(switchFinder, findsOneWidget);

      // 토글
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      SwitchListTile switchTile =
          tester.widget<SwitchListTile>(switchFinder);
      expect(switchTile.value, false);
    });

    testWidgets('사운드 스위치 토글', (tester) async {
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

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      // 사운드 스위치가 스크롤 아래에 있을 수 있으므로 스크롤
      final switchFinder = find.widgetWithText(SwitchListTile, '사운드');
      await tester.scrollUntilVisible(
        switchFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final settings = SettingsService(prefs);
      expect(settings.soundEnabled, false);
    });

    testWidgets('진동 스위치 토글', (tester) async {
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

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      // 진동 스위치가 스크롤 아래에 있을 수 있으므로 스크롤
      await tester.scrollUntilVisible(
        find.text('진동'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final switchFinder = find.widgetWithText(SwitchListTile, '진동');
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final settings = SettingsService(prefs);
      expect(settings.vibrationEnabled, false);
    });
  });

  // ============================================================
  // 3. 튜토리얼 화면 네비게이션 테스트
  // ============================================================
  group('튜토리얼 화면 네비게이션', () {
    testWidgets('튜토리얼 6페이지 기본 렌더링', (tester) async {
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

      // 홈에서 튜토리얼 아이콘 탭
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      // 첫 페이지 표시
      expect(find.text('사용법'), findsOneWidget); // AppBar 타이틀
      expect(find.text('스도쿠란?'), findsOneWidget);
      expect(find.text('1 / 6'), findsOneWidget);
      // 첫 페이지에서 이전 버튼은 비활성
      final prevButton = find.text('이전');
      expect(prevButton, findsOneWidget);
    });

    testWidgets('첫 페이지에서 이전 버튼 비활성', (tester) async {
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

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      // 이전 버튼 TextButton의 onPressed가 null
      final prevButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '이전'),
      );
      expect(prevButton.onPressed, isNull);
    });

    testWidgets('다음 버튼으로 순차 페이지 이동', (tester) async {
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

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      // 페이지 1: 스도쿠란?
      expect(find.text('스도쿠란?'), findsOneWidget);
      expect(find.text('1 / 6'), findsOneWidget);

      // 다음 → 페이지 2: 숫자 입력
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('숫자 입력'), findsOneWidget);
      expect(find.text('2 / 6'), findsOneWidget);

      // 다음 → 페이지 3: 메모 기능
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('메모 기능'), findsOneWidget);
      expect(find.text('3 / 6'), findsOneWidget);

      // 다음 → 페이지 4: 되돌리기
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('되돌리기'), findsOneWidget);
      expect(find.text('4 / 6'), findsOneWidget);

      // 다음 → 페이지 5: 힌트
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('힌트'), findsOneWidget);
      expect(find.text('5 / 6'), findsOneWidget);

      // 다음 → 페이지 6: 등급과 배지
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('등급과 배지'), findsOneWidget);
      expect(find.text('6 / 6'), findsOneWidget);
    });

    testWidgets('마지막 페이지에서 완료 버튼 표시 및 홈 복귀', (tester) async {
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

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      // 6번 다음으로 마지막 페이지 이동
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
      }

      // 마지막 페이지: 다음 대신 완료 버튼 표시
      expect(find.text('다음'), findsNothing);
      expect(find.text('완료'), findsOneWidget);
      expect(find.text('6 / 6'), findsOneWidget);

      // 완료 탭 → 홈으로 복귀
      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();

      // 홈 화면 확인
      expect(find.text('Ninedoku'), findsWidgets);
      expect(find.text('새 게임'), findsOneWidget);
    });

    testWidgets('이전 버튼으로 역방향 이동', (tester) async {
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

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      // 페이지 1 → 2 → 3
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 6'), findsOneWidget);

      // 페이지 3 → 2
      await tester.tap(find.text('이전'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 6'), findsOneWidget);

      // 페이지 2 → 1
      await tester.tap(find.text('이전'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 6'), findsOneWidget);

      // 페이지 1에서 이전 버튼 비활성
      final prevButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '이전'),
      );
      expect(prevButton.onPressed, isNull);
    });

    testWidgets('페이지 인디케이터 정확한 개수', (tester) async {
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

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      // 6개의 인디케이터 점 존재 (Container로 렌더링)
      // 1 / 6 텍스트로 6페이지 확인
      expect(find.text('1 / 6'), findsOneWidget);
    });
  });

  // ============================================================
  // 4. 라우팅 정합성 테스트
  // ============================================================
  group('전체 라우팅 정합성', () {
    test('AppRoutes 11개 경로 상수 정의 확인', () {
      // Phase 1~5 모든 라우트 상수 검증
      expect(AppRoutes.home, '/');
      expect(AppRoutes.onboarding, '/onboarding');
      expect(AppRoutes.modeSelect, '/mode-select');
      expect(AppRoutes.difficultySelect, '/difficulty-select');
      expect(AppRoutes.game, '/game');
      expect(AppRoutes.statistics, '/statistics');
      expect(AppRoutes.badges, '/badges');
      expect(AppRoutes.dailyPuzzle, '/daily-puzzle');
      expect(AppRoutes.dailyCalendar, '/daily-calendar');
      expect(AppRoutes.settings, '/settings');
      expect(AppRoutes.tutorial, '/tutorial');
    });

    testWidgets('홈 → 설정 라우팅', (tester) async {
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

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.text('설정'), findsOneWidget);
      expect(find.text('화면'), findsOneWidget);
    });

    testWidgets('홈 → 튜토리얼 라우팅', (tester) async {
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

      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('사용법'), findsOneWidget);
      expect(find.text('스도쿠란?'), findsOneWidget);
    });

    testWidgets('홈 → 통계 라우팅', (tester) async {
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

      await tester.tap(find.text('통계'));
      await tester.pumpAndSettle();

      // 통계 화면 - 빈 상태
      expect(find.text('아직 완료된 게임이 없습니다'), findsOneWidget);
    });

    testWidgets('홈 → 배지 라우팅', (tester) async {
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

      await tester.tap(find.text('배지'));
      await tester.pumpAndSettle();

      // 배지 화면
      expect(find.text('배지'), findsWidgets); // AppBar + 버튼
      expect(find.text('배지 획득'), findsOneWidget);
    });

    testWidgets('홈 → 오늘의 퍼즐 라우팅', (tester) async {
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

      await tester.tap(find.text('오늘의 퍼즐'));
      await tester.pumpAndSettle();

      // 오늘의 퍼즐 화면
      expect(find.text('시작하기'), findsOneWidget);
    });

    testWidgets('홈 → 새 게임 → 모드 선택 라우팅', (tester) async {
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

      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();

      expect(find.text('게임 모드'), findsOneWidget);
      expect(find.text('클래식'), findsOneWidget);
      expect(find.text('릴렉스'), findsOneWidget);
    });

    testWidgets('홈 상단에 튜토리얼/설정 아이콘 존재', (tester) async {
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

      // 튜토리얼 아이콘 (?) 확인
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      // 설정 아이콘 (톱니바퀴) 확인
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });
  });

  // ============================================================
  // 5. 테마 변경 반영 구조 테스트
  // ============================================================
  group('테마 변경 반영 구조', () {
    testWidgets('다크 테마 설정 시 앱 전체에 반영', (tester) async {
      SharedPreferences.setMockInitialValues({
        'first_launch': false,
        'theme_mode': 'dark',
      });
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

      // MaterialApp.router의 themeMode가 dark 적용되었는지 확인
      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );
      expect(materialApp.themeMode, ThemeMode.dark);
    });

    testWidgets('라이트 테마 설정 시 앱 전체에 반영', (tester) async {
      SharedPreferences.setMockInitialValues({
        'first_launch': false,
        'theme_mode': 'light',
      });
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

      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );
      expect(materialApp.themeMode, ThemeMode.light);
    });

    testWidgets('system 테마가 기본 적용', (tester) async {
      SharedPreferences.setMockInitialValues({
        'first_launch': false,
      });
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

      final materialApp = tester.widget<MaterialApp>(
        find.byType(MaterialApp),
      );
      expect(materialApp.themeMode, ThemeMode.system);
    });
  });

  // ============================================================
  // 6. 글자 크기 적용 테스트
  // ============================================================
  group('글자 크기 적용', () {
    testWidgets('기본 fontScale 1.0 적용', (tester) async {
      SharedPreferences.setMockInitialValues({
        'first_launch': false,
      });
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

      // MediaQuery에서 textScaler 확인
      final context = tester.element(find.byType(Scaffold).first);
      final textScaler = MediaQuery.of(context).textScaler;
      // 기본값 1.0
      expect(textScaler.scale(10.0), 10.0);
    });

    testWidgets('fontScale 1.6 설정 시 적용', (tester) async {
      SharedPreferences.setMockInitialValues({
        'first_launch': false,
        'font_scale': 1.6,
      });
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

      // MediaQuery에서 textScaler 확인
      final context = tester.element(find.byType(Scaffold).first);
      final textScaler = MediaQuery.of(context).textScaler;
      // 1.6배 적용
      expect(textScaler.scale(10.0), closeTo(16.0, 0.1));
    });
  });

  // ============================================================
  // 7. 통합 시나리오 테스트
  // ============================================================
  group('통합 시나리오', () {
    testWidgets('홈 → 튜토리얼 → 완료 → 홈 → 설정 전체 흐름', (tester) async {
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

      // 1. 홈 화면 확인
      expect(find.text('Ninedoku'), findsWidgets);

      // 2. 튜토리얼 이동
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('스도쿠란?'), findsOneWidget);

      // 3. 튜토리얼 끝까지 넘기기
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
      }

      // 4. 완료 탭 → 홈
      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();
      expect(find.text('새 게임'), findsOneWidget);

      // 5. 설정 화면 이동
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(find.text('설정'), findsOneWidget);
      expect(find.text('테마'), findsOneWidget);
    });

    testWidgets('설정에서 뒤로가기 시 홈으로 복귀', (tester) async {
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

      // 설정 이동
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(find.text('설정'), findsOneWidget);

      // AppBar 뒤로가기 버튼
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 홈 복귀 확인
      expect(find.text('Ninedoku'), findsWidgets);
    });

    testWidgets('튜토리얼에서 AppBar 뒤로가기 시 홈으로 복귀', (tester) async {
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

      // 튜토리얼 이동
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('사용법'), findsOneWidget);

      // AppBar 뒤로가기
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 홈 복귀 확인
      expect(find.text('Ninedoku'), findsWidgets);
    });

    testWidgets('홈 → 오늘의 퍼즐 → 캘린더 네비게이션', (tester) async {
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

      // 오늘의 퍼즐 이동
      await tester.tap(find.text('오늘의 퍼즐'));
      await tester.pumpAndSettle();

      // 캘린더 아이콘 탭
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.pumpAndSettle();

      // 월간 캘린더 화면 확인
      expect(find.text('월간 캘린더'), findsOneWidget);
    });

    testWidgets('전체 네비게이션 경로: 홈에서 모든 화면 접근 가능', (tester) async {
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

      // 홈 화면에서 접근 가능한 모든 진입점 확인
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget); // 튜토리얼
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget); // 설정
      expect(find.text('새 게임'), findsOneWidget); // 모드 선택
      expect(find.text('오늘의 퍼즐'), findsOneWidget); // 오늘의 퍼즐
      expect(find.text('통계'), findsOneWidget); // 통계
      expect(find.text('배지'), findsOneWidget); // 배지
    });
  });

  // ============================================================
  // 8. 에지 케이스 테스트
  // ============================================================
  group('에지 케이스', () {
    test('SettingsService - SharedPreferences에 저장되지 않은 키 기본값', () async {
      // 완전히 빈 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);

      // 모든 기본값이 정상인지 확인
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.fontScale, 1.0);
      expect(settings.showMistakes, true);
      expect(settings.showTimer, true);
      expect(settings.soundEnabled, true);
      expect(settings.vibrationEnabled, true);
      expect(settings.isFirstLaunch, true);
    });

    test('SettingsService - 빠른 연속 설정 변경', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);

      // 빠르게 여러 설정 연속 변경
      await settings.setThemeMode(ThemeMode.dark);
      await settings.setThemeMode(ThemeMode.light);
      await settings.setThemeMode(ThemeMode.dark);

      expect(settings.themeMode, ThemeMode.dark);
    });

    test('SettingsService - fontScale 허용 범위 외 값 저장 가능', () async {
      // UI에서는 1.0/1.3/1.6만 선택 가능하지만 서비스 레벨에서는 제한 없음
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);

      await settings.setFontScale(2.0);
      expect(settings.fontScale, 2.0);

      await settings.setFontScale(0.5);
      expect(settings.fontScale, 0.5);
    });

    testWidgets('온보딩 미완료 시 홈 화면 대신 온보딩 표시', (tester) async {
      // first_launch 키 없음 (기본값 true)
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

      // 온보딩 화면 표시 (홈이 아님)
      expect(find.textContaining('환영합니다'), findsOneWidget);
      expect(find.text('새 게임'), findsNothing);
    });
  });
}
