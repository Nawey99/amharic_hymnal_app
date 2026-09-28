import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The shell — navigation, settings, and the chrome of the four tabs —
/// speaks whichever language the reader chose, so nothing in it may be
/// written straight into a widget.
///
/// The hymns are another matter: their words are the book's, not the
/// app's, and they stay as they are written.
void main() {
  const shellFiles = [
    'lib/features/hymns/presentation/pages/main_navigation_page.dart',
    'lib/features/hymns/presentation/pages/settings_page.dart',
    'lib/features/hymns/presentation/pages/index_page.dart',
    'lib/features/hymns/presentation/pages/categories_page.dart',
    'lib/features/hymns/presentation/pages/favorites_page.dart',
    'lib/features/hymns/presentation/pages/number_search_page.dart',
    'lib/features/hymns/presentation/widgets/appearance_settings.dart',
    'lib/features/hymns/presentation/widgets/language_settings.dart',
    'lib/core/widgets/settings_tiles.dart',
  ];

  /// An Amharic literal that is not the fallback of a lookup.
  final loose = RegExp(
    r"(?<!\?\?\s)(?<!\?\?\n\s{0,30})'[^']*[ሀ-፿][^']*'",
  );

  test('every Amharic word in the shell is behind a lookup', () {
    final offenders = <String>[];
    for (final path in shellFiles) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // The fallback may sit on its own line under the `??`.
        final previous = i > 0 ? lines[i - 1] : '';
        // A lookup's fallback may run over two or three lines.
        final nearby = lines.sublist((i - 3).clamp(0, i), i + 1).join(' ');
        final isFallback = nearby.contains('??') &&
            nearby.contains('AppLocalizations.of(context)');
        // Marked as staying as it is written, with the reason beside it.
        final isVerbatim =
            line.contains('// verbatim') || previous.contains('// verbatim');
        if (isFallback || isVerbatim) continue;
        if (loose.hasMatch(line)) {
          offenders.add('$path:${i + 1}  ${line.trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'these would stay Amharic however the app is set:\n'
          '${offenders.join('\n')}',
    );
  });

  test('both languages name every theme', () {
    final source =
        File('lib/core/theme/app_theme_spec.dart').readAsStringSync();
    final labels =
        RegExp(r"^\s+label: '", multiLine: true).allMatches(source).length;
    final english = RegExp(r"^\s+englishLabel: '", multiLine: true)
        .allMatches(source)
        .length;
    expect(labels, 15, reason: 'the catalogue should have fifteen themes');
    expect(labels, english,
        reason: 'a theme with no English name would read as Amharic there');
  });
}
