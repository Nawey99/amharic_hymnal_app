import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/history_page.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/list_page_helpers.dart';
import '../../../../helpers/test_app.dart';

const _noHistory = 'እስካሁን ታሪክ የለም';
const _noHistoryInBook = 'በዚህ መዝሙር ስብስብ ታሪክ የለም';

void main() {
  late List<Hymn> opened;
  late FakeHymnLocalDataSource source;

  /// Opens [entries] (version, number) oldest first, then pumps the page,
  /// which loads the selected edition itself.
  Future<void> pumpHistory(
    WidgetTester tester, {
    List<(String, int)> entries = const [],
    Object? loadError,
  }) async {
    source = await setUpTestApp(content: {
      'sda_new': sampleHymns(count: 5),
      'sda_old': sampleHymns(count: 5, prefix: 'am-sda-1975'),
    });
    source.error = loadError;
    await HistoryService.init();
    for (final (version, number) in entries) {
      await HistoryService.addToHistory(number, version: version);
    }

    opened = [];
    await pumpInApp(tester, HistoryPage(onOpenHymn: opened.add));
    await tester.pumpAndSettle();
  }

  testWidgets('says there is no history yet', (tester) async {
    await pumpHistory(tester);

    expect(find.text(_noHistory), findsOneWidget);
  });

  testWidgets('lists the most recently opened hymn first', (tester) async {
    await pumpHistory(tester, entries: [
      ('sda_new', 1),
      ('sda_new', 3),
      ('sda_new', 2),
    ]);

    expect(topOf(tester, 'መዝሙር 2'), lessThan(topOf(tester, 'መዝሙር 3')));
    expect(topOf(tester, 'መዝሙር 3'), lessThan(topOf(tester, 'መዝሙር 1')));
  });

  testWidgets('re-opening a hymn moves it back to the top', (tester) async {
    await pumpHistory(tester, entries: [
      ('sda_new', 1),
      ('sda_new', 2),
      ('sda_new', 1),
    ]);

    expect(find.text('መዝሙር 1'), findsOneWidget);
    expect(topOf(tester, 'መዝሙር 1'), lessThan(topOf(tester, 'መዝሙር 2')));
  });

  testWidgets('shows only the current edition', (tester) async {
    await pumpHistory(tester, entries: [
      ('sda_old', 4),
      ('sda_new', 2),
    ]);

    expect(find.text('መዝሙር 2'), findsOneWidget);
    expect(find.text('መዝሙር 4'), findsNothing);
  });

  testWidgets('says so when only other editions have history', (tester) async {
    await pumpHistory(tester, entries: [('sda_old', 4)]);

    expect(find.text(_noHistoryInBook), findsOneWidget);
  });

  testWidgets('clearing asks first, then empties the history', (tester) async {
    await pumpHistory(tester, entries: [('sda_new', 2)]);

    await tester.tap(find.byTooltip('ታሪክን አጽዳ'));
    await tester.pumpAndSettle();
    expect(find.text('የተከፈቱ መዝሙሮች ታሪክ በሙሉ ይጠፋ?'), findsOneWidget);

    await tester.tap(find.text('አጽዳ'));
    await tester.pumpAndSettle();

    expect(find.text(_noHistory), findsOneWidget);
    expect(HistoryService.getHistoryEntries(), isEmpty);
  });

  testWidgets('cancelling the clear keeps the history', (tester) async {
    await pumpHistory(tester, entries: [('sda_new', 2)]);

    await tester.tap(find.byTooltip('ታሪክን አጽዳ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ይቅር'));
    await tester.pumpAndSettle();

    expect(find.text('መዝሙር 2'), findsOneWidget);
    expect(HistoryService.getHistoryEntries(), hasLength(1));
  });

  testWidgets('swiping an entry away removes only that entry', (tester) async {
    await pumpHistory(tester, entries: [
      ('sda_new', 1),
      ('sda_new', 2),
    ]);

    await tester.drag(find.text('መዝሙር 2'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('መዝሙር 2'), findsNothing);
    expect(find.text('መዝሙር 1'), findsOneWidget);
    expect(
      HistoryService.getHistoryEntries().map((entry) => entry.hymnNumber),
      [1],
    );
  });

  testWidgets('tapping an entry opens that hymn', (tester) async {
    await pumpHistory(tester, entries: [('sda_new', 3)]);

    await tester.tap(find.text('መዝሙር 3'));
    await tester.pump();

    expect(opened.single.number, 3);
  });

  testWidgets('shows the error when hymns cannot be loaded', (tester) async {
    await pumpHistory(
      tester,
      entries: [('sda_new', 2)],
      loadError: Exception('broken'),
    );

    expect(find.text(loadErrorMessage), findsOneWidget);
  });
}
