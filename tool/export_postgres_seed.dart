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
  String get normalizedLyrics => _normalizeLyrics(lyrics ?? '');
}

class _SheetMusicAsset {
  final File file;
  final List<int> hymnNumbers;
  final String pageLabel;
  final int sortOrder;

  const _SheetMusicAsset({
    required this.file,
    required this.hymnNumbers,
    required this.pageLabel,
    required this.sortOrder,
  });

  String get assetPath => 'assets/sheet_music/${file.uri.pathSegments.last}';
  String get extension =>
      file.uri.pathSegments.last.split('.').last.toLowerCase();
  String get storageKey {
    final numbers = hymnNumbers.join('-');
    return 'sda-hymnal/sheet-music/$numbers/$pageLabel.$extension';
  }
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
  _appendSdaSheetMusic(sdaBuffer);

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

void _appendSdaSheetMusic(StringBuffer buffer) {
  final assets = _discoverSdaSheetMusicAssets();

  buffer
    ..writeln()
    ..writeln(_clearSdaSheetMusicAssets());

  for (final asset in assets) {
    buffer.writeln(_insertMediaAsset(asset));
    for (final hymnNumber in asset.hymnNumbers) {
      buffer.writeln(_insertSdaSheetMusicLink(
        asset: asset,
        hymnNumber: hymnNumber,
      ));
    }
  }

  final invalidFiles = _discoverInvalidSheetMusicFiles();
  for (final file in invalidFiles) {
    buffer.writeln(_insertImportIssue(
      sourceName: 'sda_sheet_music_assets',
      issueKey: 'unparsed_file:${file.uri.pathSegments.last}',
      severity: 'warning',
      issueType: 'unparsed_sheet_music_filename',
      message:
          'Sheet music file name does not match the supported hymn number naming pattern.',
      metadata: {
        'asset_path': 'assets/sheet_music/${file.uri.pathSegments.last}',
      },
    ));
  }
}

List<_SheetMusicAsset> _discoverSdaSheetMusicAssets() {
  final directory = Directory('assets/sheet_music');
  if (!directory.existsSync()) {
    return const [];
  }

  final assets = <_SheetMusicAsset>[];
  for (final file in directory.listSync().whereType<File>()) {
    final parsed = _parseSheetMusicFile(file);
    if (parsed != null) {
      assets.add(parsed);
    }
  }

  assets.sort((a, b) {
    final numberCompare = a.hymnNumbers.first.compareTo(b.hymnNumbers.first);
    if (numberCompare != 0) {
      return numberCompare;
    }
    final sortCompare = a.sortOrder.compareTo(b.sortOrder);
    if (sortCompare != 0) {
      return sortCompare;
    }
    return a.file.uri.pathSegments.last.compareTo(b.file.uri.pathSegments.last);
  });

  return assets;
}

List<File> _discoverInvalidSheetMusicFiles() {
  final directory = Directory('assets/sheet_music');
  if (!directory.existsSync()) {
    return const [];
  }

  return directory
      .listSync()
      .whereType<File>()
      .where((file) => _parseSheetMusicFile(file) == null)
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

_SheetMusicAsset? _parseSheetMusicFile(File file) {
  final fileName = file.uri.pathSegments.last;
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex <= 0) {
    return null;
  }

  final extension = fileName.substring(dotIndex + 1).toLowerCase();
  if (!const {'webp', 'jpg', 'jpeg', 'png'}.contains(extension)) {
    return null;
  }

  final baseName = fileName.substring(0, dotIndex);
  final match =
      RegExp(r'^(\d+(?:,\d+)*)(?:\.)?(?:_([lLrR]))?$').firstMatch(baseName);
  if (match == null) {
    return null;
  }

  final numbers = match
      .group(1)!
      .split(',')
      .map(int.parse)
      .where((number) => number > 0)
      .toList(growable: false);
  if (numbers.isEmpty) {
    return null;
  }

  final side = match.group(2)?.toUpperCase();
  final pageLabel = switch (side) {
    'L' => 'left',
    'R' => 'right',
    _ => 'single',
  };
  final sortOrder = switch (pageLabel) {
    'single' => 0,
    'left' => 10,
    'right' => 20,
    _ => 99,
  };

  return _SheetMusicAsset(
    file: file,
    hymnNumbers: numbers,
    pageLabel: pageLabel,
    sortOrder: sortOrder,
  );
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

String _clearSdaSheetMusicAssets() {
  return '''
delete from media_links
where media_asset_id in (
  select id
  from media_assets
  where storage_provider = 'app_asset'
    and storage_key like 'sda-hymnal/sheet-music/%'
);

delete from media_assets
where storage_provider = 'app_asset'
  and storage_key like 'sda-hymnal/sheet-music/%';

delete from content_import_issues
where source_name = 'sda_sheet_music_assets';''';
}

String _insertMediaAsset(_SheetMusicAsset asset) {
  final metadataJson = jsonEncode({
    'asset_path': asset.assetPath,
    'original_file_name': asset.file.uri.pathSegments.last,
    'hymnal': 'sda',
    'hymnal_numbers': asset.hymnNumbers,
    'page_label': asset.pageLabel,
  });

  return '''
insert into media_assets (
  media_type,
  storage_provider,
  storage_key,
  public_url,
  mime_type,
  file_size_bytes,
  page_label,
  metadata
)
values (
  'sheet_music',
  'app_asset',
  ${_sql(asset.storageKey)},
  null,
  ${_sql(_mimeTypeForExtension(asset.extension))},
  ${asset.file.lengthSync()},
  ${_sql(asset.pageLabel)},
  ${_sql(metadataJson)}::jsonb
)
on conflict (storage_provider, storage_key) do update set
  media_type = excluded.media_type,
  public_url = excluded.public_url,
  mime_type = excluded.mime_type,
  file_size_bytes = excluded.file_size_bytes,
  page_label = excluded.page_label,
  metadata = excluded.metadata,
  updated_at = now();''';
}

String _insertSdaSheetMusicLink({
  required _SheetMusicAsset asset,
  required int hymnNumber,
}) {
  return '''
insert into media_links (
  media_asset_id,
  work_id,
  relation_type,
  sort_order,
  notes
)
select
  ma.id,
  e.work_id,
  'primary_sheet_music',
  ${asset.sortOrder},
  ${_sql('Imported from ${asset.assetPath} for SDA new hymnal #$hymnNumber.')}
from media_assets ma
join book_entries e on e.entry_number = $hymnNumber
join book_editions be on be.id = e.edition_id
where ma.storage_provider = 'app_asset'
  and ma.storage_key = ${_sql(asset.storageKey)}
  and be.slug = 'am-sda-hymnal-new';''';
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
  if (row.normalizedEnglish.isNotEmpty && row.normalizedLyrics.isNotEmpty) {
    final key = 'en_lyrics:${row.normalizedEnglish}:${row.normalizedLyrics}';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  if (row.normalizedAmharic.isNotEmpty && row.normalizedLyrics.isNotEmpty) {
    final key = 'am_lyrics:${row.normalizedAmharic}:${row.normalizedLyrics}';
    counts[key] = (counts[key] ?? 0) + 1;
  }
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
  final lyrics = row.normalizedLyrics;
  final englishLyricsKey =
      english.isEmpty || lyrics.isEmpty ? null : 'en_lyrics:$english:$lyrics';
  final amharicLyricsKey =
      amharic.isEmpty || lyrics.isEmpty ? null : 'am_lyrics:$amharic:$lyrics';
  final englishKey = english.isEmpty ? null : 'en:$english';
  final amharicKey = amharic.isEmpty ? null : 'am:$amharic';

  if (englishLyricsKey != null &&
      ownKeyCounts[englishLyricsKey] == 1 &&
      oppositeKeyCounts[englishLyricsKey] == 1) {
    return 'am-sda-en-lyrics-${_shortKey('$english-$lyrics')}';
  }

  if (amharicLyricsKey != null &&
      ownKeyCounts[amharicLyricsKey] == 1 &&
      oppositeKeyCounts[amharicLyricsKey] == 1) {
    return 'am-sda-am-lyrics-${_shortKey('$amharic-$lyrics')}';
  }

  if (englishKey != null &&
      ownKeyCounts[englishKey] == 1 &&
      oppositeKeyCounts[englishKey] == 1) {
    return 'am-sda-en-$english';
  }

  if (amharicKey != null &&
      ownKeyCounts[amharicKey] == 1 &&
      oppositeKeyCounts[amharicKey] == 1) {
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

String _normalizeLyrics(String value) {
  return value
      .replaceAll(r'\n', '\n')
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[።፣፤፥፦፧፨.,;:!?()\\[\\]{}"' '`~_-]+'), '')
      .trim();
}

String _shortKey(String value) {
  final normalized = _normalize(value);
  if (normalized.length <= 96) {
    return normalized;
  }
  return normalized.substring(0, 96).replaceAll(RegExp(r'-+$'), '');
}

String _mimeTypeForExtension(String extension) {
  return switch (extension.toLowerCase()) {
    'webp' => 'image/webp',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    _ => 'application/octet-stream',
  };
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
