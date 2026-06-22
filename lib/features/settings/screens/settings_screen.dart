import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/backup_service.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/l10n/app_strings.dart';
import '../../../shared/services/sound_manager.dart';
import '../../../shared/widgets/casual_widgets.dart';
import '../../../shared/utils/motion_helper.dart' as motion_helper;
import '../../../shared/widgets/kp_widgets.dart';
import 'theme_select_screen.dart';

/// 설정 화면 (S-13) — KP 디자인 시스템 적용
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // KP 디자인 컬러 상수
  static const _kpText = AppColors.kpText;
  static const _kpMuted = AppColors.kpMuted;
  static const _kpBorder = AppColors.kpBorder;
  static const _kpPaleViolet = AppColors.kpPaleViolet;
  static const _kpBlue = AppColors.brandBlue;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStrings.get;

    return Scaffold(
      // AppBar 제거 — 커스텀 헤더 Row 사용
      body: KPBackground(
        child: CustomScrollView(
          slivers: [
            // 커스텀 AppBar 영역
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.list(
                children: [
                  _buildAppBar(context, s),
                ],
              ),
            ),

            // 메인 설정 콘텐츠
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.list(
                children: [
                  // ── 화면 설정 섹션 ──
                  _sectionTitle(s('settings.display'), 'assets/icons/palette.svg'),
                  _card(isDark, [
                    _ThemeTile(
                      currentMode: settings.themeMode,
                      onChanged: (mode) async {
                        await settings.setThemeMode(mode);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.palette_outlined,
                          color: isDark ? Colors.white70 : _kpMuted),
                      title: Text(s('settings.themeSelect'),
                          style: _tileTitleStyle(isDark)),
                      trailing: _trailingChevron(isDark),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ThemeSelectScreen()),
                        );
                      },
                    ),
                    _FontScaleTile(
                      currentScale: settings.fontScale,
                      onChanged: (scale) async {
                        await settings.setFontScale(scale);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    // 언어 설정
                    _LanguageTile(
                      currentLang: AppStrings.currentLanguage,
                      onChanged: (lang) async {
                        await settings.setLanguage(lang.locale.languageCode);
                        AppStrings.setLanguage(lang);
                        ref.invalidate(settingsProvider);
                        if (mounted) setState(() {});
                      },
                    ),
                  ]),

                  // ── 게임플레이 설정 섹션 ──
                  _sectionTitle(s('settings.gameplay'), 'assets/icons/gear.svg'),
                  _card(isDark, [
                    SwitchListTile(
                      title: Text(s('settings.showMistakes'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.showMistakes.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      value: settings.showMistakes,
                      onChanged: (value) async {
                        await settings.setShowMistakes(value);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    SwitchListTile(
                      title: Text(s('settings.showTimer'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.showTimer.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      value: settings.showTimer,
                      onChanged: (value) async {
                        await settings.setShowTimer(value);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    SwitchListTile(
                      title: Text(s('settings.autoComplete'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.autoComplete.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      value: settings.autoComplete,
                      onChanged: (value) async {
                        await settings.setAutoComplete(value);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                  ]),

                  // ── 피드백 설정 섹션 ──
                  _sectionTitle(
                      s('settings.feedback'), 'assets/icons/speaker.svg'),
                  _card(isDark, [
                    SwitchListTile(
                      title: Text(s('settings.sound'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.sound.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      value: settings.soundEnabled,
                      onChanged: (value) async {
                        await settings.setSoundEnabled(value);
                        SoundManager().setEnabled(value);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    SwitchListTile(
                      title: Text(s('settings.vibration'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.vibration.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      value: settings.vibrationEnabled,
                      onChanged: (value) async {
                        await settings.setVibrationEnabled(value);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                    SwitchListTile(
                      title: Text(s('settings.reduceEffects'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.reduceEffects.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      value: settings.reduceEffects,
                      onChanged: (value) async {
                        await settings.setReduceEffects(value);
                        // 글로벌 효과 줄이기 플래그 즉시 반영
                        motion_helper.setReduceEffects(value);
                        ref.invalidate(settingsProvider);
                      },
                    ),
                  ]),

                  // ── 정보 섹션 ──
                  _sectionTitle(s('settings.info'), 'assets/icons/info.svg'),
                  _card(isDark, [
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded,
                          color: isDark ? Colors.white70 : _kpMuted),
                      title: Text(s('settings.version'),
                          style: _tileTitleStyle(isDark)),
                      trailing: Text(
                        '1.0.0',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : _kpMuted,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.wifi_off_rounded,
                          color: isDark ? Colors.white70 : _kpMuted),
                      title: Text(s('settings.offline'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.offline.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      trailing: Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade400,
                      ),
                    ),
                  ]),

                  // ── 백업 섹션 ──
                  _sectionTitle(
                      s('settings.backup'), 'assets/icons/upload.svg'),
                  _card(isDark, [
                    ListTile(
                      leading: Icon(Icons.upload_file_rounded,
                          color: isDark ? Colors.white70 : _kpMuted),
                      title: Text(s('settings.backup.export'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.backup.export.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      trailing: _trailingChevron(isDark),
                      onTap: () => _exportBackup(context, ref),
                    ),
                    ListTile(
                      leading: Icon(Icons.download_rounded,
                          color: isDark ? Colors.white70 : _kpMuted),
                      title: Text(s('settings.backup.import'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.backup.import.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      trailing: _trailingChevron(isDark),
                      onTap: () => _importBackup(context, ref),
                    ),
                  ]),

                  // ── 기타 항목 ──
                  const SizedBox(height: 12),
                  _card(isDark, [
                    ListTile(
                      leading: Icon(Icons.description_outlined,
                          color: isDark ? Colors.white70 : _kpMuted),
                      title: Text(s('settings.licenses'),
                          style: _tileTitleStyle(isDark)),
                      trailing: _trailingChevron(isDark),
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'K-Puzzles',
                          applicationVersion: '1.0.0',
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.favorite_outline_rounded,
                          color: isDark ? Colors.white70 : _kpMuted),
                      title: Text(s('settings.donation'),
                          style: _tileTitleStyle(isDark)),
                      subtitle: Text(s('settings.donation.desc'),
                          style: _tileSubtitleStyle(isDark)),
                      trailing: _trailingChevron(isDark),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const DonationScreen()),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 커스텀 AppBar — KPIconButton(뒤로가기) + 가운데 제목
  Widget _buildAppBar(BuildContext context, String Function(String) s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          KPIconButton(
            asset: 'assets/icons/arrow-left.svg',
            size: 44,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            s('settings.title'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : _kpText,
            ),
          ),
          const Spacer(),
          // 오른쪽 대칭용 빈 공간 (뒤로가기 버튼 크기만큼)
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  /// KP 스타일 섹션 타이틀 — SVG 아이콘 + paleViolet 배경 + 파란 볼드 텍스트
  Widget _sectionTitle(String text, String svgAsset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 10),
      child: Row(
        children: [
          // SVG 아이콘 컨테이너
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? _kpPaleViolet.withValues(alpha: 0.15)
                  : _kpPaleViolet,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: SvgPicture.asset(
                svgAsset,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  isDark ? AppColors.brandViolet : AppColors.brandIndigo,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDark ? AppColors.brandSkyBlue : _kpBlue,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// KP 스타일 카드 — 흰색 둥근 컨테이너 + 소프트 그림자 + 디바이더
  Widget _card(bool isDark, List<Widget> rows) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: isDark ? null : KPShadow.soft,
        border: Border.all(
          color: isDark ? AppColors.outlineDark : _kpBorder,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(
                height: 1,
                indent: 72,
                color: isDark ? AppColors.outlineDark : _kpBorder,
              ),
          ],
        ],
      ),
    );
  }

  /// 타일 제목 텍스트 스타일
  TextStyle _tileTitleStyle(bool isDark) => TextStyle(
        color: isDark ? Colors.white : _kpText,
      );

  /// 타일 부제목 텍스트 스타일
  TextStyle _tileSubtitleStyle(bool isDark) => TextStyle(
        color: isDark ? Colors.white54 : _kpMuted,
        fontSize: 13,
      );

  /// 트레일링 쉐브론 아이콘
  Widget _trailingChevron(bool isDark) => SvgPicture.asset(
        'assets/icons/chevron-right.svg',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          isDark ? Colors.white38 : _kpMuted,
          BlendMode.srcIn,
        ),
      );

  /// 내보내기: 파일 저장 후 공유 시트로 전송
  Future<void> _exportBackup(BuildContext ctx, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final service = BackupService(prefs);

      // 내보낼 데이터 확인
      if (!service.hasExportableData()) {
        if (ctx.mounted) {
          showKPToast(ctx, AppStrings.get('settings.backup.noData'), type: KPToastType.warning);
        }
        return;
      }

      // 파일 저장
      final file = await service.saveBackup();

      if (!ctx.mounted) return;

      // 공유 시트로 파일 전송
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'K-Puzzles ${AppStrings.get('settings.backup.title')}',
        ),
      );
    } catch (e) {
      if (ctx.mounted) {
        showKPToast(ctx, '${AppStrings.get('settings.backup.error')}: $e', type: KPToastType.error);
      }
    }
  }

  /// 가져오기: 내부 백업 파일 목록에서 선택하여 복원
  Future<void> _importBackup(BuildContext ctx, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final service = BackupService(prefs);
      final files = await service.listBackups();

      if (files.isEmpty) {
        if (ctx.mounted) {
          showKPToast(ctx, AppStrings.get('settings.backup.noFiles'), type: KPToastType.warning);
        }
        return;
      }

      if (!ctx.mounted) return;

      // 백업 파일 선택 다이얼로그 (KP 스타일)
      final selected = await _showKPFileSelectDialog(ctx, files);

      if (selected == null || !ctx.mounted) return;

      // 복원 방식 선택: 추가 vs 덮어쓰기 (KP 스타일)
      final overwrite = await _showKPRestoreModeDialog(ctx);

      if (overwrite == null || !ctx.mounted) return;

      final json = await selected.readAsString();
      final success =
          await service.restoreFromJson(json, overwrite: overwrite);
      if (ctx.mounted) {
        showKPToast(
          ctx,
          success
              ? AppStrings.get('settings.backup.restored')
              : AppStrings.get('settings.backup.error'),
          type: success ? KPToastType.success : KPToastType.error,
        );
        if (success) ref.invalidate(settingsProvider);
      }
    } catch (e) {
      if (ctx.mounted) {
        showKPToast(ctx, '${AppStrings.get('settings.backup.error')}: $e', type: KPToastType.error);
      }
    }
  }

  /// KP 스타일 백업 파일 선택 다이얼로그
  Future<File?> _showKPFileSelectDialog(BuildContext ctx, List<File> files) {
    return showGeneralDialog<File>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (c, anim, _, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (dialogCtx, _, __) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1D32) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandIndigo.withValues(alpha: 0.15),
                    blurRadius: 24, offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 그라데이션 헤더
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.brandIndigo.withValues(alpha: 0.3), AppColors.brandIndigo.withValues(alpha: 0.1)]
                            : [AppColors.brandIndigo.withValues(alpha: 0.08), AppColors.brandIndigo.withValues(alpha: 0.02)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppStrings.get('settings.backup.selectFile'),
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.brandIndigo,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.auto_awesome, size: 18, color: AppColors.brandGold),
                      ],
                    ),
                  ),
                  // 파일 목록
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: files.length,
                      itemBuilder: (_, i) {
                        final name = files[i].path.split('/').last.split('\\').last;
                        return ListTile(
                          title: Text(name, style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                          )),
                          onTap: () => Navigator.pop(dialogCtx, files[i]),
                        );
                      },
                    ),
                  ),
                  // 취소 버튼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: Text(
                          AppStrings.get('cancel'),
                          style: TextStyle(
                            color: isDark ? Colors.white60 : AppColors.brandIndigo,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// KP 스타일 복원 방식 선택 다이얼로그
  Future<bool?> _showKPRestoreModeDialog(BuildContext ctx) {
    return showGeneralDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (c, anim, _, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (dialogCtx, _, __) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1D32) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandIndigo.withValues(alpha: 0.15),
                    blurRadius: 24, offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 그라데이션 헤더
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [AppColors.brandIndigo.withValues(alpha: 0.3), AppColors.brandIndigo.withValues(alpha: 0.1)]
                            : [AppColors.brandIndigo.withValues(alpha: 0.08), AppColors.brandIndigo.withValues(alpha: 0.02)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.get('settings.backup.restore.title'),
                            style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.brandIndigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.auto_awesome, size: 18, color: AppColors.brandGold),
                      ],
                    ),
                  ),
                  // 본문
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.get('settings.backup.restore.message'),
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF4A4A5A),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 3개 버튼: 취소 / 추가 / 덮어쓰기
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(
                                  AppStrings.get('cancel'),
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : AppColors.brandIndigo,
                                    fontWeight: FontWeight.w700, fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(dialogCtx, false),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Ink(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        AppColors.brandIndigo,
                                        AppColors.brandIndigo.withValues(alpha: 0.8),
                                      ]),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        AppStrings.get('settings.backup.restore.add'),
                                        style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(dialogCtx, true),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Ink(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFFEF5350),
                                        Color(0xFFE53935),
                                      ]),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        AppStrings.get('settings.backup.restore.overwrite'),
                                        style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 테마 선택 타일
class _ThemeTile extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeTile({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 라벨이 긴 언어(스페인어/프랑스어/힌디어/아랍어 등)에서도 글자가 세로로 깨지지 않도록
    // 라벨을 위, 세그먼트를 아래로 분리 배치
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconForMode(currentMode),
                  color: isDark ? Colors.white70 : AppColors.kpMuted),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppStrings.get('settings.theme'),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.kpText,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 18),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (set) => onChanged(set.first),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }
}

/// 글자 크기 타일
class _FontScaleTile extends StatelessWidget {
  final double currentScale;
  final ValueChanged<double> onChanged;

  const _FontScaleTile({required this.currentScale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.get;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 라벨이 긴 언어에서도 글자가 세로로 깨지지 않도록 라벨/세그먼트 분리 배치
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields_rounded,
                  color: isDark ? Colors.white70 : AppColors.kpMuted),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  s('settings.fontSize'),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.kpText,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<double>(
              segments: [
                ButtonSegment(
                    value: 1.0, label: Text(s('settings.fontDefault'))),
                ButtonSegment(
                    value: 1.3, label: Text(s('settings.fontLarge'))),
                ButtonSegment(
                    value: 1.6, label: Text(s('settings.fontXLarge'))),
              ],
              selected: {currentScale},
              onSelectionChanged: (set) => onChanged(set.first),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    );
  }
}

/// 언어 선택 타일
class _LanguageTile extends StatelessWidget {
  final AppLanguage currentLang;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguageTile({required this.currentLang, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(Icons.language_rounded,
          color: isDark ? Colors.white70 : AppColors.kpMuted),
      title: Text(AppStrings.get('settings.language'),
          style: TextStyle(color: isDark ? Colors.white : AppColors.kpText)),
      trailing: DropdownButton<AppLanguage>(
        value: currentLang,
        underline: const SizedBox.shrink(),
        items: AppLanguage.values.map((lang) {
          return DropdownMenuItem(
            value: lang,
            child: Text(lang.label),
          );
        }).toList(),
        onChanged: (lang) {
          if (lang != null) onChanged(lang);
        },
      ),
    );
  }
}

/// 도네이션 화면
class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  static const _cryptoAddresses = [
    _CryptoAddress(
      network: 'Ethereum / Base / BNB / Arbitrum',
      icon: '⟠',
      address: '0x6104B5663077d230C137d3DB9Cb66EaBAFa53b40',
    ),
    _CryptoAddress(
      network: 'Solana',
      icon: '◎',
      address: 'HEcm7moxhrRCMxvZtAsDmRseR5md4gQxHFzrTD2WbSYE',
    ),
    _CryptoAddress(
      network: 'Tron',
      icon: '◆',
      address: 'TCFhHKPKSwDyFJEb1uKc6iDqyh82Pf1G9b',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStrings.get;

    return Scaffold(
      appBar: AppBar(title: Text(s('donation.title'))),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.brandCoral.withValues(alpha: 0.15), AppColors.backgroundDark]
                : [AppColors.brandCoral.withValues(alpha: 0.06), AppColors.backgroundLight],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 하트 히어로 카드
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.brandCoral.withValues(alpha: 0.25), AppColors.brandCoral.withValues(alpha: 0.08)]
                        : [AppColors.brandCoral.withValues(alpha: 0.12), AppColors.brandCoral.withValues(alpha: 0.04)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text('☕', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 12),
                    Text(
                      s('donation.message'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CasualSectionHeader(
                title: s('donation.crypto'),
                icon: Icons.currency_bitcoin_rounded,
                color: AppColors.brandGold,
              ),
              const SizedBox(height: 8),
              ..._cryptoAddresses.map((crypto) => _CryptoCard(
                    crypto: crypto,
                    isDark: isDark,
                  )),
              const SizedBox(height: 24),
              const _AdBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CryptoAddress {
  final String network;
  final String icon;
  final String address;
  const _CryptoAddress({
    required this.network,
    required this.icon,
    required this.address,
  });
}

/// 암호화폐 주소 카드 -- 주소 탭으로 클립보드 복사
class _CryptoCard extends StatelessWidget {
  final _CryptoAddress crypto;
  final bool isDark;

  const _CryptoCard({required this.crypto, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(crypto.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    crypto.network,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 주소 영역 -- 탭으로 복사
            InkWell(
              onTap: () => _copyAddress(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        crypto.address,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: crypto.address));
    showKPToast(context, AppStrings.get('donation.addressCopied'), type: KPToastType.success);
  }
}

/// 광고 배너 -- 외부 브라우저로 열기
class _AdBanner extends StatelessWidget {
  static const _adUrl = 'https://m.site.naver.com/2anPf';

  const _AdBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openAd(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.deepOrange.shade900 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: isDark ? Colors.amber.shade200 : Colors.deepOrange.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('donation.ad.title'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.get('donation.ad.desc'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAd() async {
    final uri = Uri.parse(_adUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // 브라우저 없는 환경에서는 무시
    }
  }
}
