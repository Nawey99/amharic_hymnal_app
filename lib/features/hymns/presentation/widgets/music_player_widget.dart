// lib/features/hymns/presentation/widgets/music_player_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

/// Music player widget for hymn audio playback
///
/// Subscribes to GlobalAudioService for reactive state updates
/// Displays play/pause, progress, and duration controls
/// Shows current hymn number and reflects global audio state
class MusicPlayerWidget extends StatefulWidget {
  final int hymnNumber;
  final String hymnTitle;

  const MusicPlayerWidget({
    super.key,
    required this.hymnNumber,
    required this.hymnTitle,
  });

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  final GlobalAudioService _audioService = GlobalAudioService();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playbackStateSubscription;
  StreamSubscription<int?>? _currentHymnSubscription;

  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  PlayerState? _playbackState;
  int? _currentPlayingHymn;
  bool _isLoading = false;
  bool _isError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _checkCurrentState();
  }

  void _setupListeners() {
    // Listen to position updates
    _positionSubscription = _audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // Listen to duration updates
    _durationSubscription = _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
          _isLoading = false;
        });
      }
    });

    // Listen to playback state changes
    _playbackStateSubscription =
        _audioService.playbackStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playbackState = state;
          _isLoading = false;
        });
      }
    });

    // Listen to current hymn changes
    _currentHymnSubscription =
        _audioService.currentHymnStream.listen((hymnNumber) {
      if (mounted) {
        setState(() {
          _currentPlayingHymn = hymnNumber;
          // If a different hymn starts playing, update UI
          if (hymnNumber != widget.hymnNumber && hymnNumber != null) {
            // Another hymn is playing - show that state
          }
        });
      }
    });
  }

  void _checkCurrentState() {
    // Check if this hymn is currently playing
    final currentHymn = _audioService.currentHymnNumber;

    setState(() {
      _currentPlayingHymn = currentHymn;
      _currentPosition = _audioService.position;
      _totalDuration = _audioService.duration;
      _playbackState = _audioService.playbackState;
    });

    // Do not auto-start audio when the widget appears; playback is user-driven.
  }

  Future<void> _loadAudio() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      await _audioService.play(
        widget.hymnNumber,
        hymnTitle: widget.hymnTitle,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = e.toString();
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load audio: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _currentHymnSubscription?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _isPlaying {
    return _playbackState == PlayerState.playing &&
        _currentPlayingHymn == widget.hymnNumber;
  }

  @override
  Widget build(BuildContext context) {
    // Check if this hymn is currently playing
    final isThisHymnActive = _currentPlayingHymn == widget.hymnNumber;

    return GlassContainer(
      borderRadius: 12.0,
      blurSigma: 12.0,
      opacity: 0.25,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title and hymn number
          Row(
            children: [
              const Icon(
                Icons.music_note,
                color: AppColors.accentGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hymnTitle,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansEthiopic',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isThisHymnActive)
                      Text(
                        'Hymn #${widget.hymnNumber}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Error state
          if (_isError) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage ?? 'Audio unavailable',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Controls
            Row(
              children: [
                // Play/Pause button
                _isLoading
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.accentGreen),
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: AppColors.accentGreen,
                        ),
                        onPressed:
                            isThisHymnActive ? _togglePlayPause : _loadAudio,
                        tooltip: _isPlaying ? 'Pause' : 'Play',
                      ),
                const SizedBox(width: 8),
                // Progress slider
                Expanded(
                  child: Column(
                    children: [
                      Slider(
                        value: _totalDuration != null &&
                                _totalDuration!.inMilliseconds > 0
                            ? _currentPosition.inMilliseconds.toDouble()
                            : 0.0,
                        max: _totalDuration != null &&
                                _totalDuration!.inMilliseconds > 0
                            ? _totalDuration!.inMilliseconds.toDouble()
                            : 100.0,
                        onChanged: (_isLoading || !isThisHymnActive)
                            ? null
                            : (value) {
                                _audioService.seek(
                                    Duration(milliseconds: value.toInt()));
                              },
                        activeColor: AppColors.accentGreen,
                        inactiveColor:
                            AppColors.secondaryText.withValues(alpha: 0.3),
                      ),
                      // Duration display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_currentPosition),
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _totalDuration != null
                                ? _formatDuration(_totalDuration!)
                                : '--:--',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _togglePlayPause() async {
    try {
      await _audioService.togglePlayPause();
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playback error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
