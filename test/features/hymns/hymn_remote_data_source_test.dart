import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';

const _base = 'https://api.example.test/api/v1';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Response _edition(String code, String contentUpdatedAt) => _json({
      'success': true,
      'data': {'code': code, 'contentUpdatedAt': contentUpdatedAt},
    });

http.Response _sync(
  String code,
  List<Map<String, dynamic>> songs, {
  bool hasMore = false,
  String? nextCursor,
  bool isActive = true,
}) =>
    _json({
      'success': true,
      'data': {
        'serverTime': '2026-09-21T12:00:00.000Z',
        'hasMore': hasMore,
        'nextCursor': nextCursor,
        'hymnVersion': {'code': code, 'isActive': isActive},
        'changes': {'songs': songs},
      },
    });

Map<String, dynamic> _song(
  String code,
  int number, {
  String? title,
  int revision = 1,
  String? deletedAt,
}) =>
    {
      'id': '$code-${number.toString().padLeft(4, '0')}',
      'number': number,
      'title': title ?? 'Hymn $number',
      'englishTitle': null,
      'lyrics': 'Lyrics $number',
      'revision': revision,
      'category': null,
      'audio': {'available': false},
      'sheetMusic': {'available': false, 'pageCount': 0, 'pages': []},
      'isActive': true,
      'deletedAt': deletedAt,
    };

