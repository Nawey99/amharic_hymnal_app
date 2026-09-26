import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

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
}
