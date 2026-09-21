import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_client.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';

/// Asks the hymnal API whether this build is too old for the published
/// content (`release.minimumAppVersion` on `/manifest`).
class AppUpdateService {
  AppUpdateService({
    http.Client? client,
    String? baseUrl,
    Future<String> Function()? currentVersion,
  })  : _api = HymnalApiClient(client: client),
        _baseUrl = baseUrl ?? ContentApiConfig.baseUrl,
        _currentVersion = currentVersion ?? _installedVersion;

  final HymnalApiClient _api;
  final String _baseUrl;
  final Future<String> Function() _currentVersion;

  static Future<String> _installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  /// The minimum version the content requires, when this build is older than
  /// it; otherwise null. A missing release or minimum means no requirement.
  Future<String?> requiredVersion(String versionCode) async {
    final uri = Uri.parse('$_baseUrl/manifest').replace(
      queryParameters: {'language': 'am', 'version': versionCode},
    );
    final response = await _api.get(
      uri,
      timeout: const Duration(seconds: 8),
      conditional: true,
    );
    final data = decodeHymnalApiData(response);
    final release = data is Map ? data['release'] : null;
    final minimum = release is Map ? release['minimumAppVersion'] : null;
    if (minimum is! String || minimum.trim().isEmpty) return null;

    final current = await _currentVersion();
    return compareVersions(current, minimum) < 0 ? minimum.trim() : null;
  }

  /// Compares dotted numeric versions (`1.4.0`, `1.10`), ignoring build and
  /// pre-release suffixes. Negative when [a] is older than [b].
  static int compareVersions(String a, String b) {
    List<int> parts(String version) => version
        .trim()
        .split(RegExp(r'[+-]'))
        .first
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    final left = parts(a);
    final right = parts(b);
    for (var i = 0; i < left.length || i < right.length; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }
}
