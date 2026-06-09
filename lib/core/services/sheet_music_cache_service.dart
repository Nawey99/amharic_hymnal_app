// lib/core/services/sheet_music_cache_service.dart
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Service for downloading and caching sheet music locally
/// 
/// Features:
/// - Downloads sheet music on demand
/// - Stores in app documents directory
/// - LRU eviction policy
/// - Cache size tracking
/// - Manual cache clearing
class SheetMusicCacheService {
  static final SheetMusicCacheService _instance = SheetMusicCacheService._internal();
  factory SheetMusicCacheService() => _instance;
  SheetMusicCacheService._internal();

  Directory? _cacheDir;
  bool _isInitialized = false;
  
  // Track access times for LRU eviction
  final Map<String, DateTime> _accessTimes = {};
  
  // Maximum cache size in bytes (default: 500 MB)
  int _maxCacheSize = 500 * 1024 * 1024;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDocDir.path, 'sheet_music_cache'));
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('✅ SheetMusicCacheService initialized');
        debugPrint('   Cache directory: ${_cacheDir!.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize SheetMusicCacheService: $e');
      }
      rethrow;
    }
  }

  /// Set maximum cache size
  void setMaxCacheSize(int maxSizeBytes) {
    _maxCacheSize = maxSizeBytes;
  }

  /// Get cached file path for a sheet music URL
  /// Returns null if not cached
  Future<String?> getCachedPath(String url) async {
    if (!_isInitialized) await initialize();
    if (_cacheDir == null) return null;

    final fileName = _getFileNameFromUrl(url);
    final file = File(path.join(_cacheDir!.path, fileName));

    if (await file.exists()) {
      // Update access time for LRU
      _accessTimes[url] = DateTime.now();
      return file.path;
    }

    return null;
  }

  /// Download and cache sheet music from URL
  /// Returns local file path if successful, null otherwise
  Future<String?> downloadAndCache(String url) async {
    if (!_isInitialized) await initialize();
    if (_cacheDir == null) return null;

    // Check if already cached
    final cachedPath = await getCachedPath(url);
    if (cachedPath != null) {
      return cachedPath;
    }

    try {
      if (kDebugMode) {
        debugPrint('📥 Downloading sheet music: $url');
      }

      // Download file
      final response = await http.get(
        Uri.parse(url),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Download timeout');
        },
      );

      if (response.statusCode == 200) {
        // Check cache size and evict if needed
        await _ensureCacheSpace(response.bodyBytes.length);

        // Save to cache
        final fileName = _getFileNameFromUrl(url);
        final file = File(path.join(_cacheDir!.path, fileName));
        await file.writeAsBytes(response.bodyBytes);

        // Update access time
        _accessTimes[url] = DateTime.now();

        if (kDebugMode) {
          debugPrint('✅ Cached sheet music: ${file.path}');
        }

        return file.path;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to download sheet music: HTTP ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error downloading sheet music: $e');
      }
      return null;
    }
  }

  /// Get current cache size in bytes
  Future<int> getCacheSize() async {
    if (!_isInitialized) await initialize();
    if (_cacheDir == null) return 0;

    try {
      int totalSize = 0;
      await for (final entity in _cacheDir!.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error calculating cache size: $e');
      }
      return 0;
    }
  }

  /// Get cache size as human-readable string
  Future<String> getCacheSizeString() async {
    final sizeBytes = await getCacheSize();
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    if (!_isInitialized) await initialize();
    if (_cacheDir == null) return;

    try {
      if (await _cacheDir!.exists()) {
        await for (final entity in _cacheDir!.list()) {
          await entity.delete(recursive: true);
        }
      }

      _accessTimes.clear();

      if (kDebugMode) {
        debugPrint('✅ Cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing cache: $e');
      }
    }
  }

  /// Delete cached file for a specific URL
  Future<bool> deleteCachedFile(String url) async {
    if (!_isInitialized) await initialize();
    if (_cacheDir == null) return false;

    try {
      final fileName = _getFileNameFromUrl(url);
      final file = File(path.join(_cacheDir!.path, fileName));

      if (await file.exists()) {
        await file.delete();
        _accessTimes.remove(url);
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting cached file: $e');
      }
      return false;
    }
  }

  /// Ensure cache has space for new file
  /// Uses LRU eviction policy
  Future<void> _ensureCacheSpace(int requiredBytes) async {
    final currentSize = await getCacheSize();
    final targetSize = _maxCacheSize - requiredBytes;

    if (currentSize <= targetSize) {
      return; // Enough space
    }

    if (kDebugMode) {
      debugPrint('🗑️ Cache full, evicting LRU files...');
    }

    // Sort files by access time (oldest first)
    final sortedEntries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Delete oldest files until we have enough space
    int freedSpace = 0;
    for (final entry in sortedEntries) {
      if (currentSize - freedSpace <= targetSize) {
        break;
      }

      final deleted = await deleteCachedFile(entry.key);
      if (deleted) {
        final fileName = _getFileNameFromUrl(entry.key);
        final file = File(path.join(_cacheDir!.path, fileName));
        if (await file.exists()) {
          freedSpace += await file.length();
        }
      }
    }

    if (kDebugMode) {
      debugPrint('✅ Freed ${(freedSpace / (1024 * 1024)).toStringAsFixed(2)} MB');
    }
  }

  /// Get file name from URL
  String _getFileNameFromUrl(String url) {
    // Extract filename from URL, sanitize for filesystem
    final uri = Uri.parse(url);
    var fileName = path.basename(uri.path);
    
    // Remove query parameters from filename
    if (fileName.contains('?')) {
      fileName = fileName.split('?').first;
    }

    // Sanitize filename (replace invalid characters)
    fileName = fileName.replaceAll(RegExp(r'[<>:"|?*]'), '_');
    
    // Use URL hash as fallback if no filename
    if (fileName.isEmpty || !fileName.contains('.')) {
      fileName = '${uri.hashCode}.webp';
    }

    return fileName;
  }

  /// Get cache directory path
  String? get cacheDirectory => _cacheDir?.path;
  
  bool get isInitialized => _isInitialized;
}





