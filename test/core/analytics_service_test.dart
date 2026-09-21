import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/analytics_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

const _base = 'https://api.example.test/api/v1';

void main() {
  late List<http.Request> sent;
  late AnalyticsService analytics;

  setUp(() {
    sent = [];
    analytics = AnalyticsService(
      baseUrl: _base,
      enabled: true,
      client: MockClient((request) async {
        sent.add(request);
        return http.Response('{"success":true,"data":{"accepted":true}}', 202);
      }),
    );
  });

  test('counts a hymn opened, with its edition and where it was opened',
      () async {
    await analytics.hymnOpened(
      const Hymn(id: 'am-sda-1975-0130', number: 130),
      'sda_old',
      HymnOpenSource.favorites,
    );

    final request = sent.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/api/v1/analytics/events');
    expect(request.url.queryParameters['version'], 'am-sda-1975');
    expect(jsonDecode(request.body), {
      'eventType': 'SONG_VIEW',
      'songId': 'am-sda-1975-0130',
      'metadata': {'source': 'favorites'},
    });
  });

  test('does not count bundled hymns the server does not know', () async {
    await analytics.hymnOpened(
      const Hymn(id: 'sda-12', number: 12),
      'sda_new',
      HymnOpenSource.catalog,
    );
    await analytics.hymnOpened(
      const Hymn(id: 'am-sda-2004-0012', number: 12),
      'sda_old',
      HymnOpenSource.catalog,
    );

    expect(sent, isEmpty);
  });

  test('counts a category by its slug', () async {
    await analytics.categoryOpened('sda_1960', 'the-christian-living');
    await analytics.categoryOpened('sda_1960', null);

    expect(sent, hasLength(1));
    expect(sent.single.url.queryParameters['version'], 'am-sda-1961');
    expect(jsonDecode(sent.single.body), {
      'eventType': 'CATEGORY_VIEW',
      'metadata': {'category': 'the-christian-living'},
    });
  });

  test('never throws when the server cannot be reached', () async {
    final offline = AnalyticsService(
      baseUrl: _base,
      enabled: true,
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      offline.categoryOpened('sda_new', 'praise'),
      completes,
    );
  });

  test('sends nothing when disabled', () async {
    final disabled = AnalyticsService(
      baseUrl: _base,
      enabled: false,
      client: MockClient((request) async {
        sent.add(request);
        return http.Response('', 202);
      }),
    );

    await disabled.categoryOpened('sda_new', 'praise');
    expect(sent, isEmpty);
  });
}
