import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/models/calculator_archive.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
import 'package:grow_castle_calculator/utils/game_calculations.dart';
import 'package:grow_castle_calculator/utils/number_utils.dart';

/// Page that lists all saved calculator archives with options to load, rename,
/// or delete each one.
class HistoryArchivesPage extends StatefulWidget {
  const HistoryArchivesPage({super.key});

  @override
  State<HistoryArchivesPage> createState() => _HistoryArchivesPageState();
}

class _HistoryArchivesPageState extends State<HistoryArchivesPage> {
  List<CalculatorArchive> _archives = [];

  @override
  void initState() {
    super.initState();
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    final archives = await PreferencesService.loadArchives();
    if (mounted) {
      setState(() => _archives = archives);
    }
  }

  Future<void> _deleteArchive(CalculatorArchive archive) async {
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
      await PreferencesService.saveArchives(_archives);
      if (mounted) setState(() {});
    }
  }

  Future<void> _renameArchive(CalculatorArchive archive) async {
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
      _archives[index] = CalculatorArchive(
        id: archive.id,
        name: newName.trim(),
        savedAt: archive.savedAt,
        dynamicFormNum: archive.dynamicFormNum,
        waveValue: archive.waveValue,
        targetName: archive.targetName,
        targetLevel: archive.targetLevel,
        targetCheckbox: archive.targetCheckbox,
        visibleColumns: archive.visibleColumns,
      );
      await PreferencesService.saveArchives(_archives);
      if (mounted) setState(() {});
    }
  }

  /// Computes the summary values for an archive.  Mirrors the logic in
  /// [CalculatorPage._updateComputedValues].
  _ArchiveSummary _computeSummary(CalculatorArchive archive) {
    final targetGold = List.generate(
      archive.targetLevel.length.clamp(0, archive.dynamicFormNum),
      (i) => waveLevelSpendGold(
        i < archive.targetLevel.length ? archive.targetLevel[i] : 10000,
        i,
      ),
    );

    final totalGold = targetGold
        .asMap()
        .entries
        .where((e) =>
            e.key < archive.dynamicFormNum &&
            e.key < archive.targetCheckbox.length &&
            archive.targetCheckbox[e.key])
        .map((e) => e.value)
        .fold<double>(0, (a, b) => a + b);

    final wave = archive.waveValue.isNotEmpty ? archive.waveValue[0] : 0;
    String totalGoldStr;
    try {
      totalGoldStr = decreaseNumSize(totalGold, context);
    } catch (_) {
      totalGoldStr = totalGold.toStringAsFixed(0);
    }

    final gpValue = wave > 0
        ? (totalGold /
                (0.5 * (310 + wave * 310) * wave) *
                100)
            .toStringAsFixed(2)
        : '0.00';
    final ratioValue = wave > 0
        ? (totalGold / (wave * wave)).toStringAsFixed(2)
        : '0.00';

    return _ArchiveSummary(
      totalGold: totalGoldStr,
      wave: wave.toString(),
      gp: gpValue,
      ratio: ratioValue,
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
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _archives.length,
              itemBuilder: (context, index) {
                final archive = _archives[index];
                final summary = _computeSummary(archive);
                return _buildArchiveCard(context, archive, summary, theme);
              },
            ),
    );
  }

  Widget _buildArchiveCard(
    BuildContext context,
    CalculatorArchive archive,
    _ArchiveSummary summary,
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
                    _summaryChip(loc.currentWaveValue, summary.wave, theme),
                    _summaryChip(
                        loc.totalGold, summary.totalGold, theme, bold: true),
                    _summaryChip(loc.gp, summary.gp, theme),
                    _summaryChip(loc.ratio, summary.ratio, theme),
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

  void _onLoadArchive(CalculatorArchive archive) {
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
class _ArchiveSummary {
  final String totalGold;
  final String wave;
  final String gp;
  final String ratio;

  const _ArchiveSummary({
    required this.totalGold,
    required this.wave,
    required this.gp,
    required this.ratio,
  });
}
