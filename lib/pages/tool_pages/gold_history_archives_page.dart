import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/models/gold_calculator_archive.dart';
import 'package:grow_castle_calculator/models/gold_calculator_data.dart';
import 'package:grow_castle_calculator/providers/gold_calculator_provider.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
import 'package:grow_castle_calculator/utils/number_utils.dart';

/// Page that lists all saved gold calculator archives with options to load,
/// rename, or delete each one.
class GoldHistoryArchivesPage extends StatefulWidget {
  const GoldHistoryArchivesPage({super.key});

  @override
  State<GoldHistoryArchivesPage> createState() =>
      _GoldHistoryArchivesPageState();
}

class _GoldHistoryArchivesPageState extends State<GoldHistoryArchivesPage> {
  List<GoldCalculatorArchive> _archives = [];

  @override
  void initState() {
    super.initState();
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    final archives = await PreferencesService.loadGoldArchives();
    if (mounted) {
      setState(() => _archives = archives);
    }
  }

  Future<void> _deleteArchive(GoldCalculatorArchive archive) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.delete),
        content: Text(loc.deleteArchiveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _archives.removeWhere((a) => a.id == archive.id);
      await PreferencesService.saveGoldArchives(_archives);
      if (mounted) setState(() {});
    }
  }

  Future<void> _renameArchive(GoldCalculatorArchive archive) async {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: archive.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.renameArchive),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: loc.archiveName,
            hintText: loc.enterArchiveName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(loc.confirm),
          ),
        ],
      ),
    );

    controller.dispose();
    if (newName == null || newName.trim().isEmpty) return;

    final index = _archives.indexWhere((a) => a.id == archive.id);
    if (index != -1) {
      _archives[index] = GoldCalculatorArchive(
        id: archive.id,
        name: newName.trim(),
        savedAt: archive.savedAt,
        waveValue: archive.waveValue,
        formField: archive.formField,
        checkboxForm: archive.checkboxForm,
        isExpanded: archive.isExpanded,
      );
      await PreferencesService.saveGoldArchives(_archives);
      if (mounted) setState(() {});
    }
  }

  /// Computes the summary values for a gold calculator archive.
  _GoldArchiveSummary _computeSummary(GoldCalculatorArchive archive) {
    final data = GoldCalculatorData(
      waveValue: archive.waveValue,
      formField: archive.formField,
      checkboxForm: archive.checkboxForm,
      isExpanded: archive.isExpanded,
    );
    final dailyIncome = GoldCalculatorProvider.computeDailyIncome(data);
    final wave =
        archive.waveValue.isNotEmpty ? archive.waveValue[0] : 0;
    final icLevel = archive.formField.length > 3
        ? archive.formField[3].truncate().toString()
        : '0';

    String dailyIncomeStr;
    try {
      dailyIncomeStr = decreaseNumSize(dailyIncome, context);
    } catch (_) {
      dailyIncomeStr = dailyIncome.toStringAsFixed(0);
    }

    return _GoldArchiveSummary(
      wave: wave.toString(),
      dailyIncome: dailyIncomeStr,
      icLevel: icLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.historyArchives),
        elevation: 1,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _archives.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant
                          .withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.noArchives,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _archives.length,
              itemBuilder: (context, index) {
                final archive = _archives[index];
                final summary = _computeSummary(archive);
                return _buildArchiveCard(
                    context, archive, summary, theme);
              },
            ),
    );
  }

  Widget _buildArchiveCard(
    BuildContext context,
    GoldCalculatorArchive archive,
    _GoldArchiveSummary summary,
    ThemeData theme,
  ) {
    final loc = AppLocalizations.of(context)!;
    final dateStr =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(archive.savedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: name + popup menu
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            archive.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'load':
                          _onLoadArchive(archive);
                        case 'rename':
                          _renameArchive(archive);
                        case 'delete':
                          _deleteArchive(archive);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'load',
                        child: ListTile(
                          leading: const Icon(Icons.download),
                          title: Text(loc.load),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: const Icon(Icons.edit),
                          title: Text(loc.rename),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete,
                              color: theme.colorScheme.error),
                          title: Text(loc.delete,
                              style: TextStyle(
                                  color: theme.colorScheme.error)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Bottom row: summary stats
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    _summaryChip(
                        loc.currentWave, summary.wave, theme),
                    _summaryChip(
                        loc.goldDay, summary.dailyIncome, theme,
                        bold: true),
                    _summaryChip(
                        loc.icLevel, summary.icLevel, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, ThemeData theme,
      {bool bold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: bold
                ? TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                  )
                : const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _onLoadArchive(GoldCalculatorArchive archive) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.load),
        content: Text(loc.loadArchiveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, archive);
            },
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
  }
}

/// Lightweight data class for computed archive summary values.
class _GoldArchiveSummary {
  final String wave;
  final String dailyIncome;
  final String icLevel;

  const _GoldArchiveSummary({
    required this.wave,
    required this.dailyIncome,
    required this.icLevel,
  });
}

