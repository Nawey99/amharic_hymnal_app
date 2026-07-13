// lib/core/services/background_image_service.dart
import 'package:flutter/foundation.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';

/// Service to manage background image state reactively
/// Allows pages to listen to changes without restarting the app
class BackgroundImageService extends ChangeNotifier {
  static final BackgroundImageService _instance =
      BackgroundImageService._internal();
  factory BackgroundImageService() => _instance;
  BackgroundImageService._internal();

  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  /// Initialize from SettingsService
  void initialize(bool value) {
    if (_isEnabled != value) {
      _isEnabled = value;
      notifyListeners();
    }
  }

  /// Update background image setting
  Future<void> setEnabled(bool value) async {
    if (_isEnabled != value) {
      _isEnabled = value;
      // Also update SettingsService for persistence
      await SettingsService.setBackgroundImageEnabled(value);
      notifyListeners();
    }
  }

  /// Toggle background image
  Future<void> toggle() async {
    await setEnabled(!_isEnabled);
  }
}
