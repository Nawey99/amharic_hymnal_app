import 'package:flutter_test/flutter_test.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/data/mappers/hymn_mapper.dart';
// import for reference to domain entity fields if needed later

void main() {
  test('HymnModel toDomain converts model to domain entity', () {
    final model = const HymnModel(
      id: '1',
      number: 5,
      title: 'Test Hymn',
      lyrics: 'la la la',
      category: 'Praise',
      audioUrl: 'https://example.com/audio.mp3',
      sheetMusic: ['sheet1.png'],
      artist: 'Artist',
    );

    final hymn = HymnMapper.toDomain(model);

    expect(hymn.id, '1');
    expect(hymn.number, 5);
    expect(hymn.title, 'Test Hymn');
    expect(hymn.lyrics, 'la la la');
    expect(hymn.category, 'Praise');
    expect(hymn.audioUrl, 'https://example.com/audio.mp3');
    expect(hymn.sheetMusic, ['sheet1.png']);
    expect(hymn.artist, 'Artist');
    expect(hymn.displayTitle, 'Test Hymn');
  });
}