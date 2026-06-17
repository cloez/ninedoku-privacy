import 'package:flutter/material.dart';
import 'models/tutorial_models.dart';

/// 13게임 튜토리얼 레지스트리
///
/// 각 게임의 단계별 컨텐츠 정의.
/// 스도쿠만 5단계 + 인터랙티브 연습.
/// 다른 12게임은 핵심 3~5단계 (S1 목표 / S2 기본규칙 / S3 보조규칙 / S4 조작).
class TutorialRegistry {
  TutorialRegistry._();

  /// gameId로 튜토리얼 조회 (null이면 미정의)
  static GameTutorial? forGame(String gameId) {
    return _tutorials[gameId];
  }

  /// 정의된 모든 게임 ID 목록
  static List<String> get allGameIds => _tutorials.keys.toList();

  static final Map<String, GameTutorial> _tutorials = {
    // ===== 스도쿠 (5단계 + 인터랙티브 연습) =====
    'sudoku': GameTutorial(
      gameId: 'sudoku',
      steps: [
        // S1: 게임 소개
        const TutorialStep(
          titleKey: 'tutorial.sudoku.step1.title',
          descriptionKey: 'tutorial.sudoku.step1.description',
          illustration: MiniBoardIllustration(
            gameId: 'sudoku',
            board: [
              [5, 3, 7],
              [6, 1, 9],
              [2, 8, 4],
            ],
            overlay: OverlayKind.okMark,
          ),
        ),
        // S2: 행과 열
        const TutorialStep(
          titleKey: 'tutorial.sudoku.step2.title',
          descriptionKey: 'tutorial.sudoku.step2.description',
          illustration: MiniBoardIllustration(
            gameId: 'sudoku',
            board: [
              [1, 2, 3],
              [4, 5, 6],
              [7, 8, 9],
            ],
            highlights: [
              CellHighlight(0, 0, HighlightStyle.info),
              CellHighlight(0, 1, HighlightStyle.info),
              CellHighlight(0, 2, HighlightStyle.info),
            ],
          ),
        ),
        // S3: 3×3 박스
        const TutorialStep(
          titleKey: 'tutorial.sudoku.step3.title',
          descriptionKey: 'tutorial.sudoku.step3.description',
          illustration: MiniBoardIllustration(
            gameId: 'sudoku',
            board: [
              [5, 3, 7],
              [6, 1, 9],
              [2, 8, 4],
            ],
            highlights: [
              CellHighlight(0, 0, HighlightStyle.success),
              CellHighlight(0, 1, HighlightStyle.success),
              CellHighlight(0, 2, HighlightStyle.success),
              CellHighlight(1, 0, HighlightStyle.success),
              CellHighlight(1, 1, HighlightStyle.success),
              CellHighlight(1, 2, HighlightStyle.success),
              CellHighlight(2, 0, HighlightStyle.success),
              CellHighlight(2, 1, HighlightStyle.success),
              CellHighlight(2, 2, HighlightStyle.success),
            ],
          ),
        ),
        // S4: 조작 방법
        const TutorialStep(
          titleKey: 'tutorial.sudoku.step4.title',
          descriptionKey: 'tutorial.sudoku.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
        // S5: 연습 — 4×4 미니 스도쿠
        const TutorialStep(
          titleKey: 'tutorial.sudoku.step5.title',
          descriptionKey: 'tutorial.sudoku.step5.description',
          illustration: MiniBoardIllustration(
            gameId: 'sudoku',
            board: [
              [1, null, 3, 2],
              [3, 2, 4, 1],
              [2, 4, 1, 3],
              [4, 3, 2, null],
            ],
            highlights: [CellHighlight(0, 1, HighlightStyle.target)],
          ),
          practice: InteractivePractice(
            gameId: 'sudoku',
            initialBoard: [
              [1, null, 3, 2],
              [3, 2, 4, 1],
              [2, 4, 1, 3],
              [4, 3, 2, null],
            ],
            target: CellTarget(0, 1),
            correctValue: 4,
            hintKey: 'tutorial.sudoku.step5.hint',
          ),
        ),
      ],
    ),

    // ===== Binairo (4단계) =====
    'binairo': const GameTutorial(
      gameId: 'binairo',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.binairo.step1.title',
          descriptionKey: 'tutorial.binairo.step1.description',
          illustration: MiniBoardIllustration(
            gameId: 'binairo',
            board: [
              [0, 1, 0, 1],
              [1, 0, 1, 0],
              [0, 1, 1, 0],
              [1, 0, 0, 1],
            ],
            overlay: OverlayKind.okMark,
          ),
        ),
        TutorialStep(
          titleKey: 'tutorial.binairo.step2.title',
          descriptionKey: 'tutorial.binairo.step2.description',
          illustration: IconIllustration(Icons.balance_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.binairo.step3.title',
          descriptionKey: 'tutorial.binairo.step3.description',
          illustration: MiniBoardIllustration(
            gameId: 'binairo',
            board: [
              [1, 1, 1, 0],
              [0, 0, 1, 1],
              [1, 0, 0, 1],
              [0, 1, 0, 0],
            ],
            highlights: [
              CellHighlight(0, 0, HighlightStyle.error),
              CellHighlight(0, 1, HighlightStyle.error),
              CellHighlight(0, 2, HighlightStyle.error),
            ],
            overlay: OverlayKind.errorMark,
          ),
        ),
        TutorialStep(
          titleKey: 'tutorial.binairo.step4.title',
          descriptionKey: 'tutorial.binairo.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Minesweeper (5단계) =====
    'minesweeper': const GameTutorial(
      gameId: 'minesweeper',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.minesweeper.step1.title',
          descriptionKey: 'tutorial.minesweeper.step1.description',
          illustration: IconIllustration(Icons.dangerous_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.minesweeper.step2.title',
          descriptionKey: 'tutorial.minesweeper.step2.description',
          illustration: IconIllustration(Icons.format_list_numbered_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.minesweeper.step3.title',
          descriptionKey: 'tutorial.minesweeper.step3.description',
          illustration: IconIllustration(Icons.flag_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.minesweeper.step4.title',
          descriptionKey: 'tutorial.minesweeper.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.minesweeper.step5.title',
          descriptionKey: 'tutorial.minesweeper.step5.description',
          illustration: IconIllustration(Icons.emoji_events_rounded),
        ),
      ],
    ),

    // ===== Yin-Yang (4단계) =====
    'yinyang': const GameTutorial(
      gameId: 'yinyang',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.yinyang.step1.title',
          descriptionKey: 'tutorial.yinyang.step1.description',
          illustration: IconIllustration(Icons.contrast_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.yinyang.step2.title',
          descriptionKey: 'tutorial.yinyang.step2.description',
          illustration: IconIllustration(Icons.account_tree_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.yinyang.step3.title',
          descriptionKey: 'tutorial.yinyang.step3.description',
          illustration: IconIllustration(Icons.grid_view_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.yinyang.step4.title',
          descriptionKey: 'tutorial.yinyang.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Nonograms (5단계) =====
    'nonogram': const GameTutorial(
      gameId: 'nonogram',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.nonogram.step1.title',
          descriptionKey: 'tutorial.nonogram.step1.description',
          illustration: IconIllustration(Icons.image_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.nonogram.step2.title',
          descriptionKey: 'tutorial.nonogram.step2.description',
          illustration: IconIllustration(Icons.format_list_numbered_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.nonogram.step3.title',
          descriptionKey: 'tutorial.nonogram.step3.description',
          illustration: IconIllustration(Icons.space_bar_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.nonogram.step4.title',
          descriptionKey: 'tutorial.nonogram.step4.description',
          illustration: IconIllustration(Icons.close_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.nonogram.step5.title',
          descriptionKey: 'tutorial.nonogram.step5.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Killer Sudoku (5단계) =====
    'killerSudoku': const GameTutorial(
      gameId: 'killerSudoku',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.killerSudoku.step1.title',
          descriptionKey: 'tutorial.killerSudoku.step1.description',
          illustration: IconIllustration(Icons.calculate_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.killerSudoku.step2.title',
          descriptionKey: 'tutorial.killerSudoku.step2.description',
          illustration: IconIllustration(Icons.grid_on_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.killerSudoku.step3.title',
          descriptionKey: 'tutorial.killerSudoku.step3.description',
          illustration: IconIllustration(Icons.add_box_outlined),
        ),
        TutorialStep(
          titleKey: 'tutorial.killerSudoku.step4.title',
          descriptionKey: 'tutorial.killerSudoku.step4.description',
          illustration: IconIllustration(Icons.block_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.killerSudoku.step5.title',
          descriptionKey: 'tutorial.killerSudoku.step5.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Star Battle (4단계) =====
    'starBattle': const GameTutorial(
      gameId: 'starBattle',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.starBattle.step1.title',
          descriptionKey: 'tutorial.starBattle.step1.description',
          illustration: IconIllustration(Icons.star_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.starBattle.step2.title',
          descriptionKey: 'tutorial.starBattle.step2.description',
          illustration: IconIllustration(Icons.dashboard_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.starBattle.step3.title',
          descriptionKey: 'tutorial.starBattle.step3.description',
          illustration: IconIllustration(Icons.block_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.starBattle.step4.title',
          descriptionKey: 'tutorial.starBattle.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Light Up (4단계) =====
    'lightUp': const GameTutorial(
      gameId: 'lightUp',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.lightUp.step1.title',
          descriptionKey: 'tutorial.lightUp.step1.description',
          illustration: IconIllustration(Icons.lightbulb_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.lightUp.step2.title',
          descriptionKey: 'tutorial.lightUp.step2.description',
          illustration: IconIllustration(Icons.brightness_5_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.lightUp.step3.title',
          descriptionKey: 'tutorial.lightUp.step3.description',
          illustration: IconIllustration(Icons.tag_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.lightUp.step4.title',
          descriptionKey: 'tutorial.lightUp.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Futoshiki (4단계) =====
    'futoshiki': const GameTutorial(
      gameId: 'futoshiki',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.futoshiki.step1.title',
          descriptionKey: 'tutorial.futoshiki.step1.description',
          illustration: IconIllustration(Icons.compare_arrows_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.futoshiki.step2.title',
          descriptionKey: 'tutorial.futoshiki.step2.description',
          illustration: IconIllustration(Icons.grid_on_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.futoshiki.step3.title',
          descriptionKey: 'tutorial.futoshiki.step3.description',
          illustration: IconIllustration(Icons.swap_horiz_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.futoshiki.step4.title',
          descriptionKey: 'tutorial.futoshiki.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Tents (4단계) =====
    'tents': const GameTutorial(
      gameId: 'tents',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.tents.step1.title',
          descriptionKey: 'tutorial.tents.step1.description',
          illustration: IconIllustration(Icons.park_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.tents.step2.title',
          descriptionKey: 'tutorial.tents.step2.description',
          illustration: IconIllustration(Icons.holiday_village_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.tents.step3.title',
          descriptionKey: 'tutorial.tents.step3.description',
          illustration: IconIllustration(Icons.tag_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.tents.step4.title',
          descriptionKey: 'tutorial.tents.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Jigsaw Sudoku (4단계) =====
    'jigsawSudoku': const GameTutorial(
      gameId: 'jigsawSudoku',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.jigsawSudoku.step1.title',
          descriptionKey: 'tutorial.jigsawSudoku.step1.description',
          illustration: IconIllustration(Icons.extension_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.jigsawSudoku.step2.title',
          descriptionKey: 'tutorial.jigsawSudoku.step2.description',
          illustration: IconIllustration(Icons.grid_on_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.jigsawSudoku.step3.title',
          descriptionKey: 'tutorial.jigsawSudoku.step3.description',
          illustration: IconIllustration(Icons.dashboard_customize_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.jigsawSudoku.step4.title',
          descriptionKey: 'tutorial.jigsawSudoku.step4.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Skyscrapers (5단계) =====
    'skyscrapers': const GameTutorial(
      gameId: 'skyscrapers',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.skyscrapers.step1.title',
          descriptionKey: 'tutorial.skyscrapers.step1.description',
          illustration: IconIllustration(Icons.apartment_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.skyscrapers.step2.title',
          descriptionKey: 'tutorial.skyscrapers.step2.description',
          illustration: IconIllustration(Icons.grid_on_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.skyscrapers.step3.title',
          descriptionKey: 'tutorial.skyscrapers.step3.description',
          illustration: IconIllustration(Icons.visibility_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.skyscrapers.step4.title',
          descriptionKey: 'tutorial.skyscrapers.step4.description',
          illustration: IconIllustration(Icons.tag_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.skyscrapers.step5.title',
          descriptionKey: 'tutorial.skyscrapers.step5.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),

    // ===== Kakuro (5단계) =====
    'kakuro': const GameTutorial(
      gameId: 'kakuro',
      steps: [
        TutorialStep(
          titleKey: 'tutorial.kakuro.step1.title',
          descriptionKey: 'tutorial.kakuro.step1.description',
          illustration: IconIllustration(Icons.tag_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.kakuro.step2.title',
          descriptionKey: 'tutorial.kakuro.step2.description',
          illustration: IconIllustration(Icons.add_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.kakuro.step3.title',
          descriptionKey: 'tutorial.kakuro.step3.description',
          illustration: IconIllustration(Icons.block_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.kakuro.step4.title',
          descriptionKey: 'tutorial.kakuro.step4.description',
          illustration: IconIllustration(Icons.format_list_numbered_rounded),
        ),
        TutorialStep(
          titleKey: 'tutorial.kakuro.step5.title',
          descriptionKey: 'tutorial.kakuro.step5.description',
          illustration: IconIllustration(Icons.touch_app_rounded),
        ),
      ],
    ),
  };
}
