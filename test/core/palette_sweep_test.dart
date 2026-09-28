import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against a page slipping back to colours of its own.
///
/// A page that paints its own backdrop, or its own white hairline, looks
/// right in the dark green it was written for and wrong in every other
/// palette: that is how the categories page came to sit under a black
/// wash while the rest of the app had turned light.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  String relative(File file) => file.path.replaceAll(r'\', '/');

  test('only the shared backdrop reaches for the background photograph', () {
    final offenders = <String>[];
    for (final file in dartFiles) {
      final path = relative(file);
      if (path.endsWith('core/widgets/app_background.dart')) continue;
      if (file.readAsStringSync().contains('background.jpg')) {
        offenders.add(path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'these paint their own backdrop instead of calling '
          'appBackgroundDecoration(context)',
    );
  });

  test('overlays are drawn with the palette, not with white', () {
    final offenders = <String>[];
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('Colors.white.withValues')) {
          offenders.add('${relative(file)}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'a white veil disappears on a light palette; '
          'use context.appColors.veil',
    );
  });
}
