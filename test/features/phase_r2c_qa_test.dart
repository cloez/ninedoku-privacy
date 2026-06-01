import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninedoku/core/sudoku/difficulty.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';
import 'package:ninedoku/core/storage/statistics_service.dart';
import 'package:ninedoku/features/game/game_state.dart';
import 'package:ninedoku/features/statistics/widgets/time_trend_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===================================================================
  // 헬퍼: CompletedGameRecord 생성
  // ===================================================================
  CompletedGameRecord makeRecord({
    String difficulty = 'beginner',
    int elapsedSeconds = 300,
    int mistakeCount = 0,
    int hintCount = 0,
    String grade = 'S',
    DateTime? completedAt,
  }) {
    return CompletedGameRecord(
      mode: 'classic',
      difficulty: difficulty,
      elapsedSeconds: elapsedSeconds,
      mistakeCount: mistakeCount,
      hintCount: hintCount,
      grade: grade,
      completedAt: completedAt ?? DateTime.now(),
    );
  }

  // ===================================================================
  // Minor 9 — 차트 필터 확장
  // ===================================================================
  group('Minor 9: 차트 필터 확장', () {
    testWidgets('TimeTrendChart에 ChoiceChip이 7개 렌더링됨', (tester) async {
      // 테스트용 레코드 (최소 1개 있어야 차트 영역 표시)
      final records = [
        makeRecord(difficulty: 'beginner', elapsedSeconds: 180),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimeTrendChart(records: records),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ChoiceChip 7개가 렌더링되어야 함
      final chipFinder = find.byType(ChoiceChip);
      expect(chipFinder, findsNWidgets(7),
          reason: 'ChoiceChip이 정확히 7개여야 함 (전체, 입문, 쉬움, 보통, 어려움, 전문가, 마스터)');
    });

    testWidgets('7개 필터 텍스트가 정확히 매칭됨', (tester) async {
      final records = [
        makeRecord(difficulty: 'beginner', elapsedSeconds: 180),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimeTrendChart(records: records),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 각 필터 텍스트 확인
      const expectedLabels = ['전체', '입문', '쉬움', '보통', '어려움', '전문가', '마스터'];
      for (final label in expectedLabels) {
        expect(find.text(label), findsOneWidget,
            reason: '"$label" 필터가 존재해야 함');
      }
    });

    testWidgets('전문가 필터 탭 시 해당 난이도 레코드만 표시', (tester) async {
      // 여러 난이도 레코드 생성
      final records = [
        makeRecord(difficulty: 'beginner', elapsedSeconds: 180),
        makeRecord(difficulty: 'expert', elapsedSeconds: 1500),
        makeRecord(difficulty: 'master', elapsedSeconds: 2000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimeTrendChart(records: records),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // '전문가' 필터 탭
      await tester.tap(find.text('전문가'));
      await tester.pumpAndSettle();

      // '최근 1게임' 텍스트 확인 (expert 레코드만 1개)
      expect(find.text('최근 1게임'), findsOneWidget,
          reason: '전문가 필터 시 해당 난이도 레코드만 표시되어야 함');
    });

    testWidgets('마스터 필터 탭 시 해당 난이도 레코드만 표시', (tester) async {
      final records = [
        makeRecord(difficulty: 'beginner', elapsedSeconds: 180),
        makeRecord(difficulty: 'expert', elapsedSeconds: 1500),
        makeRecord(difficulty: 'master', elapsedSeconds: 2000),
        makeRecord(difficulty: 'master', elapsedSeconds: 2100),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimeTrendChart(records: records),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // '마스터' 필터 탭
      await tester.tap(find.text('마스터'));
      await tester.pumpAndSettle();

      // '최근 2게임' 텍스트 확인 (master 레코드 2개)
      expect(find.text('최근 2게임'), findsOneWidget,
          reason: '마스터 필터 시 해당 난이도 레코드만 표시되어야 함');
    });

    testWidgets('해당 난이도 레코드가 없으면 빈 차트 메시지 표시', (tester) async {
      final records = [
        makeRecord(difficulty: 'beginner', elapsedSeconds: 180),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimeTrendChart(records: records),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // '전문가' 필터 탭 (expert 레코드 없음)
      await tester.tap(find.text('전문가'));
      await tester.pumpAndSettle();

      expect(find.text('해당 난이도의 완료 기록이 없습니다'), findsOneWidget,
          reason: '레코드가 없는 난이도 선택 시 빈 차트 메시지 표시');
    });
  });

  // ===================================================================
  // Minor 10 — 난이도별 통계
  // ===================================================================
  group('Minor 10: 난이도별 통계', () {
    test('빈 레코드에서 getStatsByDifficulty 호출 시 totalGames = 0', () {
      final service = StatisticsService([]);
      final stats = service.getStatsByDifficulty('beginner');
      expect(stats.totalGames, equals(0),
          reason: '빈 레코드의 통계는 totalGames=0이어야 함');
    });

    test('존재하지 않는 난이도로 조회 시 totalGames = 0', () {
      final records = [
        makeRecord(difficulty: 'beginner', elapsedSeconds: 300),
      ];
      final service = StatisticsService(records);
      final stats = service.getStatsByDifficulty('expert');
      expect(stats.totalGames, equals(0),
          reason: '레코드가 없는 난이도는 totalGames=0이어야 함');
    });

    test('단일 난이도 레코드 통계 정확성', () {
      final records = [
        makeRecord(
          difficulty: 'beginner',
          elapsedSeconds: 300,
          mistakeCount: 1,
          hintCount: 2,
        ),
        makeRecord(
          difficulty: 'beginner',
          elapsedSeconds: 400,
          mistakeCount: 3,
          hintCount: 0,
        ),
      ];
      final service = StatisticsService(records);
      final stats = service.getStatsByDifficulty('beginner');

      expect(stats.totalGames, equals(2), reason: 'beginner 레코드 2개');
      expect(stats.avgTime, equals(350.0), reason: '평균 시간 (300+400)/2=350');
      expect(stats.bestTime, equals(300), reason: '최고 기록 300초');
      expect(stats.avgMistakes, equals(2.0), reason: '평균 실수 (1+3)/2=2.0');
      expect(stats.avgHints, equals(1.0), reason: '평균 힌트 (2+0)/2=1.0');
    });

    test('여러 난이도가 섞인 레코드에서 정확히 필터링', () {
      final records = [
        makeRecord(difficulty: 'beginner', elapsedSeconds: 200),
        makeRecord(difficulty: 'easy', elapsedSeconds: 400),
        makeRecord(difficulty: 'beginner', elapsedSeconds: 300),
        makeRecord(difficulty: 'hard', elapsedSeconds: 900),
        makeRecord(difficulty: 'expert', elapsedSeconds: 1500),
        makeRecord(difficulty: 'master', elapsedSeconds: 2000),
        makeRecord(difficulty: 'easy', elapsedSeconds: 500),
      ];
      final service = StatisticsService(records);

      // beginner: 2개
      expect(service.getStatsByDifficulty('beginner').totalGames, equals(2));
      // easy: 2개
      expect(service.getStatsByDifficulty('easy').totalGames, equals(2));
      // medium: 0개
      expect(service.getStatsByDifficulty('medium').totalGames, equals(0));
      // hard: 1개
      expect(service.getStatsByDifficulty('hard').totalGames, equals(1));
      // expert: 1개
      expect(service.getStatsByDifficulty('expert').totalGames, equals(1));
      // master: 1개
      expect(service.getStatsByDifficulty('master').totalGames, equals(1));
    });

    test('expert 난이도 통계의 평균/최고 기록 정확성', () {
      final records = [
        makeRecord(difficulty: 'expert', elapsedSeconds: 1200),
        makeRecord(difficulty: 'expert', elapsedSeconds: 1800),
        makeRecord(difficulty: 'expert', elapsedSeconds: 1500),
      ];
      final service = StatisticsService(records);
      final stats = service.getStatsByDifficulty('expert');

      expect(stats.totalGames, equals(3));
      expect(stats.avgTime, equals(1500.0),
          reason: '평균 (1200+1800+1500)/3=1500');
      expect(stats.bestTime, equals(1200), reason: '최고 기록 1200초');
    });

    test('master 난이도 통계의 평균/최고 기록 정확성', () {
      final records = [
        makeRecord(difficulty: 'master', elapsedSeconds: 2400),
        makeRecord(difficulty: 'master', elapsedSeconds: 2000),
      ];
      final service = StatisticsService(records);
      final stats = service.getStatsByDifficulty('master');

      expect(stats.totalGames, equals(2));
      expect(stats.avgTime, equals(2200.0),
          reason: '평균 (2400+2000)/2=2200');
      expect(stats.bestTime, equals(2000), reason: '최고 기록 2000초');
    });
  });

  // ===================================================================
  // Minor 12 — 등급 기준 표시
  // ===================================================================
  group('Minor 12: 등급 기준 표시 — gradeThresholds', () {
    test('beginner(기본) 등급 기준: bMistakes=1, cMistakes=3', () {
      final t = Grade.gradeThresholds(Difficulty.beginner);
      expect(t.bMistakes, equals(1), reason: 'beginner bMistakes=1');
      expect(t.bHints, equals(1), reason: 'beginner bHints=1');
      expect(t.cMistakes, equals(3), reason: 'beginner cMistakes=3');
      expect(t.cHints, equals(3), reason: 'beginner cHints=3');
    });

    test('easy 등급 기준: 기본값과 동일 (bMistakes=1, cMistakes=3)', () {
      final t = Grade.gradeThresholds(Difficulty.easy);
      expect(t.bMistakes, equals(1));
      expect(t.cMistakes, equals(3));
    });

    test('medium 등급 기준: 기본값과 동일 (bMistakes=1, cMistakes=3)', () {
      final t = Grade.gradeThresholds(Difficulty.medium);
      expect(t.bMistakes, equals(1));
      expect(t.cMistakes, equals(3));
    });

    test('hard 등급 기준: bMistakes=2, cMistakes=4', () {
      final t = Grade.gradeThresholds(Difficulty.hard);
      expect(t.bMistakes, equals(2), reason: 'hard bMistakes=2');
      expect(t.bHints, equals(2), reason: 'hard bHints=2');
      expect(t.cMistakes, equals(4), reason: 'hard cMistakes=4');
      expect(t.cHints, equals(4), reason: 'hard cHints=4');
    });

    test('expert 등급 기준: bMistakes=1, cMistakes=4', () {
      final t = Grade.gradeThresholds(Difficulty.expert);
      expect(t.bMistakes, equals(1), reason: 'expert bMistakes=1');
      expect(t.bHints, equals(1), reason: 'expert bHints=1');
      expect(t.cMistakes, equals(4), reason: 'expert cMistakes=4');
      expect(t.cHints, equals(4), reason: 'expert cHints=4');
    });

    test('master 등급 기준: bMistakes=1, cMistakes=3', () {
      final t = Grade.gradeThresholds(Difficulty.master);
      expect(t.bMistakes, equals(1), reason: 'master bMistakes=1');
      expect(t.bHints, equals(1), reason: 'master bHints=1');
      expect(t.cMistakes, equals(3), reason: 'master cMistakes=3');
      expect(t.cHints, equals(3), reason: 'master cHints=3');
    });

    test('null 난이도는 기본값 반환 (bMistakes=1, cMistakes=3)', () {
      final t = Grade.gradeThresholds(null);
      expect(t.bMistakes, equals(1), reason: 'null → 기본 bMistakes=1');
      expect(t.bHints, equals(1), reason: 'null → 기본 bHints=1');
      expect(t.cMistakes, equals(3), reason: 'null → 기본 cMistakes=3');
      expect(t.cHints, equals(3), reason: 'null → 기본 cHints=3');
    });

    test('고난도일수록 엄격한 등급 기준', () {
      // 기본(beginner/easy/medium) vs hard vs expert vs master
      final defaultT = Grade.gradeThresholds(Difficulty.beginner);
      final hardT = Grade.gradeThresholds(Difficulty.hard);
      final expertT = Grade.gradeThresholds(Difficulty.expert);
      final masterT = Grade.gradeThresholds(Difficulty.master);

      // hard: 빈칸 많아 더 관대한 C 기준 (cMistakes > default)
      expect(hardT.cMistakes, greaterThan(defaultT.cMistakes));

      // expert/master: 고수 전용이므로 엄격한 B 기준 (bMistakes <= hard)
      expect(expertT.bMistakes, lessThanOrEqualTo(hardT.bMistakes));
      expect(masterT.bMistakes, lessThanOrEqualTo(expertT.bMistakes));

      // master가 가장 엄격한 C 기준
      expect(masterT.cMistakes, lessThanOrEqualTo(expertT.cMistakes));
    });
  });

  // ===================================================================
  // Minor 12 — 등급 기준 표시 — baseTimeForDifficulty
  // ===================================================================
  group('Minor 12: 등급 기준 표시 — baseTimeForDifficulty', () {
    test('beginner 기준 시간 = 300초 (5분)', () {
      expect(Grade.baseTimeForDifficulty(Difficulty.beginner), equals(300));
    });

    test('easy 기준 시간 = 600초 (10분)', () {
      expect(Grade.baseTimeForDifficulty(Difficulty.easy), equals(600));
    });

    test('medium 기준 시간 = 900초 (15분)', () {
      expect(Grade.baseTimeForDifficulty(Difficulty.medium), equals(900));
    });

    test('hard 기준 시간 = 1200초 (20분)', () {
      expect(Grade.baseTimeForDifficulty(Difficulty.hard), equals(1200));
    });

    test('expert 기준 시간 = 1800초 (30분)', () {
      expect(Grade.baseTimeForDifficulty(Difficulty.expert), equals(1800));
    });

    test('master 기준 시간 = 2400초 (40분)', () {
      expect(Grade.baseTimeForDifficulty(Difficulty.master), equals(2400));
    });

    test('난이도가 올라갈수록 기준 시간이 증가', () {
      final difficulties = Difficulty.values;
      for (var i = 1; i < difficulties.length; i++) {
        final prev = Grade.baseTimeForDifficulty(difficulties[i - 1]);
        final curr = Grade.baseTimeForDifficulty(difficulties[i]);
        expect(curr, greaterThan(prev),
            reason:
                '${difficulties[i].label}(${curr}s) > ${difficulties[i - 1].label}(${prev}s)');
      }
    });
  });

  // ===================================================================
  // 공통 검증 — Grade.evaluate 통합 동작
  // ===================================================================
  group('공통 검증: Grade.evaluate 등급 산정 통합', () {
    test('expert 난이도 실수 1개 이하면 A등급', () {
      final grade = Grade.evaluate(
        mistakes: 1,
        hints: 0,
        elapsedSeconds: 2000,
        difficulty: Difficulty.expert,
      );
      expect(grade, equals(Grade.excellent),
          reason: 'expert에서 실수 1개 이하는 A등급');
    });

    test('expert 난이도 실수 4개 이하면 B등급', () {
      final grade = Grade.evaluate(
        mistakes: 3,
        hints: 0,
        elapsedSeconds: 2000,
        difficulty: Difficulty.expert,
      );
      expect(grade, equals(Grade.great),
          reason: 'expert에서 실수 2~4개는 B등급');
    });

    test('expert 난이도 실수 5개 이상이면 C등급', () {
      final grade = Grade.evaluate(
        mistakes: 5,
        hints: 0,
        elapsedSeconds: 2000,
        difficulty: Difficulty.expert,
      );
      expect(grade, equals(Grade.good),
          reason: 'expert에서 실수 5개 이상은 C등급');
    });

    test('master 난이도 실수 1개 이하면 A등급', () {
      final grade = Grade.evaluate(
        mistakes: 1,
        hints: 0,
        elapsedSeconds: 3000,
        difficulty: Difficulty.master,
      );
      expect(grade, equals(Grade.excellent),
          reason: 'master에서 실수 1개 이하는 A등급');
    });

    test('master 난이도 실수 3개 이하면 B등급', () {
      final grade = Grade.evaluate(
        mistakes: 3,
        hints: 0,
        elapsedSeconds: 3000,
        difficulty: Difficulty.master,
      );
      expect(grade, equals(Grade.great),
          reason: 'master에서 실수 2~3개는 B등급');
    });

    test('master 난이도 실수 4개 이상이면 C등급', () {
      final grade = Grade.evaluate(
        mistakes: 4,
        hints: 0,
        elapsedSeconds: 3000,
        difficulty: Difficulty.master,
      );
      expect(grade, equals(Grade.good),
          reason: 'master에서 실수 4개 이상은 C등급');
    });

    test('모든 난이도에서 실수0 힌트0 + 기준시간 이내 → S등급', () {
      for (final diff in Difficulty.values) {
        final baseTime = Grade.baseTimeForDifficulty(diff);
        final grade = Grade.evaluate(
          mistakes: 0,
          hints: 0,
          elapsedSeconds: baseTime,
          difficulty: diff,
        );
        expect(grade, equals(Grade.perfect),
            reason: '${diff.label}에서 실수0 힌트0 + 기준시간 이내 → S등급');
      }
    });

    test('실수0 힌트0이지만 기준시간 초과 → A등급', () {
      final grade = Grade.evaluate(
        mistakes: 0,
        hints: 0,
        elapsedSeconds: 999999,
        difficulty: Difficulty.beginner,
      );
      expect(grade, equals(Grade.excellent),
          reason: '시간 초과해도 실수0 힌트0이면 최소 A등급');
    });
  });
}
