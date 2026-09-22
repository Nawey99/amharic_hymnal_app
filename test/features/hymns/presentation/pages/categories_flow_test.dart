import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/categories_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/category_hymns_page.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/list_page_helpers.dart';
import '../../../../helpers/test_app.dart';

// The category list comes from the hymns themselves; the order service
// (EditionCategoriesService) is asked over HTTP, which flutter_test answers
// with 400 without touching the network, so it falls back to what is stored.

final _sdaHymns = [
  listHymn(1, category: 'ምስጋና'),
  listHymn(2, category: 'ምስጋና'),
  listHymn(3, category: 'ጸሎት'),
  listHymn(4),
];

void main() {
  late List<Hymn> opened;
  late FakeHymnLocalDataSource source;

  Future<void> pumpCategories(
    WidgetTester tester, {
    Map<String, List<HymnModel>>? content,
    String version = 'sda_new',
    Map<String, Object> prefs = const {},
    bool load = true,
    Object? loadError,
  }) async {
    source = await setUpTestApp(
      content: content ?? {'sda_new': _sdaHymns},
      version: version,
      prefs: prefs,
    );
    source.error = loadError;
    opened = [];
    final bloc = await pumpInApp(
      tester,
      CategoriesPage(onOpenHymn: opened.add),
    );
    if (load) await loadHymns(tester, bloc, version: version);
  }

  testWidgets('before hymns load, points to the SDA books', (tester) async {
    await pumpCategories(tester, load: false);
    expect(find.text('ምድቦች ለአድቬንቲስት መዝሙር ብቻ ይገኛሉ'), findsOneWidget);
  });

  testWidgets('lists the categories the hymns belong to, in book order',
      (tester) async {
    await pumpCategories(tester);

    expect(find.text('ምስጋና'), findsOneWidget);
    expect(find.text('ጸሎት'), findsOneWidget);
    expect(topOf(tester, 'ምስጋና'), lessThan(topOf(tester, 'ጸሎት')));
  });

  testWidgets('opening a category lists only its hymns', (tester) async {
    await pumpCategories(tester);

    await tester.tap(find.text('ምስጋና'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryHymnsPage), findsOneWidget);
    expect(find.text('መዝሙር 1'), findsOneWidget);
    expect(find.text('መዝሙር 2'), findsOneWidget);
    expect(find.text('መዝሙር 3'), findsNothing);
    expect(find.text('መዝሙር 4'), findsNothing);
  });

  testWidgets('back returns from a category to the list', (tester) async {
    await pumpCategories(tester);
    await tester.tap(find.text('ጸሎት'));
    await tester.pumpAndSettle();

    // The back button's tooltip is Amharic (ተመለስ), so pageBack() misses it.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryHymnsPage), findsNothing);
    expect(find.text('ምስጋና'), findsOneWidget);
  });

  testWidgets('tapping a hymn in a category opens it', (tester) async {
    await pumpCategories(tester);
    await tester.tap(find.text('ጸሎት'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('መዝሙር 3'));
    await tester.pump();

    expect(opened.single.number, 3);
  });

  testWidgets('says so when no hymn has a category', (tester) async {
    await pumpCategories(
      tester,
      content: {
        'sda_new': [listHymn(1), listHymn(2)],
      },
    );

    expect(find.text('ምድቦች አልተገኙም'), findsOneWidget);
  });

  testWidgets('Hagerigna has no categories; it lists authors instead',
      (tester) async {
    await pumpCategories(
      tester,
      version: 'hagerigna',
      content: {
        'hagerigna': [
          listHymn(1, artist: 'ዘማሪ ሀ', prefix: 'am-hagerigna'),
          listHymn(2, artist: 'ዘማሪ ለ', prefix: 'am-hagerigna'),
          listHymn(3, artist: 'ዘማሪ ሀ', prefix: 'am-hagerigna'),
        ],
      },
    );

    expect(find.text('ዘማሪ ሀ'), findsOneWidget);
    expect(find.text('ዘማሪ ለ'), findsOneWidget);

    await tester.tap(find.text('ዘማሪ ሀ'));
    await tester.pumpAndSettle();

    expect(find.text('ደራሲ፦ ዘማሪ ሀ'), findsOneWidget);
    expect(find.text('መዝሙር 1'), findsOneWidget);
    expect(find.text('መዝሙር 3'), findsOneWidget);
    expect(find.text('መዝሙር 2'), findsNothing);
  });

  testWidgets('Hagerigna without authors says so', (tester) async {
    await pumpCategories(
      tester,
      version: 'hagerigna',
      content: {
        'hagerigna': [listHymn(1, prefix: 'am-hagerigna')],
      },
    );

    expect(find.text('ደራሲዎች አልተገኙም'), findsOneWidget);
  });

  testWidgets('shows the error when hymns cannot be loaded', (tester) async {
    await pumpCategories(tester, loadError: Exception('broken'));

    expect(find.text(loadErrorMessage), findsOneWidget);
  });

  testWidgets('a category with no hymns left says so', (tester) async {
    await setUpTestApp(content: {'sda_new': _sdaHymns});
    final bloc = await pumpInApp(
      tester,
      const CategoryHymnsPage(
        category: 'ሰንበት',
        languageCode: 'am',
        version: 'sda_new',
      ),
    );
    await tester.pumpAndSettle();
    expect(bloc.isClosed, isFalse);

    expect(find.text('በዚህ ምድብ መዝሙር አልተገኘም'), findsOneWidget);
  });

  // Keep last: EditionCategoriesService.instance remembers the order it read.
  testWidgets('follows the order stored for the book when offline',
      (tester) async {
    await pumpCategories(
      tester,
      prefs: {
        'edition_categories_am-sda-2004': jsonEncode([
          {'slug': 'prayer', 'name': 'ጸሎት', 'sortOrder': 1},
          {'slug': 'praise', 'name': 'ምስጋና', 'sortOrder': 2},
        ]),
      },
    );
    await tester.pumpAndSettle();

    expect(topOf(tester, 'ጸሎት'), lessThan(topOf(tester, 'ምስጋና')));
  });
}
