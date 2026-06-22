import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../../../shared/constants/app_colors.dart';
import '../killer_sudoku_notifier.dart';
import '../killer_sudoku_state.dart';
import '../widgets/killer_sudoku_board_widget.dart';
import '../../../shared/widgets/checkpoint_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/board_progress_bar.dart';
import '../../../shared/widgets/animated_trophy.dart';
import '../../../shared/widgets/count_up_text.dart';

/// 킬러 스도쿠 게임 플레이 화면
class KillerSudokuGameScreen extends ConsumerStatefulWidget {
  const KillerSudokuGameScreen({super.key});

  @override
  ConsumerState<KillerSudokuGameScreen> createState() =>
      _KillerSudokuGameScreenState();
}

class _KillerSudokuGameScreenState
    extends ConsumerState<KillerSudokuGameScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(killerSudokuNotifierProvider);

    // 게임 상태 없으면 홈으로
    if (gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.killerSudoku);
      });
      return const GameLoadingScreen();
    }

    // 완료 시 결과 표시
    if (gameState.isCompleted && !gameState.isAutoCompleting) {
      return _KillerResultView(gameState: gameState);
    }

    // 일시정지 시
    if (gameState.isPaused) {
      return _KillerPauseView(gameState: gameState);
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
                title: Text(AppStrings.get('killerSudoku.title')),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _showExitDialog(context),
                  tooltip: AppStrings.get('game.back'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.pause_rounded),
                    onPressed: () =>
                        ref.read(killerSudokuNotifierProvider.notifier).pause(),
                    tooltip: AppStrings.get('game.pause'),
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

  /// 세로 모드 레이아웃
  Widget _buildPortraitLayout(KillerSudokuState gameState) {
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
                child: const KillerSudokuBoardWidget(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 힌트 메시지
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: gameState.lastHintResult != null
              ? _HintMessageBar(message: gameState.lastHintResult!.message)
              : const SizedBox.shrink(),
        ),
        // 숫자 패드
        _NumberPad(gameState: gameState),
        // 컨트롤 바
        _ControlBar(gameState: gameState),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 가로 모드 레이아웃
  Widget _buildLandscapeLayout(
    BuildContext context,
    WidgetRef ref,
    KillerSudokuState gameState,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: const Center(child: KillerSudokuBoardWidget()),
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
                        AppStrings.get('killerSudoku.title'),
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.pause_rounded, size: 20),
                        onPressed: () => ref
                            .read(killerSudokuNotifierProvider.notifier)
                            .pause(),
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
                            message: gameState.lastHintResult!.message,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const Expanded(child: SizedBox()),
                _NumberPad(gameState: gameState),
                _ControlBar(gameState: gameState),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 나가기 확인 다이얼로그
  void _showExitDialog(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('game.exit.title'),
      content: AppStrings.get('game.exit.message'),
      confirmLabel: AppStrings.get('game.exit.leave'),
      cancelLabel: AppStrings.get('cancel'),
      onConfirm: () {
        ref.read(killerSudokuNotifierProvider.notifier).pause();
        context.go(AppRoutes.killerSudoku);
      },
    );
  }
}

