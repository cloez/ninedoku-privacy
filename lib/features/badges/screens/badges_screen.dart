import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../badge_definitions.dart';
import '../badge_service.dart';

/// 배지 화면 (S-11) — 전체/스도쿠/비나이로/지뢰찾기/음양/노노그램 탭 지원
class BadgesScreen extends ConsumerStatefulWidget {
  /// 초기 탭: null → 0(전체), 'sudoku' → 1, 'binairo' → 2, 'minesweeper' → 3, 'yinyang' → 4, 'nonogram' → 5
  final String? initialTab;

  const BadgesScreen({super.key, this.initialTab});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  // 스도쿠 배지 ID → 로컬라이즈 키 매핑
  static const _sudokuBadgeKeyMap = {
    'first_clear': 'firstClear',
    'no_hint': 'noHint',
    'no_mistake': 'noMistake',
    'perfect': 'perfect',
    'speed_5min': 'speed5min',
    'games_10': 'games10',
    'games_50': 'games50',
    'games_100': 'games100',
    'streak_3': 'streak3',
    'streak_7': 'streak7',
    'diff_hard': 'diffHard',
    'diff_expert': 'diffExpert',
    'diff_master': 'diffMaster',
    'streak_30': 'streak30',
  };

  /// 비나이로 배지 ID 목록
  static const _binairoBadgeIds = [
    'binairo_first_clear',
    'binairo_games_10',
    'binairo_games_50',
    'binairo_speed',
    'binairo_perfect',
    'binairo_no_hint',
    'binairo_master',
    'binairo_challenge',
    'binairo_streak_3',
    'binairo_all_s',
  ];

  /// 지뢰찾기 배지 ID 목록
  static const _minesweeperBadgeIds = [
    'minesweeper_first_sweep',
    'minesweeper_mine_hunter',
    'minesweeper_speed_sweeper',
    'minesweeper_flag_master',
    'minesweeper_logic_expert',
    'minesweeper_daily_sweeper',
    'minesweeper_no_hint_10',
    'minesweeper_hard_clear',
    'minesweeper_master_sweep',
    'minesweeper_mine_100',
  ];

  /// 지뢰찾기 배지 이모지 매핑
  static const _minesweeperIcons = {
    'minesweeper_first_sweep': '🔰',
    'minesweeper_mine_hunter': '🎯',
    'minesweeper_speed_sweeper': '⚡',
    'minesweeper_flag_master': '⚑',
    'minesweeper_logic_expert': '🧠',
    'minesweeper_daily_sweeper': '📅',
    'minesweeper_no_hint_10': '💪',
    'minesweeper_hard_clear': '🏔️',
    'minesweeper_master_sweep': '🏆',
    'minesweeper_mine_100': '💎',
  };

  /// 비나이로 배지 임시 이모지 매핑
  static const _binairoIcons = {
    'binairo_first_clear': '🎯',
    'binairo_games_10': '🔥',
    'binairo_games_50': '⭐',
    'binairo_speed': '⚡',
    'binairo_perfect': '🏆',
    'binairo_no_hint': '💡',
    'binairo_master': '💎',
    'binairo_challenge': '🎖️',
    'binairo_streak_3': '📅',
    'binairo_all_s': '🌟',
  };

  /// 음양 배지 ID 목록
  static const _yinYangBadgeIds = [
    'yinyang_first',
    'yinyang_10',
    'yinyang_speed',
    'yinyang_perfect',
    'yinyang_nohint',
    'yinyang_daily',
    'yinyang_streak5',
    'yinyang_hard',
    'yinyang_master',
    'yinyang_100',
  ];

  /// 음양 배지 이모지 매핑
  static const _yinYangIcons = {
    'yinyang_first': '☯️',
    'yinyang_10': '🔥',
    'yinyang_speed': '⚡',
    'yinyang_perfect': '🏆',
    'yinyang_nohint': '💡',
    'yinyang_daily': '📅',
    'yinyang_streak5': '💪',
    'yinyang_hard': '🏔️',
    'yinyang_master': '💎',
    'yinyang_100': '👑',
  };

