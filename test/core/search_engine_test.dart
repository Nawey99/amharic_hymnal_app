import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/search_engine.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

void main() {
  test('number matches rank before lyric-only matches', () {
    final engine = SearchEngine();
    final results = engine.search(
      hymns: const [
        Hymn(
          id: 'lyrics',
          number: 10,
          title: 'Other',
          lyrics: 'This lyric mentions 42 in the body',
        ),
        Hymn(
          id: 'number',
          number: 42,
          title: 'Target',
          lyrics: 'Simple lyric',
        ),
      ],
      query: '42',
    );

    expect(results.first.hymn.displayNumber, 42);
    expect(results.first.matchType, MatchType.number);
  });

  test('version-specific title is preferred for display and title search', () {
    final hymn = const Hymn(
      id: 'merged',
      number: 7,
      title: 'Old Display Title',
      newHymnalTitle: 'New Title',
      oldHymnalTitle: 'Old Display Title',
      oldHymnalNumber: 12,
      newHymnalNumber: 7,
    );

    expect(hymn.displayTitle, 'Old Display Title');

    final results = SearchEngine().search(
      hymns: [hymn],
      query: '12',
    );

    expect(results.single.matchType, MatchType.number);
  });

  test('title matches rank before lyric-only matches', () {
    final results = SearchEngine().search(
      hymns: const [
        Hymn(
          id: 'lyrics',
          number: 2,
          title: 'Different Hymn',
          lyrics: 'The word revival appears only in these lyrics.',
        ),
        Hymn(
          id: 'title',
          number: 9,
          title: 'Revival Song',
          englishTitleOld: 'Revival Song',
          lyrics: 'Different text',
        ),
      ],
      query: 'revival',
    );

    expect(results.first.hymn.displayNumber, 9);
    expect(results.first.matchType, MatchType.partialTitle);
  });
}
