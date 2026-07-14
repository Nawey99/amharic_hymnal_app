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
    final contentSize = tester.getSize(
      find.byKey(const ValueKey('sheet-music-content-0')),
    );
    expect(contentSize.width, closeTo(viewerSize.width, 0.001));
    expect(contentSize.height, greaterThan(contentSize.width));
    final localCenter = viewerSize.center(Offset.zero);
    final transformedCenter = MatrixUtils.transformPoint(
      controller.value,
      localCenter,
    );
    expect(transformedCenter.dx, closeTo(localCenter.dx, 0.001));
    expect(transformedCenter.dy, closeTo(localCenter.dy, 0.001));
    expect(find.text('ገጽ 1'), findsNothing);
  });

  testWidgets('sheet music fits the full width in landscape', (tester) async {
    tester.view.physicalSize = const Size(720, 360);
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

    final viewerSize = tester.getSize(find.byType(InteractiveViewer));
    final contentSize = tester.getSize(
      find.byKey(const ValueKey('sheet-music-content-0')),
    );
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );

    expect(viewerSize.width, closeTo(720, 0.001));
    expect(contentSize.width, closeTo(viewerSize.width, 0.001));
    expect(contentSize.height, greaterThan(viewerSize.height));
    expect(viewer.constrained, isFalse);
    expect(viewer.panEnabled, isTrue);
  });

  testWidgets('zoomed sheet can pan to every page edge', (tester) async {
    tester.view.physicalSize = const Size(360, 360);
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

    final viewerFinder = find.byType(InteractiveViewer);
    final contentFinder = find.byKey(const ValueKey('sheet-music-content-0'));
    final contentCenter = tester.getCenter(contentFinder);
    await tester.tapAt(contentCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(contentCenter);
    await tester.pump(const Duration(milliseconds: 500));

    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final controller = viewer.transformationController!;
    final viewerSize = tester.getSize(viewerFinder);
    final contentSize = tester.getSize(contentFinder);
    expect(controller.value.getMaxScaleOnAxis(), 2.0);

    await tester.drag(viewerFinder, const Offset(-1200, -1200));
    await tester.pumpAndSettle();
    final bottomRight = controller.toScene(
      Offset(viewerSize.width, viewerSize.height),
    );
    expect(bottomRight.dx, closeTo(contentSize.width, 0.5));
    expect(bottomRight.dy, closeTo(contentSize.height, 0.5));

    await tester.drag(viewerFinder, const Offset(1200, 1200));
    await tester.pumpAndSettle();
    final topLeft = controller.toScene(Offset.zero);
    expect(topLeft.dx, closeTo(0, 0.5));
    expect(topLeft.dy, closeTo(0, 0.5));
  });

  testWidgets('pinch-zoomed portrait sheet paints both horizontal edges',
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

    final viewerFinder = find.byType(InteractiveViewer);
    final contentFinder = find.byKey(const ValueKey('sheet-music-content-0'));
    final contentCenter = tester.getCenter(contentFinder);
    final firstFinger = await tester.startGesture(
      contentCenter.translate(-20, 0),
      pointer: 1,
    );
    final secondFinger = await tester.startGesture(
      contentCenter.translate(20, 0),
      pointer: 2,
    );
    addTearDown(firstFinger.removePointer);
    addTearDown(secondFinger.removePointer);
    await tester.pump();
    await firstFinger.moveTo(contentCenter.translate(-60, 0));
    await secondFinger.moveTo(contentCenter.translate(40, 0));
    await tester.pump();
    await firstFinger.up();
    await secondFinger.up();
    await tester.pump(const Duration(milliseconds: 500));

    final viewer = tester.widget<InteractiveViewer>(viewerFinder);
    final controller = viewer.transformationController!;
    final viewerSize = tester.getSize(viewerFinder);
    final contentSize = tester.getSize(contentFinder);
    expect(controller.value.getMaxScaleOnAxis(), inExclusiveRange(1.4, 1.42));
    expect(viewer.panEnabled, isTrue);

    await tester.drag(viewerFinder, const Offset(-1600, 0));
    await tester.pump(const Duration(milliseconds: 500));
    final rightEdge = controller.toScene(
      Offset(viewerSize.width, contentSize.height / 2),
    );
    expect(rightEdge.dx, closeTo(contentSize.width, 0.5));
    expect(
      tester.getRect(contentFinder).right,
      closeTo(tester.getRect(viewerFinder).right, 0.5),
    );

    await tester.drag(viewerFinder, const Offset(1600, 0));
    await tester.pump(const Duration(milliseconds: 500));
    final leftEdge = controller.toScene(
      Offset(0, contentSize.height / 2),
    );
    expect(leftEdge.dx, closeTo(0, 0.5));
    expect(
      tester.getRect(contentFinder).left,
      closeTo(tester.getRect(viewerFinder).left, 0.5),
    );
  });

  testWidgets('rotation refits the page width and resets stale zoom',
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

    final center = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 500));

    InteractiveViewer viewer = tester.widget(find.byType(InteractiveViewer));
    final controller = viewer.transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), 2.0);

    tester.view.physicalSize = const Size(720, 360);
    await tester.pump();
    await tester.pump();

    viewer = tester.widget(find.byType(InteractiveViewer));
    final contentSize = tester.getSize(
      find.byKey(const ValueKey('sheet-music-content-0')),
    );
    expect(tester.getSize(find.byType(InteractiveViewer)).width, 720);
    expect(contentSize.width, 720);
    expect(
      controller.value.storage,
      orderedEquals(Matrix4.identity().storage),
    );
    expect(viewer.panEnabled, isTrue);
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
