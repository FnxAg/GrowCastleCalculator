import 'package:flutter/material.dart';

/// Converts a string to an int, returning 0 if parsing fails.
int convertStringToInt(String value) {
  return int.tryParse(value) ?? 0;
}

/// Converts a string to a double, returning 0.0 if parsing fails.
double convertStringToDouble(String value) {
  return double.tryParse(value) ?? 0.0;
}

/// Formats a large gold number into a human-readable string with suffixes.
///
/// English suffixes: K, M, B, T, P, E (steps of 1,000)
/// Chinese suffixes: 万, 亿, 万亿, 亿亿, 万亿亿, 亿亿亿 (steps of 10,000)
///
/// When the locale is Chinese, both representations are shown separated by " | ".
String decreaseNumSize(double gold, BuildContext context) {
  const suffixes = ['K', 'M', 'B', 'T', 'P', 'E'];
  const suffixesZhCn = ['万', '亿', '万亿', '亿亿', '万亿亿', '亿亿亿'];

  double value = gold;
  int index = -1;

  while (value >= 1000000 && index < suffixes.length - 1) {
    value /= 1000;
    index++;
  }

  String result;
  if (index == -1) {
    result = gold.toStringAsFixed(0);
  } else {
    result = '${value.toStringAsFixed(0)}${suffixes[index]}';
  }

  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'zh') {
    double zhValue = gold;
    int zhIndex = -1;

    while (zhValue >= 10000 && zhIndex < suffixesZhCn.length - 1) {
      zhValue /= 10000;
      zhIndex++;
    }

    String zhResult;
    if (zhIndex == -1) {
      zhResult = gold.toStringAsFixed(0);
    } else {
      zhResult = '${zhValue.toStringAsFixed(2)}${suffixesZhCn[zhIndex]}';
    }

    result = '$zhResult\n$result';
  }

  return result;
}
