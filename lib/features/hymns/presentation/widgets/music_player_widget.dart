// lib/features/hymns/presentation/widgets/music_player_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
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
  final String? englishTitle;
  final String version;
  final bool condensed;

  const MusicPlayerWidget({
    super.key,
    required this.hymnNumber,
    required this.hymnTitle,
    this.englishTitle,
    required this.version,
    this.condensed = false,
  });

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  final GlobalAudioService _audioService = GlobalAudioService();
  final AudioRepository _audioRepository = AudioRepository();
  final DownloadRepository _downloadRepository = DownloadRepository();
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
  bool _isExpanded = false;
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
          if (_shouldAutoExpandFor(_currentPlayingHymn, state)) {
            _isExpanded = true;
          }
        });
      }
    });

    // Listen to current hymn changes
    _currentHymnSubscription =
        _audioService.currentHymnStream.listen((hymnNumber) {
      if (mounted) {
        setState(() {
          _currentPlayingHymn = hymnNumber;
          if (_shouldAutoExpandFor(hymnNumber, _playbackState)) {
            _isExpanded = true;
          } else if (hymnNumber != widget.hymnNumber && hymnNumber != null) {
            _isExpanded = false;
          }
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
      _isExpanded =
          _shouldAutoExpandFor(currentHymn, _audioService.playbackState);
    });

    // Do not auto-start audio when the widget appears; playback is user-driven.
  }

  bool _shouldAutoExpandFor(int? hymnNumber, PlayerState? state) {
    return hymnNumber == widget.hymnNumber &&
        (state == PlayerState.playing ||
            state == PlayerState.paused ||
            state == PlayerState.completed);
  }

  Future<void> _loadAudio() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final localTrack = await _audioRepository.getTrackForNumber(
        widget.hymnNumber,
        title: widget.hymnTitle,
        version: widget.version,
      );
      if (localTrack != null &&
          localTrack.url.startsWith(GlobalAudioService.localAssetAudioScheme)) {
        await _audioService.playAsset(
          widget.hymnNumber,
          localTrack.url.substring(
            GlobalAudioService.localAssetAudioScheme.length,
          ),
          hymnTitle: widget.hymnTitle,
        );
        return;
      }

      if (widget.hymnNumber != LocalDummyAudioRepository.dummyHymnNumber) {
        final playedCached = await _playCachedOrDownloadRemoteAudio();
        if (playedCached) return;
      }
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
              content: Text('ድምፅ መክፈት አልተቻለም: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _playCachedOrDownloadRemoteAudio() async {
    final source = await _audioRepository.remoteSourceForNumber(
      widget.hymnNumber,
    );
    if (source == null) return false;

    final cachedPath = await _audioRepository.cachedPathFor(source);
    if (cachedPath != null) {
      await _audioService.playLocalFile(
        widget.hymnNumber,
        cachedPath,
        hymnTitle: widget.hymnTitle,
      );
      return true;
    }

    if (!mounted) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'ድምፅ ይውረድ?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: const Text(
          'ይህ ድምፅ በመሣሪያዎ ላይ አልተቀመጠም። አሁን ካወረዱት በኋላ ከመስመር ውጭም ማጫወት ይችላሉ።',
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
    if (confirmed != true || !mounted) {
      setState(() => _isLoading = false);
      return true;
    }

    final cached = await _downloadRepository.requestDownload(
      mediaType: 'audio',
      hymnNumber: widget.hymnNumber,
      source: source,
    );
    await _audioService.playLocalFile(
      widget.hymnNumber,
      cached.path,
      hymnTitle: widget.hymnTitle,
    );
    return true;
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
    final englishTitle = widget.englishTitle?.trim();
    final subtitle = englishTitle != null && englishTitle.isNotEmpty
        ? englishTitle
        : 'Audio accompaniment';

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: GlassContainer(
        borderRadius: 18.0,
        blurSigma: 12.0,
        opacity: 0.2,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: const Color(0xE6292929),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _isError || widget.condensed
                ? null
                : () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: widget.condensed
                  ? const EdgeInsets.fromLTRB(10, 6, 10, 6)
                  : const EdgeInsets.fromLTRB(10, 8, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.condensed)
                    Row(
                      children: [
                        _buildPlayButton(isThisHymnActive),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.hymnTitle,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'NotoSansEthiopic',
                                  height: 1.08,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (_isError)
                    _buildErrorMessage()
                  else if (widget.condensed)
                    _buildCondensedScrubber(isThisHymnActive)
                  else
                    _buildExpandableScrubber(isThisHymnActive),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(
    bool isThisHymnActive, {
    double size = 36,
    double iconSize = 24,
  }) {
    if (_isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentGreen,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          side: BorderSide(
            color: AppColors.primaryText.withValues(alpha: 0.88),
            width: 2,
          ),
          shape: const CircleBorder(),
        ),
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: AppColors.primaryText,
          size: iconSize,
        ),
        onPressed: () => _handlePlayButtonPressed(isThisHymnActive),
        tooltip: _isPlaying ? 'አቁም' : 'አጫውት',
      ),
    );
  }

  Future<void> _handlePlayButtonPressed(bool isThisHymnActive) async {
    if (!_isExpanded && mounted) {
      setState(() => _isExpanded = true);
    }

    if (isThisHymnActive && _playbackState == PlayerState.completed) {
      await _loadAudio();
    } else if (isThisHymnActive) {
      await _togglePlayPause();
    } else {
      await _loadAudio();
    }
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'ድምፅ አልተገኘም',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableScrubber(bool isThisHymnActive) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !_isExpanded
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  _buildProgressSlider(isThisHymnActive),
                  _buildTimeLabels(),
                ],
              ),
            ),
    );
  }

  Widget _buildCondensedScrubber(bool isThisHymnActive) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          _buildPlayButton(
            isThisHymnActive,
            size: 32,
            iconSize: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 25,
                  child: _buildProgressSlider(
                    isThisHymnActive,
                    compact: true,
                  ),
                ),
                _buildTimeLabels(compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(
    bool isThisHymnActive, {
    bool compact = false,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: compact ? 2.5 : 3,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: compact ? 5 : 6,
          disabledThumbRadius: compact ? 4 : 5,
        ),
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: compact ? 12 : 14,
        ),
      ),
      child: Slider(
        value: _totalDuration != null && _totalDuration!.inMilliseconds > 0
            ? _currentPosition.inMilliseconds.toDouble().clamp(
                  0.0,
                  _totalDuration!.inMilliseconds.toDouble(),
                )
            : 0.0,
        max: _totalDuration != null && _totalDuration!.inMilliseconds > 0
            ? _totalDuration!.inMilliseconds.toDouble()
            : 100.0,
        onChanged: (_isLoading || !isThisHymnActive)
            ? null
            : (value) {
                _audioService.seek(
                  Duration(milliseconds: value.toInt()),
                );
              },
        activeColor: AppColors.accentGreen,
        inactiveColor: AppColors.secondaryText.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildTimeLabels({bool compact = false}) {
    final textStyle = TextStyle(
      color: AppColors.secondaryText,
      fontSize: compact ? 10 : 11,
      height: 1,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_formatDuration(_currentPosition), style: textStyle),
        Text(
          _totalDuration != null ? _formatDuration(_totalDuration!) : '--:--',
          style: textStyle,
        ),
      ],
    );
  }

  Future<void> _togglePlayPause() async {
    try {
      await _audioService.togglePlayPause();
    } catch (e) {
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('የድምፅ ስህተት: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
