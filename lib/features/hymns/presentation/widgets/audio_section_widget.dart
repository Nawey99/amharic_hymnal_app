import 'package:flutter/material.dart';

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

  Widget _buildUnavailableState() {
    if (widget.condensed) {
      return GlassContainer(
        borderRadius: 18,
        blurSigma: 12,
        opacity: 0.25,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(
              Icons.music_off,
              color: context.appColors.secondaryText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ድምፅ አልተገኘም',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appColors.secondaryText,
                  fontSize: 12,
                  fontFamily: 'NotoSansEthiopic',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      borderRadius: 12,
      blurSigma: 12,
      opacity: 0.25,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.music_off,
            color: context.appColors.secondaryText,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ድምፅ አልተገኘም',
              style: TextStyle(
                color: context.appColors.secondaryText,
                fontSize: 14,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
