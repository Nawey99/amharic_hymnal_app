import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/music_player_widget.dart';

/// Displays the player only when the content backend supplied valid audio.
class AudioSectionWidget extends StatefulWidget {
  final int hymnNumber;
  final String hymnTitle;
  final String? englishTitle;
  final String? audioSource;
  final HymnAudioInfo? audioInfo;
  final String version;
  final bool condensed;

  /// Whether the server has described this hymn, so that having no audio
  /// means there is none. False for a hymn read from the bundled copy,
  /// which the app has not been able to ask about.
  final bool audioIsKnown;
  final AudioMediaRepository? audioRepository;

  const AudioSectionWidget({
    super.key,
    required this.hymnNumber,
    required this.hymnTitle,
    this.englishTitle,
    this.audioSource,
    this.audioInfo,
    required this.version,
    this.condensed = false,
    this.audioIsKnown = true,
    this.audioRepository,
  });

  @override
  State<AudioSectionWidget> createState() => _AudioSectionWidgetState();
}

class _AudioSectionWidgetState extends State<AudioSectionWidget> {
  late final AudioMediaRepository _audioRepository;
  AudioTrack? _track;

  @override
  void initState() {
    super.initState();
    _audioRepository = widget.audioRepository ?? AudioRepository();
    _resolveTrack();
  }

  @override
  void didUpdateWidget(covariant AudioSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hymnNumber != widget.hymnNumber ||
        oldWidget.hymnTitle != widget.hymnTitle ||
        oldWidget.audioSource != widget.audioSource ||
        oldWidget.version != widget.version) {
      _resolveTrack();
    }
  }

  void _resolveTrack() {
    _track = _audioRepository.getTrackForNumber(
      widget.hymnNumber,
      title: widget.hymnTitle,
      version: widget.version,
      mediaSource: widget.audioSource,
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = _track;
    if (track != null) {
      return MusicPlayerWidget(
        hymnNumber: widget.hymnNumber,
        hymnTitle: widget.hymnTitle,
        englishTitle: widget.englishTitle,
        audioSource: track.url,
        audioInfo: widget.audioInfo,
        version: widget.version,
        condensed: widget.condensed,
        audioRepository: _audioRepository,
      );
    }

    return _buildUnavailableState();
  }

  /// The hymn's name is shown whether or not there is anything to play,
  /// with the reason underneath where the English title would be.
  ///
  /// "No audio" is only said of a hymn the server has described. A hymn read
  /// from the copy bundled with the app has not been asked about yet, so the
  /// reader is told how to find out instead.
  Widget _buildUnavailableState() {
    final l = AppLocalizations.of(context);
    final known = widget.audioIsKnown;
    final status = known
        ? (l?.audioNotFound ?? 'ድምፅ አልተገኘም')
        : (l?.audioNeedsInternet ?? 'ድምፅ መኖሩን ለማወቅ ከኢንተርኔት ጋር ይገናኙ');
    final condensed = widget.condensed;

    return GlassContainer(
      borderRadius: 18,
      blurSigma: 12,
      opacity: context.appColors.glassOpacityOverPhoto,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        // As the player: nearly solid, so it reads against the photograph.
        color: context.appColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: condensed
              ? const EdgeInsets.fromLTRB(10, 6, 10, 6)
              : const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  known ? Icons.music_off : Icons.cloud_off_outlined,
                  color: context.appColors.secondaryText,
                  size: condensed ? 20 : 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.hymnTitle,
                      key: const ValueKey('audio-unavailable-title'),
                      style: TextStyle(
                        color: context.appColors.primaryText,
                        fontSize: condensed ? 15 : 19,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      key: const ValueKey('audio-unavailable-status'),
                      style: TextStyle(
                        color: context.appColors.secondaryText,
                        fontSize: 12,
                        height: 1.15,
                      ),
                      maxLines: condensed ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
