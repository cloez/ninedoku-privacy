import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_notifier.dart';
import '../game_state.dart';
import '../../../core/sudoku/board.dart';
import '../../../shared/constants/app_colors.dart';

/// 9x9 스도쿠 보드 위젯
class SudokuBoardWidget extends ConsumerWidget {
  const SudokuBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.boardLineDark : AppColors.boardLineLight,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            final row = index ~/ 9;
            final col = index % 9;
            return _CellWidget(row: row, col: col);
          },
        ),
      ),
    );
  }
}

class _CellWidget extends ConsumerWidget {
  final int row;
  final int col;

  const _CellWidget({required this.row, required this.col});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    if (gameState == null) return const SizedBox.shrink();

    final board = gameState.board;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = gameState.selectedCell == (row, col);
    final isFixed = board.isFixed[row][col];
    final notes = board.notes[row][col];

    // 자동완성 중: 아직 표시 안 된 셀은 값을 숨김
    final autoCompleteIndex = _getAutoCompleteIndex(gameState);
    final isAutoCompleteHidden = autoCompleteIndex != null &&
        autoCompleteIndex >= gameState.autoCompleteStep;
    final isAutoCompleteRevealed = autoCompleteIndex != null &&
        autoCompleteIndex < gameState.autoCompleteStep;
    final value = isAutoCompleteHidden ? 0 : board.currentBoard[row][col];
    final isWrong = gameState.showMistakes && value != 0 && board.isWrong(row, col);

    // 완성된 숫자인지 확인 (9개 모두 정답으로 채워진 숫자)
    final isCompletedNumber = value > 0 && !board.isWrong(row, col) && _isNumberCompleted(board, value);

    // 하이라이트 판정
    final isHighlighted = _isHighlighted(gameState);
    final isSameNumber = _isSameNumber(gameState, value);

    // 릴렉스 모드 오답 플래시 여부
    final isWrongFlash = gameState.wrongFlashCell == (row, col);

