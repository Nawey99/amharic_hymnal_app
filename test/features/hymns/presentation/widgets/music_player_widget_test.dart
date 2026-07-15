import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/music_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('player expands and collapses without a layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: MusicPlayerWidget(
                        hymnNumber: 5,
                        hymnTitle: 'ለየሱስ ስም እልል በሉ',
                        englishTitle: 'All Hail the Power of Jesus Name',
                        audioSource: 'https://media.example.org/audio/5.mp3',
                        version: 'sda_new',
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(width: 62, child: ColoredBox(color: Colors.black)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ለየሱስ ስም እልል በሉ'));
    await _pumpTransition(tester);

    await tester.tap(find.text('ለየሱስ ስም እልል በሉ'));
    await _pumpTransition(tester);
  });
}

Future<void> _pumpTransition(WidgetTester tester) async {
  for (var frame = 0; frame < 14; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  }
}
