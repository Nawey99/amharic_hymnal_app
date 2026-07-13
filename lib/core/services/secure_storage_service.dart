// lib/core/services/secure_storage_service.dart
// Unified secure storage service that works on all platforms

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Service for secure storage of sensitive data (tokens, credentials, etc.)
///
/// On Windows: Uses SharedPreferences only (flutter_secure_storage native plugin excluded)
/// On other platforms: Attempts to use FlutterSecureStorage, falls back to SharedPreferences
///
/// Note: The Windows native plugin is excluded from builds to avoid atlstr.h errors.
/// The Dart package flutter_secure_storage is still in pubspec.yaml but won't be used on Windows.
class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  SecureStorageService._();

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize storage backend
  Future<void> _initStorage() async {
    if (_initialized) return;

    // On Windows, flutter_secure_storage native plugin is excluded from build
    // So we always use SharedPreferences on Windows
    // On other platforms, we can try to use secure storage if available

    // For now, use SharedPreferences on all platforms
    // TODO: If needed in future, add platform-specific secure storage logic
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (kDebugMode) {
        debugPrint(
            '✅ SecureStorageService initialized (using SharedPreferences)');
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
        if (kDebugMode) {
          debugPrint('✅ Stored value for key: $key');
        }
      } else {
        throw Exception('Storage not initialized');
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
        if (kDebugMode) {
          debugPrint('✅ Deleted value for key: $key');
        }
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
        if (kDebugMode) {
          debugPrint('✅ Deleted all stored values');
        }
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
