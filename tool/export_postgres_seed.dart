// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

class _SdaRow {
  final int index;
  final int number;
  final String title;
  final String? englishTitle;
  final String? lyrics;
  final String editionPrefix;

  const _SdaRow({
    required this.index,
    required this.number,
    required this.title,
    required this.englishTitle,
    required this.lyrics,
    required this.editionPrefix,
  });

  String get normalizedEnglish => _normalize(englishTitle ?? '');
  String get normalizedAmharic => _normalize(title);
}

Future<void> main(List<String> args) async {
  final outputDir = args.isNotEmpty ? args[0] : 'backend/content';

  final sda = _loadResourceArrays('assets/data/database/SDA_Hymnal.json');
  final hagerigna =
      _loadResourceArrays('assets/data/database/HagerignaData.json');

  final outputDirectory = Directory(outputDir)..createSync(recursive: true);

  final sdaBuffer = StringBuffer()
    ..writeln('-- Generated from current Flutter JSON assets.')
    ..writeln('-- SDA Hymnal content database seed.')
    ..writeln('-- Run after backend/content/schema.sql.')
    ..writeln('begin;')
    ..writeln()
    ..writeln(_insertLanguage())
    ..writeln()
    ..writeln(_insertBook(
      slug: 'am-sda-hymnal',
      languageCode: 'am',
      title: 'Amharic SDA Hymnal',
      bookType: 'hymnal',
      sourceNote: 'Imported from assets/data/database/SDA_Hymnal.json',
    ))
    ..writeln(_insertEdition(
      bookSlug: 'am-sda-hymnal',
      slug: 'am-sda-hymnal-new',
      title: 'Amharic SDA Hymnal',
      editionType: 'new',
      sortOrder: 10,
      sourceNote: 'new_title_forbookmark and new_song arrays',
    ))
    ..writeln(_insertEdition(
      bookSlug: 'am-sda-hymnal',
      slug: 'am-sda-hymnal-old',
      title: 'Amharic SDA Hymnal Old Edition',
      editionType: 'old',
      sortOrder: 20,
      sourceNote: 'old_title_forbookmark and old_song arrays',
    ));

  _appendSdaEntries(sdaBuffer, sda);

  sdaBuffer
    ..writeln()
    ..writeln('commit;');

  final sdaOutputFile = File('${outputDirectory.path}/seed_sda_hymnal.sql');
  sdaOutputFile.writeAsStringSync(sdaBuffer.toString());

  final hagerignaBuffer = StringBuffer()
    ..writeln('-- Generated from current Flutter JSON assets.')
    ..writeln('-- Hagerigna content database seed.')
    ..writeln('-- Run after backend/content/schema.sql.')
    ..writeln('begin;')
    ..writeln()
    ..writeln(_insertLanguage())
    ..writeln()
    ..writeln(_insertBook(
      slug: 'am-hagerigna',
      languageCode: 'am',
      title: 'Hagerigna Worship Songs',
      bookType: 'songbook',
      sourceNote: 'Imported from assets/data/database/HagerignaData.json',
    ))
    ..writeln(_insertEdition(
      bookSlug: 'am-hagerigna',
      slug: 'am-hagerigna-primary',
      title: 'Hagerigna Worship Songs',
      editionType: 'primary',
      sortOrder: 30,
      sourceNote: 'song_title_text, song_text, and song_author_text arrays',
    ));

  _appendHagerignaEntries(hagerignaBuffer, hagerigna);

  hagerignaBuffer
    ..writeln()
    ..writeln('commit;');

  final hagerignaOutputFile =
      File('${outputDirectory.path}/seed_hagerigna.sql');
  hagerignaOutputFile.writeAsStringSync(hagerignaBuffer.toString());

  print('Wrote SDA Hymnal seed to ${sdaOutputFile.path}');
  print('Wrote Hagerigna seed to ${hagerignaOutputFile.path}');
}

Map<String, List<String>> _loadResourceArrays(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw ArgumentError('Missing input file: $path');
  }

  final jsonData = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final arrays = jsonData['resources']?['array'] as List<dynamic>? ?? [];

  final result = <String, List<String>>{};
  for (final item in arrays) {
    if (item is! Map<String, dynamic>) {
      continue;
    }
    final name = item['_name']?.toString();
    final values = item['item'] as List<dynamic>?;
    if (name == null || values == null) {
      continue;
    }
    result[name] = values.map((value) => value?.toString() ?? '').toList();
  }

  return result;
}

