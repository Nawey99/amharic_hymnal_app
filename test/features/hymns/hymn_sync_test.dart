import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/edition_store.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';

const _base = 'https://api.example.test/api/v1';
const _code = 'am-sda-2004';
const _epoch = '1970-01-01T00:00:00.000Z';

class MemoryEditionStore implements EditionStore {
  final Map<String, String> files = {};

  @override
  Future<StoredEdition?> read(String key) async {
    final json = files[key];
    return json == null ? null : StoredEdition.fromJson(jsonDecode(json));
  }

  @override
  Future<void> write(String key, StoredEdition edition) async {
    files[key] = jsonEncode(edition.toJson());
  }

  @override
  Future<void> delete(String key) async => files.remove(key);

  @override
  Future<List<StoredEdition>?> readAll() async => [
        for (final json in files.values)
          StoredEdition.fromJson(jsonDecode(json))!,
      ];
}

class RecordingMediaCache implements MediaCache {
  Set<String>? retained;

  @override
  Future<void> retainOnly(
      Set<String> checksums, List<String> mediaTypes) async {
    retained = checksums;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _song(
  int number, {
  String? title,
  int revision = 1,
  String? deletedAt,
  Map<String, dynamic>? category,
  List<Map<String, dynamic>> pages = const [],
}) =>
    {
      'id': '$_code-${number.toString().padLeft(4, '0')}',
      'number': number,
      'title': title ?? 'Hymn $number',
      'lyrics': 'Lyrics $number',
      'revision': revision,
      'category': category,
      'audio': {'available': false},
      'sheetMusic': {'available': pages.isNotEmpty, 'pages': pages},
      'isActive': true,
      'deletedAt': deletedAt,
    };

Map<String, dynamic> _pageEntry(int number, String checksum) => {
      'pageNumber': 1,
      'downloadUrl': '$_base/songs/$_code-$number/sheet-music/pages/1/file',
      'checksumSha256': checksum,
    };

/// A scripted hymnal API. Tests set [token] and [syncResponses] per `since`.
class FakeHymnalApi {
  String token = 't1';
  bool online = true;
  final Map<String, Map<String, dynamic>> syncBySince = {};
  final Map<String, Map<String, dynamic>> songDetails = {};
  final List<Uri> requests = [];

  MockClient get client => MockClient((request) async {
        if (!online) throw http.ClientException('offline');
        requests.add(request.url);
        final path = request.url.path;
        if (path.endsWith('/hymn-versions/$_code')) {
          return _ok({'code': _code, 'contentUpdatedAt': token});
        }
        if (path.endsWith('/sync')) {
          final since = request.url.queryParameters['since']!;
          final data = syncBySince[since];
          if (data == null) {
            return _error(400, 'INVALID_SYNC_TIMESTAMP');
          }
          return _ok(data);
        }
        final songId = path.split('/').last;
        final song = songDetails[songId];
        return song == null ? _error(404, 'SONG_NOT_FOUND') : _ok(song);
      });

  List<Uri> get syncRequests =>
      requests.where((uri) => uri.path.endsWith('/sync')).toList();

  static http.Response _ok(Object data) => http.Response.bytes(
        utf8.encode(jsonEncode({'success': true, 'data': data})),
        200,
      );

  static http.Response _error(int status, String code) => http.Response(
        jsonEncode({
          'success': false,
          'error': {'code': code, 'message': code},
        }),
        status,
      );
}

Map<String, dynamic> _delta(
  String serverTime, {
  List<Map<String, dynamic>> songs = const [],
  List<Map<String, dynamic>> audio = const [],
  List<Map<String, dynamic>> categories = const [],
  List<Map<String, dynamic>> sheetMusicPages = const [],
  bool isActive = true,
}) =>
    {
      'serverTime': serverTime,
      'hasMore': false,
      'nextCursor': null,
      'hymnVersion': {'code': _code, 'isActive': isActive},
      'changes': {
        'songs': songs,
        'audio': audio,
        'categories': categories,
        'sheetMusicPages': sheetMusicPages,
      },
    };

void main() {
  late FakeHymnalApi api;
  late MemoryEditionStore store;
  late DateTime now;
  late RecordingMediaCache media;

  HymnRemoteDataSource newSource() => HymnRemoteDataSource(
        baseUrl: _base,
        client: api.client,
        store: store,
        mediaCache: media,
        clock: () => now,
      );

  setUp(() {
    api = FakeHymnalApi();
    store = MemoryEditionStore();
    media = RecordingMediaCache();
    now = DateTime.utc(2026, 9, 21, 12);
    api.syncBySince[_epoch] = _delta('2026-09-21T12:00:00.000Z', songs: [
      _song(1, category: {'slug': 'praise', 'name': 'Praise'}),
      _song(2),
    ]);
  });

  test('keeps a synced edition on the device for an offline restart', () async {
    await newSource().getHymns('am', 'sda_new');
    expect(store.files, contains('am_$_code'));

    api.online = false;
    final hymns = await newSource().getHymns('am', 'sda_new');

    expect(hymns.map((hymn) => hymn.number), [1, 2]);
  });

  test('an unchanged edition costs one small request after a restart',
      () async {
    await newSource().getHymns('am', 'sda_new');
    api.requests.clear();

    await newSource().getHymns('am', 'sda_new');

    expect(api.syncRequests, isEmpty);
    expect(api.requests, hasLength(1));
  });

  test('a changed edition downloads only the delta and applies it', () async {
    await newSource().getHymns('am', 'sda_new');
    api.requests.clear();
    api.token = 't2';
    api.songDetails['$_code-0002'] = _song(2, pages: [_pageEntry(2, 'b' * 64)]);
    api.syncBySince['2026-09-21T12:00:00.000Z'] =
        _delta('2026-09-22T08:00:00.000Z', songs: [
      _song(1,
          title: 'Corrected title',
          revision: 2,
          category: {'slug': 'praise', 'name': 'Praise'}),
      _song(3),
    ], audio: [
      {
        'songId': '$_code-0003',
        'available': true,
        'source': 'recording',
        'downloadUrl': '$_base/songs/$_code-0003/audio/file',
      },
    ], categories: [
      {'slug': 'praise', 'name': 'Worship', 'isActive': true},
    ], sheetMusicPages: [
      {'songId': '$_code-0002', 'pageNumber': 1},
    ]);
    now = now.add(const Duration(days: 1));

    final hymns = await newSource().getHymns('am', 'sda_new');

    expect(api.syncRequests.single.queryParameters['since'],
        '2026-09-21T12:00:00.000Z');
    expect(hymns.map((hymn) => hymn.number), [1, 2, 3]);
    expect(hymns[0].title, 'Corrected title');
    expect(hymns[0].category, 'Worship');
    expect(hymns[1].sheetPages!.single.file.checksumSha256, 'b' * 64);
    expect(hymns[2].audioUrl, '$_base/songs/$_code-0003/audio/file');
    expect(
      StoredEdition.fromJson(jsonDecode(store.files['am_$_code']!))!.serverTime,
      '2026-09-22T08:00:00.000Z',
    );
  });

  test('a retired song is removed and a stale resend is ignored', () async {
    await newSource().getHymns('am', 'sda_new');
    api.token = 't2';
    api.syncBySince['2026-09-21T12:00:00.000Z'] =
        _delta('2026-09-22T08:00:00.000Z', songs: [
      _song(1, title: 'Older copy', revision: 0),
      _song(2, revision: 2, deletedAt: '2026-09-22T07:00:00.000Z'),
    ]);
    now = now.add(const Duration(days: 1));

    final hymns = await newSource().getHymns('am', 'sda_new');

    expect(hymns.map((hymn) => hymn.number), [1]);
    expect(hymns.single.title, 'Hymn 1');
  });

  test('a rejected sync position falls back to a full download', () async {
    await newSource().getHymns('am', 'sda_new');
    api.token = 't2';
    // No delta is scripted for the stored serverTime, so the fake answers
    // INVALID_SYNC_TIMESTAMP; the epoch sync still works.
    now = now.add(const Duration(days: 1));

    final hymns = await newSource().getHymns('am', 'sda_new');

    expect(hymns.map((hymn) => hymn.number), [1, 2]);
    expect(api.syncRequests.last.queryParameters['since'], _epoch);
  });

  test('keeps the stored copy when an update fails part-way', () async {
    await newSource().getHymns('am', 'sda_new');
    api.token = 't2';
    api.syncBySince['2026-09-21T12:00:00.000Z'] = {'not': 'a delta'};
    now = now.add(const Duration(days: 1));

    final hymns = await newSource().getHymns('am', 'sda_new');

    expect(hymns.map((hymn) => hymn.number), [1, 2]);
  });

  test('forgets an edition the API has retired', () async {
    await newSource().getHymns('am', 'sda_new');
    api.token = 't2';
    api.syncBySince['2026-09-21T12:00:00.000Z'] =
        _delta('2026-09-22T08:00:00.000Z', isActive: false);
    now = now.add(const Duration(days: 1));

    expect(await newSource().getHymns('am', 'sda_new'), isEmpty);
    expect(store.files, isEmpty);
  });

  test('forgets an edition code the API no longer knows', () async {
    await newSource().getHymns('am', 'sda_new');
    final gone = HymnRemoteDataSource(
      baseUrl: _base,
      store: store,
      client: MockClient((_) async => http.Response(
            '{"success":false,"error":{"code":"HYMN_VERSION_NOT_FOUND","message":"gone"}}',
            404,
          )),
    );

    await expectLater(
      gone.getHymns('am', 'sda_new'),
      throwsA(isA<HymnalApiException>()),
    );
    expect(store.files, isEmpty);
  });

  test('the file store round-trips an edition and ignores damage', () async {
    final root = await Directory.systemTemp.createTemp('edition_store_test');
    addTearDown(() => root.delete(recursive: true));
    final fileStore = FileEditionStore(directoryProvider: () async => root);
    final edition = StoredEdition(
      code: _code,
      contentUpdatedAt: 't1',
      serverTime: '2026-09-21T12:00:00.000Z',
      songs: {'$_code-0001': _song(1, title: 'ወዳንተ የሱስ ሆይ')},
    );

    await fileStore.write('am_$_code', edition);
    await fileStore.write('am_$_code', edition);
    final read = await fileStore.read('am_$_code');
    expect(read!.songs['$_code-0001']!['title'], 'ወዳንተ የሱስ ሆይ');
    expect(read.contentUpdatedAt, 't1');

    final file = File('${root.path}/content_cache/am_$_code.json');
    await file.writeAsString('{ damaged');
    expect(await fileStore.read('am_$_code'), isNull);

    await fileStore.delete('am_$_code');
    expect(await file.exists(), isFalse);
  });

  test('downloads the whole edition again once a week', () async {
    await newSource().getHymns('am', 'sda_new');
    api.requests.clear();
    // Nothing changed, but a week has passed: a full copy catches songs
    // deleted outright, which deltas never report.
    api.syncBySince[_epoch] =
        _delta('2026-09-28T12:00:00.000Z', songs: [_song(1)]);
    now = now.add(HymnRemoteDataSource.fullRefreshInterval);

    final hymns = await newSource().getHymns('am', 'sda_new');

    expect(api.syncRequests.single.queryParameters['since'], _epoch);
    expect(hymns.map((hymn) => hymn.number), [1]);
  });

  test('after an update, keeps only media that stored editions still use',
      () async {
    api.syncBySince[_epoch] = _delta('2026-09-21T12:00:00.000Z', songs: [
      _song(1, pages: [_pageEntry(1, 'a' * 64)]),
    ]);
    await newSource().getHymns('am', 'sda_new');
    expect(media.retained, {'a' * 64});

    api.token = 't2';
    api.syncBySince['2026-09-21T12:00:00.000Z'] =
        _delta('2026-09-22T08:00:00.000Z', songs: [
      _song(1, revision: 2, pages: [_pageEntry(1, 'c' * 64)]),
    ]);
    now = now.add(const Duration(days: 1));
    await newSource().getHymns('am', 'sda_new');

    expect(media.retained, {'c' * 64});
  });
}
