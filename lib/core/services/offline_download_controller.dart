import 'package:flutter/foundation.dart';

import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/offline_media_download.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// Runs one whole-edition download: reports progress in bytes and stops
/// early once [isCancelled] turns true.
typedef OfflineDownloadRun = Future<MediaDownloadResult> Function(
  void Function(int doneBytes, int totalBytes) onProgress,
  bool Function() isCancelled,
);

/// Whole-edition downloads running in the background while the app stays
/// usable. One media type at a time, in the order they were started, so
/// sheet music and audio do not split the connection.
///
/// Files already saved stay saved if the app closes mid-download; starting
/// again fetches only what is still missing.
///
/// Also knows, for the edition on screen, what of its sheet music and audio
/// is on the phone, rechecked after every sync and every download.
class OfflineDownloadController extends ChangeNotifier {
  OfflineDownloadController({EditionMediaDownloader? downloader})
      : downloader = downloader ?? EditionMediaDownloader();

  static final OfflineDownloadController instance = OfflineDownloadController();

  final EditionMediaDownloader downloader;

  String? _statusVersion;
  List<Hymn> _statusHymns = const [];
  final Map<String, MediaDownloadPlan> _status = {};
  int _statusGeneration = 0;

  /// The edition [statusOf] describes, or null before any edition synced.
  String? get statusVersion => _statusVersion;

  /// What of [mediaType] the edition has, and which files are missing; null
  /// until the edition has come from the server.
  MediaDownloadPlan? statusOf(String mediaType) => _status[mediaType];

  /// Rechecks [version]'s files against the phone, from its synced [hymns].
  Future<void> updateStatus(String version, List<Hymn> hymns) {
    if (version != _statusVersion) _status.clear();
    _statusVersion = version;
    _statusHymns = hymns;
    return _recheck();
  }

  /// Forgets the state, e.g. while an edition has not come from the server.
  void clearStatus() {
    _statusGeneration++;
    _statusVersion = null;
    _statusHymns = const [];
    _status.clear();
    notifyListeners();
  }

  Future<void> _recheck() async {
    final version = _statusVersion;
    if (version == null) return;
    final generation = ++_statusGeneration;
    final hymns = _statusHymns;
    final Map<String, MediaDownloadPlan> plans;
    try {
      plans = {
        for (final mediaType in const [MediaType.sheetMusic, MediaType.audio])
          mediaType: await downloader.plan(hymns, mediaType),
      };
    } catch (_) {
      return; // Storage unreadable: keep the last known state.
    }
    // A newer sync or another edition overtook this check.
    if (generation != _statusGeneration) return;
    _status
      ..clear()
      ..addAll(plans);
    notifyListeners();
  }

  final List<_Job> _queue = [];
  final Map<String, ({int done, int total})> _progress = {};
  final Set<String> _cancelled = {};
  String? _running;

  /// Progress arrives with every network chunk from several files at once;
  /// listeners hear about it at most this often, so the screens showing it
  /// are not rebuilt hundreds of times a second.
  static const progressInterval = Duration(milliseconds: 100);
  DateTime? _lastProgressNotice;

  /// Whether a download of [mediaType] is queued or running.
  bool isActive(String mediaType) => _progress.containsKey(mediaType);

  /// Whether [mediaType] is waiting for another download to finish.
  bool isQueued(String mediaType) =>
      isActive(mediaType) && _running != mediaType;

  /// From 0 to 1 while active, otherwise null.
  double? progressOf(String mediaType) {
    final bytes = _progress[mediaType];
    if (bytes == null) return null;
    return bytes.total == 0 ? 0 : bytes.done / bytes.total;
  }

  /// Bytes downloaded so far and in all, while active; otherwise null.
  ({int done, int total})? bytesOf(String mediaType) => _progress[mediaType];

  /// Queues [run]. [onDone] gets the result once it ends, finished or
  /// stopped. Returns false, and runs nothing, if [mediaType] is already
  /// active.
  bool start(
    String mediaType,
    OfflineDownloadRun run, {
    required void Function(MediaDownloadResult result) onDone,
  }) {
    if (isActive(mediaType)) return false;
    _progress[mediaType] = (done: 0, total: 0);
    _queue.add(_Job(mediaType, run, onDone));
    notifyListeners();
    _runQueue();
    return true;
  }

