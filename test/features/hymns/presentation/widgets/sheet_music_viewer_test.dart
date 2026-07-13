import 'package:amharic_hymnal_app/core/services/secure_screen_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/sheet_music_viewer_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/sheet_music_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sheet music stays fixed until the user zooms in',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SheetMusicViewer(
            sheetMusicFiles: ['01.webp'],
            hymnNumber: 1,
          ),
        ),
      ),
    );
    await tester.pump();

    InteractiveViewer viewer = tester.widget(find.byType(InteractiveViewer));
    final controller = viewer.transformationController!;

    expect(viewer.panEnabled, isFalse);
    expect(controller.value.storage, orderedEquals(Matrix4.identity().storage));

    await tester.drag(find.byType(InteractiveViewer), const Offset(60, 40));
    await tester.pump();
    expect(controller.value.storage, orderedEquals(Matrix4.identity().storage));

    final center = tester.getCenter(find.byType(InteractiveViewer));
    TestGesture gesture = await tester.startGesture(center);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    gesture = await tester.startGesture(center);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 500));

    viewer = tester.widget(find.byType(InteractiveViewer));
    expect(viewer.panEnabled, isTrue);
    expect(controller.value.getMaxScaleOnAxis(), 2.0);

    final viewerSize = tester.getSize(find.byType(InteractiveViewer));
    expect(viewerSize.width / viewerSize.height, closeTo(2 / 3, 0.001));
    final localCenter = viewerSize.center(Offset.zero);
    final transformedCenter = MatrixUtils.transformPoint(
      controller.value,
      localCenter,
    );
    expect(transformedCenter.dx, closeTo(localCenter.dx, 0.001));
    expect(transformedCenter.dy, closeTo(localCenter.dy, 0.001));
    expect(find.text('ገጽ 1'), findsNothing);
  });

  testWidgets('sheet music page combines hymn number and title',
      (tester) async {
    await SecureScreenService.resetForTesting();
    SecureScreenService.platformInvokerForTesting = (method) async {
      if (method == 'isCaptured') return false;
      return null;
    };

    await tester.pumpWidget(
      const MaterialApp(
        home: SheetMusicViewerPage(
          hymn: Hymn(
            number: 1,
            title: 'አምላካችን',
            lyrics: 'አምላካችን አመስግኑ\nበምድር ያላችሁ ሁሉ',
          ),
          sheetMusicFiles: ['01.webp'],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 አምላካችን አመስግኑ'), findsOneWidget);
    expect(find.text('መዝሙር 1 ኖታ'), findsNothing);
    expect(find.text('ገጽ 1'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await SecureScreenService.resetForTesting();
  });

  testWidgets('iOS privacy overlay follows capture and app lifecycle',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    await SecureScreenService.resetForTesting();
    final platformCalls = <String>[];
    SecureScreenService.platformInvokerForTesting = (method) async {
      platformCalls.add(method);
      if (method == 'isCaptured') return false;
      return null;
    };
    addTearDown(() async {
      await SecureScreenService.resetForTesting();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SheetMusicViewerPage(
          hymn: Hymn(
            number: 1,
            title: 'አምላካችን',
            lyrics: 'አምላካችን አመስግኑ',
          ),
          sheetMusicFiles: ['01.webp'],
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(SecureScreenService.settleForTesting);

    const privacyMessage = 'Screen capture is not allowed for this content.';
    expect(find.text(privacyMessage), findsNothing);

    await SecureScreenService.dispatchPlatformCallForTesting(
      const MethodCall('captureChanged', true),
    );
    await tester.pump();
    expect(find.text(privacyMessage), findsOneWidget);

    await SecureScreenService.dispatchPlatformCallForTesting(
      const MethodCall('captureChanged', false),
    );
    await tester.pump();
    expect(find.text(privacyMessage), findsNothing);

    final dynamic pageState = tester.state(find.byType(SheetMusicViewerPage));
    pageState.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text(privacyMessage), findsOneWidget);

    pageState.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text(privacyMessage), findsNothing);

    await SecureScreenService.dispatchPlatformCallForTesting(
      const MethodCall('screenshotTaken'),
    );
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Screenshots of sheet music are not permitted.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(SecureScreenService.settleForTesting);
    expect(platformCalls.where((method) => method == 'enable'), hasLength(1));
    expect(platformCalls.where((method) => method == 'disable'), hasLength(1));
    debugDefaultTargetPlatformOverride = null;
  });
}
