// lib/core/services/secure_storage_service_platform.dart
// Platform-specific implementation using flutter_secure_storage
// This file is used on Android, iOS, Linux, macOS, and Web

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Platform-specific secure storage service implementation
/// Uses FlutterSecureStorage on supported platforms, falls back to SharedPreferences on error
class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  SecureStorageService._();

  bool _useSecureStorage = true;
  bool _initialized = false;
  FlutterSecureStorage? _secureStorage;
  SharedPreferences? _prefs;

  /// Initialize the appropriate storage backend
  Future<void> _initStorage() async {
    if (_initialized) return;
    
    // Try FlutterSecureStorage first
    if (_useSecureStorage) {
      try {
        _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );
        if (kDebugMode) {
          debugPrint('✅ FlutterSecureStorage initialized successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ FlutterSecureStorage initialization failed, falling back to SharedPreferences: $e');
        }
        _useSecureStorage = false;
        _secureStorage = null;
      }
    }

    // Fallback to SharedPreferences if secure storage isn't available
    if (!_useSecureStorage) {
      try {
        _prefs ??= await SharedPreferences.getInstance();
        if (kDebugMode) {
          debugPrint('✅ Using SharedPreferences for storage (fallback mode)');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Failed to initialize SharedPreferences: $e');
        }
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

  /// Store a value securely
  Future<void> write(String key, String value) async {
    await _ensureInitialized();
    
    try {
      if (_useSecureStorage && _secureStorage != null) {
        await _secureStorage!.write(key: key, value: value);
      } else if (_prefs != null) {
        await _prefs!.setString('secure_$key', value);
      } else {
        throw Exception('Storage not initialized');
      }
      
      if (kDebugMode) {
        debugPrint('✅ Stored value for key: $key (using ${_useSecureStorage ? "secure storage" : "SharedPreferences"})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to store value for key $key: $e');
      }
      rethrow;
    }
  }

  /// Read a value securely
  Future<String?> read(String key) async {
    await _ensureInitialized();
    
    try {
      String? value;
      if (_useSecureStorage && _secureStorage != null) {
        value = await _secureStorage!.read(key: key);
      } else if (_prefs != null) {
        value = _prefs!.getString('secure_$key');
      }
      
      if (kDebugMode && value != null) {
        debugPrint('✅ Retrieved value for key: $key');
      }
      return value;
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
      if (_useSecureStorage && _secureStorage != null) {
        await _secureStorage!.delete(key: key);
      } else if (_prefs != null) {
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
      if (_useSecureStorage && _secureStorage != null) {
        await _secureStorage!.deleteAll();
      } else if (_prefs != null) {
        final keys = _prefs!.getKeys().where((key) => key.startsWith('secure_'));
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
      if (_useSecureStorage && _secureStorage != null) {
        final value = await _secureStorage!.read(key: key);
        return value != null;
      } else if (_prefs != null) {
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








