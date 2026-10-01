import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/widgets/error_widget.dart';

/// AppErrorWidget is the last surface the reader sees when the app fails
/// to start (see main.dart → `_AppInitializerState`). Nothing else in
/// the app can rescue an init failure, so the widget must:
///   - show the user-supplied message,
///   - offer a retry button only when a callback is provided, and
///   - invoke the callback exactly once when tapped.
///
/// Before this file, `error_widget.dart` had 0 % test coverage.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      );

  testWidgets('shows the message that was passed in', (tester) async {
    await tester.pumpWidget(wrap(
      const AppErrorWidget(message: 'Storage is unavailable'),
    ));

    expect(find.text('Storage is unavailable'), findsOneWidget);
    // The fixed heading is still shown alongside the specific message.
    expect(find.text('ይቅርታ! የሆነ ችግር ተከስቷል'), findsOneWidget);
  });

  testWidgets('hides the retry button when no callback is given',
      (tester) async {
    await tester.pumpWidget(wrap(
      const AppErrorWidget(message: 'anything'),
    ));

    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text('እንደገና ይሞክሩ'), findsNothing);
  });

  testWidgets('shows the retry button when a callback is given and calls it '
      'exactly once when tapped', (tester) async {
    var calls = 0;
    await tester.pumpWidget(wrap(
      AppErrorWidget(
        message: 'anything',
        onRetry: () => calls++,
      ),
    ));

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('እንደገና ይሞክሩ'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(calls, 1);
  });
}
