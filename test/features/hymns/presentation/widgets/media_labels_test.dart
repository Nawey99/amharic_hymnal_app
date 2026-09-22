import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/secure_screen_service.dart';
import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/sheet_music_viewer_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/music_player_widget.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/other_editions_line.dart';

Widget _sheetImage(
  BuildContext context,
  String filePath,
  int cacheWidth,
  int cacheHeight,
) {
  return const ColoredBox(color: Colors.white);
}

Future<void> _allowScreenProtection() async {
  await SecureScreenService.resetForTesting();
  SecureScreenService.platformInvokerForTesting = (method) async {
    if (method == 'isCaptured') return false;
    return null;
  };
}

Future<void> _tearDownPage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await SecureScreenService.resetForTesting();
}

HymnSheetPage _page({String? borrowedFrom}) => HymnSheetPage(
      file: const HymnMediaFile(url: 'https://api.example.test/p/1'),
      pageNumber: 1,
      borrowedFromVersionCode: borrowedFrom,
    );

void main() {
  testWidgets('borrowed sheet music names the book and number it came from',
      (tester) async {
    await _allowScreenProtection();
    final editions = SongEditionsService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode({
              'success': true,
              'data': {
                'otherEditions': [
                  {
                    'songId': 'am-sda-2004-0132',
                    'number': 132,
                    'versionCode': 'am-sda-2004',
                  },
                ],
              },
            })),
            200,
          )),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SheetMusicViewerPage(
          hymn: Hymn(
            id: 'am-sda-1975-0130',
            number: 130,
            title: 'ወዳንተ የሱስ ሆይ',
            sheetPages: [_page(borrowedFrom: 'am-sda-2004')],
          ),
          sheetMusicFiles: const ['132R.webp'],
          imageBuilder: _sheetImage,
          editionsService: editions,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ይህ ኖታ ከ2004 ውዳሴ (ቁ. 132) የተወሰደ ነው።'), findsOneWidget);
    await _tearDownPage(tester);
  });

  testWidgets('the caption still names the book when offline', (tester) async {
    await _allowScreenProtection();
    final editions = SongEditionsService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SheetMusicViewerPage(
          hymn: Hymn(
            id: 'am-sda-1975-0130',
            number: 130,
            sheetPages: [_page(borrowedFrom: 'am-sda-1961')],
          ),
          sheetMusicFiles: const ['165.webp'],
          imageBuilder: _sheetImage,
          editionsService: editions,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ይህ ኖታ ከ1961 ውዳሴ የተወሰደ ነው።'), findsOneWidget);
    await _tearDownPage(tester);
  });

  testWidgets("an edition's own sheet music has no caption", (tester) async {
    await _allowScreenProtection();

    await tester.pumpWidget(
      MaterialApp(
        home: SheetMusicViewerPage(
          hymn: Hymn(
            id: 'am-sda-2004-0132',
            number: 132,
            sheetPages: [_page()],
          ),
          sheetMusicFiles: const ['132R.webp'],
          imageBuilder: _sheetImage,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('borrowed-sheet-caption')), findsNothing);
    await _tearDownPage(tester);
  });

  testWidgets('synthesized audio is labelled and credited', (tester) async {
    Widget player(HymnAudioInfo? info) => MaterialApp(
          home: Scaffold(
            body: MusicPlayerWidget(
              hymnNumber: 7,
              hymnTitle: 'Title',
              audioSource: 'https://api.example.test/a/7',
              audioInfo: info,
              version: 'sda_new',
            ),
          ),
        );

    await tester.pumpWidget(player(null));
    expect(find.text('መሣሪያ ብቻ'), findsNothing);

    await tester.pumpWidget(player(const HymnAudioInfo(
      file: HymnMediaFile(url: 'https://api.example.test/a/7'),
      isSynthesized: true,
      attribution: 'Rendered from MIDI.',
    )));
    expect(find.text('መሣሪያ ብቻ'), findsOneWidget);

    await tester.tap(find.text('Title'));
    for (var frame = 0; frame < 14; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Rendered from MIDI.'), findsOneWidget);
  });

  testWidgets('the hymn page lists the same hymn in other books',
      (tester) async {
    final service = SongEditionsService(
      baseUrl: 'https://api.example.test/api/v1',
      client: MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode({
              'success': true,
              'data': {
                'otherEditions': [
                  {
                    'songId': 'am-sda-1961-0165',
                    'number': 165,
                    'versionCode': 'am-sda-1961',
                  },
                  {
                    'songId': 'am-sda-2004-0132',
                    'number': 132,
                    'versionCode': 'am-sda-2004',
                  },
                ],
              },
            })),
            200,
          )),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OtherEditionsLine(
          hymn: const Hymn(id: 'am-sda-1975-0130', number: 130),
          service: service,
        ),
      ),
    ));
    await tester.pump();

    expect(
      find.text('በሌሎች መጻሕፍት፦ 1961 ውዳሴ ቁ. 165 · 2004 ውዳሴ ቁ. 132'),
      findsOneWidget,
    );
  });

  testWidgets('bundled hymns show no other-books line', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: OtherEditionsLine(hymn: Hymn(id: 'sda_old-sda-129', number: 130)),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey('other-editions-line')), findsNothing);
  });

  SongEditionsService serviceAnswering(Map<String, Object> data) =>
      SongEditionsService(
        baseUrl: 'https://api.example.test/api/v1',
        client: MockClient((_) async => http.Response.bytes(
              utf8.encode(jsonEncode({'success': true, 'data': data})),
              200,
            )),
      );

  Future<void> pumpLine(
      WidgetTester tester, SongEditionsService service) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OtherEditionsLine(
          hymn: const Hymn(id: 'am-sda-1975-0130', number: 130),
          service: service,
        ),
      ),
    ));
    await tester.pump();
  }

  const same = {
    'songId': 'am-sda-2004-0132',
    'number': 132,
    'versionCode': 'am-sda-2004',
  };
  const similar = {
    'songId': 'am-sda-2004-0112',
    'number': 112,
    'versionCode': 'am-sda-2004',
  };

  testWidgets('similar hymns get their own line under the same hymn',
      (tester) async {
    await pumpLine(
      tester,
      serviceAnswering({
        'otherEditions': [same],
        'similarEditions': [similar],
      }),
    );

    expect(find.text('በሌሎች መጻሕፍት፦ 2004 ውዳሴ ቁ. 132'), findsOneWidget);
    expect(find.text('ተመሳሳይ መዝሙሮች፦ 2004 ውዳሴ ቁ. 112'), findsOneWidget);
  });

  testWidgets('a hymn with only similar hymns shows only that line',
      (tester) async {
    await pumpLine(
      tester,
      serviceAnswering({
        'otherEditions': <Object>[],
        'similarEditions': [similar],
      }),
    );

    expect(find.byKey(const ValueKey('other-editions-line')), findsNothing);
    expect(find.byKey(const ValueKey('similar-editions-line')), findsOneWidget);
  });

  testWidgets('no similar hymns, or no field at all, shows no similar line',
      (tester) async {
    await pumpLine(
        tester,
        serviceAnswering({
          'otherEditions': [same]
        }));

    expect(find.byKey(const ValueKey('other-editions-line')), findsOneWidget);
    expect(find.byKey(const ValueKey('similar-editions-line')), findsNothing);
  });
}
