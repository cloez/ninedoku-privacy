import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/last_change_pulse.dart';
import '../../../shared/widgets/line_complete_pulse.dart';
import '../killer_sudoku_notifier.dart';
import '../killer_sudoku_state.dart';
import '../engine/killer_sudoku_board.dart';
import 'cage_palette.dart';

/// 킬러 스도쿠 보드 위젯 — 점선 케이지 + 합계 표시
class KillerSudokuBoardWidget extends ConsumerWidget {
  const KillerSudokuBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(killerSudokuNotifierProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSide = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final boardSize = maxSide - 4;
        final cellSize = boardSize / 9;

        // 케이지 색상 할당 (인접 회피 그리디)
        final cageColors = CagePalette.assignColors(gameState.board.cages);

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
                  painter: _KillerSudokuBoardPainter(
                    state: gameState,
                    isDark: isDark,
                    cellSize: cellSize,
                    cageColors: cageColors,
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
    KillerSudokuState state,
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
            ref.read(killerSudokuNotifierProvider.notifier).selectCell(row, col);
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/// 킬러 스도쿠 보드 페인터
class _KillerSudokuBoardPainter extends CustomPainter {
  final KillerSudokuState state;
  final bool isDark;
  final double cellSize;
  final List<int> cageColors;

  _KillerSudokuBoardPainter({
    required this.state,
    required this.isDark,
    required this.cellSize,
    required this.cageColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final board = state.board;

    // 1. 배경 (전체 보드 바탕)
    _drawBackground(canvas, size);

    // 2. 케이지 배경색 (옅은 색 채움) — 하이라이트보다 먼저 그려 선택 강조가 덮도록
    _drawCageBackgrounds(canvas, board);

    // 3. 선택/하이라이트
    _drawHighlights(canvas, board);

    // 4. 격자선 (3x3 박스 굵은선)
    _drawGrid(canvas, size);

    // 5. 숫자
    _drawNumbers(canvas, board);

    // 6. 메모
    _drawNotes(canvas, board);

    // 7. 케이지 테두리 (점선) — 격자선/숫자 위에 표시되어 케이지 경계 강조
    _drawCages(canvas, board);

    // 8. 케이지 합계 텍스트
    _drawCageSums(canvas, board);
  }

  /// 케이지별 옅은 배경색 채움
  void _drawCageBackgrounds(Canvas canvas, KillerSudokuBoard board) {
    for (int i = 0; i < board.cages.length; i++) {
      final cage = board.cages[i];
      // 색상 인덱스 범위 방어
      final colorIdx = i < cageColors.length ? cageColors[i] : 0;
      final bgPaint = Paint()
        ..color = CagePalette.backgroundColor(colorIdx, isDark)
        ..style = PaintingStyle.fill;
      for (final (r, c) in cage.cells) {
        final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, bgPaint);
      }
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawHighlights(Canvas canvas, KillerSudokuBoard board) {
    final sel = state.selectedCell;
    if (sel == null) return;
    final (selRow, selCol) = sel;

    // 같은 행/열/박스 하이라이트
    final highlightPaint = Paint()
      ..color = isDark
          ? Colors.blue.withValues(alpha: 0.1)
          : Colors.blue.withValues(alpha: 0.08);

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final sameRow = r == selRow;
        final sameCol = c == selCol;
        final sameBox = (r ~/ 3 == selRow ~/ 3) && (c ~/ 3 == selCol ~/ 3);

        if (sameRow || sameCol || sameBox) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            highlightPaint,
          );
        }
      }
    }

    // 같은 케이지 하이라이트
    final cage = board.getCageAt(selRow, selCol);
    if (cage != null) {
      final cagePaint = Paint()
        ..color = isDark
            ? Colors.amber.withValues(alpha: 0.12)
            : Colors.amber.withValues(alpha: 0.1);
      for (final cell in cage.cells) {
        canvas.drawRect(
          Rect.fromLTWH(
            cell.$2 * cellSize,
            cell.$1 * cellSize,
            cellSize,
            cellSize,
          ),
          cagePaint,
        );
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

  void _drawCages(Canvas canvas, KillerSudokuBoard board) {
    // 케이지마다 다른 색상의 점선 사용
    for (int i = 0; i < board.cages.length; i++) {
      final cage = board.cages[i];
      final colorIdx = i < cageColors.length ? cageColors[i] : 0;
      final dashPaint = Paint()
        ..color = CagePalette.dashColor(colorIdx, isDark)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      final cellSet = cage.cells.toSet();

      for (final cell in cage.cells) {
        final (r, c) = cell;
        final x = c * cellSize;
        final y = r * cellSize;
        // 안쪽 여백 (점선이 격자선과 겹치지 않게)
        const inset = 2.0;

        // 상단 경계: 위쪽 셀이 같은 케이지가 아니면 점선
        if (!cellSet.contains((r - 1, c))) {
          _drawDashedLine(
            canvas,
            Offset(x + inset, y + inset),
            Offset(x + cellSize - inset, y + inset),
            dashPaint,
          );
        }
        // 하단 경계
        if (!cellSet.contains((r + 1, c))) {
          _drawDashedLine(
            canvas,
            Offset(x + inset, y + cellSize - inset),
            Offset(x + cellSize - inset, y + cellSize - inset),
            dashPaint,
          );
        }
        // 좌측 경계
        if (!cellSet.contains((r, c - 1))) {
          _drawDashedLine(
            canvas,
            Offset(x + inset, y + inset),
            Offset(x + inset, y + cellSize - inset),
            dashPaint,
          );
        }
        // 우측 경계
        if (!cellSet.contains((r, c + 1))) {
          _drawDashedLine(
            canvas,
            Offset(x + cellSize - inset, y + inset),
            Offset(x + cellSize - inset, y + cellSize - inset),
            dashPaint,
          );
        }
      }
    }
  }

  /// 점선 그리기
  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashLength = 4.0;
    const gapLength = 3.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (dx * dx + dy * dy);
    final totalLen = distance > 0 ? distance.toDouble() : 0.0;
    final len = totalLen > 0 ? _sqrt(totalLen) : 0.0;
    if (len == 0) return;

    final unitDx = dx / len;
    final unitDy = dy / len;
    var current = 0.0;

    while (current < len) {
      final dashEnd = (current + dashLength).clamp(0.0, len);
      canvas.drawLine(
        Offset(start.dx + unitDx * current, start.dy + unitDy * current),
        Offset(start.dx + unitDx * dashEnd, start.dy + unitDy * dashEnd),
        paint,
      );
      current += dashLength + gapLength;
    }
  }

  /// 간단한 제곱근 (dart:math 없이)
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    var guess = x / 2;
    for (var i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  void _drawGrid(Canvas canvas, Size size) {
    // 얇은 격자선
    final thinPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..strokeWidth = 0.5;

    for (var i = 1; i < 9; i++) {
      if (i % 3 != 0) {
        final pos = i * cellSize;
        canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), thinPaint);
        canvas.drawLine(Offset(0, pos), Offset(size.width, pos), thinPaint);
      }
    }

    // 3x3 박스 굵은선
    final thickPaint = Paint()
      ..color = isDark ? Colors.white54 : Colors.black54
      ..strokeWidth = 2.0;

    for (var i = 0; i <= 3; i++) {
      final pos = i * cellSize * 3;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), thickPaint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), thickPaint);
    }
  }

  void _drawNumbers(Canvas canvas, KillerSudokuBoard board) {
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
          textColor = isDark
              ? AppColors.primaryDark
              : AppColors.primaryLight;
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

  void _drawNotes(Canvas canvas, KillerSudokuBoard board) {
    // 케이지 좌상단 셀(합계 숫자가 표시되는 셀) 집합 미리 계산
    // → 해당 셀의 메모 영역을 셀 하단으로 압축하여 합계와 겹침 방지
    final cageTopLeftCells = <(int, int)>{};
    for (final cage in board.cages) {
      var tr = 9, tc = 9;
      for (final cell in cage.cells) {
        if (cell.$1 < tr || (cell.$1 == tr && cell.$2 < tc)) {
          tr = cell.$1;
          tc = cell.$2;
        }
      }
      cageTopLeftCells.add((tr, tc));
    }

    final noteWidth = cellSize / 3;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.cells[r][c] != 0) continue;
        final noteSet = board.notes[r][c];
        if (noteSet.isEmpty) continue;

        // 합계 셀이면 메모 영역을 셀 하단 72%로 압축 (yOffset = 28%)
        final isCageTopLeft = cageTopLeftCells.contains((r, c));
        final yOffset = isCageTopLeft ? cellSize * 0.28 : 0.0;
        final noteAreaHeight = cellSize - yOffset;
        final noteHeight = noteAreaHeight / 3;
        // 폰트 크기: 압축된 영역에 맞춰 너비/높이 중 작은 쪽 기준
        final fontSize =
            (noteHeight < noteWidth ? noteHeight : noteWidth) * 0.65;

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
              c * cellSize + nc * noteWidth + (noteWidth - tp.width) / 2,
              r * cellSize +
                  yOffset +
                  nr * noteHeight +
                  (noteHeight - tp.height) / 2,
            ),
          );
        }
      }
    }
  }

  void _drawCageSums(Canvas canvas, KillerSudokuBoard board) {
    for (int i = 0; i < board.cages.length; i++) {
      final cage = board.cages[i];
      final colorIdx = i < cageColors.length ? cageColors[i] : 0;
      // 케이지의 좌상단 셀 찾기
      var topRow = 9, topCol = 9;
      for (final cell in cage.cells) {
        if (cell.$1 < topRow || (cell.$1 == topRow && cell.$2 < topCol)) {
          topRow = cell.$1;
          topCol = cell.$2;
        }
      }

      final fontSize = cellSize * 0.22;
      final tp = TextPainter(
        text: TextSpan(
          text: '${cage.sum}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: CagePalette.sumTextColor(colorIdx, isDark),
            // 가독성을 위한 가벼운 그림자
            shadows: [
              Shadow(
                color: (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: 0.6),
                blurRadius: 1.5,
              ),
            ],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // 좌상단 약간 안쪽에 표시
      tp.paint(
        canvas,
        Offset(
          topCol * cellSize + 4,
          topRow * cellSize + 3,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KillerSudokuBoardPainter oldDelegate) {
    // 상태/테마/셀크기/케이지 색상 변경 시 재페인트
    return oldDelegate.state != state ||
        oldDelegate.isDark != isDark ||
        oldDelegate.cellSize != cellSize ||
        !_listEquals(oldDelegate.cageColors, cageColors);
  }

  /// 두 int 리스트 동등 비교
  static bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
