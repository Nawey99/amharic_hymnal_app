// lib/core/services/screen_service.dart
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';

class ScreenService {
  /// Initialize screen wake lock based on settings
  static Future<void> initialize() async {
    final keepScreenOn = SettingsService.getKeepScreenOn();
    if (keepScreenOn) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  /// Update screen wake lock state
  static Future<void> updateKeepScreenOn(bool enabled) async {
    if (enabled) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }
}
