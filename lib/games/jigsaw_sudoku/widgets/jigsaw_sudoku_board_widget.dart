import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../../../shared/widgets/line_complete_pulse.dart';
import '../jigsaw_sudoku_notifier.dart';
import '../jigsaw_sudoku_state.dart';
import '../engine/jigsaw_sudoku_board.dart';

/// 직소 스도쿠 보드 위젯 — 영역별 색상 배경 + 영역 경계선 굵게
class JigsawSudokuBoardWidget extends ConsumerWidget {
  const JigsawSudokuBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(jigsawSudokuNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final boardSize = maxSide - 4;
        final cellSize = boardSize / 9;

        // 게임 완료 시 보드 전체 펄스
        final completedLines = gameState.isCompleted
            ? const [CompletedLine('all', 0)]
            : const <CompletedLine>[];
        return Center(
          child: LastChangePulse(
            lastChangedCell: gameState.selectedCell,
            cellSize: cellSize,
            child: LineCompletePulse(
              lines: completedLines,
              cellSize: cellSize,
              gridWidth: 9,
              gridHeight: 9,
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: CustomPaint(
                  painter: _JigsawSudokuBoardPainter(
                    state: gameState,
                    isDark: isDark,
                    cellSize: cellSize,
                  ),
                  child: _buildGestureGrid(ref, gameState, cellSize),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 셀별 탭 감지 그리드
  Widget _buildGestureGrid(
    WidgetRef ref,
    JigsawSudokuState state,
    double cellSize,
  ) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
      ),
      itemCount: 81,
      itemBuilder: (context, index) {
        final row = index ~/ 9;
        final col = index % 9;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref
                .read(jigsawSudokuNotifierProvider.notifier)
                .selectCell(row, col);
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/// 직소 스도쿠 보드 페인터
class _JigsawSudokuBoardPainter extends CustomPainter {
  final JigsawSudokuState state;
  final bool isDark;
  final double cellSize;

  /// 영역별 배경색 (9색, 밝은/어두운 테마)
  static const _lightRegionColors = [
    Color(0x30E57373), // 빨강
    Color(0x3064B5F6), // 파랑
    Color(0x3081C784), // 초록
    Color(0x30FFB74D), // 주황
    Color(0x30BA68C8), // 보라
    Color(0x304DD0E1), // 청록
    Color(0x30FFD54F), // 노랑
    Color(0x30F06292), // 분홍
    Color(0x30A1887F), // 갈색
  ];

  static const _darkRegionColors = [
    Color(0x25E57373),
    Color(0x2564B5F6),
    Color(0x2581C784),
    Color(0x25FFB74D),
    Color(0x25BA68C8),
    Color(0x254DD0E1),
    Color(0x25FFD54F),
    Color(0x25F06292),
    Color(0x25A1887F),
  ];

  _JigsawSudokuBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final board = state.board;

    // 1. 전체 배경
    _drawBackground(canvas, size);

    // 2. 영역별 색상 배경
    _drawRegionColors(canvas, board);

    // 3. 선택/하이라이트
    _drawHighlights(canvas, board);

    // 4. 얇은 격자선
    _drawThinGrid(canvas, size);

    // 5. 영역 경계선 (굵게)
    _drawRegionBorders(canvas, board);

    // 6. 숫자
    _drawNumbers(canvas, board);

    // 7. 메모
    _drawNotes(canvas, board);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    canvas.drawRect(Offset.zero & size, paint);
  }

  /// 영역별 배경색 채우기
  void _drawRegionColors(Canvas canvas, JigsawSudokuBoard board) {
    final colors = isDark ? _darkRegionColors : _lightRegionColors;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final regionId = board.regions[r][c];
        final paint = Paint()..color = colors[regionId % 9];
        canvas.drawRect(
          Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  void _drawHighlights(Canvas canvas, JigsawSudokuBoard board) {
    final sel = state.selectedCell;
    if (sel == null) return;
    final (selRow, selCol) = sel;

    // 같은 행/열/영역 하이라이트
    final highlightPaint = Paint()
      ..color = isDark
          ? Colors.blue.withValues(alpha: 0.12)
          : Colors.blue.withValues(alpha: 0.1);

    final selRegion = board.regions[selRow][selCol];

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final sameRow = r == selRow;
        final sameCol = c == selCol;
        final sameRegion = board.regions[r][c] == selRegion;

        if (sameRow || sameCol || sameRegion) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            highlightPaint,
          );
        }
      }
    }

    // 선택된 셀 강조
    final selPaint = Paint()
      ..color = isDark
          ? Colors.blue.withValues(alpha: 0.3)
          : Colors.blue.withValues(alpha: 0.2);
    canvas.drawRect(
      Rect.fromLTWH(selCol * cellSize, selRow * cellSize, cellSize, cellSize),
      selPaint,
    );

    // 같은 숫자 하이라이트
    final selValue = board.cells[selRow][selCol];
    if (selValue != 0) {
      final samePaint = Paint()
        ..color = isDark
            ? Colors.blue.withValues(alpha: 0.2)
            : Colors.blue.withValues(alpha: 0.15);
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.cells[r][c] == selValue && (r != selRow || c != selCol)) {
            canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
              samePaint,
            );
          }
        }
      }
    }
  }

  /// 얇은 격자선
  void _drawThinGrid(Canvas canvas, Size size) {
    final thinPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..strokeWidth = 0.5;

    for (var i = 1; i < 9; i++) {
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), thinPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), thinPaint);
    }
  }

  /// 영역 경계선 (굵게)
  void _drawRegionBorders(Canvas canvas, JigsawSudokuBoard board) {
    final borderPaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black87
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final region = board.regions[r][c];
        final x = c * cellSize;
        final y = r * cellSize;

        // 상단 경계: 위쪽 셀이 다른 영역이면 굵은 선
        if (r == 0 || board.regions[r - 1][c] != region) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + cellSize, y),
            borderPaint,
          );
        }
        // 하단 경계
        if (r == 8 || board.regions[r + 1][c] != region) {
          canvas.drawLine(
            Offset(x, y + cellSize),
            Offset(x + cellSize, y + cellSize),
            borderPaint,
          );
        }
        // 좌측 경계
        if (c == 0 || board.regions[r][c - 1] != region) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, y + cellSize),
            borderPaint,
          );
        }
        // 우측 경계
        if (c == 8 || board.regions[r][c + 1] != region) {
          canvas.drawLine(
            Offset(x + cellSize, y),
            Offset(x + cellSize, y + cellSize),
            borderPaint,
          );
        }
      }
    }
  }

  void _drawNumbers(Canvas canvas, JigsawSudokuBoard board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final value = board.cells[r][c];
        if (value == 0) continue;

        // 색상 결정
        Color textColor;
        if (board.isFixed[r][c]) {
          textColor = isDark ? Colors.white : Colors.black87;
        } else if (value != board.solution[r][c]) {
          // 틀린 값
          textColor = isDark
              ? AppColors.wrongNumberDark
              : AppColors.wrongNumberLight;
        } else {
          // 사용자 입력 (정답)
          textColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
        }

        final tp = TextPainter(
          text: TextSpan(
            text: '$value',
            style: TextStyle(
              fontSize: cellSize * 0.5,
              fontWeight:
                  board.isFixed[r][c] ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();

        tp.paint(
          canvas,
          Offset(
            c * cellSize + (cellSize - tp.width) / 2,
            r * cellSize + (cellSize - tp.height) / 2,
          ),
        );
      }
    }
  }

  void _drawNotes(Canvas canvas, JigsawSudokuBoard board) {
    final noteSize = cellSize / 3;
    final fontSize = noteSize * 0.65;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.cells[r][c] != 0) continue;
        final noteSet = board.notes[r][c];
        if (noteSet.isEmpty) continue;

        for (final n in noteSet) {
          final nr = (n - 1) ~/ 3;
          final nc = (n - 1) % 3;

          final tp = TextPainter(
            text: TextSpan(
              text: '$n',
              style: TextStyle(
                fontSize: fontSize,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout();

          tp.paint(
            canvas,
            Offset(
              c * cellSize + nc * noteSize + (noteSize - tp.width) / 2,
              r * cellSize + nr * noteSize + (noteSize - tp.height) / 2,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JigsawSudokuBoardPainter oldDelegate) {
    return true; // 상태 변경 시 항상 다시 그리기
  }
}
