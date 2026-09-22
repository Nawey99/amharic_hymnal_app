import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/features/settings/presentation/pages/report_bug_page.dart';

import '../../../../helpers/test_app.dart';

/// IDs deliberately not in the API's `am-...` form, so the page never looks
/// up other editions over the network.
List<HymnModel> _book() => [
      for (var n = 1; n <= 5; n++)
        HymnModel(
          id: 'sda_new-sda-$n',
          number: n,
          title: 'መዝሙር $n',
          lyrics: 'የመዝሙር $n ግጥም',
        ),
    ];

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late HymnsBloc bloc;
  late List<Hymn> changedTo;

  Future<void> openHymn(
    WidgetTester tester,
    int number, {
    Size size = const Size(412, 844),
  }) async {
    await setUpTestApp(content: {'sda_new': _book()});
    changedTo = [];
    final hymn = _book()[number - 1];
    bloc = await pumpInApp(
      tester,
      HymnDetailPage(hymn: hymn, onHymnChanged: changedTo.add),
      size: size,
    );
    bloc.add(LoadHymns('am', 'sda_new', 'number'));
    await _settle(tester);
    // Loading the book refreshes the open hymn; only count swipes.
    changedTo.clear();
  }

  Future<void> swipe(WidgetTester tester, double dx) async {
    await tester.fling(
      find.byType(HymnDetailPage).first,
      Offset(dx, 0),
      1500,
    );
    await _settle(tester);
  }

  group('swiping', () {
    testWidgets('left opens the next hymn', (tester) async {
      await openHymn(tester, 2);
      expect(find.text('- 2 -'), findsOneWidget);

      await swipe(tester, -300);

      expect(find.text('- 3 -'), findsOneWidget);
      expect(find.text('- 2 -'), findsNothing);
      expect(changedTo.last.number, 3);
    });

    testWidgets('right opens the previous hymn', (tester) async {
      await openHymn(tester, 3);

      await swipe(tester, 300);

      expect(find.text('- 2 -'), findsOneWidget);
    });

    testWidgets('right on the first hymn stays put', (tester) async {
      await openHymn(tester, 1);

      await swipe(tester, 300);

      expect(find.text('- 1 -'), findsOneWidget);
      expect(changedTo, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('left on the last hymn says there is no next one',
        (tester) async {
      await openHymn(tester, 5);

      await swipe(tester, -300);

      expect(find.text('- 5 -'), findsOneWidget);
      expect(find.text('መዝሙር #6 አልተገኘም'), findsOneWidget);
    });
  });

  testWidgets('opening a hymn records it in history for its book',
      (tester) async {
    await openHymn(tester, 4);

    final entries = HistoryService.getHistoryEntries();
    expect(entries.first.hymnNumber, 4);
    expect(entries.first.version, 'sda_new');
  });

  group('report a problem', () {
    testWidgets('the flag button opens the report screen for this hymn',
        (tester) async {
      await openHymn(tester, 2);

      await tester.tap(find.byTooltip('ስህተት ሪፖርት'));
      await _settle(tester);

      final page = tester.widget<ReportBugPage>(find.byType(ReportBugPage));
      expect(page.hymn?.number, 2);
    });

    testWidgets('on a narrow phone it is in the overflow menu', (tester) async {
      await openHymn(tester, 2, size: const Size(360, 740));
      expect(find.byTooltip('ስህተት ሪፖርት'), findsNothing);

      await tester.tap(find.byTooltip('ተጨማሪ'));
      await _settle(tester);
      await tester.tap(find.text('ስህተት ሪፖርት'));
      await _settle(tester);

      expect(find.byType(ReportBugPage), findsOneWidget);
    });
  });

  group('share', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async {
          calls.add(call);
          return 'dev.fluttercommunity.plus/share/unavailable';
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      );
    });

    testWidgets('shares the title and lyrics', (tester) async {
      await openHymn(tester, 2);

      await tester.tap(find.byTooltip('አጋራ'));
      await _settle(tester);

      expect(calls, isNotEmpty);
      final text = (calls.first.arguments as Map)['text'] as String;
      expect(text, 'መዝሙር 2\n\nየመዝሙር 2 ግጥም');
    });
  });
}
