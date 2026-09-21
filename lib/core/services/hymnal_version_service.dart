import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_client.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';

class HymnalVersionService extends ChangeNotifier {
  HymnalVersionService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _api = HymnalApiClient(client: client),
        _baseUrl = baseUrl ?? ContentApiConfig.baseUrl;

  // The only language the hymnal API serves today.
  static const _languageCode = 'am';

  final http.Client _client;
  final HymnalApiClient _api;
  final bool _ownsClient;
  final String _baseUrl;

  List<HymnalVersion> _versions = List.unmodifiable(HymnalVersions.all);
  Future<List<HymnalVersion>>? _activeRefresh;
  Object? _lastError;
  bool _hasRemoteCatalog = false;

  List<HymnalVersion> get versions => _versions;
  Object? get lastError => _lastError;
  bool get hasRemoteCatalog => _hasRemoteCatalog;

  Future<List<HymnalVersion>> refresh() {
    final activeRefresh = _activeRefresh;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _loadVersions();
    _activeRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_activeRefresh, refresh)) _activeRefresh = null;
    });
  }

  Future<List<HymnalVersion>> _loadVersions() async {
    try {
      final uri = Uri.parse('$_baseUrl/hymn-versions')
          .replace(queryParameters: {'language': _languageCode});
      final response = await _api.get(
        uri,
        timeout: const Duration(seconds: 10),
        conditional: true,
      );
      final data = decodeHymnalApiData(response);
      if (data is! List) {
        throw const FormatException('Version catalog is missing its data list');
      }

      final parsed = <HymnalVersion>[];
      final seen = <String>{};
      for (final value in data.whereType<Map<String, dynamic>>()) {
        final version = _fromApi(value);
        if (version != null && seen.add(version.id)) parsed.add(version);
      }
      // Known editions keep the app's order; new ones follow in API order.
      final order = HymnalVersions.all.map((item) => item.id).toList();
      final known = parsed.where((item) => order.contains(item.id)).toList()
        ..sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
      parsed
        ..removeWhere((item) => order.contains(item.id))
        ..insertAll(0, known);
      if (parsed.isEmpty) {
        throw const FormatException('Version catalog is empty');
      }

      final changed = !listEquals(_versions, parsed);
      _versions = List.unmodifiable(parsed);
      _lastError = null;
      _hasRemoteCatalog = true;
      if (changed) notifyListeners();
    } catch (error) {
      _lastError = error;
      if (kDebugMode) {
        debugPrint('Content version catalog unavailable: $error');
      }
    }
    return _versions;
  }

  HymnalVersion? _fromApi(Map<String, dynamic> json) {
    final code = json['code'];
    if (code is! String || code.trim().isEmpty) return null;

    final id = HymnalVersions.fromApiCode(code);
    if (id == null) return null;

    final isSda = id.startsWith('sda_');
    final known = HymnalVersions.all.where((item) => item.id == id).firstOrNull;
    final title = _nonEmptyString(json['title']);
    final year = _readInt(json['versionLabel']);
    final baseLabel = known?.label ??
        (isSda && year != null ? 'የ$year ውዳሴ መዝሙር' : title ?? id);
    final baseShortLabel =
        known?.shortLabel ?? (isSda && year != null ? '$year ውዳሴ' : baseLabel);
    // `songs: false` is a hymnal still being prepared: list it as such rather
    // than as an empty book.
    final capabilities = json['capabilities'];
    final ready = capabilities is! Map || capabilities['songs'] != false;
    const notReady = ' (በዝግጅት ላይ)';

    return HymnalVersion(
      id: id,
      label: ready ? baseLabel : '$baseLabel$notReady',
      shortLabel: ready ? baseShortLabel : '$baseShortLabel$notReady',
      isSda: isSda,
      hasCategories: isSda,
      fallbackDatabaseVersion: known?.fallbackDatabaseVersion ?? id,
    );
  }

  String? _nonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
    super.dispose();
  }
}
