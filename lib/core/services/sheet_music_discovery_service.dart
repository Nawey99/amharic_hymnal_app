// lib/core/services/sheet_music_discovery_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Service for discovering and mapping sheet music files to hymn numbers
/// 
/// Scans assets/sheet_music/ directory and maps files by naming convention:
/// - Single page: number.webp (e.g., "5.webp", "10.webp")
/// - Two pages: number_L.webp and number_R.webp (e.g., "8_L.webp", "8_R.webp")
/// 
/// The service automatically detects whether a hymn has one or two pages based on
/// the file naming pattern. No hardcoded assumptions are made.
class SheetMusicDiscoveryService {
  static final SheetMusicDiscoveryService _instance = SheetMusicDiscoveryService._internal();
  factory SheetMusicDiscoveryService() => _instance;
  SheetMusicDiscoveryService._internal();

  // Cache of discovered sheet music files
  // Key: hymn number, Value: list of asset paths (ordered: single page or [L, R] for two pages)
  final Map<int, List<String>> _sheetMusicCache = {};
  bool _isInitialized = false;

  /// Initialize the service by scanning assets
  /// This should be called once at app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load asset manifest to discover sheet music files
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = 
          jsonDecode(manifestContent) as Map<String, dynamic>;

      // Filter for sheet_music assets (primarily WebP format)
      final sheetMusicAssets = manifest.keys
          .where((key) => key.startsWith('assets/sheet_music/'))
          .where((key) {
            final ext = key.split('.').last.toLowerCase();
            // Support WebP (primary) and legacy formats for backward compatibility
            return ext == 'webp' || ext == 'jpg' || ext == 'jpeg' || ext == 'png';
          })
          .toList();

      if (kDebugMode) {
        debugPrint('📚 Discovered ${sheetMusicAssets.length} sheet music files');
      }

      // Group files by hymn number
      final Map<int, List<String>> hymnFiles = {};

      for (final assetPath in sheetMusicAssets) {
        final fileName = assetPath.split('/').last;
        final baseName = fileName.split('.').first; // Remove extension

        // Parse hymn number and page type
        int? hymnNumber;
        String? pageType; // '_L', '_R', or null for single page

        // Check for two-page format: <number>_L or <number>_R
        if (baseName.endsWith('_L')) {
          pageType = '_L';
          final numberStr = baseName.substring(0, baseName.length - 2);
          hymnNumber = int.tryParse(numberStr);
        } else if (baseName.endsWith('_R')) {
          pageType = '_R';
          final numberStr = baseName.substring(0, baseName.length - 2);
          hymnNumber = int.tryParse(numberStr);
        } else {
          // Single page format: <number>
          hymnNumber = int.tryParse(baseName);
        }

        if (hymnNumber != null && hymnNumber > 0) {
          hymnFiles.putIfAbsent(hymnNumber, () => []);

          if (pageType != null) {
            // Two-page format: store asset path as-is (already has _L or _R)
            hymnFiles[hymnNumber]!.add(assetPath);
          } else {
            // Single page format
            hymnFiles[hymnNumber]!.add(assetPath);
          }
        }
      }

      // Sort files for each hymn: single page first, then _L, then _R
      for (final entry in hymnFiles.entries) {
        final files = entry.value;
        files.sort((a, b) {
          final aFileName = a.split('/').last;
          final bFileName = b.split('/').last;
          final aIsL = aFileName.contains('_L.');
          final aIsR = aFileName.contains('_R.');
          final bIsL = bFileName.contains('_L.');
          final bIsR = bFileName.contains('_R.');

          // Single page files come first
          if (!aIsL && !aIsR && (bIsL || bIsR)) return -1;
          if ((aIsL || aIsR) && !bIsL && !bIsR) return 1;
          
          // Among two-page files, _L comes before _R
          if (aIsL && bIsR) return -1;
          if (aIsR && bIsL) return 1;
          
          // Same type, sort alphabetically
          return aFileName.compareTo(bFileName);
        });

        _sheetMusicCache[entry.key] = files;
      }

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ Sheet music discovery complete: ${_sheetMusicCache.length} hymns with sheet music');
        if (_sheetMusicCache.isNotEmpty) {
          final sample = _sheetMusicCache.entries.take(5);
          for (final entry in sample) {
            debugPrint('   Hymn #${entry.key}: ${entry.value.length} file(s)');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing sheet music discovery: $e');
      }
      // Continue with empty cache - app should still work
    }
  }

  /// Get sheet music asset paths for a specific hymn number
  /// Returns empty list if no sheet music found
  List<String> getSheetMusicFiles(int hymnNumber) {
    return _sheetMusicCache[hymnNumber] ?? [];
  }

  /// Check if a hymn has sheet music
  bool hasSheetMusic(int hymnNumber) {
    return _sheetMusicCache.containsKey(hymnNumber) && 
           _sheetMusicCache[hymnNumber]!.isNotEmpty;
  }

  /// Get all hymn numbers that have sheet music
  List<int> getHymnsWithSheetMusic() {
    return _sheetMusicCache.keys.toList()..sort();
  }

  /// Clear the cache (useful for testing or re-initialization)
  void clearCache() {
    _sheetMusicCache.clear();
    _isInitialized = false;
  }
}