void _appendSdaEntries(StringBuffer buffer, Map<String, List<String>> data) {
  final newTitles = data['new_title_forbookmark'] ?? const [];
  final oldTitles = data['old_title_forbookmark'] ?? const [];
  final newLyrics = data['new_song'] ?? const [];
  final oldLyrics = data['old_song'] ?? const [];
  final newEnglishTitles = data['new_title_en'] ?? const [];
  final oldEnglishTitles = data['old_title_en'] ?? const [];
  final newRows = <_SdaRow>[];
  final oldRows = <_SdaRow>[];
  final newKeyCounts = <String, int>{};
  final oldKeyCounts = <String, int>{};

  for (var index = 0; index < newTitles.length; index++) {
    final number = index + 1;
    final row = _SdaRow(
      index: index,
      number: number,
      title: _fallbackTitle(newTitles[index], 'SDA Hymn $number'),
      englishTitle: _valueAt(newEnglishTitles, index),
      lyrics: _valueAt(newLyrics, index),
      editionPrefix: 'new',
    );
    newRows.add(row);
    _countSdaMatchKeys(newKeyCounts, row);
  }

  for (var index = 0; index < oldTitles.length; index++) {
    final number = index + 1;
    final row = _SdaRow(
      index: index,
      number: number,
      title: _fallbackTitle(oldTitles[index], 'SDA Old Hymn $number'),
      englishTitle: _valueAt(oldEnglishTitles, index),
      lyrics: _valueAt(oldLyrics, index),
      editionPrefix: 'old',
    );
    oldRows.add(row);
    _countSdaMatchKeys(oldKeyCounts, row);
  }

  final newCanonicalKeys = <int, String>{};
  final oldCanonicalKeys = <int, String>{};
  final newNumbersByKey = <String, int>{};
  final oldNumbersByKey = <String, int>{};

  for (final row in newRows) {
    final canonicalKey = _sdaCanonicalKey(
      row: row,
      ownKeyCounts: newKeyCounts,
      oppositeKeyCounts: oldKeyCounts,
    );
    newCanonicalKeys[row.index] = canonicalKey;
    newNumbersByKey[canonicalKey] = row.number;
  }

  for (final row in oldRows) {
    final canonicalKey = _sdaCanonicalKey(
      row: row,
      ownKeyCounts: oldKeyCounts,
      oppositeKeyCounts: newKeyCounts,
    );
    oldCanonicalKeys[row.index] = canonicalKey;
    oldNumbersByKey[canonicalKey] = row.number;
  }

  buffer.writeln(_clearImportIssues('sda_hymnal_json'));

  for (final row in newRows) {
    final canonicalKey = newCanonicalKeys[row.index]!;
    newNumbersByKey[canonicalKey] = row.number;

    buffer
      ..writeln(_insertWork(
        canonicalKey: canonicalKey,
        defaultTitle: row.title,
        defaultEnglishTitle: row.englishTitle,
        notes: 'Imported from SDA new hymnal row ${row.number}.',
      ))
      ..writeln(_insertEntry(
        editionSlug: 'am-sda-hymnal-new',
        canonicalKey: canonicalKey,
        number: row.number,
        title: row.title,
        englishTitle: row.englishTitle,
        lyrics: row.lyrics ?? '',
        sourceKey: 'sda_new',
        sourceIndex: row.index,
        metadata: {
          'new_hymnal_number': row.number,
          'old_hymnal_number': oldNumbersByKey[canonicalKey],
          'match_status': oldNumbersByKey.containsKey(canonicalKey)
              ? 'matched'
              : 'missing_old',
        },
      ));
  }

  for (final row in oldRows) {
    final canonicalKey = oldCanonicalKeys[row.index]!;

    buffer
      ..writeln(_insertWork(
        canonicalKey: canonicalKey,
        defaultTitle: row.title,
        defaultEnglishTitle: row.englishTitle,
        notes: 'Imported from SDA old hymnal row ${row.number}.',
      ))
      ..writeln(_insertEntry(
        editionSlug: 'am-sda-hymnal-old',
        canonicalKey: canonicalKey,
        number: row.number,
        title: row.title,
        englishTitle: row.englishTitle,
        lyrics: row.lyrics ?? '',
        sourceKey: 'sda_old',
        sourceIndex: row.index,
        metadata: {
          'new_hymnal_number': newNumbersByKey[canonicalKey],
          'old_hymnal_number': row.number,
          'match_status': newNumbersByKey.containsKey(canonicalKey)
              ? 'matched'
              : 'missing_new',
        },
      ));
  }

  _appendSdaImportIssues(
    buffer,
    newNumbersByKey: newNumbersByKey,
    oldNumbersByKey: oldNumbersByKey,
  );
}

