import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../models/tutorial_models.dart';
import '../tutorial_registry.dart';
import '../widgets/mini_board.dart';
import '../widgets/practice_board.dart';

/// 신규 튜토리얼 화면 (v2)
///
/// - 게임별 단계 컨텐츠를 TutorialRegistry로부터 로드
/// - PageView로 슬라이드 진행
/// - S6 인터랙티브 연습 (현재는 스도쿠만)
/// - 오답 3회 → "정답 보기" 활성화
/// - Skip 어디서든 가능
/// - 모달 바텀시트(embedded=true)와 풀스크린 라우트 양쪽 지원
class TutorialScreenV2 extends StatefulWidget {
  final String gameId;
  // true면 모달 바텀시트 안에서 호출 (AppBar 다른 처리)
  final bool embedded;

  const TutorialScreenV2({
    super.key,
    required this.gameId,
    this.embedded = false,
  });

  @override
  State<TutorialScreenV2> createState() => _TutorialScreenV2State();
}

class _TutorialScreenV2State extends State<TutorialScreenV2> {
  final _pageController = PageController();
  int _currentIndex = 0;
  TutorialPhase _phase = TutorialPhase.reading;
  int _wrongCount = 0;

  late final GameTutorial? _tutorial;

  @override
  void initState() {
    super.initState();
    _tutorial = TutorialRegistry.forGame(widget.gameId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int idx) {
    setState(() {
      _currentIndex = idx;
      _phase = TutorialPhase.reading;
      _wrongCount = 0;
      // 연습 단계 진입 시 상태 변경
      final step = _tutorial!.steps[idx];
      if (step.practice != null) {
        _phase = TutorialPhase.practiceWaiting;
      }
    });
  }

  void _next() {
    if (_tutorial == null) return;
    if (_currentIndex < _tutorial.steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _skipOrClose() {
    _finish();
  }

  /// 종료 처리 — 모달이면 닫고, 풀스크린이면 pop
  void _finish() {
    if (widget.embedded) {
      Navigator.of(context).pop();
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        // 풀스크린에서 마지막 단계 완료 — 호출자에게 결과 반환
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 미정의 게임 처리
    if (_tutorial == null || _tutorial.steps.isEmpty) {
      return Scaffold(
        appBar: widget.embedded ? null : AppBar(),
        body: Center(
          child: Text(AppStrings.get('tutorial.notAvailable')),
        ),
      );
    }

    final steps = _tutorial.steps;
    final currentStep = steps[_currentIndex];
    final isLast = _currentIndex == steps.length - 1;

    // 연습 단계에서 정답 또는 reveal 전이면 Next 비활성
    final canAdvance = !_isPracticeStep(currentStep) ||
        _phase == TutorialPhase.practiceCorrect ||
        _phase == TutorialPhase.practiceRevealed ||
        _phase == TutorialPhase.completed;

    final body = SafeArea(
      child: Column(
        children: [
          // 상단 헤더
          _buildHeader(theme, steps.length),
          // 페이지 뷰
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: steps.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => _buildStepView(steps[i]),
            ),
          ),
          // 하단 인디케이터 + 버튼
          _buildFooter(theme, steps.length, canAdvance, isLast),
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(body: body);
  }

  bool _isPracticeStep(TutorialStep s) => s.practice != null;

  Widget _buildHeader(ThemeData theme, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: AppStrings.get('tutorial.common.skip'),
            onPressed: _skipOrClose,
          ),
          Expanded(
            child: Text(
              '${_currentIndex + 1} / $total',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: _skipOrClose,
            child: Text(AppStrings.get('tutorial.common.skip')),
          ),
        ],
      ),
    );
  }

  Widget _buildStepView(TutorialStep step) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.get(step.titleKey),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildIllustration(step),
          const SizedBox(height: 20),
          Text(
            AppStrings.get(step.descriptionKey),
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          // 연습 단계 — 힌트 / 정답 보기
          if (step.practice != null) ...[
            const SizedBox(height: 12),
            if (_phase == TutorialPhase.practiceWrong)
              Text(
                AppStrings.get(step.practice!.hintKey),
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            if (_wrongCount >= step.practice!.maxWrongAttempts &&
                _phase != TutorialPhase.practiceRevealed &&
                _phase != TutorialPhase.practiceCorrect)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _phase = TutorialPhase.practiceRevealed),
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(AppStrings.get('tutorial.common.reveal')),
                ),
              ),
            if (_phase == TutorialPhase.practiceCorrect)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppStrings.get('tutorial.common.correct'),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildIllustration(TutorialStep step) {
    final illu = step.illustration;
    if (step.practice != null) {
      // S6 인터랙티브 보드
      return PracticeBoardWidget(
        practice: step.practice!,
        revealed: _phase == TutorialPhase.practiceRevealed,
        onCorrect: () =>
            setState(() => _phase = TutorialPhase.practiceCorrect),
        onWrong: (cnt) => setState(() {
          _wrongCount = cnt;
          _phase = TutorialPhase.practiceWrong;
          // 잠시 후 다시 waiting으로 복귀
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && _phase == TutorialPhase.practiceWrong) {
              setState(() => _phase = TutorialPhase.practiceWaiting);
            }
          });
        }),
      );
    }

    if (illu is IconIllustration) {
      return Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          illu.icon,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (illu is MiniBoardIllustration) {
      return MiniBoardWidget(illustration: illu, size: 220);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFooter(
      ThemeData theme, int total, bool canAdvance, bool isLast) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          children: [
            // 점 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                final active = i == _currentIndex;
                return Container(
                  width: active ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Back / Next 또는 Start
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex > 0 ? _prev : null,
                    child: Text(AppStrings.get('tutorial.common.prev')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAdvance ? _next : null,
                    child: Text(
                      isLast
                          ? AppStrings.get('tutorial.common.start')
                          : AppStrings.get('tutorial.common.next'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 모달 바텀시트로 튜토리얼 표시 (도움말 아이콘에서 호출)
Future<void> showTutorialBottomSheet(BuildContext context, String gameId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      // 컨텐츠를 화면 높이 90%로 제한
      final maxH = MediaQuery.of(ctx).size.height * 0.92;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: TutorialScreenV2(gameId: gameId, embedded: true),
      );
    },
  );
}
