import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum SecureScreenEventType {
  captureChanged,
  screenshotTaken,
}

@immutable
class SecureScreenEvent {
  final SecureScreenEventType type;
  final bool? isCaptured;

  const SecureScreenEvent._(this.type, {this.isCaptured});

  const SecureScreenEvent.captureChanged(bool isCaptured)
      : this._(
          SecureScreenEventType.captureChanged,
          isCaptured: isCaptured,
        );

  const SecureScreenEvent.screenshotTaken()
      : this._(SecureScreenEventType.screenshotTaken);
}

class SecureScreenService {
  static const String channelName = 'wudase/secure_screen';
  static const MethodChannel _channel = MethodChannel(channelName);

  static final Set<Object> _owners = Set<Object>.identity();
  static final StreamController<SecureScreenEvent> _events =
      StreamController<SecureScreenEvent>.broadcast(sync: true);

  static Future<void>? _platformQueue;
  static bool _methodHandlerInstalled = false;
  static bool _isCaptured = false;

  @visibleForTesting
  static Future<Object?> Function(String method)? platformInvokerForTesting;

  static Stream<SecureScreenEvent> get events => _events.stream;
  static bool get isCaptured => _isCaptured;

  static bool get usesPrivacyOverlay =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<bool> acquire(Object owner) async {
    _installMethodHandler();
    if (!_owners.add(owner)) return _isCaptured;

    if (_owners.length == 1) {
      await _enqueuePlatformCall('enable');
      if (_owners.contains(owner)) {
        return refreshCaptureState();
      }
    }
    return _isCaptured;
  }

  static Future<void> release(Object owner) async {
    if (!_owners.remove(owner) || _owners.isNotEmpty) return;

    _updateCaptureState(false, emitEvent: false);
    await _enqueuePlatformCall('disable');
  }

  static Future<bool> refreshCaptureState() async {
    if (_owners.isEmpty) return false;
    final captured = await _invokePlatform<bool>('isCaptured') ?? false;
    if (_owners.isNotEmpty) {
      _updateCaptureState(captured, emitEvent: false);
    }
    return _isCaptured;
  }

  static void _installMethodHandler() {
    if (_methodHandlerInstalled) return;
    _methodHandlerInstalled = true;
    _channel.setMethodCallHandler(_handlePlatformCall);
  }

  static Future<void> _handlePlatformCall(MethodCall call) async {
    if (_owners.isEmpty) return;

    switch (call.method) {
      case 'captureChanged':
        final captured = call.arguments == true;
        _updateCaptureState(captured, emitEvent: true);
        return;
      case 'screenshotTaken':
        _events.add(const SecureScreenEvent.screenshotTaken());
        return;
    }
  }

  static void _updateCaptureState(
    bool captured, {
    required bool emitEvent,
  }) {
    if (_isCaptured == captured) return;
    _isCaptured = captured;
    if (emitEvent) {
      _events.add(SecureScreenEvent.captureChanged(captured));
    }
  }

  static Future<void> _enqueuePlatformCall(String method) {
    final previousOperation = _platformQueue;
    final operation = () async {
      if (previousOperation != null) {
        await previousOperation;
      }
      await _invokePlatform<void>(method);
    }();
    _platformQueue = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_platformQueue, operation)) {
          _platformQueue = null;
        }
      }),
    );
    return operation;
  }

  static Future<T?> _invokePlatform<T>(String method) async {
    try {
      final testInvoker = platformInvokerForTesting;
      if (testInvoker != null) {
        return await testInvoker(method) as T?;
      }
      return await _channel.invokeMethod<T>(method);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint('Secure screen $method failed: ${error.message}');
      }
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Secure screen $method failed: $error');
      }
      return null;
    }
  }

  @visibleForTesting
  static Future<void> dispatchPlatformCallForTesting(MethodCall call) {
    return _handlePlatformCall(call);
  }

  @visibleForTesting
  static Future<void> settleForTesting() async {
    final pendingOperation = _platformQueue;
    if (pendingOperation != null) {
      await pendingOperation;
    }
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    final pendingOperation = _platformQueue;
    if (pendingOperation != null) {
      await pendingOperation;
    }
    _owners.clear();
    _isCaptured = false;
    platformInvokerForTesting = null;
    _platformQueue = null;
  }
}
