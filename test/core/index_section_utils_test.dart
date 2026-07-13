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
    final order = numericRangeOrderForMax(325);
    final available = {'1-50': 0, '151-200': 3, '301-325': 8};

    expect(nearestSectionIndex('151-200', order, available), 3);
    expect(nearestSectionIndex('51-100', order, available), 3);
    expect(nearestSectionIndex('251-300', order, available), 8);
    expect(nearestSectionIndex('1-50', order, available), 0);
  });

  test('builds numeric hymn jump ranges instead of digit buckets', () {
    expect(numericRangeOrderForMax(325), const [
      '1-50',
      '51-100',
      '101-150',
      '151-200',
      '201-250',
      '251-300',
      '301-325',
    ]);

    expect(numericRangeLabelForNumber(1, 325), '1-50');
    expect(numericRangeLabelForNumber(50, 325), '1-50');
    expect(numericRangeLabelForNumber(51, 325), '51-100');
    expect(numericRangeLabelForNumber(325, 325), '301-325');
  });

  test('empty section index is safe', () {
    expect(nearestSectionIndex('1-50', numericRangeOrderForMax(325), const {}),
        isNull);
    expect(
      buildSectionIndex<String>(
          const [], (item) => item, numericSectionForText),
      isEmpty,
    );
    expect(buildNumericRangeIndex<String>(const [], (item) => 0), isEmpty);
  });
}
