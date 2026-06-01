import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';
import 'package:ninedoku/games/binairo/binairo_storage_service.dart';
import 'package:ninedoku/games/binairo/binairo_badge_service.dart';

/// 비나이로 저장/복구 테스트
void main() {
  late SharedPreferences prefs;
  late BinairoStorageService storage;
  late BinairoBadgeService badgeService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = BinairoStorageService(prefs);
    badgeService = BinairoBadgeService(prefs);
  });

  // ════════════════════════════════════════════════════════════════════
  // 완료 기록 저장/조회 테스트
  // ════════════════════════════════════════════════════════════════════
  group('완료 기록 저장/조회', () {
    test('완료 기록 저장 및 조회', () async {
      final record = CompletedGameRecord(
        mode: 'classic',
        difficulty: 'beginner',
        elapsedSeconds: 150,
        mistakeCount: 0,
        hintCount: 0,
        grade: 'S',
        completedAt: DateTime(2026, 6, 1, 10, 30),
      );

      await storage.saveCompletedGame(record);
      final records = storage.loadCompletedGames();

      expect(records.length, 1);
      expect(records[0].mode, 'classic');
      expect(records[0].difficulty, 'beginner');
      expect(records[0].elapsedSeconds, 150);
      expect(records[0].mistakeCount, 0);
      expect(records[0].grade, 'S');
    });

    test('여러 기록 누적 저장', () async {
      for (var i = 0; i < 5; i++) {
        await storage.saveCompletedGame(CompletedGameRecord(
          mode: i % 2 == 0 ? 'classic' : 'relax',
          difficulty: 'easy',
          elapsedSeconds: 100 + i * 50,
          mistakeCount: i,
          hintCount: 0,
          grade: 'A',
          completedAt: DateTime(2026, 6, 1 + i),
        ));
      }

      final records = storage.loadCompletedGames();
      expect(records.length, 5);
      // 순서 확인
      expect(records[0].elapsedSeconds, 100);
      expect(records[4].elapsedSeconds, 300);
    });

    test('빈 기록 목록', () {
      final records = storage.loadCompletedGames();
      expect(records, isEmpty);
    });

    test('CompletedGameRecord JSON 왕복', () {
      final record = CompletedGameRecord(
        mode: 'challenge',
        difficulty: 'master',
        elapsedSeconds: 800,
        mistakeCount: 2,
        hintCount: 1,
        grade: 'B',
        completedAt: DateTime(2026, 3, 15, 14, 0),
      );

      final json = record.toJson();
      final restored = CompletedGameRecord.fromJson(json);

      expect(restored.mode, 'challenge');
      expect(restored.difficulty, 'master');
      expect(restored.elapsedSeconds, 800);
      expect(restored.mistakeCount, 2);
      expect(restored.hintCount, 1);
      expect(restored.grade, 'B');
      expect(restored.completedAt, DateTime(2026, 3, 15, 14, 0));
    });

    test('기록 전체 삭제 (clearCompletedGames)', () async {
      // 기록 2건 저장
      await storage.saveCompletedGame(CompletedGameRecord(
        mode: 'classic',
        difficulty: 'easy',
        elapsedSeconds: 200,
        mistakeCount: 0,
        hintCount: 0,
        grade: 'S',
        completedAt: DateTime(2026, 6, 1),
      ));
      await storage.saveCompletedGame(CompletedGameRecord(
        mode: 'relax',
        difficulty: 'medium',
        elapsedSeconds: 400,
        mistakeCount: 1,
        hintCount: 0,
        grade: 'A',
        completedAt: DateTime(2026, 6, 2),
      ));

      expect(storage.loadCompletedGames().length, 2);

      // 전체 삭제
      await storage.clearCompletedGames();
      expect(storage.loadCompletedGames(), isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 배지 서비스 테스트
  // ════════════════════════════════════════════════════════════════════
  group('배지 서비스 (BinairoBadgeService)', () {
    test('배지 획득 저장/조회', () {
      // 첫 클리어 배지 조건을 충족하는 기록 생성
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'beginner',
          elapsedSeconds: 60,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime(2026, 6, 1),
        ),
      ];

      // 배지 평가
      final newBadges = badgeService.evaluateNewBadges(records);

      // 최소 첫 클리어 배지는 획득해야 함
      expect(newBadges.any((b) => b.id == 'binairo_first_clear'), true);

      // 저장된 배지 ID 확인
      final acquiredIds = badgeService.getAcquiredBadgeIds();
      expect(acquiredIds.contains('binairo_first_clear'), true);
    });

    test('배지 복원 (restoreBadges 병합)', () {
      // 기존 배지 하나 획득
      badgeService.restoreBadges(['binairo_first_clear']);
      expect(badgeService.getAcquiredBadgeIds().length, 1);

      // 추가 배지 복원 (병합)
      badgeService.restoreBadges(['binairo_speed', 'binairo_perfect']);
      final acquired = badgeService.getAcquiredBadgeIds();

      expect(acquired.length, 3);
      expect(acquired, containsAll([
        'binairo_first_clear',
        'binairo_speed',
        'binairo_perfect',
      ]));
    });

    test('배지 전체 삭제 (clearAll)', () {
      // 배지 저장
      badgeService.restoreBadges(['binairo_first_clear', 'binairo_speed']);
      expect(badgeService.getAcquiredBadgeIds().length, 2);

      // 전체 삭제
      badgeService.clearAll();
      expect(badgeService.getAcquiredBadgeIds(), isEmpty);
    });

    test('빈 상태에서 배지 조회 시 빈 Set 반환', () {
      expect(badgeService.getAcquiredBadgeIds(), isEmpty);
    });

    test('getAllBadges로 전체 배지 목록 (획득 여부 포함) 조회', () {
      // 배지 하나 획득
      badgeService.restoreBadges(['binairo_first_clear']);

      final allBadges = badgeService.getAllBadges();
      // 비나이로 배지는 10개
      expect(allBadges.length, 10);

      // 획득한 배지 확인
      final firstClear = allBadges.firstWhere(
        (b) => b.badge.id == 'binairo_first_clear',
      );
      expect(firstClear.acquired, true);

      // 미획득 배지 확인
      final speed = allBadges.firstWhere(
        (b) => b.badge.id == 'binairo_speed',
      );
      expect(speed.acquired, false);
    });

    test('이미 획득한 배지는 재평가 시 제외', () {
      final records = [
        CompletedGameRecord(
          mode: 'classic',
          difficulty: 'beginner',
          elapsedSeconds: 60,
          mistakeCount: 0,
          hintCount: 0,
          grade: 'S',
          completedAt: DateTime(2026, 6, 1),
        ),
      ];

      // 첫 번째 평가
      final firstBadges = badgeService.evaluateNewBadges(records);
      final firstIds = firstBadges.map((b) => b.id).toSet();

      // 동일 기록으로 재평가 — 새로 획득하는 배지 없어야 함
      final secondBadges = badgeService.evaluateNewBadges(records);
      expect(secondBadges, isEmpty,
          reason: '이미 획득한 배지는 재평가 시 반환되지 않아야 함');
    });
  });
}
