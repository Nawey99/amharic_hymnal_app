import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/services/edition_categories_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

const _base = 'https://api.example.test/api/v1';

Hymn _hymn(int number, String? category) => Hymn(
      id: 'am-sda-1961-${number.toString().padLeft(4, '0')}',
      number: number,
      title: 'Hymn $number',
      category: category,
    );

http.Response _categories(List<Map<String, Object?>> data) => http.Response(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('group', () {
    test('uses the edition\'s own categories, in the book\'s order', () {
      final groups = EditionCategoriesService.group(
        [
          _hymn(24, 'የክርስቲያን ሕይወት'),
          _hymn(1, 'ምስጋና'),
          _hymn(2, 'ምስጋና'),
          _hymn(90, null),
        ],
        const [
          EditionCategory(slug: 'praise', name: 'ምስጋና', sortOrder: 0),
          EditionCategory(
            slug: 'the-christian-living',
            name: 'የክርስቲያን ሕይወት',
            sortOrder: 5,
          ),
        ],
      );

      expect(groups.map((group) => group.name), ['ምስጋና', 'የክርስቲያን ሕይወት']);
      expect(groups.first.slug, 'praise');
      expect(groups.first.hymns.map((hymn) => hymn.number), [1, 2]);
      expect(groups.last.slug, 'the-christian-living');
    });

    test('orders by lowest hymn number before the list has loaded', () {
      final groups = EditionCategoriesService.group(
        [_hymn(40, 'B'), _hymn(3, 'A'), _hymn(12, 'B')],
        const [],
      );

      expect(groups.map((group) => group.name), ['A', 'B']);
      expect(groups.last.hymns.map((hymn) => hymn.number), [12, 40]);
      expect(groups.first.slug, isNull);
    });
  });

  test('loads an edition\'s categories and keeps them for offline use',
      () async {
    final requests = <Uri>[];
    var online = true;
    final client = MockClient((request) async {
      requests.add(request.url);
      if (!online) throw http.ClientException('offline');
      return _categories([
        {'slug': 'praise', 'name': 'ምስጋና', 'sortOrder': 0, 'songCount': 19},
      ]);
    });

    final service = EditionCategoriesService(client: client, baseUrl: _base);
    final loaded = await service.load('sda_1960');

    expect(requests.single.path, '/api/v1/categories');
    expect(requests.single.queryParameters['version'], 'am-sda-1961');
    expect(loaded.single.slug, 'praise');
    expect(service.slugFor('sda_1960', 'ምስጋና'), 'praise');

    online = false;
    final offline = EditionCategoriesService(client: client, baseUrl: _base);
    final stored = await offline.load('sda_1960');
    expect(stored.single.name, 'ምስጋና');
  });

  test('has no categories for an edition it cannot reach', () async {
    final service = EditionCategoriesService(
      client: MockClient((_) async => throw http.ClientException('offline')),
      baseUrl: _base,
    );

    expect(await service.load('sda_old'), isEmpty);
  });
}
