// lib/core/services/history_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:amharic_hymnal_app/core/utils/constants.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

/// One opened hymn, by song ID (`am-sda-2004-0132`). The ID names the
/// edition and survives the hymn being renumbered.
class HistoryEntry {
  final String songId;

  const HistoryEntry(this.songId);

  String get storageValue => songId;

  /// The number in the song ID, i.e. the hymn's number when it was created.
  /// Screens should show the number of the hymn they find for [songId].
  int get hymnNumber => int.tryParse(songId.split('-').last) ?? 0;

  static final RegExp _songId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$');
  static final RegExp _versioned = RegExp(r'^([a-z0-9_]+):(\d+)$');

  /// Reads a stored value. Older versions stored `sda_new:132`, and before
  /// that only the number, which belonged to the 2004 book; both are read as
  /// the song IDs those numbers were created under.
  static HistoryEntry? parse(String value) {
    final versioned = _versioned.firstMatch(value);
    if (versioned != null) {
      final number = int.tryParse(versioned.group(2)!);
      if (number == null || number <= 0) return null;
      return HistoryEntry(HymnalVersions.songId(versioned.group(1)!, number));
    }

    final legacyNumber = int.tryParse(value);
    if (legacyNumber != null) {
      return legacyNumber > 0
          ? HistoryEntry(
              HymnalVersions.songId(HymnalVersions.sdaNew, legacyNumber))
          : null;
    }

    return _songId.hasMatch(value) ? HistoryEntry(value) : null;
  }

  @override
  bool operator ==(Object other) =>
      other is HistoryEntry && other.songId == songId;

  @override
  int get hashCode => songId.hashCode;
}

class HistoryService {
  static SharedPreferences? _prefs;
  static const int maxHistorySize = 20;

  static Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    await _rewriteOlderEntries();
  }

  /// Stores entries written by an older version as song IDs, once.
  static Future<void> _rewriteOlderEntries() async {
    final stored = _prefs?.getStringList(AppConstants.keyHistory);
    if (stored == null) return;
    final entries = getHistoryEntries();
    final values = entries.map((entry) => entry.storageValue).toList();
    if (!listEquals(stored, values)) {
      await _prefs?.setStringList(AppConstants.keyHistory, values);
    }
  }

  /// Recently opened hymns, most recent first.
  static List<HistoryEntry> getHistoryEntries() {
    final history = _prefs?.getStringList(AppConstants.keyHistory);
    if (history == null) return [];
    final seen = <String>{};
    final entries = <HistoryEntry>[];
    for (final item in history) {
      final entry = HistoryEntry.parse(item);
      if (entry == null) continue;
      if (seen.add(entry.songId)) entries.add(entry);
    }
    return entries;
  }

  /// Puts [songId] at the top of the history.
  static Future<bool> addToHistory(String songId) async {
    final entry = HistoryEntry.parse(songId);
    if (entry == null) return false;

    final history = getHistoryEntries()
      ..removeWhere((item) => item.songId == entry.songId)
      ..insert(0, entry);
    if (history.length > maxHistorySize) {
      history.removeRange(maxHistorySize, history.length);
    }

    return await _prefs?.setStringList(
          AppConstants.keyHistory,
          history.map((e) => e.storageValue).toList(),
        ) ??
        false;
  }

  /// Clear all history
  static Future<bool> clearHistory() async {
    return await _prefs?.remove(AppConstants.keyHistory) ?? false;
  }

  /// Removes [songId] from the history.
  static Future<bool> removeFromHistory(String songId) async {
    final history = getHistoryEntries()
      ..removeWhere((item) => item.songId == songId);
    return await _prefs?.setStringList(
          AppConstants.keyHistory,
          history.map((e) => e.storageValue).toList(),
        ) ??
        false;
  }

  @visibleForTesting
  static void resetForTesting() {
    _prefs = null;
  }
}
