import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';

/// 튜토리얼 화면 (S-14) — 스도쿠 규칙 + 앱 사용법
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static List<_TutorialPage> get _pages => [
    _TutorialPage(
      icon: Icons.grid_on_rounded,
      title: AppStrings.get('tutorial.page1.title'),
      description: AppStrings.get('tutorial.page1.desc'),
    ),
    _TutorialPage(
      icon: Icons.touch_app_rounded,
      title: AppStrings.get('tutorial.page2.title'),
      description: AppStrings.get('tutorial.page2.desc'),
    ),
    _TutorialPage(
      icon: Icons.edit_note_rounded,
      title: AppStrings.get('tutorial.page3.title'),
      description: AppStrings.get('tutorial.page3.desc'),
    ),
    _TutorialPage(
      icon: Icons.undo_rounded,
      title: AppStrings.get('tutorial.page4.title'),
      description: AppStrings.get('tutorial.page4.desc'),
    ),
    _TutorialPage(
      icon: Icons.lightbulb_outline_rounded,
      title: AppStrings.get('tutorial.page5.title'),
      description: AppStrings.get('tutorial.page5.desc'),
    ),
    _TutorialPage(
      icon: Icons.emoji_events_rounded,
      title: AppStrings.get('tutorial.page6.title'),
      description: AppStrings.get('tutorial.page6.desc'),
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
      appBar: AppBar(title: Text(AppStrings.get('tutorial.title'))),
      body: Column(
        children: [
          // 페이지 뷰
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return _PageContent(page: page, isDark: isDark);
              },
            ),
          ),
          // 하단: 페이지 인디케이터 + 네비게이션
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 페이지 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => Container(
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
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
                  const SizedBox(height: 20),
                  // 네비게이션 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _currentPage > 0
                            ? () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                )
                            : null,
                        child: Text(AppStrings.get('tutorial.prev')),
                      ),
                      Text(
                        '${_currentPage + 1} / ${_pages.length}',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      _currentPage < _pages.length - 1
                          ? TextButton(
                              onPressed: () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                              child: Text(AppStrings.get('tutorial.next')),
                            )
                          : TextButton(
                              onPressed: () => context.pop(),
                              child: Text(AppStrings.get('tutorial.done')),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 페이지 컨텐츠
class _PageContent extends StatelessWidget {
  final _TutorialPage page;
  final bool isDark;

  const _PageContent({required this.page, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.icon,
            size: 72,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

/// 튜토리얼 페이지 데이터
class _TutorialPage {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
