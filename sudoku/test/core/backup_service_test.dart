import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ninedoku/core/storage/backup_service.dart';
import 'package:ninedoku/core/storage/game_storage_service.dart';
import 'package:ninedoku/features/badges/badge_service.dart';
import 'package:ninedoku/features/daily_puzzle/daily_puzzle_service.dart';
import 'package:ninedoku/core/settings/settings_service.dart';

void main() {
  group('BackupService - 내보내기/가져오기 라운드트립', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    /// 테스트 데이터 생성 헬퍼
    Future<void> populateTestData(SharedPreferences p) async {
      final storage = GameStorageService(p);
      final badges = BadgeService(p);
      final daily = DailyPuzzleService(p);
      final settings = SettingsService(p);

      // 완료 게임 2건 저장
      await storage.saveCompletedGame(CompletedGameRecord(
        mode: 'classic',
        difficulty: 'easy',
        elapsedSeconds: 180,
        mistakeCount: 1,
        hintCount: 0,
        grade: 'A',
        completedAt: DateTime(2026, 5, 20, 10, 30),
      ));
      await storage.saveCompletedGame(CompletedGameRecord(
        mode: 'relax',
        difficulty: 'hard',
        elapsedSeconds: 600,
        mistakeCount: 3,
        hintCount: 2,
        grade: 'B',
        completedAt: DateTime(2026, 5, 21, 14, 0),
      ));

      // 배지 3개 직접 저장 (evaluateNewBadges 대신)
      badges.restoreBadges(['first_clear', 'no_hint_clear', 'streak_3']);

      // 오늘의 퍼즐 기록 2건
      await daily.markCompleted(DateTime(2026, 5, 20), perfect: true);
      await daily.markCompleted(DateTime(2026, 5, 21));

      // 설정 변경
      await settings.setLanguage('en');
      await settings.setFontScale(1.3);
      await settings.setShowMistakes(false);
      await settings.setShowTimer(false);
      await settings.setSoundEnabled(false);
      await settings.setVibrationEnabled(false);
      await settings.setCustomTheme('dark');
    }

    test('내보내기 JSON이 유효한 구조를 가진다', () async {
      await populateTestData(prefs);
      final service = BackupService(prefs);

      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 최상위 구조 확인
      expect(data['version'], 1);
      expect(data['exportedAt'], isNotNull);
      expect(data['completedGames'], isList);
      expect(data['badges'], isList); // Set이 아닌 List로 직렬화됨
      expect(data['dailyRecords'], isMap);
      expect(data['settings'], isMap);
    });

    test('내보내기: badges가 List로 직렬화된다 (Set 아님)', () async {
      await populateTestData(prefs);
      final service = BackupService(prefs);

      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // badges가 List 타입이어야 한다
      final badges = data['badges'];
      expect(badges, isList);
      expect(badges, containsAll(['first_clear', 'no_hint_clear', 'streak_3']));
      expect((badges as List).length, 3);
    });

    test('내보내기: 완료 게임이 올바르게 직렬화된다', () async {
      await populateTestData(prefs);
      final service = BackupService(prefs);

      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final games = data['completedGames'] as List;
      expect(games.length, 2);

      // 첫 번째 게임 필드 확인
      final g1 = games[0] as Map<String, dynamic>;
      expect(g1['mode'], 'classic');
      expect(g1['difficulty'], 'easy');
      expect(g1['elapsedSeconds'], 180);
      expect(g1['mistakeCount'], 1);
      expect(g1['hintCount'], 0);
      expect(g1['grade'], 'A');
      expect(g1['completedAt'], isNotNull);
    });

    test('내보내기: 일일 퍼즐 기록이 올바르게 직렬화된다', () async {
      await populateTestData(prefs);
      final service = BackupService(prefs);

      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final daily = data['dailyRecords'] as Map<String, dynamic>;
      expect(daily['20260520'], 'perfect');
      expect(daily['20260521'], 'completed');
    });

    test('내보내기: 설정이 올바르게 직렬화된다', () async {
      await populateTestData(prefs);
      final service = BackupService(prefs);

      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final settings = data['settings'] as Map<String, dynamic>;
      expect(settings['language'], 'en');
      expect(settings['fontScale'], 1.3);
      expect(settings['showMistakes'], false);
      expect(settings['showTimer'], false);
      expect(settings['soundEnabled'], false);
      expect(settings['vibrationEnabled'], false);
      expect(settings['customTheme'], 'dark');
    });

    test('전체 라운드트립: 내보내기 → 가져오기 → 데이터 일치', () async {
      // 1. 원본 데이터 생성 및 내보내기
      await populateTestData(prefs);
      final exportService = BackupService(prefs);
      final jsonStr = await exportService.exportToJson();

      // 2. 새 SharedPreferences로 가져오기 (빈 상태)
      SharedPreferences.setMockInitialValues({});
      final freshPrefs = await SharedPreferences.getInstance();
      final importService = BackupService(freshPrefs);

      final result = await importService.restoreFromJson(jsonStr, overwrite: true);
      expect(result, true);

      // 3. 복원된 데이터 검증
      // 3-1. 완료 게임 확인
      final storage = GameStorageService(freshPrefs);
      final games = storage.loadCompletedGames();
      expect(games.length, 2);
      expect(games[0].mode, 'classic');
      expect(games[0].difficulty, 'easy');
      expect(games[0].elapsedSeconds, 180);
      expect(games[1].mode, 'relax');
      expect(games[1].difficulty, 'hard');
      expect(games[1].elapsedSeconds, 600);

      // 3-2. 배지 확인
      final badges = BadgeService(freshPrefs);
      final badgeIds = badges.getAcquiredBadgeIds();
      expect(badgeIds, containsAll(['first_clear', 'no_hint_clear', 'streak_3']));
      expect(badgeIds.length, 3);

      // 3-3. 일일 퍼즐 기록 확인
      final daily = DailyPuzzleService(freshPrefs);
      expect(daily.isCompleted(DateTime(2026, 5, 20)), true);
      expect(daily.isPerfect(DateTime(2026, 5, 20)), true);
      expect(daily.isCompleted(DateTime(2026, 5, 21)), true);
      expect(daily.isPerfect(DateTime(2026, 5, 21)), false);

      // 3-4. 설정 확인
      final settings = SettingsService(freshPrefs);
      expect(settings.language, 'en');
      expect(settings.fontScale, 1.3);
      expect(settings.showMistakes, false);
      expect(settings.showTimer, false);
      expect(settings.soundEnabled, false);
      expect(settings.vibrationEnabled, false);
      expect(settings.customTheme, 'dark');
    });

    test('병합 모드: 기존 데이터에 추가 복원', () async {
      // 1. 기존 데이터 (배지 1개, 게임 1건)
      final existingBadges = BadgeService(prefs);
      existingBadges.restoreBadges(['existing_badge']);
      final existingStorage = GameStorageService(prefs);
      await existingStorage.saveCompletedGame(CompletedGameRecord(
        mode: 'classic',
        difficulty: 'normal',
        elapsedSeconds: 300,
        mistakeCount: 0,
        hintCount: 0,
        grade: 'S',
        completedAt: DateTime(2026, 5, 19),
      ));

      // 2. 백업 JSON 준비 (다른 데이터)
      final backupJson = jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'completedGames': [
          {
            'mode': 'relax',
            'difficulty': 'easy',
            'elapsedSeconds': 120,
            'mistakeCount': 0,
            'hintCount': 1,
            'grade': 'A',
            'completedAt': DateTime(2026, 5, 22).toIso8601String(),
          },
        ],
        'badges': ['new_badge_1', 'new_badge_2'],
        'dailyRecords': {'20260522': 'completed'},
        'settings': {'language': 'ja'},
      });

      // 3. 병합 모드로 복원 (overwrite: false)
      final service = BackupService(prefs);
      final result = await service.restoreFromJson(backupJson, overwrite: false);
      expect(result, true);

      // 4. 기존 + 새 데이터 모두 존재
      final badges = BadgeService(prefs);
      final badgeIds = badges.getAcquiredBadgeIds();
      expect(badgeIds, containsAll(['existing_badge', 'new_badge_1', 'new_badge_2']));
      expect(badgeIds.length, 3);

      // 게임은 기존 1건 + 복원 1건 = 2건
      final storage = GameStorageService(prefs);
      final games = storage.loadCompletedGames();
      expect(games.length, 2);
    });

    test('덮어쓰기 모드: 기존 데이터 삭제 후 복원', () async {
      // 1. 기존 데이터
      final existingBadges = BadgeService(prefs);
      existingBadges.restoreBadges(['old_badge']);

      // 2. 백업 JSON
      final backupJson = jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'completedGames': [],
        'badges': ['new_badge'],
        'dailyRecords': {},
        'settings': {},
      });

      // 3. 덮어쓰기 모드로 복원
      final service = BackupService(prefs);
      final result = await service.restoreFromJson(backupJson, overwrite: true);
      expect(result, true);

      // 4. 기존 배지 사라지고 새 배지만 존재
      final badges = BadgeService(prefs);
      final badgeIds = badges.getAcquiredBadgeIds();
      expect(badgeIds.contains('old_badge'), false);
      expect(badgeIds.contains('new_badge'), true);
      expect(badgeIds.length, 1);
    });

    test('빈 데이터 내보내기/가져오기도 정상 동작', () async {
      // SharedPreferences가 비어있는 상태에서 내보내기
      final service = BackupService(prefs);
      final jsonStr = await service.exportToJson();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(data['completedGames'], isEmpty);
      expect(data['badges'], isEmpty);
      expect(data['dailyRecords'], isEmpty);

      // 빈 데이터 가져오기도 성공
      final result = await service.restoreFromJson(jsonStr);
      expect(result, true);
    });

    test('잘못된 버전의 JSON은 복원 실패', () async {
      final badJson = jsonEncode({
        'version': 999,
        'exportedAt': DateTime.now().toIso8601String(),
      });

      final service = BackupService(prefs);
      final result = await service.restoreFromJson(badJson);
      expect(result, false);
    });

    test('잘못된 JSON 형식은 복원 실패', () async {
      final service = BackupService(prefs);
      final result = await service.restoreFromJson('not valid json');
      expect(result, false);
    });

    test('hasExportableData: 데이터 유무 정확히 판단', () async {
      final service = BackupService(prefs);

      // 초기 상태 - 데이터 없음
      expect(service.hasExportableData(), false);

      // 배지 추가 후 - 데이터 있음
      BadgeService(prefs).restoreBadges(['test_badge']);
      expect(service.hasExportableData(), true);
    });

    test('내보내기 JSON이 실제로 파싱 가능한 유효한 JSON이다', () async {
      await populateTestData(prefs);
      final service = BackupService(prefs);

      final jsonStr = await service.exportToJson();

      // JSON 파싱이 예외 없이 성공해야 함
      expect(() => jsonDecode(jsonStr), returnsNormally);

      // 다시 인코딩해도 성공해야 함 (Set 등 직렬화 불가 타입이 없어야 함)
      final data = jsonDecode(jsonStr);
      expect(() => jsonEncode(data), returnsNormally);
    });
  });
}
