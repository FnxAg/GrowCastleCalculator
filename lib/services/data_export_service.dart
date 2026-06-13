import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';

/// Handles exporting and importing all app data as JSON files.
class DataExportService {
  DataExportService._();

  /// Exports all saved data to a JSON file and opens the platform share sheet.
  static Future<void> exportData(BuildContext context) async {
    try {
      final data = await PreferencesService.exportAllData();

      final exportMap = {
        'version': 1,
        'app': 'grow_castle_calculator',
        'exportTime': DateTime.now().toIso8601String(),
        'data': data,
      };

      final jsonString =
          const JsonEncoder.withIndent('  ').convert(exportMap);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/grow_castle_data_export.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Grow Castle Calculator - Data Export',
      );

      if (!context.mounted) return;
      _showSnackBar(context, AppLocalizations.of(context)!.exportSuccess);
    } catch (_) {
      if (!context.mounted) return;
      _showSnackBar(context, AppLocalizations.of(context)!.exportFailed);
    }
  }

  /// Lets the user pick a JSON file and imports its data into the app.
  static Future<void> importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      if (!await file.exists()) {
        if (!context.mounted) return;
        _showSnackBar(context, AppLocalizations.of(context)!.importFailed);
        return;
      }

      final jsonString = await file.readAsString();
      final decoded = json.decode(jsonString);

      if (decoded is! Map<String, dynamic>) {
        if (!context.mounted) return;
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.invalidDataFormat,
        );
        return;
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        if (!context.mounted) return;
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.invalidDataFormat,
        );
        return;
      }

      if (!context.mounted) return;
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

      await PreferencesService.importData(data);

      if (!context.mounted) return;
      _showSnackBar(context, AppLocalizations.of(context)!.importSuccess);
    } catch (_) {
      if (!context.mounted) return;
      _showSnackBar(context, AppLocalizations.of(context)!.importFailed);
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
