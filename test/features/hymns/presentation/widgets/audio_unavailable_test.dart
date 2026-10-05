import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/audio_section_widget.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_media_controls.dart';

const _noAudio = 'ድምፅ አልተገኘም';
const _needsInternet = 'ድምፅ መኖሩን ለማወቅ ከኢንተርኔት ጋር ይገናኙ';

/// A hymn with nothing to play used to show a card that said only "No audio
/// found", with no name on it. The name is now always there, and the line
/// under it says why there is no player.
void main() {
  final title = find.byKey(const ValueKey('audio-unavailable-title'));
  final status = find.byKey(const ValueKey('audio-unavailable-status'));

  Future<void> pumpControls(
    WidgetTester tester,
    Hymn hymn, {
    bool condensed = false,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HymnMediaControls(
          hymn: hymn,
          version: 'sda_new',
          condensed: condensed,
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('a hymn the server says has no audio shows its name, then why',
      (tester) async {
    await pumpControls(
      tester,
      const Hymn(id: 'am-sda-2004-0122', number: 122, title: 'ሰባኪው አለ ከንቱ'),
    );

    expect(tester.widget<Text>(title).data, 'ሰባኪው አለ ከንቱ');
    expect(tester.widget<Text>(status).data, _noAudio);
    // The reason sits under the name.
    expect(
      tester.getTopLeft(status).dy,
      greaterThan(tester.getTopLeft(title).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a hymn read from the bundled copy does not claim there is no audio',
      (tester) async {
    await pumpControls(
      tester,
      const Hymn(
        id: 'am-sda-2004-0122',
        number: 122,
        title: 'ሰባኪው አለ ከንቱ',
        isBundled: true,
      ),
    );

    expect(tester.widget<Text>(title).data, 'ሰባኪው አለ ከንቱ');
    expect(tester.widget<Text>(status).data, _needsInternet);
    expect(find.text(_noAudio), findsNothing);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('a hymn with no title still gets a name', (tester) async {
    await pumpControls(
      tester,
      const Hymn(id: 'am-sda-2004-0009', number: 9, title: ''),
    );

    expect(tester.widget<Text>(title).data, isNotEmpty);
    expect(tester.widget<Text>(status).data, _noAudio);
  });

  for (final condensed in const [false, true]) {
    testWidgets(
        'a long name fits a narrow phone '
        '${condensed ? 'in the condensed card' : 'in the full card'}',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: AudioSectionWidget(
              hymnNumber: 7,
              hymnTitle: 'እጅግ በጣም ረጅም የሆነ የመዝሙር ርዕስ ለጠባብ ስልክ ማያ ገጽ',
              version: 'sda_new',
              condensed: condensed,
              audioIsKnown: false,
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(title, findsOneWidget);
      expect(status, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