  /// 노노그램 배지 ID 목록
  static const _nonogramBadgeIds = [
    'nono_first',
    'nono_10',
    'nono_speed',
    'nono_perfect',
    'nono_nohint',
    'nono_daily',
    'nono_streak5',
    'nono_hard',
    'nono_master15',
    'nono_100',
  ];

  /// 노노그램 배지 이모지 매핑
  static const _nonogramIcons = {
    'nono_first': '🎯',
    'nono_10': '🔥',
    'nono_speed': '⚡',
    'nono_perfect': '🏆',
    'nono_nohint': '💡',
    'nono_daily': '📅',
    'nono_streak5': '🗓️',
    'nono_hard': '🎖️',
    'nono_master15': '💎',
    'nono_100': '👑',
  };

  /// 킬러 스도쿠 배지 ID 목록
  static const _killerSudokuBadgeIds = [
    'killer_first',
    'killer_10',
    'killer_speed',
    'killer_perfect',
    'killer_nohint',
    'killer_daily',
    'killer_streak5',
    'killer_hard',
    'killer_master',
    'killer_100',
  ];

  /// 킬러 스도쿠 배지 이모지 매핑
  static const _killerSudokuIcons = {
    'killer_first': '🎯',
    'killer_10': '🔥',
    'killer_speed': '⚡',
    'killer_perfect': '🏆',
    'killer_nohint': '💡',
    'killer_daily': '📅',
    'killer_streak5': '🗓️',
    'killer_hard': '🏔️',
    'killer_master': '💎',
    'killer_100': '👑',
  };

  /// 스타 배틀 배지 ID 목록
  static const _starBattleBadgeIds = [
    'star_first',
    'star_10',
    'star_speed',
    'star_perfect',
    'star_nohint',
    'star_daily',
    'star_streak5',
    'star_hard',
    'star_master',
    'star_100',
  ];

  /// 스타 배틀 배지 이모지 매핑
  static const _starBattleIcons = {
    'star_first': '⭐',
    'star_10': '🔥',
    'star_speed': '⚡',
    'star_perfect': '🏆',
    'star_nohint': '💡',
    'star_daily': '📅',
    'star_streak5': '🗓️',
    'star_hard': '🎖️',
    'star_master': '💎',
    'star_100': '👑',
  };

  /// 라이트업 배지 ID 목록
  static const _lightUpBadgeIds = [
    'lightup_first',
    'lightup_10',
    'lightup_speed',
    'lightup_perfect',
    'lightup_nohint',
    'lightup_daily',
    'lightup_streak5',
    'lightup_hard',
    'lightup_master',
    'lightup_100',
  ];

  /// 후토시키 배지 ID 목록
  static const _futoshikiBadgeIds = [
    'futoshiki_first',
    'futoshiki_10',
    'futoshiki_speed',
    'futoshiki_perfect',
    'futoshiki_nohint',
    'futoshiki_daily',
    'futoshiki_streak5',
    'futoshiki_hard',
    'futoshiki_master',
    'futoshiki_100',
  ];

  /// 직소 스도쿠 배지 ID 목록
  static const _jigsawSudokuBadgeIds = [
    'jigsaw_first',
    'jigsaw_10',
    'jigsaw_speed',
    'jigsaw_perfect',
    'jigsaw_nohint',
    'jigsaw_daily',
    'jigsaw_streak5',
    'jigsaw_hard',
    'jigsaw_master',
    'jigsaw_100',
  ];

  /// 빌딩 배지 ID 목록
  static const _skyscrapersBadgeIds = [
    'sky_first',
    'sky_10',
    'sky_speed',
    'sky_perfect',
    'sky_nohint',
    'sky_daily',
    'sky_streak5',
    'sky_hard',
    'sky_master',
    'sky_100',
  ];

  /// 빌딩 배지 이모지 매핑
  static const _skyscrapersIcons = {
    'sky_first': '🏙️',
    'sky_10': '🔥',
    'sky_speed': '⚡',
    'sky_perfect': '🏆',
    'sky_nohint': '💡',
    'sky_daily': '📅',
    'sky_streak5': '📆',
    'sky_hard': '🎖️',
    'sky_master': '💎',
    'sky_100': '🌟',
  };

