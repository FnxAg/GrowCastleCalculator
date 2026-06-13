import 'package:flutter/material.dart';
import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/utils/game_calculations.dart';

/// Displays a dialog with season progress information for all three season types.
///
/// [now] is the current DateTime used to compute progress values.
void showSeasonProgressDialog(BuildContext context, DateTime now) {
  final progress = calculateSeasonProgress(now);
  final loc = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(loc.progress),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressSection(
                context,
                title: loc.seasonProgress,
                progressValue: progress.seasonProgress,
                nextUpdateMs: progress.seasonNextUpdateMs,
                remainingHours: 120,
              ),
              const Text('\n'),
              _buildProgressSection(
                context,
                title: loc.hellModeSeasonProgress,
                progressValue: progress.hellModeProgress,
                nextUpdateMs: progress.hellModeNextUpdateMs,
                remainingHours: 168,
              ),
              const Text('\n'),
              _buildProgressSection(
                context,
                title: loc.seasonalColonyProgress,
                progressValue: progress.seasonalColonyProgress,
                nextUpdateMs: progress.seasonalColonyNextUpdateMs,
                remainingHours: 240,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.confirm),
          ),
        ],
      );
    },
  );
}

Widget _buildProgressSection(
  BuildContext context, {
  required String title,
  required double progressValue,
  required int nextUpdateMs,
  required int remainingHours,
}) {
  final loc = AppLocalizations.of(context)!;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildInfoRow(title, '${(progressValue * 100).toStringAsFixed(2)}%'),
      _buildInfoRow(
        loc.updateTime,
        DateTime.fromMillisecondsSinceEpoch(nextUpdateMs)
            .toLocal()
            .toString()
            .split('.')
            .first,
      ),
      _buildInfoRow(
        loc.timeTillReset,
        '${(remainingHours * (1 - progressValue)).toStringAsFixed(2)}h',
      ),
    ],
  );
}

Widget _buildInfoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, textAlign: TextAlign.left),
      Text(value, textAlign: TextAlign.right),
    ],
  );
}
