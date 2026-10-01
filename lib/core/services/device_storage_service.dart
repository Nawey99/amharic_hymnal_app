import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/services.dart';

/// What the app needs to know about the phone's storage that Dart cannot
/// tell it: how much room is free, and keeping re-downloadable files out of
/// the iPhone's backup.
class DeviceStorageService {
  DeviceStorageService._();

  static const String channelName = 'wudase/storage';
  static const MethodChannel _channel = MethodChannel(channelName);

  static final Set<String> _excluded = {};

  /// Keeps [directory] and everything in it out of iCloud and device
  /// backups on iOS. Downloaded hymns, audio and sheet music can always be
  /// fetched again, so backing them up only fills the reader's iCloud.
  ///
  /// Android needs nothing: the app does not take part in backup at all
  /// (`allowBackup="false"`). Failures are ignored; at worst the files are
  /// backed up as before.
  static Future<void> excludeFromBackup(Directory directory) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    if (!_excluded.add(directory.path)) return;
    try {
      await directory.create(recursive: true);
      await _channel.invokeMethod<void>(
        'excludeFromBackup',
        {'path': directory.path},
      );
    } on MissingPluginException {
      _excluded.remove(directory.path);
    } catch (error) {
      _excluded.remove(directory.path);
      if (kDebugMode) debugPrint('Could not exclude from backup: $error');
    }
  }

  /// Bytes free on the volume holding [directory], or null when the phone
  /// cannot say.
  static Future<int?> freeBytes(Directory directory) async {
    if (kIsWeb) return null;
    try {
      await directory.create(recursive: true);
      return await _channel.invokeMethod<int>(
        'freeBytes',
        {'path': directory.path},
      );
    } on MissingPluginException {
      return null;
    } catch (error) {
      if (kDebugMode) debugPrint('Could not read free space: $error');
      return null;
    }
  }
}
