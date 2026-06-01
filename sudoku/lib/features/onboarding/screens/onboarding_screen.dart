import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';

/// 첫 실행 온보딩 화면
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  List<_OnboardingPage> get _pages => [
    _OnboardingPage(
      icon: Icons.grid_on_rounded,
      title: AppStrings.get('onboarding.page1.title'),
      description: AppStrings.get('onboarding.page1.desc'),
    ),
    _OnboardingPage(
      icon: Icons.lightbulb_outline_rounded,
      title: AppStrings.get('onboarding.page2.title'),
      description: AppStrings.get('onboarding.page2.desc'),
    ),
    _OnboardingPage(
      icon: Icons.emoji_events_outlined,
      title: AppStrings.get('onboarding.page3.title'),
      description: AppStrings.get('onboarding.page3.desc'),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) =>
                    setState(() => _currentPage = page),
                children: _pages,
              ),
            ),
            // 페이지 인디케이터
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? (isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight)
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? AppStrings.get('onboarding.next') : AppStrings.get('onboarding.start'),
                  ),
                ),
              ),
            ),
            // 건너뛰기
            if (_currentPage < _pages.length - 1)
              TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  AppStrings.get('onboarding.skip'),
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _completeOnboarding() {
    ref.read(settingsProvider).setFirstLaunchDone();
    context.go(AppRoutes.home);
  }
}

/// 온보딩 페이지
class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
