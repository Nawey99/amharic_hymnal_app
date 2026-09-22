import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/app_update_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';
import 'package:amharic_hymnal_app/core/services/sheet_music_bulk_download_service.dart';
import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/edition_store.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/local_data_source.dart';

import '../../helpers/fake_hymnal_api.dart';
import '../../helpers/fakes.dart';

const _base = 'https://api.example.test/api/v1';
const _code = 'am-sda-2004';
const _epoch = '1970-01-01T00:00:00.000Z';

Map<String, dynamic> _song(int number, {String? checksum}) => {
      'id': '$_code-${number.toString().padLeft(4, '0')}',
      'number': number,
      'title': 'Hymn $number',
      'lyrics': 'Lyrics $number',
      'revision': 1,
      'category': null,
      'audio': {'available': false},
      'sheetMusic': {
        'available': checksum != null,
        'pages': [
          if (checksum != null)
            {
              'pageNumber': 1,
              'downloadUrl':
                  '$_base/songs/$_code-$number/sheet-music/pages/1/file',
              'checksumSha256': checksum,
            },
        ],
      },
      'isActive': true,
      'deletedAt': null,
    };

Map<String, dynamic> _delta(
  String serverTime,
  List<Map<String, dynamic>> songs, {
  List<Map<String, dynamic>> sheetMusicPages = const [],
}) =>
    {
      'serverTime': serverTime,
      'hasMore': false,
      'nextCursor': null,
      'hymnVersion': {'code': _code, 'isActive': true},
      'changes': {'songs': songs, 'sheetMusicPages': sheetMusicPages},
    };

/// A healthy API with a two-song 2004 edition at change token [token].
FakeHymnalApi _healthyApi({String token = 't1'}) =>
    FakeHymnalApi(baseUrl: _base)
      ..ok('/hymn-versions/$_code', {'code': _code, 'contentUpdatedAt': token})
      ..ok('/sync', _delta('2026-09-21T12:00:00.000Z', [_song(1), _song(2)]));

/// [api]'s client, except that requests whose path ends with [suffix] never
/// answer, like a connection that stalls.
http.Client _hangOn(FakeHymnalApi api, String suffix) =>
    _HangingClient(api.client, suffix);

class _HangingClient extends http.BaseClient {
  _HangingClient(this.inner, this.suffix);

  final http.Client inner;
  final String suffix;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.path.endsWith(suffix)) {
      return Completer<http.StreamedResponse>().future;
    }
    return inner.send(request);
  }
}

/// A store whose writes fail as on a full disk.
class _FullDiskStore extends MemoryEditionStore {
  @override
  Future<void> write(String key, StoredEdition edition) async =>
      throw const FileSystemException('No space left on device');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryEditionStore store;
  late MemoryMediaCache media;
  late DateTime now;

  setUp(() {
    store = MemoryEditionStore();
    media = MemoryMediaCache();
    now = DateTime.utc(2026, 9, 21, 12);
  });

  HymnRemoteDataSource sourceFor(http.Client client,
          {EditionStore? withStore}) =>
      HymnRemoteDataSource(
        baseUrl: _base,
        client: client,
        store: withStore ?? store,
        mediaCache: media,
        clock: () => now,
      );

