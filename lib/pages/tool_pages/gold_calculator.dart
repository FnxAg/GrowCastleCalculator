import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:grow_castle_calculator/l10n/app_localizations.dart';
import 'package:grow_castle_calculator/models/gold_calculator_archive.dart';
import 'package:grow_castle_calculator/models/gold_calculator_data.dart';
import 'package:grow_castle_calculator/pages/calculator_page.dart';
import 'package:grow_castle_calculator/pages/tool_pages/gold_history_archives_page.dart';
import 'package:grow_castle_calculator/providers/gold_calculator_provider.dart';
import 'package:grow_castle_calculator/services/preferences_service.dart';
import 'package:grow_castle_calculator/utils/number_utils.dart';
import 'package:grow_castle_calculator/utils/text_input_formatter.dart';
import 'package:grow_castle_calculator/widgets/collapsible_section.dart';

class GoldCalculator extends StatefulWidget {
  const GoldCalculator({super.key});

  @override
  State<GoldCalculator> createState() => _GoldCalculatorState();
}

class _GoldCalculatorState extends State<GoldCalculator>
    with WidgetsBindingObserver {
  // ── State ──────────────────────────────────────────────────────────────

  List<bool> _isExpanded = List.filled(4, true);
  List<int> _waveValue = [1000000, 40000];
  List<num> _formField = List<num>.filled(9, 0);
  List<bool> _checkboxForm = List.filled(4, true);
  bool _isLoading = true;

  // ── Controllers ────────────────────────────────────────────────────────

  final List<TextEditingController> _waveValueControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<TextEditingController> _formFieldControllers =
      List.generate(9, (_) => TextEditingController());

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _waveValueControllers) {
      c.dispose();
    }
    for (final c in _formFieldControllers) {
      c.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      FocusScope.of(context).unfocus();
      _saveData();
    } else if (state == AppLifecycleState.resumed) {
      _saveData();
    }
  }

  // ── Data persistence ───────────────────────────────────────────────────

  Future<void> _loadData() async {
    final data = await PreferencesService.loadGoldCalculatorData();
    _checkboxForm = _padList(data.checkboxForm, true, 4);
    _formField = _padList(data.formField, 0, 9);
    _isExpanded = _padList(data.isExpanded, true, 4);
    _waveValue = data.waveValue.length >= 2
        ? List<int>.from(data.waveValue)
        : [1000000, 40000];
    _syncControllers();
    setState(() => _isLoading = false);
  }

  static List<T> _padList<T>(List<T> list, T fillValue, int minLength) {
    if (list.length >= minLength) return List<T>.from(list);
    return [...list, for (int i = list.length; i < minLength; i++) fillValue];
  }

  /// Formats a [num] for display, stripping the trailing `.0` for whole numbers.
  String _formatNumDisplay(num value) {
    return value == value.truncateToDouble()
        ? value.truncate().toString()
        : value.toString();
  }

  void _syncControllers() {
    for (int i = 0; i < _formFieldControllers.length; i++) {
      _formFieldControllers[i].text = _formatNumDisplay(_formField[i]);
    }
    _syncWaveControllers();
  }

  void _syncWaveControllers() {
    if (_checkboxForm[0]) {
      _waveValue = List<int>.from(CalculatorPage.waveValue);
      for (int i = 0; i < _waveValueControllers.length; i++) {
        _waveValueControllers[i].text =
            CalculatorPage.waveValue[i].toString();
      }
    } else {
      for (int i = 0; i < _waveValueControllers.length; i++) {
        _waveValueControllers[i].text = _waveValue[i].toString();
      }
    }
  }

  Future<void> _saveData() async {
    await PreferencesService.saveGoldCalculatorData(
      GoldCalculatorData(
        waveValue: _waveValue,
        formField: _formField,
        checkboxForm: _checkboxForm,
        isExpanded: _isExpanded,
      ),
    );
  }

  // ── Archive operations ─────────────────────────────────────────────────

  Future<void> _showSaveArchiveDialog() async {
    final loc = AppLocalizations.of(context)!;
    final defaultName =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final controller = TextEditingController(text: defaultName);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.saveArchive),
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
            child: Text(loc.save),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null || name.trim().isEmpty) return;

    final archive = GoldCalculatorArchive(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      savedAt: DateTime.now(),
      waveValue: _waveValue.toList(),
      formField: _formField.toList(),
      checkboxForm: _checkboxForm.toList(),
      isExpanded: _isExpanded.toList(),
    );

    final archives = await PreferencesService.loadGoldArchives();
    archives.insert(0, archive);
    await PreferencesService.saveGoldArchives(archives);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.saveArchive}: ${archive.name}')),
      );
    }
  }

  Future<void> _openHistoryArchives() async {
    final archive = await Navigator.push<GoldCalculatorArchive>(
      context,
      MaterialPageRoute(
        builder: (_) => const GoldHistoryArchivesPage(),
      ),
    );
    if (archive != null) {
      _applyArchive(archive);
    }
  }

  void _applyArchive(GoldCalculatorArchive archive) {
    _waveValue = archive.waveValue.toList();
    _formField = _padList(archive.formField.toList(), 0, 9);
    _checkboxForm = _padList(archive.checkboxForm.toList(), true, 4);
    _isExpanded = _padList(archive.isExpanded.toList(), true, 4);
    _syncControllers();
    setState(() {});
    _saveData();
  }

  // ── Build helpers ──────────────────────────────────────────────────────

  Widget _dataRow(
    BuildContext context, {
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _labelValuePair(leftLabel, leftValue, theme),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _labelValuePair(rightLabel, rightValue, theme),
          ),
        ],
      ),
    );
  }

  Widget _labelValuePair(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Parse fields
    final f0 = convertStringToDouble(_formFieldControllers[0].text);
    final f1 = convertStringToDouble(_formFieldControllers[1].text);
    final f2 = convertStringToDouble(_formFieldControllers[2].text);
    final f3 = convertStringToInt(_formFieldControllers[3].text);
    final f4 = convertStringToInt(_formFieldControllers[4].text);
    final f5 = convertStringToInt(_formFieldControllers[5].text);
    final f6 = convertStringToDouble(_formFieldControllers[6].text);
    final f7 = convertStringToDouble(_formFieldControllers[7].text);
    final f8 = convertStringToDouble(_formFieldControllers[8].text);
    final w0 = convertStringToInt(_waveValueControllers[0].text);

    // Computed values
    final wph = f2 == 0 ? 0 : (3600 / f2 * f1);
    final goldPerCart = (f3 * 5400 + 1374406) / 1.2 * (1.2 + 0.01 * f5);
    final secondsPerCart =
        60 / ((f4 * 0.005 + 1.1) + (_checkboxForm[1] ? 0.15 : 0));
    final icRatio = f0 == 0 ? 0 : (f3 * 1000 / w0);
    final cartsPerHour =
        f2 == 0 ? 0.0 : (((f2 - 1.5) * f0 + 1.5) * 3600 / f2 / secondsPerCart);
    final adGold = w0 * 2160;
    final gabCost = 456 * w0 - 29264;
    final gabBenefitGoldPerWave = gabCost * f7 * 0.01;
    final gabBenefitGoldPerHour =
        f2 == 0 ? 0.0 : 3600 / f2 * gabBenefitGoldPerWave;
    final tabGoldPerWave = gabCost * (1 + f7 * 0.01);
    final tabGoldPerHour = f2 == 0 ? 0.0 : tabGoldPerWave * (3600 / f2);
    final tabGoldPerDay = tabGoldPerHour * f8;
    final gabBenefitGoldPerDay = gabBenefitGoldPerHour * f6;
    final goldenTreeGoldPerHour =
        f2 == 0 ? 0.0 : 48 / 456 * gabCost * 3600 / f2 / 2;
    final goldenTreeGoldPerDay =
        _checkboxForm[2] ? ((f6 + f8) * goldenTreeGoldPerHour) : 0.0;
    final seasonalColonyGoldPerHour = 16 * adGold / 24;
    final seasonalColonyGoldPerDay =
        _checkboxForm[3] ? seasonalColonyGoldPerHour * 24 : 0.0;
    final colonyGoldPerDay = goldPerCart * cartsPerHour * 24;

    final totalGoldPerDay = colonyGoldPerDay +
        gabBenefitGoldPerDay +
        tabGoldPerDay +
        goldenTreeGoldPerDay +
        seasonalColonyGoldPerDay;

    // Notify the global provider so tool_page can display the value.
    // Skip while loading — controllers are empty and would push 0.
    if (!_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<GoldCalculatorProvider>(context, listen: false)
            .setDailyIncome(totalGoldPerDay);
      });
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async => _saveData(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.goldCalculator),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'save':
                    _showSaveArchiveDialog();
                  case 'history_archives':
                    _openHistoryArchives();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'history_archives',
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(loc.historyArchives),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'save',
                  child: ListTile(
                    leading: const Icon(Icons.save),
                    title: Text(loc.save),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // ── Wave input section ───────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      Text(
                                        loc.inherit,
                                        style: theme.textTheme.labelSmall,
                                      ),
                                      Checkbox(
                                        value: _checkboxForm[0],
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        onChanged: (value) {
                                          setState(() {
                                            _checkboxForm[0] = value!;
                                            _syncWaveControllers();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: TextField(
                                    controller: _waveValueControllers[0],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    readOnly: _checkboxForm[0],
                                    decoration: InputDecoration(
                                      labelText: loc.currentWave,
                                      hintText: loc.enterCurrentWave,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) => setState(() {
                                      _waveValue[0] = convertStringToInt(v);
                                    }),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: TextField(
                                    controller: _waveValueControllers[1],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    readOnly: _checkboxForm[0],
                                    decoration: InputDecoration(
                                      labelText: loc.seasonalWave,
                                      hintText: loc.enterSeasonalWave,
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) => setState(() {
                                      _waveValue[1] = convertStringToInt(v);
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Top-line summary ─────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                        child: _dataRow(
                          context,
                          leftLabel: loc.gabCost,
                          leftValue: decreaseNumSize(gabCost.toDouble(), context),
                          rightLabel: loc.goldDay,
                          rightValue: decreaseNumSize(totalGoldPerDay, context),
                        ),
                      ),
                    ),

                    // ── Game speed / Wave config ─────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withAlpha(80),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              spacing: 6,
                              children: [
                                Row(
                                  spacing: 8,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _formFieldControllers[0],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FormatterWithMinusAndDot(),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: loc.gameSpeed,
                                          hintText: loc.enterGameSpeed,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        onChanged: (v) => setState(() {
                                          _formField[0] =
                                              convertStringToDouble(v);
                                        }),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _formFieldControllers[1],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FormatterWithMinusAndDot(),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: loc.jumpAndWave,
                                          hintText: loc.enterWave,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        onChanged: (v) => setState(() {
                                          _formField[1] =
                                              convertStringToDouble(v);
                                        }),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _formFieldControllers[2],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FormatterWithMinusAndDot(),
                                        ],
                                        decoration: InputDecoration(
                                          labelText: loc.waveTime,
                                          hintText: loc.enterWaveTime,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        onChanged: (v) => setState(() {
                                          _formField[2] =
                                              convertStringToDouble(v);
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${loc.wph} ${wph.toStringAsFixed(2)}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Infinite Colony ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CollapsibleSection(
                              title: loc.infiniteColony,
                              isExpanded: _isExpanded[0],
                              onToggle: () => setState(
                                  () => _isExpanded[0] = !_isExpanded[0]),
                              showIcon: true,
                              child: Column(
                                spacing: 6,
                                children: [
                                  Row(
                                    spacing: 8,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _formFieldControllers[3],
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            labelText: loc.icLevel,
                                            hintText: loc.enterLV,
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (v) => setState(() {
                                            _formField[3] =
                                                convertStringToInt(v);
                                          }),
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            loc.ironWheel,
                                            style: theme.textTheme.labelSmall,
                                          ),
                                          Checkbox(
                                            value: _checkboxForm[1],
                                            visualDensity:
                                                VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            onChanged: (v) => setState(() {
                                              _checkboxForm[1] = v ?? false;
                                            }),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    spacing: 8,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _formFieldControllers[4],
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            labelText: loc.extraColonyCD,
                                            hintText: loc.enterLV,
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (v) => setState(() {
                                            _formField[4] =
                                                convertStringToInt(v);
                                          }),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _formFieldControllers[5],
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            labelText: loc.extraColonyGold,
                                            hintText: loc.enterLV,
                                            border:
                                                const OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                          onChanged: (v) => setState(() {
                                            _formField[5] =
                                                convertStringToInt(v);
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _dataRow(
                              context,
                              leftLabel: loc.secCart,
                              leftValue:
                                  '${secondsPerCart.toStringAsFixed(2)}s',
                              rightLabel: loc.goldCart,
                              rightValue:
                                  decreaseNumSize(goldPerCart, context),
                            ),
                            _dataRow(
                              context,
                              leftLabel: loc.cartHour,
                              leftValue:
                                  cartsPerHour.toStringAsFixed(2),
                              rightLabel: loc.icRatio,
                              rightValue:
                                  icRatio.toStringAsFixed(2),
                            ),
                            _dataRow(
                              context,
                              leftLabel: loc.goldHour,
                              leftValue: decreaseNumSize(
                                  goldPerCart * cartsPerHour, context),
                              rightLabel: loc.goldDay,
                              rightValue: decreaseNumSize(
                                  colonyGoldPerDay, context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Gold Auto Battle ─────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CollapsibleSection(
                              title: loc.goldAutoBattle,
                              isExpanded: _isExpanded[1],
                              onToggle: () => setState(
                                  () => _isExpanded[1] = !_isExpanded[1]),
                              showIcon: true,
                              child: Row(
                                spacing: 8,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          _formFieldControllers[6],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: loc.gabHourDay,
                                        hintText: loc.enterHour,
                                        border:
                                            const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (v) => setState(() {
                                        _formField[6] =
                                            convertStringToDouble(v);
                                      }),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller:
                                          _formFieldControllers[7],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: loc.gabProfit,
                                        hintText: loc.enterProfit,
                                        border:
                                            const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (v) => setState(() {
                                        _formField[7] =
                                            convertStringToDouble(v);
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _dataRow(
                              context,
                              leftLabel: loc.goldWave,
                              leftValue: decreaseNumSize(
                                  gabBenefitGoldPerWave, context),
                              rightLabel: loc.goldDay,
                              rightValue: decreaseNumSize(
                                  gabBenefitGoldPerDay, context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Time Auto Battle ─────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CollapsibleSection(
                              title: loc.timeAutoBattle,
                              isExpanded: _isExpanded[2],
                              onToggle: () => setState(
                                  () => _isExpanded[2] = !_isExpanded[2]),
                              showIcon: true,
                              child: TextField(
                                controller: _formFieldControllers[8],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: loc.tabHourDay,
                                  hintText: loc.enterHour,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (v) => setState(() {
                                  _formField[8] =
                                      convertStringToDouble(v);
                                }),
                              ),
                            ),
                            _dataRow(
                              context,
                              leftLabel: loc.goldWave,
                              leftValue: decreaseNumSize(
                                  tabGoldPerWave, context),
                              rightLabel: loc.goldDay,
                              rightValue: decreaseNumSize(
                                  tabGoldPerDay, context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Golden Tree ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CollapsibleSection(
                              title: loc.goldenTree,
                              isExpanded: false,
                              onToggle: () => setState(() =>
                                  _checkboxForm[2] = !_checkboxForm[2]),
                              showIcon: false,
                              trailing: Checkbox(
                                value: _checkboxForm[2],
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) => setState(() {
                                  _checkboxForm[2] = v ?? false;
                                }),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                            _dataRow(
                              context,
                              leftLabel: loc.goldHour,
                              leftValue: decreaseNumSize(
                                  goldenTreeGoldPerHour, context),
                              rightLabel: loc.goldDay,
                              rightValue: decreaseNumSize(
                                  goldenTreeGoldPerDay, context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Seasonal Colony ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CollapsibleSection(
                              title: loc.seasonalColony,
                              isExpanded: false,
                              onToggle: () => setState(() =>
                                  _checkboxForm[3] = !_checkboxForm[3]),
                              showIcon: false,
                              trailing: Checkbox(
                                value: _checkboxForm[3],
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (v) => setState(() {
                                  _checkboxForm[3] = v ?? false;
                                }),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                            _dataRow(
                              context,
                              leftLabel: loc.goldHour,
                              leftValue: decreaseNumSize(
                                  seasonalColonyGoldPerHour.toDouble(),
                                  context),
                              rightLabel: loc.goldDay,
                              rightValue: decreaseNumSize(
                                  seasonalColonyGoldPerDay.toDouble(),
                                  context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
        ),
      ),
    );
  }
}
