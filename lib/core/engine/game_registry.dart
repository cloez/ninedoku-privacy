import 'package:flutter/material.dart';

/// 게임 정보 클래스 — 각 게임의 메타데이터를 보유
class GameInfo {
  /// 게임 고유 식별자 (예: 'sudoku', 'binairo')
  final String id;

  /// 다국어 이름 키 (예: 'game.sudoku.name')
  final String nameKey;

  /// 다국어 설명 키 (예: 'game.sudoku.desc')
  final String descriptionKey;

  /// 게임 아이콘
  final IconData icon;

  /// 게임 이모지
  final String emoji;

  /// 라우트 경로 (예: '/', '/binairo')
  final String routePath;

  /// 표시 순서
  final int order;

  /// SVG 아이콘 에셋 경로
  final String iconAsset;

  /// NEW 배지 표시 여부
  final bool isNew;

  const GameInfo({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.icon,
    required this.emoji,
    required this.iconAsset,
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
    GameInfo(
      id: 'sudoku', nameKey: 'game.sudoku.name', descriptionKey: 'game.sudoku.desc',
      icon: Icons.grid_on_rounded, emoji: '\u{1F522}',
      iconAsset: 'assets/icons/game-sudoku.svg',
      routePath: '/', order: 0,
    ),
    GameInfo(
      id: 'binairo', nameKey: 'game.binairo.name', descriptionKey: 'game.binairo.desc',
      icon: Icons.circle_outlined, emoji: '\u{26AA}',
      iconAsset: 'assets/icons/game-binairo.svg',
      routePath: '/binairo', order: 1,
    ),
    GameInfo(
      id: 'minesweeper', nameKey: 'game.minesweeper.name', descriptionKey: 'game.minesweeper.desc',
      icon: Icons.flag_rounded, emoji: '\u{1F4A3}',
      iconAsset: 'assets/icons/game-minesweeper.svg',
      routePath: '/minesweeper', order: 2,
    ),
    GameInfo(
      id: 'yinyang', nameKey: 'game.yinyang.name', descriptionKey: 'game.yinyang.desc',
      icon: Icons.contrast_rounded, emoji: '\u{262F}',
      iconAsset: 'assets/icons/game-yinyang.svg',
      routePath: '/yin-yang', order: 3,
    ),
    GameInfo(
      id: 'nonogram', nameKey: 'game.nonogram.name', descriptionKey: 'game.nonogram.desc',
      icon: Icons.grid_view_rounded, emoji: '\u{1F5BC}',
      iconAsset: 'assets/icons/game-nonogram.svg',
      routePath: '/nonograms', order: 4,
    ),
    GameInfo(
      id: 'killerSudoku', nameKey: 'game.killerSudoku.name', descriptionKey: 'game.killerSudoku.desc',
      icon: Icons.calculate_rounded, emoji: '\u{1F522}',
      iconAsset: 'assets/icons/game-killer-sudoku.svg',
      routePath: '/killer-sudoku', order: 5,
    ),
    GameInfo(
      id: 'starBattle', nameKey: 'game.starBattle.name', descriptionKey: 'game.starBattle.desc',
      icon: Icons.star_rounded, emoji: '\u{2B50}',
      iconAsset: 'assets/icons/game-star-battle.svg',
      routePath: '/star-battle', order: 6,
    ),
    GameInfo(
      id: 'lightUp', nameKey: 'game.lightUp.name', descriptionKey: 'game.lightUp.desc',
      icon: Icons.lightbulb_rounded, emoji: '\u{1F4A1}',
      iconAsset: 'assets/icons/game-lightup.svg',
      routePath: '/light-up', order: 7,
    ),
    GameInfo(
      id: 'futoshiki', nameKey: 'game.futoshiki.name', descriptionKey: 'game.futoshiki.desc',
      icon: Icons.compare_arrows_rounded, emoji: '\u{2696}',
      iconAsset: 'assets/icons/game-futoshiki.svg',
      routePath: '/futoshiki', order: 8,
    ),
    GameInfo(
      id: 'tents', nameKey: 'game.tents.name', descriptionKey: 'game.tents.desc',
      icon: Icons.park_rounded, emoji: '\u{26FA}',
      iconAsset: 'assets/icons/game-tent.svg',
      routePath: '/tents', order: 9,
    ),
    GameInfo(
      id: 'jigsawSudoku', nameKey: 'game.jigsawSudoku.name', descriptionKey: 'game.jigsawSudoku.desc',
      icon: Icons.extension_rounded, emoji: '\u{1F9E9}',
      iconAsset: 'assets/icons/game-jigsaw-sudoku.svg',
      routePath: '/jigsaw-sudoku', order: 10,
    ),
    GameInfo(
      id: 'skyscrapers', nameKey: 'game.skyscrapers.name', descriptionKey: 'game.skyscrapers.desc',
      icon: Icons.apartment_rounded, emoji: '\u{1F3D9}',
      iconAsset: 'assets/icons/game-building.svg',
      routePath: '/skyscrapers', order: 11,
    ),
    GameInfo(
      id: 'kakuro', nameKey: 'game.kakuro.name', descriptionKey: 'game.kakuro.desc',
      icon: Icons.tag_rounded, emoji: '\u{1F522}',
      iconAsset: 'assets/icons/game-kakuro.svg',
      routePath: '/kakuro', order: 12, isNew: true,
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
