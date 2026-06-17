import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/game_storage_service.dart';

/// 음양 완료 기록 저장 서비스
class YinYangStorageService {
  static const _keyCompletedGames = 'yinyang_completed_games';
  final SharedPreferences _prefs;

  YinYangStorageService(this._prefs);

  Future<void> saveCompletedGame(CompletedGameRecord record) async {
    try {
      final records = loadCompletedGames();
      records.add(record);
      final json = jsonEncode(records.map((r) => r.toJson()).toList());
      await _prefs.setString(_keyCompletedGames, json);
    } catch (_) {}
  }

  List<CompletedGameRecord> loadCompletedGames() {
    final json = _prefs.getString(_keyCompletedGames);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCompletedGames() async {
    await _prefs.remove(_keyCompletedGames);
  }
}
