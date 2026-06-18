// lib/core/services/history_service.dart
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/utils/constants.dart';

class HistoryService {
  static SharedPreferences? _prefs;
  static const int maxHistorySize = 20;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get list of recently viewed hymn numbers (most recent first)
  static List<int> getHistory() {
    final List<String>? history =
        _prefs?.getStringList(AppConstants.keyHistory);
    if (history == null) return [];
    return history
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e > 0)
        .toList();
  }

  /// Add a hymn to history (most recent first)
  static Future<bool> addToHistory(int hymnNumber) async {
    if (hymnNumber <= 0) return false;

    final List<int> history = getHistory();

    // Remove if already exists (to move to top)
    history.remove(hymnNumber);

    // Add to beginning
    history.insert(0, hymnNumber);

    // Limit to max size
    if (history.length > maxHistorySize) {
      history.removeRange(maxHistorySize, history.length);
    }

    // Save back to SharedPreferences
    final List<String> historyStrings =
        history.map((e) => e.toString()).toList();
    return await _prefs?.setStringList(
            AppConstants.keyHistory, historyStrings) ??
        false;
  }

  /// Clear all history
  static Future<bool> clearHistory() async {
    return await _prefs?.remove(AppConstants.keyHistory) ?? false;
  }

  /// Remove a specific hymn from history
  static Future<bool> removeFromHistory(int hymnNumber) async {
    final List<int> history = getHistory();
    history.remove(hymnNumber);

    final List<String> historyStrings =
        history.map((e) => e.toString()).toList();
    return await _prefs?.setStringList(
            AppConstants.keyHistory, historyStrings) ??
        false;
  }
}
