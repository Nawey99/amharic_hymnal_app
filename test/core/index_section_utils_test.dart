import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/utils/index_section_utils.dart';

void main() {
  test('maps Ethiopic syllables to base Fidel sections', () {
    expect(amharicSectionForText('ሙሉ'), 'መ');
    expect(amharicSectionForText('ስም'), 'ሰ');
    expect(amharicSectionForText('ቫን'), 'ቨ');
    expect(amharicSectionForText('እናት'), 'አ');
    expect(amharicSectionForText('ፓስታ'), 'ፐ');
    expect(amharicSectionForText('123'), '#');
    expect(amharicSectionForText(''), '#');
  });

  test('maps numeric sections by first meaningful digit', () {
    expect(numericSectionForText('0 Apple'), '0');
    expect(numericSectionForText('123 Main Street'), '1');
    expect(numericSectionForText('2500'), '2');
    expect(numericSectionForText('9Lives'), '9');
    expect(numericSectionForText('(456) 789-0000'), '4');
    expect(numericSectionForText('+251 911 123 456'), '2');
    expect(numericSectionForText('ABC'), '#');
    expect(numericSectionForText(''), '#');
  });

  test('nearest section falls forward, then backward', () {
    final available = {'1': 0, '4': 3, '9': 8};

    expect(nearestSectionIndex('4', numericIndexOrder, available), 3);
    expect(nearestSectionIndex('2', numericIndexOrder, available), 3);
    expect(nearestSectionIndex('8', numericIndexOrder, available), 8);
    expect(nearestSectionIndex('0', numericIndexOrder, available), 0);
  });

  test('empty section index is safe', () {
    expect(nearestSectionIndex('1', numericIndexOrder, const {}), isNull);
    expect(
      buildSectionIndex<String>(
          const [], (item) => item, numericSectionForText),
      isEmpty,
    );
  });
}
