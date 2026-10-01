import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/offline_download_controller.dart';
import 'package:amharic_hymnal_app/core/services/offline_media_download.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/offline_download_flow.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_app.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _mb = 1024 * 1024;

HymnMediaFile _file(String checksum, int size) => HymnMediaFile(
      url: 'https://api.example.test/files/$checksum',
      checksumSha256: checksum * 64,
      sizeBytes: size,
    );

/// A 2004 hymn as synced from the API.
Hymn _hymn(int number, {String? audio, List<String> pages = const []}) => Hymn(
      id: 'am-sda-2004-000$number',
      number: number,
      audioInfo:
          audio == null ? null : HymnAudioInfo(file: _file(audio, 2 * _mb)),
      sheetPages: [
        for (final (index, page) in pages.indexed)
          HymnSheetPage(file: _file(page, _mb), pageNumber: index + 1),
      ],
    );

/// Two recordings (a, b) and three pages (c, d, e); hymn 3 has neither.
List<Hymn> _syncedHymns() => [
      _hymn(1, audio: 'a', pages: ['c', 'd']),
      _hymn(2, audio: 'b', pages: ['e']),
      _hymn(3),
    ];

// Bundled hymns carry the API's IDs too; only the flag tells them apart.
const _bundledHymns = [
  Hymn(id: 'am-sda-2004-0001', number: 1, isBundled: true),
];

SettingsRepository get _settings => di.sl<SettingsRepository>();

