import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../../../shared/constants/app_colors.dart';
import '../yin_yang_notifier.dart';
import '../yin_yang_state.dart';
import '../widgets/yin_yang_board_widget.dart';
import '../../../shared/widgets/checkpoint_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/board_progress_bar.dart';
import '../../../shared/widgets/animated_trophy.dart';
import '../../../shared/widgets/count_up_text.dart';

/// 음양 게임 플레이 화면 (지뢰찾기 패턴: ConsumerStatefulWidget + 배지 팝업)
class YinYangGameScreen extends ConsumerStatefulWidget {
  const YinYangGameScreen({super.key});

  @override
  ConsumerState<YinYangGameScreen> createState() => _YinYangGameScreenState();
}

class _YinYangGameScreenState extends ConsumerState<YinYangGameScreen> {
  bool _badgePopupShown = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(yinYangNotifierProvider);
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
  Widget _buildPlayScreen(BuildContext context, YinYangState state) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(yinYangNotifierProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        appBar: isLandscape ? null : AppBar(
          title: Text(AppStrings.get('yinyang.title')),
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

  /// 세로 모드 레이아웃
  Widget _buildPortraitLayout(BuildContext context, YinYangState state, bool isDark) {
    return Column(
      children: [
        _GameInfoBar(gameState: state),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BoardProgressBar(progress: state.progress),
        ),
        const SizedBox(height: 8),
        // 보드
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: const YinYangBoardWidget(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 힌트 메시지
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: state.lastHintResult != null
              ? _HintMessageBar(message: state.lastHintResult!.message)
              : const SizedBox.shrink(),
        ),
        // 컨트롤 바
        _ControlBar(gameState: state),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 가로 모드 레이아웃
  Widget _buildLandscapeLayout(BuildContext context, YinYangState state, bool isDark) {
    final notifier = ref.read(yinYangNotifierProvider.notifier);

    return Row(
      children: [
        // 좌측: 보드
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: const Center(child: YinYangBoardWidget()),
          ),
        ),
        // 우측: 정보 + 컨트롤
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: [
                // 가로 모드 상단
                Row(
                  children: [
                    SizedBox(
                      width: 40, height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        onPressed: () => _showExitDialog(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.get('yinyang.title'),
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 40, height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.pause_rounded, size: 20),
                        onPressed: () => notifier.pause(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _GameInfoBar(gameState: state),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BoardProgressBar(progress: state.progress),
        ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: state.lastHintResult != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _HintMessageBar(message: state.lastHintResult!.message),
                        )
                      : const SizedBox.shrink(),
                ),
                const Expanded(child: SizedBox()),
                _ControlBar(gameState: state),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 일시정지 화면 (공통 키 사용: pause.resume, pause.home, pause.giveUp)
  Widget _buildPauseScreen(BuildContext context, YinYangState state) {
    final notifier = ref.read(yinYangNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seconds = state.elapsedSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
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
                      onPressed: () => context.go(AppRoutes.yinYang),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(AppStrings.get('pause.home')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 3. 포기
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showGiveUpDialog(context),
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

  /// 결과 화면
  Widget _buildResultScreen(BuildContext context, YinYangState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(yinYangNotifierProvider.notifier);
    final grade = state.grade;
    final minutes = state.elapsedSeconds ~/ 60;
    final secs = state.elapsedSeconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final gradeColor = switch (grade) {
      YinYangGrade.perfect => Colors.amber,
      YinYangGrade.excellent => const Color(0xFF4CAF50),
      YinYangGrade.great => const Color(0xFF2196F3),
      YinYangGrade.good => Colors.grey,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          notifier.giveUp();
          context.go(AppRoutes.yinYang);
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
                  _StatRow(label: AppStrings.get('result.difficulty'),
                    value: '${state.difficulty.label} (${state.size}x${state.size})', isDark: isDark),
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
                        context.go(AppRoutes.yinYang);
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
        ref.read(yinYangNotifierProvider.notifier).pause();
        context.go(AppRoutes.yinYang);
      },
    );
  }

  void _showGiveUpDialog(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('pause.giveUp.title'),
      content: AppStrings.get('pause.giveUp.message'),
      confirmLabel: AppStrings.get('pause.giveUp.action'),
      cancelLabel: AppStrings.get('cancel'),
      isDanger: true,
      onConfirm: () {
        ref.read(yinYangNotifierProvider.notifier).giveUp();
        context.go(AppRoutes.yinYang);
      },
    );
  }

  void _showBadgePopup(BuildContext context) {
    final notifier = ref.read(yinYangNotifierProvider.notifier);
    if (notifier.lastNewBadges.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Text('🎉 '),
            Text(AppStrings.get('result.newBadges')),
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
            child: Text(AppStrings.get('confirm')),
          ),
        ],
      ),
    );
  }

  void _showDifficultyPickerForNewGame(BuildContext context) {
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
                AppStrings.get('yinyang.selectDifficulty'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...YinYangDifficulty.values.map((diff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.of(ctx).pop();
                          ref.read(yinYangNotifierProvider.notifier).startNewGame(
                                mode: YinYangGameMode.classic,
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

  Color _diffColor(YinYangDifficulty diff) {
    switch (diff) {
      case YinYangDifficulty.beginner: return Colors.green;
      case YinYangDifficulty.easy: return Colors.lightGreen;
      case YinYangDifficulty.medium: return Colors.orange;
      case YinYangDifficulty.hard: return Colors.deepOrange;
      case YinYangDifficulty.master: return Colors.purple;
    }
  }
}

/// 게임 정보 바 (난이도, 크기, 타이머)
class _GameInfoBar extends StatelessWidget {
  final YinYangState gameState;
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
          // 난이도 + 크기
          Text(
            '${gameState.difficulty.label} (${gameState.size}x${gameState.size})',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
          ),
          // 실수
          Row(
            children: [
              Icon(Icons.close_rounded, size: 16,
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
          // 타이머
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16,
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

/// 하단 조작 버튼 바 (이진 토글: ●(흑) / ○(백) / 지우개)
class _ControlBar extends ConsumerWidget {
  final YinYangState gameState;
  const _ControlBar({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(yinYangNotifierProvider.notifier);
    final currentMode = gameState.inputMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 입력 모드 토글 바 (● / ○ / 지우개)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ● 흑
                _ToggleButton(
                  label: AppStrings.get('yinyang.input.black'),
                  symbolLabel: '●',
                  isSelected: currentMode == YinYangInputMode.black,
                  onTap: () => notifier.setInputMode(YinYangInputMode.black),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                // ○ 백
                _ToggleButton(
                  label: AppStrings.get('yinyang.input.white'),
                  symbolLabel: '○',
                  isSelected: currentMode == YinYangInputMode.white,
                  onTap: () => notifier.setInputMode(YinYangInputMode.white),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                // 지우개
                _ToggleButton(
                  icon: Icons.auto_fix_high_rounded,
                  isSelected: currentMode == YinYangInputMode.erase,
                  onTap: () => notifier.setInputMode(YinYangInputMode.erase),
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

/// 액션 버튼 (되돌리기, 힌트)
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
            ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))
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

/// 입력 모드 토글 버튼 (● / ○ / 지우개)
class _ToggleButton extends StatelessWidget {
  final String? label;
  final String? symbolLabel;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ToggleButton({
    this.label,
    this.symbolLabel,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark ? Colors.blue.shade700 : Colors.blue.shade100;
    final unselectedBg = Colors.transparent;
    final selectedFg = isDark ? Colors.white : Colors.blue.shade800;
    final unselectedFg = isDark ? Colors.white54 : Colors.black45;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: symbolLabel != null
              ? Text(
                  symbolLabel!,
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

/// 힌트 메시지 표시 바
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
          Icon(Icons.lightbulb_rounded, size: 16,
              color: isDark ? Colors.amber.shade300 : Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.amber.shade100 : Colors.amber.shade900,
              ),
            ),
          ),
        ],
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
