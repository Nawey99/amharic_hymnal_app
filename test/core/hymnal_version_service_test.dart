import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';

Map<String, dynamic> _edition(String code, String title, String label) => {
      'code': code,
      'title': title,
      'versionLabel': label,
      'languageCode': 'am',
      'capabilities': {'songs': true},
      'contentUpdatedAt': '2026-09-21T11:39:04.463Z',
    };

void main() {
  test('loads editions from the hymnal API in the app order', () async {
    final service = HymnalVersionService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/hymn-versions');
        expect(request.url.queryParameters, {'language': 'am'});
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'success': true,
            'data': [
              _edition(
                  'am-sda-2004', 'Amharic Adventist Hymnal (2004)', '2004'),
              _edition(
                  'am-sda-1961', 'Amharic Adventist Hymnal (1961)', '1961'),
              _edition(
                  'am-sda-2019', 'Amharic Adventist Hymnal (2019)', '2019'),
              _edition(
                  'am-sda-1975', 'Amharic Adventist Hymnal (1975)', '1975'),
              _edition('am-hagerigna', 'Hagerigna Hymnal', 'hagerigna'),
            ],
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final versions = await service.refresh();

    expect(versions.map((version) => version.id), [
      HymnalVersions.sdaNew,
      HymnalVersions.sdaOld,
      HymnalVersions.sda1961,
      HymnalVersions.hagerigna,
      'sda_2019',
    ]);
    expect(versions[1].label, 'የ1975 ውዳሴ መዝሙር');
    expect(versions[2].label, 'የ1961 ውዳሴ መዝሙር');
    expect(versions[4].label, 'የ2019 ውዳሴ መዝሙር');
    expect(versions[4].shortLabel, '2019 ውዳሴ');
    expect(versions[4].hasCategories, isTrue);
    expect(versions[3].isSda, isFalse);
    expect(service.hasRemoteCatalog, isTrue);
    service.dispose();
  });

  test('marks a hymnal that is still being prepared', () async {
    final service = HymnalVersionService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode({
              'success': true,
              'data': [
                {
                  ..._edition(
                      'am-sda-2019', 'Amharic Adventist Hymnal (2019)', '2019'),
                  'capabilities': {'songs': false},
                },
              ],
            })),
            200,
          )),
    );

    final versions = await service.refresh();

    expect(versions.single.label, 'የ2019 ውዳሴ መዝሙር (በዝግጅት ላይ)');
    expect(versions.single.shortLabel, '2019 ውዳሴ (በዝግጅት ላይ)');
    service.dispose();
  });

  test('keeps bundled versions when version discovery is unavailable',
      () async {
    final service = HymnalVersionService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((request) async => http.Response(
            '{"success":false,"error":{"code":"DATABASE_UNAVAILABLE","message":"down"}}',
            503,
          )),
    );

    final versions = await service.refresh();

    expect(versions, HymnalVersions.all);
    expect(service.hasRemoteCatalog, isFalse);
    expect(service.lastError, isNotNull);
    service.dispose();
  });
}
