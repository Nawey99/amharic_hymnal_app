import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

void main() {
  test('normalizes legacy hymnal id to new SDA hymnal', () {
    expect(HymnalVersions.normalizeId('hymnal'), HymnalVersions.sdaNew);
    expect(HymnalVersions.normalizeId('sda_new'), HymnalVersions.sdaNew);
    expect(HymnalVersions.normalizeId('sda_old'), HymnalVersions.sdaOld);
  });

  test('identifies SDA category support', () {
    expect(HymnalVersions.hasCategories(HymnalVersions.sdaNew), isTrue);
    expect(HymnalVersions.hasCategories(HymnalVersions.sdaOld), isTrue);
    expect(HymnalVersions.hasCategories(HymnalVersions.hagerigna), isFalse);
  });
}
