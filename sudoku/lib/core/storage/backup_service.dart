import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_storage_service.dart';
import '../settings/settings_service.dart';
import '../../features/badges/badge_service.dart';
import '../../features/daily_puzzle/daily_puzzle_service.dart';

/// 백업/복원 서비스
class BackupService {
  final SharedPreferences _prefs;

  BackupService(this._prefs);

  /// 전체 데이터를 JSON으로 내보내기
  Future<String> exportToJson() async {
    final storage = GameStorageService(_prefs);
    final settings = SettingsService(_prefs);
    final badgeService = BadgeService(_prefs);
    final dailyService = DailyPuzzleService(_prefs);

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'completedGames': storage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'badges': badgeService.getAcquiredBadgeIds().toList(),
      'dailyRecords': dailyService.exportRecords(),
      'settings': {
        'language': settings.language,
        'fontScale': settings.fontScale,
        'showMistakes': settings.showMistakes,
        'showTimer': settings.showTimer,
        'soundEnabled': settings.soundEnabled,
        'vibrationEnabled': settings.vibrationEnabled,
        'customTheme': settings.customTheme,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 백업 파일 저장 (Documents 디렉토리)
  Future<File> saveBackup() async {
    final json = await exportToJson();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final file = File('${dir.path}/ninedoku_backup_$timestamp.json');
    return file.writeAsString(json);
  }

  /// JSON에서 데이터 복원
  /// [overwrite] true면 기존 데이터 삭제 후 복원, false면 추가 병합
  Future<bool> restoreFromJson(String json, {bool overwrite = false}) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      if (data['version'] != 1) return false;

      final storage = GameStorageService(_prefs);
      final settings = SettingsService(_prefs);
      final badgeService = BadgeService(_prefs);
      final dailyService = DailyPuzzleService(_prefs);

      // 덮어쓰기 모드: 기존 데이터 초기화
      if (overwrite) {
        storage.clearCompletedGames();
        badgeService.clearAll();
        dailyService.clearRecords();
      }

      // 게임 기록 복원
      if (data['completedGames'] != null) {
        final games = (data['completedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await storage.saveCompletedGame(game);
        }
      }

      // 배지 복원
      if (data['badges'] != null) {
        final badges = (data['badges'] as List).cast<String>();
        badgeService.restoreBadges(badges);
      }

      // 일일 퍼즐 기록 복원
      if (data['dailyRecords'] != null) {
        dailyService.importRecords(data['dailyRecords'] as Map<String, dynamic>);
      }

      // 설정 복원
      if (data['settings'] != null) {
        final s = data['settings'] as Map<String, dynamic>;
        if (s['language'] != null) await settings.setLanguage(s['language'] as String);
        if (s['fontScale'] != null) await settings.setFontScale((s['fontScale'] as num).toDouble());
        if (s['showMistakes'] != null) await settings.setShowMistakes(s['showMistakes'] as bool);
        if (s['showTimer'] != null) await settings.setShowTimer(s['showTimer'] as bool);
        if (s['soundEnabled'] != null) await settings.setSoundEnabled(s['soundEnabled'] as bool);
        if (s['vibrationEnabled'] != null) await settings.setVibrationEnabled(s['vibrationEnabled'] as bool);
        if (s['customTheme'] != null) await settings.setCustomTheme(s['customTheme'] as String);
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Documents 디렉토리의 백업 파일 목록 (이전 이름 호환)
  Future<List<File>> listBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') &&
            (f.path.contains('ninedoku_backup') || f.path.contains('pure_sudoku_backup') || f.path.contains('sudoku_calm_backup')))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// 내보낼 데이터가 있는지 확인
  bool hasExportableData() {
    final storage = GameStorageService(_prefs);
    final badgeService = BadgeService(_prefs);
    final dailyService = DailyPuzzleService(_prefs);
    return storage.loadCompletedGames().isNotEmpty ||
        badgeService.getAcquiredBadgeIds().isNotEmpty ||
        dailyService.exportRecords().isNotEmpty;
  }
}
