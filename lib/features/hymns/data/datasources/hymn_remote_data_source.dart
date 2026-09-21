import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_client.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart'
    show MediaType;
import 'package:amharic_hymnal_app/features/hymns/data/datasources/edition_store.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

/// Loads whole editions from the hymnal API and keeps them on the device.
///
/// The first load of an edition reads its full catalogue through `/sync` from
/// the epoch, since the song list route omits lyrics. Later loads ask only for
/// changes since the stored `serverTime`, and only when the edition's
/// `contentUpdatedAt` change token has moved. Offline, the stored copy is
/// served; with no stored copy the caller falls back to bundled content.
class HymnRemoteDataSource {
  HymnRemoteDataSource({
    http.Client? client,
    String? baseUrl,
    DateTime Function()? clock,
    EditionStore? store,
    MediaCache? mediaCache,
  })  : _api = HymnalApiClient(client: client, clock: clock),
        _baseUrl = baseUrl ?? ContentApiConfig.baseUrl,
        _clock = clock ?? DateTime.now,
        _store = store ?? (kIsWeb ? null : FileEditionStore()),
        _mediaCache =
            mediaCache ?? (kIsWeb ? null : LocalMediaCacheService.instance);

  /// How long a loaded edition is served without asking whether it changed.
  /// Number lookups, search and categories all read the full edition, so this
  /// keeps them from each costing a request.
  static const freshnessWindow = Duration(minutes: 1);

  /// How often an edition is downloaded whole instead of patched. Deltas do
  /// not report songs deleted outright, nor re-scans of pages an edition
  /// borrows from another, so a periodic full copy catches both.
  static const fullRefreshInterval = Duration(days: 7);

  static const _checkTimeout = Duration(seconds: 5);
  static const _syncTimeout = Duration(seconds: 15);
  static const _syncPageSize = 500;
  static const _syncFromStart = '1970-01-01T00:00:00.000Z';

  final HymnalApiClient _api;
  final String _baseUrl;
  final DateTime Function() _clock;
  final EditionStore? _store;
  final MediaCache? _mediaCache;

  final Map<String, _CachedEdition> _cache = {};
  final Map<String, Future<List<HymnModel>>> _inFlight = {};