  /// 카쿠로 배지 ID 목록
  static const _kakuroBadgeIds = [
    'kakuro_first',
    'kakuro_10',
    'kakuro_speed',
    'kakuro_perfect',
    'kakuro_nohint',
    'kakuro_daily',
    'kakuro_streak5',
    'kakuro_hard',
    'kakuro_master',
    'kakuro_100',
  ];

  /// 카쿠로 배지 이모지 매핑
  static const _kakuroIcons = {
    'kakuro_first': '🔢',
    'kakuro_10': '🔥',
    'kakuro_speed': '⚡',
    'kakuro_perfect': '🏆',
    'kakuro_nohint': '💡',
    'kakuro_daily': '📅',
    'kakuro_streak5': '📆',
    'kakuro_hard': '🎖️',
    'kakuro_master': '💎',
    'kakuro_100': '🌟',
  };

  /// 직소 스도쿠 배지 이모지 매핑
  static const _jigsawSudokuIcons = {
    'jigsaw_first': '🧩',
    'jigsaw_10': '🔥',
    'jigsaw_speed': '⚡',
    'jigsaw_perfect': '🏆',
    'jigsaw_nohint': '💡',
    'jigsaw_daily': '📅',
    'jigsaw_streak5': '🗓️',
    'jigsaw_hard': '🏔️',
    'jigsaw_master': '💎',
    'jigsaw_100': '👑',
  };

  /// 텐트 배지 ID 목록
  static const _tentsBadgeIds = [
    'tents_first',
    'tents_10',
    'tents_speed',
    'tents_perfect',
    'tents_nohint',
    'tents_daily',
    'tents_streak5',
    'tents_hard',
    'tents_master',
    'tents_100',
  ];

  /// 텐트 배지 이모지 매핑
  static const _tentsIcons = {
    'tents_first': '⛺',
    'tents_10': '🔥',
    'tents_speed': '⚡',
    'tents_perfect': '🏆',
    'tents_nohint': '💡',
    'tents_daily': '📅',
    'tents_streak5': '🗓️',
    'tents_hard': '🎖️',
    'tents_master': '💎',
    'tents_100': '👑',
  };

  /// 후토시키 배지 이모지 매핑
  static const _futoshikiIcons = {
    'futoshiki_first': '⚖️',
    'futoshiki_10': '🔥',
    'futoshiki_speed': '⚡',
    'futoshiki_perfect': '🏆',
    'futoshiki_nohint': '💡',
    'futoshiki_daily': '📅',
    'futoshiki_streak5': '🗓️',
    'futoshiki_hard': '🎖️',
    'futoshiki_master': '💎',
    'futoshiki_100': '👑',
  };

  /// 라이트업 배지 이모지 매핑
  static const _lightUpIcons = {
    'lightup_first': '💡',
    'lightup_10': '🔥',
    'lightup_speed': '⚡',
    'lightup_perfect': '🏆',
    'lightup_nohint': '💪',
    'lightup_daily': '📅',
    'lightup_streak5': '🗓️',
    'lightup_hard': '🎖️',
    'lightup_master': '💎',
    'lightup_100': '👑',
  };

  /// 초기 탭 인덱스 변환
  int get _initialIndex {
    switch (widget.initialTab) {
      case 'sudoku':
        return 1;
      case 'binairo':
        return 2;
      case 'minesweeper':
        return 3;
      case 'yinyang':
        return 4;
      case 'nonogram':
        return 5;
      case 'killerSudoku':
        return 6;
      case 'starBattle':
        return 7;
      case 'lightUp':
        return 8;
      case 'futoshiki':
        return 9;
      case 'tents':
        return 10;
      case 'jigsawSudoku':
        return 11;
      case 'skyscrapers':
        return 12;
      case 'kakuro':
        return 13;
      default:
        return 0;
    }
  }

