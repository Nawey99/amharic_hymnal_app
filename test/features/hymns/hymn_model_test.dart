import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';

void main() {
  test('HymnModel JSON roundtrip', () {
    final json = {
      'id': '1',
      'number': 42,
      'title': 'My Hymn',
      'lyrics': 'Some lyrics',
      'category': 'Worship',
      'audio': 'audio_url.mp3',
      'sheet_music': ['sheet1.png', 'sheet2.png'],
    };

    final model = HymnModel.fromJson(json);
    expect(model.id, '1');
    expect(model.number, 42);
    expect(model.title, 'My Hymn');
    expect(model.lyrics, 'Some lyrics');
    expect(model.category, 'Worship');
    expect(model.audioUrl, 'audio_url.mp3');
    expect(model.sheetMusic?.length, 2);

    final encoded = model.toJson();
    final decodedJson = jsonEncode(encoded);
    expect(decodedJson.contains('My Hymn'), true);
  });
}
