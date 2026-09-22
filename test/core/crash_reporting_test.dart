import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:amharic_hymnal_app/core/services/crash_reporting.dart';

void main() {
  test('is off unless a build supplies a DSN', () {
    // Tests are built without WUDASE_SENTRY_DSN, exactly like store builds.
    expect(CrashReporting.isEnabled, isFalse);
  });

  test('runs the app directly when off', () async {
    var ran = false;
    await CrashReporting.run(() => ran = true);
    expect(ran, isTrue);
  });

  test('removes anything identifying before an event is sent', () {
    final event = SentryEvent(
      user: SentryUser(
          id: 'u1', email: 'someone@example.com', ipAddress: '1.2.3.4'),
      request: SentryRequest(url: 'https://api.example.test/reports'),
      serverName: 'phone-name',
    );

    final scrubbed = CrashReporting.scrub(event, Hint())!;

    expect(scrubbed.user, isNull);
    expect(scrubbed.request, isNull);
    expect(scrubbed.serverName, isNull);
  });
}
