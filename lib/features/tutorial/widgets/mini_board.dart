import 'package:flutter/material.dart';
import '../models/tutorial_models.dart';

/// 게임 공용 미니 보드 위젯
///
/// 3×3, 4×4 등 작은 보드를 단순한 격자로 표시.
/// readonly + 강조 셀 + 오버레이(✓ / ⚠) 지원.
class MiniBoardWidget extends StatelessWidget {
  final MiniBoardIllustration illustration;
  final double size;

  const MiniBoardWidget({
    super.key,
    required this.illustration,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final board = illustration.board;
    final rows = board.length;
    final cols = rows > 0 ? board[0].length : 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (rows == 0 || cols == 0) {
      return SizedBox(width: size, height: size);
    }

    final cellSize = size / rows;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.white38 : Colors.black54,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: List.generate(rows, (r) {
              return Expanded(
                child: Row(
                  children: List.generate(cols, (c) {
                    return Expanded(child: _buildCell(context, r, c, cellSize));
                  }),
                ),
              );
            }),
          ),
        ),
        if (illustration.overlay != null)
          _buildOverlay(context, illustration.overlay!),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int r, int c, double cellSize) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final value = illustration.board[r][c];
    final highlight = _highlightFor(r, c);

    // 강조 스타일에 따른 배경/테두리 결정
    Color? bg;
    Color borderColor = isDark ? Colors.white24 : Colors.black26;
    double borderWidth = 0.6;
    Widget? badge;
    if (highlight != null) {
      switch (highlight.style) {
        case HighlightStyle.info:
          bg = Colors.blue.withValues(alpha: 0.18);
          break;
        case HighlightStyle.success:
          bg = Colors.green.withValues(alpha: 0.15);
          break;
        case HighlightStyle.error:
          bg = Colors.red.withValues(alpha: 0.18);
          // 색맹 대응 — ⚠ 아이콘 동반
          badge = const Icon(Icons.warning_amber_rounded,
              size: 12, color: Colors.red);
          break;
        case HighlightStyle.arrow:
          borderColor = Colors.orange;
          borderWidth = 2.0;
          break;
        case HighlightStyle.target:
          bg = Colors.yellow.withValues(alpha: 0.4);
          borderColor = Colors.orange;
          borderWidth = 2.0;
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (value != null)
            _renderValue(context, value, illustration.gameId, cellSize),
          if (badge != null) Positioned(top: 2, right: 2, child: badge),
        ],
      ),
    );
  }

  /// 게임별 값 렌더링 — 이진 게임은 원/엑스, 그 외는 숫자
  Widget _renderValue(
      BuildContext context, int value, String gameId, double cellSize) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (gameId == 'binairo' || gameId == 'yinyang') {
      // 0=검은 원, 1=흰 원
      if (value == 0) {
        return Container(
          width: cellSize * 0.5,
          height: cellSize * 0.5,
          decoration: BoxDecoration(
            color: textColor,
            shape: BoxShape.circle,
          ),
        );
      }
      return Container(
        width: cellSize * 0.5,
        height: cellSize * 0.5,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: textColor, width: 2),
        ),
      );
    }

    // 숫자 표시
    return Text(
      '$value',
      style: TextStyle(
        fontSize: cellSize * 0.45,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  CellHighlight? _highlightFor(int r, int c) {
    for (final h in illustration.highlights) {
      if (h.row == r && h.col == c) return h;
    }
    return null;
  }

  Widget _buildOverlay(BuildContext context, OverlayKind kind) {
    switch (kind) {
      case OverlayKind.okMark:
        return Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 16, color: Colors.white),
          ),
        );
      case OverlayKind.errorMark:
        return Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                size: 16, color: Colors.white),
          ),
        );
      case OverlayKind.arrow:
        return const Positioned(
          bottom: 4,
          right: 4,
          child: Icon(Icons.arrow_forward_rounded,
              size: 24, color: Colors.orange),
        );
      case OverlayKind.pulse:
        return const SizedBox.shrink();
    }
  }
}
