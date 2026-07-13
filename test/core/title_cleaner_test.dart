import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/utils/title_cleaner.dart';

void main() {
  test('cleans noisy English titles without touching meaningful words', () {
    expect(cleanEnglishTitle('  ## Amazing Grace!!  '), 'Amazing Grace');
    expect(cleanEnglishTitle('Song — Title'), 'Song — Title');
    expect(cleanEnglishTitle("Savior's Love (Live)"), "Savior's Love (Live)");
  });

  test('handles empty and Amharic titles safely', () {
    expect(cleanEnglishTitle(null), '');
    expect(cleanEnglishTitle('   '), '');
    expect(cleanEnglishTitle('  አምላካችን  '), 'አምላካችን');
  });
}
