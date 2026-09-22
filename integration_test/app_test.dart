// Full-app flows on a real device, emulator or desktop.
//
// Deterministic: hymn content comes from a scripted in-process API, and every
// other service is pointed at an unreachable host, so the run never depends
// on the live hymnal API. Run with:
//
//   flutter test integration_test/app_test.dart \
//     --dart-define=WUDASE_CONTENT_API_URL=https://content.example.invalid
//
// Each test asserts its outcome; a missing widget fails the test.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/edition_store.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;
import 'package:amharic_hymnal_app/main.dart' as app;

const _base = 'https://api.example.test/api/v1';

/// A small scripted hymnal API: three books, a few hymns each.
class _ScriptedApi {
  bool online = true;

  static const _books = {
    'am-sda-2004': ['ምስጋና ለአምላክ', 'ጸሎቴን ስማ', 'ተስፋዬ ነህ'],
    'am-sda-1975': ['የቀድሞ ምስጋና', 'የቀድሞ ጸሎት'],
    'am-hagerigna': ['እነሆ ክረምቱ ያልፋል'],
  };

  static http.Response _ok(Object data) => http.Response.bytes(
        utf8.encode(jsonEncode({'success': true, 'data': data})),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  static Map<String, dynamic> _song(String code, int number, String title) => {
        'id': '$code-${number.toString().padLeft(4, '0')}',
        'number': number,
        'title': title,
        'englishTitle': null,
        'lyrics': '$title\nሁለተኛ መስመር',
        'revision': 1,
        'category': null,
        'audio': {'available': false},
        'sheetMusic': {'available': false, 'pageCount': 0, 'pages': []},
        'isActive': true,
        'deletedAt': null,
      };

  late final MockClient client = MockClient((request) async {
    if (!online) throw http.ClientException('offline', request.url);
    final path = request.url.path;
    if (path.endsWith('/hymn-versions')) {
      return _ok([
        for (final code in _books.keys)
          {
            'code': code,
            'title': code,
            'versionLabel': code.split('-').last,
            'capabilities': {'songs': true},
            'contentUpdatedAt': 't1',
          },
      ]);
    }
    for (final code in _books.keys) {
      if (path.endsWith('/hymn-versions/$code')) {
        return _ok({'code': code, 'contentUpdatedAt': 't1'});
      }
    }
    if (path.endsWith('/sync')) {
      final code = request.url.queryParameters['version']!;
      final titles = _books[code] ?? const <String>[];
      return _ok({
        'serverTime': '2026-09-21T12:00:00.000Z',
        'hasMore': false,
        'nextCursor': null,
        'hymnVersion': {'code': code, 'isActive': true},
        'changes': {
          'songs': [
            for (var i = 0; i < titles.length; i++)
              _song(code, i + 1, titles[i]),
          ],
        },
      });
    }
    return http.Response(
        '{"success":false,"error":{"code":"ROUTE_NOT_FOUND"}}', 404);
  });
}

class _MemoryStore implements EditionStore {
  final Map<String, StoredEdition> _editions = {};
  @override
  Future<StoredEdition?> read(String key) async => _editions[key];
  @override
  Future<void> write(String key, StoredEdition edition) async =>
      _editions[key] = edition;
  @override
  Future<void> delete(String key) async => _editions.remove(key);
  @override
  Future<List<StoredEdition>?> readAll() async => _editions.values.toList();
}

/// Starts the real app with the scripted API and the given saved settings.
Future<_ScriptedApi> _startApp(
  WidgetTester tester, {
  bool onboardingDone = true,
  bool online = true,
  String version = 'sda_new',
}) async {
  final api = _ScriptedApi()..online = online;
  await di.sl.reset();
  HistoryService.resetForTesting();
  SharedPreferences.setMockInitialValues({
    'onboarding_completed': onboardingDone,
    'selected_language': 'am',
    'selected_version': version,
    'sort_type': 'number',
  });
  di.sl.registerLazySingleton<HymnLocalDataSource>(
    () => LocalDataSource(
      remoteDataSource: HymnRemoteDataSource(
        client: api.client,
        baseUrl: _base,
        store: _MemoryStore(),
      ),
    ),
  );
  di.sl.registerLazySingleton<HymnalVersionService>(
    () => HymnalVersionService(client: api.client, baseUrl: _base),
  );

  app.main();
  // A cold first install can take several seconds to start; wait for either
  // onboarding or the main screen instead of a fixed delay.
  final ready = find.byWidgetPredicate(
    (widget) =>
        widget is Text && (widget.data == 'ዝለል' || widget.data == 'ቁጥር'),
  );
  for (var i = 0; i < 300 && ready.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready, findsWidgets, reason: 'the app did not start within 30 s');
  await tester.pumpAndSettle();
  return api;
}

Future<void> _openNumber(WidgetTester tester, String number) async {
  await tester.tap(find.text('ቁጥር').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.keyboardType == TextInputType.number,
    ),
    number,
  );
  await tester.tap(find.text('ክፈት'));
  await tester.pumpAndSettle();
}

Future<void> _goBack(WidgetTester tester) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
  navigator.pop();
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch shows onboarding, and finishing it opens the app',
      (tester) async {
    await _startApp(tester, onboardingDone: false);

    expect(find.text('ዝለል'), findsOneWidget);
    await tester.tap(find.text('ዝለል'));
    await tester.pumpAndSettle();

    expect(find.text('ቁጥር'), findsWidgets);
    expect(find.text('ዝለል'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_completed'), isTrue);
  });

  testWidgets('open a hymn by number, favourite it, find it in Favourites',
      (tester) async {
    await _startApp(tester);

    await _openNumber(tester, '2');
    expect(find.byType(HymnDetailPage), findsOneWidget);
    expect(find.textContaining('ጸሎቴን ስማ'), findsWidgets);

    await tester.tap(find.byTooltip('ወደ ተወዳጅ ጨምር'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('ከተወዳጅ አስወግድ'), findsOneWidget);

    await _goBack(tester);
    await tester.tap(find.text('ተወዳጅ').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('ጸሎቴን ስማ'), findsWidgets);
  });

  testWidgets('each book keeps its own favourites', (tester) async {
    await _startApp(tester);
    await _openNumber(tester, '1');
    await tester.tap(find.byTooltip('ወደ ተወዳጅ ጨምር'));
    await tester.pumpAndSettle();
    await _goBack(tester);

    // Switch to the 1975 book through Settings.
    await tester.tap(find.text('ቅንብር').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('የ2004 ውዳሴ መዝሙር').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('የ1975 ውዳሴ መዝሙር').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ተወዳጅ').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('ምስጋና ለአምላክ'), findsNothing);
    expect(find.textContaining('የቀድሞ ምስጋና'), findsNothing);
  });

  testWidgets('offline on first launch, the bundled hymns are shown',
      (tester) async {
    await _startApp(tester, online: false);

    await _openNumber(tester, '1');

    // Bundled 2004 hymn 1 (from assets), not the scripted API's title.
    expect(find.byType(HymnDetailPage), findsOneWidget);
    expect(find.textContaining('ምስጋና ለአምላክ'), findsNothing);
  });

  testWidgets('Hagerigna has no Category tab', (tester) async {
    await _startApp(tester, version: 'hagerigna');

    expect(find.text('ምድብ'), findsNothing);
    expect(find.text('ማውጫ'), findsWidgets);
  });
}
