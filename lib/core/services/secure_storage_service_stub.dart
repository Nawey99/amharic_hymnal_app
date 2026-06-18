// lib/core/services/secure_storage_service_stub.dart
// Stub implementation for platforms that don't support flutter_secure_storage
// This file is used on Windows to avoid importing flutter_secure_storage

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Stub secure storage service that uses SharedPreferences
/// Used on Windows where flutter_secure_storage isn't available
class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  SecureStorageService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize SharedPreferences
  Future<void> _initStorage() async {
    if (_initialized) return;

    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (kDebugMode) {
        debugPrint('✅ Using SharedPreferences for storage (Windows)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize SharedPreferences: $e');
      }
    }

    _initialized = true;
  }

  /// Ensure storage is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initStorage();
    }
  }

  /// Store a value
  Future<void> write(String key, String value) async {
    await _ensureInitialized();

    try {
      if (_prefs != null) {
        await _prefs!.setString('secure_$key', value);
      } else {
        throw Exception('Storage not initialized');
      }

      if (kDebugMode) {
        debugPrint('✅ Stored value for key: $key (using SharedPreferences)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to store value for key $key: $e');
      }
      rethrow;
    }
  }

  /// Read a value
  Future<String?> read(String key) async {
    await _ensureInitialized();

    try {
      if (_prefs != null) {
        final value = _prefs!.getString('secure_$key');
        if (kDebugMode && value != null) {
          debugPrint('✅ Retrieved value for key: $key');
        }
        return value;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to read value for key $key: $e');
      }
      return null;
    }
  }

  /// Delete a value
  Future<void> delete(String key) async {
    await _ensureInitialized();

    try {
      if (_prefs != null) {
        await _prefs!.remove('secure_$key');
      }

      if (kDebugMode) {
        debugPrint('✅ Deleted value for key: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete value for key $key: $e');
      }
    }
  }

  /// Delete all stored values
  Future<void> deleteAll() async {
    await _ensureInitialized();

    try {
      if (_prefs != null) {
        final keys =
            _prefs!.getKeys().where((key) => key.startsWith('secure_'));
        for (final key in keys) {
          await _prefs!.remove(key);
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Deleted all stored values');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete all stored values: $e');
      }
    }
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();

    try {
      if (_prefs != null) {
        return _prefs!.containsKey('secure_$key');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to check key existence for $key: $e');
      }
      return false;
    }
  }
}
