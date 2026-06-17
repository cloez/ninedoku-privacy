import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/game_storage_service.dart';

/// 텐트 완료 기록 저장/조회 서비스 (SharedPreferences + JSON)
class TentsStorageService {
  static const _keyCompletedGames = 'tents_completed_games';

  final SharedPreferences _prefs;

  TentsStorageService(this._prefs);

  /// 완료된 게임 기록 저장
  Future<void> saveCompletedGame(CompletedGameRecord record) async {
    try {
      final records = loadCompletedGames();
      records.add(record);
      final json = jsonEncode(records.map((r) => r.toJson()).toList());
      await _prefs.setString(_keyCompletedGames, json);
    } catch (_) {}
  }

  /// 완료된 게임 기록 목록 불러오기
  List<CompletedGameRecord> loadCompletedGames() {
    final json = _prefs.getString(_keyCompletedGames);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CompletedGameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 완료된 게임 기록 전체 삭제
  Future<void> clearCompletedGames() async {
    await _prefs.remove(_keyCompletedGames);
  }
}
