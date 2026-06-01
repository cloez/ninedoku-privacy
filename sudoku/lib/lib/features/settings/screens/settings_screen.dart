import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/storage/backup_service.dart';
import '../../../shared/l10n/app_strings.dart';
import 'theme_select_screen.dart';

/// 설정 화면 (S-13)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStrings.get;

    return Scaffold(
      appBar: AppBar(title: Text(s('settings.title'))),
      body: ListView(
        children: [
          // 화면 설정
          _SectionHeader(title: s('settings.display')),
          _ThemeTile(
            currentMode: settings.themeMode,
            onChanged: (mode) async {
              await settings.setThemeMode(mode);
              ref.invalidate(settingsProvider);
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(s('settings.themeSelect')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemeSelectScreen()),
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
          const Divider(),

          // 게임플레이 설정
          _SectionHeader(title: s('settings.gameplay')),
          SwitchListTile(
            title: Text(s('settings.showMistakes')),
            subtitle: Text(s('settings.showMistakes.desc')),
            value: settings.showMistakes,
            onChanged: (value) async {
              await settings.setShowMistakes(value);
              ref.invalidate(settingsProvider);
            },
          ),
          SwitchListTile(
            title: Text(s('settings.showTimer')),
            subtitle: Text(s('settings.showTimer.desc')),
            value: settings.showTimer,
            onChanged: (value) async {
              await settings.setShowTimer(value);
              ref.invalidate(settingsProvider);
            },
          ),
          SwitchListTile(
            title: Text(s('settings.autoComplete')),
            subtitle: Text(s('settings.autoComplete.desc')),
            value: settings.autoComplete,
            onChanged: (value) async {
              await settings.setAutoComplete(value);
              ref.invalidate(settingsProvider);
            },
          ),
          const Divider(),

          // 피드백 설정
          _SectionHeader(title: s('settings.feedback')),
          SwitchListTile(
            title: Text(s('settings.sound')),
            subtitle: Text(s('settings.sound.desc')),
            value: settings.soundEnabled,
            onChanged: (value) async {
              await settings.setSoundEnabled(value);
              ref.invalidate(settingsProvider);
            },
          ),
          SwitchListTile(
            title: Text(s('settings.vibration')),
            subtitle: Text(s('settings.vibration.desc')),
            value: settings.vibrationEnabled,
            onChanged: (value) async {
              await settings.setVibrationEnabled(value);
              ref.invalidate(settingsProvider);
            },
          ),
          const Divider(),

          // 정보
          _SectionHeader(title: s('settings.info')),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(s('settings.version')),
            trailing: Text(
              '1.0.0',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wifi_off_rounded),
            title: Text(s('settings.offline')),
            subtitle: Text(s('settings.offline.desc')),
            trailing: Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade400,
            ),
          ),
          const Divider(),
          _SectionHeader(title: s('settings.backup')),
          ListTile(
            leading: const Icon(Icons.upload_file_rounded),
            title: Text(s('settings.backup.export')),
            subtitle: Text(s('settings.backup.export.desc')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: Text(s('settings.backup.import')),
            subtitle: Text(s('settings.backup.import.desc')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _importBackup(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(s('settings.licenses')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Ninedoku',
                applicationVersion: '1.0.0',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline_rounded),
            title: Text(s('settings.donation')),
            subtitle: Text(s('settings.donation.desc')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DonationScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 내보내기: 파일 저장 후 공유 시트로 전송
  Future<void> _exportBackup(BuildContext ctx, WidgetRef ref) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final service = BackupService(prefs);

      // 내보낼 데이터 확인
      if (!service.hasExportableData()) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(AppStrings.get('settings.backup.noData'))),
          );
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
          subject: 'Ninedoku ${AppStrings.get('settings.backup.title')}',
        ),
      );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('${AppStrings.get('settings.backup.error')}: $e')),
        );
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
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(AppStrings.get('settings.backup.noFiles'))),
          );
        }
        return;
      }

      if (!ctx.mounted) return;

      // 백업 파일 선택 다이얼로그
      final selected = await showDialog<File>(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: Text(AppStrings.get('settings.backup.selectFile')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              itemBuilder: (_, i) {
                final name = files[i].path.split('/').last.split('\\').last;
                return ListTile(
                  title: Text(name, style: const TextStyle(fontSize: 13)),
                  onTap: () => Navigator.pop(dialogCtx, files[i]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppStrings.get('cancel')),
            ),
          ],
        ),
      );

      if (selected == null || !ctx.mounted) return;

      // 복원 방식 선택: 추가 vs 덮어쓰기
      final overwrite = await showDialog<bool>(
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: Text(AppStrings.get('settings.backup.restore.title')),
          content: Text(AppStrings.get('settings.backup.restore.message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppStrings.get('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(AppStrings.get('settings.backup.restore.add')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(AppStrings.get('settings.backup.restore.overwrite')),
            ),
          ],
        ),
      );

      if (overwrite == null || !ctx.mounted) return;

      final json = await selected.readAsString();
      final success = await service.restoreFromJson(json, overwrite: overwrite);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(
            success
                ? AppStrings.get('settings.backup.restored')
                : AppStrings.get('settings.backup.error'),
          )),
        );
        if (success) ref.invalidate(settingsProvider);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('${AppStrings.get('settings.backup.error')}: $e')),
        );
      }
    }
  }
}

/// 섹션 헤더
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
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
    return ListTile(
      leading: Icon(_iconForMode(currentMode)),
      title: Text(AppStrings.get('settings.theme')),
      trailing: SegmentedButton<ThemeMode>(
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
    return ListTile(
      leading: const Icon(Icons.text_fields_rounded),
      title: Text(s('settings.fontSize')),
      trailing: SegmentedButton<double>(
        segments: [
          ButtonSegment(value: 1.0, label: Text(s('settings.fontDefault'))),
          ButtonSegment(value: 1.3, label: Text(s('settings.fontLarge'))),
          ButtonSegment(value: 1.6, label: Text(s('settings.fontXLarge'))),
        ],
        selected: {currentScale},
        onSelectionChanged: (set) => onChanged(set.first),
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
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
    return ListTile(
      leading: const Icon(Icons.language_rounded),
      title: Text(AppStrings.get('settings.language')),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.favorite_rounded,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              s('donation.message'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Text(
              s('donation.crypto'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._cryptoAddresses.map((crypto) => _CryptoCard(
                  crypto: crypto,
                  isDark: isDark,
                )),
            const SizedBox(height: 24),
            // 광고 섹션
            const _AdBanner(),
          ],
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

/// 암호화폐 주소 카드 — 주소 탭으로 클립보드 복사
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
            // 주소 영역 — 탭으로 복사
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.get('donation.addressCopied')),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 광고 배너 — 외부 브라우저로 열기
class _AdBanner extends StatelessWidget {
  static const _adUrl = 'https://bit.ly/4wT5dxi';

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
                  color: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_bag_rounded,
                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
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
