import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_client.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';

/// A hymn in another edition: either the same hymn (`otherEditions`) or one
/// an admin marked similar (`similarEditions`).
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

/// A song's links to other editions, from song detail.
class SongEditionLinks {
  /// The same hymn as printed in other editions. It shares recordings and
  /// may lend its sheet music.
  final List<OtherEdition> same;

  /// Related but different hymns (another translation, other verses, a
  /// different tune). Shown for reference only: nothing is shared.
  final List<OtherEdition> similar;

  const SongEditionLinks({this.same = const [], this.similar = const []});
}

/// Reads a song's `otherEditions` and `similarEditions`, which the API
/// includes only on song detail. One request serves both, kept for the
/// session.
class SongEditionsService {
  SongEditionsService({http.Client? client, String? baseUrl})
      : _api = HymnalApiClient(client: client),
        _baseUrl = baseUrl ?? ContentApiConfig.baseUrl;

  static final SongEditionsService instance = SongEditionsService();

  static final RegExp _songNumberSuffix = RegExp(r'-\d+$');

  final HymnalApiClient _api;
  final String _baseUrl;
  final Map<String, Future<SongEditionLinks>> _cache = {};

  /// The edition code in an API song ID, e.g. `am-sda-1975` for
  /// `am-sda-1975-0130`, or null if [songId] is not in that form.
  static String? versionCodeOf(String songId) {
    final code = songId.replaceFirst(_songNumberSuffix, '');
    return code == songId || code.isEmpty ? null : code;
  }

  /// The same hymn in other editions.
  Future<List<OtherEdition>> otherEditions(String songId) async =>
      (await links(songId)).same;

  /// Hymns an admin marked similar to this one.
  Future<List<OtherEdition>> similarEditions(String songId) async =>
      (await links(songId)).similar;

  Future<SongEditionLinks> links(String songId) {
    final versionCode = versionCodeOf(songId);
    if (versionCode == null) return Future.value(const SongEditionLinks());

    return _cache[songId] ??= _fetch(songId, versionCode).catchError(
      (Object error) {
        // Let a later call try again once the connection is back.
        _cache.remove(songId);
        throw error;
      },
    );
  }

  Future<SongEditionLinks> _fetch(String songId, String versionCode) async {
    final uri = Uri.parse('$_baseUrl/songs/${Uri.encodeComponent(songId)}')
        .replace(queryParameters: {'language': 'am', 'version': versionCode});
    final response = await _api.get(uri, timeout: const Duration(seconds: 8));
    final data = decodeHymnalApiData(response);
    if (data is! Map) return const SongEditionLinks();
    return SongEditionLinks(
      same: _editions(data['otherEditions']),
      similar: _editions(data['similarEditions']),
    );
  }

  /// Missing or malformed lists read as empty.
  static List<OtherEdition> _editions(Object? value) => [
        if (value is List)
          for (final edition in value.whereType<Map<String, dynamic>>())
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
