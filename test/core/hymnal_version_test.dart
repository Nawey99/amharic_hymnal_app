import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

void main() {
  test('normalizes legacy hymnal id to the 2004 SDA hymnal', () {
    expect(HymnalVersions.normalizeId('hymnal'), HymnalVersions.sdaNew);
    expect(HymnalVersions.normalizeId('sda_new'), HymnalVersions.sdaNew);
    expect(HymnalVersions.normalizeId('sda_old'), HymnalVersions.sdaOld);
    expect(HymnalVersions.normalizeId('sda_1960'), HymnalVersions.sda1961);
    expect(HymnalVersions.normalizeId('sda_2019'), 'sda_2019');
    expect(HymnalVersions.normalizeId('../invalid'), HymnalVersions.sdaNew);
  });

  test('exposes corrected SDA edition labels in display order', () {
    expect(
      HymnalVersions.all.map((version) => version.label),
      [
        'የ2004 ውዳሴ መዝሙር',
        'የ1975 ውዳሴ መዝሙር',
        'የ1961 ውዳሴ መዝሙር',
        'የሀገርኛ መዝሙር',
      ],
    );
  });

  test('identifies SDA category support', () {
    expect(HymnalVersions.hasCategories(HymnalVersions.sdaNew), isTrue);
    expect(HymnalVersions.hasCategories(HymnalVersions.sdaOld), isTrue);
    expect(HymnalVersions.hasCategories(HymnalVersions.sda1961), isTrue);
    expect(HymnalVersions.hasCategories(HymnalVersions.hagerigna), isFalse);
    expect(HymnalVersions.hasCategories('sda_2019'), isTrue);
  });

  test('maps local edition IDs to hymnal API codes and back', () {
    const pairs = {
      HymnalVersions.sdaNew: 'am-sda-2004',
      HymnalVersions.sdaOld: 'am-sda-1975',
      HymnalVersions.sda1961: 'am-sda-1961',
      HymnalVersions.hagerigna: 'am-hagerigna',
      'sda_2019': 'am-sda-2019',
    };
    pairs.forEach((id, code) {
      expect(HymnalVersions.apiCode(id), code);
      expect(HymnalVersions.fromApiCode(code), id);
    });
    expect(HymnalVersions.apiCode('hymnal'), 'am-sda-2004');
    expect(HymnalVersions.fromApiCode('am-../x'), isNull);
  });
}
