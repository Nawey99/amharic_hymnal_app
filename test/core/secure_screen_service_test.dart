import 'package:amharic_hymnal_app/core/services/secure_screen_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(SecureScreenService.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> platformCalls;

  setUp(() async {
    await SecureScreenService.resetForTesting();
    platformCalls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      platformCalls.add(call.method);
      if (call.method == 'isCaptured') return false;
      return null;
    });
  });

  tearDown(() async {
    await SecureScreenService.resetForTesting();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('deduplicates native enable and disable calls by owner', () async {
    final firstOwner = Object();
    final secondOwner = Object();

    await SecureScreenService.acquire(firstOwner);
    await SecureScreenService.acquire(firstOwner);
    await SecureScreenService.acquire(secondOwner);
    await SecureScreenService.release(firstOwner);

    expect(platformCalls, ['enable', 'isCaptured']);

    await SecureScreenService.release(secondOwner);
    expect(platformCalls, ['enable', 'isCaptured', 'disable']);
  });

  test('forwards capture and screenshot events only while protected', () async {
    final owner = Object();
    await SecureScreenService.acquire(owner);
    final events = <SecureScreenEvent>[];
    final subscription = SecureScreenService.events.listen(events.add);

    await SecureScreenService.dispatchPlatformCallForTesting(
      const MethodCall('captureChanged', true),
    );
    await SecureScreenService.dispatchPlatformCallForTesting(
      const MethodCall('screenshotTaken'),
    );

    expect(SecureScreenService.isCaptured, isTrue);
    expect(
      events.map((event) => event.type),
      [
        SecureScreenEventType.captureChanged,
        SecureScreenEventType.screenshotTaken,
      ],
    );

    await SecureScreenService.release(owner);
    await SecureScreenService.dispatchPlatformCallForTesting(
      const MethodCall('screenshotTaken'),
    );
    expect(events, hasLength(2));

    await subscription.cancel();
  });
}
