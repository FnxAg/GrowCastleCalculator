import 'package:flutter/material.dart';

/// Smooth shared-axis-style page transition for pushed routes.
///
/// The entering page slides in from the right with a subtle fade-in, while the
/// exiting page slides out to the left with a fade-out.  This produces a
/// fluid, modern feel compared to the default platform transition.
///
/// Usage — drop-in replacement for [MaterialPageRoute]:
/// ```dart
/// Navigator.push(context, smoothPageRoute(builder: (_) => MyPage()));
/// ```
PageRouteBuilder<T> smoothPageRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  Duration duration = const Duration(milliseconds: 300),
}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.12, 0.0); // small horizontal shift
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      final t = CurvedAnimation(parent: animation, curve: curve);
      final fadeT = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      );

      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: end).animate(t),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(fadeT),
          child: child,
        ),
      );
    },
  );
}
