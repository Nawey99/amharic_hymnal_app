import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/sheet_music_viewer.dart';
import 'package:flutter/material.dart';
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
  });
}
