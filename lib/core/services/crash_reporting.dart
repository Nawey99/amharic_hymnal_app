import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash reporting for beta builds.
///
/// Off unless the build supplies a Sentry DSN:
///
/// ```
/// flutter build appbundle --release \
///   --dart-define=WUDASE_SENTRY_DSN=https://<key>@<org>.ingest.sentry.io/<id> \
///   --dart-define=WUDASE_SENTRY_ENVIRONMENT=beta
/// ```
///
/// Store builds without the DSN send nothing. Reports carry the error, stack
/// trace, app version and device model only: no user identity, IP-derived
/// data, screenshots or view hierarchy (sheet music is protected content).
class CrashReporting {
  const CrashReporting._();

  static const _dsn = String.fromEnvironment('WUDASE_SENTRY_DSN');
  static const _environment = String.fromEnvironment(
    'WUDASE_SENTRY_ENVIRONMENT',
    defaultValue: 'beta',
  );

  static bool get isEnabled => _dsn.isNotEmpty;

  /// Runs [appRunner], inside Sentry's error capture when enabled. Sentry
  /// installs the Flutter and platform error handlers itself.
  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (!isEnabled) {
      await appRunner();
      return;
    }
    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = _environment;
        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        options.attachViewHierarchy = false;
        options.beforeSend = scrub;
      },
      appRunner: appRunner,
    );
  }

  /// Reports an error that was caught and handled, so it is still seen.
  static Future<void> recordError(Object error, StackTrace stackTrace) async {
    if (kDebugMode) debugPrint('Recorded error: $error');
    if (!isEnabled) return;
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Drops anything that could identify the person before an event leaves
  /// the device.
  static SentryEvent? scrub(SentryEvent event, Hint hint) {
    event.user = null;
    event.request = null;
    event.serverName = null;
    return event;
  }
}
