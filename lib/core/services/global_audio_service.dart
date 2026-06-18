// lib/core/services/global_audio_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

/// Global audio service - single source of truth for all audio playback
///
/// Simplified implementation using `audioplayers` so it works on all
/// supported platforms (including Windows) without extra native setup.
class GlobalAudioService {
  static final GlobalAudioService _instance = GlobalAudioService._internal();
  factory GlobalAudioService() => _instance;
  GlobalAudioService._internal();

  AudioPlayer? _player;

  String? _apiKey;
  String? _baseUrl;
  int? _currentHymnNumber;
  String? _currentAudioUrl;

  // Stream controllers for state changes
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<PlayerState> _playbackStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<int?> _currentHymnController =
      StreamController<int?>.broadcast();

  // Current state
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  PlayerState _playbackState = PlayerState.stopped;

  bool _isInitialized = false;
  bool _audioBackendAvailable = true;

  /// Initialize the audio service with API configuration
  ///
  /// [apiKey] - API key for audio URL resolution (optional)
  /// [baseUrl] - Base URL for audio API (optional, can be set later)
  Future<void> initialize({String? apiKey, String? baseUrl}) async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('⚠️ GlobalAudioService already initialized');
      }
      return;
    }

    _apiKey = apiKey;
    _baseUrl = baseUrl;

    if (!_isNativeAudioBackendSupported) {
      _audioBackendAvailable = false;
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint(
          'ℹ️ Audio playback disabled on this platform until a supported backend is configured.',
        );
      }
      return;
    }

    _player = AudioPlayer();
    _setupPlayerListeners();
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('✅ GlobalAudioService initialized (audioplayers)');
    }
  }

  /// Set API configuration (can be called after initialization)
  void setApiConfig({String? apiKey, String? baseUrl}) {
    _apiKey = apiKey;
    _baseUrl = baseUrl;
  }

  /// Set up player event listeners
  void _setupPlayerListeners() {
    final player = _player;
    if (player == null) {
      return;
    }

    // Listen to position changes
    player.onPositionChanged.listen((position) {
      _currentPosition = position;
      _positionController.add(position);
    });

    // Listen to duration changes
    player.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      _durationController.add(duration);
      if (kDebugMode) {
        debugPrint('🎵 Audio duration: ${duration.inSeconds}s');
      }
    });

    // Listen to player state changes
    player.onPlayerStateChanged.listen((state) {
      _playbackState = state;
      _playbackStateController.add(state);
    });
  }

  /// Resolve audio URL from API for a given hymn number
  ///
  /// [hymnNumber] - The hymn number to get audio for
  /// Returns the audio URL if found, null otherwise
  ///
  /// API format: {baseUrl}/audio/{hymnNumber}?apiKey={apiKey}
  /// Can be customized based on actual API structure
  Future<String?> resolveAudioUrl(int hymnNumber) async {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Base URL not configured for audio API');
      }
      return null;
    }

    try {
      final url = _apiKey != null && _apiKey!.isNotEmpty
          ? '$_baseUrl/audio/$hymnNumber?apiKey=$_apiKey'
          : '$_baseUrl/audio/$hymnNumber';

      if (kDebugMode) {
        debugPrint('🔍 Resolving audio URL for hymn #$hymnNumber: $url');
      }

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ Audio API request timeout for hymn #$hymnNumber');
          }
          throw Exception('Audio API request timed out');
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;

          final audioUrl = data['url'] as String? ??
              data['audioUrl'] as String? ??
              data['audio_url'] as String? ??
              data['audio'] as String?;

          if (audioUrl != null && audioUrl.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('✅ Resolved audio URL: $audioUrl');
            }
            return audioUrl;
          } else {
            if (kDebugMode) {
              debugPrint(
                '⚠️ Audio URL not found in API response for hymn #$hymnNumber',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '❌ Failed to parse API response for hymn #$hymnNumber: $e',
            );
          }
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('ℹ️ Audio not found (404) for hymn #$hymnNumber');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '⚠️ API returned status ${response.statusCode} for hymn #$hymnNumber',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to resolve audio URL for hymn #$hymnNumber: $e');
      }
    }

    return null;
  }

  /// Play audio for a specific hymn number
  ///
  /// Automatically stops previous hymn if one is playing
  /// Resolves audio URL from API if not already cached
  Future<void> play(
    int hymnNumber, {
    String? hymnTitle,
    String? artist,
  }) async {
    try {
      final player = _player;
      if (!_audioBackendAvailable || player == null) {
        throw Exception('Audio playback is not available on this platform');
      }

      // Stop previous hymn if different
      if (_currentHymnNumber != null &&
          _currentHymnNumber != hymnNumber &&
          _playbackState == PlayerState.playing) {
        await stop();
      }

      final audioUrl = await resolveAudioUrl(hymnNumber);

      if (audioUrl == null || audioUrl.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No audio URL found for hymn #$hymnNumber');
        }
        throw Exception('Audio not available for hymn #$hymnNumber');
      }

      await player.stop();
      await player.play(UrlSource(audioUrl));

      _currentHymnNumber = hymnNumber;
      _currentAudioUrl = audioUrl;
      _currentHymnController.add(hymnNumber);

      if (kDebugMode) {
        debugPrint('🎵 Playing hymn #$hymnNumber: $audioUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to play hymn #$hymnNumber: $e');
      }
      rethrow;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      final player = _player;
      if (!_audioBackendAvailable || player == null) {
        return;
      }
      await player.pause();
      if (kDebugMode) {
        debugPrint('⏸️ Audio paused');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to pause audio: $e');
      }
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      final player = _player;
      if (!_audioBackendAvailable || player == null) {
        return;
      }
      await player.resume();
      if (kDebugMode) {
        debugPrint('▶️ Audio resumed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to resume audio: $e');
      }
    }
  }

  /// Stop playback and reset state
  Future<void> stop() async {
    try {
      final player = _player;
      if (!_audioBackendAvailable || player == null) {
        return;
      }
      await player.stop();
      _currentPosition = Duration.zero;
      _positionController.add(_currentPosition);
      _currentHymnNumber = null;
      _currentAudioUrl = null;
      _currentHymnController.add(null);

      if (kDebugMode) {
        debugPrint('⏹️ Audio stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to stop audio: $e');
      }
    }
  }

  /// Seek to a specific position
  Future<void> seek(Duration position) async {
    try {
      final player = _player;
      if (!_audioBackendAvailable || player == null) {
        return;
      }
      await player.seek(position);
      _currentPosition = position;
      _positionController.add(position);

      if (kDebugMode) {
        debugPrint('⏩ Seeked to: ${position.inSeconds}s');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to seek: $e');
      }
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_playbackState == PlayerState.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  // Streams for reactive UI
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<PlayerState> get playbackStateStream =>
      _playbackStateController.stream;
  Stream<int?> get currentHymnStream => _currentHymnController.stream;

  // Current state properties
  int? get currentHymnNumber => _currentHymnNumber;
  Duration get position => _currentPosition;
  Duration? get duration => _totalDuration;
  PlayerState get playbackState => _playbackState;
  bool get isPlaying => _playbackState == PlayerState.playing;
  bool get isPaused => _playbackState == PlayerState.paused;
  bool get isStopped => _playbackState == PlayerState.stopped;
  String? get currentAudioUrl => _currentAudioUrl;

  bool get _isNativeAudioBackendSupported {
    return defaultTargetPlatform != TargetPlatform.windows;
  }

  /// Dispose resources
  void dispose() {
    _positionController.close();
    _durationController.close();
    _playbackStateController.close();
    _currentHymnController.close();
    _player?.dispose();
    _player = null;
    _audioBackendAvailable = true;
    _isInitialized = false;
  }
}
