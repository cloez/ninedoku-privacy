import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../../../shared/widgets/kp_widgets.dart';
import '../game_notifier.dart';
import '../game_state.dart';
import '../../../core/sudoku/difficulty.dart';
import '../../../core/sudoku/hint_engine.dart';
import '../../../core/sudoku/technique_analyzer.dart';
import '../../../shared/constants/app_colors.dart';
import '../../badges/badge_definitions.dart';
import '../../../shared/widgets/animated_trophy.dart';
import '../../../shared/widgets/count_up_text.dart';

/// 결과 화면 (S-07)
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _badgePopupShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBadgePopupIfNeeded();
    });
  }

  void _showBadgePopupIfNeeded() {
    if (_badgePopupShown) return;
    final newBadges = ref.read(gameProvider.notifier).lastNewBadges;
    if (newBadges.isEmpty) return;
    _badgePopupShown = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : const Color(0xFF4A4A5A);

    showKPDialog<void>(
      context: context,
      title: '🎉 ${AppStrings.get('result.newBadges')}',
      confirmLabel: AppStrings.get('confirm'),
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: newBadges.map((badge) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(badge.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(badge.name, style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                    )),
                    Text(badge.description, style: TextStyle(fontSize: 12, color: textColor)),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grade = gameState.grade;

    // 하드웨어 백키 → 홈으로 이동 (게임 정리 포함)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(gameProvider.notifier).giveUp();
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('result.title')),
        automaticallyImplyLeading: false,
      ),
      body: KPBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 축하 아이콘
              Icon(
                Icons.emoji_events_rounded,
                size: 72,
                color: _gradeColor(grade, isDark),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.get('result.congrats'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              // 등급 배지
              _GradeBadge(grade: grade, isDark: isDark),
              const SizedBox(height: 8),
              // 등급 기준 안내
              _GradeCriteria(difficulty: gameState.difficulty, isDark: isDark),
              const SizedBox(height: 32),
              // 통계 카드 (KP 스타일 컨테이너)
              _StatCard(
                children: [
                  _StatRow(
                    icon: Icons.timer_outlined,
                    label: AppStrings.get('result.time'),
                    value: _formatTime(gameState.elapsedSeconds),
                    // 시간 카운트업 (0 → 경과 초)
                    valueWidget: CountUpText(
                      value: gameState.elapsedSeconds,
                      formatter: _formatTime,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Divider(height: 24),
                  _StatRow(
                    icon: Icons.grid_on_rounded,
                    label: AppStrings.get('result.difficulty'),
                    value: AppStrings.get('difficulty.${gameState.difficulty.name}'),
                  ),
                  const Divider(height: 24),
                  _StatRow(
                    icon: Icons.close_rounded,
                    label: AppStrings.get('result.mistakes'),
                    value: '${gameState.mistakeCount}${AppStrings.get('result.count.suffix')}',
                    isWarning: gameState.mistakeCount > 0,
                    // 실수 카운트업
                    valueWidget: CountUpText(
                      value: gameState.mistakeCount,
                      formatter: (v) => '$v${AppStrings.get('result.count.suffix')}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: gameState.mistakeCount > 0
                                ? (isDark
                                    ? AppColors.wrongNumberDark
                                    : AppColors.wrongNumberLight)
                                : null,
                          ),
                    ),
                  ),
                  const Divider(height: 24),
                  _StatRow(
                    icon: Icons.lightbulb_outline_rounded,
                    label: AppStrings.get('result.hints'),
                    value: '${gameState.hintCount}${AppStrings.get('result.count.suffix')}',
                    // 힌트 카운트업
                    valueWidget: CountUpText(
                      value: gameState.hintCount,
                      formatter: (v) => '$v${AppStrings.get('result.count.suffix')}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              // H4: 이번 게임에서 학습한 기법 (1개 이상일 때만)
              _UsedTechniquesSection(usedTechniques: gameState.usedTechniques),
              // 새로 획득한 배지
              _NewBadgesSection(
                badges: ref.read(gameProvider.notifier).lastNewBadges,
              ),
              const SizedBox(height: 32),
              // 새 게임 버튼 (KP 그라데이션 CTA)
              KPGradientButton(
                onTap: () {
                  ref.read(gameProvider.notifier).startNewGame(
                        mode: gameState.mode,
                        difficulty: gameState.difficulty,
                      );
                },
                iconAsset: 'assets/icons/play.svg',
                label: AppStrings.get('result.newGame'),
                colors: [_gradeColor(grade, isDark), _gradeColor(grade, isDark).withValues(alpha: 0.7)],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(gameProvider.notifier).giveUp();
                    context.go(AppRoutes.home);
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: Text(AppStrings.get('result.home')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Color _gradeColor(Grade grade, bool isDark) {
    switch (grade) {
      case Grade.perfect:
        return const Color(0xFFFFD700); // 금색
      case Grade.excellent:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
      case Grade.great:
        return const Color(0xFF4CAF50);
      case Grade.good:
        return isDark ? Colors.white54 : Colors.black45;
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 등급 배지
class _GradeBadge extends StatelessWidget {
  final Grade grade;
  final bool isDark;

  const _GradeBadge({required this.grade, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor;

    return AnimatedTrophy(
      glowColor: color,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Text(
              grade.symbol,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              AppStrings.get('grade.${grade.name}'),
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _badgeColor {
    switch (grade) {
      case Grade.perfect:
        return const Color(0xFFFFD700);
      case Grade.excellent:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
      case Grade.great:
        return const Color(0xFF4CAF50);
      case Grade.good:
        return isDark ? Colors.white54 : Colors.black45;
    }
  }
}

/// 통계 카드 (KP 스타일)
class _StatCard extends StatelessWidget {
  final List<Widget> children;

  const _StatCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? AppColors.outlineDark : AppColors.kpBorder),
        boxShadow: isDark ? null : KPShadow.soft,
      ),
      child: Column(children: children),
    );
  }
}

/// 통계 행
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;
  // 카운트업 등 커스텀 위젯이 필요한 경우 (예: 시간/실수/힌트)
  final Widget? valueWidget;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isWarning
        ? (isDark ? AppColors.wrongNumberDark : AppColors.wrongNumberLight)
        : null;

    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.black45),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        valueWidget ??
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
            ),
      ],
    );
  }
}

/// 등급 기준 안내
class _GradeCriteria extends StatelessWidget {
  final Difficulty difficulty;
  final bool isDark;

  const _GradeCriteria({required this.difficulty, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final thresholds = Grade.gradeThresholds(difficulty);
    final baseTime = Grade.baseTimeForDifficulty(difficulty);
    final baseMin = baseTime ~/ 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            AppStrings.get('result.gradeCriteria'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.get('result.grade.s')}${baseMin}${AppStrings.get('result.grade.minSuffix')}\n'
            '${AppStrings.get('result.grade.a')}${thresholds.bMistakes}${AppStrings.get('result.grade.belowSuffix')}\n'
            '${AppStrings.get('result.grade.b')}${thresholds.cMistakes}${AppStrings.get('result.grade.belowSuffix')}\n'
            '${AppStrings.get('result.grade.c')}',
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// H4: 이번 게임에서 학습한 기법 목록 — 0개면 비표시
class _UsedTechniquesSection extends StatelessWidget {
  final Set<SolvingTechnique> usedTechniques;
  const _UsedTechniquesSection({required this.usedTechniques});

  @override
  Widget build(BuildContext context) {
    if (usedTechniques.isEmpty) return const SizedBox.shrink();
    final names = usedTechniques
        .map((t) => AppStrings.get(HintEngine.techniqueKeyOf(t)))
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 8, right: 8),
      child: Text(
        '${AppStrings.get('result.usedTechniques.title')}: $names',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

/// 새로 획득한 배지 표시
class _NewBadgesSection extends StatelessWidget {
  final List<BadgeDefinition> badges;
  const _NewBadgesSection({required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          AppStrings.get('result.newBadges'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: badges.map((badge) {
            return Chip(
              avatar: Text(badge.icon, style: const TextStyle(fontSize: 18)),
              label: Text(badge.name),
            );
          }).toList(),
        ),
      ],
    );
  }
}
