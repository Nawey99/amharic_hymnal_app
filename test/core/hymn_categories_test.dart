import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';

void main() {
  test('canonical SDA categories cover 1 through 325 without gaps', () {
    expect(HymnCategories.all, hasLength(31));
    expect(HymnCategories.validate(), isEmpty);
    expect(HymnCategories.getAllCoveredNumbers(), hasLength(325));
  });

  test('category lookup returns expected range names', () {
    expect(HymnCategories.getCategoryByNumber(1)?.nameAmharic, 'ምስጋና');
    expect(HymnCategories.getCategoryByNumber(325)?.nameAmharic, 'መሰናበቻ');
    expect(HymnCategories.getCategoryByNumber(326), isNull);
  });
}
