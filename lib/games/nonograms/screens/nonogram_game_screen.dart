import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/constants/app_colors.dart';
import '../nonogram_notifier.dart';
import '../nonogram_state.dart';
import '../widgets/nonogram_board_widget.dart';
import '../../../shared/widgets/checkpoint_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/board_progress_bar.dart';
import '../../../shared/widgets/animated_trophy.dart';
import '../../../shared/widgets/count_up_text.dart';

/// 노노그램 게임 플레이 화면
class NonogramGameScreen extends ConsumerStatefulWidget {
  const NonogramGameScreen({super.key});

  @override
  ConsumerState<NonogramGameScreen> createState() => _NonogramGameScreenState();
}

class _NonogramGameScreenState extends ConsumerState<NonogramGameScreen> {
  bool _badgePopupShown = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(nonogramNotifierProvider);
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
  Widget _buildPlayScreen(BuildContext context, NonogramState state) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(nonogramNotifierProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        appBar: isLandscape ? null : AppBar(
          title: Text(AppStrings.get('nonogram.title')),
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

  Widget _buildPortraitLayout(BuildContext context, NonogramState state, bool isDark) {
    final notifier = ref.read(nonogramNotifierProvider.notifier);

    return Column(
      children: [
        // 상태 바 (타이머, 실수, 힌트)
        _StatusBar(state: state, isDark: isDark),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BoardProgressBar(progress: state.progress),
        ),
        // 보드
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: NonogramBoardWidget(
              board: state.current,
              solution: state.solution,
              selectedCell: state.selectedCell,
              hintTargetCell: state.hintTargetCell,
              onCellTap: (r, c) => notifier.tapCell(r, c),
              onCellLongPress: (r, c) {
                // 롱프레스: 크로스 토글
                notifier.setInputMode(NonogramInputMode.cross);
                notifier.tapCell(r, c);
                notifier.setInputMode(state.inputMode);
              },
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
        _ControlBar(
              state: state,
              notifier: notifier,
              isDark: isDark,
              onVerify: () => _onVerify(context, notifier),
            ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, NonogramState state, bool isDark) {
    final notifier = ref.read(nonogramNotifierProvider.notifier);

    return Row(
      children: [
        // 보드 (좌측)
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: NonogramBoardWidget(
              board: state.current,
              solution: state.solution,
              selectedCell: state.selectedCell,
              hintTargetCell: state.hintTargetCell,
              onCellTap: (r, c) => notifier.tapCell(r, c),
              onCellLongPress: (r, c) {
                notifier.setInputMode(NonogramInputMode.cross);
                notifier.tapCell(r, c);
                notifier.setInputMode(state.inputMode);
              },
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
                  Text(AppStrings.get('nonogram.title')),
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
              _ControlBar(
              state: state,
              notifier: notifier,
              isDark: isDark,
              onVerify: () => _onVerify(context, notifier),
            ),
            ],
          ),
        ),
      ],
    );
  }

  /// 일시정지 화면 (스도쿠/비나이로와 동일 구성)
  Widget _buildPauseScreen(BuildContext context, NonogramState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(nonogramNotifierProvider.notifier);

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
                  // 1. 재개
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
                  // 2. 홈으로
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.nonograms),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(AppStrings.get('pause.home')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 3. 포기 (빨간색)
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

  /// 결과 화면
  Widget _buildResultScreen(BuildContext context, NonogramState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(nonogramNotifierProvider.notifier);
    final grade = state.grade;
    final minutes = state.elapsedSeconds ~/ 60;
    final secs = state.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final gradeColor = switch (grade) {
      NonogramGrade.perfect => Colors.amber,
      NonogramGrade.excellent => const Color(0xFF4CAF50),
      NonogramGrade.great => const Color(0xFF2196F3),
      NonogramGrade.good => Colors.grey,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          notifier.giveUp();
          context.go(AppRoutes.nonograms);
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
                  // 정통 노노그램: 실수 표시 없음 (시간/난이도/힌트 3개)
                  _StatRow(label: AppStrings.get('result.time'), value: timeText, isDark: isDark, valueWidget: CountUpText(value: state.elapsedSeconds, formatter: (v) => '\${(v ~/ 60).toString().padLeft(2, "0")}:\${(v % 60).toString().padLeft(2, "0")}', style: const TextStyle(fontWeight: FontWeight.w600))),
                  _StatRow(label: AppStrings.get('result.difficulty'), value: state.difficulty.label, isDark: isDark),
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
                        context.go(AppRoutes.nonograms);
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('exit.title')),
        content: Text(AppStrings.get('exit.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(nonogramNotifierProvider.notifier).pause();
              context.go(AppRoutes.nonograms);
            },
            child: Text(AppStrings.get('exit.confirm')),
          ),
        ],
      ),
    );
  }

  void _showGiveUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('giveUp.title')),
        content: Text(AppStrings.get('giveUp.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(nonogramNotifierProvider.notifier).giveUp();
              context.go(AppRoutes.nonograms);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.get('giveUp.confirm')),
          ),
        ],
      ),
    );
  }

  /// 확인 버튼 핸들러 — 정통 노노그램 검증
  ///
  /// 정답이면 _checkCompletion이 완료 화면으로 전환한다.
  /// 정답이 아니면 토스트만 표시하고 틀린 위치는 알려주지 않는다.
  void _onVerify(BuildContext context, NonogramNotifier notifier) {
    final ok = notifier.verify();
    if (!ok) {
      // 실패: 약한 햅틱 + 토스트 (틀린 위치 비공개)
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('nonogram.verify.fail')),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        ),
      );
    }
    // 성공이면 _checkCompletion이 자동으로 결과 화면으로 전환
  }

  void _showBadgePopup(BuildContext context) {
    final notifier = ref.read(nonogramNotifierProvider.notifier);
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
        top: false, // 모달이라 상단 padding 불필요
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom, // 키보드/시스템바 대응
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
                AppStrings.get('nonogram.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...NonogramDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ref.read(nonogramNotifierProvider.notifier).startNewGame(
                                mode: NonogramGameMode.classic,
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
                        subtitle: Text('${diff.gridSize}x${diff.gridSize}'),
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

  Color _diffColor(NonogramDifficulty diff) {
    switch (diff) {
      case NonogramDifficulty.beginner: return Colors.green;
      case NonogramDifficulty.easy: return Colors.lightGreen;
      case NonogramDifficulty.medium: return Colors.orange;
      case NonogramDifficulty.hard: return Colors.deepOrange;
    }
  }
}

/// 상태 바 (타이머, 힌트)
///
/// 정통 노노그램 방식: 실수 카운트 표시 없음.
/// 시간과 힌트 사용량만 노출한다.
class _StatusBar extends StatelessWidget {
  final NonogramState state;
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
          _StatusChip(icon: Icons.lightbulb_outline, value: '${state.hintCount}', isDark: isDark, color: Colors.amber),
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

/// 컨트롤 바: [■ 채우기] [✕ 지우기] [↩ 되돌리기] [💡 힌트] [📌 체크포인트] [✓ 확인]
class _ControlBar extends StatelessWidget {
  final NonogramState state;
  final NonogramNotifier notifier;
  final bool isDark;

  /// 확인 버튼 콜백 (정통 노노그램 명시적 검증)
  final VoidCallback onVerify;

  const _ControlBar({
    required this.state,
    required this.notifier,
    required this.isDark,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final isFillMode = state.inputMode == NonogramInputMode.fill;
    final isCrossMode = state.inputMode == NonogramInputMode.cross;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ■ 채우기 모드
          _ModeButton(
            icon: Icons.square_rounded,
            label: AppStrings.get('nonogram.input.fill'),
            isSelected: isFillMode,
            isDark: isDark,
            onTap: () => notifier.setInputMode(NonogramInputMode.fill),
          ),
          const SizedBox(width: 8),
          // ✕ 지우기 (크로스) 모드
          _ModeButton(
            icon: Icons.close_rounded,
            label: AppStrings.get('nonogram.input.cross'),
            isSelected: isCrossMode,
            isDark: isDark,
            onTap: () => notifier.setInputMode(NonogramInputMode.cross),
          ),
          const SizedBox(width: 16),
          // ↩ 되돌리기
          IconButton(
            onPressed: state.undoStack.isNotEmpty ? () => notifier.undo() : null,
            icon: const Icon(Icons.undo_rounded),
            tooltip: AppStrings.get('undo'),
          ),
          // 💡 힌트
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
                showCheckpointToast(context, 'checkpoint.restored');
              } else {
                notifier.saveCheckpoint();
                showCheckpointToast(context, 'checkpoint.saved');
              }
            },
            onLongPress: () {
              notifier.clearCheckpoint();
              showCheckpointToast(context, 'checkpoint.cleared');
            },
          ),
          const SizedBox(width: 8),
          // ✓ 확인 (정통 노노그램 명시적 검증)
          IconButton(
            onPressed: onVerify,
            icon: const Icon(Icons.check_circle_outline_rounded),
            tooltip: AppStrings.get('nonogram.verify'),
            color: Colors.green,
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