void main() {
  late MemoryMediaCache cache;
  late OfflineDownloadController controller;

  setUp(() async {
    await setUpTestApp();
    cache = MemoryMediaCache();
    controller = OfflineDownloadController(
      downloader: EditionMediaDownloader(cache: cache),
    );
  });

  /// Pumps a button that runs [action] with a context under a Scaffold.
  Future<void> tapToRun(
    WidgetTester tester,
    Future<void> Function(BuildContext context) action,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => action(context),
            child: const Text('run'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('run'));
    await _settle(tester);
  }

  group('offer after onboarding', () {
    Future<void> offer(
      WidgetTester tester, {
      List<Hymn>? hymns,
      bool pending = true,
    }) async {
      await _settings.setOfflineDownloadOfferPending(pending);
      await tapToRun(
        tester,
        (context) => maybeOfferOfflineDownloads(
          context,
          version: 'sda_new',
          hymns: hymns ?? _syncedHymns(),
          controller: controller,
        ),
      );
    }

    Switch switchOf(WidgetTester tester, String mediaType) =>
        tester.widget<Switch>(find.descendant(
          of: find.byKey(ValueKey('offer-$mediaType')),
          matching: find.byType(Switch),
        ));

    testWidgets('asks about sheet music and audio, each with its size',
        (tester) async {
      await offer(tester);

      expect(find.text('ያለ ኢንተርኔት ለመጠቀም ማውረድ'), findsOneWidget);
      expect(find.text('3 ገጾች · 3.0 MB'), findsOneWidget);
      expect(find.text('2 ድምፆች · 4.0 MB'), findsOneWidget);
      expect(switchOf(tester, MediaType.sheetMusic).value, isTrue);
      expect(switchOf(tester, MediaType.audio).value, isFalse,
          reason: 'audio is large, so it is a deliberate choice');
    });

    testWidgets('downloads what was chosen and keeps it offline',
        (tester) async {
      await offer(tester);

      await tester.tap(find.byKey(const ValueKey('offer-audio')));
      await tester.pump();
      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(
        cache.stored.keys,
        containsAll([
          for (final key in ['a', 'b', 'c', 'd', 'e']) key * 64
        ]),
      );
      expect(
        cache.downloads.first.checksumSha256,
        anyOf('c' * 64, 'd' * 64, 'e' * 64),
        reason: 'sheet music first',
      );
      expect(_settings.isOfflineDownloadOfferPending(), isFalse);
      expect(_settings.isMediaKeptOffline('sda_new', MediaType.audio), isTrue);
      // Both ended, so neither is carried on at the next start-up.
      expect(_settings.getUnfinishedDownloads(), isEmpty);
      expect(
        _settings.isMediaKeptOffline('sda_new', MediaType.sheetMusic),
        isTrue,
      );
    });

    testWidgets('download is off until something is chosen', (tester) async {
      await offer(tester);

      await tester.tap(find.byKey(const ValueKey('offer-sheet_music')));
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('"later" downloads nothing and never asks again',
        (tester) async {
      await offer(tester);

      await tester.tap(find.text('በኋላ'));
      await _settle(tester);
      expect(cache.downloads, isEmpty);
      expect(_settings.isOfflineDownloadOfferPending(), isFalse);

      await tester.tap(find.text('run'));
      await _settle(tester);
      expect(find.text('ያለ ኢንተርኔት ለመጠቀም ማውረድ'), findsNothing);
    });

    testWidgets('an edition without sheet music is asked only about audio',
        (tester) async {
      await offer(tester, hymns: [_hymn(1, audio: 'a')]);

      expect(find.byKey(const ValueKey('offer-sheet_music')), findsNothing);
      expect(find.byKey(const ValueKey('offer-audio')), findsOneWidget);
    });

    testWidgets('with everything on the phone there is nothing to ask',
        (tester) async {
      cache.stored.addAll({
        for (final key in ['a', 'b', 'c', 'd', 'e']) key * 64: 1,
      });
      await offer(tester);

      expect(find.text('ያለ ኢንተርኔት ለመጠቀም ማውረድ'), findsNothing);
      expect(_settings.isOfflineDownloadOfferPending(), isFalse);
    });

    testWidgets('waits for the edition to come from the server',
        (tester) async {
      await offer(tester, hymns: _bundledHymns);

      expect(find.text('ያለ ኢንተርኔት ለመጠቀም ማውረድ'), findsNothing);
      expect(_settings.isOfflineDownloadOfferPending(), isTrue);
    });

    testWidgets('asks only once onboarding has set it up', (tester) async {
      await offer(tester, pending: false);

      expect(find.text('ያለ ኢንተርኔት ለመጠቀም ማውረድ'), findsNothing);
    });
  });

  group('download from Settings', () {
    Future<void> run(
      WidgetTester tester,
      String mediaType, {
      List<Hymn>? hymns,
    }) =>
        tapToRun(
          tester,
          (context) => runEditionMediaDownload(
            context,
            'sda_new',
            mediaType,
            loadHymns: (_) async => hymns ?? _syncedHymns(),
            controller: controller,
          ),
        );

    testWidgets('sheet music: states the size, then downloads', (tester) async {
      await run(tester, MediaType.sheetMusic);

      expect(find.text('ሁሉም ኖታዎች ይውረዱ?'), findsOneWidget);
      expect(find.textContaining('3 ገጾች፣ 3.0 MB'), findsOneWidget);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(cache.stored.keys, containsAll(['c' * 64, 'd' * 64, 'e' * 64]));
      expect(find.text('ሁሉም ኖታዎች ወርደዋል።'), findsOneWidget);
      expect(
        _settings.isMediaKeptOffline('sda_new', MediaType.sheetMusic),
        isTrue,
      );
    });

    testWidgets('audio: states the size, then downloads', (tester) async {
      await run(tester, MediaType.audio);

      expect(find.text('ሁሉም ድምፆች ይውረዱ?'), findsOneWidget);
      expect(find.textContaining('2 ድምፆች፣ 4.0 MB'), findsOneWidget);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(cache.stored.keys, containsAll(['a' * 64, 'b' * 64]));
      expect(find.text('ሁሉም ድምፆች ወርደዋል።'), findsOneWidget);
    });

    testWidgets('a phone without room says so instead of starting',
        (tester) async {
      // 4 MB of audio, 10 MB free: the 50 MB kept spare does not fit.
      cache.free = 10 * 1024 * 1024;
      await run(tester, MediaType.audio);

      expect(find.text('ሁሉም ድምፆች ይውረዱ?'), findsNothing);
      expect(find.textContaining('በቂ ቦታ የለም'), findsOneWidget);
      expect(cache.stored, isEmpty);
      expect(controller.isActive(MediaType.audio), isFalse);
    });

    testWidgets('a phone with room is asked as before', (tester) async {
      cache.free = 2 * 1024 * 1024 * 1024;
      await run(tester, MediaType.audio);

      expect(find.text('ሁሉም ድምፆች ይውረዱ?'), findsOneWidget);
    });

    testWidgets('after a sync, only what changed is offered', (tester) async {
      cache.stored.addAll({'c' * 64: 1, 'd' * 64: 1});
      await run(tester, MediaType.sheetMusic);

      expect(find.textContaining('1 ገጾች፣ 1.0 MB'), findsOneWidget);
    });

    testWidgets('cancelling at the size prompt downloads nothing',
        (tester) async {
      await run(tester, MediaType.sheetMusic);

      await tester.tap(find.text('ይቅር'));
      await _settle(tester);

      expect(cache.downloads, isEmpty);
      expect(
        _settings.isMediaKeptOffline('sda_new', MediaType.sheetMusic),
        isFalse,
      );
    });

    testWidgets('reports files that failed; a retry fetches the rest',
        (tester) async {
      cache.failing.add('e' * 64);
      await run(tester, MediaType.sheetMusic);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(
        find.text('1 ገጾችን ማውረድ አልተቻለም። እንደገና ሲሞክሩ የቀሩት ብቻ ይወርዳሉ።'),
        findsOneWidget,
      );
    });

    testWidgets('says so when everything is already on the phone',
        (tester) async {
      cache.stored.addAll({'a' * 64: 1, 'b' * 64: 1});
      await run(tester, MediaType.audio);

      expect(find.text('ሁሉም ድምፆች በመሣሪያዎ ላይ አሉ።'), findsOneWidget);
      expect(find.text('ሁሉም ድምፆች ይውረዱ?'), findsNothing);
      expect(_settings.isMediaKeptOffline('sda_new', MediaType.audio), isTrue);
    });

    testWidgets('says so when the book has no sheet music', (tester) async {
      await run(tester, MediaType.sheetMusic, hymns: [_hymn(1, audio: 'a')]);

      expect(find.text('ይህ የመዝሙር መጽሐፍ ኖታ የለውም።'), findsOneWidget);
    });

    testWidgets('needs the edition from the server first', (tester) async {
      await run(tester, MediaType.audio, hymns: _bundledHymns);

      expect(
        find.text('ለማውረድ መጀመሪያ የኢንተርኔት ግንኙነት ያስፈልጋል። እባክዎ ቆይተው እንደገና ይሞክሩ።'),
        findsOneWidget,
      );
    });
  });

  group('tile', () {
    Future<void> pumpTile(WidgetTester tester, String mediaType) async {
      await controller.updateStatus('sda_new', _syncedHymns());
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OfflineDownloadTile(
            mediaType: mediaType,
            version: 'sda_new',
            controller: controller,
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('offers the download with its size', (tester) async {
      await pumpTile(tester, MediaType.audio);

      expect(find.byIcon(Icons.download_for_offline_outlined), findsOneWidget);
      expect(find.textContaining('4.0 MB'), findsOneWidget);
    });

    testWidgets('shows a tick once everything is on the phone', (tester) async {
      cache.stored.addAll({'a' * 64: 1, 'b' * 64: 1});
      await pumpTile(tester, MediaType.audio);

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('ሁሉም ወርደዋል · 2 ድምፆች · 4.0 MB'), findsOneWidget);
    });

    testWidgets('shows what a sync added to a kept edition', (tester) async {
      await _settings.setMediaKeptOffline('sda_new', MediaType.audio, true);
      cache.stored['a' * 64] = 1;
      await pumpTile(tester, MediaType.audio);

      expect(find.byIcon(Icons.update), findsOneWidget);
      expect(find.text('1 አዲስ ድምፆች ለማውረድ · 2.0 MB'), findsOneWidget);
    });

    testWidgets('a running download shows its progress and can be stopped',
        (tester) async {
      await pumpTile(tester, MediaType.sheetMusic);
      final running = Completer<void>();
      var stopRequested = false;

      controller.start(
        MediaType.sheetMusic,
        (onProgress, isCancelled) async {
          onProgress(_mb, 2 * _mb);
          await running.future;
          stopRequested = isCancelled();
          return const MediaDownloadResult(
            downloaded: 1,
            failed: 0,
            cancelled: true,
          );
        },
        onDone: (_) {},
      );
      await tester.pump();

      expect(find.text('50% · 1.0 MB / 2.0 MB'), findsOneWidget);

      await tester.tap(find.byTooltip('አቁም'));
      running.complete();
      await _settle(tester);

      expect(stopRequested, isTrue);
      expect(find.textContaining('50%'), findsNothing);
    });

    testWidgets('a download waiting its turn says so', (tester) async {
      await pumpTile(tester, MediaType.audio);
      final running = Completer<MediaDownloadResult>();
      controller.start(
        MediaType.sheetMusic,
        (_, __) => running.future,
        onDone: (_) {},
      );
      controller.start(
        MediaType.audio,
        (_, __) async => const MediaDownloadResult(
          downloaded: 0,
          failed: 0,
          cancelled: false,
        ),
        onDone: (_) {},
      );
      await tester.pump();

      expect(find.text('በመጠባበቅ ላይ'), findsOneWidget);
      running.complete(
        const MediaDownloadResult(downloaded: 0, failed: 0, cancelled: false),
      );
      await _settle(tester);
    });
  });

  group('changes to kept media', () {
    Future<void> syncChanges(WidgetTester tester, List<Hymn> hymns) async {
      await controller.updateStatus('sda_new', hymns);
      await tapToRun(tester, (context) async {
        downloadKeptMediaChanges(
          ScaffoldMessenger.of(context),
          AppLocalizations.of(context),
          controller: controller,
        );
      });
    }

    testWidgets('only what a sync added is fetched, without asking',
        (tester) async {
      await _settings.setMediaKeptOffline('sda_new', MediaType.audio, true);
      cache.stored['a' * 64] = 1;

      await syncChanges(tester, _syncedHymns());

      expect(
        cache.downloads.map((source) => source.checksumSha256),
        ['b' * 64],
      );
      expect(find.text('1 አዲስ ድምፆች ወርደዋል።'), findsOneWidget);
      expect(find.text('ሁሉም ድምፆች ይውረዱ?'), findsNothing);
    });

    testWidgets('media never chosen for offline is left alone', (tester) async {
      await syncChanges(tester, _syncedHymns());

      expect(cache.downloads, isEmpty);
    });

    testWidgets('large changes wait for a tap', (tester) async {
      await _settings.setMediaKeptOffline('sda_new', MediaType.audio, true);
      await syncChanges(tester, [
        for (var number = 1; number <= 13; number++)
          _hymn(number, audio: String.fromCharCode(96 + number)),
      ]);

      expect(
        controller.statusOf(MediaType.audio)!.missingBytes,
        greaterThan(automaticUpdateLimitBytes),
      );
      expect(cache.downloads, isEmpty);
    });

    testWidgets('stopping a download stops keeping that media offline',
        (tester) async {
      await tapToRun(tester, (context) async {
        final messenger = ScaffoldMessenger.of(context);
        final plan =
            await controller.downloader.plan(_syncedHymns(), MediaType.audio);
        startOfflineDownload(
          messenger,
          null,
          'sda_new',
          plan,
          controller: controller,
        );
        controller.stop(MediaType.audio);
      });

      expect(_settings.isMediaKeptOffline('sda_new', MediaType.audio), isFalse);
    });

    testWidgets('each edition keeps its own choice', (tester) async {
      await _settings.setMediaKeptOffline('sda_old', MediaType.audio, true);

      await syncChanges(tester, _syncedHymns());

      expect(cache.downloads, isEmpty);
    });
  });
}
