import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards PR #19: when the app is swiped out of Recents, or its media
/// notification is dismissed, the audio handler must stop the player.
///
/// The `HymnalAudioHandler` constructor wires a `just_audio` `AudioPlayer`
/// that needs a mocked platform channel to instantiate in tests. Rather
/// than pull in a full platform mock (which would have its own drift
/// risk), this test asserts the two overrides *structurally*: they must
/// call `stop()` before delegating to `super`. If a future edit removes
/// either call, this fails and the change surfaces in review.
void main() {
  final source = File(
    'lib/core/services/hymnal_audio_handler.dart',
  ).readAsStringSync();

  String bodyOf(String override) {
    // Matches: Future<void> <override>() async { … }
    final match = RegExp(
      r'@override\s*\n\s*Future<void>\s+' +
          RegExp.escape(override) +
          r'\s*\(\s*\)\s*async\s*\{([^}]*)\}',
      multiLine: true,
    ).firstMatch(source);
    if (match == null) {
      fail(
        '$override not found in hymnal_audio_handler.dart as an async override',
      );
    }
    return match.group(1)!;
  }

  test('onTaskRemoved calls stop() so the player is not left running when '
      'the app is swiped out of Recents', () {
    final body = bodyOf('onTaskRemoved');
    expect(
      body,
      contains('await stop();'),
      reason: 'PR #19: swiping the app out of Recents must stop playback. '
          'Removing this leaves the audio_service foreground service alive '
          'and keeps the process pinned; testers on the S22 originally hit '
          'that as "app frozen after swipe".',
    );
    expect(
      body,
      contains('await super.onTaskRemoved();'),
      reason: 'audio_service still needs the base handler to run.',
    );
    final stopIndex = body.indexOf('await stop();');
    final superIndex = body.indexOf('await super.onTaskRemoved();');
    expect(
      stopIndex,
      lessThan(superIndex),
      reason: 'stop() must run before super so the base class sees the idle '
          'state, not a still-playing player.',
    );
  });

  test('onNotificationDeleted calls stop() so dismissing the notification '
      'stops playback instead of leaving it playing invisibly', () {
    final body = bodyOf('onNotificationDeleted');
    expect(
      body,
      contains('await stop();'),
      reason: 'PR #19: swiping the media notification away must stop '
          'playback, so a reader who chose to dismiss the notification is '
          'not left listening to a hymn they cannot see.',
    );
    expect(
      body,
      contains('await super.onNotificationDeleted();'),
      reason: 'audio_service still needs the base handler to run.',
    );
    final stopIndex = body.indexOf('await stop();');
    final superIndex = body.indexOf('await super.onNotificationDeleted();');
    expect(stopIndex, lessThan(superIndex));
  });

  test('android:stopWithTask is still true in the manifest', () {
    // The Kotlin side of PR #19 relies on the manifest telling Android to
    // tear down the service with the task. If someone reverts this,
    // onTaskRemoved never fires and the Dart guard above is bypassed.
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      manifest,
      contains('android:stopWithTask="true"'),
      reason: 'Without stopWithTask, Android keeps the audio foreground '
          'service alive when the app is swiped out of Recents, and '
          'onTaskRemoved is never delivered to the handler.',
    );
  });

  test('the completion listener still stops the player when the hymn ends',
      () {
    // Behaviour that pre-dates PR #19 but is load-bearing for "one hymn is
    // open at a time" — if a completed hymn stayed in the notification the
    // notification's UX becomes wrong.
    final constructorBlock = RegExp(
      r'HymnalAudioHandler\(\) \{(.*?)\n  \}',
      dotAll: true,
    ).firstMatch(source);
    expect(constructorBlock, isNotNull);
    expect(
      constructorBlock!.group(1)!,
      contains('ProcessingState.completed'),
      reason: 'The processing-state listener must still react to '
          'completed.',
    );
    expect(
      constructorBlock.group(1)!,
      contains('unawaited(stop())'),
      reason: 'When a hymn completes, the handler must stop() so the '
          'notification lets go — this is the "one hymn at a time" '
          'contract.',
    );
  });
}