  group('timeouts', () {
    test('the change check gives up after its timeout', () {
      fakeAsync((async) {
        Object? error;
        sourceFor(_hangOn(_healthyApi(), '/hymn-versions/$_code'))
            .getHymns('am', 'sda_new')
            .then((_) {})
            .catchError((Object e) {
          error = e;
        });
        async.elapse(const Duration(seconds: 4));
        expect(error, isNull, reason: 'still waiting inside the timeout');
        async.elapse(const Duration(seconds: 2));
        expect(error, isA<TimeoutException>());
      });
    });

    test('a stalled sync gives up, and the stored copy is served', () {
      fakeAsync((async) {
        sourceFor(_healthyApi().client).getHymns('am', 'sda_new');
        async.flushMicrotasks();
        expect(store.files, contains('am_$_code'));

        List<int?>? numbers;
        now = now.add(const Duration(days: 1));
        sourceFor(_hangOn(_healthyApi(token: 't2'), '/sync'))
            .getHymns('am', 'sda_new')
            .then((hymns) => numbers = [for (final h in hymns) h.number]);
        async.elapse(const Duration(seconds: 14));
        expect(numbers, isNull, reason: 'still inside the 15 s sync timeout');
        async.elapse(const Duration(seconds: 2));
        expect(numbers, [1, 2]);
      });
    });

    test('a stalled song re-read during a delta keeps the stored copy', () {
      fakeAsync((async) {
        sourceFor(_healthyApi().client).getHymns('am', 'sda_new');
        async.flushMicrotasks();

        final api = _healthyApi(token: 't2')
          ..ok(
            '/sync',
            _delta('2026-09-22T00:00:00.000Z', const [], sheetMusicPages: [
              {'songId': '$_code-0002', 'pageNumber': 1},
            ]),
          );
        List<int?>? numbers;
        now = now.add(const Duration(days: 1));
        sourceFor(_hangOn(api, '/songs/$_code-0002'))
            .getHymns('am', 'sda_new')
            .then((hymns) => numbers = [for (final h in hymns) h.number]);
        async.elapse(const Duration(seconds: 16));

        expect(numbers, [1, 2]);
        final stored =
            StoredEdition.fromJson(jsonDecode(store.files['am_$_code']!))!;
        expect(stored.contentUpdatedAt, 't1',
            reason: 'a failed update must not be recorded as done');
      });
    });

    test('the edition list keeps the built-in books when it stalls', () {
      fakeAsync((async) {
        final service = HymnalVersionService(
          baseUrl: _base,
          client: _hangOn(FakeHymnalApi(baseUrl: _base), '/hymn-versions'),
        );
        List<HymnalVersion>? versions;
        service.refresh().then((value) => versions = value);
        async.elapse(const Duration(seconds: 11));

        expect(versions, HymnalVersions.all);
        expect(service.lastError, isA<TimeoutException>());
      });
    });

    test('other-edition numbers, update check and page list time out', () {
      fakeAsync((async) {
        final client = _hangOn(FakeHymnalApi(baseUrl: _base), '');
        final errors = <String, Object>{};
        SongEditionsService(baseUrl: _base, client: client)
            .otherEditions('$_code-0001')
            .then((_) {})
            .catchError((Object e) {
          errors['editions'] = e;
        });
        AppUpdateService(
          baseUrl: _base,
          client: client,
          currentVersion: () async => '1.0.0',
        ).requiredVersion(_code).then((_) {}).catchError((Object e) {
          errors['update'] = e;
        });
        SheetMusicBulkDownloadService(
          baseUrl: _base,
          client: client,
          cache: media,
        ).plan(_code).then((_) {}).catchError((Object e) {
          errors['pages'] = e;
        });

        async.elapse(const Duration(seconds: 9));
        expect(errors.keys, containsAll(['editions', 'update']));
        expect(errors.containsKey('pages'), isFalse,
            reason: 'the page list allows 20 s');
        async.elapse(const Duration(seconds: 12));
        expect(errors, hasLength(3));
        expect(errors.values, everyElement(isA<TimeoutException>()));
      });
    });
  });

  group('rate limits and outages', () {
    test('after 429 the stored copy is served and the reset is waited out',
        () async {
      final api = _healthyApi();
      final source = sourceFor(api.client);
      await source.getHymns('am', 'sda_new');

      api.fail('/hymn-versions/$_code', 429, 'RATE_LIMIT_EXCEEDED',
          headers: {'ratelimit': '"60-in-1min"; r=0; t=30'});
      now = now.add(const Duration(minutes: 2));
      expect(await source.getHymns('am', 'sda_new'), hasLength(2));
      final sentAfterLimit = api.requests.length;

      // Inside the 30 s reset: nothing is sent at all.
      now = now.add(const Duration(seconds: 20));
      expect(await source.getHymns('am', 'sda_new'), hasLength(2));
      expect(api.requests, hasLength(sentAfterLimit));

      // After the reset the API is asked again.
      api.ok(
          '/hymn-versions/$_code', {'code': _code, 'contentUpdatedAt': 't1'});
      now = now.add(const Duration(seconds: 15));
      await source.getHymns('am', 'sda_new');
      expect(api.requests, hasLength(sentAfterLimit + 1));
    });

    test('503 with Retry-After is honoured the same way', () async {
      final api = _healthyApi();
      final source = sourceFor(api.client);
      await source.getHymns('am', 'sda_new');

      api.fail('/hymn-versions/$_code', 503, 'DATABASE_UNAVAILABLE',
          headers: {'retry-after': '90'});
      now = now.add(const Duration(minutes: 2));
      await source.getHymns('am', 'sda_new');
      final sent = api.requests.length;

      now = now.add(const Duration(minutes: 1, seconds: 5));
      expect(await source.getHymns('am', 'sda_new'), hasLength(2));
      expect(api.requests, hasLength(sent), reason: 'inside Retry-After');

      now = now.add(const Duration(seconds: 30));
      await source.getHymns('am', 'sda_new');
      expect(api.requests, hasLength(sent + 1));
    });

    test('a rate limit on first launch falls back to the bundled hymns',
        () async {
      final api = FakeHymnalApi(baseUrl: _base)
        ..fail('/hymn-versions/$_code', 429, 'RATE_LIMIT_EXCEEDED');
      final local = LocalDataSource(remoteDataSource: sourceFor(api.client));

      final hymns = await local.getHymns('am', HymnalVersions.sdaNew);

      expect(hymns, isNotEmpty);
      expect(hymns.first.id, isNot(startsWith('am-sda-')),
          reason: 'bundled hymns, not API ones');
    });
  });

