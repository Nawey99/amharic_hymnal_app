// lib/core/services/history_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:amharic_hymnal_app/core/utils/constants.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

class HistoryEntry {
  final String version;
  final int hymnNumber;

  const HistoryEntry({
    required this.version,
    required this.hymnNumber,
  });

  String get storageValue => '$version:$hymnNumber';

  static HistoryEntry? parse(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      final number = int.tryParse(parts[1]);
      if (number != null && number > 0) {
        return HistoryEntry(
          version: HymnalVersions.normalizeId(parts[0]),
          hymnNumber: number,
        );
      }
    }

    final legacyNumber = int.tryParse(value);
    if (legacyNumber != null && legacyNumber > 0) {
      return HistoryEntry(
        version: HymnalVersions.sdaNew,
        hymnNumber: legacyNumber,
      );
    }

    return null;
  }
}

class HistoryService {
  static SharedPreferences? _prefs;
  static const int maxHistorySize = 20;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get list of recently viewed hymn numbers (most recent first)
  static List<int> getHistory() {
    return getHistoryEntries()
        .map((entry) => entry.hymnNumber)
        .toList(growable: false);
  }

  static List<HistoryEntry> getHistoryEntries() {
    final history = _prefs?.getStringList(AppConstants.keyHistory);
    if (history == null) return [];
    final seen = <String>{};
    final entries = <HistoryEntry>[];
    for (final item in history) {
      final entry = HistoryEntry.parse(item);
      if (entry == null) continue;
      if (seen.add(entry.storageValue)) {
        entries.add(entry);
      }
    }
    return entries;
  }

  /// Add a hymn to history (most recent first)
  static Future<bool> addToHistory(
    int hymnNumber, {
    String version = HymnalVersions.sdaNew,
  }) async {
    if (hymnNumber <= 0) return false;

    final entry = HistoryEntry(
      version: HymnalVersions.normalizeId(version),
      hymnNumber: hymnNumber,
    );
    final history = getHistoryEntries();

    // Remove if already exists (to move to top)
    history.removeWhere((item) => item.storageValue == entry.storageValue);

    // Add to beginning
    history.insert(0, entry);

    // Limit to max size
    if (history.length > maxHistorySize) {
      history.removeRange(maxHistorySize, history.length);
    }

    // Save back to SharedPreferences
    final List<String> historyStrings =
        history.map((e) => e.storageValue).toList();
    return await _prefs?.setStringList(
            AppConstants.keyHistory, historyStrings) ??
        false;
  }

  /// Clear all history
  static Future<bool> clearHistory() async {
    return await _prefs?.remove(AppConstants.keyHistory) ?? false;
  }

  /// Remove a specific hymn from history
  static Future<bool> removeFromHistory(
    int hymnNumber, {
    String? version,
  }) async {
    final history = getHistoryEntries();
    final normalizedVersion =
        version == null ? null : HymnalVersions.normalizeId(version);
    history.removeWhere(
      (item) =>
          item.hymnNumber == hymnNumber &&
          (normalizedVersion == null || item.version == normalizedVersion),
    );

    final List<String> historyStrings =
        history.map((e) => e.storageValue).toList();
    return await _prefs?.setStringList(
            AppConstants.keyHistory, historyStrings) ??
        false;
  }

  @visibleForTesting
  static void resetForTesting() {
    _prefs = null;
  }
}
