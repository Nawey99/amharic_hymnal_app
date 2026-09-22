// Native end-to-end tests: flows that cross into Android itself (system back,
// notifications, the share sheet, airplane mode). Run with Patrol on a real
// device or Firebase Test Lab, against the LIVE hymnal API (read-only; debug
// builds send no analytics):
//
//   patrol test --target integration_test/native/native_flows_test.dart
//
// See docs/test-plan.md → "Where each test runs".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/main.dart' as app;

/// Starts the app from a fresh install (Patrol clears app data per test) and
/// passes onboarding.
Future<void> _launch(PatrolIntegrationTester $) async {
  app.main();
  // A fresh install takes a few seconds to start; wait for onboarding or the
  // main screen rather than a fixed delay.
  final ready = find.byWidgetPredicate(
    (widget) =>
        widget is Text && (widget.data == 'ዝለል' || widget.data == 'ቁጥር'),
  );
  for (var i = 0; i < 300 && ready.evaluate().isEmpty; i++) {
    await $.pump(const Duration(milliseconds: 100));
  }
  expect(ready, findsWidgets, reason: 'the app did not start within 30 s');
  await $.pumpAndSettle();
  if ($('ዝለል').exists) {
    await $('ዝለል').tap();
    await $.pumpAndSettle();
  }
}

Future<void> _openNumber(PatrolIntegrationTester $, int number) async {
  await $('ቁጥር').last.tap();
  await $(TextField).first.enterText('$number');
  await $('ክፈት').tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 20));
}

/// Toggles airplane mode from Quick Settings. Patrol's own helper looks only
/// for "Airplane mode"; Samsung phones set to UK English call it "Flight mode".
Future<void> _toggleAirplaneMode(PatrolIntegrationTester $) async {
  await $.native.openQuickSettings();
  // Stock Android shows the label as text; Samsung puts it in the tile's
  // accessibility description.
  final selectors = [
    for (final label in ['Airplane mode', 'Flight mode']) ...[
      Selector(text: label),
      Selector(contentDescription: label),
    ],
  ];
  for (final selector in selectors) {
    try {
      await $.native.tap(selector);
      // Not system back: a second back would close the app at its root.
      await $.native.closeNotifications();
      await $.pumpAndSettle();
      return;
    } on PatrolActionException {
      // Try the next selector.
    }
  }
  fail('No airplane / flight mode tile in Quick Settings');
}

void main() {
  patrolTest('system back closes a hymn (predictive back on Android 14+)',
      ($) async {
    await _launch($);
    await _openNumber($, 1);
    expect($(HymnDetailPage), findsOneWidget);

    await $.native.pressBack();
    await $.pumpAndSettle();

    expect($(HymnDetailPage), findsNothing);
  });

  patrolTest('sharing a hymn opens the Android share sheet', ($) async {
    await _launch($);
    await _openNumber($, 1);

    await $(IconButton).which<IconButton>((b) => b.tooltip == 'አጋራ').tap();
    await Future<void>.delayed(const Duration(seconds: 2));
    // The share sheet is native; leaving it must return to the hymn.
    await $.native.pressBack();
    await $.pumpAndSettle();

    expect($(HymnDetailPage), findsOneWidget);
  });

  patrolTest('with airplane mode on, a book opened before still works',
      ($) async {
    await _launch($);
    await _openNumber($, 2);
    expect($(HymnDetailPage), findsOneWidget);
    await $(BackButton).tap();
    await $.pumpAndSettle();

    await _toggleAirplaneMode($);
    try {
      await _openNumber($, 3);
      expect($(HymnDetailPage), findsOneWidget);
    } finally {
      await _toggleAirplaneMode($);
    }
  });

  patrolTest('audio keeps playing in the background with a media notification',
      ($) async {
    await _launch($);
    await _openNumber($, 1);

    await $(Icons.play_arrow).tap();
    if ($('አውርድ').exists) {
      await $('አውርድ').tap();
    }
    await $.pumpAndSettle(timeout: const Duration(seconds: 60));
    expect($(Icons.pause), findsWidgets);

    await $.native.pressHome();
    await $.native.openNotifications();
    final notifications = await $.native.getNotifications();
    expect(
      notifications.any((n) => n.title.isNotEmpty),
      isTrue,
      reason: 'the playback notification should be shown',
    );
    await $.native.closeNotifications();
    await $.native.openApp();
    await $.pumpAndSettle();

    // Stop playback so no foreground service outlives the test.
    if ($(Icons.pause).exists) {
      await $(Icons.pause).first.tap();
      await $.pumpAndSettle();
    }
  });
}
