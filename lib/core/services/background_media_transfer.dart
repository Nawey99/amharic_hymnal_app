import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:path/path.dart' as path;

import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/offline_media_download.dart';

/// Moves a whole edition's missing media onto the phone.
abstract interface class MediaTransfer {
  /// Downloads [plan]'s missing files. [onProgress] reports bytes;
  /// [isCancelled] is polled and stops what has not finished.
  Future<MediaDownloadResult> download(
    MediaDownloadPlan plan, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  });

  /// Whether downloads of [mediaType] started earlier are still running,
  /// e.g. after the app was closed and opened again.
  Future<bool> hasRunning(String mediaType);

  /// Follows downloads of [mediaType] that are still running, as
  /// [download] would have. Null when there are none.
  Future<RunningTransfer?> resume(
    String mediaType, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  });
}

/// Downloads that were already running when the app picked them up.
class RunningTransfer {
  /// The edition they were started for.
  final String? version;
  final MediaDownloadResult result;

  const RunningTransfer({required this.version, required this.result});
}

/// Downloads inside the app, a few at a time. They stop if the phone
/// suspends or closes the app. Used where background transfer does not
/// exist (desktop, web, tests).
class InProcessMediaTransfer implements MediaTransfer {
  InProcessMediaTransfer(this.cache);

  final MediaCache cache;

  @override
  Future<MediaDownloadResult> download(
    MediaDownloadPlan plan, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) =>
      downloadMissingMedia(
        cache,
        plan,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );

  @override
  Future<bool> hasRunning(String mediaType) async => false;

  @override
  Future<RunningTransfer?> resume(
    String mediaType, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) async =>
      null;
}

/// The part of `background_downloader` this app uses, so it can be faked.
abstract interface class DownloaderPort {
  /// Every task's status and progress, as a broadcast stream.
  Stream<TaskUpdate> get updates;

  /// Starts tracking and picks up updates that arrived while the app was
  /// away. Safe to call repeatedly.
  Future<void> start();

  /// Completes once tasks the system killed (e.g. by Force stop) have been
  /// handed back to it, a few seconds after [start]. Ask what is running
  /// only after this, or those tasks are missed.
  Future<void> get settled;

  /// Hands [tasks] to the system in one go; one result per task.
  Future<List<bool>> enqueueAll(List<DownloadTask> tasks);

  /// Tasks of [group] still queued or running on the platform.
  Future<List<Task>> tasksIn(String group);

  Future<void> cancelGroup(String group);

  /// Where [filePath] lies, as a task names it.
  Future<(BaseDirectory, String, String)> split(String filePath);

  /// The file [task] writes.
  Future<String> filePathOf(Task task);
}

/// [DownloaderPort] over `FileDownloader`: WorkManager on Android, a
/// background `URLSession` on iOS. Transfers carry on while the app is in
/// the background or closed, unless the phone restricts background work.
///
/// Every file is handed to the system at once rather than through the
/// plugin's in-app holding queue: that queue lives in the app's memory, so
/// on iOS nothing in it would start while the app is suspended. The systems
/// limit concurrency themselves (WorkManager runs a handful of workers; iOS
/// limits connections per host), which keeps within the API's rate limits.
class FileDownloaderPort implements DownloaderPort {
  final _updates = StreamController<TaskUpdate>.broadcast();
  final _settled = Completer<void>();
  Future<void>? _started;

  @override
  Stream<TaskUpdate> get updates => _updates.stream;

  @override
  Future<void> get settled => _settled.future;

  @override
  Future<void> start() => _started ??= () async {
        // The plugin's stream allows one listener; this is it.
        FileDownloader().updates.listen(_updates.add);
        // autoCleanDatabase: drop records of long-finished tasks.
        await FileDownloader().start(
          doRescheduleKilledTasks: false,
          autoCleanDatabase: true,
        );
        // The plugin's own timing: give the platform's queue a moment to
        // report what it still has before re-sending what it lost.
        Timer(const Duration(seconds: 5), () async {
          try {
            await FileDownloader().rescheduleKilledTasks();
          } catch (_) {
            // Nothing to reschedule, or tracking unavailable.
          } finally {
            _settled.complete();
          }
        });
      }();

