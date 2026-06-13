import 'package:flutter/material.dart';

/// A reusable expandable/collapsible section with an animated chevron.
///
/// Tapping the header toggles visibility of [child]. An optional [trailing]
/// widget (e.g., a Checkbox) can be placed between the title and the chevron.
class CollapsibleSection extends StatelessWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
    this.trailing,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trailing != null) trailing!,
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          height: isExpanded ? null : 0,
          child: isExpanded ? child : null,
        ),
      ],
    );
  }
}
