import 'dart:convert';

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

class HymnRemoteDataSource {
  HymnRemoteDataSource({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ContentApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<HymnModel>> getHymns(String languageCode, String version) async {
    final uri = Uri.parse('$_baseUrl/api/hymns').replace(
      queryParameters: {
        'language': languageCode,
        'version': version,
      },
    );

    if (kDebugMode) {
      debugPrint('🌐 Loading hymns from content API: $uri');
    }

    final response = await _client.get(uri).timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        throw const FormatException('Content API request timed out');
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Content API returned ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is! List) {
      throw const FormatException('Content API response missing data list');
    }

    final hymns = data
        .whereType<Map<String, dynamic>>()
        .map(HymnModel.fromJson)
        .toList(growable: false);

    if (kDebugMode) {
      debugPrint('✅ Loaded ${hymns.length} hymns from content API');
    }

    return hymns;
  }
}
