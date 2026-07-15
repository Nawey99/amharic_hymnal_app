import 'dart:async';

import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
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
          : 'መዝሙር ${hymn.displayNumber}',
      englishTitle: hymn.displayEnglishTitle,
      audioSource: hymn.audioUrl,
      version: widget.version,
      condensed: condensed,
    );
  }

  Future<void> _openSheetMusic() async {
    var files = await _sheetMusicRepository.getFilesForHymn(widget.hymn);
    if (!mounted) return;

    final remoteSources = files
        .map(Uri.tryParse)
        .whereType<Uri>()
        .where((source) => source.scheme == 'http' || source.scheme == 'https')
        .toList(growable: false);
    if (remoteSources.isNotEmpty) {
      final canDownload = await _downloadRepository.isDownloadAvailable(
        MediaType.sheetMusic,
        remoteSources.first,
      );
      if (!mounted) return;
      if (!canDownload) {
        _showMessage('በዚህ መሣሪያ ላይ ኖታ ማውረድ አይቻልም');
        return;
      }

      final downloaded = await _confirmAndDownloadSheetMusic(remoteSources);
      if (!mounted || downloaded.length != remoteSources.length) return;

      var downloadedIndex = 0;
      files = files.map((file) {
        final uri = Uri.tryParse(file);
        if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
          return file;
        }
        return downloaded[downloadedIndex++];
      }).toList(growable: false);
    }

    if (files.isEmpty) {
      _showMessage('ለዚህ መዝሙር ኖታ አልተገኘም');
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
    List<Uri> sources,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'ኖታ ይውረድ?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: const Text(
          'ይህ ኖታ በመሣሪያዎ ላይ አልተቀመጠም። አሁን ካወረዱት በኋላ ከመስመር ውጭም መክፈት ይችላሉ።',
          style: TextStyle(color: AppColors.secondaryText),
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
    if (confirmed != true || !mounted) return const <String>[];

    final progress = ValueNotifier<double?>(null);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final dialogClosed = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'ኖታ በማውረድ ላይ',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double?>(
              valueListenable: progress,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'እባክዎ ይጠብቁ...',
              style: TextStyle(color: AppColors.secondaryText),
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
    } catch (_) {
      downloaded.clear();
      if (mounted) {
        _showMessage('ኖታውን ማውረድ አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።');
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
      label: 'ኖታ ክፈት',
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
                color:
                    enabled ? AppColors.accentGreen : AppColors.secondaryText,
                size: condensed ? 22 : 20,
              ),
              if (!condensed) ...[
                const SizedBox(height: 2),
                Text(
                  enabled ? 'ኖታ' : 'የለም',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled
                        ? AppColors.primaryText
                        : AppColors.secondaryText,
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansEthiopic',
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
