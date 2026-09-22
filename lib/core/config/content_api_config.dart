import 'package:flutter/foundation.dart';

class ContentApiConfig {
  /// The production hymnal API. Override with
  /// `--dart-define=WUDASE_CONTENT_API_URL=<root>`, where the root includes
  /// the version prefix, e.g. `http://localhost:8787/api/v1`.
  static const productionBaseUrl =
      'https://amharichymnalbackend.vercel.app/api/v1';

  static const _configuredBaseUrl = String.fromEnvironment(
    'WUDASE_CONTENT_API_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final value = _configuredBaseUrl.trim();
    if (value.isEmpty) return productionBaseUrl;

    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw StateError('WUDASE_CONTENT_API_URL must be an HTTP(S) URL.');
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError(
          'WUDASE_CONTENT_API_URL must use HTTPS in release builds.');
    }
    return value.replaceFirst(RegExp(r'/$'), '');
  }
}