  group('responses that are not the API', () {
    final bodies = <String, http.Response Function()>{
      'malformed JSON': () => http.Response('{"success": true, "data": [', 200),
      'a captive-portal login page': () => http.Response(
          '<html><body>Sign in to Wi-Fi</body></html>', 200,
          headers: {'content-type': 'text/html'}),
      'an empty body': () => http.Response('', 200),
      'a JSON array': () => http.Response('[1, 2, 3]', 200),
      'success with the wrong data shape': () =>
          http.Response('{"success": true, "data": "oops"}', 200),
    };

    bodies.forEach((name, response) {
      test('$name on first launch falls back to the bundled hymns', () async {
        final api = FakeHymnalApi(baseUrl: _base)
          ..on('/hymn-versions/$_code', (_) => response());
        final local = LocalDataSource(remoteDataSource: sourceFor(api.client));

        final hymns = await local.getHymns('am', HymnalVersions.sdaNew);

        expect(hymns, isNotEmpty);
        expect(store.files, isEmpty, reason: 'nothing bogus is stored');
      });

      test('$name instead of a sync keeps the stored copy', () async {
        final api = _healthyApi();
        await sourceFor(api.client).getHymns('am', 'sda_new');
        api
          ..ok('/hymn-versions/$_code',
              {'code': _code, 'contentUpdatedAt': 't2'})
          ..on('/sync', (_) => response());
        now = now.add(const Duration(days: 1));

        final hymns = await sourceFor(api.client).getHymns('am', 'sda_new');

        expect([for (final hymn in hymns) hymn.number], [1, 2]);
      });
    });

    test('an HTML page is reported as INVALID_RESPONSE', () {
      expect(
        () => decodeHymnalApiData(bodies['a captive-portal login page']!()),
        throwsA(isA<HymnalApiException>()
            .having((e) => e.code, 'code', 'INVALID_RESPONSE')),
      );
    });
  });

  group('device storage', () {
    test('a full disk still shows the hymns and deletes no downloads',
        () async {
      final api = FakeHymnalApi(baseUrl: _base)
        ..ok('/hymn-versions/$_code', {'code': _code, 'contentUpdatedAt': 't1'})
        ..ok('/sync',
            _delta('2026-09-21T12:00:00.000Z', [_song(1, checksum: 'a' * 64)]));
      media.stored['b' * 64] = 1; // a page downloaded for another edition

      final hymns = await sourceFor(api.client, withStore: _FullDiskStore())
          .getHymns('am', 'sda_new');

      expect(hymns.single.number, 1);
      expect(media.retained, isNull,
          reason: 'with the copy unsaved, references are unknown');
      expect(media.stored, contains('b' * 64));
    });

    test('a corrupt stored file is replaced by a fresh full download',
        () async {
      final root = await Directory.systemTemp.createTemp('corrupt_store');
      addTearDown(() => root.delete(recursive: true));
      final fileStore = FileEditionStore(directoryProvider: () async => root);
      final file = File('${root.path}/content_cache/am_$_code.json');
      await file.create(recursive: true);
      await file.writeAsString('{"schemaVersion": 1, "songs": [trunc');
      final api = _healthyApi();

      final hymns = await sourceFor(api.client, withStore: fileStore)
          .getHymns('am', 'sda_new');

      expect(hymns, hasLength(2));
      expect(
          api.requestsTo('/sync').single.url.queryParameters['since'], _epoch);
      expect((await fileStore.read('am_$_code'))!.songs, hasLength(2));
    });
  });

  group('wrong device clock', () {
    test('a clock years ahead still refreshes in full', () async {
      final api = _healthyApi();
      await sourceFor(api.client).getHymns('am', 'sda_new');
      api.requests.clear();

      now = DateTime.utc(2040, 1, 1);
      await sourceFor(api.client).getHymns('am', 'sda_new');

      expect(
          api.requestsTo('/sync').single.url.queryParameters['since'], _epoch);
    });

    test('a copy stored while the clock was ahead is not trusted forever',
        () async {
      // Synced with the clock wrongly set to 2030, then corrected.
      now = DateTime.utc(2030, 1, 1);
      final api = _healthyApi();
      await sourceFor(api.client).getHymns('am', 'sda_new');
      api.requests.clear();

      now = DateTime.utc(2026, 9, 21, 12);
      await sourceFor(api.client).getHymns('am', 'sda_new');

      expect(api.requestsTo('/sync'), hasLength(1),
          reason: 'a full refresh dated in the future must count as due');
    });

    test('a clock set back during a session does not freeze the content',
        () async {
      final api = _healthyApi();
      final source = sourceFor(api.client);
      await source.getHymns('am', 'sda_new');
      api.requests.clear();

      now = now.subtract(const Duration(days: 1));
      await source.getHymns('am', 'sda_new');

      expect(api.requestsTo('/hymn-versions/$_code'), hasLength(1),
          reason: 'a negative age must not count as fresh');
    });
  });
}
