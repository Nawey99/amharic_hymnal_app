import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
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

  Future<void> pumpPage(WidgetTester tester, {int count = 5}) async {
    await setUpTestApp(content: {'sda_new': sampleHymns(count: count)});
    opened = [];
    final bloc = await pumpInApp(
      tester,
      Scaffold(body: NumberSearchPage(onOpenHymn: opened.add)),
    );
    await loadHymns(tester, bloc);
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
      find.text('ይህ ቁጥር በአሁኑ መዝሙር ስብስብ ውስጥ የለም። እባክዎ ከ1 እስከ 5 ያለ ቁጥር ያስገቡ።'),
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
}
