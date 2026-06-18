import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/services/settings_service.dart';

void main() {
  test('keep screen on setting persists through SettingsService', () async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();

    expect(SettingsService.getKeepScreenOn(), isFalse);
    expect(await SettingsService.setKeepScreenOn(true), isTrue);
    expect(SettingsService.getKeepScreenOn(), isTrue);
    expect(await SettingsService.setKeepScreenOn(false), isTrue);
    expect(SettingsService.getKeepScreenOn(), isFalse);
  });
}
