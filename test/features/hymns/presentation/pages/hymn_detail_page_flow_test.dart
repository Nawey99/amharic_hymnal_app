import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/core/widgets/app_bottom_navigation_bar.dart';
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

  /// A drag of [offset] in many small steps, as a finger reading down a
  /// page moves: each frame travels a little, and it ends without a flick.
  Future<void> dragSlowly(WidgetTester tester, Offset offset) async {
    const steps = 40;
    // Over the player card above the lyrics: no scroll view takes the drag
    // there, so the page's own swipe gesture is all that is listening.
    final page = tester.getRect(find.byType(HymnDetailPage).first);
    final gesture = await tester.startGesture(
      Offset(page.center.dx, page.top + page.height * 0.16),
    );
    for (var step = 0; step < steps; step++) {
      await gesture.moveBy(offset / steps.toDouble());
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.up();
    await _settle(tester);
  }

  Future<void> swipe(WidgetTester tester, double dx) async {
    await tester.fling(
      find.byType(HymnDetailPage).first,
      Offset(dx, 0),
      1500,
    );
    await _settle(tester);
  }

  group('what counts as a swipe between hymns', () {
    test('a sideways run, at least twice as far as any up or down', () {
      expect(isHymnSwipe(const Offset(-60, 10)), isTrue);
      expect(isHymnSwipe(const Offset(60, -10)), isTrue);
    });

    test('scrolling the lyrics is not, however far it drifts sideways', () {
      expect(isHymnSwipe(const Offset(30, -300)), isFalse);
      expect(isHymnSwipe(const Offset(-40, 120)), isFalse,
          reason: 'a diagonal drag belongs to the lyrics');
      expect(isHymnSwipe(const Offset(20, 0)), isFalse,
          reason: 'too short to mean anything');
    });
  });

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

    testWidgets('scrolling a short hymn up and down stays on it',
        (tester) async {
      await openHymn(tester, 2);

      await dragSlowly(tester, const Offset(0, -260)); // up
      await dragSlowly(tester, const Offset(0, 240)); // back down
      await dragSlowly(tester, const Offset(-30, -260)); // up, drifting

      expect(find.text('- 2 -'), findsOneWidget);
      expect(changedTo, isEmpty);
    });

    testWidgets('a scroll that starts with a thumb arc stays on the hymn',
        (tester) async {
      await openHymn(tester, 2);
      final page = tester.getRect(find.byType(HymnDetailPage).first);

      // A thumb pivots sideways before it travels up the page. That first
      // sideways move used to mark the whole drag as a swipe.
      final gesture = await tester.startGesture(
        Offset(page.center.dx, page.top + page.height * 0.7),
      );
      for (final step in const [Offset(20, -1), Offset(18, -2)]) {
        await gesture.moveBy(step);
        await tester.pump(const Duration(milliseconds: 16));
      }
      for (var up = 0; up < 8; up++) {
        await gesture.moveBy(const Offset(-1, -50));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await _settle(tester);

      expect(find.text('- 2 -'), findsOneWidget);
      expect(changedTo, isEmpty);
    });

    testWidgets('a sideways drag released without a flick stays put',
        (tester) async {
      await openHymn(tester, 2);

      await dragSlowly(tester, const Offset(-200, 0));

      expect(find.text('- 2 -'), findsOneWidget);
      expect(changedTo, isEmpty);
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
      expect(find.text('መዝሙር ቁጥር 6 አልተገኘም'), findsOneWidget);
    });
  });

  testWidgets('swiping to another hymn is not closing the page',
      (tester) async {
    await setUpTestApp(content: {'sda_new': _book()});
    var closed = 0;
    bloc = await pumpInApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HymnDetailPage(
                  hymn: _book()[1],
                  onClosed: () => closed++,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    bloc.add(LoadHymns('am', 'sda_new', 'number'));
    await _settle(tester);
    await tester.tap(find.text('open'));
    await _settle(tester);

    await swipe(tester, -300);
    expect(find.text('- 3 -'), findsOneWidget);
    expect(closed, 0, reason: 'the next hymn replaces the page');

    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(find.byType(HymnDetailPage), findsNothing);
    expect(closed, 1, reason: 'back closes it');
  });

  group('the end of the lyrics clears the bottom bar', () {
    final longHymn = Hymn(
      id: 'sda_new-sda-99',
      number: 99,
      title: 'ረጅም መዝሙር',
      lyrics: [for (var line = 1; line <= 40; line++) 'መስመር $line']
          .join(String.fromCharCode(10)),
    );

    /// Scrolls to the end and returns the gap between the last line and the
    /// top of the floating bar.
    Future<double> gapBelowLastLine(WidgetTester tester) async {
      final scrollable = find
          .descendant(
            of: find.byType(SingleChildScrollView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      final position = tester.state<ScrollableState>(scrollable).position;
      while (position.pixels < position.maxScrollExtent) {
        position.jumpTo(position.maxScrollExtent);
        await _settle(tester);
      }

      final lyrics = tester.getRect(find.byType(SelectableText));
      final bar = tester.getRect(find.byType(AppBottomNavigationBar));
      return bar.top - lyrics.bottom;
    }

    // The two ends of what a reader can choose, so raising the maximum
    // is checked for overflow rather than assumed safe.
    for (final fontSize in [
      AppConstants.minFontSize,
      AppConstants.maxFontSize,
    ]) {
      testWidgets('at size ${fontSize.toInt()} on a small screen',
          (tester) async {
        await setUpTestApp(content: {'sda_new': _book()});
        FontSizeService().initialize(fontSize);
        changedTo = [];
        bloc = await pumpInApp(
          tester,
          HymnDetailPage(hymn: longHymn, onHymnChanged: changedTo.add),
          size: const Size(360, 640),
        );
        bloc.add(LoadHymns('am', 'sda_new', 'number'));
        await _settle(tester);

        expect(await gapBelowLastLine(tester), greaterThanOrEqualTo(0));
      });
    }

    testWidgets('and with the phone text size raised too', (tester) async {
      await setUpTestApp(content: {'sda_new': _book()});
      FontSizeService().initialize(AppConstants.maxFontSize);
      changedTo = [];
      bloc = await pumpInApp(
        tester,
        HymnDetailPage(hymn: longHymn, onHymnChanged: changedTo.add),
        size: const Size(360, 640),
        textScale: 1.6,
      );
      bloc.add(LoadHymns('am', 'sda_new', 'number'));
      await _settle(tester);

      expect(await gapBelowLastLine(tester), greaterThanOrEqualTo(0));
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

      await tester.tap(find.byTooltip('የስህተት ጥቆማ'));
      await _settle(tester);

      final page = tester.widget<ReportBugPage>(find.byType(ReportBugPage));
      expect(page.hymn?.number, 2);
    });

    testWidgets('on a narrow phone it is in the overflow menu', (tester) async {
      await openHymn(tester, 2, size: const Size(360, 740));
      expect(find.byTooltip('የስህተት ጥቆማ'), findsNothing);

      await tester.tap(find.byTooltip('ተጨማሪ'));
      await _settle(tester);
      await tester.tap(find.text('የስህተት ጥቆማ'));
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
