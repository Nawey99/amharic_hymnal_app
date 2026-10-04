import 'dart:async';

import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/sheet_music_viewer_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/audio_section_widget.dart';

/// Coordinates hymn audio, sheet-music downloads, and sheet-music navigation.
class HymnMediaControls extends StatefulWidget {
  final Hymn hymn;
  final String version;
  final bool condensed;
  final SheetMusicMediaRepository? sheetMusicRepository;
  final MediaDownloadRepository? downloadRepository;

  const HymnMediaControls({
    super.key,
    required this.hymn,
    required this.version,
    required this.condensed,
    this.sheetMusicRepository,
    this.downloadRepository,
  });

  @override
  State<HymnMediaControls> createState() => _HymnMediaControlsState();
}

class _HymnMediaControlsState extends State<HymnMediaControls> {
  late final SheetMusicMediaRepository _sheetMusicRepository;
  late final MediaDownloadRepository _downloadRepository;

  @override
  void initState() {
    super.initState();
    _sheetMusicRepository =
        widget.sheetMusicRepository ?? SheetMusicRepository();
    _downloadRepository = widget.downloadRepository ?? DownloadRepository();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = widget.condensed || constraints.maxWidth < 380;
        final shouldStack = constraints.maxWidth < 320;
        final sheetButtonWidth = compact ? 62.0 : 72.0;
        final mediaGap = compact ? 8.0 : 10.0;

        Widget buildSheetMusicButton({required bool stretch}) {
          final hasSheetMusic =
              _sheetMusicRepository.hasMediaForHymn(widget.hymn);
          return _SheetMusicPreviewBox(
            enabled: hasSheetMusic,
            width: stretch ? sheetButtonWidth : null,
            stretch: stretch,
            condensed: widget.condensed,
            onTap: hasSheetMusic ? _openSheetMusic : null,
          );
        }

        if (shouldStack || (constraints.maxWidth < 340 && !widget.condensed)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAudioSection(condensed: false),
              buildSheetMusicButton(stretch: false),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildAudioSection(condensed: widget.condensed),
              ),
              SizedBox(width: mediaGap),
              SizedBox(
                width: sheetButtonWidth,
                child: buildSheetMusicButton(stretch: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioSection({required bool condensed}) {
    final hymn = widget.hymn;
    return AudioSectionWidget(
      hymnNumber: hymn.displayNumber,
      hymnTitle: hymn.displayTitle.isNotEmpty
          ? hymn.displayTitle
          : (AppLocalizations.of(context)?.hymnNumber(hymn.displayNumber) ??
              'መዝሙር ${hymn.displayNumber}'),
      englishTitle: hymn.displayEnglishTitle,
      audioSource: hymn.audioUrl,
      audioInfo: hymn.audioInfo,
      version: widget.version,
      condensed: condensed,
      audioIsKnown: !hymn.isBundled,
    );
  }

  Future<void> _openSheetMusic() async {
    // Captured before the first await, so nothing reaches for a context
    // that has since gone away.
    final l = AppLocalizations.of(context);
    final resolved =
        await _sheetMusicRepository.resolveFilesForHymn(widget.hymn);
    if (!mounted) return;

    final missing = [
      for (final file in resolved)
        if (!file.isLocal) file.remote!,
    ];
    var downloaded = const <String>[];
    if (missing.isNotEmpty) {
      final canDownload = await _downloadRepository.isDownloadAvailable(
        MediaType.sheetMusic,
        missing.first,
      );
      if (!mounted) return;
      if (!canDownload) {
        _showMessage(l?.sheetCannotDownloadHere ?? 'በዚህ መሣሪያ ላይ ኖታ ማውረድ አይቻልም');
        return;
      }

      downloaded = await _confirmAndDownloadSheetMusic(missing);
      if (!mounted || downloaded.length != missing.length) return;
    }

    var downloadedIndex = 0;
    final files = [
      for (final file in resolved)
        file.isLocal ? file.localPath! : downloaded[downloadedIndex++],
    ];

    if (files.isEmpty) {
      _showMessage(l?.sheetNoneForHymn ?? 'ለዚህ መዝሙር ኖታ አልተገኘም');
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SheetMusicViewerPage(
          hymn: widget.hymn,
          sheetMusicFiles: files,
        ),
      ),
    );
  }

  Future<List<String>> _confirmAndDownloadSheetMusic(
    List<MediaSource> sources,
  ) async {
    final l = AppLocalizations.of(context);
    final sizes = sources.map((source) => source.sizeBytes).toList();
    final totalBytes = sizes.contains(null)
        ? null
        : sizes.fold<int>(0, (sum, size) => sum + size!);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text(
          l?.sheetDownloadTitle ?? 'ኖታ ይውረድ?',
          style: TextStyle(color: context.appColors.primaryText),
        ),
        content: Text(
          '${l?.sheetDownloadBody ?? 'ይህ ኖታ በመሣሪያዎ ላይ አልተቀመጠም። አሁን ካወረዱት በኋላ ከመስመር ውጭም መክፈት ይችላሉ።'}'
          '${totalBytes == null ? '' : '\n\n${l?.mediaSizeLine(formatMediaSize(totalBytes)) ?? 'መጠን፦ ${formatMediaSize(totalBytes)}'}'}',
          style: TextStyle(color: context.appColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l?.actionCancel ?? 'ይቅር'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l?.actionDownload ?? 'አውርድ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return const <String>[];

    final progress = ValueNotifier<double?>(null);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final dialogClosed = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text(
          l?.sheetDownloading ?? 'ኖታ በማውረድ ላይ',
          style: TextStyle(color: context.appColors.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double?>(
              valueListenable: progress,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                color: context.appColors.accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l?.pleaseWait ?? 'እባክዎ ይጠብቁ...',
              style: TextStyle(color: context.appColors.secondaryText),
            ),
          ],
        ),
      ),
    );

    final downloaded = <String>[];
    try {
      for (var index = 0; index < sources.length; index++) {
        final file = await _downloadRepository.requestDownload(
          mediaType: MediaType.sheetMusic,
          hymnNumber: widget.hymn.displayNumber,
          source: sources[index],
          onProgress: (received, total) {
            if (total == null || total <= 0) return;
            final fileProgress = (received / total).clamp(0.0, 1.0);
            progress.value = (index + fileProgress) / sources.length;
          },
        );
        downloaded.add(file.path);
      }
    } on MediaIntegrityException {
      downloaded.clear();
      if (mounted) {
        _showMessage(
            l?.sheetDownloadCorrupt ?? 'የወረደው ኖታ ትክክል አልሆነም። እባክዎ እንደገና ይሞክሩ።');
      }
    } catch (_) {
      downloaded.clear();
      if (mounted) {
        _showMessage(
            l?.sheetDownloadFailed ?? 'ኖታውን ማውረድ አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።');
      }
    } finally {
      if (rootNavigator.mounted) rootNavigator.pop();
      await dialogClosed;
      progress.dispose();
    }
    return downloaded;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class _SheetMusicPreviewBox extends StatelessWidget {
  final bool enabled;
  final double? width;
  final bool stretch;
  final bool condensed;
  final VoidCallback? onTap;

  const _SheetMusicPreviewBox({
    required this.enabled,
    this.width,
    required this.stretch,
    required this.condensed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context)?.sheetOpen ?? 'ኖታ ክፈት',
      button: enabled,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassContainer(
          width: width ?? double.infinity,
          height: stretch ? double.infinity : null,
          borderRadius: 18,
          blurSigma: 12,
          opacity: enabled ? 0.25 : 0.12,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_music_outlined,
                color: enabled
                    ? context.appColors.accent
                    : context.appColors.secondaryText,
                size: condensed ? 22 : 20,
              ),
              if (!condensed) ...[
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? (AppLocalizations.of(context)?.sheetShort ?? 'ኖታ')
                      : (AppLocalizations.of(context)?.sheetNone ?? 'የለም'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled
                        ? context.appColors.primaryText
                        : context.appColors.secondaryText,
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
