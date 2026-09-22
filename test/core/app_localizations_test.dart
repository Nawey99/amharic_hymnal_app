import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

/// Every string in the hand-written table, read from the source so a new
/// entry is checked without editing this test.
class _Entry {
  final String name;
  final Map<String, String> values;
  _Entry(this.name, this.values);
}

List<_Entry> _entries() {
  final source =
      File('lib/core/l10n/app_localizations.dart').readAsStringSync();
  final entry = RegExp(
    r"String get (\w+) => _localizedValue\(\{(.*?)\}\);",
    dotAll: true,
  );
  final value = RegExp(r"'(\w+)':\s*'((?:[^'\\]|\\.)*)'");
  return [
    for (final match in entry.allMatches(source))
      _Entry(match.group(1)!, {
        for (final v in value.allMatches(match.group(2)!))
          v.group(1)!: v.group(2)!,
      }),
  ];
}

/// `{name}`, `$name` and `%s`-style markers a translation must keep.
Set<String> _placeholders(String text) => {
      for (final m in RegExp(r'\{\w+\}|\$\{?\w+\}?|%\w').allMatches(text))
        m.group(0)!,
    };

void main() {
  final entries = _entries();

  test('the table was found and parsed', () {
    // Guards the parsing below: if the file's shape changes, fail loudly
    // instead of checking nothing.
    final getterCount = RegExp(r'String get \w+ =>')
        .allMatches(
            File('lib/core/l10n/app_localizations.dart').readAsStringSync())
        .length;
    expect(entries, isNotEmpty);
    expect(entries, hasLength(getterCount));
  });

  test('every string has non-empty Amharic and English', () {
    final missing = [
      for (final e in entries)
        for (final lang in ['am', 'en'])
          if ((e.values[lang] ?? '').trim().isEmpty) '${e.name}.$lang',
    ];
    expect(missing, isEmpty);
  });

  test('translations keep the same placeholders', () {
    final mismatched = [
      for (final e in entries)
        if (!_placeholders(e.values['am'] ?? '')
            .containsAll(_placeholders(e.values['en'] ?? '')))
          e.name,
    ];
    expect(mismatched, isEmpty);
  });

  test('Amharic strings are written in Ethiopic script', () {
    final ethiopic = RegExp(r'[ሀ-፿]');
    final latinOnly = [
      for (final e in entries)
        if (!ethiopic.hasMatch(e.values['am'] ?? '')) e.name,
    ];
    expect(latinOnly, isEmpty);
  });

  test('getter names are unique', () {
    final names = entries.map((e) => e.name).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  group('runtime lookup', () {
    test('returns the language asked for', () {
      expect(AppLocalizations(const Locale('am')).settingsTitle, 'ቅንብሮች');
      expect(AppLocalizations(const Locale('en')).settingsTitle, 'Settings');
    });

    test('falls back to English for an unsupported language', () {
      expect(AppLocalizations(const Locale('fr')).settingsTitle, 'Settings');
    });

    test('the delegate supports exactly Amharic and English', () async {
      const delegate = AppLocalizations.delegate;

      expect(delegate.isSupported(const Locale('am')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('om')), isFalse);
      expect(
          (await delegate.load(const Locale('am'))).locale.languageCode, 'am');
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        unorderedEquals(['en', 'am']),
      );
    });
  });
}
