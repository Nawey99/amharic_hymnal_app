import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/database/json_data_source.dart';
import 'package:amharic_hymnal_app/core/error/exceptions.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/local_data_source.dart';

import '../../../helpers/fake_hymnal_api.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fixtures.dart';

/// Records which books were read from the bundle.
class _RecordingJsonDataSource implements JsonDataSource {
  final List<String> requested = [];

  @override
  Future<List<Map<String, dynamic>>> getHymns(
    String languageCode,
    String version,
  ) {
    requested.add(version);
    return JsonDataSource.instance.getHymns(languageCode, version);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHymnalApi api;
  late _RecordingJsonDataSource bundled;
  late LocalDataSource source;

  setUp(() {
    api = FakeHymnalApi();
    bundled = _RecordingJsonDataSource();
    source = LocalDataSource(
      remoteDataSource: HymnRemoteDataSource(
        baseUrl: api.baseUrl,
        client: api.client,
        store: MemoryEditionStore(),
        mediaCache: MemoryMediaCache(),
      ),
      jsonDataSource: bundled,
    );
  });

  void serve1975Sample() {
    api.ok('/hymn-versions/am-sda-1975',
        apiFixtureData<Map<String, dynamic>>('hymn_version_1975.json'));
    api.ok(
        '/sync', apiFixtureData<Map<String, dynamic>>('sync_1975_sample.json'));
  }

  group('offline, nothing stored', () {
    setUp(() => api.online = false);

    test('the 2004 book comes from the bundle, 325 hymns', () async {
      final hymns = await source.getHymns('am', HymnalVersions.sdaNew);

      expect(hymns, hasLength(325));
      expect(bundled.requested, [HymnalVersions.sdaNew]);
      expect(hymns.first.number, 1);
      expect(hymns.first.title, isNotEmpty);
      expect(hymns.first.lyrics, isNotEmpty);
    });

    test('the 1975 book uses its own numbers and titles', () async {
      final hymns1975 = await source.getHymns('am', HymnalVersions.sdaOld);
      final hymns2004 = await source.getHymns('am', HymnalVersions.sdaNew);

      expect(hymns1975, hasLength(294));
      expect(
          hymns1975.map((h) => h.number), [for (var n = 1; n <= 294; n++) n]);
      // Hymn 1 opens both books; later numbers differ between them.
      final differing = [
        for (var i = 0; i < 294; i++)
          if (hymns1975[i].title != hymns2004[i].title) i,
      ];
      expect(differing, isNotEmpty);
    });

    test('Hagerigna comes from its own bundle, 121 songs', () async {
      final songs = await source.getHymns('am', HymnalVersions.hagerigna);

      expect(songs, hasLength(121));
      expect(songs.every((s) => s.isHagerigna), isTrue);
    });

    test('the legacy "hymnal" ID reads the 2004 book', () async {
      final hymns = await source.getHymns('am', 'hymnal');

      expect(hymns, hasLength(325));
      expect(bundled.requested, [HymnalVersions.sdaNew]);
    });

    test('the 1961 book, which is not bundled, fails with a clear error',
        () async {
      await expectLater(
        source.getHymns('am', HymnalVersions.sda1961),
        throwsA(isA<DatabaseNotFoundException>()),
      );
      expect(bundled.requested, isEmpty);
    });

    test('a book the API added later is not replaced by another book',
        () async {
      await expectLater(
        source.getHymns('am', 'sda_2019'),
        throwsA(isA<DatabaseNotFoundException>()),
      );
    });

    test('bundled 2004 hymns get categories from the number ranges', () async {
      final hymns = await source.getHymns('am', HymnalVersions.sdaNew);

      expect(hymns.first.category, isNotNull);
    });

    test('bundled 1975 hymns get no fallback category', () async {
      final hymns = await source.getHymns('am', HymnalVersions.sdaOld);

      expect(hymns.every((h) => h.category == null), isTrue);
    });
  });

  group('online', () {
    test('API content wins over the bundle', () async {
      serve1975Sample();

      final hymns = await source.getHymns('am', HymnalVersions.sdaOld);

      expect(hymns.map((h) => h.number), [1, 4, 56, 64, 130]);
      expect(hymns.first.id, 'am-sda-1975-0001');
      expect(bundled.requested, isEmpty);
    });

    test('an empty edition from the API stays empty', () async {
      api.ok('/hymn-versions/am-sda-2004',
          {'code': 'am-sda-2004', 'contentUpdatedAt': 't1'});
      api.ok('/sync', {
        'serverTime': '2026-09-21T12:00:00.000Z',
        'hasMore': false,
        'nextCursor': null,
        'hymnVersion': {'code': 'am-sda-2004', 'isActive': true},
        'changes': {'songs': []},
      });

      final hymns = await source.getHymns('am', HymnalVersions.sdaNew);

      expect(hymns, isEmpty);
      expect(bundled.requested, isEmpty);
    });

    test('the 1961 book loads from the API when online', () async {
      api.ok('/hymn-versions/am-sda-1961',
          {'code': 'am-sda-1961', 'contentUpdatedAt': 't1'});
      api.ok('/sync', {
        'serverTime': '2026-09-21T12:00:00.000Z',
        'hasMore': false,
        'nextCursor': null,
        'hymnVersion': {'code': 'am-sda-1961', 'isActive': true},
        'changes': {
          'songs': [
            {
              'id': 'am-sda-1961-0001',
              'number': 1,
              'title': 'ርዕስ',
              'lyrics': 'ግጥም',
              'revision': 1,
              'isActive': true,
              'deletedAt': null,
            },
          ],
        },
      });

      final hymns = await source.getHymns('am', HymnalVersions.sda1961);

      expect(hymns.single.id, 'am-sda-1961-0001');
    });

    test('a server error falls back to the bundle', () async {
      api.fail('/hymn-versions/am-sda-2004', 503, 'DATABASE_UNAVAILABLE');

      final hymns = await source.getHymns('am', HymnalVersions.sdaNew);

      expect(hymns, hasLength(325));
      expect(bundled.requested, [HymnalVersions.sdaNew]);
    });
  });
}