    // 셀 배경색
    Color bgColor;
    if (isAutoCompleteRevealed) {
      // 자동완성으로 채워진 셀: 초록 하이라이트
      bgColor = isDark
          ? Colors.green.shade800.withValues(alpha: 0.4)
          : Colors.green.shade100;
    } else if (isWrongFlash) {
      // 릴렉스 모드 오답 플래시: 붉은 배경
      bgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.5) : Colors.red.shade100;
    } else if (isSelected) {
      bgColor = isDark ? AppColors.cellSelectedDark : AppColors.cellSelectedLight;
    } else if (isSameNumber) {
      bgColor = isDark ? AppColors.cellSameNumberDark : AppColors.cellSameNumberLight;
    } else if (isHighlighted) {
      bgColor = isDark ? AppColors.cellHighlightDark : AppColors.cellHighlightLight;
    } else {
      bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    }

    // 3x3 박스 경계선
    final rightBorder = (col + 1) % 3 == 0 && col < 8 ? 2.0 : 0.5;
    final bottomBorder = (row + 1) % 3 == 0 && row < 8 ? 2.0 : 0.5;
    final borderColor = isDark ? AppColors.boardLineDark : AppColors.boardLineLight;

    return GestureDetector(
      onTap: () => ref.read(gameProvider.notifier).selectCell(row, col),
      child: Semantics(
        label: '행 ${row + 1}, 열 ${col + 1}${value > 0 ? ', 값 $value' : ', 비어있음'}${isFixed ? ', 고정' : ''}',
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              right: BorderSide(color: borderColor, width: rightBorder),
              bottom: BorderSide(color: borderColor, width: bottomBorder),
              left: col % 3 == 0 && col > 0
                  ? BorderSide(color: borderColor, width: 0.0)
                  : BorderSide.none,
              top: row % 3 == 0 && row > 0
                  ? BorderSide(color: borderColor, width: 0.0)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: value > 0
                ? _buildNumberText(context, value, isFixed, isWrong, isDark, isCompletedNumber)
                : notes.isNotEmpty
                    ? _buildNotesGrid(context, notes, isDark, _getHighlightNumber(gameState))
                    : null,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberText(
    BuildContext context,
    int value,
    bool isFixed,
    bool isWrong,
    bool isDark,
    bool isCompletedNumber,
  ) {
    Color textColor;
    if (isWrong) {
      textColor = isDark ? AppColors.wrongNumberDark : AppColors.wrongNumberLight;
    } else if (isCompletedNumber) {
      // 완성된 숫자는 약간 투명하게 표시
      textColor = (isFixed
              ? (isDark ? AppColors.fixedNumberDark : AppColors.fixedNumberLight)
              : (isDark ? AppColors.userNumberDark : AppColors.userNumberLight))
          .withValues(alpha: 0.45);
    } else if (isFixed) {
      textColor = isDark ? AppColors.fixedNumberDark : AppColors.fixedNumberLight;
    } else {
      textColor = isDark ? AppColors.userNumberDark : AppColors.userNumberLight;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 22,
          fontWeight: isFixed ? FontWeight.bold : FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  /// 특정 숫자가 보드에서 9개 모두 정답으로 채워졌는지 확인
  bool _isNumberCompleted(SudokuBoard board, int number) {
    var count = 0;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.currentBoard[r][c] == number && !board.isWrong(r, c)) {
          count++;
        }
      }
    }
    return count >= 9;
  }

  /// 현재 하이라이트할 숫자 (선택된 셀의 값 또는 숫자 우선 모드의 선택 숫자)
  int? _getHighlightNumber(GameState gameState) {
    // 숫자 우선 모드에서 선택된 숫자
    if (gameState.inputMode == InputMode.numberFirst && gameState.selectedNumber != null) {
      return gameState.selectedNumber;
    }
    // 선택된 셀의 값
    if (gameState.selectedCell != null) {
      final (r, c) = gameState.selectedCell!;
      final v = gameState.board.currentBoard[r][c];
      if (v > 0) return v;
    }
    return null;
  }

  Widget _buildNotesGrid(BuildContext context, Set<int> notes, bool isDark, int? highlightNumber) {
    final noteColor = isDark ? AppColors.noteNumberDark : AppColors.noteNumberLight;
    // 같은 숫자 하이라이트 색상 (진한 파란색 계열)
    final highlightColor = isDark ? AppColors.userNumberDark : AppColors.userNumberLight;

    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(1),
      children: List.generate(9, (i) {
        final n = i + 1;
        final isHighlit = highlightNumber != null && n == highlightNumber && notes.contains(n);
        return Center(
          child: Container(
            decoration: isHighlit
                ? BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  )
                : null,
            child: Text(
              notes.contains(n) ? '$n' : '',
              style: TextStyle(
                fontSize: 9,
                color: isHighlit ? highlightColor : noteColor,
                fontWeight: isHighlit ? FontWeight.bold : FontWeight.normal,
                height: 1,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 이 셀이 자동완성 목록에서 몇 번째인지 반환 (없으면 null)
  int? _getAutoCompleteIndex(GameState gameState) {
    if (!gameState.isAutoCompleting || gameState.autoCompleteCells.isEmpty) {
      return null;
    }
    for (var i = 0; i < gameState.autoCompleteCells.length; i++) {
      final (r, c, _) = gameState.autoCompleteCells[i];
      if (r == row && c == col) return i;
    }
    return null;
  }

  bool _isHighlighted(GameState gameState) {
    if (gameState.selectedCell == null) return false;
    final (selRow, selCol) = gameState.selectedCell!;
    if (row == selRow || col == selCol) return true;
    final selBoxRow = (selRow ~/ 3) * 3;
    final selBoxCol = (selCol ~/ 3) * 3;
    final cellBoxRow = (row ~/ 3) * 3;
    final cellBoxCol = (col ~/ 3) * 3;
    return selBoxRow == cellBoxRow && selBoxCol == cellBoxCol;
  }

  bool _isSameNumber(GameState gameState, int value) {
    if (value == 0 || gameState.selectedCell == null) return false;
    final (selRow, selCol) = gameState.selectedCell!;
    final selValue = gameState.board.currentBoard[selRow][selCol];
    return selValue == value && !(row == selRow && col == selCol);
  }
}
