import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_storage_service.dart';
import '../settings/settings_service.dart';
import '../../features/badges/badge_service.dart';
import '../../features/daily_puzzle/daily_puzzle_service.dart';
import '../../games/binairo/binairo_storage_service.dart';
import '../../games/binairo/binairo_badge_service.dart';
import '../../games/minesweeper/minesweeper_storage_service.dart';
import '../../games/minesweeper/minesweeper_badge_service.dart';
import '../../games/yin_yang/yin_yang_storage_service.dart';
import '../../games/yin_yang/yin_yang_badge_service.dart';
import '../../games/nonograms/nonogram_storage_service.dart';
import '../../games/nonograms/nonogram_badge_service.dart';
import '../../games/killer_sudoku/killer_sudoku_storage_service.dart';
import '../../games/killer_sudoku/killer_sudoku_badge_service.dart';
import '../../games/star_battle/star_battle_storage_service.dart';
import '../../games/star_battle/star_battle_badge_service.dart';
import '../../games/light_up/light_up_storage_service.dart';
import '../../games/light_up/light_up_badge_service.dart';
import '../../games/futoshiki/futoshiki_storage_service.dart';
import '../../games/futoshiki/futoshiki_badge_service.dart';
import '../../games/tents/tents_storage_service.dart';
import '../../games/tents/tents_badge_service.dart';
import '../../games/jigsaw_sudoku/jigsaw_sudoku_storage_service.dart';
import '../../games/jigsaw_sudoku/jigsaw_sudoku_badge_service.dart';
import '../../games/skyscrapers/skyscrapers_storage_service.dart';
import '../../games/skyscrapers/skyscrapers_badge_service.dart';
import '../../games/kakuro/kakuro_storage_service.dart';
import '../../games/kakuro/kakuro_badge_service.dart';

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
    final binairoStorage = BinairoStorageService(_prefs);
    final binairoBadges = BinairoBadgeService(_prefs);
    final minesweeperStorage = MinesweeperStorageService(_prefs);
    final minesweeperBadges = MinesweeperBadgeService(_prefs);
    final yinyangStorage = YinYangStorageService(_prefs);
    final yinyangBadges = YinYangBadgeService(_prefs);
    final nonogramStorage = NonogramStorageService(_prefs);
    final nonogramBadges = NonogramBadgeService(_prefs);
    final killerSudokuStorage = KillerSudokuStorageService(_prefs);
    final killerSudokuBadges = KillerSudokuBadgeService(_prefs);
    final starBattleStorage = StarBattleStorageService(_prefs);
    final starBattleBadges = StarBattleBadgeService(_prefs);
    final lightUpStorage = LightUpStorageService(_prefs);
    final lightUpBadges = LightUpBadgeService(_prefs);
    final futoshikiStorage = FutoshikiStorageService(_prefs);
    final futoshikiBadges = FutoshikiBadgeService(_prefs);
    final tentsStorage = TentsStorageService(_prefs);
    final tentsBadges = TentsBadgeService(_prefs);
    final jigsawSudokuStorage = JigsawSudokuStorageService(_prefs);
    final jigsawSudokuBadges = JigsawSudokuBadgeService(_prefs);
    final skyscrapersStorage = SkyscrapersStorageService(_prefs);
    final skyscrapersBadges = SkyscrapersBadgeService(_prefs);
    final kakuroStorage = KakuroStorageService(_prefs);
    final kakuroBadges = KakuroBadgeService(_prefs);

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'completedGames': storage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'badges': badgeService.getAcquiredBadgeIds().toList(),
      'dailyRecords': dailyService.exportRecords(),
      // 비나이로 데이터
      'binairoCompletedGames': binairoStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'binairoBadges': binairoBadges.getAcquiredBadgeIds().toList(),
      // 지뢰찾기 데이터
      'minesweeperCompletedGames': minesweeperStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'minesweeperBadges': minesweeperBadges.getAcquiredBadgeIds().toList(),
      // 음양 데이터
      'yinyangCompletedGames': yinyangStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'yinyangBadges': yinyangBadges.getAcquiredBadgeIds().toList(),
      // 노노그램 데이터
      'nonogramCompletedGames': nonogramStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'nonogramBadges': nonogramBadges.getAcquiredBadgeIds().toList(),
      // 킬러 스도쿠 데이터
      'killerSudokuCompletedGames': killerSudokuStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'killerSudokuBadges': killerSudokuBadges.getAcquiredBadgeIds().toList(),
      // 스타 배틀 데이터
      'starBattleCompletedGames': starBattleStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'starBattleBadges': starBattleBadges.getAcquiredBadgeIds().toList(),
      // 라이트업 데이터
      'lightUpCompletedGames': lightUpStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'lightUpBadges': lightUpBadges.getAcquiredBadgeIds().toList(),
      // 후토시키 데이터
      'futoshikiCompletedGames': futoshikiStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'futoshikiBadges': futoshikiBadges.getAcquiredBadgeIds().toList(),
      // 텐트 데이터
      'tentsCompletedGames': tentsStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'tentsBadges': tentsBadges.getAcquiredBadgeIds().toList(),
      // 직소 스도쿠 데이터
      'jigsawSudokuCompletedGames': jigsawSudokuStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'jigsawSudokuBadges': jigsawSudokuBadges.getAcquiredBadgeIds().toList(),
      // 빌딩 데이터
      'skyscrapersCompletedGames': skyscrapersStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'skyscrapersBadges': skyscrapersBadges.getAcquiredBadgeIds().toList(),
      // 카쿠로 데이터
      'kakuroCompletedGames': kakuroStorage.loadCompletedGames().map((r) => r.toJson()).toList(),
      'kakuroBadges': kakuroBadges.getAcquiredBadgeIds().toList(),
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
    // 새 백업 prefix는 'kpuzzles_backup_' (기존 ninedoku_backup_도 복원 시 인식)
    final file = File('${dir.path}/kpuzzles_backup_$timestamp.json');
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
      final binairoStorage = BinairoStorageService(_prefs);
      final binairoBadges = BinairoBadgeService(_prefs);
      final minesweeperStorage = MinesweeperStorageService(_prefs);
      final minesweeperBadges = MinesweeperBadgeService(_prefs);
      final yinyangStorage = YinYangStorageService(_prefs);
      final yinyangBadges = YinYangBadgeService(_prefs);
      final nonogramStorage = NonogramStorageService(_prefs);
      final nonogramBadges = NonogramBadgeService(_prefs);
      final killerSudokuStorage = KillerSudokuStorageService(_prefs);
      final killerSudokuBadges = KillerSudokuBadgeService(_prefs);
      final starBattleStorage = StarBattleStorageService(_prefs);
      final starBattleBadges = StarBattleBadgeService(_prefs);
      final lightUpStorage = LightUpStorageService(_prefs);
      final lightUpBadges = LightUpBadgeService(_prefs);
      final futoshikiStorage = FutoshikiStorageService(_prefs);
      final futoshikiBadges = FutoshikiBadgeService(_prefs);
      final tentsStorage = TentsStorageService(_prefs);
      final tentsBadges = TentsBadgeService(_prefs);
      final jigsawSudokuStorage = JigsawSudokuStorageService(_prefs);
      final jigsawSudokuBadges = JigsawSudokuBadgeService(_prefs);
      final skyscrapersStorage = SkyscrapersStorageService(_prefs);
      final skyscrapersBadges = SkyscrapersBadgeService(_prefs);
      final kakuroStorage = KakuroStorageService(_prefs);
      final kakuroBadges = KakuroBadgeService(_prefs);

      // 덮어쓰기 모드: 기존 데이터 초기화
      if (overwrite) {
        storage.clearCompletedGames();
        badgeService.clearAll();
        dailyService.clearRecords();
        binairoStorage.clearCompletedGames();
        binairoBadges.clearAll();
        minesweeperStorage.clearCompletedGames();
        minesweeperBadges.clearAll();
        yinyangStorage.clearCompletedGames();
        yinyangBadges.clearAll();
        nonogramStorage.clearCompletedGames();
        nonogramBadges.clearAll();
        killerSudokuStorage.clearCompletedGames();
        killerSudokuBadges.clearAll();
        starBattleStorage.clearCompletedGames();
        starBattleBadges.clearAll();
        lightUpStorage.clearCompletedGames();
        lightUpBadges.clearAll();
        futoshikiStorage.clearCompletedGames();
        futoshikiBadges.clearAll();
        tentsStorage.clearCompletedGames();
        tentsBadges.clearAll();
        jigsawSudokuStorage.clearCompletedGames();
        jigsawSudokuBadges.clearAll();
        skyscrapersStorage.clearCompletedGames();
        skyscrapersBadges.clearAll();
        kakuroStorage.clearCompletedGames();
        kakuroBadges.clearAll();
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

      // 비나이로 게임 기록 복원
      if (data['binairoCompletedGames'] != null) {
        final games = (data['binairoCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await binairoStorage.saveCompletedGame(game);
        }
      }

      // 비나이로 배지 복원
      if (data['binairoBadges'] != null) {
        final badges = (data['binairoBadges'] as List).cast<String>();
        binairoBadges.restoreBadges(badges);
      }

      // 지뢰찾기 게임 기록 복원
      if (data['minesweeperCompletedGames'] != null) {
        final games = (data['minesweeperCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await minesweeperStorage.saveCompletedGame(game);
        }
      }

      // 지뢰찾기 배지 복원
      if (data['minesweeperBadges'] != null) {
        final badges = (data['minesweeperBadges'] as List).cast<String>();
        minesweeperBadges.restoreBadges(badges);
      }

      // 음양 게임 기록 복원
      if (data['yinyangCompletedGames'] != null) {
        final games = (data['yinyangCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await yinyangStorage.saveCompletedGame(game);
        }
      }

      // 음양 배지 복원
      if (data['yinyangBadges'] != null) {
        final badges = (data['yinyangBadges'] as List).cast<String>();
        yinyangBadges.restoreBadges(badges);
      }

      // 노노그램 게임 기록 복원
      if (data['nonogramCompletedGames'] != null) {
        final games = (data['nonogramCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await nonogramStorage.saveCompletedGame(game);
        }
      }

      // 노노그램 배지 복원
      if (data['nonogramBadges'] != null) {
        final badges = (data['nonogramBadges'] as List).cast<String>();
        nonogramBadges.restoreBadges(badges);
      }

      // 킬러 스도쿠 게임 기록 복원
      if (data['killerSudokuCompletedGames'] != null) {
        final games = (data['killerSudokuCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await killerSudokuStorage.saveCompletedGame(game);
        }
      }

      // 킬러 스도쿠 배지 복원
      if (data['killerSudokuBadges'] != null) {
        final badges = (data['killerSudokuBadges'] as List).cast<String>();
        killerSudokuBadges.restoreBadges(badges);
      }

      // 스타 배틀 게임 기록 복원
      if (data['starBattleCompletedGames'] != null) {
        final games = (data['starBattleCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await starBattleStorage.saveCompletedGame(game);
        }
      }

      // 스타 배틀 배지 복원
      if (data['starBattleBadges'] != null) {
        final badges = (data['starBattleBadges'] as List).cast<String>();
        starBattleBadges.restoreBadges(badges);
      }

      // 라이트업 게임 기록 복원
      if (data['lightUpCompletedGames'] != null) {
        final games = (data['lightUpCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await lightUpStorage.saveCompletedGame(game);
        }
      }

      // 라이트업 배지 복원
      if (data['lightUpBadges'] != null) {
        final badges = (data['lightUpBadges'] as List).cast<String>();
        lightUpBadges.restoreBadges(badges);
      }

      // 후토시키 게임 기록 복원
      if (data['futoshikiCompletedGames'] != null) {
        final games = (data['futoshikiCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await futoshikiStorage.saveCompletedGame(game);
        }
      }

      // 후토시키 배지 복원
      if (data['futoshikiBadges'] != null) {
        final badges = (data['futoshikiBadges'] as List).cast<String>();
        futoshikiBadges.restoreBadges(badges);
      }

      // 텐트 게임 기록 복원
      if (data['tentsCompletedGames'] != null) {
        final games = (data['tentsCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await tentsStorage.saveCompletedGame(game);
        }
      }

      // 텐트 배지 복원
      if (data['tentsBadges'] != null) {
        final badges = (data['tentsBadges'] as List).cast<String>();
        tentsBadges.restoreBadges(badges);
      }

      // 직소 스도쿠 게임 기록 복원
      if (data['jigsawSudokuCompletedGames'] != null) {
        final games = (data['jigsawSudokuCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await jigsawSudokuStorage.saveCompletedGame(game);
        }
      }

      // 직소 스도쿠 배지 복원
      if (data['jigsawSudokuBadges'] != null) {
        final badges = (data['jigsawSudokuBadges'] as List).cast<String>();
        jigsawSudokuBadges.restoreBadges(badges);
      }

      // 빌딩 게임 기록 복원
      if (data['skyscrapersCompletedGames'] != null) {
        final games = (data['skyscrapersCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await skyscrapersStorage.saveCompletedGame(game);
        }
      }

      // 빌딩 배지 복원
      if (data['skyscrapersBadges'] != null) {
        final badges = (data['skyscrapersBadges'] as List).cast<String>();
        skyscrapersBadges.restoreBadges(badges);
      }

      // 카쿠로 게임 기록 복원
      if (data['kakuroCompletedGames'] != null) {
        final games = (data['kakuroCompletedGames'] as List)
            .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final game in games) {
          await kakuroStorage.saveCompletedGame(game);
        }
      }

      // 카쿠로 배지 복원
      if (data['kakuroBadges'] != null) {
        final badges = (data['kakuroBadges'] as List).cast<String>();
        kakuroBadges.restoreBadges(badges);
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
            (f.path.contains('kpuzzles_backup') || f.path.contains('ninedoku_backup') || f.path.contains('pure_sudoku_backup') || f.path.contains('sudoku_calm_backup')))
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// 내보낼 데이터가 있는지 확인
  bool hasExportableData() {
    final storage = GameStorageService(_prefs);
    final badgeService = BadgeService(_prefs);
    final dailyService = DailyPuzzleService(_prefs);
    final binairoStorage = BinairoStorageService(_prefs);
    final binairoBadges = BinairoBadgeService(_prefs);
    final minesweeperStorage = MinesweeperStorageService(_prefs);
    final minesweeperBadges = MinesweeperBadgeService(_prefs);
    final yinyangStorage = YinYangStorageService(_prefs);
    final yinyangBadges = YinYangBadgeService(_prefs);
    final nonogramStorage = NonogramStorageService(_prefs);
    final nonogramBadges = NonogramBadgeService(_prefs);
    final killerSudokuStorage = KillerSudokuStorageService(_prefs);
    final killerSudokuBadges = KillerSudokuBadgeService(_prefs);
    final starBattleStorage = StarBattleStorageService(_prefs);
    final starBattleBadges = StarBattleBadgeService(_prefs);
    final lightUpStorage = LightUpStorageService(_prefs);
    final lightUpBadges = LightUpBadgeService(_prefs);
    final futoshikiStorage = FutoshikiStorageService(_prefs);
    final futoshikiBadges = FutoshikiBadgeService(_prefs);
    final tentsStorage = TentsStorageService(_prefs);
    final tentsBadges = TentsBadgeService(_prefs);
    final jigsawSudokuStorage = JigsawSudokuStorageService(_prefs);
    final jigsawSudokuBadges = JigsawSudokuBadgeService(_prefs);
    final skyscrapersStorage = SkyscrapersStorageService(_prefs);
    final skyscrapersBadges = SkyscrapersBadgeService(_prefs);
    final kakuroStorage = KakuroStorageService(_prefs);
    final kakuroBadges = KakuroBadgeService(_prefs);
    return storage.loadCompletedGames().isNotEmpty ||
        badgeService.getAcquiredBadgeIds().isNotEmpty ||
        dailyService.exportRecords().isNotEmpty ||
        binairoStorage.loadCompletedGames().isNotEmpty ||
        binairoBadges.getAcquiredBadgeIds().isNotEmpty ||
        minesweeperStorage.loadCompletedGames().isNotEmpty ||
        minesweeperBadges.getAcquiredBadgeIds().isNotEmpty ||
        yinyangStorage.loadCompletedGames().isNotEmpty ||
        yinyangBadges.getAcquiredBadgeIds().isNotEmpty ||
        nonogramStorage.loadCompletedGames().isNotEmpty ||
        nonogramBadges.getAcquiredBadgeIds().isNotEmpty ||
        killerSudokuStorage.loadCompletedGames().isNotEmpty ||
        killerSudokuBadges.getAcquiredBadgeIds().isNotEmpty ||
        starBattleStorage.loadCompletedGames().isNotEmpty ||
        starBattleBadges.getAcquiredBadgeIds().isNotEmpty ||
        lightUpStorage.loadCompletedGames().isNotEmpty ||
        lightUpBadges.getAcquiredBadgeIds().isNotEmpty ||
        futoshikiStorage.loadCompletedGames().isNotEmpty ||
        futoshikiBadges.getAcquiredBadgeIds().isNotEmpty ||
        tentsStorage.loadCompletedGames().isNotEmpty ||
        tentsBadges.getAcquiredBadgeIds().isNotEmpty ||
        jigsawSudokuStorage.loadCompletedGames().isNotEmpty ||
        jigsawSudokuBadges.getAcquiredBadgeIds().isNotEmpty ||
        skyscrapersStorage.loadCompletedGames().isNotEmpty ||
        skyscrapersBadges.getAcquiredBadgeIds().isNotEmpty ||
        kakuroStorage.loadCompletedGames().isNotEmpty ||
        kakuroBadges.getAcquiredBadgeIds().isNotEmpty;
  }
}
