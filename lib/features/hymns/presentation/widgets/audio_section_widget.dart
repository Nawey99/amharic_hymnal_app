// lib/features/hymns/presentation/widgets/audio_section_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/music_player_widget.dart';

/// Automatic audio section widget for hymn detail page
///
/// Automatically detects if audio is available for the hymn
/// Transitions from static section to full player when audio is available
/// Shows "Audio unavailable" state when no audio is found
/// Subscribes to GlobalAudioService for reactive state updates
class AudioSectionWidget extends StatefulWidget {
  final int hymnNumber;
  final String hymnTitle;

  const AudioSectionWidget({
    super.key,
    required this.hymnNumber,
    required this.hymnTitle,
  });

  @override
  State<AudioSectionWidget> createState() => _AudioSectionWidgetState();
}

class _AudioSectionWidgetState extends State<AudioSectionWidget> {
  final GlobalAudioService _audioService = GlobalAudioService();
  bool _isChecking = true;
  bool _hasAudio = false;
  StreamSubscription<int?>? _currentHymnSubscription;

  @override
  void initState() {
    super.initState();
    _checkAudioAvailability();
    _setupListener();
  }

  void _setupListener() {
    // Listen to current hymn changes to update UI when another hymn starts
    _currentHymnSubscription =
        _audioService.currentHymnStream.listen((hymnNumber) {
      if (mounted) {
        setState(() {
          // UI will update automatically via MusicPlayerWidget
        });
      }
    });
  }

  Future<void> _checkAudioAvailability() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Try to resolve audio URL
      final audioUrl = await _audioService.resolveAudioUrl(widget.hymnNumber);

      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasAudio = audioUrl != null && audioUrl.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasAudio = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _currentHymnSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return _buildLoadingState();
    }

    if (_hasAudio) {
      // Show full player UI
      return MusicPlayerWidget(
        hymnNumber: widget.hymnNumber,
        hymnTitle: widget.hymnTitle,
      );
    }

    // Show unavailable state
    return _buildUnavailableState();
  }

  Widget _buildLoadingState() {
    return const GlassContainer(
      borderRadius: 12.0,
      blurSigma: 12.0,
      opacity: 0.25,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: AppColors.accentGreen,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Checking audio availability...',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableState() {
    return const GlassContainer(
      borderRadius: 12.0,
      blurSigma: 12.0,
      opacity: 0.25,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.music_off,
            color: AppColors.secondaryText,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Audio unavailable',
              style: TextStyle(
                color: AppColors.secondaryText,
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
