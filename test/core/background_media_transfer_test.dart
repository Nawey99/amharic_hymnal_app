import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:amharic_hymnal_app/core/services/background_media_transfer.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/offline_media_download.dart';

/// The system's download queue, in memory: tasks stay "running" until the
/// test finishes, fails or cancels them.
class _FakePort implements DownloaderPort {
  final _updates = StreamController<TaskUpdate>.broadcast();
  final Map<String, DownloadTask> running = {};
  final List<DownloadTask> enqueued = [];
  final List<String> cancelledGroups = [];
  int starts = 0;
  bool refuse = false;

  @override
  Stream<TaskUpdate> get updates => _updates.stream;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> get settled async {}

  /// How many times the transfer called [enqueueAll].
  int batches = 0;

  /// Task IDs the plugin has records of. It does not run a task again under
  /// an ID it has already finished.
  final Set<String> knownIds = {};

  @override
  Future<List<bool>> enqueueAll(List<DownloadTask> tasks) async {
    batches++;
    final accepted = <bool>[];
    for (final task in tasks) {
      if (refuse || !knownIds.add(task.taskId)) {
        accepted.add(false);
        continue;
      }
      enqueued.add(task);
      running[task.taskId] = task;
      _updates.add(TaskStatusUpdate(task, TaskStatus.enqueued));
      accepted.add(true);
    }
    return accepted;
  }

  @override
  Future<List<Task>> tasksIn(String group) async =>
      running.values.where((task) => task.group == group).toList();

  @override
  Future<void> cancelGroup(String group) async {
    cancelledGroups.add(group);
    for (final task in await tasksIn(group)) {
      running.remove(task.taskId);
      _updates.add(TaskStatusUpdate(task, TaskStatus.canceled));
    }
  }

  /// Where each file was asked to go, by file name. A Task keeps its
  /// directory with any leading separator stripped (on Linux `/tmp/x`
  /// becomes `tmp/x`), so the real path is remembered rather than rebuilt.
  final Map<String, String> _paths = {};

  @override
  Future<(BaseDirectory, String, String)> split(String filePath) async {
    _paths[path.basename(filePath)] = filePath;
    return (
      BaseDirectory.root,
      path.dirname(filePath),
      path.basename(filePath)
    );
  }

  @override
  Future<String> filePathOf(Task task) async => pathOf(task);

  /// [task]'s file: as split, or rebuilt with the separator a Task strips.
  String pathOf(Task task) {
    final known = _paths[task.filename];
    if (known != null) return known;
    final directory = path.isAbsolute(task.directory)
        ? task.directory
        : '${path.separator}${task.directory}';
    return path.join(directory, task.filename);
  }

  void progress(DownloadTask task, double fraction) =>
      _updates.add(TaskProgressUpdate(task, fraction));

  /// The system finishes [task], writing [bytes] where it was told to.
  Future<void> finish(DownloadTask task, List<int> bytes) async {
    final file = File(pathOf(task));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    running.remove(task.taskId);
    _updates.add(TaskStatusUpdate(task, TaskStatus.complete));
  }

  void fail(DownloadTask task) {
    running.remove(task.taskId);
    _updates.add(TaskStatusUpdate(task, TaskStatus.failed));
  }
}

