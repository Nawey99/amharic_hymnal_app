// lib/core/services/font_size_service.dart
import 'package:flutter/foundation.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';

/// Service to manage font size state reactively
/// Allows pages to listen to changes without restarting the app
class FontSizeService extends ChangeNotifier {
  static final FontSizeService _instance = FontSizeService._internal();
  factory FontSizeService() => _instance;
  FontSizeService._internal() {
    // Initialize from SettingsService and clamp to valid range
    _fontSize = SettingsService.getFontSize().clamp(12.0, 30.0);
  }

  double _fontSize = 20.0;

  double get fontSize => _fontSize;

  /// Initialize from SettingsService
  /// Always clamps to valid range (12.0-30.0)
  void initialize(double initialFontSize) {
    // Clamp to valid range to prevent slider assertion errors
    final clampedFontSize = initialFontSize.clamp(12.0, 30.0);
    if (_fontSize != clampedFontSize) {
      _fontSize = clampedFontSize;
      notifyListeners();
    }
  }

  /// Update font size setting
  /// Always clamps to valid range (12.0-30.0) before setting
  Future<void> setFontSize(double fontSize) async {
    // Clamp to valid range to prevent slider assertion errors
    final clampedFontSize = fontSize.clamp(12.0, 30.0);

    if (_fontSize != clampedFontSize) {
      _fontSize = clampedFontSize;
      // Also update SettingsService for persistence
      await SettingsService.setFontSize(clampedFontSize);
      notifyListeners();
    }
  }

  /// Get current font size (synchronous)
  /// Returns clamped value to ensure it's always in valid range
  double getFontSize() => _fontSize.clamp(12.0, 30.0);
}
