import 'package:flutter/material.dart';
import '../../../core/sudoku/hint_engine.dart';
import '../../../core/sudoku/technique_analyzer.dart';
import '../../../shared/l10n/app_strings.dart';

/// H5: 기법 사전 모달 — 8종 기법의 이름/난이도/설명/도해 표시
///
/// 진입점:
/// - HintBanner의 기법 이름 탭
/// - 결과 화면의 사용 기법 기록 탭(향후)
class TechniqueGlossaryModal extends StatelessWidget {
  final SolvingTechnique technique;

  const TechniqueGlossaryModal({super.key, required this.technique});

  /// 모달 열기 헬퍼
  static Future<void> show(BuildContext context, SolvingTechnique tech) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TechniqueGlossaryModal(technique: tech),
    );
  }

  /// 기법 → glossary 단축 키 (다국어 키 조립용)
  String _glossaryShortKey() {
    switch (technique) {
      case SolvingTechnique.nakedSingle:
        return 'nakedSingle';
      case SolvingTechnique.hiddenSingle:
        return 'hiddenSingle';
      case SolvingTechnique.nakedPair:
        return 'nakedPair';
      case SolvingTechnique.nakedTriple:
        return 'nakedTriple';
      case SolvingTechnique.hiddenPair:
        return 'hiddenPair';
      case SolvingTechnique.pointingPair:
        return 'pointingPair';
      case SolvingTechnique.boxLineReduction:
        return 'boxLine';
      case SolvingTechnique.xWing:
        return 'xWing';
    }
  }

  /// 기법 난이도 — 초급/중급/고급
  String _difficultyKey() {
    switch (technique) {
      case SolvingTechnique.nakedSingle:
      case SolvingTechnique.hiddenSingle:
        return 'hint.glossary.difficulty.beginner';
      case SolvingTechnique.xWing:
        return 'hint.glossary.difficulty.advanced';
      default:
        return 'hint.glossary.difficulty.intermediate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortKey = _glossaryShortKey();
    final title = AppStrings.get(HintEngine.techniqueKeyOf(technique));
    final body = AppStrings.get('hint.glossary.$shortKey.body');
    final caption = AppStrings.get('hint.glossary.$shortKey.caption');
    final difficulty = AppStrings.get(_difficultyKey());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 사전 타이틀 + 닫기
              Row(
                children: [
                  Text(
                    AppStrings.get('hint.glossary.title'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: AppStrings.get('close'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 기법명 + 난이도 배지
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _difficultyColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _difficultyColor(), width: 1),
                    ),
                    child: Text(
                      difficulty,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _difficultyColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 설명 본문
              Text(
                body,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 20),
              // 미니 도해
              Center(
                child: _GlossaryFigure(technique: technique),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  caption,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              // 닫기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppStrings.get('close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _difficultyColor() {
    switch (technique) {
      case SolvingTechnique.nakedSingle:
      case SolvingTechnique.hiddenSingle:
        return const Color(0xFF10B981); // 초록 — 초급
      case SolvingTechnique.xWing:
        return const Color(0xFFEF4444); // 빨강 — 고급
      default:
        return const Color(0xFFF59E0B); // 주황 — 중급
    }
  }
}

/// H5: 기법별 미니 보드 도해 — 5x5 정적 그리드로 핵심 셀 강조
class _GlossaryFigure extends StatelessWidget {
  final SolvingTechnique technique;
  const _GlossaryFigure({required this.technique});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.black26;
    // 기법별 강조 셀 위치 (5x5 그리드)
    final highlights = _highlightCells();
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        itemCount: 25,
        itemBuilder: (context, index) {
          final r = index ~/ 5;
          final c = index % 5;
          final highlight = highlights[(r, c)];
          Color? bg;
          if (highlight == _CellTint.answer) {
            bg = const Color(0xFF10B981).withValues(alpha: 0.35);
          } else if (highlight == _CellTint.key) {
            bg = const Color(0xFFF59E0B).withValues(alpha: 0.3);
          } else if (highlight == _CellTint.eliminate) {
            bg = const Color(0xFFEF4444).withValues(alpha: 0.2);
          }
          return Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor, width: 0.4),
            ),
          );
        },
      ),
    );
  }

  /// 기법별 도해 셀 강조 패턴 (5x5)
  Map<(int, int), _CellTint> _highlightCells() {
    switch (technique) {
      case SolvingTechnique.nakedSingle:
      case SolvingTechnique.hiddenSingle:
        return {(2, 2): _CellTint.answer};
      case SolvingTechnique.nakedPair:
      case SolvingTechnique.nakedTriple:
        return {
          (1, 1): _CellTint.key,
          (1, 3): _CellTint.key,
          (1, 0): _CellTint.eliminate,
          (1, 2): _CellTint.eliminate,
          (1, 4): _CellTint.eliminate,
        };
      case SolvingTechnique.hiddenPair:
        return {(2, 1): _CellTint.key, (2, 3): _CellTint.key};
      case SolvingTechnique.pointingPair:
        return {
          (0, 0): _CellTint.key,
          (0, 1): _CellTint.key,
          (0, 2): _CellTint.eliminate,
          (0, 3): _CellTint.eliminate,
          (0, 4): _CellTint.eliminate,
        };
      case SolvingTechnique.boxLineReduction:
        return {
          (0, 0): _CellTint.key,
          (1, 0): _CellTint.key,
          (2, 0): _CellTint.eliminate,
          (3, 0): _CellTint.eliminate,
          (4, 0): _CellTint.eliminate,
        };
      case SolvingTechnique.xWing:
        return {
          (1, 1): _CellTint.key,
          (1, 3): _CellTint.key,
          (3, 1): _CellTint.key,
          (3, 3): _CellTint.key,
        };
    }
  }
}

enum _CellTint { key, answer, eliminate }
