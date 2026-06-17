import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';
import 'yin_yang_badge_definitions.dart';

/// 음양 배지 서비스
class YinYangBadgeService {
  static const _keyAcquiredBadges = 'yinyang_acquired_badges';
  final SharedPreferences _prefs;

  YinYangBadgeService(this._prefs);

  Set<String> getAcquiredBadgeIds() {
    final json = _prefs.getString(_keyAcquiredBadges);
    if (json == null) return {};
    try {
      return (jsonDecode(json) as List<dynamic>).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  List<BadgeDefinition> evaluateNewBadges(List<CompletedGameRecord> records) {
    final acquired = getAcquiredBadgeIds();
    final newBadges = <BadgeDefinition>[];
    for (final badge in yinYangBadgeDefinitions) {
      if (acquired.contains(badge.id)) continue;
      if (badge.condition.evaluate(records)) newBadges.add(badge);
    }
    if (newBadges.isNotEmpty) {
      final updated = {...acquired, ...newBadges.map((b) => b.id)};
      _prefs.setString(_keyAcquiredBadges, jsonEncode(updated.toList()));
    }
    return newBadges;
  }

  void restoreBadges(List<String> badgeIds) {
    final merged = {...getAcquiredBadgeIds(), ...badgeIds};
    _prefs.setString(_keyAcquiredBadges, jsonEncode(merged.toList()));
  }

  void clearAll() => _prefs.remove(_keyAcquiredBadges);

  List<({BadgeDefinition badge, bool acquired})> getAllBadges() {
    final acquired = getAcquiredBadgeIds();
    return yinYangBadgeDefinitions.map((b) => (badge: b, acquired: acquired.contains(b.id))).toList();
  }
}