void _appendHagerignaEntries(
  StringBuffer buffer,
  Map<String, List<String>> data,
) {
  final titles = data['song_title_text'] ?? const [];
  final lyrics = data['song_text'] ?? const [];
  final artists = data['song_author_text'] ?? const [];

  for (var index = 0; index < titles.length; index++) {
    final number = index + 1;
    final title = _fallbackTitle(titles[index], 'Hagerigna Song $number');
    final canonicalKey = 'am-hagerigna-${number.toString().padLeft(3, '0')}';

    buffer
      ..writeln(_insertWork(
        canonicalKey: canonicalKey,
        defaultTitle: title,
        defaultEnglishTitle: null,
        notes: 'Imported from Hagerigna row $number.',
      ))
      ..writeln(_insertEntry(
        editionSlug: 'am-hagerigna-primary',
        canonicalKey: canonicalKey,
        number: number,
        title: title,
        englishTitle: null,
        lyrics: _valueAt(lyrics, index) ?? '',
        sourceKey: 'hagerigna',
        sourceIndex: index,
        metadata: {
          'artist': _valueAt(artists, index),
        },
      ));
  }
}

String _insertLanguage() {
  return '''
insert into languages (code, native_name, english_name, script_code)
values ('am', 'አማርኛ', 'Amharic', 'Ethi')
on conflict (code) do update set
  native_name = excluded.native_name,
  english_name = excluded.english_name,
  script_code = excluded.script_code,
  updated_at = now();''';
}

String _insertBook({
  required String slug,
  required String languageCode,
  required String title,
  required String bookType,
  required String sourceNote,
}) {
  return '''
insert into books (slug, language_code, title, book_type, source_note)
values (${_sql(slug)}, ${_sql(languageCode)}, ${_sql(title)}, ${_sql(bookType)}, ${_sql(sourceNote)})
on conflict (slug) do update set
  language_code = excluded.language_code,
  title = excluded.title,
  book_type = excluded.book_type,
  source_note = excluded.source_note,
  updated_at = now();''';
}

String _insertEdition({
  required String bookSlug,
  required String slug,
  required String title,
  required String editionType,
  required int sortOrder,
  required String sourceNote,
}) {
  return '''
insert into book_editions (book_id, slug, title, edition_type, sort_order, source_note)
select id, ${_sql(slug)}, ${_sql(title)}, ${_sql(editionType)}, $sortOrder, ${_sql(sourceNote)}
from books
where slug = ${_sql(bookSlug)}
on conflict (slug) do update set
  title = excluded.title,
  edition_type = excluded.edition_type,
  sort_order = excluded.sort_order,
  source_note = excluded.source_note,
  updated_at = now();''';
}

String _insertWork({
  required String canonicalKey,
  required String defaultTitle,
  required String? defaultEnglishTitle,
  required String notes,
}) {
  return '''
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  ${_sql(canonicalKey)},
  'am',
  ${_sql(defaultTitle)},
  ${_sqlNullable(defaultEnglishTitle)},
  ${_sql(_normalize(defaultTitle))},
  ${_sql(notes)}
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();''';
}

String _insertEntry({
  required String editionSlug,
  required String canonicalKey,
  required int number,
  required String title,
  required String? englishTitle,
  required String lyrics,
  required String sourceKey,
  required int sourceIndex,
  Map<String, Object?> metadata = const {},
}) {
  final metadataJson = jsonEncode(metadata);
  return '''
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  $number,
  ${_sql(title)},
  ${_sqlNullable(englishTitle)},
  ${_sql(lyrics.replaceAll(r'\n', '\n'))},
  ${_sql(sourceKey)},
  $sourceIndex,
  ${_sql(metadataJson)}::jsonb
from book_editions be
join works w on w.canonical_key = ${_sql(canonicalKey)}
where be.slug = ${_sql(editionSlug)}
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();''';
}

