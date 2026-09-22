import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/database/json_data_source.dart';
import 'package:amharic_hymnal_app/core/database/parsers/hagerigna_parser.dart';
import 'package:amharic_hymnal_app/core/database/parsers/sda_parser.dart';
import 'package:amharic_hymnal_app/core/models/database_config.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

/// The bundled hymns are the only content a first launch without a network
/// has, so they are checked against the real asset files.
Map<String, dynamic> _asset(String name) =>
    jsonDecode(File('assets/data/database/$name').readAsStringSync())
        as Map<String, dynamic>;

List<String> _array(Map<String, dynamic> json, String name) {
  final arrays = (json['resources'] as Map)['array'] as List;
  final array = arrays.cast<Map>().firstWhere((a) => a['_name'] == name);
  return (array['item'] as List).map((e) => e.toString()).toList();
}

void _expectNumbersWithoutGaps(List<Map<String, dynamic>> hymns, int count) {
  expect(hymns.map((h) => h['number']), [for (var n = 1; n <= count; n++) n]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sda = _asset('SDA_Hymnal.json');
  final hagerigna = _asset('HagerignaData.json');

  group('SdaParser on the bundled SDA file', () {
    test('2004 book: 325 hymns numbered 1..325, each with title and lyrics',
        () {
      final hymns = SdaParser.parse(sda, version: HymnalVersions.sdaNew);

      expect(hymns, hasLength(325));
      _expectNumbersWithoutGaps(hymns, 325);
      for (final hymn in hymns) {
        expect((hymn['title'] as String).trim(), isNotEmpty,
            reason: 'title of #${hymn['number']}');
        expect((hymn['lyrics'] as String).trim(), isNotEmpty,
            reason: 'lyrics of #${hymn['number']}');
      }
    });

    test('1975 book: 294 hymns numbered 1..294, each with title and lyrics',
        () {
      final hymns = SdaParser.parse(sda, version: HymnalVersions.sdaOld);

      expect(hymns, hasLength(294));
      _expectNumbersWithoutGaps(hymns, 294);
      for (final hymn in hymns) {
        expect((hymn['title'] as String).trim(), isNotEmpty);
        expect((hymn['lyrics'] as String).trim(), isNotEmpty);
      }
    });

    test('each edition takes its own title and lyrics', () {
      final newTitles = _array(sda, 'new_title_forbookmark');
      final oldTitles = _array(sda, 'old_title_forbookmark');
      final newLyrics = _array(sda, 'new_song');
      final oldLyrics = _array(sda, 'old_song');

      final hymns2004 = SdaParser.parse(sda, version: HymnalVersions.sdaNew);
      final hymns1975 = SdaParser.parse(sda, version: HymnalVersions.sdaOld);

      for (final i in [0, 99, 293]) {
        expect(hymns2004[i]['title'], newTitles[i]);
        expect(hymns2004[i]['lyrics'], newLyrics[i]);
        expect(hymns1975[i]['title'], oldTitles[i]);
        expect(hymns1975[i]['lyrics'], oldLyrics[i]);
      }
      expect(hymns2004.last['title'], newTitles[324]);
    });

    test('IDs are unique within an edition and name it', () {
      for (final version in [HymnalVersions.sdaNew, HymnalVersions.sdaOld]) {
        final ids = SdaParser.parse(sda, version: version)
            .map((h) => h['id'] as String)
            .toList();
        expect(ids.toSet(), hasLength(ids.length));
        expect(ids.every((id) => id.startsWith('$version-')), isTrue);
      }
    });

    test('an empty file yields no hymns rather than throwing', () {
      expect(SdaParser.parse({}), isEmpty);
      expect(
          SdaParser.parse({
            'resources': {'array': []}
          }),
          isEmpty);
    });
  });

  group('HagerignaParser on the bundled file', () {
    test('121 songs numbered 1..121 with title, lyrics and artist', () {
      final songs = HagerignaParser.parse(hagerigna);

      expect(songs, hasLength(121));
      _expectNumbersWithoutGaps(songs, 121);
      final titles = _array(hagerigna, 'song_title_text');
      for (var i = 0; i < songs.length; i++) {
        expect(songs[i]['title'], titles[i]);
        expect((songs[i]['lyrics'] as String).trim(), isNotEmpty);
        expect((songs[i]['artist'] as String).trim(), isNotEmpty);
        expect(songs[i]['id'], 'hagerigna-$i');
      }
    });

    test('an empty file yields no songs', () {
      expect(HagerignaParser.parse({}), isEmpty);
    });
  });

  group('DatabaseRegistry', () {
    test('bundles the 2004, 1975 and Hagerigna books, and the legacy alias',
        () {
      expect(
          DatabaseRegistry.getDatabase('am', HymnalVersions.sdaNew), isNotNull);
      expect(
          DatabaseRegistry.getDatabase('am', HymnalVersions.sdaOld), isNotNull);
      expect(DatabaseRegistry.getDatabase('am', HymnalVersions.hagerigna),
          isNotNull);
      expect(DatabaseRegistry.getDatabase('am', 'hymnal')!.filePath,
          'assets/data/database/SDA_Hymnal.json');
    });

    test('has no bundled copy of the 1961 book or unknown languages', () {
      expect(
          DatabaseRegistry.getDatabase('am', HymnalVersions.sda1961), isNull);
      expect(DatabaseRegistry.getDatabase('en', HymnalVersions.sdaNew), isNull);
    });

    test('every registered file exists in the app assets', () {
      for (final version in [
        HymnalVersions.sdaNew,
        HymnalVersions.sdaOld,
        HymnalVersions.hagerigna,
      ]) {
        final path = DatabaseRegistry.getDatabase('am', version)!.filePath;
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });

  group('JsonDataSource', () {
    test('loads each bundled book through the asset bundle', () async {
      final source = JsonDataSource.instance;

      expect(
          await source.getHymns('am', HymnalVersions.sdaNew), hasLength(325));
      expect(
          await source.getHymns('am', HymnalVersions.sdaOld), hasLength(294));
      expect(await source.getHymns('am', HymnalVersions.hagerigna),
          hasLength(121));
    });

    test('the legacy "hymnal" ID reads the 2004 book', () async {
      final hymns = await JsonDataSource.instance.getHymns('am', 'hymnal');
      expect(hymns, hasLength(325));
      expect(JsonDataSource.instance.isCached('am', HymnalVersions.sdaNew),
          isTrue);
    });

    test('a book with no bundled copy returns nothing', () async {
      expect(
        await JsonDataSource.instance.getHymns('am', HymnalVersions.sda1961),
        isEmpty,
      );
    });

    test('loading two books at once returns each its own hymns', () async {
      JsonDataSource.instance.clearCache();

      final results = await Future.wait([
        JsonDataSource.instance.getHymns('am', HymnalVersions.sdaNew),
        JsonDataSource.instance.getHymns('am', HymnalVersions.hagerigna),
      ]);

      expect(results[0], hasLength(325));
      expect(results[1], hasLength(121));
    });
  });
}
