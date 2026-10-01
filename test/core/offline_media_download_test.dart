import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/background_media_transfer.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/offline_download_controller.dart';
import 'package:amharic_hymnal_app/core/services/offline_media_download.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';

import '../helpers/fakes.dart';

HymnMediaFile _file(String checksum, int size) => HymnMediaFile(
      url: 'https://api.example.test/files/$checksum',
      checksumSha256: checksum * 64,
      sizeBytes: size,
    );

Hymn _hymn(
  int number, {
  String? audio,
  List<String> pages = const [],
  int size = 1000,
}) =>
    Hymn(
      id: 'am-sda-2004-${number.toString().padLeft(4, '0')}',
      number: number,
      audioInfo: audio == null ? null : HymnAudioInfo(file: _file(audio, size)),
      sheetPages: [
        for (final (index, page) in pages.indexed)
          HymnSheetPage(file: _file(page, size), pageNumber: index + 1),
      ],
    );

const _done = MediaDownloadResult(downloaded: 1, failed: 0, cancelled: false);

/// Downloads the system kept running while the app was closed.
class _RunningTransfer implements MediaTransfer {
  _RunningTransfer(this.running);

  /// By media type: what [resume] finds, once [finish] completes.
  final Map<String, RunningTransfer> running;
  final finish = Completer<void>();

  @override
  Future<MediaDownloadResult> download(
    MediaDownloadPlan plan, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) async =>
      _done;

  @override
  Future<bool> hasRunning(String mediaType) async =>
      running.containsKey(mediaType);

  @override
  Future<RunningTransfer?> resume(
    String mediaType, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    onProgress?.call(1, 4);
    await finish.future;
    return running[mediaType];
  }
}