/// 게임 정보 바
class _GameInfoBar extends StatelessWidget {
  final KillerSudokuState gameState;
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
            '${gameState.difficultyLabel} (9x9)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
          ),
          Row(
            children: [
              Icon(Icons.close_rounded,
                  size: 16,
                  color:
                      isDark ? Colors.red.shade400 : Colors.red.shade400),
              const SizedBox(width: 2),
              Text(
                '${gameState.mistakeCount}',
                style: TextStyle(
                  color:
                      isDark ? Colors.red.shade400 : Colors.red.shade400,
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

/// 숫자 패드 (1~9)
class _NumberPad extends ConsumerWidget {
  final KillerSudokuState gameState;
  const _NumberPad({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(killerSudokuNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (i) {
          final num = i + 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AspectRatio(
                aspectRatio: 0.9,
                child: Material(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => notifier.inputNumber(num),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        '$num',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 하단 컨트롤 바
class _ControlBar extends ConsumerWidget {
  final KillerSudokuState gameState;
  const _ControlBar({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(killerSudokuNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 되돌리기
          _ActionButton(
            icon: Icons.undo_rounded,
            label: AppStrings.get('game.undo'),
            onPressed: gameState.undoStack.isNotEmpty
                ? () => notifier.undo()
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          // 삭제
          _ActionButton(
            icon: Icons.backspace_outlined,
            label: AppStrings.get('game.delete'),
            onPressed: gameState.selectedCell != null
                ? () => notifier.deleteSelected()
                : null,
            isDark: isDark,
          ),
          const SizedBox(width: 16),
          // 메모 토글
          _ActionButton(
            icon: Icons.edit_note_rounded,
            label: AppStrings.get('game.memo'),
            onPressed: () => notifier.toggleNoteMode(),
            isDark: isDark,
            isActive: gameState.isNoteMode,
          ),
          const SizedBox(width: 16),
          // 힌트
          _ActionButton(
            icon: Icons.lightbulb_outline_rounded,
            label: AppStrings.get('game.hint'),
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
    );
  }
}

/// 액션 버튼
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isDark;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    required this.isDark,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final activeBg = isDark ? Colors.blue.shade700 : Colors.blue.shade100;
    final normalBg = isDark
        ? Colors.white10
        : Colors.black.withValues(alpha: 0.05);

    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: isActive
            ? activeBg
            : (enabled ? normalBg : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
                label,
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
              color:
                  isDark ? Colors.amber.shade300 : Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.amber.shade100
                    : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 일시정지 화면
class _KillerPauseView extends ConsumerWidget {
  final KillerSudokuState gameState;
  const _KillerPauseView({required this.gameState});

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
        if (!didPop) {
          ref.read(killerSudokuNotifierProvider.notifier).resume();
        }
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
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
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
                      onPressed: () => ref
                          .read(killerSudokuNotifierProvider.notifier)
                          .resume(),
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
                      onPressed: () =>
                          context.go(AppRoutes.killerSudoku),
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
                      onPressed: () =>
                          _showGiveUpDialog(context, ref),
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
      title: AppStrings.get('pause.giveUp.title'),
      content: AppStrings.get('pause.giveUp.message'),
      confirmLabel: AppStrings.get('pause.giveUp.action'),
      cancelLabel: AppStrings.get('cancel'),
      isDanger: true,
      onConfirm: () {
        ref.read(killerSudokuNotifierProvider.notifier).giveUp();
        context.go(AppRoutes.killerSudoku);
      },
    );
  }
}

/// 결과 화면
class _KillerResultView extends ConsumerStatefulWidget {
  final KillerSudokuState gameState;
  const _KillerResultView({required this.gameState});

  @override
  ConsumerState<_KillerResultView> createState() =>
      _KillerResultViewState();
}

class _KillerResultViewState extends ConsumerState<_KillerResultView> {
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
    final newBadges =
        ref.read(killerSudokuNotifierProvider.notifier).lastNewBadges;
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
          ref.read(killerSudokuNotifierProvider.notifier).giveUp();
          context.go(AppRoutes.killerSudoku);
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
                  // 등급 표시
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
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          color: gradeColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.get('result.congrats'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _StatRow(
                    label: AppStrings.get('result.time'),
                    value: timeText,
                    valueWidget: CountUpText(value: gameState.elapsedSeconds, formatter: (v) => '${(v ~/ 60).toString().padLeft(2, "0")}:${(v % 60).toString().padLeft(2, "0")}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    isDark: isDark,
                  ),
                  _StatRow(
                    label: AppStrings.get('result.difficulty'),
                    value: '${gameState.difficultyLabel} (9x9)',
                    isDark: isDark,
                  ),
                  _StatRow(
                    label: AppStrings.get('result.mistakes'),
                    value: '${gameState.mistakeCount}',
                    isDark: isDark,
                  ),
                  _StatRow(
                    label: AppStrings.get('result.hints'),
                    value: '${gameState.hintCount}',
                    isDark: isDark,
                  ),
                  // 새 배지 표시
                  _buildNewBadgesSection(ref, context),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(killerSudokuNotifierProvider.notifier)
                            .startNewGame(
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
                        ref
                            .read(killerSudokuNotifierProvider.notifier)
                            .giveUp();
                        context.go(AppRoutes.killerSudoku);
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
    final badges =
        ref.read(killerSudokuNotifierProvider.notifier).lastNewBadges;
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

  Color _gradeColor(KillerSudokuGrade grade, bool isDark) {
    switch (grade) {
      case KillerSudokuGrade.perfect:
        return Colors.amber.shade600;
      case KillerSudokuGrade.excellent:
        return isDark ? Colors.green.shade300 : Colors.green.shade600;
      case KillerSudokuGrade.great:
        return isDark ? Colors.blue.shade300 : Colors.blue.shade600;
      case KillerSudokuGrade.good:
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
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
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
