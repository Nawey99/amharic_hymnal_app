import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/core/widgets/main_page_title_bar.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/number_search_page.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_app.dart';

Finder get _numberField => find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.keyboardType == TextInputType.number,
    );

Future<void> _enterAndOpen(WidgetTester tester, String text) async {
  await tester.enterText(_numberField, text);
  await tester.tap(find.text('ክፈት'));
  await tester.pump();
}

void main() {
  late List<Hymn> opened;

  Future<void> pumpPage(
    WidgetTester tester, {
    int count = 5,
    Listenable? reveals,
  }) async {
    await setUpTestApp(content: {'sda_new': sampleHymns(count: count)});
    opened = [];
    final bloc = await pumpInApp(
      tester,
      Scaffold(
        body: NumberSearchPage(
          onOpenHymn: opened.add,
          revealRequests: reveals,
        ),
      ),
    );
    await loadHymns(tester, bloc);
  }

  /// What the field is showing.
  String numberText(WidgetTester tester) =>
      tester.widget<TextField>(_numberField).controller!.text;

  bool numberHasFocus(WidgetTester tester) =>
      tester.widget<TextField>(_numberField).focusNode!.hasFocus;

  /// Leaving the field, as tapping elsewhere on the page does.
  Future<void> leaveTheField(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  testWidgets('opens the hymn with the entered number', (tester) async {
    await pumpPage(tester);

    await _enterAndOpen(tester, '3');

    expect(opened.single.number, 3);
    expect(opened.single.title, 'መዝሙር 3');
  });

  testWidgets('asks for a number when the field is empty', (tester) async {
    await pumpPage(tester);

    await _enterAndOpen(tester, '');

    expect(find.text('እባክዎ የመዝሙር ቁጥር ያስገቡ።'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('rejects a number outside the book and names the range',
      (tester) async {
    await pumpPage(tester, count: 5);

    await _enterAndOpen(tester, '6');

    expect(
      find.text('ይህ ቁጥር በአሁኑ የመዝሙር ስብስብ ውስጥ የለም። እባክዎ ከ1 እስከ 5 ያለ ቁጥር ያስገቡ።'),
      findsOneWidget,
    );
    expect(opened, isEmpty);
  });

  testWidgets('rejects zero', (tester) async {
    await pumpPage(tester);

    await _enterAndOpen(tester, '0');

    expect(opened, isEmpty);
    expect(find.text('እባክዎ ትክክለኛ የመዝሙር ቁጥር ያስገቡ'), findsOneWidget);
  });

  testWidgets('clears the message as soon as the number changes',
      (tester) async {
    await pumpPage(tester);
    await _enterAndOpen(tester, '');
    expect(find.text('እባክዎ የመዝሙር ቁጥር ያስገቡ።'), findsOneWidget);

    await tester.enterText(_numberField, '2');
    await tester.pump();

    expect(find.text('እባክዎ የመዝሙር ቁጥር ያስገቡ።'), findsNothing);
  });

  testWidgets('accepts digits only', (tester) async {
    await pumpPage(tester);

    await tester.enterText(_numberField, '1a2-');
    await tester.pump();

    expect(tester.widget<TextField>(_numberField).controller!.text, '12');
  });

  /// The title bar gives its sides a fixed width so the title stays
  /// centred. English set in the serif face is wider than the Amharic it
  /// replaces, and the History pill ran over the end by 1.2 pixels.
  group('the header holds its shape', () {
    for (final locale in const [Locale('am'), Locale('en')]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('in ${locale.languageCode} at text scale $scale',
            (tester) async {
          await setUpTestApp(content: {'sda_new': sampleHymns(count: 5)});
          final bloc = await pumpInApp(
            tester,
            Scaffold(body: NumberSearchPage(onOpenHymn: (_) {})),
            size: const Size(360, 640),
            textScale: scale,
            locale: locale,
          );
          await loadHymns(tester, bloc);

          expect(tester.takeException(), isNull, reason: 'nothing overflows');
        });
      }
    }

    /// Not overflowing is not enough: "Histo..." is not a label. The pill
    /// has to be wide enough for the whole word at the ordinary text size.
    testWidgets('the History label is not cut short in English',
        (tester) async {
      await setUpTestApp(content: {'sda_new': sampleHymns(count: 5)});
      final bloc = await pumpInApp(
        tester,
        Scaffold(body: NumberSearchPage(onOpenHymn: (_) {})),
        size: const Size(360, 640),
        locale: const Locale('en'),
      );
      await loadHymns(tester, bloc);

      final label = tester.renderObject<RenderParagraph>(find.text('History'));
      expect(label.didExceedMaxLines, isFalse,
          reason: 'the whole word fits in the pill');
    });
  });

  /// The reader comes to this page to type a number. Whatever number is
  /// already in the box is the one they just finished with, so meeting them
  /// with it costs two taps to delete before they can start.
  group('the field is empty whenever it is arrived at', () {
    testWidgets('opening a hymn empties the box behind it', (tester) async {
      await pumpPage(tester);

      await _enterAndOpen(tester, '3');

      expect(opened.single.number, 3);
      expect(numberText(tester), isEmpty);
    });

    testWidgets('touching the field clears a number left in it',
        (tester) async {
      await pumpPage(tester);
      await tester.enterText(_numberField, '3');
      await leaveTheField(tester);
      expect(numberText(tester), '3', reason: 'still there once left alone');

      await tester.tap(_numberField);
      await tester.pumpAndSettle();

      expect(numberText(tester), isEmpty);
    });

    testWidgets('a tap while typing leaves what is being typed alone',
        (tester) async {
      await pumpPage(tester);
      await tester.tap(_numberField);
      await tester.pumpAndSettle();
      await tester.enterText(_numberField, '12');

      // Reaching in to move the caret, not arriving at the field.
      await tester.tap(_numberField);
      await tester.pumpAndSettle();

      expect(numberText(tester), '12');
    });

    testWidgets('being arrived at empties the field and takes focus',
        (tester) async {
      final reveals = ValueNotifier<int>(0);
      addTearDown(reveals.dispose);
      await pumpPage(tester, reveals: reveals);
      await tester.enterText(_numberField, '3');
      await leaveTheField(tester);
      expect(numberHasFocus(tester), isFalse);

      reveals.value++;
      await tester.pumpAndSettle();

      expect(numberText(tester), isEmpty);
      // Focus is what raises the keyboard, so the reader can type at once.
      expect(numberHasFocus(tester), isTrue);
    });

    testWidgets('a search in progress is left undisturbed', (tester) async {
      final reveals = ValueNotifier<int>(0);
      addTearDown(reveals.dispose);
      await pumpPage(tester, reveals: reveals);
      await tester.enterText(_numberField, '3');
      await leaveTheField(tester);

      await tester.tap(find.byTooltip('ፈልግ'));
      await tester.pumpAndSettle();
      final searchField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.keyboardType != TextInputType.number,
      );
      expect(searchField, findsOneWidget, reason: 'the search field opened');
      await tester.enterText(searchField, 'መዝሙር');
      await tester.pumpAndSettle();

      reveals.value++;
      await tester.pumpAndSettle();

      // Searching means the number input is not what the reader is looking
      // at, so their number must not be taken away behind the results, nor
      // the keyboard pulled over to a field they did not ask for.
      expect(numberText(tester), '3');
      expect(numberHasFocus(tester), isFalse);
    });
  });

  // The CI emulator's screen: the title bar is 264 wide. Its two sides were
  // 140 each (room for "History" in the serif face), 16 more than fit, so
  // every full-app test failed on the overflow.
  for (final locale in const [Locale('en'), Locale('am')]) {
    testWidgets('the title bar fits a 320-wide phone in ${locale.languageCode}',
        (tester) async {
      await setUpTestApp(content: {'sda_new': sampleHymns(count: 5)});
      final bloc = await pumpInApp(
        tester,
        Scaffold(body: NumberSearchPage(onOpenHymn: (_) {})),
        locale: locale,
        size: const Size(320, 640),
      );
      await loadHymns(tester, bloc);

      // The bar's row is the width CI's emulator gave it.
      expect(tester.getSize(find.byType(MainPageTitleBar)).width, 320);
      expect(tester.takeException(), isNull);
      expect(find.byTooltip(locale.languageCode == 'en' ? 'History' : 'ታሪክ'),
          findsOneWidget);
    });
  }
}