  @override
  Future<List<bool>> enqueueAll(List<DownloadTask> tasks) =>
      FileDownloader().enqueueAll(tasks);

  @override
  Future<List<Task>> tasksIn(String group) =>
      FileDownloader().allTasks(group: group);

  @override
  Future<void> cancelGroup(String group) =>
      FileDownloader().cancelAll(group: group);

  @override
  Future<(BaseDirectory, String, String)> split(String filePath) =>
      Task.split(filePath: filePath);

  @override
  Future<String> filePathOf(Task task) => task.filePath();
}

/// Whole-edition downloads handed to the platform, so they continue with
/// the app in the background or closed.
///
/// Each file lands as `<sha256>.<ext>.unverified` and only becomes cached
/// media once its checksum matches ([LocalMediaCacheService.promoteStaged]),
/// whether that happens as it finishes or the next time the app opens.
class BackgroundMediaTransfer implements MediaTransfer {
  BackgroundMediaTransfer({
    required this.cache,
    required this.port,
    this.pollInterval = const Duration(milliseconds: 500),
    this.recheckInterval = const Duration(seconds: 30),
  });

  /// The app's instance on Android and iOS; null where background transfer
  /// does not exist.
  static final BackgroundMediaTransfer? shared =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS)
          ? BackgroundMediaTransfer(
              cache: LocalMediaCacheService.instance,
              port: FileDownloaderPort(),
            )
          : null;

  final LocalMediaCacheService cache;
  final DownloaderPort port;

  /// How often cancellation is checked.
  final Duration pollInterval;

  /// How often the platform's queue is asked directly, in case an update
  /// was missed (e.g. while the app was suspended).
  final Duration recheckInterval;

  static const _groupPrefix = 'wudase-media-';

  static String groupFor(String mediaType) => '$_groupPrefix$mediaType';

  /// A task ID for [source] in this run. Unique per run: the plugin keeps
  /// records of finished tasks, and a file fetched again later (e.g. after a
  /// page was re-scanned) must not reuse a finished task's ID.
  static String _taskIdFor(String mediaType, MediaSource source, int run) =>
      '$mediaType-${source.checksumSha256 ?? source.uri.toString().hashCode}'
      '-$run';

  StreamSubscription<TaskUpdate>? _promoter;

  /// Starts tracking and puts away anything that finished while the app
  /// was closed. Call once at start-up; later calls are cheap.
  Future<void> start() async {
    try {
      await port.start();
      // Files can finish when no download is being followed, e.g. tasks the
      // system re-sends after a Force stop: check and put each one away as
      // it lands. Followers do the same; whichever is first wins.
      _promoter ??= port.updates
          .where((update) =>
              update is TaskStatusUpdate &&
              update.status == TaskStatus.complete &&
              update.task.group.startsWith(_groupPrefix))
          .listen((update) async {
        try {
          await cache.promoteStaged(File(await port.filePathOf(update.task)));
        } catch (_) {
          // Left staged; the next start-up sweep checks it.
        }
      });
      await cache.promoteAllStaged();
    } catch (error) {
      if (kDebugMode) debugPrint('Background downloads unavailable: $error');
    }
  }

  @override
  Future<MediaDownloadResult> download(
    MediaDownloadPlan plan, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
    String? version,
  }) async {
    await cache.prepareForTransfer();
    await start();

    final group = groupFor(plan.mediaType);
    final run = DateTime.now().microsecondsSinceEpoch;
    // Files already on their way: task ID by the file it will write.
    final running = {
      for (final task in await port.tasksIn(group)) task.filename: task.taskId,
    };
    final sizes = <String, int>{};
    final staged = <String, File>{};
    var failed = 0;

    final follower = _Follower(
      cache: cache,
      port: port,
      group: group,
      sizes: sizes,
      staged: staged,
      onProgress: onProgress,
      isCancelled: isCancelled,
      pollInterval: pollInterval,
      recheckInterval: recheckInterval,
    )..listen();

    // Every file's size up front, so the total shown is right from the
    // start rather than growing as files are handed over.
    for (final source in plan.missing) {
      sizes[_taskIdFor(plan.mediaType, source, run)] =
          source.sizeBytes ?? 1024 * 1024;
    }
    final tasks = <DownloadTask>[];
    for (final source in plan.missing) {
      final taskId = _taskIdFor(plan.mediaType, source, run);
      // Missing when planned, here now: it finished while the app was away.
      if (await cache.cachedPath(source, plan.mediaType) != null) {
        follower.settle(taskId, true);
        continue;
      }
      final file = await cache.stagingFileFor(source, plan.mediaType);
      staged[taskId] = file;
      // Finished while the app was away, not yet checked: check it now.
      if (await file.exists()) {
        follower.settle(taskId, await cache.promoteStaged(file));
        continue;
      }
      // Already on its way under an earlier task: follow that one instead
      // of sending the file twice.
      final earlier = running[path.basename(file.path)];
      if (earlier != null) {
        sizes[earlier] = sizes.remove(taskId)!;
        staged[earlier] = file;
        continue;
      }

      final (baseDirectory, directory, filename) = await port.split(file.path);
      tasks.add(DownloadTask(
        taskId: taskId,
        url: source.uri.toString(),
        filename: filename,
        directory: directory,
        baseDirectory: baseDirectory,
        group: group,
        updates: Updates.statusAndProgress,
        retries: 3,
        metaData: jsonEncode({
          'size': sizes[taskId],
          if (version != null) 'version': version,
        }),
      ));
    }

    // All at once: from this call the system (and the plugin's records)
    // hold every file, so closing the app straight after loses none.
    final accepted =
        tasks.isEmpty ? const <bool>[] : await port.enqueueAll(tasks);
    for (var i = 0; i < tasks.length; i++) {
      if (i >= accepted.length || !accepted[i]) {
        failed++;
        follower.settle(tasks[i].taskId, false, counted: false);
      }
    }

    final result = await follower.finish();
    return MediaDownloadResult(
      downloaded: result.downloaded,
      failed: result.failed + failed,
      cancelled: result.cancelled,
    );
  }

  @override
  Future<bool> hasRunning(String mediaType) async {
    try {
      await start();
      await port.settled;
      return (await port.tasksIn(groupFor(mediaType))).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<RunningTransfer?> resume(
    String mediaType, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    await start();
    await port.settled;
    final group = groupFor(mediaType);
    final sizes = <String, int>{};
    final staged = <String, File>{};
    final follower = _Follower(
      cache: cache,
      port: port,
      group: group,
      sizes: sizes,
      staged: staged,
      onProgress: onProgress,
      isCancelled: isCancelled,
      pollInterval: pollInterval,
      recheckInterval: recheckInterval,
    )..listen();

    final tasks = await port.tasksIn(group);
    if (tasks.isEmpty) {
      await follower.finish();
      return null;
    }
    String? version;
    for (final task in tasks) {
      final meta = _meta(task);
      sizes[task.taskId] = (meta['size'] as num?)?.toInt() ?? 1024 * 1024;
      version ??= meta['version'] as String?;
      staged[task.taskId] = File(await port.filePathOf(task));
    }
    return RunningTransfer(version: version, result: await follower.finish());
  }

  static Map<String, dynamic> _meta(Task task) {
    try {
      final decoded = jsonDecode(task.metaData);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}

/// Follows one group's tasks to the end: adds up progress, checks and puts
/// away each finished file, and cancels the rest when asked.
class _Follower {
  _Follower({
    required this.cache,
    required this.port,
    required this.group,
    required this.sizes,
    required this.staged,
    required this.onProgress,
    required this.isCancelled,
    required this.pollInterval,
    required this.recheckInterval,
  });

  final LocalMediaCacheService cache;
  final DownloaderPort port;
  final String group;

  /// Expected bytes and staging file by task ID, filled in as tasks are
  /// enqueued (or found, when resuming).
  final Map<String, int> sizes;
  final Map<String, File> staged;
  final void Function(int doneBytes, int totalBytes)? onProgress;
  final bool Function()? isCancelled;
  final Duration pollInterval;
  final Duration recheckInterval;

  final Map<String, int> _bytes = {};
  final Set<String> _settled = {};
  final Set<String> _working = {};
  final _done = Completer<void>();
  StreamSubscription<TaskUpdate>? _subscription;
  Timer? _poll;
  Timer? _recheck;
  var _downloaded = 0;
  var _failed = 0;
  var _cancelled = false;

  void listen() {
    _subscription = port.updates
        .where((update) => update.task.group == group)
        .listen(_onUpdate);
  }

  void _onUpdate(TaskUpdate update) {
    final taskId = update.task.taskId;
    switch (update) {
      case TaskProgressUpdate(:final progress):
        if (progress >= 0 && progress <= 1 && !_settled.contains(taskId)) {
          final size = sizes[taskId] ?? 0;
          _bytes[taskId] = (progress * size).round();
          _report();
        }
      case TaskStatusUpdate(:final status) when status.isFinalState:
        _onFinal(taskId, status, update.task);
      case TaskStatusUpdate():
        break;
    }
  }

  Future<void> _onFinal(String taskId, TaskStatus status, Task task) async {
    if (_settled.contains(taskId) || !_working.add(taskId)) return;
    try {
      var ok = false;
      if (status == TaskStatus.complete) {
        final file = staged[taskId] ?? File(await port.filePathOf(task));
        ok = await cache.promoteStaged(file) || await cache.isPromoted(file);
      } else if (status == TaskStatus.canceled) {
        _cancelled = true;
      }
      settle(taskId, ok, counted: status != TaskStatus.canceled);
    } finally {
      _working.remove(taskId);
      // settle() ran while this task still counted as in hand.
      _completeIfDone();
    }
  }

  /// Records [taskId] as finished: [ok] if its file is now cached.
  void settle(String taskId, bool ok, {bool counted = true}) {
    if (!_settled.add(taskId)) return;
    if (ok) {
      _downloaded++;
    } else if (counted) {
      _failed++;
    }
    _bytes[taskId] = sizes[taskId] ?? 0;
    _report();
    _completeIfDone();
  }

  void _report() {
    final total = sizes.values.fold(0, (sum, size) => sum + size);
    final done = _bytes.values.fold(0, (sum, bytes) => sum + bytes);
    onProgress?.call(done.clamp(0, total), total);
  }

  void _completeIfDone() {
    if (!_done.isCompleted &&
        _working.isEmpty &&
        sizes.keys.every(_settled.contains)) {
      _done.complete();
    }
  }

  /// Waits until every task in [sizes] has finished, then tidies up.
  Future<MediaDownloadResult> finish() async {
    _completeIfDone();
    _poll = Timer.periodic(pollInterval, (_) {
      if (!_cancelled && (isCancelled?.call() ?? false)) {
        _cancelled = true;
        unawaited(port.cancelGroup(group));
      }
    });
    _recheck = Timer.periodic(recheckInterval, (_) => unawaited(_reconcile()));
    try {
      await _done.future;
    } finally {
      _poll?.cancel();
      _recheck?.cancel();
      await _subscription?.cancel();
    }
    return MediaDownloadResult(
      downloaded: _downloaded,
      failed: _failed,
      cancelled: _cancelled || (isCancelled?.call() ?? false),
    );
  }

  /// Settles tasks the platform no longer has, in case their final update
  /// never reached the app.
  Future<void> _reconcile() async {
    try {
      final running = {for (final t in await port.tasksIn(group)) t.taskId};
      for (final taskId in sizes.keys.toList()) {
        if (_settled.contains(taskId) || running.contains(taskId)) continue;
        if (_working.contains(taskId)) continue;
        final file = staged[taskId];
        settle(
          taskId,
          file != null &&
              (await cache.promoteStaged(file) || await cache.isPromoted(file)),
        );
      }
    } catch (_) {
      // Try again at the next check.
    }
  }
}
