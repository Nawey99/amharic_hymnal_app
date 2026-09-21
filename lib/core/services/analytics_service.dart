import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// Where a hymn was opened from, as the analytics API names it.
enum HymnOpenSource { catalog, search, favorites }

/// Anonymous usage counts for the admin console's Analytics tab
/// (`POST /analytics/events`). The server counts searches and downloads
/// itself; only the app knows which hymns and categories people open.
///
/// Fire and forget: nothing waits on it, nothing is retried, and a failure
/// is never shown. Nothing identifying the person is sent.
///
/// Debug builds send nothing unless built with
/// `--dart-define=WUDASE_ANALYTICS=true`, so development and tests do not
/// count as use.
class AnalyticsService {
  AnalyticsService({http.Client? client, String? baseUrl, bool? enabled})
      : _client = client,
        _baseUrl = baseUrl,
        _enabled = enabled ?? (!kDebugMode || _enabledInDebug);

  static final AnalyticsService instance = AnalyticsService();

  static const _enabledInDebug = bool.fromEnvironment('WUDASE_ANALYTICS');

  final http.Client? _client;
  final String? _baseUrl;
  final bool _enabled;

  /// The user opened [hymn] in [version]. Only hymns from the API have an
  /// ID the server knows; bundled hymns are not counted.
  /// Callers need not await it; the Future is for tests.
  Future<void> hymnOpened(Hymn hymn, String version, HymnOpenSource source) {
    final code = HymnalVersions.apiCode(version);
    final songId = hymn.id;
    if (songId == null || !songId.startsWith('$code-')) {
      return Future.value();
    }
    return _send(code, {
      'eventType': 'SONG_VIEW',
      'songId': songId,
      'metadata': {'source': source.name},
    });
  }

  /// The user opened the category [slug] in [version].
  Future<void> categoryOpened(String version, String? slug) {
    if (slug == null || slug.isEmpty) return Future.value();
    return _send(HymnalVersions.apiCode(version), {
      'eventType': 'CATEGORY_VIEW',
      'metadata': {'category': slug},
    });
  }

  Future<void> _send(String code, Map<String, Object?> event) {
    if (!_enabled) return Future.value();
    return _post(code, event);
  }

  Future<void> _post(String code, Map<String, Object?> event) async {
    try {
      final uri =
          Uri.parse('${_baseUrl ?? ContentApiConfig.baseUrl}/analytics/events')
              .replace(queryParameters: {'language': 'am', 'version': code});
      final body = jsonEncode(event);
      const headers = {'content-type': 'application/json; charset=utf-8'};
      const timeout = Duration(seconds: 5);
      final client = _client;
      if (client != null) {
        await client.post(uri, headers: headers, body: body).timeout(timeout);
      } else {
        await http.post(uri, headers: headers, body: body).timeout(timeout);
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Analytics event not sent: $error');
    }
  }
}
