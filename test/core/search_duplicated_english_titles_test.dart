import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/search_engine.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/mappers/hymn_mapper.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

import '../helpers/fakes.dart';

/// Several English titles are shared across different Amharic hymns
/// (the audit at 2026-09-29 found five such strings in the bundled JSON:
/// `Holy Holy Holy`, `Majestic Sweetness Sits Enthroned`,
/// `I Will Follow Thee`, `We Thank Thee`, and — across editions — a
/// couple more).
///
/// When the reader types one of these into search, several hymns
/// legitimately match. The top result must be **deterministic** so a
/// reviewer can reproduce screenshots and the reader is not surprised
/// by re-ordering between builds. The choice made here: the top hit is
/// the hymn with the smaller number.
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
  late List<Hymn> newBook;
  late List<Hymn> oldBook;

  setUpAll(() async {
    newBook = await _bundled('sda_new');
    oldBook = await _bundled('sda_old');
  });

  /// A duplicated English title is deterministic if the top result is
  /// the hymn with the smaller number, and every hymn whose English
  /// title matches is in the result set.
  void expectDeterministic(
    List<Hymn> hymns,
    String query,
    List<int> expectedNumbers,
  ) {
    final results = engine.search(hymns: hymns, query: query);
    final numbersInOrder = results.map((r) => r.hymn.displayNumber).toList();

    expect(
      numbersInOrder.isNotEmpty,
      isTrue,
      reason: '"$query" returned nothing at all',
    );
    // Every expected hymn is present.
    for (final n in expectedNumbers) {
      expect(
        numbersInOrder,
        contains(n),
        reason: '"$query" should have found hymn #$n',
      );
    }
    // The first result is the smallest expected number.
    final expectedFirst = expectedNumbers.reduce((a, b) => a < b ? a : b);
    expect(
      numbersInOrder.first,
      expectedFirst,
      reason: '"$query" should list hymn #$expectedFirst first, but got '
          '#${numbersInOrder.first}. Duplicated English titles must sort '
          'stably (smallest number first) so screenshots and links do not '
          'drift between builds.',
    );
  }

  test(
      '2004: "Holy Holy Holy" lists both hymns starting with the smaller '
      'number', () {
    // 2004 hymns #2 and #3 share this English title.
    expectDeterministic(newBook, 'Holy Holy Holy', [2, 3]);
  });

  test('2004: "Majestic Sweetness Sits Enthroned" is deterministic', () {
    // 2004 indices 6 and 74 (i.e. hymn numbers 7 and 75).
    expectDeterministic(newBook, 'Majestic Sweetness Sits Enthroned', [7, 75]);
  });

  test('2004: "I Will Follow Thee" is deterministic', () {
    // Indices 122 and 268 → hymn numbers 123 and 269.
    expectDeterministic(newBook, 'I Will Follow Thee', [123, 269]);
  });

  test('1975: "We Thank Thee" is deterministic', () {
    // Indices 12 and 249 → hymn numbers 13 and 250.
    expectDeterministic(oldBook, 'We Thank Thee', [13, 250]);
  });

  test('1975: "I Will Follow Thee" is deterministic', () {
    // Indices 124 and 268 → hymn numbers 125 and 269.
    expectDeterministic(oldBook, 'I Will Follow Thee', [125, 269]);
  });
}
