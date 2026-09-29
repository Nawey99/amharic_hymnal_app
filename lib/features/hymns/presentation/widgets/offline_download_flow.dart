import 'dart:async';

import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/offline_download_controller.dart';
import 'package:amharic_hymnal_app/core/services/offline_media_download.dart';
import 'package:amharic_hymnal_app/core/widgets/settings_tiles.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

/// Loads every hymn of an edition, as stored on the device.
typedef EditionHymnsLoader = Future<List<Hymn>> Function(String version);

/// Session-scoped cache: two `AllEditionsDownloadTile`s (sheet music and
/// audio) mount together, so without this each pays the load cost per
/// version, doubling the delay before the tiles render their aggregate.
final Map<String, Future<List<Hymn>>> _editionHymnsCache = {};

/// Clears the shared hymn cache; call after a sync so a later plan sees
/// the fresh content.
void invalidateEditionHymnsCache([String? version]) {
  if (version == null) {
    _editionHymnsCache.clear();
  } else {
    _editionHymnsCache.remove(version);
  }
}

Future<List<Hymn>> _loadEditionHymns(String version) {
  return _editionHymnsCache.putIfAbsent(version, () async {
    try {
      final result = await sl<HymnRepository>().getHymns(
        sl<SettingsRepository>().getSelectedLanguage(),
        version,
      );
      return result.fold((failure) => throw failure, (hymns) => hymns);
    } catch (error) {
      // Do not cache a failure: the next tile mount should retry.
      _editionHymnsCache.remove(version);
      rethrow;
    }
  });
}

/// Whether [hymns] came from the content API, which is what describes their
/// sheet music and audio. Hymns bundled with the app have neither yet.
bool hymnsAreFromServer(List<Hymn> hymns, String version) {
  final prefix = '${HymnalVersions.apiCode(version)}-';
  return hymns.any((hymn) => hymn.id?.startsWith(prefix) ?? false);
}

/// Changes to a kept edition are fetched without asking up to this size.
/// Beyond it the tile offers them instead: the app cannot tell Wi-Fi from
/// mobile data.
const int automaticUpdateLimitBytes = 25 * 1024 * 1024;

/// Locale-aware strings for one kind of download.
class _Words {
  final String tileTitle;
  final String tileDescription;
  final String confirmTitle;
  final String units;
  final String benefit;
  final String none;
  final String allPresent;
  final String started;
  final String finished;
  final String Function(int saved) stopped;
  final String Function(int count) failed;
  final String Function(int count) updated;
  final String Function(MediaDownloadPlan plan) allDownloaded;
  final String Function(MediaDownloadPlan plan) updatesAvailable;

  const _Words({
    required this.tileTitle,
    required this.tileDescription,
    required this.confirmTitle,
    required this.units,
    required this.benefit,
    required this.none,
    required this.allPresent,
    required this.started,
    required this.finished,
    required this.stopped,
    required this.failed,
    required this.updated,
    required this.allDownloaded,
    required this.updatesAvailable,
  });
}

_Words _wordsFor(AppLocalizations l, String mediaType) {
  final isAudio = mediaType == MediaType.audio;
  return _Words(
    tileTitle:
        isAudio ? l.downloadAllAudiosTitle : l.downloadAllSheetsTitle,
    tileDescription: isAudio
        ? l.downloadAllAudiosDescription
        : l.downloadAllSheetsDescription,
    confirmTitle: isAudio
        ? l.downloadAudiosConfirmTitle
        : l.downloadSheetsConfirmTitle,
    units: isAudio ? l.downloadUnitAudios : l.downloadUnitPages,
    benefit: isAudio ? l.downloadAudiosBenefit : l.downloadSheetsBenefit,
    none: isAudio ? l.downloadAudiosNone : l.downloadSheetsNone,
    allPresent: isAudio
        ? l.downloadAudiosAllPresent
        : l.downloadSheetsAllPresent,
    started: isAudio ? l.downloadAudiosStarted : l.downloadSheetsStarted,
    finished: isAudio ? l.downloadAudiosFinished : l.downloadSheetsFinished,
    stopped: (saved) => isAudio
        ? l.downloadAudiosStopped(saved)
        : l.downloadSheetsStopped(saved),
    failed: (count) => isAudio
        ? l.downloadAudiosFailed(count)
        : l.downloadSheetsFailed(count),
    updated: (count) => isAudio
        ? l.downloadAudiosUpdated(count)
        : l.downloadSheetsUpdated(count),
    allDownloaded: (plan) => l.downloadAllDone(
      plan.itemCount,
      isAudio ? l.downloadUnitAudios : l.downloadUnitPages,
      formatMediaSize(plan.totalBytes),
    ),
    updatesAvailable: (plan) => l.downloadUpdatesAvailable(
      plan.missing.length,
      isAudio ? l.downloadUnitAudios : l.downloadUnitPages,
      formatMediaSize(plan.missingBytes),
    ),
  );
}

