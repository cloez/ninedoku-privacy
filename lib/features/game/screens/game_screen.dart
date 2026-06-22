import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/sudoku/hint_engine.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../game_notifier.dart';
import '../game_state.dart';
import '../widgets/sudoku_board_widget.dart';
import '../widgets/number_pad_widget.dart';
import '../widgets/game_info_bar.dart';
import '../widgets/encouragement_widget.dart';
import '../widgets/hint_banner.dart';
import '../widgets/hint_region_pulse.dart';
import '../widgets/technique_glossary_modal.dart';
import 'pause_screen.dart';
import 'result_screen.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/board_progress_bar.dart';

/// 게임 플레이 화면 (S-05)
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    // 게임 상태 없으면 홈으로
    if (gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
      return const GameLoadingScreen();
    }

    // 도전 모드 게임 오버
    if (gameState.isGameOver) {
      return _GameOverScreen(gameState: gameState);
    }

    // 완료 시 결과 화면 (자동완성 애니메이션 중에는 보드 유지)
    if (gameState.isCompleted && !gameState.isAutoCompleting) {
      return const ResultScreen();
    }

    // 일시정지 시 일시정지 화면
    if (gameState.isPaused) {
      return const PauseScreen();
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // 하드웨어 백키와 AppBar 뒤로가기를 동일하게 처리
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        appBar: isLandscape
            ? null // 가로 모드에서는 앱바 숨기고 공간 활용
            : AppBar(
                title: Text(AppStrings.get('mode.${gameState.mode.name}')),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _showExitDialog(context),
                  tooltip: AppStrings.get('game.back'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.pause_rounded),
                    onPressed: () => ref.read(gameProvider.notifier).pause(),
                    tooltip: AppStrings.get('game.pause'),
                  ),
                ],
              ),
        body: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(context, ref)
              : _buildPortraitLayout(),
        ),
      ),
    );
  }

  /// 힌트 메시지 키 → 치환된 텍스트 (간단 템플릿 {key} 치환)
  String _resolveHintMessage(String? key, Map<String, String>? params) {
    if (key == null) return '';
    var text = AppStrings.get(key);
    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  /// 힌트 배너 슬롯 높이 (배너 등장/사라짐에도 보드 위치가 흔들리지 않도록 고정)
  static const double _hintBannerSlotHeight = 96.0;

  /// 힌트 배너 (Level 1~4 표시) — 항상 고정 높이 슬롯 안에서 렌더링
  Widget _buildHintBanner(GameState gameState) {
    final level = gameState.currentHintLevel;
    Widget child;
    if (level == 0 || gameState.lastHintResult == null) {
      child = const SizedBox.shrink();
    } else {
      final h = gameState.lastHintResult!;
      final technique = h.techniqueKey != null
          ? AppStrings.get(h.techniqueKey!)
          : null;
      // 단계별로 다른 메시지 키를 조립한다.
      // - Lv.1: 영역 안내 (hint.level1.*)
      // - Lv.2: 기법 안내 (hint.l2.{tech})
      // - Lv.3: 상세 이유 (hint.l3.{tech})
      // - Lv.4: 정답 공개 (hint.answer)
      String message;
      if (level == 4) {
        message = _resolveHintMessage(h.messageKey ?? 'hint.answer', h.messageParams);
      } else if (level == 1) {
        message = _resolveHintMessage(h.messageKey ?? 'hint.level1.box', null);
      } else {
        // Lv.2/Lv.3: 기법 단축 키로 메시지 조립
        final shortKey = h.technique != null
            ? HintEngine.techniqueShortKeyOf(h.technique!)
            : 'nakedSingle';
        final prefix = level == 2 ? 'hint.l2' : 'hint.l3';
        final assembledKey = '$prefix.$shortKey';
        message = _resolveHintMessage(assembledKey, h.messageParams);
        // 안전망: 키 누락 시 기존 explain 키 → 원시 메시지 순으로 폴백
        if (message.isEmpty || message == assembledKey) {
          message = _resolveHintMessage(h.messageKey, h.messageParams);
          if (message.isEmpty) message = h.message;
        }
      }
      final footer = level < 4 ? AppStrings.get('hint.tapForMore') : null;
      child = HintBanner(
        level: level,
        technique: level >= 2 ? technique : null,
        message: message,
        hintFooter: footer,
        onClose: () => ref.read(gameProvider.notifier).clearHintState(),
        // H5: 기법 이름 탭 → 기법 사전 모달 열기 (technique이 있을 때만)
        onTechniqueTap: (level >= 2 && h.technique != null)
            ? () => TechniqueGlossaryModal.show(context, h.technique!)
            : null,
      );
    }
    // 고정 슬롯: 배너 등장/사라짐 시에도 보드가 흔들리지 않도록 일정 높이 유지
    return SizedBox(
      height: _hintBannerSlotHeight,
      child: Align(
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }

  /// 세로 모드 레이아웃 (기존)
  Widget _buildPortraitLayout() {
    final gameState = ref.watch(gameProvider)!;
    final progress = gameState.progress;
    // Level 1일 때만 영역 펄스 발동
    final region = (gameState.currentHintLevel == 1 &&
            gameState.lastHintResult?.regionType != null &&
            gameState.lastHintResult?.regionIndex != null)
        ? (
            type: gameState.lastHintResult!.regionType!,
            index: gameState.lastHintResult!.regionIndex!,
          )
        : null;
    return Column(
      children: [
        const GameInfoBar(),
        // 진행률 바 (공통 위젯)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BoardProgressBar(progress: progress),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = constraints.maxWidth / 9;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        HintRegionPulse(
                          region: region,
                          cellSize: cellSize,
                          child: const SudokuBoardWidget(),
                        ),
                        const Positioned(
                          top: 8,
                          child: EncouragementWidget(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        // 힌트 배너 (Level 1~4) — 보드 하단에 표시
        _buildHintBanner(gameState),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: NumberPadWidget(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 가로 모드 레이아웃: 보드 좌측, 숫자 패드+정보 우측
  Widget _buildLandscapeLayout(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 좌측: 보드 (높이 최대 활용, 최소 패딩)
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4, right: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SudokuBoardWidget(),
                const Positioned(
                  top: 4,
                  child: EncouragementWidget(),
                ),
              ],
            ),
          ),
        ),
        // 우측: 정보 + 숫자 패드
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: [
                // 가로 모드 상단: 뒤로가기 + 모드명 + 일시정지
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        onPressed: () => _showExitDialog(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.get('mode.${ref.read(gameProvider)!.mode.name}'),
                        style: Theme.of(context).textTheme.titleSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        icon: const Icon(Icons.pause_rounded, size: 20),
                        onPressed: () => ref.read(gameProvider.notifier).pause(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const GameInfoBar(),
                // 진행률 바 (가로 모드)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: BoardProgressBar(
                    progress: ref.watch(gameProvider)?.progress ?? 0.0,
                  ),
                ),
                // 힌트 배너 (가로 모드)
                _buildHintBanner(ref.watch(gameProvider)!),
                // 유연한 공간 확보 (숫자 패드가 잘리지 않도록)
                const Expanded(child: SizedBox()),
                // 숫자 패드 (가로 모드용 컴팩트 배치)
                const NumberPadWidget(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showExitDialog(BuildContext context) {
    showKPDialog(
      context: context,
      title: AppStrings.get('game.exit.title'),
      content: AppStrings.get('game.exit.message'),
      confirmLabel: AppStrings.get('game.exit.leave'),
      cancelLabel: AppStrings.get('cancel'),
      onConfirm: () {
        ref.read(gameProvider.notifier).pause();
        context.go(AppRoutes.home);
      },
    );
  }
}

/// 도전 모드 게임 오버 화면 — 마지막 실수 셀이 표시된 보드 포함
class _GameOverScreen extends ConsumerWidget {
  final GameState gameState;
  const _GameOverScreen({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 하드웨어 백키 → 홈으로 이동 (게임 정리 포함)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(gameProvider.notifier).giveUp();
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 64,
                color: isDark ? Colors.red.shade400 : Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.get('game.challenge.failed'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.red.shade400 : Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.get('game.challenge.failed.desc'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // 마지막 실수 셀이 표시된 축소 보드
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                child: const SudokuBoardWidget(),
              ),
              const SizedBox(height: 16),
              Text(
                '${AppStrings.get('game.info.mistakes')}: ${gameState.mistakeCount}/${gameState.maxMistakes}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.read(gameProvider.notifier).giveUp();
                  context.go(AppRoutes.home);
                },
                icon: const Icon(Icons.home_rounded),
                label: Text(AppStrings.get('result.home')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(gameProvider.notifier).startNewGame(
                    mode: GameMode.challenge,
                    difficulty: gameState.difficulty,
                  );
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppStrings.get('result.newGame')),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
