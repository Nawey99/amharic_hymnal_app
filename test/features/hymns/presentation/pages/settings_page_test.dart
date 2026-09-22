import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';
import 'package:amharic_hymnal_app/core/services/sheet_music_bulk_download_service.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/settings_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/sheet_music_bulk_download_flow.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

import '../../../../helpers/fake_hymnal_api.dart';
import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_app.dart';

const _wakelockToggle =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The edition list offline: settings falls back to the built-in editions.
void _offlineVersionCatalog() {
  di.sl.unregister<HymnalVersionService>();
  di.sl.registerLazySingleton<HymnalVersionService>(
    () => HymnalVersionService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((_) async => http.Response('', 503)),
    ),
  );
}

void main() {
  group('SettingsPage', () {
    late List<Object?> wakelockCalls;

    setUp(() {
      wakelockCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(_wakelockToggle, (message) async {
        // The message uses Pigeon's own codec; that it arrived is what
        // matters here.
        wakelockCalls.add(message);
        return const StandardMessageCodec().encodeMessage(<Object?>[]);
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(_wakelockToggle, null);
    });

    Future<HymnsBloc> pumpSettings(WidgetTester tester) async {
      await setUpTestApp(content: {
        'sda_new': sampleHymns(),
        'sda_old': sampleHymns(count: 3, prefix: 'am-sda-1975'),
      });
      _offlineVersionCatalog();
      final bloc = await pumpInApp(
        tester,
        const Scaffold(body: SettingsPage()),
        size: const Size(412, 1400),
      );
      await _settle(tester);
      return bloc;
    }

    testWidgets('switching edition saves it and reloads that book',
        (tester) async {
      final bloc = await pumpSettings(tester);

      await tester.tap(find.text('የ2004 ውዳሴ መዝሙር').last);
      await _settle(tester);
      await tester.tap(find.text('የ1975 ውዳሴ መዝሙር').last);
      await _settle(tester);

      expect(di.sl<SettingsRepository>().getSelectedVersion(), 'sda_old');
      final state = bloc.state as HymnsLoaded;
      expect(state.version, 'sda_old');
      expect(state.hymns, hasLength(3));
    });

    testWidgets('keep-screen-on is saved and applied', (tester) async {
      await pumpSettings(tester);
      expect(di.sl<SettingsRepository>().getKeepScreenOn(), isFalse);

      await tester.tap(find.byType(Switch).last);
      await _settle(tester);

      expect(di.sl<SettingsRepository>().getKeepScreenOn(), isTrue);
      expect(wakelockCalls, isNotEmpty, reason: 'the wake lock was toggled');
    });

    testWidgets('offers the whole-book sheet music download', (tester) async {
      await pumpSettings(tester);

      expect(find.text('ኖታዎችን በሙሉ አውርድ'), findsOneWidget);
    });
  });

  group('download all sheet music', () {
    late FakeHymnalApi api;
    late MemoryMediaCache cache;

    Map<String, dynamic> page(String checksum, {int size = 512 * 1024}) => {
          'downloadUrl': '${api.baseUrl}/p/$checksum',
          'checksumSha256': checksum,
          'sizeBytes': size,
          'contentType': 'image/webp',
        };

    void servePages(List<Map<String, dynamic>> pages) => api.ok(
          '/downloads/sheet-music/pages',
          {'pageCount': pages.length, 'pages': pages},
        );

    Future<void> start(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => runSheetMusicBulkDownload(
                context,
                'sda_1960',
                service: SheetMusicBulkDownloadService(
                  baseUrl: api.baseUrl,
                  client: api.client,
                  cache: cache,
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await _settle(tester);
    }

    setUp(() {
      api = FakeHymnalApi();
      cache = MemoryMediaCache();
    });

    testWidgets('states the size, then downloads every missing page',
        (tester) async {
      servePages([page('a' * 64), page('b' * 64)]);
      await start(tester);

      expect(api.requests.single.url.queryParameters['version'], 'am-sda-1961');
      expect(find.text('ኖታዎችን በሙሉ ይውረዱ?'), findsOneWidget);
      expect(find.textContaining('2 ገጾች፣ 1.0 MB'), findsOneWidget);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(cache.stored.keys, containsAll(['a' * 64, 'b' * 64]));
      expect(find.text('ሁሉም ኖታዎች ወርደዋል።'), findsOneWidget);
    });

    testWidgets('cancelling at the size prompt downloads nothing',
        (tester) async {
      servePages([page('a' * 64)]);
      await start(tester);

      await tester.tap(find.text('ይቅር'));
      await _settle(tester);

      expect(cache.downloads, isEmpty);
    });

    testWidgets('reports pages that failed and that a retry fetches the rest',
        (tester) async {
      servePages([page('a' * 64), page('b' * 64)]);
      cache.failing.add('b' * 64);
      await start(tester);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(
        find.text('1 ገጾችን ማውረድ አልተቻለም። እንደገና ሲሞክሩ የቀሩት ብቻ ይወርዳሉ።'),
        findsOneWidget,
      );
    });

    testWidgets('says so when everything is already on the phone',
        (tester) async {
      servePages([page('a' * 64)]);
      cache.stored['a' * 64] = 1;
      await start(tester);

      expect(find.text('ሁሉም ኖታዎች በመሣሪያዎ ላይ አሉ።'), findsOneWidget);
      expect(find.text('ኖታዎችን በሙሉ ይውረዱ?'), findsNothing);
    });

    testWidgets('says so when the book has no sheet music', (tester) async {
      servePages([]);
      await start(tester);

      expect(find.text('ይህ መዝሙር መጽሐፍ ኖታ የለውም።'), findsOneWidget);
    });

    testWidgets('explains a failed listing', (tester) async {
      api.online = false;
      await start(tester);

      expect(
          find.text('የኖታ ዝርዝሩን ማግኘት አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።'), findsOneWidget);
    });
  });
}
