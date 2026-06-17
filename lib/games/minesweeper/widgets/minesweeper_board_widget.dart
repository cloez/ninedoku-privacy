import 'package:flutter/material.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../../../shared/widgets/line_complete_pulse.dart';
import '../engine/minesweeper_board.dart';

/// 지뢰찾기 보드 위젯 — CustomPaint 기반
class MinesweeperBoardWidget extends StatelessWidget {
  final MinesweeperBoard board;
  final MinesweeperBoard? solution;
  final (int, int)? selectedCell;
  final (int, int)? hintTargetCell;
  final bool isCompleted;
  final void Function(int row, int col)? onCellTap;
  final void Function(int row, int col)? onCellLongPress;
  final void Function(int row, int col)? onCellDoubleTap;

  const MinesweeperBoardWidget({
    super.key,
    required this.board,
    this.solution,
    this.selectedCell,
    this.hintTargetCell,
    this.isCompleted = false,
    this.onCellTap,
    this.onCellLongPress,
    this.onCellDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final cellSize = (maxSize / board.size).floorToDouble();
        final boardSize = cellSize * board.size;

        // 게임 완료 시 보드 전체 펄스
        final completedLines = isCompleted
            ? const [CompletedLine('all', 0)]
            : const <CompletedLine>[];
        return Center(
          child: LastChangePulse(
            lastChangedCell: selectedCell,
            cellSize: cellSize,
            child: LineCompletePulse(
              lines: completedLines,
              cellSize: cellSize,
              gridWidth: board.size,
              gridHeight: board.size,
              child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: GestureDetector(
              onTapUp: (details) {
                if (onCellTap == null) return;
                final row = (details.localPosition.dy / cellSize).floor();
                final col = (details.localPosition.dx / cellSize).floor();
                if (row >= 0 && row < board.size && col >= 0 && col < board.size) {
                  onCellTap!(row, col);
                }
              },
              onDoubleTapDown: (details) {
                if (onCellDoubleTap == null) return;
                final row = (details.localPosition.dy / cellSize).floor();
                final col = (details.localPosition.dx / cellSize).floor();
                if (row >= 0 && row < board.size && col >= 0 && col < board.size) {
                  onCellDoubleTap!(row, col);
                }
              },
              onLongPressStart: (details) {
                if (onCellLongPress == null) return;
                final row = (details.localPosition.dy / cellSize).floor();
                final col = (details.localPosition.dx / cellSize).floor();
                if (row >= 0 && row < board.size && col >= 0 && col < board.size) {
                  onCellLongPress!(row, col);
                }
              },
              child: CustomPaint(
                size: Size(boardSize, boardSize),
                painter: _MinesweeperBoardPainter(
                  board: board,
                  cellSize: cellSize,
                  isDark: isDark,
                  selectedCell: selectedCell,
                  hintTargetCell: hintTargetCell,
                  isCompleted: isCompleted,
                ),
              ),
            ),
            ),
            ),
          ),
        );
      },
    );
  }
}

/// 숫자별 색상
const _numberColors = [
  Colors.transparent, // 0 (표시 안 함)
  Color(0xFF2196F3),  // 1: 파란색
  Color(0xFF4CAF50),  // 2: 초록색
  Color(0xFFF44336),  // 3: 빨간색
  Color(0xFF3F51B5),  // 4: 남색
  Color(0xFF795548),  // 5: 갈색
  Color(0xFF009688),  // 6: 청록색
  Color(0xFF212121),  // 7: 검정
  Color(0xFF9E9E9E),  // 8: 회색
];

class _MinesweeperBoardPainter extends CustomPainter {
  final MinesweeperBoard board;
  final double cellSize;
  final bool isDark;
  final (int, int)? selectedCell;
  final (int, int)? hintTargetCell;
  final bool isCompleted;

  _MinesweeperBoardPainter({
    required this.board,
    required this.cellSize,
    required this.isDark,
    this.selectedCell,
    this.hintTargetCell,
    this.isCompleted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < board.size; r++) {
      for (int c = 0; c < board.size; c++) {
        _drawCell(canvas, r, c);
      }
    }
    _drawGrid(canvas, size);
  }

  void _drawCell(Canvas canvas, int r, int c) {
    final cell = board.getCell(r, c);
    final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);

    // 배경색
    Color bgColor;
    if (cell.revealed) {
      if (cell.isMine) {
        bgColor = Colors.red.shade300; // 실수로 열린 지뢰
      } else {
        bgColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
      }
    } else {
      bgColor = isDark ? const Color(0xFF424242) : const Color(0xFFC0C0C0);
    }

    // 선택된 셀 강조
    if (selectedCell != null && selectedCell!.$1 == r && selectedCell!.$2 == c) {
      bgColor = isDark ? const Color(0xFF1565C0) : const Color(0xFFBBDEFB);
    }

    // 힌트 대상 셀 강조
    if (hintTargetCell != null && hintTargetCell!.$1 == r && hintTargetCell!.$2 == c) {
      bgColor = isDark ? const Color(0xFF827717) : const Color(0xFFFFF9C4);
    }

    canvas.drawRect(rect, Paint()..color = bgColor);

    // 셀 내용
    if (cell.revealed && !cell.isMine && cell.adjacentMines > 0) {
      // 숫자 표시
      _drawText(
        canvas, rect,
        '${cell.adjacentMines}',
        color: _numberColors[cell.adjacentMines],
        fontSize: cellSize * 0.5,
        fontWeight: FontWeight.bold,
      );
    } else if (cell.revealed && cell.isMine) {
      // 지뢰 표시
      _drawText(canvas, rect, '💣', fontSize: cellSize * 0.4);
    } else if (cell.flagged) {
      // 깃발 표시
      _drawText(canvas, rect, '⚑',
        color: Colors.red,
        fontSize: cellSize * 0.45,
        fontWeight: FontWeight.bold,
      );
    } else if (!cell.revealed) {
      // 닫힌 셀 — 3D 입체감 효과
      final highlight = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.4);
      final shadow = Paint()
        ..color = isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.15);

      // 상단/좌측 하이라이트
      canvas.drawLine(
        rect.topLeft, rect.topRight,
        highlight..strokeWidth = 2,
      );
      canvas.drawLine(
        rect.topLeft, rect.bottomLeft,
        highlight..strokeWidth = 2,
      );
      // 하단/우측 그림자
      canvas.drawLine(
        rect.bottomLeft, rect.bottomRight,
        shadow..strokeWidth = 2,
      );
      canvas.drawLine(
        rect.topRight, rect.bottomRight,
        shadow..strokeWidth = 2,
      );
    }

    // 완료 시 지뢰 위치에 깃발 표시
    if (isCompleted && cell.isMine && !cell.flagged) {
      _drawText(canvas, rect, '⚑',
        color: Colors.green,
        fontSize: cellSize * 0.45,
        fontWeight: FontWeight.bold,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    Rect rect,
    String text, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? (isDark ? Colors.white : Colors.black),
          fontSize: fontSize ?? cellSize * 0.4,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        rect.center.dx - tp.width / 2,
        rect.center.dy - tp.height / 2,
      ),
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black26
      ..strokeWidth = 1;

    for (int i = 0; i <= board.size; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinesweeperBoardPainter oldDelegate) => true;
}
