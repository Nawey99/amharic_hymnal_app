import 'package:flutter/foundation.dart';

class ContentApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment(
    'WUDASE_CONTENT_API_URL',
    defaultValue: '',
  );
  static const enableLocalContentDatabase = bool.fromEnvironment(
    'WUDASE_ENABLE_LOCAL_CONTENT_DB',
    defaultValue: false,
  );

  static String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return _configuredBaseUrl.trim();
    }

    if (kIsWeb) {
      return 'http://localhost:8787';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8787',
      _ => 'http://localhost:8787',
    };
  }
}
