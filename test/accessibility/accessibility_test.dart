// Accessibility guidelines on the main screens: tap targets big enough for
// fingers (48×48 on Android, 44×44 on iOS), every tappable control labelled
// for TalkBack/VoiceOver, and readable text contrast.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/pages/favorites_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/index_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/number_search_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/settings_page.dart';

import '../helpers/fakes.dart';
import '../helpers/test_app.dart';

final _screens = <String, Widget Function()>{
  'number search': () => const Scaffold(body: NumberSearchPage()),
  'index': () => const Scaffold(body: IndexPage()),
  'favorites': () => const Scaffold(body: FavoritesPage()),
  'settings': () => const Scaffold(body: SettingsPage()),
  'hymn detail': () => HymnDetailPage(hymn: sampleHymns().first),
};

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await setUpTestApp(prefs: {
    'favorite_hymns_v2': <String>['sda_new:1']
  });
  final bloc = await pumpInApp(tester, screen);
  await loadHymns(tester, bloc);
}

void main() {
  for (final entry in _screens.entries) {
    group(entry.key, () {
      testWidgets('tap targets meet the Android size guideline',
          (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpScreen(tester, entry.value());
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('tap targets meet the iOS size guideline', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpScreen(tester, entry.value());
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('every tappable control has a label', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpScreen(tester, entry.value());
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('text has enough contrast', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpScreen(tester, entry.value());
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    });
  }
}