  /// Carries on whole-edition downloads the app was closed in the middle
  /// of, and shows those still running, so their progress shows and Stop
  /// works. Called once the app has started.
  ///
  /// [unfinished] lists the (version, media type) downloads that never got
  /// to end; each is planned again from [loadHymns] and downloaded, which
  /// follows the files the system still has and sends the rest. Without an
  /// entry, files still running are simply followed. [onEnded] hears when
  /// one ends; [onStopped] when the reader stopped it.
  Future<void> resumeRunningDownloads({
    List<(String, String)> unfinished = const [],
    Future<List<Hymn>> Function(String version)? loadHymns,
    void Function(String version, String mediaType)? onEnded,
    void Function(String version, String mediaType)? onStopped,
  }) async {
    final transfer = downloader.transfer;
    for (final mediaType in const [MediaType.sheetMusic, MediaType.audio]) {
      if (isActive(mediaType)) continue;

      final version = [
        for (final (version, type) in unfinished)
          if (type == mediaType) version,
      ].firstOrNull;
      if (version != null && loadHymns != null) {
        final MediaDownloadPlan plan;
        try {
          plan = await downloader.plan(await loadHymns(version), mediaType);
        } catch (_) {
          continue; // Not readable yet; the entry stays for next time.
        }
        if (plan.missing.isEmpty) {
          onEnded?.call(version, mediaType);
          continue;
        }
        start(
          mediaType,
          (onProgress, isCancelled) => downloader.download(
            plan,
            onProgress: onProgress,
            isCancelled: isCancelled,
            version: version,
          ),
          onDone: (result) {
            onEnded?.call(version, mediaType);
            if (result.cancelled) onStopped?.call(version, mediaType);
          },
        );
        continue;
      }

      if (!await transfer.hasRunning(mediaType)) continue;
      start(
        mediaType,
        (onProgress, isCancelled) async {
          final running = await transfer.resume(
            mediaType,
            onProgress: onProgress,
            isCancelled: isCancelled,
          );
          if (running == null) {
            return const MediaDownloadResult(
              downloaded: 0,
              failed: 0,
              cancelled: false,
            );
          }
          final version = running.version;
          if (running.result.cancelled && version != null) {
            onStopped?.call(version, mediaType);
          }
          return running.result;
        },
        onDone: (_) {},
      );
    }
  }

  /// Stops [mediaType]: a queued download never starts, a running one
  /// finishes the files in flight and then stops.
  void stop(String mediaType) {
    if (!isActive(mediaType)) return;
    final queued = _queue.indexWhere((job) => job.mediaType == mediaType);
    if (queued >= 0) {
      final job = _queue.removeAt(queued);
      _progress.remove(mediaType);
      notifyListeners();
      job.onDone(
        const MediaDownloadResult(downloaded: 0, failed: 0, cancelled: true),
      );
      return;
    }
    _cancelled.add(mediaType);
  }

  Future<void> _runQueue() async {
    if (_running != null) return;
    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      _running = job.mediaType;
      notifyListeners();

      MediaDownloadResult result;
      try {
        result = await job.run(
          (done, total) {
            _progress[job.mediaType] = (done: done, total: total);
            final now = DateTime.now();
            final last = _lastProgressNotice;
            if (last == null ||
                done >= total ||
                now.isBefore(last) ||
                now.difference(last) >= progressInterval) {
              _lastProgressNotice = now;
              notifyListeners();
            }
          },
          () => _cancelled.contains(job.mediaType),
        );
      } catch (_) {
        result = const MediaDownloadResult(
          downloaded: 0,
          failed: 1,
          cancelled: false,
        );
      }

      _progress.remove(job.mediaType);
      _cancelled.remove(job.mediaType);
      _running = null;
      notifyListeners();
      job.onDone(result);
      await _recheck();
    }
  }
}

class _Job {
  final String mediaType;
  final OfflineDownloadRun run;
  final void Function(MediaDownloadResult result) onDone;

  _Job(this.mediaType, this.run, this.onDone);
}
