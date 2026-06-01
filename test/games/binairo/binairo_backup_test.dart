import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/core/storage/backup_service.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';
import 'package:ninedoku/games/binairo/binairo_storage_service.dart';
import 'package:ninedoku/games/binairo/binairo_badge_service.dart';
import 'package:ninedoku/features/badges/badge_service.dart';

/// 비나이로 백업 통합 테스트
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// 비나이로 테스트 데이터 생성 헬퍼
  Future<void> populateBinairoData(SharedPreferences p) async {
    final binairoStorage = BinairoStorageService(p);
    final binairoBadges = BinairoBadgeService(p);

    // 비나이로 완료 기록 2건
    await binairoStorage.saveCompletedGame(CompletedGameRecord(
      mode: 'classic',
      difficulty: 'beginner',
      elapsedSeconds: 90,
      mistakeCount: 0,
      hintCount: 0,
      grade: 'S',
      completedAt: DateTime(2026, 6, 1, 10, 0),
    ));
    await binairoStorage.saveCompletedGame(CompletedGameRecord(
      mode: 'challenge',
      difficulty: 'medium',
      elapsedSeconds: 360,
      mistakeCount: 1,
      hintCount: 0,
      grade: 'A',
      completedAt: DateTime(2026, 6, 2, 14, 30),
    ));

    // 비나이로 배지 2개
    binairoBadges.restoreBadges(['binairo_first_clear', 'binairo_speed']);
  }

  /// 스도쿠 + 비나이로 혼합 데이터 생성 헬퍼
  Future<void> populateMixedData(SharedPreferences p) async {
    // 스도쿠 데이터
    final sudokuStorage = GameStorageService(p);
    await sudokuStorage.saveCompletedGame(CompletedGameRecord(
      mode: 'classic',
      difficulty: 'easy',
      elapsedSeconds: 300,
      mistakeCount: 1,
      hintCount: 0,
      grade: 'A',
      completedAt: DateTime(2026, 5, 30, 9, 0),
    ));
    final sudokuBadges = BadgeService(p);
    sudokuBadges.restoreBadges(['first_clear', 'no_hint']);

    // 비나이로 데이터
    await populateBinairoData(p);
  }

  // ════════════════════════════════════════════════════════════════════
  // 백업 내보내기 구조 테스트
  // ════════════════════════════════════════════════════════════════════
  group('백업 내보내기 구조', () {
    test('내보내기 JSON에 binairoCompletedGames 키 존재', () async {
      await populateBinairoData(prefs);
      final service = BackupService(prefs);

      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(data.containsKey('binairoCompletedGames'), true);
      final games = data['binairoCompletedGames'] as List;
      expect(games.length, 2);

      // 첫 번째 기록 필드 확인
      final g1 = games[0] as Map<String, dynamic>;
      expect(g1['mode'], 'classic');
      expect(g1['difficulty'], 'beginner');
      expect(g1['elapsedSeconds'], 90);
      expect(g1['grade'], 'S');
    });

    test('내보내기 JSON에 binairoBadges 키 존재', () async {
      await populateBinairoData(prefs);
      final service = BackupService(prefs);

      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(data.containsKey('binairoBadges'), true);
      final badges = data['binairoBadges'] as List;
      expect(badges.length, 2);
      expect(badges, containsAll(['binairo_first_clear', 'binairo_speed']));
    });
  });

  // ════════════════════════════════════════════════════════════════════
  // 라운드트립 테스트
  // ════════════════════════════════════════════════════════════════════
  group('백업 라운드트립', () {
    test('비나이로 데이터 내보내기 -> 가져오기 -> 일치', () async {
      // 1. 원본 데이터 생성 및 내보내기
      await populateBinairoData(prefs);
      final exportService = BackupService(prefs);
      final jsonStr = await exportService.exportToJson();

      // 2. 새 SharedPreferences로 가져오기
      SharedPreferences.setMockInitialValues({});
      final freshPrefs = await SharedPreferences.getInstance();
      final importService = BackupService(freshPrefs);

      final result = await importService.restoreFromJson(jsonStr, overwrite: true);
      expect(result, true);

      // 3. 복원된 비나이로 데이터 검증
      final binairoStorage = BinairoStorageService(freshPrefs);
      final games = binairoStorage.loadCompletedGames();
      expect(games.length, 2);
      expect(games[0].mode, 'classic');
      expect(games[0].difficulty, 'beginner');
      expect(games[0].elapsedSeconds, 90);
      expect(games[1].mode, 'challenge');
      expect(games[1].difficulty, 'medium');
      expect(games[1].elapsedSeconds, 360);

      // 배지 검증
      final binairoBadges = BinairoBadgeService(freshPrefs);
      final badgeIds = binairoBadges.getAcquiredBadgeIds();
      expect(badgeIds.length, 2);
      expect(badgeIds, containsAll(['binairo_first_clear', 'binairo_speed']));
    });

    test('덮어쓰기 모드에서 비나이로 데이터 삭제 후 복원', () async {
      // 1. 기존 비나이로 데이터
      final existingBinairoStorage = BinairoStorageService(prefs);
      await existingBinairoStorage.saveCompletedGame(CompletedGameRecord(
        mode: 'relax',
        difficulty: 'hard',
        elapsedSeconds: 500,
        mistakeCount: 3,
        hintCount: 2,
        grade: 'C',
        completedAt: DateTime(2026, 5, 28),
      ));
      final existingBinairoBadges = BinairoBadgeService(prefs);
      existingBinairoBadges.restoreBadges(['binairo_master']);

      // 2. 새 데이터로 덮어쓰기할 백업 JSON
      final backupJson = jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'completedGames': [],
        'badges': [],
        'dailyRecords': {},
        'binairoCompletedGames': [
          {
            'mode': 'classic',
            'difficulty': 'beginner',
            'elapsedSeconds': 100,
            'mistakeCount': 0,
            'hintCount': 0,
            'grade': 'S',
            'completedAt': DateTime(2026, 6, 1).toIso8601String(),
          },
        ],
        'binairoBadges': ['binairo_first_clear'],
        'settings': {},
      });

      // 3. 덮어쓰기 모드로 복원
      final service = BackupService(prefs);
      final result = await service.restoreFromJson(backupJson, overwrite: true);
      expect(result, true);

      // 4. 기존 데이터 삭제되고 새 데이터만 존재
      final binairoStorage = BinairoStorageService(prefs);
      final games = binairoStorage.loadCompletedGames();
      expect(games.length, 1);
      expect(games[0].mode, 'classic');
      expect(games[0].elapsedSeconds, 100);

      final binairoBadges = BinairoBadgeService(prefs);
      final badgeIds = binairoBadges.getAcquiredBadgeIds();
      expect(badgeIds.contains('binairo_master'), false); // 기존 배지 삭제됨
      expect(badgeIds.contains('binairo_first_clear'), true);
      expect(badgeIds.length, 1);
    });

    test('빈 비나이로 데이터 내보내기/가져오기', () async {
      // 비나이로 데이터 없는 상태에서 내보내기
      final service = BackupService(prefs);
      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(data['binairoCompletedGames'], isEmpty);
      expect(data['binairoBadges'], isEmpty);

      // 빈 데이터 가져오기도 성공
      SharedPreferences.setMockInitialValues({});
      final freshPrefs = await SharedPreferences.getInstance();
      final importService = BackupService(freshPrefs);
      final result = await importService.restoreFromJson(jsonStr, overwrite: true);
      expect(result, true);

      // 복원 후에도 비어있어야 함
      final binairoStorage = BinairoStorageService(freshPrefs);
      expect(binairoStorage.loadCompletedGames(), isEmpty);
      final binairoBadges = BinairoBadgeService(freshPrefs);
      expect(binairoBadges.getAcquiredBadgeIds(), isEmpty);
    });

    test('스도쿠 + 비나이로 혼합 백업 라운드트립', () async {
      // 1. 스도쿠 + 비나이로 데이터 모두 생성
      await populateMixedData(prefs);
      final exportService = BackupService(prefs);
      final jsonStr = await exportService.exportToJson();

      // 2. 새 환경으로 가져오기
      SharedPreferences.setMockInitialValues({});
      final freshPrefs = await SharedPreferences.getInstance();
      final importService = BackupService(freshPrefs);
      final result = await importService.restoreFromJson(jsonStr, overwrite: true);
      expect(result, true);

      // 3. 스도쿠 데이터 검증
      final sudokuStorage = GameStorageService(freshPrefs);
      final sudokuGames = sudokuStorage.loadCompletedGames();
      expect(sudokuGames.length, 1);
      expect(sudokuGames[0].mode, 'classic');
      expect(sudokuGames[0].elapsedSeconds, 300);

      final sudokuBadges = BadgeService(freshPrefs);
      final sudokuBadgeIds = sudokuBadges.getAcquiredBadgeIds();
      expect(sudokuBadgeIds, containsAll(['first_clear', 'no_hint']));

      // 4. 비나이로 데이터 검증
      final binairoStorage = BinairoStorageService(freshPrefs);
      final binairoGames = binairoStorage.loadCompletedGames();
      expect(binairoGames.length, 2);
      expect(binairoGames[0].mode, 'classic');
      expect(binairoGames[1].mode, 'challenge');

      final binairoBadges = BinairoBadgeService(freshPrefs);
      final binairoBadgeIds = binairoBadges.getAcquiredBadgeIds();
      expect(binairoBadgeIds, containsAll(['binairo_first_clear', 'binairo_speed']));
    });
  });
}
