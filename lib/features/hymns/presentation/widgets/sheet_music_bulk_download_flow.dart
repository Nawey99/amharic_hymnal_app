import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/sheet_music_bulk_download_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';

/// Offers to install every sheet-music page of [version] for offline use:
/// states the size first, then downloads with progress and a cancel button.
Future<void> runSheetMusicBulkDownload(
  BuildContext context,
  String version, {
  SheetMusicBulkDownloadService? service,
}) async {
  final downloader = service ?? SheetMusicBulkDownloadService();
  final messenger = ScaffoldMessenger.of(context);
  void say(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  say('ኖታዎችን በመፈለግ ላይ...');
  final SheetMusicDownloadPlan plan;
  try {
    plan = await downloader.plan(HymnalVersions.apiCode(version));
  } catch (_) {
    say('የኖታ ዝርዝሩን ማግኘት አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።');
    return;
  }
  messenger.hideCurrentSnackBar();
  if (!context.mounted) return;

  if (plan.pageCount == 0) {
    say('ይህ መዝሙር መጽሐፍ ኖታ የለውም።');
    return;
  }
  if (plan.missing.isEmpty) {
    say('ሁሉም ኖታዎች በመሣሪያዎ ላይ አሉ።');
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'ኖታዎችን በሙሉ ይውረዱ?',
        style: TextStyle(color: AppColors.primaryText),
      ),
      content: Text(
        '${HymnalVersions.displayLabel(version)}፦ '
        '${plan.missing.length} ገጾች፣ '
        '${formatMediaSize(plan.missingBytes)}።\n\n'
        'ከወረዱ በኋላ ኖታዎቹን ያለ ኢንተርኔት መክፈት ይችላሉ። Wi-Fi መጠቀም ይመከራል።',
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
  if (confirmed != true || !context.mounted) return;

  final progress = ValueNotifier<double>(0);
  var cancelled = false;
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final dialogClosed = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'ኖታዎች በማውረድ ላይ',
        style: TextStyle(color: AppColors.primaryText),
      ),
      content: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, value, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: value, color: AppColors.accentGreen),
            const SizedBox(height: 12),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => cancelled = true,
          child: const Text('አቁም'),
        ),
      ],
    ),
  );

  final result = await downloader.download(
    plan,
    onProgress: (done, total) => progress.value = done / total,
    isCancelled: () => cancelled,
  );
  if (rootNavigator.mounted) rootNavigator.pop();
  await dialogClosed;
  progress.dispose();

  if (result.cancelled) {
    say('ማውረድ ቆሟል። ${result.downloaded} ገጾች ተቀምጠዋል።');
  } else if (result.failed > 0) {
    say('${result.failed} ገጾችን ማውረድ አልተቻለም። እንደገና ሲሞክሩ የቀሩት ብቻ ይወርዳሉ።');
  } else {
    say('ሁሉም ኖታዎች ወርደዋል።');
  }
}
