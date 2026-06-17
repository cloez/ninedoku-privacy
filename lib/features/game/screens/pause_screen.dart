import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/widgets/kp_widgets.dart';
import '../game_notifier.dart';
import '../../../shared/constants/app_colors.dart';

/// 일시정지 화면 (S-06) - 보드 가림
class PauseScreen extends ConsumerWidget {
  const PauseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    if (gameState == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seconds = gameState.elapsedSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    // 하드웨어 백키 → 게임 재개 (재개 버튼과 동일)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(gameProvider.notifier).resume();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('pause.title')),
        automaticallyImplyLeading: false,
      ),
      body: KPBackground(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // 일시정지 히어로 (KP 스타일)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: isDark ? null : KPShadow.soft,
                    ),
                    child: Column(
                      children: [
                        // 일시정지 SVG 아이콘
                        SvgPicture.asset(
                          'assets/icons/pause.svg',
                          width: 72,
                          height: 72,
                          colorFilter: ColorFilter.mode(
                            isDark ? AppColors.primaryDark : AppColors.brandIndigo,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.get('pause.message'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppStrings.get('pause.elapsed')}$timeText',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: isDark ? Colors.white54 : AppColors.kpMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // 재개 (KP 그라데이션 CTA)
                  KPGradientButton(
                    onTap: () => ref.read(gameProvider.notifier).resume(),
                    iconAsset: 'assets/icons/play.svg',
                    label: AppStrings.get('pause.resume'),
                    colors: [AppColors.brandIndigo, AppColors.brandViolet],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(AppStrings.get('pause.home')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showGiveUpDialog(context, ref),
                      icon: Icon(
                        Icons.flag_outlined,
                        color: isDark ? AppColors.wrongNumberDark : AppColors.wrongNumberLight,
                      ),
                      label: Text(
                        AppStrings.get('pause.giveUp'),
                        style: TextStyle(
                          color: isDark ? AppColors.wrongNumberDark : AppColors.wrongNumberLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  void _showGiveUpDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('pause.giveUp.title')),
        content: Text(AppStrings.get('pause.giveUp.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(gameProvider.notifier).giveUp();
              context.go(AppRoutes.home);
            },
            child: Text(
              AppStrings.get('pause.giveUp.action'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