void _say(ScaffoldMessengerState messenger, String message) {
  if (!messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Downloads [plan]'s missing files for [version] in the background and
/// keeps that kind of media on the phone from now on, so later additions are
/// fetched too. Stopping part-way stops keeping it.
///
/// [quiet] is for fetching an edition's changes: no message at the start,
/// and one at the end only if something arrived.
void startOfflineDownload(
  ScaffoldMessengerState messenger,
  AppLocalizations l,
  String version,
  MediaDownloadPlan plan, {
  bool quiet = false,
  OfflineDownloadController? controller,
  SettingsRepository? settings,
  void Function(MediaDownloadResult result)? onDone,
}) {
  final downloads = controller ?? OfflineDownloadController.instance;
  final preferences = settings ?? sl<SettingsRepository>();
  final words = _wordsFor(l, plan.mediaType);

  final started = downloads.start(
    plan.mediaType,
    (onProgress, isCancelled) => downloads.downloader.download(
      plan,
      onProgress: onProgress,
      isCancelled: isCancelled,
    ),
    onDone: (result) {
      if (result.cancelled) {
        preferences.setMediaKeptOffline(version, plan.mediaType, false);
        _say(messenger, words.stopped(result.downloaded));
      } else if (result.failed > 0) {
        _say(messenger, words.failed(result.failed));
      } else if (!quiet) {
        _say(messenger, words.finished);
      } else if (result.downloaded > 0) {
        _say(messenger, words.updated(result.downloaded));
      }
      onDone?.call(result);
    },
  );
  if (!started) {
    onDone?.call(
      const MediaDownloadResult(downloaded: 0, failed: 0, cancelled: true),
    );
    return;
  }
  preferences.setMediaKeptOffline(version, plan.mediaType, true);
  if (!quiet) _say(messenger, words.started);
}

/// Offers to install all of [mediaType] for [version]: states the size of
/// what is missing, then downloads it in the background. After a sync this
/// is only what was added or replaced.
Future<void> runEditionMediaDownload(
  BuildContext context,
  String version,
  String mediaType, {
  EditionHymnsLoader? loadHymns,
  OfflineDownloadController? controller,
  SettingsRepository? settings,
}) async {
  final downloads = controller ?? OfflineDownloadController.instance;
  final preferences = settings ?? sl<SettingsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context)!;
  final words = _wordsFor(l, mediaType);

  final List<Hymn> hymns;
  try {
    hymns = await (loadHymns ?? _loadEditionHymns)(version);
  } catch (_) {
    _say(messenger, l.downloadListUnavailable);
    return;
  }
  if (!hymnsAreFromServer(hymns, version)) {
    _say(messenger, l.downloadNeedInternet);
    return;
  }
  final plan = await downloads.downloader.plan(hymns, mediaType);
  if (plan.itemCount == 0) {
    _say(messenger, words.none);
    return;
  }
  if (plan.missing.isEmpty) {
    // Already all here: keep it that way as the edition changes.
    await preferences.setMediaKeptOffline(version, mediaType, true);
    _say(messenger, words.allPresent);
    return;
  }
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.appColors.surface,
      title: Text(
        words.confirmTitle,
        style: TextStyle(color: context.appColors.primaryText),
      ),
      content: Text(
        _confirmBodySingle(l, version, plan, words),
        style: TextStyle(color: context.appColors.secondaryText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.downloadCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.downloadStart),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  startOfflineDownload(
    messenger,
    l,
    version,
    plan,
    controller: downloads,
    settings: preferences,
  );
}

String _confirmBodySingle(
  AppLocalizations l,
  String version,
  MediaDownloadPlan plan,
  _Words words,
) {
  return l.downloadConfirmBodySingle(
    l.hymnalLabelEn(version),
    plan.missing.length,
    words.units,
    formatMediaSize(plan.missingBytes),
    words.benefit,
  );
}

/// Plans and (with confirmation) downloads [mediaType] across every version
/// in [versions] sequentially.
Future<void> runAllEditionsMediaDownload(
  BuildContext context,
  List<String> versions,
  String mediaType, {
  EditionHymnsLoader? loadHymns,
  OfflineDownloadController? controller,
  SettingsRepository? settings,
}) async {
  final downloads = controller ?? OfflineDownloadController.instance;
  final preferences = settings ?? sl<SettingsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context)!;
  final words = _wordsFor(l, mediaType);

  final List<_EditionPlan> perEdition = [];
  int aggregateItemCount = 0;
  int aggregateMissingCount = 0;
  int aggregateMissingBytes = 0;
  bool anyServerMissing = false;

  for (final version in versions) {
    final List<Hymn> hymns;
    try {
      hymns = await (loadHymns ?? _loadEditionHymns)(version);
    } catch (_) {
      _say(messenger, l.downloadListUnavailable);
      return;
    }
    if (!hymnsAreFromServer(hymns, version)) {
      anyServerMissing = true;
      continue;
    }
    final plan = await downloads.downloader.plan(hymns, mediaType);
    aggregateItemCount += plan.itemCount;
    aggregateMissingCount += plan.missing.length;
    aggregateMissingBytes += plan.missingBytes;
    perEdition.add(_EditionPlan(version: version, plan: plan));
  }

  final noneMessage = mediaType == MediaType.audio
      ? l.downloadAudiosNoneAll
      : l.downloadSheetsNoneAll;

  if (perEdition.isEmpty) {
    _say(messenger, anyServerMissing ? l.downloadNeedInternet : noneMessage);
    return;
  }

  if (aggregateItemCount == 0) {
    _say(messenger, noneMessage);
    return;
  }

  if (aggregateMissingCount == 0) {
    for (final entry in perEdition) {
      await preferences.setMediaKeptOffline(entry.version, mediaType, true);
    }
    _say(messenger, words.allPresent);
    return;
  }

  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.appColors.surface,
      title: Text(
        words.confirmTitle,
        style: TextStyle(color: context.appColors.primaryText),
      ),
      content: Text(
        l.downloadConfirmBodyAll(
          aggregateMissingCount,
          words.units,
          formatMediaSize(aggregateMissingBytes),
          words.benefit,
        ),
        style: TextStyle(color: context.appColors.secondaryText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.downloadCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.downloadStart),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  _runSequential(
    messenger,
    l,
    perEdition,
    controller: downloads,
    settings: preferences,
  );
}

class _EditionPlan {
  final String version;
  final MediaDownloadPlan plan;

  const _EditionPlan({required this.version, required this.plan});
}

void _runSequential(
  ScaffoldMessengerState messenger,
  AppLocalizations l,
  List<_EditionPlan> plans, {
  required OfflineDownloadController controller,
  required SettingsRepository settings,
}) {
  final pending = List<_EditionPlan>.of(
    plans.where((entry) => entry.plan.missing.isNotEmpty),
  );
  if (pending.isEmpty) return;

  void kickNext() {
    if (pending.isEmpty) return;
    final next = pending.removeAt(0);
    startOfflineDownload(
      messenger,
      l,
      next.version,
      next.plan,
      controller: controller,
      settings: settings,
      quiet: pending.isNotEmpty, // suppress mid-chain "started" toasts
      onDone: (_) => kickNext(),
    );
  }

  kickNext();
}

/// Fetches what a sync added to or replaced in the kept media of the
/// edition in [controller]'s state, up to [automaticUpdateLimitBytes] each.
/// Larger changes wait on the tile for a tap.
void downloadKeptMediaChanges(
  ScaffoldMessengerState messenger,
  AppLocalizations l, {
  OfflineDownloadController? controller,
  SettingsRepository? settings,
}) {
  final downloads = controller ?? OfflineDownloadController.instance;
  final preferences = settings ?? sl<SettingsRepository>();
  final version = downloads.statusVersion;
  if (version == null) return;

  for (final mediaType in const [MediaType.sheetMusic, MediaType.audio]) {
    final plan = downloads.statusOf(mediaType);
    if (plan == null ||
        plan.missing.isEmpty ||
        plan.missingBytes > automaticUpdateLimitBytes ||
        downloads.isActive(mediaType) ||
        !preferences.isMediaKeptOffline(version, mediaType)) {
      continue;
    }
    startOfflineDownload(
      messenger,
      l,
      version,
      plan,
      quiet: true,
      controller: downloads,
      settings: preferences,
    );
  }
}

/// A Settings tile for all of [mediaType] in [version]: offers the
/// download, shows its progress, then a tick once everything is on the
/// phone, or what a later sync added.
class OfflineDownloadTile extends StatelessWidget {
  final String mediaType;
  final String version;
  final OfflineDownloadController? controller;
  final SettingsRepository? settings;

  const OfflineDownloadTile({
    super.key,
    required this.mediaType,
    required this.version,
    this.controller,
    this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final downloads = controller ?? OfflineDownloadController.instance;
    final preferences = settings ?? sl<SettingsRepository>();
    final l = AppLocalizations.of(context)!;
    final words = _wordsFor(l, mediaType);

    return ListenableBuilder(
      listenable: downloads,
      builder: (context, _) {
        final plan = downloads.statusVersion == version
            ? downloads.statusOf(mediaType)
            : null;
        final complete =
            plan != null && plan.itemCount > 0 && plan.missing.isEmpty;
        final hasUpdates = plan != null &&
            plan.missing.isNotEmpty &&
            plan.missing.length < plan.itemCount &&
            preferences.isMediaKeptOffline(version, mediaType);

        final String description;
        final IconData icon;
        if (complete) {
          description = words.allDownloaded(plan);
          icon = Icons.check_circle;
        } else if (hasUpdates) {
          description = words.updatesAvailable(plan);
          icon = Icons.update;
        } else {
          description = plan == null || plan.missing.isEmpty
              ? words.tileDescription
              : '${words.tileDescription} · '
                  '${formatMediaSize(plan.missingBytes)}';
          icon = Icons.download_for_offline_outlined;
        }

        return SettingsTile(
          key: ValueKey('download-all-$mediaType'),
          trailingIcon: icon,
          title: words.tileTitle,
          description: description,
          progress: downloads.progressOf(mediaType),
          progressLabel: _progressLabel(l, downloads),
          onStop: () => downloads.stop(mediaType),
          onTap: () => runEditionMediaDownload(
            context,
            version,
            mediaType,
            controller: downloads,
            settings: preferences,
          ),
        );
      },
    );
  }

  String? _progressLabel(AppLocalizations l, OfflineDownloadController d) {
    if (d.isQueued(mediaType)) return l.downloadWaiting;
    final bytes = d.bytesOf(mediaType);
    if (bytes == null || bytes.total == 0) return null;
    final percent = (bytes.done * 100 / bytes.total).floor();
    return '$percent% · ${formatMediaSize(bytes.done)} / '
        '${formatMediaSize(bytes.total)}';
  }
}

/// Settings tile that plans downloads across every version in [versions]
/// (typically all of `HymnalVersions.all`).
///
/// Aggregates missing counts and sizes across editions for its description,
/// and on tap sequentially downloads what is missing in each one.
class AllEditionsDownloadTile extends StatefulWidget {
  final String mediaType;
  final List<String> versions;
  final OfflineDownloadController? controller;
  final SettingsRepository? settings;
  final EditionHymnsLoader? loadHymns;

  const AllEditionsDownloadTile({
    super.key,
    required this.mediaType,
    required this.versions,
    this.controller,
    this.settings,
    this.loadHymns,
  });

  @override
  State<AllEditionsDownloadTile> createState() =>
      _AllEditionsDownloadTileState();
}

class _AllEditionsDownloadTileState extends State<AllEditionsDownloadTile> {
  int _totalItems = 0;
  int _missingItems = 0;
  int _missingBytes = 0;
  int _totalBytes = 0;
  bool _planned = false;
  bool _refreshing = false;
  int _refreshGeneration = 0;
  bool _wasActiveForThisMediaType = false;

  OfflineDownloadController get _downloads =>
      widget.controller ?? OfflineDownloadController.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshAggregate());
    _downloads.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _downloads.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    // Only re-plan when this media type's activity transitions from
    // running to finished, or when [statusVersion] changed. Progress ticks
    // and other-media-type changes just repaint through setState.
    final activeNow = _downloads.isActive(widget.mediaType);
    final justFinished = _wasActiveForThisMediaType && !activeNow;
    _wasActiveForThisMediaType = activeNow;
    if (justFinished) {
      // A download just wrote new files: what is on disk changed, so drop
      // the shared hymn cache and re-plan.
      invalidateEditionHymnsCache();
      unawaited(_refreshAggregate());
    }
    if (mounted) setState(() {});
  }

  Future<void> _refreshAggregate() async {
    if (_refreshing) return; // avoid overlapping passes
    _refreshing = true;
    final generation = ++_refreshGeneration;
    try {
      int totalItems = 0;
      int missingItems = 0;
      int missingBytes = 0;
      int totalBytes = 0;
      for (final version in widget.versions) {
        try {
          final hymns =
              await (widget.loadHymns ?? _loadEditionHymns)(version);
          if (generation != _refreshGeneration) return;
          if (!hymnsAreFromServer(hymns, version)) continue;
          final plan =
              await _downloads.downloader.plan(hymns, widget.mediaType);
          if (generation != _refreshGeneration) return;
          totalItems += plan.itemCount;
          missingItems += plan.missing.length;
          missingBytes += plan.missingBytes;
          totalBytes += plan.totalBytes;
        } catch (_) {
          // Skip this edition on error; retry on the next transition.
        }
      }
      if (!mounted || generation != _refreshGeneration) return;
      setState(() {
        _totalItems = totalItems;
        _missingItems = missingItems;
        _missingBytes = missingBytes;
        _totalBytes = totalBytes;
        _planned = true;
      });
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final words = _wordsFor(l, widget.mediaType);
    final isActive = _downloads.isActive(widget.mediaType);
    final unit = words.units;

    final String description;
    final IconData icon;
    if (!_planned) {
      description = l.downloadChecking;
      icon = Icons.download_for_offline_outlined;
    } else if (_totalItems > 0 && _missingItems == 0) {
      description = l.downloadAllDone(
        _totalItems,
        unit,
        formatMediaSize(_totalBytes),
      );
      icon = Icons.check_circle;
    } else if (_missingItems > 0) {
      description = l.downloadUpdatesAvailable(
        _missingItems,
        unit,
        formatMediaSize(_missingBytes),
      );
      icon = _missingItems < _totalItems
          ? Icons.update
          : Icons.download_for_offline_outlined;
    } else {
      description = words.tileDescription;
      icon = Icons.download_for_offline_outlined;
    }

    return SettingsTile(
      key: ValueKey('download-all-editions-${widget.mediaType}'),
      trailingIcon: icon,
      title: words.tileTitle,
      description: description,
      progress: _downloads.progressOf(widget.mediaType),
      progressLabel: _progressLabel(l),
      onStop: isActive ? () => _downloads.stop(widget.mediaType) : null,
      onTap: () => runAllEditionsMediaDownload(
        context,
        widget.versions,
        widget.mediaType,
        controller: widget.controller,
        settings: widget.settings,
        loadHymns: widget.loadHymns,
      ),
    );
  }

  String? _progressLabel(AppLocalizations l) {
    if (_downloads.isQueued(widget.mediaType)) return l.downloadWaiting;
    final bytes = _downloads.bytesOf(widget.mediaType);
    if (bytes == null || bytes.total == 0) return null;
    final percent = (bytes.done * 100 / bytes.total).floor();
    return '$percent% · ${formatMediaSize(bytes.done)} / '
        '${formatMediaSize(bytes.total)}';
  }
}

/// After onboarding, asks once whether to download [version]'s sheet music
/// and audio for offline use, each with its size.
///
/// Waits, leaving the offer pending, until the edition has come from the
/// server, so the sizes shown are real. Clears the offer once answered, and
/// when there is nothing to offer.
Future<void> maybeOfferOfflineDownloads(
  BuildContext context, {
  required String version,
  required List<Hymn> hymns,
  SettingsRepository? settings,
  OfflineDownloadController? controller,
}) async {
  final preferences = settings ?? sl<SettingsRepository>();
  if (!preferences.isOfflineDownloadOfferPending()) return;
  if (!hymnsAreFromServer(hymns, version)) return;

  final downloads = controller ?? OfflineDownloadController.instance;
  final List<MediaDownloadPlan> offered;
  try {
    offered = [
      for (final mediaType in const [MediaType.sheetMusic, MediaType.audio])
        await downloads.downloader.plan(hymns, mediaType),
    ].where((plan) => plan.missing.isNotEmpty).toList();
  } catch (_) {
    return; // Storage unreadable: ask on a later launch.
  }
  if (offered.isEmpty) {
    await preferences.setOfflineDownloadOfferPending(false);
    return;
  }
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context)!;
  final chosen = await showDialog<Set<String>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => OfflineDownloadOfferDialog(
      version: version,
      plans: offered,
    ),
  );
  await preferences.setOfflineDownloadOfferPending(false);

  for (final plan in offered) {
    if (!(chosen?.contains(plan.mediaType) ?? false)) continue;
    startOfflineDownload(
      messenger,
      l,
      version,
      plan,
      controller: downloads,
      settings: preferences,
    );
  }
}

