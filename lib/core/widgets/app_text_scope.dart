import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/font_size_service.dart';

/// Wraps every screen so text obeys both the phone's text-size setting and
/// the reader's own choice in the app.
///
/// The phone's setting is clamped, because past twice the size the layouts
/// give way. The app's own setting is watched here, in the one place every
/// screen is built inside, so changing it redraws the hymn list, search and
/// the rest, not only the lyrics.
class AppTextScope extends StatelessWidget {
  final Widget child;

  const AppTextScope({super.key, required this.child});

  static const double maxSystemScale = 2;
  static const double minSystemScale = 1;

  @override
  Widget build(BuildContext context) {
    final systemScale = MediaQuery.of(context).textScaler.scale(1);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          systemScale.clamp(minSystemScale, maxSystemScale),
        ),
      ),
      child: FontSizeScope(
        notifier: FontSizeService(),
        child: child,
      ),
    );
  }
}

/// Carries the reader's text size down the tree, so a screen that reads it
/// with [of] is redrawn when it changes rather than waiting to be rebuilt
/// for some other reason.
class FontSizeScope extends InheritedNotifier<FontSizeService> {
  const FontSizeScope({
    super.key,
    required FontSizeService super.notifier,
    required super.child,
  });

  /// The chosen size, or the stored one when no scope is above [context]
  /// (a screen pumped on its own in a test, for instance).
  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FontSizeScope>();
    return scope?.notifier?.fontSize ?? FontSizeService().getFontSize();
  }
}
