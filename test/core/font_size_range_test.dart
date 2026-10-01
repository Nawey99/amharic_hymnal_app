import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/utils/constants.dart';

/// The sizes a reader may choose from.
///
/// The bound used to be written out as `12.0, 30.0` in nineteen places
/// across four files, plus a `divisions: 18` that was silently `30 - 12`.
/// Raising the maximum meant finding all of them, and any one missed would
/// have clamped a reader's choice back down without a word.
void main() {
  test('the range is the one the app offers', () {
    expect(AppConstants.minFontSize, 12.0);
    expect(AppConstants.maxFontSize, 40.0);
    expect(AppConstants.minFontSize, lessThan(AppConstants.maxFontSize));
  });

  /// One stop per whole point, so two readers on "17" have the same text.
  test('the slider has a division for every whole point', () {
    expect(
      AppConstants.fontSizeDivisions,
      (AppConstants.maxFontSize - AppConstants.minFontSize).round(),
    );
    expect(AppConstants.fontSizeDivisions, 28);
  });

  test('nothing writes the bounds out by hand', () {
    // Only the reader's own bounds. Plenty of other clamps in the app are
    // pairs of numbers -- blur sigma, a keyboard inset, a download ratio --
    // and none of them has anything to do with this.
    String pattern(double min, double max) =>
        '${min.toStringAsFixed(1)},\\s*${max.toStringAsFixed(1)}';
    final current = RegExp(
      pattern(AppConstants.minFontSize, AppConstants.maxFontSize),
    );
    // The pair as it was before the maximum was raised: a copy left behind
    // anywhere would quietly hold that reader at the old limit.
    final superseded = RegExp(pattern(12, 30));

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      // Where the numbers are allowed to be written down.
      if (path == 'lib/core/utils/constants.dart') continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (current.hasMatch(line) || superseded.hasMatch(line)) {
          offenders.add('$path:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'use AppConstants.minFontSize / maxFontSize so raising the '
          'maximum reaches everywhere at once. Found at: '
          '${offenders.join(', ')}',
    );
  });
}
