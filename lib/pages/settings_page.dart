import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/app.dart';
import 'package:grow_castle_calculator/enums/locale_option.dart';
import 'package:grow_castle_calculator/enums/theme_option.dart';
import 'package:grow_castle_calculator/models/update_info.dart';
import 'package:grow_castle_calculator/providers/theme_provider.dart';
import 'package:grow_castle_calculator/services/data_export_service.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
import 'package:grow_castle_calculator/services/update_checker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        children: [
          // ── Language ──────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc.language),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleOption.fromLocaleCode2LocaleOption(localeChoice)
                      .localeString,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Icon(Icons.keyboard_arrow_right),
              ],
            ),
            onTap: () async {
              final choice = await _showLanguageDialog();
              if (choice != null) {
                setState(() {
                  Get.updateLocale(
                    LocaleOption.values[choice].localeType,
                  );
                  localeChoice = LocaleOption.values[choice].localeCode;
                  PreferencesService.setLocaleChoice(localeChoice);
                });
              }
            },
          ),

          // ── Theme ─────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text(loc.themeMode),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ThemeOption.fromThemeCode2ThemeOption(themeChoice)
                      .themeString,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Icon(Icons.keyboard_arrow_right),
              ],
            ),
            onTap: () async {
              final choice = await _showThemeDialog();
              if (choice != null) {
                setState(() {
                  themeChoice = ThemeOption.values[choice].themeCode;
                  themeProvider.setThemeMode(
                    ThemeOption.values[choice].themeMode,
                  );
                  PreferencesService.setThemeChoice(themeChoice);
                });
              }
            },
          ),

          // ── Clear data ────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(loc.clearSavedData),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () async {
              final confirm = await _showClearDataDialog();
              if (confirm == true) {
                await PreferencesService.clearAllData();
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(loc.clearDataFinished)),
                  );
              }
            },
          ),

          // ── Export / Import ───────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: Text(loc.exportData),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () => DataExportService.exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(loc.importData),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () => DataExportService.importData(context),
          ),

          // ── Check for updates ─────────────────────────────────────────
          ListTile(
            leading: _isChecking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update),
            title: Text(loc.checkForUpdates),
            trailing: const Icon(Icons.keyboard_arrow_right),
            enabled: !_isChecking,
            onTap: _isChecking ? null : _checkForUpdate,
          ),

          // ── About ─────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(loc.about),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  // ── Language dialog ────────────────────────────────────────────────────

  Future<int?> _showLanguageDialog() async {
    final loc = AppLocalizations.of(context)!;
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.language),
        children: [
          _buildDialogOption(
            label: loc.systemDefault,
            isSelected: localeChoice == 0,
            onTap: () => Navigator.of(ctx).pop(0),
          ),
          _buildDialogOption(
            label: loc.zh_CN_withCode,
            isSelected: localeChoice == 1,
            onTap: () => Navigator.of(ctx).pop(1),
          ),
          _buildDialogOption(
            label: loc.en_withCode,
            isSelected: localeChoice == 2,
            onTap: () => Navigator.of(ctx).pop(2),
          ),
        ],
      ),
    );
  }

  // ── Theme dialog ───────────────────────────────────────────────────────

  Future<int?> _showThemeDialog() async {
    final loc = AppLocalizations.of(context)!;
    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.themeMode),
        children: [
          _buildDialogOption(
            label: loc.systemDefault,
            isSelected: themeChoice == 0,
            onTap: () => Navigator.of(ctx).pop(0),
          ),
          _buildDialogOption(
            label: loc.lightMode,
            isSelected: themeChoice == 1,
            onTap: () => Navigator.of(ctx).pop(1),
          ),
          _buildDialogOption(
            label: loc.darkMode,
            isSelected: themeChoice == 2,
            onTap: () => Navigator.of(ctx).pop(2),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            if (isSelected) const Icon(Icons.check) else const SizedBox(),
          ],
        ),
      ),
    );
  }

  // ── Clear data dialog ──────────────────────────────────────────────────

  Future<bool?> _showClearDataDialog() {
    final loc = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.clearSavedData),
        content: Text(loc.clearDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
  }

  // ── Update checking ────────────────────────────────────────────────────

  Future<void> _checkForUpdate() async {
    setState(() => _isChecking = true);
    final info = await UpdateChecker.checkForUpdate();
    setState(() => _isChecking = false);

    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;

    if (info == null) {
      _showToast(loc.checkForUpdateFailed);
    } else if (info.hasUpdate) {
      _showUpdateDialog(info);
    } else {
      _showToast(loc.isLatestVersion);
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(loc.findNewVersion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${loc.currentVersion}${info.localVersion}'),
            Text('${loc.latestVersion}${info.latestVersion}'),
            const SizedBox(height: 12),
            Text(loc.updateContent),
            const SizedBox(height: 8),
            Text(info.updateContent ?? loc.fixedKnownIssues),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.updateLater),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (info.downloadUrl != null) {
                UpdateChecker.openDownloadUrl(info.downloadUrl!);
              }
            },
            child: Text(loc.updateNow),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── About dialog ───────────────────────────────────────────────────────

  Future<void> _showAboutDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final version = await UpdateChecker.getAppVersion();
    showAboutDialog(
      context: context,
      applicationName: loc.appName,
      applicationVersion: loc.appVersion(version),
      applicationIcon: const Icon(Icons.calculate),
      applicationLegalese: loc.developer,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLinkButton(
              icon: Icons.link,
              label: loc.github,
              url: loc.repositoryUrl,
            ),
            _buildLinkButton(
              icon: Icons.link,
              label: loc.bilibili,
              url: loc.developerBilibiliUrl,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required String url,
  }) {
    final loc = AppLocalizations.of(context)!;
    return TextButton.icon(
      icon: Icon(icon),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(loc.cannotLaunchURL(url)),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
        }
      },
      label: Text(label),
    );
  }
}
