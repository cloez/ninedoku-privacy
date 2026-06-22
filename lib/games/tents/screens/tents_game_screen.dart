import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../../../shared/constants/app_colors.dart';
import '../tents_notifier.dart';
import '../tents_state.dart';
import '../widgets/tents_board_widget.dart';
import '../../../shared/widgets/checkpoint_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/board_progress_bar.dart';
import '../../../shared/widgets/animated_trophy.dart';
import '../../../shared/widgets/count_up_text.dart';

/// Tents 게임 플레이 화면
class TentsGameScreen extends ConsumerStatefulWidget {
  const TentsGameScreen({super.key});

  @override
  ConsumerState<TentsGameScreen> createState() => _TentsGameScreenState();
}

class _TentsGameScreenState extends ConsumerState<TentsGameScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(tentsNotifierProvider);

    if (gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.tents);
      });
      return const GameLoadingScreen();
    }

    if (gameState.isCompleted && !gameState.isAutoCompleting) {
      return _TentsResultView(gameState: gameState);
    }

    if (gameState.isPaused) {
      return _TentsPauseView(gameState: gameState);
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        appBar: isLandscape
            ? null
            : AppBar(
                title: Text(AppStrings.get('tents.title')),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _showExitDialog(context),
                  tooltip: AppStrings.get('tents.back'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.pause_rounded),
                    onPressed: () =>
                        ref.read(tentsNotifierProvider.notifier).pause(),
                    tooltip: AppStrings.get('tents.pause'),
                  ),
                ],
              ),
        body: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(context, ref, gameState)
              : _buildPortraitLayout(gameState),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(TentsState gameState) {
    return Column(
      children: [
        _GameInfoBar(gameState: gameState),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BoardProgressBar(progress: gameState.progress),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: const TentsBoardWidget(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: gameState.lastHintResult != null
              ? _HintMessageBar(message: gameState.lastHintResult!.message)
              : const SizedBox.shrink(),
        ),
        _ControlBar(gameState: gameState),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context, WidgetRef ref, TentsState gameState) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: const Center(child: TentsBoardWidget()),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        onPressed: () => _showExitDialog(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.get('tents.title'),
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.pause_rounded, size: 20),
                        onPressed: () =>
                            ref.read(tentsNotifierProvider.notifier).pause(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _GameInfoBar(gameState: gameState),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BoardProgressBar(progress: gameState.progress),
        ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: gameState.lastHintResult != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _HintMessageBar(
                              message: gameState.lastHintResult!.message),
                        )
                      : const SizedBox.shrink(),
                ),
                const Expanded(child: SizedBox()),
                _ControlBar(gameState: gameState),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showExitDialog(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('tents.exit.title'),
      content: AppStrings.get('tents.exit.message'),
      confirmLabel: AppStrings.get('tents.exit.leave'),
      cancelLabel: AppStrings.get('cancel'),
      onConfirm: () {
        ref.read(tentsNotifierProvider.notifier).pause();
        context.go(AppRoutes.tents);
      },
    );
  }
}

