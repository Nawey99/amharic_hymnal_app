import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/alphabet_scroll_bar.dart';

void main() {
  test('alphabet scrollbar contains only groups that have hymns', () {
    final visible = AlphabetScrollBar.visibleLetters(['አ', 'ለ', 'መ']);

    expect(visible, containsAllInOrder(['ለ', 'መ']));
    expect(visible, contains('አ'));
    expect(visible, isNot(contains('በ')));
    expect(visible, isNot(contains('ዘ')));
  });

  testWidgets('alphabet scrollbar is fixed, not internally scrollable',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            AlphabetScrollBar(
              letters: const ['አ', 'ለ', 'መ', 'ሰ'],
              onLetterSelected: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
