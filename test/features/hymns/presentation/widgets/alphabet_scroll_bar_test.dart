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
    final selectedLabels = <String>[];
    const labels = ['አ', 'ለ', 'መ', 'ሰ'];
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            AlphabetScrollBar(
              availableLabels: labels,
              onLetterSelected: selectedLabels.add,
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

    for (final label in labels) {
      await tester.tap(find.text(label));
      await tester.pump();
      expect(selectedLabels.last, label);
    }
  });

  testWidgets('vertical rail fits Samsung-height constraints without overflow',
      (tester) async {
    final labels = amharicFidelIndexOrder.take(25).toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: const ValueKey('samsung-height-host'),
              width: 360,
              height: 554,
              child: Stack(
                children: [
                  AlphabetScrollBar(
                    availableLabels: labels,
                    bottomPadding: 8,
                    onLetterSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final rail = find.byKey(const ValueKey('alphabet-vertical-rail'));
    expect(rail, findsOneWidget);
    expect(tester.takeException(), isNull);

    final hostRect = tester.getRect(
      find.byKey(const ValueKey('samsung-height-host')),
    );
    expect(tester.getRect(rail).bottom, lessThanOrEqualTo(hostRect.bottom - 8));
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
    Future<Set<String>> verifyVisibleLetters() async {
      final verified = <String>{};
      for (final label in amharicFidelIndexOrder) {
        final visibleLabel = find.text(label).hitTestable();
        if (visibleLabel.evaluate().isEmpty) continue;
        final center = tester.getCenter(visibleLabel);
        if (!railRect.contains(center)) continue;

        await tester.tapAt(center);
        await tester.pump();
        expect(selectedLabels.last, label);
        verified.add(label);
      }
      return verified;
    }

    final initiallyVerified = await verifyVisibleLetters();
    expect(initiallyVerified.length, greaterThan(3));

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

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();
    final scrolledVerified = await verifyVisibleLetters();
    expect(scrolledVerified.difference(initiallyVerified), isNotEmpty);
  });

  testWidgets('active letter glides smoothly to the rail center',
      (tester) async {
    final targetLabel = amharicFidelIndexOrder[12];
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
                    activeLabel: targetLabel,
                    useHorizontalLayout: true,
                    onLetterSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    final rail = find.byKey(const ValueKey('alphabet-horizontal-rail'));
    final target = find.text(targetLabel);
    final railCenterX = tester.getCenter(rail).dx;
    final initialDistance = (tester.getCenter(target).dx - railCenterX).abs();

    await tester.pump(const Duration(milliseconds: 90));
    final midwayDistance = (tester.getCenter(target).dx - railCenterX).abs();
    await tester.pumpAndSettle();
    final finalDistance = (tester.getCenter(target).dx - railCenterX).abs();

    expect(midwayDistance, lessThan(initialDistance));
    expect(finalDistance, lessThan(midwayDistance));
    expect(finalDistance, lessThan(1));
  });

  testWidgets('every horizontal letter returns itself across the full rail',
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
                    useHorizontalLayout: true,
                    onLetterSelected: selectedLabels.add,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final rail = find.byKey(const ValueKey('alphabet-horizontal-rail'));
    final railRect = tester.getRect(rail);
    final verifiedLabels = <String>{};

    for (var page = 0; page < 8; page++) {
      for (final label in amharicFidelIndexOrder) {
        final visibleLabel = find.text(label).hitTestable();
        if (visibleLabel.evaluate().isEmpty) continue;
        final center = tester.getCenter(visibleLabel);
        if (!railRect.contains(center)) continue;

        await tester.tapAt(center);
        await tester.pump();
        expect(selectedLabels.last, label);
        verifiedLabels.add(label);
      }

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
    }

    expect(verifiedLabels, containsAll(amharicFidelIndexOrder));
  });
}
