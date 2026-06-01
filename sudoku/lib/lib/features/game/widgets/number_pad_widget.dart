import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/l10n/app_strings.dart';
import '../game_notifier.dart';
import '../game_state.dart';
import '../../../core/sudoku/board.dart';
import '../../../shared/constants/app_colors.dart';

/// 하단 숫자 패드 (1~9 + 기능 버튼)
class NumberPadWidget extends ConsumerWidget {
  const NumberPadWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 기능 버튼 행: 되돌리기, 삭제, 메모, 힌트
        _buildToolRow(context, ref, gameState, isDark, isLandscape),
        SizedBox(height: isLandscape ? 4 : 8),
        // 숫자 버튼 1~9
        _buildNumberRow(context, ref, gameState, isDark, isLandscape),
      ],
    );
  }

  Widget _buildToolRow(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
    bool isDark,
    bool isLandscape,
  ) {
    final notifier = ref.read(gameProvider.notifier);
    final isMemoMode = gameState.isMemoMode;
    final isNumberFirst = gameState.inputMode == InputMode.numberFirst;

    final buttons = [
      _ToolButton(
        icon: Icons.undo_rounded,
        label: AppStrings.get('game.undo'),
        onTap: gameState.undoStack.isEmpty ? null : () => notifier.undo(),
        isDark: isDark,
        compact: isLandscape,
      ),
      _ToolButton(
        icon: Icons.backspace_outlined,
        label: AppStrings.get('game.delete'),
        onTap: () => notifier.deleteValue(),
        isDark: isDark,
        compact: isLandscape,
      ),
      _ToolButton(
        icon: Icons.edit_note_rounded,
        label: AppStrings.get('game.memo'),
        onTap: () => notifier.toggleMemoMode(),
        isActive: isMemoMode,
        isDark: isDark,
        compact: isLandscape,
      ),
      _ToolButton(
        icon: Icons.auto_fix_high_rounded,
        label: AppStrings.get('game.autoMemo'),
        onTap: () => notifier.autoFillNotes(),
        isDark: isDark,
        compact: isLandscape,
      ),
      _ToolButton(
        icon: isNumberFirst ? Icons.grid_on_rounded : Icons.pin_rounded,
        label: isNumberFirst ? AppStrings.get('game.cellFirst') : AppStrings.get('game.numberFirst'),
        onTap: () => notifier.toggleInputMode(),
        isActive: isNumberFirst,
        isDark: isDark,
        compact: isLandscape,
      ),
      _ToolButton(
        icon: Icons.lightbulb_outline_rounded,
        label: AppStrings.get('game.hint'),
        onTap: gameState.isHintDisabled ? null : () => notifier.useHint(),
        isDark: isDark,
        compact: isLandscape,
      ),
    ];

    // 가로 모드: Wrap으로 2줄 배치하여 오버플로우 방지
    if (isLandscape) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 2,
        children: buttons,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }

  Widget _buildNumberRow(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
    bool isDark,
    bool isLandscape,
  ) {
    final notifier = ref.read(gameProvider.notifier);

    // 각 숫자별 남은 개수 계산 (9개 모두 채워지면 비활성)
    final remainingCounts = _calcRemainingCounts(gameState.board, gameState.showMistakes);
    // 완성된 숫자 집합 (9개 모두 정답으로 채워진 숫자)
    final completedNumbers = _getCompletedNumbers(gameState.board);

    final isNumberFirst = gameState.inputMode == InputMode.numberFirst;

    final buttons = List.generate(9, (i) {
      final number = i + 1;
      final remaining = remainingCounts[number] ?? 0;
      final isExhausted = remaining <= 0;
      final isCompleted = completedNumbers.contains(number);
      final isSelected = isNumberFirst && gameState.selectedNumber == number;

      return _NumberButton(
        number: number,
        remaining: remaining,
        isExhausted: isExhausted,
        isCompleted: isCompleted,
        isSelected: isSelected,
        isDark: isDark,
        compact: isLandscape,
        onTap: isExhausted
            ? null
            : isNumberFirst
                ? () => notifier.selectNumber(number)
                : () => notifier.inputNumber(number),
      );
    });

    // 가로 모드: Wrap으로 배치 (공간 부족 시 줄바꿈)
    if (isLandscape) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: buttons,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons,
    );
  }

  /// 각 숫자(1~9)가 보드에서 몇 개 남았는지 계산
  /// showMistakes가 false이면 오답도 포함해 카운트 (정보 노출 방지)
  Map<int, int> _calcRemainingCounts(SudokuBoard board, bool showMistakes) {
    final counts = <int, int>{};
    for (var n = 1; n <= 9; n++) {
      counts[n] = 9;
    }
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = board.currentBoard[r][c];
        if (v > 0) {
          // showMistakes가 true이면 정답만 카운트, false이면 모든 입력 카운트
          if (showMistakes && board.isWrong(r, c)) continue;
          counts[v] = (counts[v] ?? 0) - 1;
        }
      }
    }
    return counts;
  }

  /// 9개 모두 정답으로 채워진 숫자 집합
  Set<int> _getCompletedNumbers(SudokuBoard board) {
    final correctCounts = <int, int>{};
    for (var n = 1; n <= 9; n++) {
      correctCounts[n] = 0;
    }
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final v = board.currentBoard[r][c];
        if (v > 0 && !board.isWrong(r, c)) {
          correctCounts[v] = (correctCounts[v] ?? 0) + 1;
        }
      }
    }
    return correctCounts.entries
        .where((e) => e.value >= 9)
        .map((e) => e.key)
        .toSet();
  }
}

/// 기능 버튼 (되돌리기, 삭제, 메모, 힌트)
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDark;
  final bool compact; // 가로 모드 컴팩트 버전

  const _ToolButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final normalColor = isDark ? Colors.white70 : Colors.black87;
    final disabledColor = isDark ? Colors.white24 : Colors.black26;

    final color = isDisabled
        ? disabledColor
        : isActive
            ? activeColor
            : normalColor;

    final iconSize = compact ? 20.0 : 24.0;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: isActive
                    ? BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                padding: EdgeInsets.all(compact ? 4 : 6),
                child: Icon(icon, size: iconSize, color: color),
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 숫자 버튼 (1~9)
class _NumberButton extends StatelessWidget {
  final int number;
  final int remaining;
  final bool isExhausted;
  final bool isCompleted;
  final bool isSelected;
  final bool isDark;
  final bool compact; // 가로 모드 컴팩트 버전
  final VoidCallback? onTap;

  const _NumberButton({
    required this.number,
    required this.remaining,
    required this.isExhausted,
    required this.isCompleted,
    this.isSelected = false,
    required this.isDark,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final disabledColor = isDark ? Colors.white24 : Colors.black26;
    final completedColor = const Color(0xFF4CAF50);
    final textColor = isCompleted
        ? completedColor
        : isExhausted
            ? disabledColor
            : activeColor;

    final buttonWidth = compact ? 30.0 : 36.0;
    final buttonHeight = compact ? 42.0 : 52.0;
    final fontSize = compact ? 20.0 : 24.0;

    return Semantics(
      button: true,
      label: '숫자 $number${isCompleted ? ', 완성' : isExhausted ? ', 모두 채움' : ', 남은 수 $remaining'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
          decoration: isSelected
              ? BoxDecoration(
                  color: activeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeColor, width: 2),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$number',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (isCompleted)
                Icon(Icons.check_circle_rounded, size: compact ? 10 : 12, color: completedColor)
              else if (!isExhausted)
                Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
