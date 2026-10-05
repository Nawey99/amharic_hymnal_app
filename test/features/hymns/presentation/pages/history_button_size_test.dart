import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/pages/number_search_page.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_app.dart';

/// The History button once filled its whole side of the title bar, 140 wide
/// and 48 tall, and ran up against the app's name. It is now as wide as its
/// icon and word, drawn shorter than the area that takes the tap.
void main() {
  final pill = find.byKey(const ValueKey('history-pill'));
  final button = find.byKey(const ValueKey('history-button'));
  final title = find.text('ውዳሴ');

  Future<void> pumpPage(
    WidgetTester tester, {
    required Size size,
    Locale locale = const Locale('am'),
    double textScale = 1,
  }) async {
    await setUpTestApp(content: {'sda_new': sampleHymns(count: 5)});
    final bloc = await pumpInApp(
      tester,
      Scaffold(body: NumberSearchPage(onOpenHymn: (_) {})),
      size: size,
      locale: locale,
      textScale: textScale,
    );
    await loadHymns(tester, bloc);
  }

  for (final width in const [320.0, 360.0, 412.0, 600.0, 840.0]) {
    for (final locale in const [Locale('am'), Locale('en')]) {
      testWidgets(
          'at $width wide in ${locale.languageCode} the pill is small and '
          'the tap area is not', (tester) async {
        await pumpPage(tester, size: Size(width, 900), locale: locale);

        final pillSize = tester.getSize(pill);
        expect(pillSize.height, 36);
        // The side of the bar is 140: the pill no longer fills it.
        expect(pillSize.width, lessThan(140));

        final tapArea = tester.getSize(button);
        expect(tapArea.height, greaterThanOrEqualTo(48));
        expect(tapArea.width, greaterThanOrEqualTo(48));

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the pill does not grow with the screen', (tester) async {
    await pumpPage(tester, size: const Size(360, 800));
    final onPhone = tester.getSize(pill);

    await pumpPage(tester, size: const Size(840, 1200));
    expect(tester.getSize(pill), onPhone);
  });

  testWidgets('there is space between the pill and the app name',
      (tester) async {
    await pumpPage(tester, size: const Size(360, 800));

    final gap = tester.getTopLeft(title).dx - tester.getTopRight(pill).dx;
    expect(gap, greaterThanOrEqualTo(8));
  });

  testWidgets('landscape on a phone draws it a little shorter', (tester) async {
    await pumpPage(tester, size: const Size(800, 360));

    expect(tester.getSize(pill).height, 32);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  group('when the word cannot fit, the clock stands alone', () {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('320 wide in English at text scale $scale', (tester) async {
        await pumpPage(
          tester,
          size: const Size(320, 640),
          locale: const Locale('en'),
          textScale: scale,
        );

        // Never a cut-off word: either all of it or none of it.
        final word = find.descendant(
          of: pill,
          matching: find.text('History'),
        );
        if (word.evaluate().isNotEmpty) {
          expect(
            tester.getSize(pill).width,
            lessThanOrEqualTo(tester.getSize(button).width),
          );
        } else {
          final size = tester.getSize(pill);
          expect(size.width, size.height, reason: 'a round icon button');
        }
        expect(find.descendant(of: pill, matching: find.byIcon(Icons.history)),
            findsOneWidget);
        // Still named for a screen reader.
        expect(find.byTooltip('History'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('at a very large text size the word is dropped',
        (tester) async {
      await pumpPage(
        tester,
        size: const Size(320, 640),
        locale: const Locale('en'),
        textScale: 2.0,
      );

      expect(
        find.descendant(of: pill, matching: find.text('History')),
        findsNothing,
      );
    });
  });

  testWidgets('tapping the pill opens History', (tester) async {
    await pumpPage(tester, size: const Size(360, 800));

    await tester.tap(pill);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('history-pill')), findsNothing);
  });
}