  Future<List<HymnModel>> getHymns(String languageCode, String version) {
    final code = HymnalVersions.apiCode(version, languageCode: languageCode);
    final key = '${languageCode}_$code';
    // A block body: returning the removed future would make whenComplete
    // wait on itself.
    return _inFlight[key] ??= _load(languageCode, code, key).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<List<HymnModel>> _load(
    String languageCode,
    String code,
    String key,
  ) async {
    var cached = _cache[key];
    final now = _clock();
    final checkedAt = cached?.checkedAt;
    if (cached != null &&
        checkedAt != null &&
        now.difference(checkedAt) < freshnessWindow) {
      return cached.hymns;
    }
    cached ??= await _restore(key, code);

    final String? contentUpdatedAt;
    try {
      contentUpdatedAt = await _fetchContentUpdatedAt(languageCode, code);
    } on HymnalApiException catch (error) {
      if (error.code == 'HYMN_VERSION_NOT_FOUND') {
        // Retired: the stored copy must not keep it alive.
        await _forget(key);
        rethrow;
      }
      return _servedOffline(key, cached, code, error);
    } catch (error) {
      return _servedOffline(key, cached, code, error);
    }

    final fullSyncAt = cached?.fullSyncAt;
    final fullRefreshDue = cached != null &&
        (fullSyncAt == null ||
            now.difference(fullSyncAt) >= fullRefreshInterval);
    if (cached != null &&
        !fullRefreshDue &&
        contentUpdatedAt != null &&
        cached.contentUpdatedAt == contentUpdatedAt) {
      _cache[key] = cached.copyWith(checkedAt: now);
      return cached.hymns;
    }

    final _SyncResult result;
    try {
      result = await _sync(languageCode, code, fullRefreshDue ? null : cached);
    } catch (error) {
      return _servedOffline(key, cached, code, error);
    }

    if (!result.isActive) {
      await _forget(key);
      return const [];
    }

    final edition = _CachedEdition.fromSongs(
      code: code,
      songs: result.songs,
      serverTime: result.serverTime,
      contentUpdatedAt: contentUpdatedAt,
      checkedAt: now,
      fullSyncAt: result.isFullSync ? now : cached?.fullSyncAt,
    );
    _cache[key] = edition;
    if (await _save(key, edition)) await _pruneMedia();
    return edition.hymns;
  }

  /// What this device already has, when the API cannot be reached or the
  /// update fails part-way.
  List<HymnModel> _servedOffline(
    String key,
    _CachedEdition? cached,
    String code,
    Object error,
  ) {
    if (cached == null) throw error;
    if (kDebugMode) {
      debugPrint('Hymnal API unavailable, using stored $code: $error');
    }
    _cache[key] = cached;
    return cached.hymns;
  }

  Future<_CachedEdition?> _restore(String key, String code) async {
    final stored = await _store?.read(key);
    if (stored == null || stored.code != code) return null;
    return _CachedEdition.fromSongs(
      code: code,
      songs: stored.songs,
      serverTime: stored.serverTime,
      contentUpdatedAt: stored.contentUpdatedAt,
      checkedAt: null,
      fullSyncAt: stored.fullSyncAt,
    );
  }

  /// Returns whether the edition was stored.
  Future<bool> _save(String key, _CachedEdition edition) async {
    final store = _store;
    if (store == null) return false;
    try {
      await store.write(
        key,
        StoredEdition(
          code: edition.code,
          contentUpdatedAt: edition.contentUpdatedAt,
          serverTime: edition.serverTime,
          songs: edition.songs,
          fullSyncAt: edition.fullSyncAt,
        ),
      );
      return true;
    } catch (error) {
      // Still usable this session; the next launch syncs again.
      if (kDebugMode) debugPrint('Could not store ${edition.code}: $error');
      return false;
    }
  }

  /// Deletes downloaded audio and pages no stored edition refers to any
  /// more, e.g. the old image after a page is re-scanned.
  Future<void> _pruneMedia() async {
    final mediaCache = _mediaCache;
    if (mediaCache == null) return;
    try {
      final editions = await _store?.readAll();
      // Unknown references: keep everything rather than guess.
      if (editions == null) return;
      final keep = {for (final edition in editions) ...edition.mediaChecksums};
      await mediaCache
          .retainOnly(keep, const [MediaType.audio, MediaType.sheetMusic]);
    } catch (error) {
      if (kDebugMode) debugPrint('Could not tidy downloaded media: $error');
    }
  }

  Future<void> _forget(String key) async {
    _cache.remove(key);
    try {
      await _store?.delete(key);
    } catch (_) {}
  }

  Future<String?> _fetchContentUpdatedAt(
    String languageCode,
    String code,
  ) async {
    final uri =
        Uri.parse('$_baseUrl/hymn-versions/${Uri.encodeComponent(code)}')
            .replace(queryParameters: {'language': languageCode});
    final response =
        await _api.get(uri, timeout: _checkTimeout, conditional: true);
    final data = decodeHymnalApiData(response);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Edition response is missing its data.');
    }
    return data['contentUpdatedAt']?.toString();
  }

  /// Brings [base] up to date: a delta from its `serverTime`, or the whole
  /// edition when there is no base or the server rejects the delta.
  Future<_SyncResult> _sync(
    String languageCode,
    String code,
    _CachedEdition? base,
  ) async {
    if (base == null) {
      return _pull(languageCode, code, since: _syncFromStart, songs: {});
    }
    try {
      return await _pull(
        languageCode,
        code,
        since: base.serverTime,
        songs: Map.of(base.songs),
      );
    } on HymnalApiException catch (error) {
      if (error.code != 'INVALID_SYNC_CURSOR' &&
          error.code != 'INVALID_SYNC_TIMESTAMP') {
        rethrow;
      }
      return _pull(languageCode, code, since: _syncFromStart, songs: {});
    }
  }

  Future<_SyncResult> _pull(
    String languageCode,
    String code, {
    required String since,
    required Map<String, Map<String, dynamic>> songs,
  }) async {
    final isFullSync = since == _syncFromStart;
    final changedSongIds = <String>{};
    final changedPageSongIds = <String>{};
    String? cursor;
    var serverTime = since;

    do {
      final uri = Uri.parse('$_baseUrl/sync').replace(queryParameters: {
        'language': languageCode,
        'version': code,
        'since': since,
        'limit': '$_syncPageSize',
        if (cursor != null) 'cursor': cursor,
      });
      if (kDebugMode) debugPrint('🌐 Syncing hymns from hymnal API: $uri');

      final response = await _api.get(uri, timeout: _syncTimeout);
      final data = decodeHymnalApiData(response);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Sync response is missing its data.');
      }

      final edition = data['hymnVersion'];
      if (edition is Map && edition['isActive'] == false) {
        return _SyncResult.inactive();
      }

      final changes = data['changes'];
      if (changes is! Map || changes['songs'] is! List) {
        throw const FormatException('Sync response is missing its songs.');
      }
      _applySongs(songs, changes['songs'] as List, changedSongIds);
      _applyAudio(songs, changes['audio']);
      _applyCategories(songs, changes['categories']);
      for (final page in _maps(changes['sheetMusicPages'])) {
        final songId = page['songId'];
        if (songId is String) changedPageSongIds.add(songId);
      }

      serverTime = data['serverTime']?.toString() ?? serverTime;
      cursor = data['hasMore'] == true ? data['nextCursor']?.toString() : null;
    } while (cursor != null);