void main() {
  late Directory root;
  late LocalMediaCacheService cache;
  late _FakePort port;
  late BackgroundMediaTransfer transfer;

  final first = utf8.encode('first page');
  final second = utf8.encode('second page, a little longer');
  MediaSource sourceOf(List<int> bytes, String name) => MediaSource(
        Uri.parse('https://api.example.test/api/v1/$name/file'),
        checksumSha256: sha256.convert(bytes).toString(),
        sizeBytes: bytes.length,
        contentType: 'image/webp',
      );

  MediaDownloadPlan planOf(List<MediaSource> missing) => MediaDownloadPlan(
        mediaType: MediaType.sheetMusic,
        itemCount: missing.length,
        missing: missing,
      );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('background_transfer');
    cache = LocalMediaCacheService(directoryProvider: () async => root);
    port = _FakePort();
    transfer = BackgroundMediaTransfer(
      cache: cache,
      port: port,
      pollInterval: const Duration(milliseconds: 5),
      recheckInterval: const Duration(milliseconds: 50),
    );
  });

  tearDown(() => root.delete(recursive: true));

  /// Lets real file work (staging, hashing) finish: the event queue alone
  /// does not cover file I/O. With [enqueued], also waits (up to a deadline)
  /// until that many files have been handed over, so a slow machine does
  /// not make the test read the queue too early.
  Future<void> settle({int enqueued = 0}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (
        port.enqueued.length < enqueued && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test('each missing file goes to the system once, into a staging name',
      () async {
    final a = sourceOf(first, 'a');
    final running = transfer.download(planOf([a]), version: 'sda_new');
    await settle(enqueued: 1);

    final task = port.enqueued.single;
    expect(task.group, BackgroundMediaTransfer.groupFor(MediaType.sheetMusic));
    expect(task.url, a.uri.toString());
    expect(task.filename, '${a.checksumSha256}.webp.unverified');
    expect(path.basename(task.directory), 'incoming');
    expect(jsonDecode(task.metaData),
        {'size': first.length, 'version': 'sda_new'});

    await port.finish(task, first);
    final result = await running;

    expect(result.downloaded, 1);
    expect(result.failed, 0);
    expect(await cache.cachedPath(a, MediaType.sheetMusic), isNotNull);
  });

  test('a finished file whose checksum is wrong is thrown away', () async {
    final a = sourceOf(first, 'a');
    final running = transfer.download(planOf([a]));
    await settle(enqueued: 1);

    await port.finish(port.enqueued.single, utf8.encode('tampered bytes'));
    final result = await running;

    expect(result.downloaded, 0);
    expect(result.failed, 1);
    expect(await cache.cachedPath(a, MediaType.sheetMusic), isNull);
    final leftovers = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith(LocalMediaCacheService.stagedSuffix));
    expect(leftovers, isEmpty);
  });

  test('the whole plan is handed to the system in one call', () async {
    final running = transfer.download(
      planOf([sourceOf(first, 'a'), sourceOf(second, 'b')]),
    );
    await settle(enqueued: 2);

    expect(port.batches, 1);
    expect(port.enqueued, hasLength(2));
    await port.finish(port.enqueued[0], first);
    await port.finish(port.enqueued[1], second);
    expect((await running).downloaded, 2);
  });

  test('progress adds up across files and ends at the total', () async {
    final a = sourceOf(first, 'a');
    final b = sourceOf(second, 'b');
    final reports = <(int, int)>[];
    final running = transfer.download(
      planOf([a, b]),
      onProgress: (done, total) => reports.add((done, total)),
    );
    await settle(enqueued: 2);
    final total = first.length + second.length;

    port.progress(port.enqueued[0], 0.5);
    await settle(enqueued: 2);
    expect(reports.last, ((first.length * 0.5).round(), total));

    await port.finish(port.enqueued[0], first);
    port.fail(port.enqueued[1]);
    final result = await running;

    expect(reports.last, (total, total));
    expect(result.downloaded, 1);
    expect(result.failed, 1);
  });

  test('stopping cancels what is still running', () async {
    var stop = false;
    final running = transfer.download(
      planOf([sourceOf(first, 'a'), sourceOf(second, 'b')]),
      isCancelled: () => stop,
    );
    await settle(enqueued: 2);
    await port.finish(port.enqueued[0], first);

    stop = true;
    final result = await running;

    expect(port.cancelledGroups,
        [BackgroundMediaTransfer.groupFor(MediaType.sheetMusic)]);
    expect(result.cancelled, isTrue);
    expect(result.downloaded, 1);
    expect(result.failed, 0, reason: 'a stopped file is not a failure');
  });

  test('a file that finished while the app was closed is put away first',
      () async {
    final a = sourceOf(first, 'a');
    final staged = await cache.stagingFileFor(a, MediaType.sheetMusic);
    await staged.parent.create(recursive: true);
    await staged.writeAsBytes(first);

    final result = await transfer.download(planOf([a]));

    expect(port.enqueued, isEmpty);
    expect(result.downloaded, 1);
    expect(await cache.cachedPath(a, MediaType.sheetMusic), isNotNull);
  });

  test('a file already on its way is not sent again', () async {
    final a = sourceOf(first, 'a');
    unawaited(transfer.download(planOf([a])));
    await settle(enqueued: 1);
    final task = port.enqueued.single;

    final again = transfer.download(planOf([a]));
    await settle(enqueued: 1);
    expect(port.enqueued, hasLength(1));

    await port.finish(task, first);
    expect((await again).downloaded, 1);
  });

  test('a file fetched before can be fetched again later', () async {
    final a = sourceOf(first, 'a');
    final once = transfer.download(planOf([a]));
    await settle(enqueued: 1);
    await port.finish(port.enqueued.single, first);
    expect((await once).downloaded, 1);

    // The file goes (e.g. pruned after a re-scan) and is wanted again.
    final cached = await cache.cachedPath(a, MediaType.sheetMusic);
    await File(cached!).delete();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final again = transfer.download(planOf([a]));
    await settle(enqueued: 2);

    expect(port.enqueued, hasLength(2));
    expect(port.enqueued.last.taskId, isNot(port.enqueued.first.taskId));
    await port.finish(port.enqueued.last, first);
    expect((await again).downloaded, 1);
  });

  test('a refused file counts as failed and does not hang', () async {
    port.refuse = true;
    final result = await transfer.download(planOf([sourceOf(first, 'a')]));

    expect(result.failed, 1);
    expect(result.downloaded, 0);
  });

  group('after the app was closed and opened again', () {
    test('running downloads are followed to the end', () async {
      final a = sourceOf(first, 'a');
      unawaited(transfer.download(planOf([a]), version: 'sda_old'));
      await settle(enqueued: 1);
      final task = port.enqueued.single;

      // A new app run: a new transfer over the same system queue.
      final reopened = BackgroundMediaTransfer(
        cache: cache,
        port: port,
        pollInterval: const Duration(milliseconds: 5),
        recheckInterval: const Duration(milliseconds: 50),
      );
      expect(await reopened.hasRunning(MediaType.sheetMusic), isTrue);
      final resumed = reopened.resume(MediaType.sheetMusic);
      await settle();
      await port.finish(task, first);

      final running = await resumed;
      expect(running?.version, 'sda_old');
      expect(running?.result.downloaded, 1);
      expect(await cache.cachedPath(a, MediaType.sheetMusic), isNotNull);
    });

    test('with nothing running there is nothing to follow', () async {
      expect(await transfer.hasRunning(MediaType.audio), isFalse);
      expect(await transfer.resume(MediaType.audio), isNull);
    });

    test('a finished update that never arrived is caught by the recheck',
        () async {
      final a = sourceOf(first, 'a');
      final running = transfer.download(planOf([a]));
      await settle(enqueued: 1);
      final task = port.enqueued.single;

      // The file arrives and the system forgets the task, but the app was
      // suspended and missed the update.
      final file = File(port.pathOf(task));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(first);
      port.running.remove(task.taskId);

      final result = await running;
      expect(result.downloaded, 1);
    });
  });

  test('the total is the whole plan from the first report', () async {
    final a = sourceOf(first, 'a');
    final b = sourceOf(second, 'b');
    final totals = <int>{};
    final running = transfer.download(
      planOf([a, b]),
      onProgress: (_, total) => totals.add(total),
    );
    await settle(enqueued: 2);
    port.progress(port.enqueued.first, 0.1);
    await settle(enqueued: 2);
    await port.finish(port.enqueued[0], first);
    await port.finish(port.enqueued[1], second);
    await running;

    expect(totals, {first.length + second.length});
  });

  test('a file that lands while nothing is being followed is put away',
      () async {
    await transfer.start();
    // The system re-sends a task after a Force stop and finishes it while
    // no download is being followed.
    final a = sourceOf(first, 'a');
    final staged = await cache.stagingFileFor(a, MediaType.audio);
    final task = DownloadTask(
      taskId: 'audio-resent',
      url: a.uri.toString(),
      filename: path.basename(staged.path),
      directory: staged.parent.path,
      baseDirectory: BaseDirectory.root,
      group: BackgroundMediaTransfer.groupFor(MediaType.audio),
    );
    port.running[task.taskId] = task;
    await port.finish(task, first);
    await settle();

    expect(await cache.cachedPath(a, MediaType.audio), isNotNull);
    expect(await staged.exists(), isFalse);
  });

  group('putting staged files away', () {
    test('every finished file is checked and promoted at start-up', () async {
      final a = sourceOf(first, 'a');
      final b = sourceOf(second, 'b');
      for (final (source, bytes) in [(a, first), (b, utf8.encode('bad'))]) {
        final staged = await cache.stagingFileFor(source, MediaType.audio);
        await staged.parent.create(recursive: true);
        await staged.writeAsBytes(bytes);
      }

      expect(await cache.promoteAllStaged(), 1);
      expect(await cache.cachedPath(a, MediaType.audio), isNotNull);
      expect(await cache.cachedPath(b, MediaType.audio), isNull);
    });
  });
}
