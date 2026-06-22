import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../../../shared/constants/app_colors.dart';
import '../minesweeper_notifier.dart';
import '../minesweeper_state.dart';
import '../widgets/minesweeper_board_widget.dart';
import '../../../shared/widgets/checkpoint_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/board_progress_bar.dart';
import '../../../shared/widgets/animated_trophy.dart';
import '../../../shared/widgets/count_up_text.dart';

/// 지뢰찾기 게임 플레이 화면
class MinesweeperGameScreen extends ConsumerStatefulWidget {
  const MinesweeperGameScreen({super.key});

  @override
  ConsumerState<MinesweeperGameScreen> createState() => _MinesweeperGameScreenState();
}

class _MinesweeperGameScreenState extends ConsumerState<MinesweeperGameScreen> {
  bool _badgePopupShown = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(minesweeperNotifierProvider);
    if (gameState == null) {
      return const GameLoadingScreen();
    }

    // UX: 결과 화면 인라인 배지 칩과 다이얼로그가 중복되므로 다이얼로그 비활성화
    // if (gameState.isCompleted && !_badgePopupShown) {
    //   _badgePopupShown = true;
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _showBadgePopup(context);
    //   });
    // }

    if (gameState.isPaused && !gameState.isCompleted) {
      return _buildPauseScreen(context, gameState);
    }

    if (gameState.isCompleted) {
      return _buildResultScreen(context, gameState);
    }

