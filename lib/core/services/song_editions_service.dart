import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_client.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';

/// The same hymn as printed in another edition.
class OtherEdition {
  final String songId;
  final int number;
  final String versionCode;

  const OtherEdition({
    required this.songId,
    required this.number,
    required this.versionCode,
  });
}

/// Reads a song's numbers in other editions (`otherEditions`), which the API
/// includes only on song detail. Results are kept for the session.
class SongEditionsService {
  SongEditionsService({http.Client? client, String? baseUrl})
      : _api = HymnalApiClient(client: client),
        _baseUrl = baseUrl ?? ContentApiConfig.baseUrl;

  static final SongEditionsService instance = SongEditionsService();

  static final RegExp _songNumberSuffix = RegExp(r'-\d+$');

  final HymnalApiClient _api;
  final String _baseUrl;
  final Map<String, Future<List<OtherEdition>>> _cache = {};

  /// The edition code in an API song ID, e.g. `am-sda-1975` for
  /// `am-sda-1975-0130`, or null if [songId] is not in that form.
  static String? versionCodeOf(String songId) {
    final code = songId.replaceFirst(_songNumberSuffix, '');
    return code == songId || code.isEmpty ? null : code;
  }

  Future<List<OtherEdition>> otherEditions(String songId) {
    final versionCode = versionCodeOf(songId);
    if (versionCode == null) return Future.value(const []);

    return _cache[songId] ??= _fetch(songId, versionCode).catchError(
      (Object error) {
        // Let a later call try again once the connection is back.
        _cache.remove(songId);
        throw error;
      },
    );
  }

  Future<List<OtherEdition>> _fetch(String songId, String versionCode) async {
    final uri = Uri.parse('$_baseUrl/songs/${Uri.encodeComponent(songId)}')
        .replace(queryParameters: {'language': 'am', 'version': versionCode});
    final response = await _api.get(uri, timeout: const Duration(seconds: 8));
    final data = decodeHymnalApiData(response);
    final editions = data is Map ? data['otherEditions'] : null;
    if (editions is! List) return const [];

    return [
      for (final edition in editions.whereType<Map<String, dynamic>>())
        if (edition['songId'] is String &&
            edition['number'] is num &&
            edition['versionCode'] is String)
          OtherEdition(
            songId: edition['songId'] as String,
            number: (edition['number'] as num).toInt(),
            versionCode: edition['versionCode'] as String,
          ),
    ];
  }
}
