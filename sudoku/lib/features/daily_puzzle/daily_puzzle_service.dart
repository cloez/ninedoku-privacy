import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 오늘의 퍼즐 완료 기록 관리
class DailyPuzzleService {
  static const _keyDailyRecords = 'daily_puzzle_records';
  final SharedPreferences _prefs;

  DailyPuzzleService(this._prefs);

  /// 날짜 키 생성 (yyyyMMdd)
  static String dateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// 오늘의 퍼즐 seed 생성
  static int seedForDate(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// 완료된 날짜 기록 저장
  Future<void> markCompleted(DateTime date, {bool perfect = false}) async {
    final records = _loadRecords();
    final key = dateKey(date);
    records[key] = perfect ? 'perfect' : 'completed';
    await _prefs.setString(_keyDailyRecords, jsonEncode(records));
  }

  /// 특정 날짜 완료 여부
  bool isCompleted(DateTime date) {
    final records = _loadRecords();
    return records.containsKey(dateKey(date));
  }

  /// 특정 날짜 퍼펙트 여부
  bool isPerfect(DateTime date) {
    final records = _loadRecords();
    return records[dateKey(date)] == 'perfect';
  }

  /// 특정 월의 기록 맵 반환 {day: status}
  Map<int, String> getMonthRecords(int year, int month) {
    final records = _loadRecords();
    final result = <int, String>{};

    for (final entry in records.entries) {
      if (entry.key.length != 8) continue;
      final y = int.tryParse(entry.key.substring(0, 4));
      final m = int.tryParse(entry.key.substring(4, 6));
      final d = int.tryParse(entry.key.substring(6, 8));
      if (y == year && m == month && d != null) {
        result[d] = entry.value;
      }
    }
    return result;
  }

  /// 총 완료 수
  int get totalCompleted => _loadRecords().length;

  /// 백업용 내보내기
  Map<String, dynamic> exportRecords() {
    return Map<String, dynamic>.from(_loadRecords());
  }

  /// 기록 전체 삭제 (백업 덮어쓰기용)
  void clearRecords() {
    _prefs.remove(_keyDailyRecords);
  }

  /// 백업에서 복원
  void importRecords(Map<String, dynamic> data) {
    final current = _loadRecords();
    for (final entry in data.entries) {
      current[entry.key] = entry.value as String;
    }
    _prefs.setString(_keyDailyRecords, jsonEncode(current));
  }

  /// 내부: 기록 로드
  Map<String, String> _loadRecords() {
    final json = _prefs.getString(_keyDailyRecords);
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }
}
