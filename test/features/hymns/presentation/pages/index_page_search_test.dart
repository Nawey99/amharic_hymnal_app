import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/index_page.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/list_page_helpers.dart';
import '../../../../helpers/test_app.dart';

const _noHymnsFound = 'ምንም መዝሙር አልተገኘም';

// Sort, scrubber and section behaviour are in index_page_scroller_test.
void main() {
  late List<Hymn> opened;
  late FakeHymnLocalDataSource source;

  Future<HymnsBloc> pumpIndex(
    WidgetTester tester, {
    bool load = true,
    Object? loadError,
  }) async {
    source = await setUpTestApp(content: {
      'sda_new': [
        listHymn(1, title: 'አምላካችን'),
        listHymn(2, title: 'ቅዱስ ቅዱስ'),
        listHymn(3, title: 'ጸጋው ድንቅ ነው'),
      ],
    });
    source.error = loadError;
    opened = [];
    final bloc = await pumpInApp(
      tester,
      Scaffold(body: IndexPage(onOpenHymn: opened.add)),
    );
    if (load) await loadHymns(tester, bloc);
    return bloc;
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), query);
    // SearchStateController debounces by 350 ms.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('lists every hymn before searching', (tester) async {
    await pumpIndex(tester);

    expect(find.text('አምላካችን'), findsOneWidget);
    expect(find.text('ቅዱስ ቅዱስ'), findsOneWidget);
    expect(find.text('ጸጋው ድንቅ ነው'), findsOneWidget);
  });

  testWidgets('search icon reveals the search field', (tester) async {
    await pumpIndex(tester);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('መዝሙር ይፈልጉ...'), findsOneWidget);
  });

  testWidgets('searching by title narrows the list', (tester) async {
    final bloc = await pumpIndex(tester);

    await search(tester, 'ቅዱስ');

    expect((bloc.state as HymnsLoaded).sortType, 'search');
    expect(find.text('ቅዱስ ቅዱስ'), findsOneWidget);
    expect(find.text('አምላካችን'), findsNothing);
  });

  testWidgets('a search that matches nothing says so', (tester) async {
    await pumpIndex(tester);

    await search(tester, 'zzzqqq');

    expect(find.text(_noHymnsFound), findsOneWidget);
  });

  testWidgets('clearing the search restores the full list', (tester) async {
    final bloc = await pumpIndex(tester);
    await search(tester, 'ቅዱስ');

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect((bloc.state as HymnsLoaded).sortType, 'number');
    expect(find.text('አምላካችን'), findsOneWidget);
    expect(find.text('ጸጋው ድንቅ ነው'), findsOneWidget);
  });

  testWidgets('tapping a search result opens it', (tester) async {
    await pumpIndex(tester);
    await search(tester, 'ጸጋው');

    await tester.tap(find.text('ጸጋው ድንቅ ነው'));
    await tester.pump();

    expect(opened.single.number, 3);
  });

  testWidgets('an empty book says there are no hymns', (tester) async {
    await setUpTestApp(content: {'sda_new': []});
    final bloc = await pumpInApp(tester, const Scaffold(body: IndexPage()));
    await loadHymns(tester, bloc);

    expect(find.text(_noHymnsFound), findsOneWidget);
  });

  testWidgets('shows the error when hymns cannot be loaded', (tester) async {
    await pumpIndex(tester, loadError: Exception('broken'));

    expect(find.text(loadErrorMessage), findsOneWidget);
  });
}
