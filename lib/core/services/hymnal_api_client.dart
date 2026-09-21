import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';

/// GET requests to the hymnal API with the two courtesies its contract asks
/// for: conditional requests on metadata routes (`If-None-Match`, answered
/// with `304`), and backing off after `429` or `503` until the server says to
/// try again rather than retrying at once.
class HymnalApiClient {
  HymnalApiClient({http.Client? client, DateTime Function()? clock})
      : _client = client ?? http.Client(),
        _clock = clock ?? DateTime.now;

  /// Longest pause honoured from a server hint, so a bad header cannot lock
  /// the app out for long.
  static const maxBackoff = Duration(minutes: 5);

  final http.Client _client;
  final DateTime Function() _clock;
  final Map<Uri, http.Response> _byEtag = {};
  DateTime? _blockedUntil;

  /// Fetches [uri]. With [conditional], a stored ETag is sent and a `304`
  /// returns the stored response, so callers always see a full body.
  Future<http.Response> get(
    Uri uri, {
    required Duration timeout,
    bool conditional = false,
  }) async {
    final blockedUntil = _blockedUntil;
    if (blockedUntil != null && _clock().isBefore(blockedUntil)) {
      throw const HymnalApiException(
        429,
        'RATE_LIMIT_EXCEEDED',
        'Waiting for the rate limit to reset.',
      );
    }

    final stored = conditional ? _byEtag[uri] : null;
    final etag = stored?.headers['etag'];
    final response = await _client
        .get(
          uri,
          headers: etag == null ? null : {'If-None-Match': etag},
        )
        .timeout(timeout);

    if (response.statusCode == 304 && stored != null) return stored;

    if (response.statusCode == 429 || response.statusCode == 503) {
      final wait = retryDelay(response);
      if (wait != null) _blockedUntil = _clock().add(wait);
    } else if (conditional &&
        response.statusCode == 200 &&
        response.headers['etag'] != null) {
      _byEtag[uri] = response;
    }
    return response;
  }

  /// How long the server asks us to wait: `t=` from a draft-8 `RateLimit`
  /// header, else `Retry-After` in seconds; capped at [maxBackoff].
  static Duration? retryDelay(http.Response response) {
    final rateLimit = response.headers['ratelimit'];
    final match =
        rateLimit == null ? null : RegExp(r'\bt=(\d+)').firstMatch(rateLimit);
    final seconds = int.tryParse(
      match?.group(1) ?? response.headers['retry-after'] ?? '',
    );
    if (seconds == null) return null;
    final wait = Duration(seconds: seconds);
    return wait > maxBackoff ? maxBackoff : wait;
  }
}
