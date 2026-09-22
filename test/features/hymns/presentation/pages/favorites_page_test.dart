import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/favorites_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

import '../../../../helpers/fakes.dart';
import '../../../../helpers/list_page_helpers.dart';
import '../../../../helpers/test_app.dart';

const _noFavoritesYet = 'እስካሁን ምንም ተወዳጆች የሉም';
const _noFavoritesFound = 'ምንም ተወዳጆች አልተገኙም';

void main() {
  late List<Hymn> opened;
  late FakeHymnLocalDataSource source;

  /// Sets up the app, marks [favorites] in sda_new (and [oldFavorites] in
  /// sda_old), then pumps the page.
  Future<HymnsBloc> pumpFavorites(
    WidgetTester tester, {
    List<int> favorites = const [],
    List<int> oldFavorites = const [],
    bool load = true,
  }) async {
    source = await setUpTestApp(content: {
      'sda_new': sampleHymns(count: 5),
      'sda_old': sampleHymns(count: 5, prefix: 'am-sda-1975'),
    });
    final settings = di.sl<SettingsRepository>();
    await settings.setSelectedVersion('sda_old');
    for (final n in oldFavorites) {
      await settings.toggleFavorite(n);
    }
    await settings.setSelectedVersion('sda_new');
    for (final n in favorites) {
      await settings.toggleFavorite(n);
    }

    opened = [];
    final bloc = await pumpInApp(
      tester,
      Scaffold(body: FavoritesPage(onOpenHymn: opened.add)),
    );
    if (load) await loadHymns(tester, bloc);
    return bloc;
  }

  testWidgets('shows a spinner before hymns are loaded', (tester) async {
    await pumpFavorites(tester, load: false);

    expect(spinner, findsOneWidget);
  });

  testWidgets('says there are no favourites yet', (tester) async {
    await pumpFavorites(tester);

    expect(find.text(_noFavoritesYet), findsOneWidget);
  });

  testWidgets('lists only favourites of the current edition, in order',
      (tester) async {
    await pumpFavorites(tester, favorites: [4, 2], oldFavorites: [3]);

    expect(find.text('መዝሙር 2'), findsOneWidget);
    expect(find.text('መዝሙር 4'), findsOneWidget);
    expect(find.text('መዝሙር 3'), findsNothing);
    expect(topOf(tester, 'መዝሙር 2'), lessThan(topOf(tester, 'መዝሙር 4')));
  });

  testWidgets('removing the last favourite shows the empty state',
      (tester) async {
    final bloc = await pumpFavorites(tester, favorites: [2]);
    expect(find.text('መዝሙር 2'), findsOneWidget);

    bloc.add(ToggleFavorite(2));
    await tester.pumpAndSettle();

    expect(find.text('መዝሙር 2'), findsNothing);
    expect(find.text(_noFavoritesYet), findsOneWidget);
    expect(di.sl<SettingsRepository>().isFavorite(2), isFalse);
  });

  testWidgets('adding a favourite shows it straight away', (tester) async {
    final bloc = await pumpFavorites(tester, favorites: [2]);

    bloc.add(ToggleFavorite(5));
    await tester.pumpAndSettle();

    expect(find.text('መዝሙር 5'), findsOneWidget);
    expect(find.text('መዝሙር 2'), findsOneWidget);
  });

  testWidgets('search narrows the favourites by number', (tester) async {
    await pumpFavorites(tester, favorites: [2, 3]);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('መዝሙር 3'), findsOneWidget);
    expect(find.text('መዝሙር 2'), findsNothing);
  });

  testWidgets('a search with no matching favourite says so', (tester) async {
    await pumpFavorites(tester, favorites: [2]);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text(_noFavoritesFound), findsOneWidget);
  });

  testWidgets('closing search shows every favourite again', (tester) async {
    await pumpFavorites(tester, favorites: [2, 3]);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('መዝሙር 2'), findsOneWidget);
    expect(find.text('መዝሙር 3'), findsOneWidget);
  });

  testWidgets('tapping a favourite opens that hymn', (tester) async {
    await pumpFavorites(tester, favorites: [4]);

    await tester.tap(find.text('መዝሙር 4'));
    await tester.pump();

    expect(opened.single.number, 4);
  });

  testWidgets('shows the error when hymns cannot be loaded', (tester) async {
    final bloc = await pumpFavorites(tester, favorites: [2], load: false);
    source.error = Exception('broken');

    await loadHymns(tester, bloc);

    expect(find.text(loadErrorMessage), findsOneWidget);
  });
}