    return _buildPlayScreen(context, gameState);
  }

  /// 플레이 화면
  Widget _buildPlayScreen(BuildContext context, MinesweeperState state) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(minesweeperNotifierProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        appBar: isLandscape ? null : AppBar(
          title: Text(AppStrings.get('minesweeper.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _showExitDialog(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.pause_rounded),
              onPressed: () => notifier.pause(),
            ),
          ],
        ),
        body: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(context, state, isDark)
              : _buildPortraitLayout(context, state, isDark),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, MinesweeperState state, bool isDark) {
    final notifier = ref.read(minesweeperNotifierProvider.notifier);

    return Column(
      children: [
        // 상태 바 (타이머, 실수, 남은 지뢰)
        _StatusBar(state: state, isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BoardProgressBar(progress: state.progress),
        ),
        // 보드
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: MinesweeperBoardWidget(
              board: state.current,
              solution: state.solution,
              selectedCell: state.selectedCell,
              hintTargetCell: state.hintTargetCell,
              onCellTap: (r, c) => notifier.tapCell(r, c),
              onCellLongPress: (r, c) => notifier.longPressCell(r, c),
              onCellDoubleTap: (r, c) => notifier.doubleTapCell(r, c),
            ),
          ),
        ),
        // 힌트 메시지 영역
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: state.lastHintResult != null
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3)
                      : Colors.amber.shade50,
                  child: Text(
                    state.lastHintResult!.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // 컨트롤 바
        _ControlBar(state: state, notifier: notifier, isDark: isDark),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, MinesweeperState state, bool isDark) {
    final notifier = ref.read(minesweeperNotifierProvider.notifier);

    return Row(
      children: [
        // 보드 (좌측)
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: MinesweeperBoardWidget(
              board: state.current,
              solution: state.solution,
              selectedCell: state.selectedCell,
              hintTargetCell: state.hintTargetCell,
              onCellTap: (r, c) => notifier.tapCell(r, c),
              onCellLongPress: (r, c) => notifier.longPressCell(r, c),
              onCellDoubleTap: (r, c) => notifier.doubleTapCell(r, c),
            ),
          ),
        ),
        // 컨트롤 (우측)
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 상단 바
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => _showExitDialog(context),
                  ),
                  Text(AppStrings.get('minesweeper.title')),
                  IconButton(
                    icon: const Icon(Icons.pause_rounded),
                    onPressed: () => notifier.pause(),
                  ),
                ],
              ),
              _StatusBar(state: state, isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BoardProgressBar(progress: state.progress),
        ),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: state.lastHintResult != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          state.lastHintResult!.message,
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const Spacer(),
              _ControlBar(state: state, notifier: notifier, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }

  /// 일시정지 화면 (스도쿠/비나이로와 동일한 구성)
  Widget _buildPauseScreen(BuildContext context, MinesweeperState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(minesweeperNotifierProvider.notifier);

    final minutes = state.elapsedSeconds ~/ 60;
    final secs = state.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) notifier.resume();
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
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                  const SizedBox(height: 16),
                  // 일시정지 메시지 (스도쿠/비나이로와 동일)
                  Text(
                    AppStrings.get('pause.message'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  // 경과 시간 표시
                  Text(
                    '${AppStrings.get('pause.elapsed')}$timeText',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                  ),
                  const SizedBox(height: 48),
                  // 1. 재개 (ElevatedButton)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => notifier.resume(),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(AppStrings.get('pause.resume')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 2. 홈으로 (OutlinedButton)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.minesweeper),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(AppStrings.get('pause.home')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 3. 포기 (TextButton, 빨간색)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showGiveUpDialog(context),
                      icon: const Icon(Icons.flag_outlined, color: Colors.red),
                      label: Text(
                        AppStrings.get('pause.giveUp'),
                        style: const TextStyle(color: Colors.red),
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

  /// 결과 화면 (스도쿠와 동일한 구성)
  Widget _buildResultScreen(BuildContext context, MinesweeperState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(minesweeperNotifierProvider.notifier);
    final grade = state.grade;
    final minutes = state.elapsedSeconds ~/ 60;
    final secs = state.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final gradeColor = switch (grade) {
      MinesweeperGrade.perfect => Colors.amber,
      MinesweeperGrade.excellent => const Color(0xFF4CAF50),
      MinesweeperGrade.great => const Color(0xFF2196F3),
      MinesweeperGrade.good => Colors.grey,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          notifier.giveUp();
          context.go(AppRoutes.minesweeper);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 등급 배지
                  AnimatedTrophy(

                    glowColor: gradeColor,

                    child: Container(

                      width: 80, height: 80,

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
                  const SizedBox(height: 8),
                  Text(grade.label,
                    style: TextStyle(fontSize: 16, color: gradeColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // 통계
                  _StatRow(label: AppStrings.get('result.time'), value: timeText, isDark: isDark, valueWidget: CountUpText(value: state.elapsedSeconds, formatter: (v) => '${(v ~/ 60).toString().padLeft(2, "0")}:${(v % 60).toString().padLeft(2, "0")}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  _StatRow(label: AppStrings.get('result.difficulty'), value: state.difficulty.label, isDark: isDark),
                  _StatRow(label: AppStrings.get('result.mistakes'), value: '${state.mistakeCount}', isDark: isDark),
                  _StatRow(label: AppStrings.get('result.hints'), value: '${state.hintCount}', isDark: isDark),
                  const SizedBox(height: 16),

                  // 새 배지 칩
                  if (notifier.lastNewBadges.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(AppStrings.get('result.newBadges'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: notifier.lastNewBadges.map((b) => Chip(
                        avatar: Text(b.icon),
                        label: Text(b.name, style: const TextStyle(fontSize: 12)),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        notifier.giveUp();
                        _showDifficultyPickerForNewGame(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(AppStrings.get('result.newGame')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        notifier.giveUp();
                        context.go(AppRoutes.minesweeper);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(AppStrings.get('result.home')),
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

  void _showExitDialog(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('exit.title'),
      content: AppStrings.get('exit.message'),
      confirmLabel: AppStrings.get('exit.confirm'),
      cancelLabel: AppStrings.get('cancel'),
      onConfirm: () {
        ref.read(minesweeperNotifierProvider.notifier).pause();
        context.go(AppRoutes.minesweeper);
      },
    );
  }

  void _showGiveUpDialog(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('giveUp.title'),
      content: AppStrings.get('giveUp.message'),
      confirmLabel: AppStrings.get('giveUp.confirm'),
      cancelLabel: AppStrings.get('cancel'),
      isDanger: true,
      onConfirm: () {
        ref.read(minesweeperNotifierProvider.notifier).giveUp();
        context.go(AppRoutes.minesweeper);
      },
    );
  }

  void _showBadgePopup(BuildContext context) {
    final notifier = ref.read(minesweeperNotifierProvider.notifier);
    if (notifier.lastNewBadges.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Text('🎉 '),
            Text(AppStrings.get('badge.newBadge')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: notifier.lastNewBadges.map((b) => ListTile(
            leading: Text(b.icon, style: const TextStyle(fontSize: 28)),
            title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(b.description),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('ok')),
          ),
        ],
      ),
    );
  }

  void _showDifficultyPickerForNewGame(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 컨텐츠 전체 크기 사용 (하단 잘림 방지)
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 시각적 핸들 (BottomSheet 힌트)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                AppStrings.get('minesweeper.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...MinesweeperDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ref.read(minesweeperNotifierProvider.notifier).startNewGame(
                                mode: MinesweeperGameMode.classic,
                                difficulty: diff,
                              );
                        },
                        leading: Container(
                          width: 4, height: 36,
                          decoration: BoxDecoration(
                            color: _diffColor(diff),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(diff.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${diff.gridSize}×${diff.gridSize}  💣${diff.mineCount}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Color _diffColor(MinesweeperDifficulty diff) {
    switch (diff) {
      case MinesweeperDifficulty.beginner: return Colors.green;
      case MinesweeperDifficulty.easy: return Colors.lightGreen;
      case MinesweeperDifficulty.medium: return Colors.orange;
      case MinesweeperDifficulty.hard: return Colors.deepOrange;
      case MinesweeperDifficulty.master: return Colors.purple;
    }
  }
}

/// 상태 바 (타이머, 실수, 남은 지뢰)
class _StatusBar extends StatelessWidget {
  final MinesweeperState state;
  final bool isDark;

  const _StatusBar({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final minutes = state.elapsedSeconds ~/ 60;
    final secs = state.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatusChip(icon: Icons.timer_outlined, value: timeText, isDark: isDark),
          _StatusChip(icon: Icons.close_rounded, value: '${state.mistakeCount}', isDark: isDark, color: Colors.red),
          _StatusChip(icon: Icons.flag_rounded, value: '${state.remainingMines}', isDark: isDark, color: Colors.orange),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;
  final Color? color;

  const _StatusChip({required this.icon, required this.value, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color ?? (isDark ? Colors.white54 : Colors.black45)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
      ],
    );
  }
}

/// 컨트롤 바
class _ControlBar extends StatelessWidget {
  final MinesweeperState state;
  final MinesweeperNotifier notifier;
  final bool isDark;

  const _ControlBar({required this.state, required this.notifier, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isRevealMode = state.inputMode == MinesweeperInputMode.reveal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 열기 모드
          _ModeButton(
            icon: Icons.touch_app_rounded,
            label: AppStrings.get('minesweeper.input.open'),
            isSelected: isRevealMode,
            isDark: isDark,
            onTap: () => notifier.setInputMode(MinesweeperInputMode.reveal),
          ),
          const SizedBox(width: 12),
          // 깃발 모드
          _ModeButton(
            icon: Icons.flag_rounded,
            label: AppStrings.get('minesweeper.input.flag'),
            isSelected: !isRevealMode,
            isDark: isDark,
            onTap: () => notifier.setInputMode(MinesweeperInputMode.flag),
          ),
          const SizedBox(width: 24),
          // 힌트
          IconButton(
            onPressed: () => notifier.getHint(),
            icon: const Icon(Icons.lightbulb_outline_rounded),
            tooltip: AppStrings.get('hint'),
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

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18,
              color: isSelected ? selectedColor : (isDark ? Colors.white54 : Colors.black45)),
            const SizedBox(width: 4),
            Text(label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? selectedColor : (isDark ? Colors.white54 : Colors.black45),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 통계 행
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  final Widget? valueWidget;
  const _StatRow({required this.label, required this.value, required this.isDark, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          valueWidget ?? Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