void _appendSdaImportIssues(
  StringBuffer buffer, {
  required Map<String, int> newNumbersByKey,
  required Map<String, int> oldNumbersByKey,
}) {
  for (final entry in newNumbersByKey.entries) {
    if (oldNumbersByKey.containsKey(entry.key)) {
      continue;
    }
    buffer.writeln(_insertImportIssue(
      sourceName: 'sda_hymnal_json',
      issueKey: 'missing_old:${entry.key}',
      severity: 'warning',
      issueType: 'missing_old_hymnal_entry',
      message:
          'SDA song has a new hymnal number but no matched old hymnal number.',
      metadata: {
        'canonical_key': entry.key,
        'new_hymnal_number': entry.value,
      },
    ));
  }

  for (final entry in oldNumbersByKey.entries) {
    if (newNumbersByKey.containsKey(entry.key)) {
      continue;
    }
    buffer.writeln(_insertImportIssue(
      sourceName: 'sda_hymnal_json',
      issueKey: 'missing_new:${entry.key}',
      severity: 'warning',
      issueType: 'missing_new_hymnal_entry',
      message:
          'SDA song has an old hymnal number but no matched new hymnal number.',
      metadata: {
        'canonical_key': entry.key,
        'old_hymnal_number': entry.value,
      },
    ));
  }
}

String _clearImportIssues(String sourceName) {
  return '''
delete from content_import_issues
where source_name = ${_sql(sourceName)};''';
}

String _insertImportIssue({
  required String sourceName,
  required String issueKey,
  required String severity,
  required String issueType,
  required String message,
  required Map<String, Object?> metadata,
}) {
  final metadataJson = jsonEncode(metadata);
  return '''
insert into content_import_issues (
  source_name,
  issue_key,
  severity,
  issue_type,
  message,
  metadata
)
values (
  ${_sql(sourceName)},
  ${_sql(issueKey)},
  ${_sql(severity)},
  ${_sql(issueType)},
  ${_sql(message)},
  ${_sql(metadataJson)}::jsonb
)
on conflict (source_name, issue_key) do update set
  severity = excluded.severity,
  issue_type = excluded.issue_type,
  message = excluded.message,
  metadata = excluded.metadata,
  resolved_at = null,
  updated_at = now();''';
}

void _countSdaMatchKeys(Map<String, int> counts, _SdaRow row) {
  if (row.normalizedEnglish.isNotEmpty) {
    counts['en:${row.normalizedEnglish}'] =
        (counts['en:${row.normalizedEnglish}'] ?? 0) + 1;
  }
  if (row.normalizedAmharic.isNotEmpty) {
    counts['am:${row.normalizedAmharic}'] =
        (counts['am:${row.normalizedAmharic}'] ?? 0) + 1;
  }
}

String _sdaCanonicalKey({
  required _SdaRow row,
  required Map<String, int> ownKeyCounts,
  required Map<String, int> oppositeKeyCounts,
}) {
  final english = row.normalizedEnglish;
  final amharic = row.normalizedAmharic;
  final englishKey = english.isEmpty ? null : 'en:$english';
  final amharicKey = amharic.isEmpty ? null : 'am:$amharic';

  if (englishKey != null &&
      ownKeyCounts[englishKey] == 1 &&
      oppositeKeyCounts.containsKey(englishKey)) {
    return 'am-sda-en-$english';
  }

  if (amharicKey != null &&
      ownKeyCounts[amharicKey] == 1 &&
      oppositeKeyCounts.containsKey(amharicKey)) {
    return 'am-sda-am-$amharic';
  }

  if (english.isNotEmpty) {
    return 'am-sda-en-$english';
  }

  if (amharic.isNotEmpty) {
    return 'am-sda-am-$amharic';
  }

  return 'am-sda-${row.editionPrefix}-${row.number.toString().padLeft(3, '0')}';
}

String _fallbackTitle(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String? _valueAt(List<String> values, int index) {
  if (index >= values.length) {
    return null;
  }
  final value = values[index].trim();
  return value.isEmpty ? null : value;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u1200-\u137f]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

String _sqlNullable(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'null';
  }
  return _sql(value);
}

String _sql(String value) {
  return "'${value.replaceAll("'", "''")}'";
}
