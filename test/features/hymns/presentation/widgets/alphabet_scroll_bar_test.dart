import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/utils/index_section_utils.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/alphabet_scroll_bar.dart';

void main() {
  test('alphabet scrollbar contains only groups that have hymns', () {
    final visible = AlphabetScrollBar.visibleLetters(['አ', 'ለ', 'መ']);

    expect(visible, containsAllInOrder(['ለ', 'መ']));
    expect(visible, contains('አ'));
    expect(visible, isNot(contains('በ')));
    expect(visible, isNot(contains('ዘ')));
  });

  test('horizontal fallback is used only when vertical labels do not fit', () {
    expect(
      IndexedFastScroller.shouldUseHorizontalLayout(
        labelCount: 4,
        availableHeight: 400,
      ),
      isFalse,
    );
    expect(
      IndexedFastScroller.shouldUseHorizontalLayout(
        labelCount: amharicFidelIndexOrder.length,
        availableHeight: 240,
      ),
      isTrue,
    );
  });

  testWidgets('alphabet scrollbar stays vertical when all labels fit',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            AlphabetScrollBar(
              availableLabels: const ['አ', 'ለ', 'መ', 'ሰ'],
              onLetterSelected: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('alphabet-vertical-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('alphabet-horizontal-rail')),
      findsNothing,
    );
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('horizontal rail scrubs letters immediately without a modal',
      (tester) async {
    final selectedLabels = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 180,
              child: Stack(
                children: [
                  AlphabetScrollBar(
                    availableLabels: amharicFidelIndexOrder,
                    onLetterSelected: selectedLabels.add,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final horizontalRail =
        find.byKey(const ValueKey('alphabet-horizontal-rail'));
    expect(horizontalRail, findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    final railRect = tester.getRect(horizontalRail);
    final gesture = await tester.startGesture(
      Offset(railRect.left + 18, railRect.center.dy),
    );
    await tester.pump();

    expect(selectedLabels, isNotEmpty);
    final firstSelected = selectedLabels.last;
    expect(
      find.byKey(const ValueKey('fast-scroller-selection-bubble')),
      findsOneWidget,
    );

    await gesture.moveTo(
      Offset(railRect.right - 18, railRect.center.dy),
    );
    await tester.pump();
    expect(selectedLabels.last, isNot(firstSelected));

    await gesture.up();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('fast-scroller-selection-bubble')),
      findsNothing,
    );
  });
}