/// 게임 정보 바
class _GameInfoBar extends StatelessWidget {
  final TentsState gameState;
  const _GameInfoBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seconds = gameState.elapsedSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${gameState.difficulty.label} (${gameState.size}x${gameState.size})',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
          ),
          Row(
            children: [
              Icon(Icons.close_rounded,
                  size: 16,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade400),
              const SizedBox(width: 2),
              Text(
                '${gameState.mistakeCount}',
                style: TextStyle(
                  color: isDark ? Colors.red.shade400 : Colors.red.shade400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 4),
              Text(
                timeText,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 하단 조작 버튼 바
class _ControlBar extends ConsumerWidget {
  final TentsState gameState;
  const _ControlBar({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(tentsNotifierProvider.notifier);
    final currentMode = gameState.inputMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 입력 모드 토글 바 (⛺ / ✕ / 지우개)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleButton(
                  label: '⛺',
                  sublabel: '텐트',
                  isSelected: currentMode == TentsInputMode.tent,
                  onTap: () => notifier.setInputMode(TentsInputMode.tent),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _ToggleButton(
                  label: '✕',
                  sublabel: '잔디',
                  isSelected: currentMode == TentsInputMode.grass,
                  onTap: () => notifier.setInputMode(TentsInputMode.grass),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _ToggleButton(
                  icon: Icons.auto_fix_high_rounded,
                  isSelected: currentMode == TentsInputMode.erase,
                  onTap: () => notifier.setInputMode(TentsInputMode.erase),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 보조 버튼 (되돌리기 / 힌트)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.undo_rounded,
                onPressed: gameState.undoStack.isNotEmpty
                    ? () => notifier.undo()
                    : null,
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.lightbulb_outline_rounded,
                onPressed: () => notifier.getHint(),
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              // 체크포인트 버튼
              CheckpointButton(
                hasCheckpoint: notifier.hasCheckpoint,
                onTap: () {
                  if (notifier.hasCheckpoint) {
                    notifier.restoreCheckpoint();
                    notifier.clearCheckpoint();
                    showCheckpointToast(context, 'checkpoint.restored');
                  } else {
                    notifier.saveCheckpoint();
                    showCheckpointToast(context, 'checkpoint.saved');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 액션 버튼
class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isDark;

  const _ActionButton({
    this.icon,
    this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: enabled
            ? (isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: enabled
                      ? (isDark ? Colors.white70 : Colors.black54)
                      : (isDark ? Colors.white24 : Colors.black26),
                ),
                const SizedBox(height: 2),
                Text(
                  icon == Icons.undo_rounded ? '되돌리기' : '힌트',
                  style: TextStyle(
                    fontSize: 9,
                    color: enabled
                        ? (isDark ? Colors.white54 : Colors.black45)
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 입력 모드 토글 버튼
class _ToggleButton extends StatelessWidget {
  final String? label;
  final String? sublabel;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ToggleButton({
    this.label,
    this.sublabel,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark ? Colors.blue.shade700 : Colors.blue.shade100;
    final selectedFg = isDark ? Colors.white : Colors.blue.shade800;
    final unselectedFg = isDark ? Colors.white54 : Colors.black45;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: label != null
              ? Text(
                  label!,
                  style: TextStyle(
                    fontSize: 24,
                    color: isSelected ? selectedFg : unselectedFg,
                  ),
                )
              : Icon(
                  icon,
                  size: 22,
                  color: isSelected ? selectedFg : unselectedFg,
                ),
        ),
      ),
    );
  }
}

/// 힌트 메시지 바
class _HintMessageBar extends StatelessWidget {
  final String message;
  const _HintMessageBar({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.shade900.withValues(alpha: 0.3)
            : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.amber.shade700 : Colors.amber.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded,
              size: 16,
              color: isDark ? Colors.amber.shade300 : Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? Colors.amber.shade100 : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 일시정지 화면
class _TentsPauseView extends ConsumerWidget {
  final TentsState gameState;
  const _TentsPauseView({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seconds = gameState.elapsedSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(tentsNotifierProvider.notifier).resume();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('pause.title')),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pause_circle_outline_rounded,
                    size: 80,
                    color:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.get('pause.message'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${AppStrings.get('pause.elapsed')}$timeText',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(tentsNotifierProvider.notifier).resume(),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(AppStrings.get('pause.resume')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.tents),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(AppStrings.get('pause.home')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showGiveUpDialog(context, ref),
                      icon: Icon(
                        Icons.flag_outlined,
                        color: isDark
                            ? AppColors.wrongNumberDark
                            : AppColors.wrongNumberLight,
                      ),
                      label: Text(
                        AppStrings.get('pause.giveUp'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.wrongNumberDark
                              : AppColors.wrongNumberLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGiveUpDialog(BuildContext context, WidgetRef ref) {
    showKPDialog(
      context: context,
      title: AppStrings.get('tents.giveUp.title'),
      content: AppStrings.get('tents.giveUp.message'),
      confirmLabel: AppStrings.get('tents.giveUp.action'),
      cancelLabel: AppStrings.get('cancel'),
      isDanger: true,
      onConfirm: () {
        ref.read(tentsNotifierProvider.notifier).giveUp();
        context.go(AppRoutes.tents);
      },
    );
  }
}

/// 결과 화면
class _TentsResultView extends ConsumerStatefulWidget {
  final TentsState gameState;
  const _TentsResultView({required this.gameState});

  @override
  ConsumerState<_TentsResultView> createState() => _TentsResultViewState();
}

class _TentsResultViewState extends ConsumerState<_TentsResultView> {
  bool _badgePopupShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // UX: 결과 화면 인라인 배지 칩과 다이얼로그가 중복되므로 다이얼로그 비활성화
      // _showBadgePopupIfNeeded();
    });
  }

  void _showBadgePopupIfNeeded() {
    if (_badgePopupShown) return;
    final newBadges = ref.read(tentsNotifierProvider.notifier).lastNewBadges;
    if (newBadges.isEmpty) return;
    _badgePopupShown = true;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉 ', style: TextStyle(fontSize: 24)),
            Text(AppStrings.get('result.newBadges')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: newBadges
              .map((badge) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text(badge.icon,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(badge.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(badge.description,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final gameState = widget.gameState;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grade = gameState.grade;
    final seconds = gameState.elapsedSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final gradeColor = _gradeColor(grade, isDark);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(tentsNotifierProvider.notifier).giveUp();
          context.go(AppRoutes.tents);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedTrophy(

                    glowColor: gradeColor,

                    child: Container(

                      width: 80,

                      height: 80,

                      decoration: BoxDecoration(

                        shape: BoxShape.circle,

                        color: gradeColor.withValues(alpha: 0.15),

                        border: Border.all(color: gradeColor, width: 3),

                      ),

                      child: Center(

                        child: Text(

                          grade.symbol,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                        ),

                        ),

                      ),

                    ),

                  ),
                  const SizedBox(height: 12),
                  Text(
                    grade.label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: gradeColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.get('tents.result.completed'),
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 16),
                  _StatRow(
                    label: AppStrings.get('tents.result.time'),
                    value: timeText,
                    valueWidget: CountUpText(value: gameState.elapsedSeconds, formatter: (v) => '${(v ~/ 60).toString().padLeft(2, "0")}:${(v % 60).toString().padLeft(2, "0")}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    isDark: isDark,
                  ),
                  _StatRow(
                    label: AppStrings.get('tents.result.difficulty'),
                    value:
                        '${gameState.difficulty.label} (${gameState.size}x${gameState.size})',
                    isDark: isDark,
                  ),
                  _StatRow(
                    label: AppStrings.get('tents.result.mistakes'),
                    value: '${gameState.mistakeCount}',
                    isDark: isDark,
                  ),
                  _StatRow(
                    label: AppStrings.get('tents.result.hints'),
                    value: '${gameState.hintCount}',
                    isDark: isDark,
                  ),
                  _buildNewBadgesSection(ref, context),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(tentsNotifierProvider.notifier).startNewGame(
                              mode: gameState.mode,
                              difficulty: gameState.difficulty,
                            );
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(AppStrings.get('result.newGame')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(tentsNotifierProvider.notifier).giveUp();
                        context.go(AppRoutes.tents);
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: Text(AppStrings.get('result.home')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewBadgesSection(WidgetRef ref, BuildContext context) {
    final badges = ref.read(tentsNotifierProvider.notifier).lastNewBadges;
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

  Color _gradeColor(TentsGrade grade, bool isDark) {
    switch (grade) {
      case TentsGrade.perfect:
        return Colors.amber.shade600;
      case TentsGrade.excellent:
        return isDark ? Colors.green.shade300 : Colors.green.shade600;
      case TentsGrade.great:
        return isDark ? Colors.blue.shade300 : Colors.blue.shade600;
      case TentsGrade.good:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }
}

/// 통계 행
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Widget? valueWidget;
  const _StatRow(
      {required this.label, required this.value, required this.isDark, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          valueWidget ?? Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
