import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Everything the app says in its own voice speaks whichever language the
/// reader chose, so no Amharic may be written straight into the code.
///
/// The hymns are another matter: their words are the book's, not the
/// app's, and they stay as they are written.
///
/// This scans the whole of `lib/` and exempts only the files listed below.
/// It used to check a list of nine shell files instead, which is why the
/// hymn page kept its Amharic through a whole language release: nobody
/// remembered to add it. A new screen now fails here by default.
void main() {
  /// Files whose Amharic is data rather than something the app says.
  ///
  /// Each one is content: the letters the index is divided by, the sounds
  /// a search types, the names of the book's own categories. Translating
  /// any of it would break the app rather than open it up.
  const contentFiles = {
    // The table itself: the one file where Amharic is the point.
    'lib/core/l10n/app_localizations.dart',
    // The Ethiopic alphabet, used to split the index into sections.
    'lib/core/utils/index_section_utils.dart',
    // Amharic letters mapped to the sounds a reader might type.
    'lib/core/services/amharic_phonetic_service.dart',
    // The book's own category names, and the icons chosen for them.
    'lib/core/constants/hymn_categories.dart',
    'lib/core/utils/category_icon_mapper.dart',
    // Theme names and hymnal names, which carry their own English
    // alongside; the tests below are what keep the two in step.
    'lib/core/theme/app_theme_spec.dart',
    'lib/core/models/hymnal_version.dart',
  };

  /// Windows hands back backslashes; the list above is written with the
  /// separator the repository uses.
  String posix(String path) => path.split(Platform.pathSeparator).join('/');

  final shellFiles = [
    for (final entity in Directory('lib').listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        if (!contentFiles.contains(posix(entity.path))) posix(entity.path),
  ];

  /// An Amharic literal that is not the fallback of a lookup.
  final loose = RegExp(
    r"(?<!\?\?\s)(?<!\?\?\n\s{0,30})'[^']*[ሀ-፿][^']*'",
  );

  test('every Amharic word the app says is behind a lookup', () {
    final offenders = <String>[];
    for (final path in shellFiles) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // The fallback may sit on its own line under the `??`.
        final previous = i > 0 ? lines[i - 1] : '';
        // A lookup's fallback may sit several lines under its `??` once
        // the formatter has wrapped a long call, so look back further
        // than the three lines this once allowed.
        final nearby = lines.sublist((i - 6).clamp(0, i), i + 1).join(' ');
        // Either the lookup is written out, or it was captured as `l`
        // first — which is what the code does before an await, so that
        // no error path reaches for a context that has gone.
        final looksUpWords = nearby.contains('AppLocalizations.of(') ||
            RegExp(r'l\?\.\w|\bl\.\w').hasMatch(nearby);
        // Or it is one of the named fallbacks a lookup falls back *to*.
        // The onboarding copy is long enough that keeping it beside the
        // `??` would make the page unreadable, so it is declared apart.
        final isFallback = (nearby.contains('??') && looksUpWords) ||
            nearby.contains('_fallback');
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

  test('both languages name every hymnal', () {
    final source =
        File('lib/core/models/hymnal_version.dart').readAsStringSync();
    final amharic =
        RegExp(r"^\s+label: '", multiLine: true).allMatches(source).length;
    final english = RegExp(r"^\s+englishLabel: '", multiLine: true)
        .allMatches(source)
        .length;
    expect(amharic, 4, reason: 'the app knows four hymnals');
    expect(amharic, english,
        reason: 'a hymnal with no English name would read as Amharic there');
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