    // A re-scanned page moves no song timestamp, and page entries do not say
    // whether a page was withdrawn, so re-read each affected song whole. A
    // full sync already has every song current.
    if (!isFullSync) {
      for (final songId in changedPageSongIds.difference(changedSongIds)) {
        await _refetchSong(languageCode, code, songId, songs);
      }
    }

    return _SyncResult(
      songs: songs,
      serverTime: serverTime,
      isFullSync: isFullSync,
    );
  }

  void _applySongs(
    Map<String, Map<String, dynamic>> songs,
    List<dynamic> changes,
    Set<String> changedSongIds,
  ) {
    // Sync resends a short window of rows; keep the highest revision.
    for (final song in changes.whereType<Map<String, dynamic>>()) {
      final id = song['id'];
      if (id is! String) continue;
      changedSongIds.add(id);
      final existing = songs[id];
      if (existing != null &&
          (_readInt(song['revision']) ?? 0) <
              (_readInt(existing['revision']) ?? 0)) {
        continue;
      }
      if (song['deletedAt'] != null || song['isActive'] == false) {
        songs.remove(id);
      } else {
        songs[id] = song;
      }
    }
  }

  /// Tracks added, replaced or made unavailable without the song changing.
  void _applyAudio(Map<String, Map<String, dynamic>> songs, Object? changes) {
    for (final track in _maps(changes)) {
      final songId = track['songId'];
      final song = songs[songId];
      if (songId is String && song != null) {
        songs[songId] = {...song, 'audio': track};
      }
    }
  }

  /// Renamed or retired categories. Songs keep their place; a retired
  /// category is simply no longer shown on them.
  void _applyCategories(
    Map<String, Map<String, dynamic>> songs,
    Object? changes,
  ) {
    for (final category in _maps(changes)) {
      final slug = category['slug'];
      if (slug is! String) continue;
      for (final entry in songs.entries.toList()) {
        final current = entry.value['category'];
        if (current is! Map || current['slug'] != slug) continue;
        songs[entry.key] = {
          ...entry.value,
          'category': category['isActive'] == false
              ? null
              : {...current, 'name': category['name']},
        };
      }
    }
  }

  Future<void> _refetchSong(
    String languageCode,
    String code,
    String songId,
    Map<String, Map<String, dynamic>> songs,
  ) async {
    final uri = Uri.parse('$_baseUrl/songs/${Uri.encodeComponent(songId)}')
        .replace(queryParameters: {'language': languageCode, 'version': code});
    try {
      final response = await _api.get(uri, timeout: _syncTimeout);
      final song = decodeHymnalApiData(response);
      if (song is Map<String, dynamic>) songs[songId] = song;
    } on HymnalApiException catch (error) {
      if (error.code != 'SONG_NOT_FOUND') rethrow;
      songs.remove(songId);
    }
  }

  static Iterable<Map<String, dynamic>> _maps(Object? value) =>
      value is List ? value.whereType<Map<String, dynamic>>() : const [];

  /// Maps an API song object onto the app's hymn model.
  static HymnModel mapSong(Map<String, dynamic> song, String code) {
    final number = _readInt(song['number']);
    final category = song['category'];
    final audioInfo = _mapAudio(song['audio']);
    final sheetMusic = song['sheetMusic'];
    final pages = sheetMusic is Map ? sheetMusic['pages'] : null;

    final sheetPages = pages is List
        ? (pages
            .whereType<Map<String, dynamic>>()
            .map(_mapSheetPage)
            .whereType<HymnSheetPage>()
            .toList()
          ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber)))
        : const <HymnSheetPage>[];

    return HymnModel(
      id: song['id'] as String?,
      number: number,
      title: song['title'] as String?,
      lyrics: song['lyrics'] as String?,
      // The number ranges are the 2004 book's; other editions group their
      // hymns differently, so they get no category rather than a wrong one.
      category: (category is Map ? category['name'] as String? : null) ??
          (code == HymnalVersions.apiCode(HymnalVersions.sdaNew)
              ? HymnCategories.getCategoryByNumber(number ?? 0)?.nameAmharic
              : null),
      audioUrl: audioInfo?.file.url,
      audioInfo: audioInfo,
      sheetMusic: sheetPages.isEmpty
          ? null
          : sheetPages.map((page) => page.file.url).toList(),
      sheetPages: sheetPages.isEmpty ? null : List.unmodifiable(sheetPages),
      englishTitleOld: song['englishTitle'] as String?,
      newHymnalNumber:
          code == HymnalVersions.apiCode(HymnalVersions.sdaNew) ? number : null,
      oldHymnalNumber:
          code == HymnalVersions.apiCode(HymnalVersions.sdaOld) ? number : null,
    );
  }

  static HymnAudioInfo? _mapAudio(Object? audio) {
    if (audio is! Map<String, dynamic> || audio['available'] != true) {
      return null;
    }
    final file = _mapFile(audio);
    if (file == null) return null;
    return HymnAudioInfo(
      file: file,
      isSynthesized: audio['source'] == 'synthesized',
      attribution: _nonEmpty(audio['attribution']),
    );
  }

  static HymnSheetPage? _mapSheetPage(Map<String, dynamic> page) {
    final file = _mapFile(page);
    final pageNumber = _readInt(page['pageNumber']);
    if (file == null || pageNumber == null) return null;
    return HymnSheetPage(
      file: file,
      pageNumber: pageNumber,
      borrowedFromVersionCode: _nonEmpty(page['borrowedFromVersionCode']),
    );
  }

  static HymnMediaFile? _mapFile(Map<String, dynamic> json) {
    final url = _nonEmpty(json['downloadUrl']);
    if (url == null) return null;
    return HymnMediaFile(
      url: url,
      checksumSha256: _nonEmpty(json['checksumSha256'])?.toLowerCase(),
      sizeBytes: _readInt(json['sizeBytes']),
      contentType: _nonEmpty(json['contentType']),
      fileName: _nonEmpty(json['fileName']),
    );
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class _SyncResult {
  final Map<String, Map<String, dynamic>> songs;
  final String serverTime;
  final bool isFullSync;
  final bool isActive;

  const _SyncResult({
    required this.songs,
    required this.serverTime,
    required this.isFullSync,
  }) : isActive = true;

  _SyncResult.inactive()
      : songs = const {},
        serverTime = '',
        isFullSync = false,
        isActive = false;
}

class _CachedEdition {
  final String code;
  final Map<String, Map<String, dynamic>> songs;
  final List<HymnModel> hymns;
  final String serverTime;
  final String? contentUpdatedAt;

  /// When the change token was last confirmed; null for a copy restored from
  /// the device and not yet checked.
  final DateTime? checkedAt;
  final DateTime? fullSyncAt;

  const _CachedEdition({
    required this.code,
    required this.songs,
    required this.hymns,
    required this.serverTime,
    required this.contentUpdatedAt,
    required this.checkedAt,
    required this.fullSyncAt,
  });

  factory _CachedEdition.fromSongs({
    required String code,
    required Map<String, Map<String, dynamic>> songs,
    required String serverTime,
    required String? contentUpdatedAt,
    required DateTime? checkedAt,
    required DateTime? fullSyncAt,
  }) {
    final hymns = songs.values
        .map((song) => HymnRemoteDataSource.mapSong(song, code))
        .toList()
      ..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
    if (kDebugMode) debugPrint('✅ ${hymns.length} hymns ready for $code');
    return _CachedEdition(
      code: code,
      songs: Map.unmodifiable(songs),
      hymns: List.unmodifiable(hymns),
      serverTime: serverTime,
      contentUpdatedAt: contentUpdatedAt,
      checkedAt: checkedAt,
      fullSyncAt: fullSyncAt,
    );
  }

  _CachedEdition copyWith({required DateTime checkedAt}) => _CachedEdition(
        code: code,
        songs: songs,
        hymns: hymns,
        serverTime: serverTime,
        contentUpdatedAt: contentUpdatedAt,
        checkedAt: checkedAt,
        fullSyncAt: fullSyncAt,
      );
}
