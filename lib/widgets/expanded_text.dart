import 'package:flutter/material.dart';

/// A simple row widget that displays a [name] label on the left and a
/// [variable] value on the right, with flexible spacing between them.
class ExpandedText extends StatelessWidget {
  const ExpandedText({
    super.key,
    required this.name,
    required this.variable,
  });

  final String name;
  final dynamic variable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(name),
        const Expanded(child: SizedBox()),
        Text('$variable'),
      ],
    );
  }
}
