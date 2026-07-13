import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/sheet_music_viewer_page.dart';
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
  });
}
