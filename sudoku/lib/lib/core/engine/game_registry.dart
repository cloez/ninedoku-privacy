import 'package:flutter/material.dart';

/// 게임 정보 클래스 — 각 게임의 메타데이터를 보유
class GameInfo {
  /// 게임 고유 식별자 (예: 'sudoku', 'binairo')
  final String id;

  /// 다국어 키 (예: 'game.sudoku.name')
  final String nameKey;

  /// 게임 아이콘
  final IconData icon;

  /// 게임 이모지
  final String emoji;

  /// 라우트 경로 (예: '/home', '/binairo')
  final String routePath;

  /// 표시 순서
  final int order;

  /// NEW 배지 표시 여부
  final bool isNew;

  const GameInfo({
    required this.id,
    required this.nameKey,
    required this.icon,
    required this.emoji,
    required this.routePath,
    required this.order,
    this.isNew = false,
  });
}

/// 게임 레지스트리 — 등록된 모든 게임 목록 관리
class GameRegistry {
  GameRegistry._();

  /// 등록된 게임 목록 (표시 순서대로 정렬)
  static List<GameInfo> get games => List.unmodifiable(_registeredGames);

  /// 내부 게임 목록
  static const List<GameInfo> _registeredGames = [
    // 스도쿠 — 기본 게임
    GameInfo(
      id: 'sudoku',
      nameKey: 'game.sudoku.name',
      icon: Icons.grid_on_rounded,
      emoji: '\u{1F522}', // 숫자 이모지
      routePath: '/home',
      order: 0,
    ),
    // 바이네리 — 추후 추가 예정
    GameInfo(
      id: 'binairo',
      nameKey: 'game.binairo.name',
      icon: Icons.circle_outlined,
      emoji: '\u{26AA}', // 흰 동그라미 이모지
      routePath: '/binairo',
      order: 1,
      isNew: true,
    ),
  ];

  /// ID로 게임 정보 검색
  static GameInfo? findById(String id) {
    try {
      return _registeredGames.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
