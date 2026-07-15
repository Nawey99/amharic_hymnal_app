import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/media_reference.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

void main() {
  group('MediaReference', () {
    test('accepts explicit backend URLs', () {
      final reference = MediaReference.tryParse(
        'https://media.example.org/hymns/1.mp3?token=temporary',
      );

      expect(reference, isNotNull);
      expect(reference!.isRemote, isTrue);
      expect(reference.uri.host, 'media.example.org');
    });

    test('accepts absolute downloaded-file paths', () {
      final reference = MediaReference.tryParse(
        r'C:\app-data\media_cache\audio\1.mp3',
      );

      expect(reference, isNotNull);
      expect(reference!.isLocalFile, isTrue);
      expect(reference.localPath, contains('media_cache'));
    });

    test('rejects retired bundled and relative media paths', () {
      expect(MediaReference.tryParse('assets/audio/1.mp3'), isNull);
      expect(MediaReference.tryParse('sheet_music/1.webp'), isNull);
      expect(MediaReference.tryParse('1.webp'), isNull);
    });
  });

  group('metadata-backed repositories', () {
    test('audio has no hymn-number fallback', () {
      final repository = AudioRepository();

      expect(repository.getTrackForNumber(1), isNull);
      expect(
        repository.getTrackForHymn(
          const Hymn(
            number: 1,
            title: 'Title',
            audioUrl: 'https://media.example.org/audio/1.mp3',
          ),
        ),
        isNotNull,
      );
    });

    test('sheet music keeps only explicit usable references', () {
      final repository = SheetMusicRepository();
      const hymn = Hymn(
        number: 1,
        sheetMusic: [
          'assets/sheet_music/1.webp',
          'https://media.example.org/sheet/1.webp',
          'https://media.example.org/sheet/1.webp',
        ],
      );

      final references = repository.referencesForHymn(hymn);
      expect(references, hasLength(1));
      expect(references.single.isRemote, isTrue);
      expect(repository.hasMediaForHymn(hymn), isTrue);
    });
  });
}
