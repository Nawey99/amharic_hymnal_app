import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/music_player_widget.dart';

void main() {
  group('AudioTrackerDisplay', () {
    test('follows the hymn that is playing', () {
      final display = AudioTrackerDisplay.of(
        isThisHymnActive: true,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3),
      );

      expect(display.value, 30000);
      expect(display.max, 180000);
      expect(display.elapsed, '00:30');
      expect(display.total, '03:00');
    });

    test('shows nothing for a hymn that is not the one playing', () {
      final display = AudioTrackerDisplay.of(
        isThisHymnActive: false,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3),
      );

      expect(display.value, 0);
      expect(display.elapsed, '00:00');
      expect(display.total, '--:--');
    });

    test('waits for a duration before showing one', () {
      final display = AudioTrackerDisplay.of(
        isThisHymnActive: true,
        position: Duration.zero,
        duration: null,
      );

      expect(display.value, 0);
      expect(display.total, '--:--');
    });
  });
}