  /// SharedPreferences에서 빌딩 획득 배지 ID 로드
  Set<String> _loadSkyscrapersAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('skyscrapers_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 빌딩 배지 아이템 리스트 생성
  List<_BadgeItem> _buildSkyscrapersBadgeItems(Set<String> acquiredIds) {
    return _skyscrapersBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _skyscrapersIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'skyscrapers',
      );
    }).toList();
  }

  /// SharedPreferences에서 카쿠로 획득 배지 ID 로드
  Set<String> _loadKakuroAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('kakuro_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 카쿠로 배지 아이템 리스트 생성
  List<_BadgeItem> _buildKakuroBadgeItems(Set<String> acquiredIds) {
    return _kakuroBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _kakuroIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'kakuro',
      );
    }).toList();
  }

  /// SharedPreferences에서 직소 스도쿠 획득 배지 ID 로드
  Set<String> _loadJigsawSudokuAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('jigsaw_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 직소 스도쿠 배지 아이템 리스트 생성
  List<_BadgeItem> _buildJigsawSudokuBadgeItems(Set<String> acquiredIds) {
    return _jigsawSudokuBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _jigsawSudokuIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'jigsawSudoku',
      );
    }).toList();
  }

  /// SharedPreferences에서 텐트 획득 배지 ID 로드
  Set<String> _loadTentsAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('tents_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 텐트 배지 아이템 리스트 생성
  List<_BadgeItem> _buildTentsBadgeItems(Set<String> acquiredIds) {
    return _tentsBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _tentsIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'tents',
      );
    }).toList();
  }

  /// SharedPreferences에서 후토시키 획득 배지 ID 로드
  Set<String> _loadFutoshikiAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('futoshiki_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 후토시키 배지 아이템 리스트 생성
  List<_BadgeItem> _buildFutoshikiBadgeItems(Set<String> acquiredIds) {
    return _futoshikiBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _futoshikiIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'futoshiki',
      );
    }).toList();
  }

  /// SharedPreferences에서 라이트업 획득 배지 ID 로드
  Set<String> _loadLightUpAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('lightup_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 라이트업 배지 아이템 리스트 생성
  List<_BadgeItem> _buildLightUpBadgeItems(Set<String> acquiredIds) {
    return _lightUpBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _lightUpIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'lightUp',
      );
    }).toList();
  }

  /// SharedPreferences에서 킬러 스도쿠 획득 배지 ID 로드
  Set<String> _loadKillerSudokuAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('killer_sudoku_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 킬러 스도쿠 배지 아이템 리스트 생성
  List<_BadgeItem> _buildKillerSudokuBadgeItems(Set<String> acquiredIds) {
    return _killerSudokuBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _killerSudokuIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'killerSudoku',
      );
    }).toList();
  }

  /// SharedPreferences에서 스타 배틀 획득 배지 ID 로드
  Set<String> _loadStarBattleAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('starbattle_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 스타 배틀 배지 아이템 리스트 생성
  List<_BadgeItem> _buildStarBattleBadgeItems(Set<String> acquiredIds) {
    return _starBattleBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _starBattleIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'starBattle',
      );
    }).toList();
  }

  /// SharedPreferences에서 노노그램 획득 배지 ID 로드
  Set<String> _loadNonogramAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('nonogram_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 노노그램 배지 아이템 리스트 생성
  List<_BadgeItem> _buildNonogramBadgeItems(Set<String> acquiredIds) {
    return _nonogramBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _nonogramIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'nonogram',
      );
    }).toList();
  }

  /// SharedPreferences에서 지뢰찾기 획득 배지 ID 로드
  Set<String> _loadMinesweeperAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('minesweeper_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 지뢰찾기 배지 아이템 리스트 생성
  List<_BadgeItem> _buildMinesweeperBadgeItems(Set<String> acquiredIds) {
    return _minesweeperBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _minesweeperIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'minesweeper',
      );
    }).toList();
  }

  /// SharedPreferences에서 비나이로 획득 배지 ID 로드
  Set<String> _loadBinairoAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('binairo_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// SharedPreferences에서 음양 획득 배지 ID 로드
  Set<String> _loadYinYangAcquiredIds(SharedPreferences prefs) {
    final json = prefs.getString('yinyang_acquired_badges');
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// 음양 배지 아이템 리스트 생성
  List<_BadgeItem> _buildYinYangBadgeItems(Set<String> acquiredIds) {
    return _yinYangBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _yinYangIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'yinyang',
      );
    }).toList();
  }

  /// 비나이로 배지 아이템 리스트 생성
  List<_BadgeItem> _buildBinairoBadgeItems(Set<String> acquiredIds) {
    return _binairoBadgeIds.map((id) {
      return _BadgeItem(
        id: id,
        name: AppStrings.get('badge.$id.name'),
        description: AppStrings.get('badge.$id.desc'),
        icon: _binairoIcons[id] ?? '🔒',
        acquired: acquiredIds.contains(id),
        gameType: 'binairo',
      );
    }).toList();
  }

  /// 스도쿠 배지 아이템 리스트 생성
  List<_BadgeItem> _buildSudokuBadgeItems(BadgeService badgeService) {
    final allBadges = badgeService.getAllBadges();
    return allBadges.map((item) {
      final key = _sudokuBadgeKeyMap[item.badge.id];
      return _BadgeItem(
        id: item.badge.id,
        name: key != null ? AppStrings.get('badge.$key') : item.badge.name,
        description: key != null ? AppStrings.get('badge.$key.desc') : item.badge.description,
        icon: item.badge.icon,
        acquired: item.acquired,
        gameType: 'sudoku',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final badgeService = BadgeService(prefs);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 스도쿠 배지
    final sudokuBadges = _buildSudokuBadgeItems(badgeService);
    // 비나이로 배지
    final binairoAcquired = _loadBinairoAcquiredIds(prefs);
    final binairoBadges = _buildBinairoBadgeItems(binairoAcquired);
    // 지뢰찾기 배지
    final minesweeperAcquired = _loadMinesweeperAcquiredIds(prefs);
    final minesweeperBadges = _buildMinesweeperBadgeItems(minesweeperAcquired);
    // 음양 배지
    final yinyangAcquired = _loadYinYangAcquiredIds(prefs);
    final yinyangBadges = _buildYinYangBadgeItems(yinyangAcquired);
    // 노노그램 배지
    final nonogramAcquired = _loadNonogramAcquiredIds(prefs);
    final nonogramBadges = _buildNonogramBadgeItems(nonogramAcquired);
    // 킬러 스도쿠 배지
    final killerSudokuAcquired = _loadKillerSudokuAcquiredIds(prefs);
    final killerSudokuBadges = _buildKillerSudokuBadgeItems(killerSudokuAcquired);
    // 스타 배틀 배지
    final starBattleAcquired = _loadStarBattleAcquiredIds(prefs);
    final starBattleBadges = _buildStarBattleBadgeItems(starBattleAcquired);
    // 라이트업 배지
    final lightUpAcquired = _loadLightUpAcquiredIds(prefs);
    final lightUpBadges = _buildLightUpBadgeItems(lightUpAcquired);
    // 후토시키 배지
    final futoshikiAcquired = _loadFutoshikiAcquiredIds(prefs);
    final futoshikiBadges = _buildFutoshikiBadgeItems(futoshikiAcquired);
    // 텐트 배지
    final tentsAcquired = _loadTentsAcquiredIds(prefs);
    final tentsBadges = _buildTentsBadgeItems(tentsAcquired);
    // 직소 스도쿠 배지
    final jigsawSudokuAcquired = _loadJigsawSudokuAcquiredIds(prefs);
    final jigsawSudokuBadges = _buildJigsawSudokuBadgeItems(jigsawSudokuAcquired);
    // 빌딩 배지
    final skyscrapersAcquired = _loadSkyscrapersAcquiredIds(prefs);
    final skyscrapersBadges = _buildSkyscrapersBadgeItems(skyscrapersAcquired);
    // 카쿠로 배지
    final kakuroAcquired = _loadKakuroAcquiredIds(prefs);
    final kakuroBadges = _buildKakuroBadgeItems(kakuroAcquired);
    // 전체 배지
    final allBadges = [...sudokuBadges, ...binairoBadges, ...minesweeperBadges, ...yinyangBadges, ...nonogramBadges, ...killerSudokuBadges, ...starBattleBadges, ...lightUpBadges, ...futoshikiBadges, ...tentsBadges, ...jigsawSudokuBadges, ...skyscrapersBadges, ...kakuroBadges];

    return DefaultTabController(
      length: 14,
      initialIndex: _initialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('badges.title')),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: AppStrings.get('badge.tab.all')),
              Tab(text: AppStrings.get('badge.tab.sudoku')),
              Tab(text: AppStrings.get('badge.tab.binairo')),
              Tab(text: AppStrings.get('badge.tab.minesweeper')),
              Tab(text: AppStrings.get('badge.tab.yinyang')),
              Tab(text: AppStrings.get('badge.tab.nonogram')),
              Tab(text: AppStrings.get('badge.tab.killerSudoku')),
              Tab(text: AppStrings.get('badge.tab.starBattle')),
              Tab(text: AppStrings.get('badge.tab.lightUp')),
              Tab(text: AppStrings.get('badge.tab.futoshiki')),
              Tab(text: AppStrings.get('badge.tab.tents')),
              Tab(text: AppStrings.get('badge.tab.jigsawSudoku')),
              Tab(text: AppStrings.get('badge.tab.skyscrapers')),
              Tab(text: AppStrings.get('badge.tab.kakuro')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 전체 탭
            _BadgesContent(badges: allBadges, isDark: isDark),
            // 스도쿠 탭
            _BadgesContent(badges: sudokuBadges, isDark: isDark),
            // 비나이로 탭
            _BadgesContent(badges: binairoBadges, isDark: isDark),
            // 지뢰찾기 탭
            _BadgesContent(badges: minesweeperBadges, isDark: isDark),
            // 음양 탭
            _BadgesContent(badges: yinyangBadges, isDark: isDark),
            // 노노그램 탭
            _BadgesContent(badges: nonogramBadges, isDark: isDark),
            // 킬러 스도쿠 탭
            _BadgesContent(badges: killerSudokuBadges, isDark: isDark),
            // 스타 배틀 탭
            _BadgesContent(badges: starBattleBadges, isDark: isDark),
            // 라이트업 탭
            _BadgesContent(badges: lightUpBadges, isDark: isDark),
            // 후토시키 탭
            _BadgesContent(badges: futoshikiBadges, isDark: isDark),
            // 텐트 탭
            _BadgesContent(badges: tentsBadges, isDark: isDark),
            // 직소 스도쿠 탭
            _BadgesContent(badges: jigsawSudokuBadges, isDark: isDark),
            // 빌딩 탭
            _BadgesContent(badges: skyscrapersBadges, isDark: isDark),
            // 카쿠로 탭
            _BadgesContent(badges: kakuroBadges, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

/// 내부 배지 데이터 모델 (스도쿠/비나이로 공통)
class _BadgeItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool acquired;
  final String gameType; // 'sudoku' 또는 'binairo'

  const _BadgeItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.acquired,
    required this.gameType,
  });
}

/// 배지 콘텐츠 (각 탭에서 재사용)
class _BadgesContent extends StatelessWidget {
  final List<_BadgeItem> badges;
  final bool isDark;

  const _BadgesContent({required this.badges, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final acquiredCount = badges.where((b) => b.acquired).length;
    // P1-10: 획득한 배지가 하나도 없을 때 빈 상태 안내 표시
    final allEmpty = badges.isNotEmpty && acquiredCount == 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 획득 요약
        _AcquiredSummary(
          acquired: acquiredCount,
          total: badges.length,
          isDark: isDark,
        ),
        // 빈 상태 안내 (모든 배지가 미획득일 때)
        if (allEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('badges.emptyHint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        // 배지 그리드
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final item = badges[index];
              return _BadgeTile(
                badge: item,
                isDark: isDark,
                onTap: () => _showBadgeDetail(context, item, isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 배지 상세 다이얼로그
  void _showBadgeDetail(BuildContext context, _BadgeItem badge, bool isDark) {
    showKPDialog<void>(
      context: context,
      title: badge.name,
      confirmLabel: AppStrings.get('confirm'),
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.acquired ? badge.icon : '🔒',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge.acquired
                ? AppStrings.get('badges.acquiredDone')
                : AppStrings.get('badges.notAcquired'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: badge.acquired ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// 획득 요약 헤더
class _AcquiredSummary extends StatelessWidget {
  final int acquired;
  final int total;
  final bool isDark;

  const _AcquiredSummary({
    required this.acquired,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? acquired / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '$acquired / $total',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.get('badges.acquired'),
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 배지 타일
class _BadgeTile extends StatelessWidget {
  final _BadgeItem badge;
  final bool isDark;
  final VoidCallback onTap;

  const _BadgeTile({
    required this.badge,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: badge.acquired ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.acquired ? badge.icon : '🔒',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
