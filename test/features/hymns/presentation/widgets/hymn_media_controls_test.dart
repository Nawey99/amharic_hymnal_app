import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/secure_screen_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/sheet_music_viewer_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_media_controls.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/music_player_widget.dart';

import '../../../../helpers/fakes.dart';

const _base = 'https://api.example.test/api/v1';
final _audioChecksum = 'b' * 64;

HymnMediaFile _pageFile(int n, String checksum) => HymnMediaFile(
      url: '$_base/songs/am-sda-2004-0007/sheet-music/pages/$n/file',
      checksumSha256: checksum,
      sizeBytes: 300 * 1024,
      contentType: 'image/webp',
      fileName: '07_$n.webp',
    );

Hymn _hymnWithSheet({int pages = 1}) {
  final files = [
    for (var n = 1; n <= pages; n++) _pageFile(n, '$n' * 64),
  ];
  return Hymn(
    id: 'am-sda-2004-0007',
    number: 7,
    title: 'መዝሙር 7',
    lyrics: 'ግጥም',
    sheetMusic: files.map((f) => f.url).toList(),
    sheetPages: [
      for (var i = 0; i < files.length; i++)
        HymnSheetPage(file: files[i], pageNumber: i + 1),
    ],
  );
}

/// Pumps through dialogs and routes; spinners never settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late MemoryMediaCache cache;

  setUp(() async {
    cache = MemoryMediaCache();
    await SecureScreenService.resetForTesting();
    SecureScreenService.platformInvokerForTesting = (method) async {
      if (method == 'isCaptured') return false;
      return null;
    };
  });

  tearDown(SecureScreenService.resetForTesting);

  Future<void> pumpControls(WidgetTester tester, Hymn hymn) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HymnMediaControls(
          hymn: hymn,
          version: 'sda_new',
          condensed: false,
          sheetMusicRepository: SheetMusicRepository(cache: cache),
          downloadRepository: DownloadRepository(cache: cache),
        ),
      ),
    ));
    await tester.pump();
  }

  Future<void> tapSheetBox(WidgetTester tester) async {
    await tester.tap(find.text('ኖታ'));
    await _settle(tester);
  }

  group('sheet music', () {
    testWidgets('a hymn without sheet music shows it as unavailable',
        (tester) async {
      await pumpControls(
        tester,
        const Hymn(id: 'am-sda-2004-0001', number: 1, title: 't'),
      );

      expect(find.text('የለም'), findsOneWidget);
      expect(find.text('ኖታ'), findsNothing);
      await tester.tap(find.text('የለም'));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('asks before downloading and states the size', (tester) async {
      await pumpControls(tester, _hymnWithSheet(pages: 2));

      await tapSheetBox(tester);

      expect(find.text('ኖታ ይውረድ?'), findsOneWidget);
      expect(find.textContaining('መጠን፦ 600 KB'), findsOneWidget);
      expect(cache.downloads, isEmpty);
    });

    testWidgets('cancel downloads nothing and stays on the hymn',
        (tester) async {
      await pumpControls(tester, _hymnWithSheet());
      await tapSheetBox(tester);

      await tester.tap(find.text('ይቅር'));
      await _settle(tester);

      expect(cache.downloads, isEmpty);
      expect(find.byType(SheetMusicViewerPage), findsNothing);
    });

    testWidgets('downloading opens the viewer with the stored pages',
        (tester) async {
      await pumpControls(tester, _hymnWithSheet(pages: 2));
      await tapSheetBox(tester);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(
          cache.downloads.map((s) => s.checksumSha256), ['1' * 64, '2' * 64]);
      final viewer = tester.widget<SheetMusicViewerPage>(
        find.byType(SheetMusicViewerPage),
      );
      expect(
          viewer.sheetMusicFiles, ['/cache/${'1' * 64}', '/cache/${'2' * 64}']);
    });

    testWidgets('already downloaded pages open without asking', (tester) async {
      cache.stored['1' * 64] = 1;
      await pumpControls(tester, _hymnWithSheet());

      await tapSheetBox(tester);

      expect(find.text('ኖታ ይውረድ?'), findsNothing);
      expect(cache.downloads, isEmpty);
      expect(find.byType(SheetMusicViewerPage), findsOneWidget);
    });

    testWidgets('a download that fails its checksum is reported, not shown',
        (tester) async {
      cache.failing.add('1' * 64);
      await pumpControls(tester, _hymnWithSheet());
      await tapSheetBox(tester);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(
          find.text('የወረደው ኖታ ትክክል አልሆነም። እባክዎ እንደገና ይሞክሩ።'), findsOneWidget);
      expect(find.byType(SheetMusicViewerPage), findsNothing);
      expect(cache.stored, isEmpty);
    });
  });

  group('audio', () {
    Future<void> pumpPlayer(WidgetTester tester, HymnAudioInfo info) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MusicPlayerWidget(
            hymnNumber: 7,
            hymnTitle: 'መዝሙር 7',
            audioSource: info.file.url,
            audioInfo: info,
            version: 'sda_new',
            audioRepository: AudioRepository(cache: cache),
            downloadRepository: DownloadRepository(cache: cache),
          ),
        ),
      ));
      await tester.pump();
    }

    final track = HymnAudioInfo(
      file: HymnMediaFile(
        url: '$_base/songs/am-sda-2004-0007/audio/file',
        checksumSha256: _audioChecksum,
        sizeBytes: (1.6 * 1024 * 1024).round(),
        contentType: 'audio/mp4',
      ),
    );

    testWidgets('a hymn without audio says so', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: HymnMediaControls(
            hymn: Hymn(id: 'am-sda-2004-0001', number: 1, title: 't'),
            version: 'sda_new',
            condensed: false,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('ድምፅ አልተገኘም'), findsOneWidget);
    });

    testWidgets('asks before downloading and states the size', (tester) async {
      await pumpPlayer(tester, track);

      await tester.tap(find.byTooltip('አጫውት'));
      await _settle(tester);

      expect(find.text('ድምፅ ይውረድ?'), findsOneWidget);
      expect(find.textContaining('መጠን፦ 1.6 MB'), findsOneWidget);

      await tester.tap(find.text('ይቅር'));
      await _settle(tester);
      expect(cache.downloads, isEmpty);
      expect(find.byTooltip('አጫውት'), findsOneWidget,
          reason: 'cancelling leaves the play button usable');
    });

    testWidgets('a confirmed download is verified and stored', (tester) async {
      await pumpPlayer(tester, track);
      await tester.tap(find.byTooltip('አጫውት'));
      await _settle(tester);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(cache.downloads.single.checksumSha256, _audioChecksum);
      expect(cache.downloads.single.fileExtension, '.m4a');
      expect(cache.stored.keys, [_audioChecksum]);
    });

    testWidgets('already downloaded audio plays without asking',
        (tester) async {
      cache.stored[_audioChecksum] = 1;
      await pumpPlayer(tester, track);

      await tester.tap(find.byTooltip('አጫውት'));
      await _settle(tester);

      expect(find.text('ድምፅ ይውረድ?'), findsNothing);
      expect(cache.downloads, isEmpty);
    });

    testWidgets('a download that fails its checksum is reported',
        (tester) async {
      cache.failing.add(_audioChecksum);
      await pumpPlayer(tester, track);
      await tester.tap(find.byTooltip('አጫውት'));
      await _settle(tester);

      await tester.tap(find.text('አውርድ'));
      await _settle(tester);

      expect(find.text('የወረደው ድምፅ ትክክል አልሆነም። እባክዎ እንደገና ይሞክሩ።'), findsWidgets);
      expect(cache.stored, isEmpty);
    });
  });
}
