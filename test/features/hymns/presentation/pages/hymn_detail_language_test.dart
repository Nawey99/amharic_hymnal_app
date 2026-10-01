import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_app.dart';

/// The hymn page reads in the app's language, like every other page.
///
/// It used to be the one place that did not: it carried its own hardcoded
/// Amharic, including its own copies of the five tab labels, so opening a
/// hymn in an English app flipped the whole bottom bar back to Amharic.
void main() {
  Future<void> openHymnIn(WidgetTester tester, Locale locale) async {
    await setUpTestApp(content: {'sda_new': sampleHymns(count: 5)});
    final hymn = sampleHymns(count: 5).first;
    final bloc = await pumpInApp(
      tester,
      HymnDetailPage(hymn: hymn, sourceDestination: 'number'),
      locale: locale,
    );
    addTearDown(bloc.close);
    bloc.add(LoadHymns('am', 'sda_new', 'number'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('the tabs under a hymn are English when the app is',
      (tester) async {
    await openHymnIn(tester, const Locale('en'));

    for (final label in ['Index', 'Number', 'Favourites', 'Settings']) {
      expect(find.text(label), findsWidgets, reason: '$label is missing');
    }
    // The five labels this page used to keep its own Amharic copies of.
    for (final amharic in ['ማውጫ', 'ቁጥር', 'ተወዳጅ', 'ቅንብሮች']) {
      expect(find.text(amharic), findsNothing,
          reason: '$amharic survived into the English app');
    }
  });

  testWidgets('and Amharic when the app is', (tester) async {
    await openHymnIn(tester, const Locale('am'));

    for (final label in ['ማውጫ', 'ቁጥር', 'ተወዳጅ', 'ቅንብሮች']) {
      expect(find.text(label), findsWidgets, reason: '$label is missing');
    }
    expect(find.text('Index'), findsNothing);
  });

  testWidgets('the hymn itself stays as it is written', (tester) async {
    await openHymnIn(tester, const Locale('en'));

    // The book's words are the book's, whichever language the app speaks.
    final hymn = sampleHymns(count: 5).first;
    expect(find.text(hymn.displayLyrics), findsOneWidget);
  });
}
