// lib/core/services/remote_sheet_music_service.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:convert';

/// Remote sheet music service - fetches sheet music from CDN/server
/// 
/// Similar architecture to GlobalAudioService
/// Supports on-demand loading with URL resolution
class RemoteSheetMusicService {
  static final RemoteSheetMusicService _instance = RemoteSheetMusicService._internal();
  factory RemoteSheetMusicService() => _instance;
  RemoteSheetMusicService._internal();

  String? _baseUrl;
  String? _apiKey;
  bool _isInitialized = false;

  /// Initialize the service with API configuration
  /// 
  /// [baseUrl] - Base URL for sheet music CDN/server
  /// [apiKey] - Optional API key for authentication
  Future<void> initialize({String? baseUrl, String? apiKey}) async {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('⚠️ RemoteSheetMusicService already initialized');
      }
      return;
    }

    _baseUrl = baseUrl;
    _apiKey = apiKey;

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('✅ RemoteSheetMusicService initialized');
      if (baseUrl != null) {
        debugPrint('   Base URL: $baseUrl');
      }
    }
  }

  /// Set API configuration (can be called after initialization)
  void setApiConfig({String? baseUrl, String? apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
  }

  /// Get sheet music URL for a specific hymn number
  /// 
  /// [hymnNumber] - The hymn number to get sheet music for
  /// [page] - Optional page indicator ('L', 'R', or null for single page)
  /// 
  /// Returns the sheet music URL if available, null otherwise
  /// 
  /// URL patterns:
  /// - Single page: {baseUrl}/sheet_music/{hymnNumber}.webp
  /// - Two pages: {baseUrl}/sheet_music/{hymnNumber}_L.webp or {hymnNumber}_R.webp
  String? getSheetMusicUrl(int hymnNumber, {String? page}) {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Base URL not configured for sheet music');
      }
      return null;
    }

    String fileName;
    if (page != null && (page == 'L' || page == 'R')) {
      fileName = '${hymnNumber}_$page.webp';
    } else {
      fileName = '$hymnNumber.webp';
    }

    final url = _apiKey != null && _apiKey!.isNotEmpty
        ? '$_baseUrl/sheet_music/$fileName?apiKey=$_apiKey'
        : '$_baseUrl/sheet_music/$fileName';

    return url;
  }

  /// Get all sheet music URLs for a hymn (handles single page or L/R pages)
  /// 
  /// [hymnNumber] - The hymn number
  /// 
  /// Returns list of URLs. Empty list if not available.
  /// First checks for two-page format (L/R), then single page.
  Future<List<String>> getSheetMusicUrls(int hymnNumber) async {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      return [];
    }

    final urls = <String>[];

    // Try two-page format first (L and R)
    final leftUrl = getSheetMusicUrl(hymnNumber, page: 'L');
    final rightUrl = getSheetMusicUrl(hymnNumber, page: 'R');

    if (leftUrl != null && rightUrl != null) {
      // Check if both pages exist
      final leftExists = await _checkUrlExists(leftUrl);
      final rightExists = await _checkUrlExists(rightUrl);

      if (leftExists && rightExists) {
        urls.add(leftUrl);
        urls.add(rightUrl);
        return urls;
      }
    }

    // Fallback to single page format
    final singleUrl = getSheetMusicUrl(hymnNumber);
    if (singleUrl != null) {
      final exists = await _checkUrlExists(singleUrl);
      if (exists) {
        urls.add(singleUrl);
      }
    }

    return urls;
  }

  /// Check if a URL exists (HEAD request)
  Future<bool> _checkUrlExists(String url) async {
    try {
      final response = await http.head(
        Uri.parse(url),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return http.Response('', 408); // Timeout
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking sheet music URL: $url - $e');
      }
      return false;
    }
  }

  /// Resolve sheet music URLs from API (alternative approach)
  /// 
  /// [hymnNumber] - The hymn number to get sheet music for
  /// Returns list of sheet music URLs if found, empty list otherwise
  /// 
  /// API format: {baseUrl}/api/sheet_music/{hymnNumber}
  /// Response: { "urls": ["url1", "url2"] } or { "url": "url1" }
  Future<List<String>> resolveSheetMusicUrls(int hymnNumber) async {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Base URL not configured for sheet music API');
      }
      return [];
    }

    try {
      // Construct API URL
      final url = _apiKey != null && _apiKey!.isNotEmpty
          ? '$_baseUrl/api/sheet_music/$hymnNumber?apiKey=$_apiKey'
          : '$_baseUrl/api/sheet_music/$hymnNumber';

      if (kDebugMode) {
        debugPrint('🔍 Resolving sheet music URLs for hymn #$hymnNumber: $url');
      }

      // Make API request with timeout
      final response = await http.get(
        Uri.parse(url),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏱️ Sheet music API request timeout for hymn #$hymnNumber');
          }
          throw Exception('Sheet music API request timed out');
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          
          // Extract URLs from response
          // Supports multiple formats: { "urls": [...] } or { "url": "..." }
          if (data.containsKey('urls')) {
            final urls = data['urls'] as List<dynamic>?;
            if (urls != null) {
              return urls.map((e) => e.toString()).toList();
            }
          } else if (data.containsKey('url')) {
            return [data['url'] as String];
          } else if (data.containsKey('sheet_music_url')) {
            return [data['sheet_music_url'] as String];
          }
          
          if (kDebugMode) {
            debugPrint('⚠️ Sheet music URLs not found in API response for hymn #$hymnNumber');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Failed to parse API response for hymn #$hymnNumber: $e');
          }
        }
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          debugPrint('ℹ️ Sheet music not found (404) for hymn #$hymnNumber');
        }
        // 404 is not an error - just means sheet music doesn't exist for this hymn
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ API returned status ${response.statusCode} for hymn #$hymnNumber');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to resolve sheet music URLs for hymn #$hymnNumber: $e');
      }
    }

    return [];
  }

  /// Check if sheet music is available for a hymn
  Future<bool> hasSheetMusic(int hymnNumber) async {
    final urls = await getSheetMusicUrls(hymnNumber);
    return urls.isNotEmpty;
  }

  String? get baseUrl => _baseUrl;
  bool get isInitialized => _isInitialized;
}





