import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dummy hymn audio asset is available and non-empty', () async {
    final data = await rootBundle.load(
      'assets/${GlobalAudioService.dummyAudioAsset}',
    );

    expect(data.lengthInBytes, greaterThan(44));
  });
}
