import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/offline_download_controller.dart';
import 'package:amharic_hymnal_app/core/services/offline_media_download.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/settings_tiles.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

/// Loads every hymn of an edition, as stored on the device.
typedef EditionHymnsLoader = Future<List<Hymn>> Function(String version);

Future<List<Hymn>> _loadEditionHymns(String version) async {
  final result = await sl<HymnRepository>().getHymns(
    sl<SettingsRepository>().getSelectedLanguage(),
    version,
  );
  return result.fold((failure) => throw failure, (hymns) => hymns);
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

/// What the app says about one kind of download.
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
  });

  String stopped(int saved) => 'ማውረድ ቆሟል። $saved $units ተቀምጠዋል።';

  String failed(int count) =>
      '$count $unitsን ማውረድ አልተቻለም። እንደገና ሲሞክሩ የቀሩት ብቻ ይወርዳሉ።';

  String updated(int count) => '$count አዲስ $units ወርደዋል።';

  String allDownloaded(MediaDownloadPlan plan) =>
      'ሁሉም ወርደዋል · ${plan.itemCount} $units · '
      '${formatMediaSize(plan.totalBytes)}';

  String updatesAvailable(MediaDownloadPlan plan) =>
      '${plan.missing.length} አዲስ $units ለማውረድ · '
      '${formatMediaSize(plan.missingBytes)}';
}

const _sheetMusicWords = _Words(
  tileTitle: 'ኖታዎችን በሙሉ አውርድ',
  tileDescription: 'የተመረጠውን መጽሐፍ ኖታዎች ያለ ኢንተርኔት ለመክፈት',
  confirmTitle: 'ሁሉም ኖታዎች ይውረዱ?',
  units: 'ገጾች',
  benefit: 'ከወረዱ በኋላ ኖታዎቹን ያለ ኢንተርኔት መክፈት ይችላሉ።',
  none: 'ይህ የመዝሙር መጽሐፍ ኖታ የለውም።',
  allPresent: 'ሁሉም ኖታዎች በመሣሪያዎ ላይ አሉ።',
  started: 'ኖታዎች በመውረድ ላይ ናቸው። መተግበሪያውን መጠቀም ይችላሉ።',
  finished: 'ሁሉም ኖታዎች ወርደዋል።',
);

const _audioWords = _Words(
  tileTitle: 'ድምፆችን በሙሉ አውርድ',
  tileDescription: 'የተመረጠውን መጽሐፍ መዝሙሮች ያለ ኢንተርኔት ለማዳመጥ',
  confirmTitle: 'ሁሉም ድምፆች ይውረዱ?',
  units: 'ድምፆች',
  benefit: 'ከወረዱ በኋላ መዝሙሮቹን ያለ ኢንተርኔት ማዳመጥ ይችላሉ።',
  none: 'ይህ የመዝሙር መጽሐፍ ድምፅ የለውም።',
  allPresent: 'ሁሉም ድምፆች በመሣሪያዎ ላይ አሉ።',
  started: 'ድምፆች በመውረድ ላይ ናቸው። መተግበሪያውን መጠቀም ይችላሉ።',
  finished: 'ሁሉም ድምፆች ወርደዋል።',
);

_Words _wordsFor(String mediaType) =>
    mediaType == MediaType.audio ? _audioWords : _sheetMusicWords;

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
  String version,
  MediaDownloadPlan plan, {
  bool quiet = false,
  OfflineDownloadController? controller,
  SettingsRepository? settings,
}) {
  final downloads = controller ?? OfflineDownloadController.instance;
  final preferences = settings ?? sl<SettingsRepository>();
  final words = _wordsFor(plan.mediaType);

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
    },
  );
  if (!started) return;
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
  final words = _wordsFor(mediaType);

  final List<Hymn> hymns;
  try {
    hymns = await (loadHymns ?? _loadEditionHymns)(version);
  } catch (_) {
    _say(messenger, 'የመዝሙሮቹን ዝርዝር ማግኘት አልተቻለም።');
    return;
  }
  if (!hymnsAreFromServer(hymns, version)) {
    _say(messenger, 'ለማውረድ መጀመሪያ የኢንተርኔት ግንኙነት ያስፈልጋል። እባክዎ ቆይተው እንደገና ይሞክሩ።');
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
      backgroundColor: AppColors.surface,
      title: Text(
        words.confirmTitle,
        style: const TextStyle(color: AppColors.primaryText),
      ),
      content: Text(
        '${HymnalVersions.displayLabel(version)}፦ '
        '${plan.missing.length} ${words.units}፣ '
        '${formatMediaSize(plan.missingBytes)}።\n\n'
        '${words.benefit} Wi-Fi መጠቀም ይመከራል።',
        style: const TextStyle(color: AppColors.secondaryText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ይቅር'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('አውርድ'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  startOfflineDownload(
    messenger,
    version,
    plan,
    controller: downloads,
    settings: preferences,
  );
}

/// Fetches what a sync added to or replaced in the kept media of the
/// edition in [controller]'s state, up to [automaticUpdateLimitBytes] each.
/// Larger changes wait on the tile for a tap.
void downloadKeptMediaChanges(
  ScaffoldMessengerState messenger, {
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
    final words = _wordsFor(mediaType);

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
          progressLabel: _progressLabel(downloads),
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

  String? _progressLabel(OfflineDownloadController downloads) {
    if (downloads.isQueued(mediaType)) return 'በመጠባበቅ ላይ';
    final bytes = downloads.bytesOf(mediaType);
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
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'ያለ ኢንተርኔት ለመጠቀም ማውረድ',
        style: TextStyle(color: AppColors.primaryText),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${HymnalVersions.displayLabel(widget.version)}ን ያለ ኢንተርኔት '
              'ለመጠቀም ምን ይውረድ?',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),
            for (final plan in widget.plans) _buildChoice(plan),
            const SizedBox(height: 8),
            const Text(
              'Wi-Fi መጠቀም ይመከራል። በኋላም ከቅንብሮች ማውረድ ይችላሉ።',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(<String>{}),
          child: const Text('በኋላ'),
        ),
        FilledButton(
          onPressed: _chosen.isEmpty
              ? null
              : () => Navigator.of(context).pop(Set.of(_chosen)),
          child: const Text('አውርድ'),
        ),
      ],
    );
  }

  Widget _buildChoice(MediaDownloadPlan plan) {
    final audio = plan.mediaType == MediaType.audio;
    final selected = _chosen.contains(plan.mediaType);
    void toggle(bool value) => setState(() {
          value ? _chosen.add(plan.mediaType) : _chosen.remove(plan.mediaType);
        });

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
                color: AppColors.accentGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio ? 'ድምፆች' : 'ኖታዎች',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${plan.missing.length} ${_wordsFor(plan.mediaType).units}'
                      ' · ${formatMediaSize(plan.missingBytes)}',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
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
