import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grow_castle_calculator/pages/update_checker_page/update_checker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/main.dart';
import 'package:grow_castle_calculator/enums/locale_option.dart';
import 'package:grow_castle_calculator/enums/theme_option.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.language),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocaleOption.fromLocaleCode2LocaleOption(
                      localeChoice,
                    ).localeString,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_right),
                ],
              ),
              onTap: () async {
                final choice = await _changeLanguageDialog();
                choice == null
                    ? null
                    : setState(() {
                        Get.updateLocale(
                          LocaleOption.values[choice].localeType,
                        );
                        localeChoice =
                            LocaleOption.values[choice].localeCode;
                        _saveLocale();
                      });
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text(AppLocalizations.of(context)!.themeMode),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ThemeOption.fromThemeCode2ThemeOption(
                      themeChoice,
                    ).themeString,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_right),
                ],
              ),
              onTap: () async {
                final choice = await _changeThemeModeDialog();
                choice == null
                    ? null
                    : setState(() {
                        themeChoice =
                            ThemeOption.values[choice].themeCode;
                        themeProvider.setThemeMode(
                          ThemeOption.values[choice].themeMode,
                        );
                        _saveTheme();
                      });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: Text(AppLocalizations.of(context)!.clearSavedData),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                final confirm = await _clearDataDialogConfirmation();
                if (confirm == true) {
                  clearData();
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.clearDataFinished,
                        ),
                      ),
                    );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text(AppLocalizations.of(context)!.exportData),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: _exportData,
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: Text(AppLocalizations.of(context)!.importData),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: _importData,
            ),
            ListTile(
              leading: _isChecking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update),
              title: Text(AppLocalizations.of(context)!.checkForUpdates),
              trailing: const Icon(Icons.keyboard_arrow_right),
              enabled: !_isChecking,
              onTap: _isChecking ? null : _checkUpdate,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(AppLocalizations.of(context)!.about),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                showAboutDialog(
                  context: context,
                  applicationName: AppLocalizations.of(context)!.appName,
                  applicationVersion: AppLocalizations.of(
                    context,
                  )!.appVersion(await UpdateChecker.getAppVersion()),
                  applicationIcon: const Icon(Icons.calculate),
                  applicationLegalese: AppLocalizations.of(
                    context,
                  )!.developer,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.link),
                          onPressed: () async {
                            final url = Uri.parse(
                              AppLocalizations.of(
                                context,
                              )!.repositoryUrl,
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              ScaffoldMessenger.of(context)
                                ..removeCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.cannotLaunchURL(url.toString()),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                            }
                          },
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.github,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.link),
                          onPressed: () async {
                            final url = Uri.parse(
                              AppLocalizations.of(
                                context,
                              )!.developerBilibiliUrl,
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              ScaffoldMessenger.of(context)
                                ..removeCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.cannotLaunchURL(url.toString()),
                                    ),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                );
                            }
                          },
                          label: Text(
                            AppLocalizations.of(
                              context,
                            )!.bilibili,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
    );
  }

  Future<void> _saveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('localeChoice', localeChoice);
  }

  Future<int?> _changeLanguageDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(AppLocalizations.of(context)!.language),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.systemDefault),
                    localeChoice == 0 ? const Icon(Icons.check) : const SizedBox(),
                  ],
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.zh_CN_withCode),
                    localeChoice == 1 ? const Icon(Icons.check) : const SizedBox(),
                  ],
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(2),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.en_withCode),
                    localeChoice == 2 ? const Icon(Icons.check) : const SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeChoice', themeChoice);
  }

  Future<int?> _changeThemeModeDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(AppLocalizations.of(context)!.themeMode),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.systemDefault),
                    themeChoice == 0 ? const Icon(Icons.check) : const SizedBox(),
                  ],
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.lightMode),
                    themeChoice == 1 ? const Icon(Icons.check) : const SizedBox(),
                  ],
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(2),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.darkMode),
                    themeChoice == 2 ? const Icon(Icons.check) : const SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _clearDataDialogConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.clearSavedData),
          content: Text(AppLocalizations.of(context)!.clearDataWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        );
      },
    );
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('dynamicFormNum');
    prefs.remove('waveValue');
    prefs.remove('targetName');
    prefs.remove('targetLevel');
    prefs.remove('targetCheckbox');
    prefs.remove('gc_waveValue');
    prefs.remove('gc_formField');
    prefs.remove('gc_checkboxForm');
    prefs.remove('gc_isExpanded');
  }
  
  static const _dataKeys = [
    'dynamicFormNum',
    'waveValue',
    'targetName',
    'targetLevel',
    'targetCheckbox',
    'gc_waveValue',
    'gc_formField',
    'gc_checkboxForm',
    'gc_isExpanded',
  ];

  static const _stringListKeys = {
    'waveValue',
    'targetName',
    'targetLevel',
    'targetCheckbox',
    'gc_waveValue',
    'gc_formField',
    'gc_checkboxForm',
    'gc_isExpanded',
  };

  Future<void> _exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      for (final key in _dataKeys) {
        if (_stringListKeys.contains(key)) {
          data[key] = prefs.getStringList(key);
        } else {
          data[key] = prefs.getInt(key);
        }
      }

      final exportMap = {
        'version': 1,
        'app': 'grow_castle_calculator',
        'exportTime': DateTime.now().toIso8601String(),
        'data': data,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/grow_castle_data_export.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Grow Castle Calculator - Data Export',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportSuccess),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportFailed),
          ),
        );
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.importFailed),
            ),
          );
        return;
      }

      final jsonString = await file.readAsString();
      final decoded = json.decode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidDataFormat),
            ),
          );
        return;
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidDataFormat),
            ),
          );
        return;
      }

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.importData),
          content: Text(AppLocalizations.of(context)!.importWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context)!.importData),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final prefs = await SharedPreferences.getInstance();
      for (final key in _dataKeys) {
        if (!data.containsKey(key)) continue;
        final value = data[key];
        if (_stringListKeys.contains(key)) {
          if (value is List) {
            await prefs.setStringList(
              key,
              value.map((e) => e.toString()).toList(),
            );
          }
        } else {
          if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is String) {
            await prefs.setInt(key, int.tryParse(value) ?? 0);
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importSuccess),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importFailed),
          ),
        );
    }
  }

  bool _isChecking = false;

  void _checkUpdate() async {
    setState(() => _isChecking = true);
    final updateInfo = await UpdateChecker.checkForUpdate();
    setState(() => _isChecking = false);

    if (updateInfo == null) {
      _showToast(AppLocalizations.of(context)!.checkForUpdateFailed);
      return;
    }

    if (updateInfo.hasUpdate) {
      _showUpdateDialog(updateInfo);
    } else {
      _showToast(AppLocalizations.of(context)!.isLatestVersion);
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.findNewVersion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${AppLocalizations.of(context)!.currentVersion}${info.localVersion}"),
            Text("${AppLocalizations.of(context)!.latestVersion}${info.latestVersion}"),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.updateContent),
            const SizedBox(height: 8),
            Text(info.updateContent ?? AppLocalizations.of(context)!.fixedKnownIssues),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.updateLater),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              UpdateChecker.openDownloadUrl(info.downloadUrl!);
            },
            child: Text(AppLocalizations.of(context)!.updateNow),
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
}
