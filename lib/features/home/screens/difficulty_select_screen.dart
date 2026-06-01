import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../core/sudoku/difficulty.dart';
import '../../game/game_notifier.dart';
import '../../game/game_state.dart';

/// 난이도 선택 화면 (S-04)
class DifficultySelectScreen extends ConsumerWidget {
  final String mode;
  const DifficultySelectScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final GameMode gameMode;
    switch (mode) {
      case 'relax':
        gameMode = GameMode.relax;
      case 'challenge':
        gameMode = GameMode.challenge;
      default:
        gameMode = GameMode.classic;
    }

    // 릴렉스 모드: 입문~어려움만 (Calm 컨셉과 고난도 상충 방지)
    // 도전 모드: 보통~마스터 (쉬운 난이도는 도전 의미 없음)
    final List<Difficulty> availableDifficulties;
    if (gameMode == GameMode.relax) {
      availableDifficulties = Difficulty.values.where((d) => d.code <= Difficulty.hard.code).toList();
    } else if (gameMode == GameMode.challenge) {
      availableDifficulties = Difficulty.values.where((d) => d.code >= Difficulty.medium.code).toList();
    } else {
      availableDifficulties = Difficulty.values;
    }

    return Scaffold(
      appBar: AppBar(title: Text('${AppStrings.get('difficulty.title')} - ${AppStrings.get('mode.${gameMode.name}')}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              ...availableDifficulties.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DifficultyCard(
                      difficulty: diff,
                      isDark: isDark,
                      onTap: () {
                        ref.read(gameProvider.notifier).startNewGame(
                              mode: gameMode,
                              difficulty: diff,
                            );
                        context.go(AppRoutes.game);
                      },
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// 난이도 카드
class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final bool isDark;
  final VoidCallback? onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(isDark);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: diffColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('difficulty.${difficulty.name}'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.get('difficulty.emptyCells.prefix')}${difficulty.emptyCellRange.$1}~${difficulty.emptyCellRange.$2}${AppStrings.get('difficulty.emptyCells.suffix')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                    ),
                    // 전문가/마스터 기법 안내
                    if (difficulty == Difficulty.expert || difficulty == Difficulty.master) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.get('difficulty.${difficulty.name}.desc'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: difficulty == Difficulty.master
                                  ? Colors.purple.shade300
                                  : Colors.red.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(bool isDark) {
    switch (difficulty) {
      case Difficulty.beginner:
        return Colors.green;
      case Difficulty.easy:
        return Colors.lightGreen;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.deepOrange;
      case Difficulty.expert:
        return Colors.red;
      case Difficulty.master:
        return Colors.purple;
    }
  }
}