void main() {
  group('EditionMediaDownloader', () {
    test('lists each missing track once, from the hymns on the device',
        () async {
      final cache = MemoryMediaCache()..stored['c' * 64] = 1;
      final plan = await EditionMediaDownloader(cache: cache).plan([
        _hymn(1, audio: 'a', size: 2000),
        _hymn(2, audio: 'a', size: 2000), // the same recording
        _hymn(3, audio: 'b', size: 3000),
        _hymn(4, audio: 'c'), // already downloaded
        _hymn(5), // no recording
      ], MediaType.audio);

      expect(plan.mediaType, MediaType.audio);
      expect(plan.itemCount, 3);
      expect(plan.totalBytes, 6000);
      expect(
        plan.missing.map((source) => source.checksumSha256),
        unorderedEquals(['a' * 64, 'b' * 64]),
      );
      expect(plan.missingBytes, 5000);
    });

    test('lists sheet music pages, a sheet shared by two hymns once', () async {
      final plan =
          await EditionMediaDownloader(cache: MemoryMediaCache()).plan([
        _hymn(1, pages: ['a', 'b']),
        _hymn(2, pages: ['b']), // prints on the same sheet
        _hymn(3, audio: 'c'),
      ], MediaType.sheetMusic);

      expect(plan.itemCount, 2);
      expect(
        plan.missing.map((source) => source.checksumSha256),
        unorderedEquals(['a' * 64, 'b' * 64]),
      );
    });

    test('downloads the missing files and counts the ones that fail', () async {
      final cache = MemoryMediaCache()..failing.add('b' * 64);
      final downloader = EditionMediaDownloader(cache: cache);
      final hymns = [_hymn(1, audio: 'a'), _hymn(2, audio: 'b')];

      final result = await downloader.download(
        await downloader.plan(hymns, MediaType.audio),
      );

      expect(result.downloaded, 1);
      expect(result.failed, 1);
      expect(cache.stored.keys, contains('a' * 64));
      expect(cache.stored.keys, isNot(contains('b' * 64)));
      expect(
          (await downloader.plan(hymns, MediaType.audio)).missing, hasLength(1),
          reason: 'a retry fetches only what is still missing');
    });

    test('progress counts bytes, so a large file weighs more', () async {
      final downloader = EditionMediaDownloader(cache: MemoryMediaCache());
      final plan = await downloader.plan([
        _hymn(1, audio: 'a', size: 1000),
        _hymn(2, audio: 'b', size: 3000),
      ], MediaType.audio);
      final reports = <(int, int)>[];

      await downloader.download(
        plan,
        onProgress: (done, total) => reports.add((done, total)),
      );

      expect(reports.map((report) => report.$2).toSet(), {4000});
      expect(reports.last.$1, 4000);
      expect(
        reports.map((report) => report.$1),
        containsAll([3000, 4000]),
        reason: 'the 3000-byte file is three quarters of the work',
      );
    });

    test('stops when cancelled', () async {
      final cache = MemoryMediaCache();
      final downloader = EditionMediaDownloader(cache: cache);
      final plan = await downloader.plan(
        [_hymn(1, audio: 'a'), _hymn(2, audio: 'b')],
        MediaType.audio,
      );

      final result = await downloader.download(plan, isCancelled: () => true);

      expect(result.cancelled, isTrue);
      expect(result.downloaded, 0);
      expect(cache.stored, isEmpty);
    });
  });

  group('OfflineDownloadController', () {
    test('runs one download at a time, in the order started', () async {
      final controller = OfflineDownloadController();
      final sheetMusic = Completer<MediaDownloadResult>();
      final order = <String>[];

      controller.start(
        MediaType.sheetMusic,
        (onProgress, _) {
          order.add('sheet');
          onProgress(1, 4);
          return sheetMusic.future;
        },
        onDone: (_) {},
      );
      controller.start(
        MediaType.audio,
        (_, __) async {
          order.add('audio');
          return _done;
        },
        onDone: (_) {},
      );
      await Future<void>.delayed(Duration.zero);

      expect(order, ['sheet']);
      expect(controller.progressOf(MediaType.sheetMusic), 0.25);
      expect(controller.isQueued(MediaType.audio), isTrue);
      expect(controller.isQueued(MediaType.sheetMusic), isFalse);

      sheetMusic.complete(_done);
      await pumpEventQueue();

      expect(order, ['sheet', 'audio']);
      expect(controller.isActive(MediaType.sheetMusic), isFalse);
      expect(controller.isActive(MediaType.audio), isFalse);
    });

    test('will not start the same kind twice', () async {
      final controller = OfflineDownloadController();
      final running = Completer<MediaDownloadResult>();
      Future<MediaDownloadResult> run(
              void Function(int, int) _, bool Function() __) =>
          running.future;

      expect(controller.start(MediaType.audio, run, onDone: (_) {}), isTrue);
      expect(controller.start(MediaType.audio, run, onDone: (_) {}), isFalse);
      running.complete(_done);
    });

    test('stop ends a running download and cancels a queued one', () async {
      final controller = OfflineDownloadController();
      final results = <String, MediaDownloadResult>{};
      var audioRan = false;

      controller.start(
        MediaType.sheetMusic,
        (_, isCancelled) async {
          while (!isCancelled()) {
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          return const MediaDownloadResult(
            downloaded: 2,
            failed: 0,
            cancelled: true,
          );
        },
        onDone: (result) => results[MediaType.sheetMusic] = result,
      );
      controller.start(
        MediaType.audio,
        (_, __) async {
          audioRan = true;
          return _done;
        },
        onDone: (result) => results[MediaType.audio] = result,
      );

      controller.stop(MediaType.audio);
      expect(results[MediaType.audio]!.cancelled, isTrue);
      expect(controller.isActive(MediaType.audio), isFalse);

      controller.stop(MediaType.sheetMusic);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(results[MediaType.sheetMusic]!.cancelled, isTrue);
      expect(results[MediaType.sheetMusic]!.downloaded, 2);
      expect(controller.isActive(MediaType.sheetMusic), isFalse);
      expect(audioRan, isFalse);
    });

    test('knows what of an edition is on the phone, and rechecks it', () async {
      final cache = MemoryMediaCache();
      final controller = OfflineDownloadController(
        downloader: EditionMediaDownloader(cache: cache),
      );
      final hymns = [
        _hymn(1, audio: 'a', pages: ['c']),
        _hymn(2, audio: 'b'),
      ];

      await controller.updateStatus('sda_new', hymns);
      expect(controller.statusVersion, 'sda_new');
      expect(controller.statusOf(MediaType.audio)!.missing, hasLength(2));
      expect(controller.statusOf(MediaType.sheetMusic)!.missing, hasLength(1));

      final plan = controller.statusOf(MediaType.audio)!;
      controller.start(
        MediaType.audio,
        (onProgress, isCancelled) => controller.downloader.download(plan),
        onDone: (_) {},
      );
      await pumpEventQueue();

      expect(controller.statusOf(MediaType.audio)!.missing, isEmpty,
          reason: 'a finished download is rechecked');
      expect(controller.statusOf(MediaType.sheetMusic)!.missing, hasLength(1));

      controller.clearStatus();
      expect(controller.statusOf(MediaType.audio), isNull);
    });

    test('a sync that brings a new recording shows just that file missing',
        () async {
      final cache = MemoryMediaCache()
        ..stored.addAll({'a' * 64: 1, 'b' * 64: 1});
      final controller = OfflineDownloadController(
        downloader: EditionMediaDownloader(cache: cache),
      );

      await controller.updateStatus(
        'sda_new',
        [_hymn(1, audio: 'a'), _hymn(2, audio: 'b')],
      );
      expect(controller.statusOf(MediaType.audio)!.missing, isEmpty);

      await controller.updateStatus('sda_new', [
        _hymn(1, audio: 'a'),
        _hymn(2, audio: 'd'), // re-recorded
        _hymn(3, audio: 'e'), // newly recorded
      ]);
      expect(
        controller
            .statusOf(MediaType.audio)!
            .missing
            .map((source) => source.checksumSha256),
        unorderedEquals(['d' * 64, 'e' * 64]),
      );
    });
  });

  group('downloads that ran while the app was closed', () {
    test('are picked up, shown and followed to the end', () async {
      final transfer = _RunningTransfer({
        MediaType.audio:
            const RunningTransfer(version: 'sda_old', result: _done),
      });
      final controller = OfflineDownloadController(
        downloader: EditionMediaDownloader(
          cache: MemoryMediaCache(),
          transfer: transfer,
        ),
      );

      await controller.resumeRunningDownloads();
      await pumpEventQueue();

      expect(controller.isActive(MediaType.audio), isTrue);
      expect(controller.progressOf(MediaType.audio), 0.25);
      expect(controller.isActive(MediaType.sheetMusic), isFalse);

      transfer.finish.complete();
      await pumpEventQueue();
      expect(controller.isActive(MediaType.audio), isFalse);
    });

    test('one the reader stops is no longer kept for its edition', () async {
      final transfer = _RunningTransfer({
        MediaType.sheetMusic: const RunningTransfer(
          version: 'sda_old',
          result:
              MediaDownloadResult(downloaded: 2, failed: 0, cancelled: true),
        ),
      });
      final stopped = <(String, String)>[];
      final controller = OfflineDownloadController(
        downloader: EditionMediaDownloader(
          cache: MemoryMediaCache(),
          transfer: transfer,
        ),
      );

      await controller.resumeRunningDownloads(
        onStopped: (version, type) => stopped.add((version, type)),
      );
      transfer.finish.complete();
      await pumpEventQueue();

      expect(stopped, [('sda_old', MediaType.sheetMusic)]);
    });

    test('with nothing running, nothing starts', () async {
      final controller = OfflineDownloadController(
        downloader: EditionMediaDownloader(
          cache: MemoryMediaCache(),
          transfer: _RunningTransfer({}),
        ),
      );

      await controller.resumeRunningDownloads();

      expect(controller.isActive(MediaType.audio), isFalse);
      expect(controller.isActive(MediaType.sheetMusic), isFalse);
    });
  });

  group('a download the app was closed in the middle of', () {
    test('is planned again and carries on with what is missing', () async {
      final cache = MemoryMediaCache()..stored['a' * 64] = 1000;
      final controller = OfflineDownloadController(
        downloader: EditionMediaDownloader(cache: cache),
      );
      final ended = <(String, String)>[];

      await controller.resumeRunningDownloads(
        unfinished: const [('sda_new', MediaType.audio)],
        loadHymns: (version) async =>
            [_hymn(1, audio: 'a'), _hymn(2, audio: 'b')],
        onEnded: (version, type) => ended.add((version, type)),
      );
      expect(controller.isActive(MediaType.audio), isTrue);
      await pumpEventQueue();

      // Only the file that never arrived is fetched.
      expect(cache.downloads.map((d) => d.checksumSha256), ['b' * 64]);
      expect(ended, [('sda_new', MediaType.audio)]);
      expect(controller.isActive(MediaType.audio), isFalse);
    });

    test('with everything already here, it is simply marked ended', () async {
      final cache = MemoryMediaCache()..stored['a' * 64] = 1000;
      final controller = OfflineDownloadController(
        downloader: EditionMediaDownloader(cache: cache),
      );
      final ended = <(String, String)>[];

      await controller.resumeRunningDownloads(
        unfinished: const [('sda_new', MediaType.audio)],
        loadHymns: (version) async => [_hymn(1, audio: 'a')],
        onEnded: (version, type) => ended.add((version, type)),
      );

      expect(controller.isActive(MediaType.audio), isFalse);
      expect(cache.downloads, isEmpty);
      expect(ended, [('sda_new', MediaType.audio)]);
    });

    test('an edition that cannot be read yet is left for next time', () async {
      final controller = OfflineDownloadController(
        downloader: EditionMediaDownloader(cache: MemoryMediaCache()),
      );
      final ended = <(String, String)>[];

      await controller.resumeRunningDownloads(
        unfinished: const [('sda_new', MediaType.audio)],
        loadHymns: (version) async => throw StateError('not synced yet'),
        onEnded: (version, type) => ended.add((version, type)),
      );

      expect(controller.isActive(MediaType.audio), isFalse);
      expect(ended, isEmpty, reason: 'the entry must survive');
    });
  });
}