/// One question per kind of download, each with its size. Pops the chosen
/// media types; an empty set means "later".
class OfflineDownloadOfferDialog extends StatefulWidget {
  final String version;
  final List<MediaDownloadPlan> plans;

  const OfflineDownloadOfferDialog({
    super.key,
    required this.version,
    required this.plans,
  });

  @override
  State<OfflineDownloadOfferDialog> createState() =>
      _OfflineDownloadOfferDialogState();
}

class _OfflineDownloadOfferDialogState
    extends State<OfflineDownloadOfferDialog> {
  // Sheet music is small enough to suggest; audio is a deliberate choice.
  late final Set<String> _chosen = {
    for (final plan in widget.plans)
      if (plan.mediaType == MediaType.sheetMusic) plan.mediaType,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: context.appColors.surface,
      title: Text(
        l.downloadOfferTitle,
        style: TextStyle(color: context.appColors.primaryText),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.downloadOfferBody(l.hymnalLabelEn(widget.version)),
              style: TextStyle(color: context.appColors.secondaryText),
            ),
            const SizedBox(height: 8),
            for (final plan in widget.plans) _buildChoice(l, plan),
            const SizedBox(height: 8),
            Text(
              l.downloadOfferHintLater,
              style: TextStyle(
                  color: context.appColors.secondaryText, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(<String>{}),
          child: Text(l.downloadOfferLater),
        ),
        FilledButton(
          onPressed: _chosen.isEmpty
              ? null
              : () => Navigator.of(context).pop(Set.of(_chosen)),
          child: Text(l.downloadStart),
        ),
      ],
    );
  }

  Widget _buildChoice(AppLocalizations l, MediaDownloadPlan plan) {
    final audio = plan.mediaType == MediaType.audio;
    final selected = _chosen.contains(plan.mediaType);
    void toggle(bool value) => setState(() {
          value ? _chosen.add(plan.mediaType) : _chosen.remove(plan.mediaType);
        });

    final words = _wordsFor(l, plan.mediaType);
    return Semantics(
      toggled: selected,
      child: InkWell(
        key: ValueKey('offer-${plan.mediaType}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => toggle(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                audio
                    ? Icons.headphones_outlined
                    : Icons.library_music_outlined,
                color: context.appColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio ? l.downloadOfferAudios : l.downloadOfferSheets,
                      style: TextStyle(
                        color: context.appColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${plan.missing.length} ${words.units}'
                      ' · ${formatMediaSize(plan.missingBytes)}',
                      style: TextStyle(
                        color: context.appColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AppSwitch(value: selected, onChanged: toggle),
            ],
          ),
        ),
      ),
    );
  }
}
