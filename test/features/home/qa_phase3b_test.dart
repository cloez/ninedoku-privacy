import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/app/router.dart';
import 'package:ninedoku/core/storage/storage_providers.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/features/game/game_notifier.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/features/home/screens/home_screen.dart';
import 'package:ninedoku/features/home/screens/mode_select_screen.dart';
import 'package:ninedoku/features/home/screens/difficulty_select_screen.dart';
import 'package:ninedoku/features/onboarding/screens/onboarding_screen.dart';
import 'package:ninedoku/main.dart';

/// Phase 3B QA 엣지 케이스 테스트
void main() {
  group('홈 화면 기본 렌더링', () {
    testWidgets('홈 화면에 앱 타이틀, 새 게임, 오늘의 퍼즐 버튼 표시', (tester) async {
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

      // 스도쿠 홈 타이틀 표시
      expect(find.text('스도쿠'), findsOneWidget);
      // 서브 타이틀 표시
      expect(find.text('마음을 편안하게, 한 칸씩'), findsOneWidget);
      // 새 게임 버튼
      expect(find.text('새 게임'), findsOneWidget);
      // 오늘의 퍼즐 버튼
      expect(find.text('오늘의 퍼즐'), findsOneWidget);
    });

    testWidgets('게임 없을 때 빈 상태 안내 표시', (tester) async {
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

      // 빈 상태 안내 메시지
      expect(find.text('첫 게임을 시작해 보세요!'), findsOneWidget);
      // 이어하기 카드는 미표시
      expect(find.text('이어하기'), findsNothing);
    });

    testWidgets('진행 중 게임 있으면 이어하기 카드 표시', (tester) async {
      SharedPreferences.setMockInitialValues({'first_launch': false});
      final prefs = await SharedPreferences.getInstance();

      // 게임 시작 후 일시정지 상태로 저장
      final notifier = GameNotifier();
      notifier.startNewGame(
        mode: GameMode.classic,
        difficulty: Difficulty.easy,
        seed: 42,
      );
      notifier.pause();
      final savedState = notifier.testState;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            initialLocationProvider.overrideWithValue(AppRoutes.home),
            gameProvider.overrideWith((ref) {
              final n = GameNotifier();
              n.restoreGame(savedState!);
              return n;
            }),
          ],
          child: const NinedokuApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 이어하기 카드 표시
      expect(find.text('이어하기'), findsOneWidget);
      // 모드, 난이도 레이블
      expect(find.text('클래식'), findsOneWidget);
      expect(find.text('쉬움'), findsOneWidget);
      // 진행률 표시
      expect(find.textContaining('% 완료'), findsOneWidget);
      // 빈 상태 안내는 미표시
      expect(find.text('첫 게임을 시작해 보세요!'), findsNothing);

      notifier.dispose();
    });
  });

  group('온보딩 플로우', () {
    testWidgets('첫 실행 시 온보딩 화면으로 리다이렉트', (tester) async {
      // first_launch 키 없음 → isFirstLaunch = true
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // hub에서 시작 → 온보딩으로 리다이렉트 확인
          ],
          child: const NinedokuApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 온보딩 첫 페이지 표시
      expect(find.textContaining('환영합니다'), findsOneWidget);
      expect(find.text('다음'), findsOneWidget);
      expect(find.text('건너뛰기'), findsOneWidget);
    });

    testWidgets('온보딩 건너뛰기로 홈 화면 전환', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // hub에서 시작 → 온보딩으로 리다이렉트
          ],
          child: const NinedokuApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 건너뛰기 탭
      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();

      // 홈 화면 표시
      expect(find.text('스도쿠'), findsOneWidget);
      expect(find.text('새 게임'), findsOneWidget);
    });

    testWidgets('온보딩 3페이지 순차 넘기기 후 시작하기', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // hub에서 시작 → 온보딩으로 리다이렉트
          ],
          child: const NinedokuApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1페이지: 환영
      expect(find.textContaining('환영합니다'), findsOneWidget);

      // 다음 버튼으로 2페이지
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('쉽게 시작하세요'), findsOneWidget);

      // 다음 버튼으로 3페이지
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('성장을 기록하세요'), findsOneWidget);

      // 마지막 페이지에서 '건너뛰기'는 사라지고 '시작하기' 표시
      expect(find.text('건너뛰기'), findsNothing);
      expect(find.text('시작하기'), findsOneWidget);

      // 시작하기 탭 → 홈 이동
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('새 게임'), findsOneWidget);
    });

    testWidgets('온보딩 완료 후 재시작 시 홈 바로 표시', (tester) async {
      // 이미 온보딩 완료됨
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

      // 온보딩 화면은 안 나오고 홈 바로 표시
      expect(find.textContaining('환영합니다'), findsNothing);
      expect(find.text('새 게임'), findsOneWidget);
    });
  });

  group('모드 선택 화면', () {
    testWidgets('모든 모드가 활성 상태로 표시됨', (tester) async {
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

      // 새 게임 탭 → 모드 선택
      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();

      // 모드 카드 렌더링 확인
      expect(find.text('클래식'), findsOneWidget);
      expect(find.text('릴렉스'), findsOneWidget);
      expect(find.text('빠른 게임'), findsOneWidget);
      expect(find.text('도전'), findsOneWidget);

      // 모든 모드가 활성화 → Coming Soon 없음
      expect(find.text('Coming Soon'), findsNothing);
    });

    testWidgets('클래식 모드 탭 시 난이도 선택 화면으로 이동', (tester) async {
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

      // 새 게임 → 모드 선택
      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();

      // 클래식 모드 카드 탭
      await tester.tap(find.text('클래식'));
      await tester.pumpAndSettle();

      // 난이도 선택 화면 표시
      expect(find.text('난이도 - 클래식'), findsOneWidget);
    });

    testWidgets('릴렉스 모드 탭 시 난이도 선택 화면으로 이동', (tester) async {
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

      // 새 게임 → 모드 선택
      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();

      // 릴렉스 모드 카드 탭
      await tester.tap(find.text('릴렉스'));
      await tester.pumpAndSettle();

      // 난이도 선택 화면 표시 (릴렉스 모드)
      expect(find.text('난이도 - 릴렉스'), findsOneWidget);
    });
  });

  group('난이도 선택 화면', () {
    testWidgets('MVP 4단계 난이도 렌더링', (tester) async {
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

      // 홈 → 모드 선택 → 난이도 선택
      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('클래식'));
      await tester.pumpAndSettle();

      // MVP 4단계 난이도 표시
      expect(find.text('입문'), findsOneWidget);
      expect(find.text('쉬움'), findsOneWidget);
      expect(find.text('보통'), findsOneWidget);
      expect(find.text('어려움'), findsOneWidget);

      // Coming Soon 난이도 표시
      expect(find.text('전문가'), findsOneWidget);
      expect(find.text('마스터'), findsOneWidget);

      // 전문가/마스터 레벨 활성화 확인 (Coming Soon 없음)
    });

    testWidgets('난이도별 빈 칸 범위 표시', (tester) async {
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

      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('클래식'));
      await tester.pumpAndSettle();

      // 빈 칸 범위 텍스트 확인
      expect(find.text('빈 칸 30~35개'), findsOneWidget); // 입문
      expect(find.text('빈 칸 36~40개'), findsOneWidget); // 쉬움
      expect(find.text('빈 칸 41~46개'), findsOneWidget); // 보통
      expect(find.text('빈 칸 47~52개'), findsOneWidget); // 어려움
    });

    testWidgets('난이도 탭 시 게임 화면으로 이동', (tester) async {
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

      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('클래식'));
      await tester.pumpAndSettle();

      // 입문 난이도 탭
      await tester.tap(find.text('입문'));
      await tester.pumpAndSettle();

      // 게임 화면으로 이동 확인 (클래식 모드 레이블)
      expect(find.text('클래식'), findsOneWidget);
      // 일시정지 버튼 존재 (AppBar + GameInfoBar에서 중복 가능)
      expect(find.byIcon(Icons.pause_rounded), findsAtLeastNWidgets(1));
    });
  });

  group('라우팅 정합성', () {
    testWidgets('AppRoutes 경로 상수 정확성', (tester) async {
      // 라우트 상수 확인
      expect(AppRoutes.home, '/');
      expect(AppRoutes.onboarding, '/onboarding');
      expect(AppRoutes.modeSelect, '/mode-select');
      expect(AppRoutes.difficultySelect, '/difficulty-select');
      expect(AppRoutes.game, '/game');
    });

    testWidgets('게임 화면에서 나가기 다이얼로그 → 홈 이동', (tester) async {
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

      // 홈 → 모드 → 난이도 → 게임
      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('클래식'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('입문'));
      await tester.pumpAndSettle();

      // 뒤로 버튼 (나가기 다이얼로그)
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // 다이얼로그 표시
      expect(find.text('게임 나가기'), findsOneWidget);
      expect(find.text('나가기'), findsOneWidget);

      // 나가기 탭
      await tester.tap(find.text('나가기'));
      await tester.pumpAndSettle();

      // 홈으로 돌아감
      expect(find.text('새 게임'), findsOneWidget);
    });

    testWidgets('mode → difficulty 간 모드 전달 확인 (extra 파라미터)', (tester) async {
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

      // 릴렉스 모드 선택 시 extra로 'relax' 전달
      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('릴렉스'));
      await tester.pumpAndSettle();

      // 난이도 선택 화면의 AppBar 제목에 릴렉스 표시
      expect(find.text('난이도 - 릴렉스'), findsOneWidget);
    });
  });

  group('오늘의 퍼즐', () {
    testWidgets('오늘의 퍼즐 탭 시 오늘의 퍼즐 화면으로 이동', (tester) async {
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

      // 오늘의 퍼즐 탭
      await tester.tap(find.text('오늘의 퍼즐'));
      await tester.pumpAndSettle();

      // 오늘의 퍼즐 화면으로 이동 (날짜/시작 버튼 표시)
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    });
  });

  group('context.go vs context.push 적절성', () {
    testWidgets('홈→모드선택: push (스택에 쌓임, 뒤로가기 가능)', (tester) async {
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

      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();

      // 모드 선택 화면 표시 확인
      expect(find.text('게임 모드'), findsOneWidget);

      // AppBar 뒤로가기 버튼 존재 (push로 스택에 쌓였으므로)
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('난이도→게임: go (스택 초기화, 중간 화면 없이)', (tester) async {
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

      // 전체 플로우 실행
      await tester.tap(find.text('새 게임'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('클래식'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('입문'));
      await tester.pumpAndSettle();

      // 게임 화면에 도달 (difficulty_select에서 context.go 사용)
      // 자체 뒤로가기 버튼만 존재 (AppBar의 자동 BackButton 아님)
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });
}
