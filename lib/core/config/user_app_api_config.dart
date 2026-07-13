import 'package:flutter/foundation.dart';

class UserAppApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment(
    'WUDASE_USER_APP_API_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return _configuredBaseUrl.trim();
    }

    if (kIsWeb) {
      return 'http://localhost:8790';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8790',
      _ => 'http://localhost:8790',
    };
  }
}