void main() {
  test('maps a full API song, including audio and ordered sheet pages', () {
    final hymn = HymnRemoteDataSource.mapSong({
      'id': 'am-sda-1975-0130',
      'number': 130,
      'title': 'ወዳንተ የሱስ ሆይ',
      'englishTitle': 'Longing to be With Jesus',
      'lyrics': 'ወዳንተ የሱስ ሆይ ልቤ ይናፍቃል',
      'category': {'slug': 'prayer', 'name': 'ጸሎት'},
      'audio': {
        'available': true,
        'downloadUrl': '$_base/songs/am-sda-1975-0130/audio/file',
      },
      'sheetMusic': {
        'available': true,
        'pageCount': 2,
        'pages': [
          {'pageNumber': 2, 'downloadUrl': '$_base/p/2'},
          {'pageNumber': 1, 'downloadUrl': '$_base/p/1'},
        ],
      },
    }, 'am-sda-1975');

    expect(hymn.id, 'am-sda-1975-0130');
    expect(hymn.number, 130);
    expect(hymn.title, 'ወዳንተ የሱስ ሆይ');
    expect(hymn.englishTitleOld, 'Longing to be With Jesus');
    expect(hymn.lyrics, 'ወዳንተ የሱስ ሆይ ልቤ ይናፍቃል');
    expect(hymn.category, 'ጸሎት');
    expect(hymn.audioUrl, '$_base/songs/am-sda-1975-0130/audio/file');
    expect(hymn.sheetMusic, ['$_base/p/1', '$_base/p/2']);
    expect(hymn.oldHymnalNumber, 130);
    expect(hymn.newHymnalNumber, isNull);
  });

  test('maps file details, synthesized audio and borrowed pages', () {
    final hymn = HymnRemoteDataSource.mapSong({
      'id': 'am-sda-1975-0130',
      'number': 130,
      'title': 'ወዳንተ የሱስ ሆይ',
      'audio': {
        'available': true,
        'source': 'synthesized',
        'attribution': 'Synthesized from the edition MIDI.',
        'downloadUrl': '$_base/songs/am-sda-1975-0130/audio/file',
        'checksumSha256': 'A' * 64,
        'sizeBytes': 758048,
        'contentType': 'audio/mp4',
        'fileName': '132.m4a',
      },
      'sheetMusic': {
        'available': true,
        'pages': [
          {
            'pageNumber': 1,
            'downloadUrl': '$_base/p/1',
            'checksumSha256': 'b' * 64,
            'sizeBytes': 269036,
            'contentType': 'image/webp',
            'fileName': '132R.webp',
            'borrowedFromVersionCode': 'am-sda-2004',
          },
        ],
      },
    }, 'am-sda-1975');

    final audio = hymn.audioInfo!;
    expect(audio.isSynthesized, isTrue);
    expect(audio.attribution, 'Synthesized from the edition MIDI.');
    expect(audio.file.checksumSha256, 'a' * 64);
    expect(audio.file.sizeBytes, 758048);
    expect(audio.file.contentType, 'audio/mp4');

    final page = hymn.sheetPages!.single;
    expect(page.pageNumber, 1);
    expect(page.borrowedFromVersionCode, 'am-sda-2004');
    expect(page.file.fileName, '132R.webp');
    expect(hymn.sheetMusic, ['$_base/p/1']);
  });

  test('treats a track without a source as a recording', () {
    final hymn = HymnRemoteDataSource.mapSong({
      'id': 'am-sda-2004-0001',
      'number': 1,
      'audio': {'available': true, 'downloadUrl': '$_base/a/1'},
    }, 'am-sda-2004');

    expect(hymn.audioInfo!.isSynthesized, isFalse);
    expect(hymn.audioInfo!.attribution, isNull);
  });

  test('leaves media empty when the API says it is unavailable', () {
    final hymn = HymnRemoteDataSource.mapSong(
      _song('am-hagerigna', 1),
      'am-hagerigna',
    );

    expect(hymn.audioUrl, isNull);
    expect(hymn.sheetMusic, isNull);
    expect(hymn.isHagerigna, isTrue);
  });

  test('loads every sync page for the mapped edition code', () async {
    final requests = <Uri>[];
    final source = HymnRemoteDataSource(
      baseUrl: _base,
      client: MockClient((request) async {
        requests.add(request.url);
        if (request.url.path.endsWith('/hymn-versions/am-sda-1975')) {
          return _edition('am-sda-1975', '2026-09-21T11:00:00.000Z');
        }
        final cursor = request.url.queryParameters['cursor'];
        return cursor == null
            ? _sync('am-sda-1975', [_song('am-sda-1975', 2)],
                hasMore: true, nextCursor: 'next')
            : _sync('am-sda-1975', [_song('am-sda-1975', 1)]);
      }),
    );

    final hymns = await source.getHymns('am', 'sda_old');

    expect(hymns.map((hymn) => hymn.number), [1, 2]);
    final syncs = requests.where((uri) => uri.path.endsWith('/sync')).toList();
    expect(syncs, hasLength(2));
    expect(syncs.first.queryParameters, {
      'language': 'am',
      'version': 'am-sda-1975',
      'since': '1970-01-01T00:00:00.000Z',
      'limit': '500',
    });
    expect(syncs.last.queryParameters['cursor'], 'next');
  });

  test('keeps the newest revision and drops retired songs', () async {
    final source = HymnRemoteDataSource(
      baseUrl: _base,
      client: MockClient((request) async {
        if (request.url.path.contains('/hymn-versions/')) {
          return _edition('am-sda-2004', 't1');
        }
        return _sync('am-sda-2004', [
          _song('am-sda-2004', 1, title: 'New title', revision: 2),
          _song('am-sda-2004', 1, title: 'Old title', revision: 1),
          _song('am-sda-2004', 2, deletedAt: '2026-09-01T00:00:00.000Z'),
        ]);
      }),
    );

    final hymns = await source.getHymns('am', 'sda_new');

    expect(hymns, hasLength(1));
    expect(hymns.single.title, 'New title');
    expect(hymns.single.newHymnalNumber, 1);
  });

  test('refetches an edition only when its change token moves', () async {
    var now = DateTime.utc(2026, 9, 21, 12);
    var token = 't1';
    var syncs = 0;
    final source = HymnRemoteDataSource(
      baseUrl: _base,
      clock: () => now,
      client: MockClient((request) async {
        if (request.url.path.contains('/hymn-versions/')) {
          return _edition('am-sda-2004', token);
        }
        syncs++;
        return _sync('am-sda-2004', [_song('am-sda-2004', 1)]);
      }),
    );

    await source.getHymns('am', 'sda_new');
    await source.getHymns('am', 'sda_new');
    expect(syncs, 1, reason: 'served from memory inside the freshness window');

    now = now.add(const Duration(minutes: 2));
    await source.getHymns('am', 'sda_new');
    expect(syncs, 1, reason: 'token unchanged, so nothing to download');

    now = now.add(const Duration(minutes: 2));
    token = 't2';
    await source.getHymns('am', 'sda_new');
    expect(syncs, 2);
  });

  test('keeps the loaded edition when the API becomes unreachable', () async {
    var now = DateTime.utc(2026, 9, 21, 12);
    var online = true;
    final source = HymnRemoteDataSource(
      baseUrl: _base,
      clock: () => now,
      client: MockClient((request) async {
        if (!online) throw http.ClientException('offline');
        if (request.url.path.contains('/hymn-versions/')) {
          return _edition('am-sda-2004', 't1');
        }
        return _sync('am-sda-2004', [_song('am-sda-2004', 1)]);
      }),
    );

    await source.getHymns('am', 'sda_new');
    online = false;
    now = now.add(const Duration(minutes: 5));

    final hymns = await source.getHymns('am', 'sda_new');
    expect(hymns.single.number, 1);
  });

  test('fails when offline with nothing loaded, so the caller can fall back',
      () async {
    final source = HymnRemoteDataSource(
      baseUrl: _base,
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    expect(
        source.getHymns('am', 'sda_new'), throwsA(isA<http.ClientException>()));
  });

  test('surfaces the API error code', () async {
    final source = HymnRemoteDataSource(
      baseUrl: _base,
      client: MockClient((_) async => _json({
            'success': false,
            'error': {
              'code': 'HYMN_VERSION_NOT_FOUND',
              'message': 'No edition.',
            },
          }, 404)),
    );

    expect(
      source.getHymns('am', 'sda_2019'),
      throwsA(isA<HymnalApiException>()
          .having((e) => e.code, 'code', 'HYMN_VERSION_NOT_FOUND')
          .having((e) => e.statusCode, 'statusCode', 404)),
    );
  });

  test('treats a withdrawn edition as empty', () async {
    final source = HymnRemoteDataSource(
      baseUrl: _base,
      client: MockClient((request) async {
        if (request.url.path.contains('/hymn-versions/')) {
          return _edition('am-sda-1961', 't1');
        }
        return _sync('am-sda-1961', [_song('am-sda-1961', 1)], isActive: false);
      }),
    );

    expect(await source.getHymns('am', 'sda_1960'), isEmpty);
  });
}
