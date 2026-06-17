import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tutorial_models.dart';

/// 인터랙티브 연습 보드 (S6 단계)
///
/// 사용자가 target 셀에만 입력 가능. 다른 셀은 readonly.
/// 정답/오답 콜백을 통해 상위 위젯에 결과 전달.
class PracticeBoardWidget extends StatefulWidget {
  final InteractivePractice practice;
  // 정답 콜백
  final VoidCallback onCorrect;
  // 오답 콜백 (현재 누적 오답 횟수 전달)
  final void Function(int wrongCount) onWrong;
  // 정답 보기 모드인지
  final bool revealed;
  // 보드 크기 (px)
  final double size;

  const PracticeBoardWidget({
    super.key,
    required this.practice,
    required this.onCorrect,
    required this.onWrong,
    this.revealed = false,
    this.size = 240,
  });

  @override
  State<PracticeBoardWidget> createState() => _PracticeBoardWidgetState();
}

class _PracticeBoardWidgetState extends State<PracticeBoardWidget>
    with SingleTickerProviderStateMixin {
  int? _userValue;
  int _wrongCount = 0;
  bool? _lastIsCorrect;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _onSelectValue(int v) {
    if (widget.revealed) return;
    final correct = (v == widget.practice.correctValue);
    setState(() {
      _userValue = v;
      _lastIsCorrect = correct;
    });

    if (correct) {
      HapticFeedback.lightImpact();
      widget.onCorrect();
    } else {
      _wrongCount += 1;
      _shake.forward(from: 0).then((_) => _shake.reverse());
      HapticFeedback.selectionClick();
      widget.onWrong(_wrongCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.practice.initialBoard;
    final rows = board.length;
    final cols = rows > 0 ? board[0].length : 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final target = widget.practice.target;
    final correctVal = widget.practice.correctValue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 보드 (흔들림 애니메이션 적용)
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final dx = (_lastIsCorrect == false)
                ? (_shake.value * 6 * (_shake.value > 0.5 ? -1 : 1))
                : 0.0;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.white38 : Colors.black54,
                  width: 2,
                ),
              ),
              child: Column(
                children: List.generate(rows, (r) {
                  return Expanded(
                    child: Row(
                      children: List.generate(cols, (c) {
                        return Expanded(
                            child: _buildCell(context, r, c, target));
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 숫자 패드 (1..N) — 4×4 미니 스도쿠 가정
        Wrap(
          spacing: 8,
          children: List.generate(rows, (i) {
            final v = i + 1;
            final isSelected = _userValue == v;
            return ElevatedButton(
              onPressed: () => _onSelectValue(v),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                minimumSize: const Size(48, 48),
              ),
              child: Text('$v', style: const TextStyle(fontSize: 18)),
            );
          }),
        ),
        // revealed 상태에서 정답 표시
        if (widget.revealed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '✓ ${target.row + 1}행 ${target.col + 1}열 = $correctVal',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int r, int c, CellTarget target) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final board = widget.practice.initialBoard;
    final isTarget = (target.row == r && target.col == c);
    final initial = board[r][c];

    Color? bg;
    int? displayValue;

    if (isTarget) {
      // 타깃 셀 — 노란색 강조
      if (widget.revealed) {
        bg = Colors.green.withValues(alpha: 0.25);
        displayValue = widget.practice.correctValue;
      } else if (_userValue != null) {
        bg = (_lastIsCorrect == true)
            ? Colors.green.withValues(alpha: 0.25)
            : Colors.red.withValues(alpha: 0.18);
        displayValue = _userValue;
      } else {
        bg = Colors.yellow.withValues(alpha: 0.4);
      }
    } else {
      displayValue = initial;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: isTarget
              ? Colors.orange
              : (isDark ? Colors.white24 : Colors.black26),
          width: isTarget ? 2.0 : 0.6,
        ),
      ),
      alignment: Alignment.center,
      child: displayValue == null
          ? const SizedBox.shrink()
          : Text(
              '$displayValue',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
    );
  }
}
