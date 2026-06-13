import 'package:flutter/services.dart';

/// A [TextInputFormatter] that allows only valid numeric input:
/// - Digits 0-9
/// - One minus sign at the very beginning
/// - One decimal point after at least one character
class FormatterWithMinusAndDot extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String validChars = newValue.text.replaceAll(RegExp(r'[^0-9.-]'), '');

    String processedText = '';
    bool hasMinus = false;
    bool hasDot = false;

    for (int i = 0; i < validChars.length; i++) {
      final char = validChars[i];
      if (char == '-') {
        if (i == 0 && !hasMinus) {
          processedText += char;
          hasMinus = true;
        }
      } else if (char == '.') {
        if (!hasDot && processedText.isNotEmpty) {
          processedText += char;
          hasDot = true;
        }
      } else {
        processedText += char;
      }
    }

    return TextEditingValue(
      text: processedText,
      selection: TextSelection.collapsed(offset: processedText.length),
    );
  }
}
