import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/amharic_phonetic_service.dart';
import 'package:amharic_hymnal_app/core/services/search_engine.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/mappers/hymn_mapper.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

import '../helpers/fakes.dart';

/// The bundled catalogue of [version], loaded the way the app loads it when
/// offline on first launch.
Future<List<Hymn>> _bundled(String version) async {
  final offline = HymnRemoteDataSource(
    baseUrl: 'https://api.example.test/api/v1',
    client: MockClient(
        (request) async => throw http.ClientException('offline', request.url)),
    store: MemoryEditionStore(),
    mediaCache: MemoryMediaCache(),
  );
  final source = LocalDataSource(remoteDataSource: offline);
  return HymnMapper.toDomainList(await source.getHymns('am', version));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final engine = SearchEngine();
  late Map<String, List<Hymn>> books;

  setUpAll(() async {
    books = {
      for (final version in ['sda_new', 'sda_old', 'hagerigna'])
        version: await _bundled(version),
    };
  });

  test('every bundled book loads with hymns', () {
    for (final entry in books.entries) {
      expect(entry.value, isNotEmpty, reason: entry.key);
    }
  });

  /// Each hymn with only its own title and lyrics, as the hymnal API supplies
  /// them.
  List<Hymn> ownFieldsOnly(List<Hymn> hymns) => [
        for (final hymn in hymns)
          Hymn(
            id: hymn.id,
            number: hymn.displayNumber,
            title: hymn.displayTitle,
            lyrics: hymn.displayLyrics,
          ),
      ];

  /// Titles whose search does not return that hymn (or a same-titled one)
  /// first.
  List<String> titleMisses(List<Hymn> hymns, String label) {
    final failures = <String>[];
    var searched = 0;
    for (final hymn in hymns) {
      final title = hymn.displayTitle.trim();
      if (title.isEmpty) continue;
      searched++;
      final results = engine.search(hymns: hymns, query: title);
      // Several hymns may share a title; any of them first is correct.
      final first = results.isEmpty ? null : results.first.hymn;
      final ok = first != null &&
          AmharicPhoneticService.normalizeAmharic(first.displayTitle.trim()) ==
              AmharicPhoneticService.normalizeAmharic(title);
      if (!ok) {
        failures.add('#${hymn.displayNumber} "$title" -> '
            '${first == null ? 'no result' : '#${first.displayNumber} "${first.displayTitle}"'}');
      }
    }
    // ignore: avoid_print
    print('$label: ${searched - failures.length}/$searched titles rank 1'
        '${failures.isEmpty ? '' : '\n  ${failures.take(10).join('\n  ')}'}');
    return failures;
  }

  for (final version in ['sda_new', 'sda_old', 'hagerigna']) {
    test('$version: with only its own fields, each title finds its hymn first',
        () {
      expect(titleMisses(ownFieldsOnly(books[version]!), '$version (own)'),
          isEmpty);
    });

    test(
      '$version: searching each bundled title finds that hymn first',
      () {
        expect(titleMisses(books[version]!, version), isEmpty);
      },
    );
  }

  for (final version in ['sda_new', 'sda_old', 'hagerigna']) {
    test('$version: searching each number finds that hymn first', () {
      final hymns = books[version]!;
      for (final hymn in hymns.take(60)) {
        final results =
            engine.search(hymns: hymns, query: '${hymn.displayNumber}');
        expect(results, isNotEmpty, reason: '#${hymn.displayNumber}');
        expect(
          results.first.hymn.displayNumber,
          hymn.displayNumber,
          reason: 'number ${hymn.displayNumber}',
        );
      }
    });
  }

  test('a phrase from inside a verse finds its hymn', () {
    final hymns = books['sda_new']!;
    var checked = 0;
    for (final hymn
        in hymns.where((h) => h.displayLyrics.isNotEmpty).take(40)) {
      final lines = hymn.displayLyrics
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.length >= 12)
          .toList();
      if (lines.length < 2) continue;
      final phrase = lines[1];
      final results = engine.search(hymns: hymns, query: phrase);
      expect(
        results.map((r) => r.hymn.displayNumber),
        contains(hymn.displayNumber),
        reason: '#${hymn.displayNumber} "$phrase"',
      );
      checked++;
    }
    expect(checked, greaterThan(20));
  });

  test('sound-alike spellings find the same hymns', () {
    final hymns = books['sda_new']!;
    const swaps = {'ሰ': 'ሠ', 'ስ': 'ሥ', 'ሀ': 'ሐ', 'ሃ': 'ኃ', 'ጸ': 'ፀ', 'ጽ': 'ፅ'};
    var checked = 0;
    for (final hymn in hymns) {
      final title = hymn.displayTitle.trim();
      final entry =
          swaps.entries.where((e) => title.contains(e.key)).firstOrNull;
      if (entry == null) continue;
      final variant = title.replaceAll(entry.key, entry.value);
      final original = engine
          .search(hymns: hymns, query: title)
          .map((r) => r.hymn.displayNumber)
          .toList();
      final swapped = engine
          .search(hymns: hymns, query: variant)
          .map((r) => r.hymn.displayNumber)
          .toList();
      expect(swapped, original, reason: '"$title" vs "$variant"');
      if (++checked == 25) break;
    }
    expect(checked, greaterThan(5));
  });

  test('an unknown word finds nothing', () {
    expect(
      engine.search(hymns: books['sda_new']!, query: 'zzqxjv'),
      isEmpty,
    );
  });

  // The real 50 ms budget is checked on a phone (integration_test/perf/). On a
  // shared CI machine this only catches a large regression; it measured
  // 34-42 ms alone and ~90 ms with builds running alongside.
  test('a search over a full book stays well under 200 ms', () {
    final hymns = books['sda_new']!;
    final queries = [
      'ኢየሱስ',
      'ፍቅር',
      'ጌታ',
      'Jesus',
      'love',
      '132',
      for (final hymn in hymns.take(14)) hymn.displayTitle,
    ];
    // Warm up once so JIT compilation is not counted.
    engine.search(hymns: hymns, query: queries.first);
    final watch = Stopwatch()..start();
    for (final query in queries) {
      engine.search(hymns: hymns, query: query);
    }
    watch.stop();
    final average = watch.elapsedMicroseconds / queries.length / 1000;
    // ignore: avoid_print
    print('search over ${hymns.length} hymns: '
        '${average.toStringAsFixed(1)} ms average (${queries.length} queries)');
    expect(average, lessThan(200));
  });
}
