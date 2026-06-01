import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/game/game_state.dart';

/// 게임 상태 저장/복구 서비스 (SharedPreferences + JSON)
class GameStorageService {
  static const _keyCurrentGame = 'current_game';
  static const _keyCompletedGames = 'completed_games';

  final SharedPreferences _prefs;

  GameStorageService(this._prefs);

  /// 현재 진행 중인 게임 저장
  Future<void> saveCurrentGame(GameState state) async {
    final json = jsonEncode(state.toJson());
    await _prefs.setString(_keyCurrentGame, json);
  }

  /// 저장된 진행 중 게임 불러오기
  GameState? loadCurrentGame() {
    final json = _prefs.getString(_keyCurrentGame);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return GameState.fromJson(map);
    } catch (_) {
      // 파싱 실패 시 저장 데이터 삭제
      _prefs.remove(_keyCurrentGame);
      return null;
    }
  }

  /// 진행 중 게임 삭제
  Future<void> deleteCurrentGame() async {
    await _prefs.remove(_keyCurrentGame);
  }

  /// 완료된 게임 기록 저장
  Future<void> saveCompletedGame(CompletedGameRecord record) async {
    final records = loadCompletedGames();
    records.add(record);
    final json = jsonEncode(records.map((r) => r.toJson()).toList());
    await _prefs.setString(_keyCompletedGames, json);
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

  /// 완료된 게임 기록 전체 삭제 (백업 덮어쓰기용)
  Future<void> clearCompletedGames() async {
    await _prefs.remove(_keyCompletedGames);
  }

  /// 진행 중 게임 존재 여부
  bool hasCurrentGame() {
    return _prefs.containsKey(_keyCurrentGame);
  }
}

/// 완료된 게임 기록
class CompletedGameRecord {
  final String mode;
  final String difficulty;
  final int elapsedSeconds;
  final int mistakeCount;
  final int hintCount;
  final String grade;
  final DateTime completedAt;

  const CompletedGameRecord({
    required this.mode,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.mistakeCount,
    required this.hintCount,
    required this.grade,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'difficulty': difficulty,
        'elapsedSeconds': elapsedSeconds,
        'mistakeCount': mistakeCount,
        'hintCount': hintCount,
        'grade': grade,
        'completedAt': completedAt.toIso8601String(),
      };

  factory CompletedGameRecord.fromJson(Map<String, dynamic> json) {
    return CompletedGameRecord(
      mode: json['mode'] as String,
      difficulty: json['difficulty'] as String,
      elapsedSeconds: json['elapsedSeconds'] as int,
      mistakeCount: json['mistakeCount'] as int,
      hintCount: json['hintCount'] as int,
      grade: json['grade'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}
