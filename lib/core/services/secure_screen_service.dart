import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SecureScreenService {
  static const MethodChannel _channel = MethodChannel('wudase/secure_screen');

  static Future<void> setProtected(bool enabled) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>(
        enabled ? 'enable' : 'disable',
      );
    } on MissingPluginException {
      // Non-mobile platforms are allowed to no-op.
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint('Secure screen update failed: ${error.message}');
      }
    }
  }
}
