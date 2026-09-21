import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';

void main() {
  test('reads other editions from song detail and caches them', () async {
    var requests = 0;
    final service = SongEditionsService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((request) async {
        requests++;
        expect(request.url.path, '/api/v1/songs/am-sda-1975-0130');
        expect(request.url.queryParameters,
            {'language': 'am', 'version': 'am-sda-1975'});
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'success': true,
            'data': {
              'id': 'am-sda-1975-0130',
              'otherEditions': [
                {
                  'songId': 'am-sda-2004-0132',
                  'number': 132,
                  'versionCode': 'am-sda-2004',
                },
              ],
            },
          })),
          200,
        );
      }),
    );

    final editions = await service.otherEditions('am-sda-1975-0130');
    await service.otherEditions('am-sda-1975-0130');

    expect(editions.single.number, 132);
    expect(editions.single.versionCode, 'am-sda-2004');
    expect(requests, 1);
  });

  test('retries after a failure instead of caching it', () async {
    var online = false;
    final service = SongEditionsService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((_) async {
        if (!online) throw http.ClientException('offline');
        return http.Response(
            '{"success":true,"data":{"otherEditions":[]}}', 200);
      }),
    );

    await expectLater(
      service.otherEditions('am-sda-1975-0130'),
      throwsA(isA<http.ClientException>()),
    );
    online = true;
    expect(await service.otherEditions('am-sda-1975-0130'), isEmpty);
  });

  test('extracts the edition code from a song ID', () {
    expect(
        SongEditionsService.versionCodeOf('am-sda-1975-0130'), 'am-sda-1975');
    expect(
        SongEditionsService.versionCodeOf('am-hagerigna-0001'), 'am-hagerigna');
    expect(SongEditionsService.versionCodeOf('plain'), isNull);
  });
}
