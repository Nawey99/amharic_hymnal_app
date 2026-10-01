import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Text in this app carries no drop shadow.
///
/// Three of them once did, to help the words stand off the background
/// photograph. They were redundant -- the hymn words and the list titles sit
/// on a translucent panel whose contrast is already asserted in
/// palette_contrast_test.dart, and the Index's section letter is measured
/// against the scrimmed photograph in the same file. What the shadows did
/// contribute was a blur: Ethiopic glyphs carry fine strokes, and a 2px
/// smear of black under them reads as soft focus at the sizes a reader
/// actually chooses.
///
/// This is a source scan rather than a widget test because a shadow can be
/// added to any one of hundreds of TextStyles, and the point is that none of
/// them has one.
void main() {
  test('no text in lib carries a shadow', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // `shadows:` is TextStyle's; `boxShadow:` is a container's and is
        // left alone, so cards and bars keep their elevation.
        if (RegExp(r'(^|[^x])\bshadows\s*:').hasMatch(lines[i])) {
          offenders.add('${entity.path.replaceAll(r'\', '/')}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'text shadows blur Ethiopic script; the contrast that makes '
          'the words readable is asserted in palette_contrast_test.dart '
          'instead. Found at: ${offenders.join(', ')}',
    );
  });
}
