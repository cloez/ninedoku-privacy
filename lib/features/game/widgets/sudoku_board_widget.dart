import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game_notifier.dart';
import '../game_state.dart';
import '../../../core/sudoku/board.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import 'hint_reveal_pulse.dart';
import 'line_complete_pulse.dart';

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 마지막 변경 셀 펄스용 cellSize 산정 (보드 폭 / 9)
          final cellSize = constraints.maxWidth / 9;
          // 완성된 라인 정보를 펄스 위젯용으로 변환
          final pulseLines = gameState.recentlyCompletedLines
              .map((l) => CompletedLine(l.type, l.index))
              .toList();
          return LastChangePulse(
            lastChangedCell: gameState.selectedCell,
            cellSize: cellSize,
            child: LineCompletePulse(
              lines: pulseLines,
              cellSize: cellSize,
              child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? AppColors.boardLineDark
                      : AppColors.boardLineLight,
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
            ),
          );
        },
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

    // 셀 배경색 — 새 토큰 (피어 → 같은 숫자 → 선택 순으로 진해짐)
    Color bgColor;
    if (isAutoCompleteRevealed) {
      // 자동완성으로 채워진 셀: Jade Bloom 하이라이트 (성공 의미)
      bgColor = isDark
          ? AppColors.jadeBloomDarkDarkMode.withValues(alpha: 0.4)
          : AppColors.jadeBloomLight;
    } else if (isWrongFlash) {
      // 릴렉스 모드 오답 플래시: error 토큰 배경
      bgColor = isDark
          ? AppColors.errorDark.withValues(alpha: 0.35)
          : AppColors.errorLight.withValues(alpha: 0.18);
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

    // H1: L2 핵심 셀 강조 (초록 테두리 #10B981, 2.5dp)
    final isHintKeyCell = gameState.currentHintLevel == 2 &&
        gameState.lastHintResult != null &&
        gameState.lastHintResult!.keyCells.any((kc) => kc.$1 == row && kc.$2 == col);

    // H2: L3 자동 메모 데이터 (대상 셀이 빈 경우)
    final hintAutoMemo = (gameState.currentHintLevel == 3 &&
            value == 0 &&
            gameState.lastHintResult != null &&
            gameState.lastHintResult!.autoMemo.containsKey((row, col)))
        ? gameState.lastHintResult!.autoMemo[(row, col)]!
        : null;
    final hintEliminated = (gameState.currentHintLevel == 3 &&
            value == 0 &&
            gameState.lastHintResult != null &&
            gameState.lastHintResult!.eliminated.containsKey((row, col)))
        ? gameState.lastHintResult!.eliminated[(row, col)]!
        : <int>{};
    final isHintAnswerCell = gameState.currentHintLevel == 3 &&
        gameState.lastHintResult != null &&
        gameState.lastHintResult!.answerCell?.$1 == row &&
        gameState.lastHintResult!.answerCell?.$2 == col;
    final hintAnswerValue = isHintAnswerCell
        ? gameState.lastHintResult!.answerValue
        : null;

    return GestureDetector(
      onTap: () => ref.read(gameProvider.notifier).selectCell(row, col),
      child: Semantics(
        label: '행 ${row + 1}, 열 ${col + 1}${value > 0 ? ', 값 $value' : ', 비어있음'}${isFixed ? ', 고정' : ''}',
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: isHintKeyCell
                ? Border.all(
                    // H1: L2 핵심 셀 강조 — Jade Bloom mid (success 의미)
                    color: isDark
                        ? AppColors.jadeBloomMidDarkMode
                        : AppColors.jadeBloomMid,
                    width: 2.5,
                  )
                : Border(
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
            child: _wrapWithHintRevealPulse(
              gameState,
              value > 0
                  ? _buildNumberText(context, value, isFixed, isWrong, isDark, isCompletedNumber)
                  : (hintAutoMemo != null || hintEliminated.isNotEmpty)
                      ? _buildHintCandidates(
                          context,
                          hintAutoMemo ?? const {},
                          hintEliminated,
                          hintAnswerValue,
                          isDark,
                        )
                      : notes.isNotEmpty
                          ? _buildNotesGrid(context, notes, isDark, _getHighlightNumber(gameState))
                          : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  /// H3: 이 셀이 최근 L4 정답 공개 셀이면 글로우 펄스로 감싸 반환
  Widget _wrapWithHintRevealPulse(GameState gameState, Widget child) {
    final reveal = gameState.recentlyRevealedHintCell;
    final isActive = reveal != null && reveal.$1 == row && reveal.$2 == col;
    return HintRevealPulse(active: isActive, child: child);
  }

  /// H2: L3 힌트 자동 후보 메모 그리드 (3x3, 회색/빨강 X/초록)
  /// - autoMemo: 잔존 후보 (회색)
  /// - eliminated: 소거된 후보 (빨강 + 사선 X)
  /// - answerValue: 정답 숫자 (초록 굵게) — 대상 셀에만 전달
  Widget _buildHintCandidates(
    BuildContext context,
    Set<int> autoMemo,
    Set<int> eliminated,
    int? answerValue,
    bool isDark,
  ) {
    // 색상 토큰 — 새 팔레트 정합 (회색=note, 빨강=error WCAG AA, 초록=jade success)
    final candidateGray = isDark ? AppColors.noteNumberDark : AppColors.noteNumberLight;
    final eliminatedRed = isDark ? AppColors.errorDark : AppColors.errorLight;
    final answerGreen = isDark ? AppColors.jadeBloomMidDarkMode : AppColors.jadeBloomMid;

    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(1),
      children: List.generate(9, (i) {
        final n = i + 1;
        final isAnswer = answerValue == n;
        final isEliminated = eliminated.contains(n);
        final isRemain = autoMemo.contains(n);
        if (!isAnswer && !isEliminated && !isRemain) {
          return const SizedBox.shrink();
        }
        Color color;
        FontWeight weight = FontWeight.normal;
        if (isAnswer) {
          color = answerGreen;
          weight = FontWeight.bold;
        } else if (isEliminated) {
          color = eliminatedRed;
        } else {
          color = candidateGray;
        }
        final textChild = Text(
          '$n',
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: weight,
            height: 1,
          ),
        );
        return Center(
          child: isEliminated
              ? CustomPaint(
                  painter: _StrikethroughPainter(color: eliminatedRed),
                  child: textChild,
                )
              : textChild,
        );
      }),
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

  /// 현재 하이라이트할 숫자 (셀우선/숫자우선 모드 모두 selectedNumber 우선)
  int? _getHighlightNumber(GameState gameState) {
    // 두 모드 모두 선택된 숫자가 있으면 우선 사용 (셀우선 모드에서도 숫자 패드 탭 시 하이라이트)
    if (gameState.selectedNumber != null) {
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
    if (value == 0) return false;
    // selectedNumber 우선 (셀우선 모드에서 숫자 패드 탭 시에도 작동)
    if (gameState.selectedNumber != null) {
      return gameState.selectedNumber == value;
    }
    if (gameState.selectedCell == null) return false;
    final (selRow, selCol) = gameState.selectedCell!;
    final selValue = gameState.board.currentBoard[selRow][selCol];
    return selValue == value && !(row == selRow && col == selCol);
  }
}

/// H2: L3 소거 후보의 사선 X(대각선 strike-through) 페인터
class _StrikethroughPainter extends CustomPainter {
  final Color color;
  const _StrikethroughPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    // 좌상 → 우하 대각선
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.9, size.height * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StrikethroughPainter oldDelegate) =>
      oldDelegate.color != color;
}
