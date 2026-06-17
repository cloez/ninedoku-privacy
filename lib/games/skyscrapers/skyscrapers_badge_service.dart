import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/game_storage_service.dart';
import '../../features/badges/badge_definitions.dart';
import 'skyscrapers_badge_definitions.dart';

/// Skyscrapers 배지 서비스 — 달성 평가 및 저장
class SkyscrapersBadgeService {
  static const _keyAcquiredBadges = 'skyscrapers_acquired_badges';
  final SharedPreferences _prefs;

  SkyscrapersBadgeService(this._prefs);

  /// 획득한 배지 ID 목록
  Set<String> getAcquiredBadgeIds() {
    final json = _prefs.getString(_keyAcquiredBadges);
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 게임 완료 시 새로 획득한 배지 평가
  List<BadgeDefinition> evaluateNewBadges(List<CompletedGameRecord> records) {
    final acquired = getAcquiredBadgeIds();
    final newBadges = <BadgeDefinition>[];

    for (final badge in skyscrapersBadgeDefinitions) {
      if (acquired.contains(badge.id)) continue;
      if (badge.condition.evaluate(records)) {
        newBadges.add(badge);
      }
    }

    // 새 배지 저장
    if (newBadges.isNotEmpty) {
      final updated = {...acquired, ...newBadges.map((b) => b.id)};
      _prefs.setString(_keyAcquiredBadges, jsonEncode(updated.toList()));
    }

    return newBadges;
  }

  /// 배지 복원 (백업에서)
  void restoreBadges(List<String> badgeIds) {
    final current = getAcquiredBadgeIds();
    final merged = {...current, ...badgeIds};
    _prefs.setString(_keyAcquiredBadges, jsonEncode(merged.toList()));
  }

  /// 배지 데이터 전체 삭제
  void clearAll() {
    _prefs.remove(_keyAcquiredBadges);
  }

  /// 전체 배지 목록 (획득 여부 포함)
  List<({BadgeDefinition badge, bool acquired})> getAllBadges() {
    final acquired = getAcquiredBadgeIds();
    return skyscrapersBadgeDefinitions
        .map((b) => (badge: b, acquired: acquired.contains(b.id)))
        .toList();
  }
}
