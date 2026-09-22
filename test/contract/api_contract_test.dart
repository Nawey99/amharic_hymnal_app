import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/app_update_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';
import 'package:amharic_hymnal_app/core/services/sheet_music_bulk_download_service.dart';
import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';

import '../helpers/fake_hymnal_api.dart';
import '../helpers/fakes.dart';
import '../helpers/fixtures.dart';
import 'openapi_validator.dart';

/// Serves a recorded response exactly as the server sent it.
http.Response _recorded(String name, [int status = 200]) => http.Response.bytes(
      utf8.encode(apiFixtureText(name)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  final contract = OpenApiContract.load();

  group('recorded responses match the published contract', () {
    const responses = {
      'hymn_versions.json': '/api/v1/hymn-versions',
      'hymn_version_1975.json': '/api/v1/hymn-versions/{version}',
      'song_1975_0130.json': '/api/v1/songs/{songId}',
      'sync_1975_sample.json': '/api/v1/sync',
      'manifest_2004.json': '/api/v1/manifest',
      'sheet_pages_1961_sample.json': '/api/v1/downloads/sheet-music/pages',
    };

    responses.forEach((fixture, path) {
      test('$fixture is a valid $path response', () {
        expect(contract.validateResponse(path, apiFixture(fixture)), isEmpty);
      });
    });

    test('error responses are ErrorEnvelopes', () {
      for (final fixture in [
        'error_song_not_found.json',
        'error_hymn_version_not_found.json',
      ]) {
        expect(contract.validateComponent('ErrorEnvelope', apiFixture(fixture)),
            isEmpty,
            reason: fixture);
      }
    });

    test('the validator really rejects a broken body', () {
      final song = Map<String, dynamic>.of(
          apiFixtureData<Map<String, dynamic>>('song_1975_0130.json'))
        ..remove('title')
        ..['revision'] = 'one';
      expect(contract.validateComponent('Song', song), isNotEmpty);
    });
  });

  group('every field the app reads is declared by the contract', () {
    // What HymnRemoteDataSource.mapSong and the sync code read from a song.
    const songFields = [
      'id',
      'number',
      'title',
      'lyrics',
      'englishTitle',
      'revision',
      'isActive',
      'deletedAt',
      'category.name',
      'category.slug',
      'audio.available',
      'audio.songId',
      'audio.downloadUrl',
      'audio.checksumSha256',
      'audio.sizeBytes',
      'audio.contentType',
      'audio.fileName',
      'audio.source',
      'audio.attribution',
      'sheetMusic.pages.pageNumber',
      'sheetMusic.pages.downloadUrl',
      'sheetMusic.pages.checksumSha256',
      'sheetMusic.pages.sizeBytes',
      'sheetMusic.pages.contentType',
      'sheetMusic.pages.fileName',
      'sheetMusic.pages.borrowedFromVersionCode',
      'otherEditions.songId',
      'otherEditions.number',
      'otherEditions.versionCode',
    ];
    for (final field in songFields) {
      test('Song.$field',
          () => expect(contract.declares('Song', field), isTrue));
    }

    const otherFields = {
      'SyncDelta': [
        'serverTime',
        'hasMore',
        'nextCursor',
        'hymnVersion',
        'changes.songs',
        'changes.audio',
      ],
      'HymnVersionSummary': ['code', 'title', 'versionLabel', 'capabilities'],
      'Manifest': ['release.minimumAppVersion'],
      'SheetMusicPageList': [
        'pages.downloadUrl',
        'pages.checksumSha256',
        'pages.sizeBytes',
        'pages.fileName',
        'pages.contentType',
      ],
      'ErrorEnvelope': ['error.code', 'error.message'],
    };
    otherFields.forEach((schema, fields) {
      for (final field in fields) {
        test('$schema.$field',
            () => expect(contract.declares(schema, field), isTrue));
      }
    });

    // Declared since backend commit 423605f; the app depends on them, so a
    // backend change that drops them must fail here.
    const reliedOn = {
      'HymnVersionSummary': ['contentUpdatedAt'],
      'SyncDelta': ['changes.categories', 'changes.sheetMusicPages'],
    };
    reliedOn.forEach((schema, fields) {
      for (final field in fields) {
        test('$schema.$field (relied on by sync)',
            () => expect(contract.declares(schema, field), isTrue));
      }
    });
  });

  group('recorded responses through the real parsers', () {
    const base = 'https://api.example.test/api/v1';

    test('every sampled 1975 song maps as the app expects', () {
      final sync =
          apiFixtureData<Map<String, dynamic>>('sync_1975_sample.json');
      final songs =
          (sync['changes']['songs'] as List).cast<Map<String, dynamic>>();
      final hymns = {
        for (final song in songs)
          song['number'] as int:
              HymnRemoteDataSource.mapSong(song, 'am-sda-1975'),
      };

      for (final hymn in hymns.values) {
        expect(hymn.id, startsWith('am-sda-1975-'));
        expect(hymn.title, isNotEmpty);
        expect(hymn.lyrics, isNotEmpty);
        expect(hymn.oldHymnalNumber, hymn.number);
        for (final page in hymn.sheetPages ?? const []) {
          expect(page.file.checksumSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
          expect(page.file.url, contains('version=am-sda-1975'));
        }
      }

      // #1 has a recording and 2004's scan.
      expect(hymns[1]!.audioInfo!.isSynthesized, isFalse);
      expect(hymns[1]!.audioInfo!.file.contentType, 'audio/mp4');
      expect(
          hymns[1]!.sheetPages!.first.borrowedFromVersionCode, 'am-sda-2004');
      // #4 borrows 1961's scan and has no audio.
      expect(hymns[4]!.audioInfo, isNull);
      expect(
          hymns[4]!.sheetPages!.first.borrowedFromVersionCode, 'am-sda-1961');
      // #56 is in no scanned book.
      expect(hymns[56]!.sheetPages, isNull);
      expect(hymns[56]!.sheetMusic, isNull);
      // #64 plays a synthesized track and carries its credit.
      expect(hymns[64]!.audioInfo!.isSynthesized, isTrue);
      expect(hymns[64]!.audioInfo!.attribution, isNotEmpty);
      // #130 prints 2004's page and has no recording.
      expect(hymns[130]!.audioUrl, isNull);
      expect(hymns[130]!.sheetPages!.single.file.fileName, '132R.webp');
    });

    test('a recorded sync loads through HymnRemoteDataSource', () async {
      final api = FakeHymnalApi(baseUrl: base)
        ..on('/hymn-versions/am-sda-1975',
            (_) => _recorded('hymn_version_1975.json'))
        ..on('/sync', (_) => _recorded('sync_1975_sample.json'));
      final source = HymnRemoteDataSource(
        baseUrl: base,
        client: api.client,
        store: MemoryEditionStore(),
        mediaCache: MemoryMediaCache(),
      );

      final hymns = await source.getHymns('am', HymnalVersions.sdaOld);

      expect(hymns.map((hymn) => hymn.number), [1, 4, 56, 64, 130]);
    });

    test('the recorded edition list maps to the app\'s books', () async {
      final service = HymnalVersionService(
        baseUrl: base,
        client: FakeHymnalApi(baseUrl: base).client,
      );
      final api = FakeHymnalApi(baseUrl: base)
        ..on('/hymn-versions', (_) => _recorded('hymn_versions.json'));
      final live = HymnalVersionService(baseUrl: base, client: api.client);

      final versions = await live.refresh();

      expect(versions.map((version) => version.id), [
        HymnalVersions.sdaNew,
        HymnalVersions.sdaOld,
        HymnalVersions.sda1961,
        HymnalVersions.hagerigna,
      ]);
      expect(live.hasRemoteCatalog, isTrue);
      service.dispose();
      live.dispose();
    });

    test('recorded song detail gives the other editions\' numbers', () async {
      final api = FakeHymnalApi(baseUrl: base)
        ..on(
            '/songs/am-sda-1975-0130', (_) => _recorded('song_1975_0130.json'));
      final editions =
          await SongEditionsService(baseUrl: base, client: api.client)
              .otherEditions('am-sda-1975-0130');

      expect(
        {for (final edition in editions) edition.versionCode: edition.number},
        {'am-sda-1961': 165, 'am-sda-2004': 132},
      );
    });

    test('the recorded manifest minimum version is enforced', () async {
      final api = FakeHymnalApi(baseUrl: base)
        ..on('/manifest', (_) => _recorded('manifest_2004.json'));
      final minimum =
          (apiFixtureData<Map<String, dynamic>>('manifest_2004.json')['release']
              as Map)['minimumAppVersion'];
      AppUpdateService service(String installed) => AppUpdateService(
            baseUrl: base,
            client: api.client,
            currentVersion: () async => installed,
          );

      // Recorded 2026-09-21: the backend requires 1.0.0.
      expect(minimum, '1.0.0');
      expect(await service('0.9.9').requiredVersion('am-sda-2004'), '1.0.0');
      expect(await service('1.0.0').requiredVersion('am-sda-2004'), isNull);
    });

    test('the recorded page list plans a verified download', () async {
      final api = FakeHymnalApi(baseUrl: base)
        ..on('/downloads/sheet-music/pages',
            (_) => _recorded('sheet_pages_1961_sample.json'));
      final recorded =
          apiFixtureData<Map<String, dynamic>>('sheet_pages_1961_sample.json');

      final plan = await SheetMusicBulkDownloadService(
        baseUrl: base,
        client: api.client,
        cache: MemoryMediaCache(),
      ).plan('am-sda-1961');

      expect(plan.pageCount, 4);
      expect(plan.missingBytes, recorded['totalSizeBytes']);
      expect(plan.missing.every((source) => source.isVerifiable), isTrue);
      expect(plan.missing.every((source) => source.fileExtension == '.webp'),
          isTrue);
    });

    test('recorded errors surface their stable codes', () async {
      final api = FakeHymnalApi(baseUrl: base)
        ..on('/songs/am-sda-2004-9999',
            (_) => _recorded('error_song_not_found.json', 404))
        ..on('/hymn-versions/am-sda-1900',
            (_) => _recorded('error_hymn_version_not_found.json', 404));

      Future<String> codeOf(String path) async {
        final response = await api.client.get(Uri.parse('$base$path'));
        try {
          decodeHymnalApiData(response);
        } on HymnalApiException catch (error) {
          expect(error.statusCode, 404);
          return error.code;
        }
        fail('expected an error');
      }

      expect(await codeOf('/songs/am-sda-2004-9999'), 'SONG_NOT_FOUND');
      expect(
          await codeOf('/hymn-versions/am-sda-1900'), 'HYMN_VERSION_NOT_FOUND');
    });
  });
}
