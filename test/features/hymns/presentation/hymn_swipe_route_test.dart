import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_swipe_route.dart';

/// Turning back through the book has to look like turning back.
///
/// The swipe used to push a plain MaterialPageRoute, which animates the
/// same way whichever way the hand went: swiping right to the previous
/// hymn looked identical to swiping left to the next one.
void main() {
  /// Where the arriving hymn sits, part-way through the transition, as a
  /// fraction of the screen width. Negative is off to the left, positive
  /// off to the right, zero is settled in place.
  Future<double> arrivingFrom(WidgetTester tester,
      {required bool forward}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                hymnSwipeRoute<void>(
                  forward: forward,
                  page: const Scaffold(body: Text('the next hymn')),
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();
    // Part-way in, while it is still travelling.
    await tester.pump(hymnSwipeDuration ~/ 4);

    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final x = tester.getTopLeft(find.text('the next hymn')).dx;
    await tester.pumpAndSettle();

    // Back to the button, so a second measurement in the same test has
    // something to tap.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    return x / width;
  }

  testWidgets('the next hymn comes in from the right', (tester) async {
    final offset = await arrivingFrom(tester, forward: true);

    expect(offset, greaterThan(0.05),
        reason: 'swiping left onwards: the page arrives from the right');
  });

  testWidgets('the previous hymn comes in from the left', (tester) async {
    final offset = await arrivingFrom(tester, forward: false);

    expect(offset, lessThan(-0.05),
        reason: 'swiping right back: the page arrives from the left');
  });

  testWidgets('the two directions are mirror images, not the same motion',
      (tester) async {
    final next = await arrivingFrom(tester, forward: true);
    final previous = await arrivingFrom(tester, forward: false);

    // This is the bug itself: they used to be identical.
    expect(next.sign, isNot(previous.sign));
    expect(next.abs(), closeTo(previous.abs(), 0.02));
  });

  testWidgets('it settles flush with the screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                hymnSwipeRoute<void>(
                  forward: true,
                  page: const Scaffold(body: Text('the next hymn')),
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('the next hymn')).dx, 0);
  });
}
