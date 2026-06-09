// lib/core/services/search_state_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Stream-based controller managing search query state
/// 
/// Features:
/// - 350ms debounce (configurable)
/// - Emits normalized queries via stream
/// - Handles empty query reset automatically
/// - Zero UI logic, pure state management
/// 
/// Architecture: This is the middle layer between UI (SearchTextField) and
/// search logic (SearchEngine). It handles debouncing and state management
/// without any UI dependencies.
class SearchStateController {
  final StreamController<String> _queryController = StreamController<String>.broadcast();
  Timer? _debounceTimer;
  String _currentQuery = '';
  static const Duration _debounceDuration = Duration(milliseconds: 350);
  
  // Validation logs (disabled by default, can be enabled for debugging)
  bool _enableValidationLogs = false;

  /// Stream of search queries (debounced and normalized)
  /// 
  /// Emits:
  /// - Empty string when query is cleared
  /// - Normalized query after debounce period
  /// - Immediately emits empty string if query becomes empty
  Stream<String> get queryStream => _queryController.stream;

  /// Current query value
  String get currentQuery => _currentQuery;

  /// Update the search query
  /// 
  /// [query] - Raw query from UI (will be normalized)
  /// 
  /// Behavior:
  /// - If query is empty, immediately emits empty string (no debounce)
  /// - Otherwise, debounces for 350ms before emitting
  /// - Cancels previous debounce timer if new query arrives
  void updateQuery(String query) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // If query is empty, emit immediately (no debounce for clear)
    if (query.isEmpty) {
      _currentQuery = '';
      _queryController.add('');
      if (_enableValidationLogs && kDebugMode) {
        debugPrint('🔍 [SearchStateController] Query cleared - immediate emit');
      }
      return;
    }

    // Store current query for immediate access
    _currentQuery = query;

    // Temporary validation log
    if (_enableValidationLogs && kDebugMode) {
      debugPrint('🔍 [SearchStateController] Query updated: "$query" (debouncing...)');
    }

    // Debounce search queries
    _debounceTimer = Timer(_debounceDuration, () {
      if (_currentQuery.isNotEmpty) {
        _queryController.add(_currentQuery);
        if (_enableValidationLogs && kDebugMode) {
          debugPrint('🔍 [SearchStateController] Query emitted after debounce: "$_currentQuery"');
        }
      }
    });
  }

  /// Clear the current query
  /// 
  /// Immediately emits empty string (no debounce)
  void clear() {
    _debounceTimer?.cancel();
    _currentQuery = '';
    _queryController.add('');
    if (_enableValidationLogs && kDebugMode) {
      debugPrint('🔍 [SearchStateController] Query cleared via clear()');
    }
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _queryController.close();
  }

  /// Disable validation logs (call after testing)
  void disableValidationLogs() {
    _enableValidationLogs = false;
  }
}

