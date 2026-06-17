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

  /// NEW 배지 표시 여부
  final bool isNew;

  const GameInfo({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
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
      descriptionKey: 'game.sudoku.desc',
      icon: Icons.grid_on_rounded,
      emoji: '\u{1F522}', // 숫자 이모지
      routePath: '/', // AppRoutes.home = '/'
      order: 0,
    ),
    // 비나이로
    GameInfo(
      id: 'binairo',
      nameKey: 'game.binairo.name',
      descriptionKey: 'game.binairo.desc',
      icon: Icons.circle_outlined,
      emoji: '\u{26AA}', // 흰 동그라미 이모지
      routePath: '/binairo',
      order: 1,
    ),
    // 지뢰찾기
    GameInfo(
      id: 'minesweeper',
      nameKey: 'game.minesweeper.name',
      descriptionKey: 'game.minesweeper.desc',
      icon: Icons.flag_rounded,
      emoji: '\u{1F4A3}', // 폭탄 이모지
      routePath: '/minesweeper',
      order: 2,
    ),
    // 음양
    GameInfo(
      id: 'yinyang',
      nameKey: 'game.yinyang.name',
      descriptionKey: 'game.yinyang.desc',
      icon: Icons.contrast_rounded,
      emoji: '\u{262F}', // ☯ 이모지
      routePath: '/yin-yang',
      order: 3,
    ),
    // 노노그램
    GameInfo(
      id: 'nonogram',
      nameKey: 'game.nonogram.name',
      descriptionKey: 'game.nonogram.desc',
      icon: Icons.grid_view_rounded,
      emoji: '\u{1F5BC}', // 액자 이모지
      routePath: '/nonograms',
      order: 4,
    ),
    // 킬러 스도쿠
    GameInfo(
      id: 'killerSudoku',
      nameKey: 'game.killerSudoku.name',
      descriptionKey: 'game.killerSudoku.desc',
      icon: Icons.calculate_rounded,
      emoji: '\u{1F522}', // 숫자 이모지
      routePath: '/killer-sudoku',
      order: 5,
    ),
    // 스타 배틀
    GameInfo(
      id: 'starBattle',
      nameKey: 'game.starBattle.name',
      descriptionKey: 'game.starBattle.desc',
      icon: Icons.star_rounded,
      emoji: '\u{2B50}', // ⭐ 이모지
      routePath: '/star-battle',
      order: 6,
    ),
    // 라이트업
    GameInfo(
      id: 'lightUp',
      nameKey: 'game.lightUp.name',
      descriptionKey: 'game.lightUp.desc',
      icon: Icons.lightbulb_rounded,
      emoji: '\u{1F4A1}', // 💡 이모지
      routePath: '/light-up',
      order: 7,
    ),
    // 후토시키
    GameInfo(
      id: 'futoshiki',
      nameKey: 'game.futoshiki.name',
      descriptionKey: 'game.futoshiki.desc',
      icon: Icons.compare_arrows_rounded,
      emoji: '\u{2696}', // ⚖️ 이모지
      routePath: '/futoshiki',
      order: 8,
    ),
    // 텐트
    GameInfo(
      id: 'tents',
      nameKey: 'game.tents.name',
      descriptionKey: 'game.tents.desc',
      icon: Icons.park_rounded,
      emoji: '\u{26FA}', // ⛺ 이모지
      routePath: '/tents',
      order: 9,
    ),
    // 직소 스도쿠
    GameInfo(
      id: 'jigsawSudoku',
      nameKey: 'game.jigsawSudoku.name',
      descriptionKey: 'game.jigsawSudoku.desc',
      icon: Icons.extension_rounded,
      emoji: '\u{1F9E9}', // 🧩 이모지
      routePath: '/jigsaw-sudoku',
      order: 10,
    ),
    // 빌딩 (Skyscrapers)
    GameInfo(
      id: 'skyscrapers',
      nameKey: 'game.skyscrapers.name',
      descriptionKey: 'game.skyscrapers.desc',
      icon: Icons.apartment_rounded,
      emoji: '\u{1F3D9}', // 🏙️ 이모지
      routePath: '/skyscrapers',
      order: 11,
    ),
    // 카쿠로 (Kakuro)
    GameInfo(
      id: 'kakuro',
      nameKey: 'game.kakuro.name',
      descriptionKey: 'game.kakuro.desc',
      icon: Icons.tag_rounded,
      emoji: '\u{1F522}', // 🔢 이모지
      routePath: '/kakuro',
      order: 12,
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
