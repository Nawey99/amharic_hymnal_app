// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HymnsTable extends Hymns with TableInfo<$HymnsTable, Hymn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HymnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hymnIdMeta = const VerificationMeta('hymnId');
  @override
  late final GeneratedColumn<String> hymnId = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _languageCodeMeta =
      const VerificationMeta('languageCode');
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
      'language_code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 2, maxTextLength: 10),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
      'version', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lyricsMeta = const VerificationMeta('lyrics');
  @override
  late final GeneratedColumn<String> lyrics = GeneratedColumn<String>(
      'lyrics', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioUrlMeta =
      const VerificationMeta('audioUrl');
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
      'audio_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sheetMusicMeta =
      const VerificationMeta('sheetMusic');
  @override
  late final GeneratedColumn<String> sheetMusic = GeneratedColumn<String>(
      'sheet_music', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _songMeta = const VerificationMeta('song');
  @override
  late final GeneratedColumn<String> song = GeneratedColumn<String>(
      'song', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newHymnalTitleMeta =
      const VerificationMeta('newHymnalTitle');
  @override
  late final GeneratedColumn<String> newHymnalTitle = GeneratedColumn<String>(
      'new_hymnal_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _oldHymnalTitleMeta =
      const VerificationMeta('oldHymnalTitle');
  @override
  late final GeneratedColumn<String> oldHymnalTitle = GeneratedColumn<String>(
      'old_hymnal_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newHymnalLyricsMeta =
      const VerificationMeta('newHymnalLyrics');
  @override
  late final GeneratedColumn<String> newHymnalLyrics = GeneratedColumn<String>(
      'new_hymnal_lyrics', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _englishTitleOldMeta =
      const VerificationMeta('englishTitleOld');
  @override
  late final GeneratedColumn<String> englishTitleOld = GeneratedColumn<String>(
      'english_title_old', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _oldHymnalLyricsMeta =
      const VerificationMeta('oldHymnalLyrics');
  @override
  late final GeneratedColumn<String> oldHymnalLyrics = GeneratedColumn<String>(
      'old_hymnal_lyrics', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newHymnalNumberMeta =
      const VerificationMeta('newHymnalNumber');
  @override
  late final GeneratedColumn<int> newHymnalNumber = GeneratedColumn<int>(
      'new_hymnal_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _oldHymnalNumberMeta =
      const VerificationMeta('oldHymnalNumber');
  @override
  late final GeneratedColumn<int> oldHymnalNumber = GeneratedColumn<int>(
      'old_hymnal_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        hymnId,
        languageCode,
        version,
        number,
        title,
        lyrics,
        category,
        audioUrl,
        sheetMusic,
        artist,
        song,
        newHymnalTitle,
        oldHymnalTitle,
        newHymnalLyrics,
        englishTitleOld,
        oldHymnalLyrics,
        newHymnalNumber,
        oldHymnalNumber,
        createdAt,
        updatedAt,
        isFavorite
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hymns';
  @override
  VerificationContext validateIntegrity(Insertable<Hymn> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(
          _hymnIdMeta, hymnId.isAcceptableOrUnknown(data['id']!, _hymnIdMeta));
    } else if (isInserting) {
      context.missing(_hymnIdMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
          _languageCodeMeta,
          languageCode.isAcceptableOrUnknown(
              data['language_code']!, _languageCodeMeta));
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('lyrics')) {
      context.handle(_lyricsMeta,
          lyrics.isAcceptableOrUnknown(data['lyrics']!, _lyricsMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('audio_url')) {
      context.handle(_audioUrlMeta,
          audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta));
    }
    if (data.containsKey('sheet_music')) {
      context.handle(
          _sheetMusicMeta,
          sheetMusic.isAcceptableOrUnknown(
              data['sheet_music']!, _sheetMusicMeta));
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('song')) {
      context.handle(
          _songMeta, song.isAcceptableOrUnknown(data['song']!, _songMeta));
    }
    if (data.containsKey('new_hymnal_title')) {
      context.handle(
          _newHymnalTitleMeta,
          newHymnalTitle.isAcceptableOrUnknown(
              data['new_hymnal_title']!, _newHymnalTitleMeta));
    }
    if (data.containsKey('old_hymnal_title')) {
      context.handle(
          _oldHymnalTitleMeta,
          oldHymnalTitle.isAcceptableOrUnknown(
              data['old_hymnal_title']!, _oldHymnalTitleMeta));
    }
    if (data.containsKey('new_hymnal_lyrics')) {
      context.handle(
          _newHymnalLyricsMeta,
          newHymnalLyrics.isAcceptableOrUnknown(
              data['new_hymnal_lyrics']!, _newHymnalLyricsMeta));
    }
    if (data.containsKey('english_title_old')) {
      context.handle(
          _englishTitleOldMeta,
          englishTitleOld.isAcceptableOrUnknown(
              data['english_title_old']!, _englishTitleOldMeta));
    }
    if (data.containsKey('old_hymnal_lyrics')) {
      context.handle(
          _oldHymnalLyricsMeta,
          oldHymnalLyrics.isAcceptableOrUnknown(
              data['old_hymnal_lyrics']!, _oldHymnalLyricsMeta));
    }
    if (data.containsKey('new_hymnal_number')) {
      context.handle(
          _newHymnalNumberMeta,
          newHymnalNumber.isAcceptableOrUnknown(
              data['new_hymnal_number']!, _newHymnalNumberMeta));
    }
    if (data.containsKey('old_hymnal_number')) {
      context.handle(
          _oldHymnalNumberMeta,
          oldHymnalNumber.isAcceptableOrUnknown(
              data['old_hymnal_number']!, _oldHymnalNumberMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hymnId};
  @override
  Hymn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Hymn(
      hymnId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      languageCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language_code'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      lyrics: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lyrics']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      audioUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_url']),
      sheetMusic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sheet_music']),
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist']),
      song: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song']),
      newHymnalTitle: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}new_hymnal_title']),
      oldHymnalTitle: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}old_hymnal_title']),
      newHymnalLyrics: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}new_hymnal_lyrics']),
      englishTitleOld: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}english_title_old']),
      oldHymnalLyrics: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}old_hymnal_lyrics']),
      newHymnalNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}new_hymnal_number']),
      oldHymnalNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}old_hymnal_number']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
    );
  }

  @override
  $HymnsTable createAlias(String alias) {
    return $HymnsTable(attachedDatabase, alias);
  }
}

class Hymn extends DataClass implements Insertable<Hymn> {
  final String hymnId;
  final String languageCode;
  final String version;
  final int? number;
  final String? title;
  final String? lyrics;
  final String? category;
  final String? audioUrl;
  final String? sheetMusic;
  final String? artist;
  final String? song;
  final String? newHymnalTitle;
  final String? oldHymnalTitle;
  final String? newHymnalLyrics;
  final String? englishTitleOld;
  final String? oldHymnalLyrics;
  final int? newHymnalNumber;
  final int? oldHymnalNumber;
  final int createdAt;
  final int updatedAt;
  final bool isFavorite;
  const Hymn(
      {required this.hymnId,
      required this.languageCode,
      required this.version,
      this.number,
      this.title,
      this.lyrics,
      this.category,
      this.audioUrl,
      this.sheetMusic,
      this.artist,
      this.song,
      this.newHymnalTitle,
      this.oldHymnalTitle,
      this.newHymnalLyrics,
      this.englishTitleOld,
      this.oldHymnalLyrics,
      this.newHymnalNumber,
      this.oldHymnalNumber,
      required this.createdAt,
      required this.updatedAt,
      required this.isFavorite});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(hymnId);
    map['language_code'] = Variable<String>(languageCode);
    map['version'] = Variable<String>(version);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || lyrics != null) {
      map['lyrics'] = Variable<String>(lyrics);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    if (!nullToAbsent || sheetMusic != null) {
      map['sheet_music'] = Variable<String>(sheetMusic);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || song != null) {
      map['song'] = Variable<String>(song);
    }
    if (!nullToAbsent || newHymnalTitle != null) {
      map['new_hymnal_title'] = Variable<String>(newHymnalTitle);
    }
    if (!nullToAbsent || oldHymnalTitle != null) {
      map['old_hymnal_title'] = Variable<String>(oldHymnalTitle);
    }
    if (!nullToAbsent || newHymnalLyrics != null) {
      map['new_hymnal_lyrics'] = Variable<String>(newHymnalLyrics);
    }
    if (!nullToAbsent || englishTitleOld != null) {
      map['english_title_old'] = Variable<String>(englishTitleOld);
    }
    if (!nullToAbsent || oldHymnalLyrics != null) {
      map['old_hymnal_lyrics'] = Variable<String>(oldHymnalLyrics);
    }
    if (!nullToAbsent || newHymnalNumber != null) {
      map['new_hymnal_number'] = Variable<int>(newHymnalNumber);
    }
    if (!nullToAbsent || oldHymnalNumber != null) {
      map['old_hymnal_number'] = Variable<int>(oldHymnalNumber);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  HymnsCompanion toCompanion(bool nullToAbsent) {
    return HymnsCompanion(
      hymnId: Value(hymnId),
      languageCode: Value(languageCode),
      version: Value(version),
      number:
          number == null && nullToAbsent ? const Value.absent() : Value(number),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      lyrics:
          lyrics == null && nullToAbsent ? const Value.absent() : Value(lyrics),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      sheetMusic: sheetMusic == null && nullToAbsent
          ? const Value.absent()
          : Value(sheetMusic),
      artist:
          artist == null && nullToAbsent ? const Value.absent() : Value(artist),
      song: song == null && nullToAbsent ? const Value.absent() : Value(song),
      newHymnalTitle: newHymnalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(newHymnalTitle),
      oldHymnalTitle: oldHymnalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(oldHymnalTitle),
      newHymnalLyrics: newHymnalLyrics == null && nullToAbsent
          ? const Value.absent()
          : Value(newHymnalLyrics),
      englishTitleOld: englishTitleOld == null && nullToAbsent
          ? const Value.absent()
          : Value(englishTitleOld),
      oldHymnalLyrics: oldHymnalLyrics == null && nullToAbsent
          ? const Value.absent()
          : Value(oldHymnalLyrics),
      newHymnalNumber: newHymnalNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(newHymnalNumber),
      oldHymnalNumber: oldHymnalNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(oldHymnalNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isFavorite: Value(isFavorite),
    );
  }

  factory Hymn.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Hymn(
      hymnId: serializer.fromJson<String>(json['hymnId']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      version: serializer.fromJson<String>(json['version']),
      number: serializer.fromJson<int?>(json['number']),
      title: serializer.fromJson<String?>(json['title']),
      lyrics: serializer.fromJson<String?>(json['lyrics']),
      category: serializer.fromJson<String?>(json['category']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      sheetMusic: serializer.fromJson<String?>(json['sheetMusic']),
      artist: serializer.fromJson<String?>(json['artist']),
      song: serializer.fromJson<String?>(json['song']),
      newHymnalTitle: serializer.fromJson<String?>(json['newHymnalTitle']),
      oldHymnalTitle: serializer.fromJson<String?>(json['oldHymnalTitle']),
      newHymnalLyrics: serializer.fromJson<String?>(json['newHymnalLyrics']),
      englishTitleOld: serializer.fromJson<String?>(json['englishTitleOld']),
      oldHymnalLyrics: serializer.fromJson<String?>(json['oldHymnalLyrics']),
      newHymnalNumber: serializer.fromJson<int?>(json['newHymnalNumber']),
      oldHymnalNumber: serializer.fromJson<int?>(json['oldHymnalNumber']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hymnId': serializer.toJson<String>(hymnId),
      'languageCode': serializer.toJson<String>(languageCode),
      'version': serializer.toJson<String>(version),
      'number': serializer.toJson<int?>(number),
      'title': serializer.toJson<String?>(title),
      'lyrics': serializer.toJson<String?>(lyrics),
      'category': serializer.toJson<String?>(category),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'sheetMusic': serializer.toJson<String?>(sheetMusic),
      'artist': serializer.toJson<String?>(artist),
      'song': serializer.toJson<String?>(song),
      'newHymnalTitle': serializer.toJson<String?>(newHymnalTitle),
      'oldHymnalTitle': serializer.toJson<String?>(oldHymnalTitle),
      'newHymnalLyrics': serializer.toJson<String?>(newHymnalLyrics),
      'englishTitleOld': serializer.toJson<String?>(englishTitleOld),
      'oldHymnalLyrics': serializer.toJson<String?>(oldHymnalLyrics),
      'newHymnalNumber': serializer.toJson<int?>(newHymnalNumber),
      'oldHymnalNumber': serializer.toJson<int?>(oldHymnalNumber),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  Hymn copyWith(
          {String? hymnId,
          String? languageCode,
          String? version,
          Value<int?> number = const Value.absent(),
          Value<String?> title = const Value.absent(),
          Value<String?> lyrics = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> audioUrl = const Value.absent(),
          Value<String?> sheetMusic = const Value.absent(),
          Value<String?> artist = const Value.absent(),
          Value<String?> song = const Value.absent(),
          Value<String?> newHymnalTitle = const Value.absent(),
          Value<String?> oldHymnalTitle = const Value.absent(),
          Value<String?> newHymnalLyrics = const Value.absent(),
          Value<String?> englishTitleOld = const Value.absent(),
          Value<String?> oldHymnalLyrics = const Value.absent(),
          Value<int?> newHymnalNumber = const Value.absent(),
          Value<int?> oldHymnalNumber = const Value.absent(),
          int? createdAt,
          int? updatedAt,
          bool? isFavorite}) =>
      Hymn(
        hymnId: hymnId ?? this.hymnId,
        languageCode: languageCode ?? this.languageCode,
        version: version ?? this.version,
        number: number.present ? number.value : this.number,
        title: title.present ? title.value : this.title,
        lyrics: lyrics.present ? lyrics.value : this.lyrics,
        category: category.present ? category.value : this.category,
        audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
        sheetMusic: sheetMusic.present ? sheetMusic.value : this.sheetMusic,
        artist: artist.present ? artist.value : this.artist,
        song: song.present ? song.value : this.song,
        newHymnalTitle:
            newHymnalTitle.present ? newHymnalTitle.value : this.newHymnalTitle,
        oldHymnalTitle:
            oldHymnalTitle.present ? oldHymnalTitle.value : this.oldHymnalTitle,
        newHymnalLyrics: newHymnalLyrics.present
            ? newHymnalLyrics.value
            : this.newHymnalLyrics,
        englishTitleOld: englishTitleOld.present
            ? englishTitleOld.value
            : this.englishTitleOld,
        oldHymnalLyrics: oldHymnalLyrics.present
            ? oldHymnalLyrics.value
            : this.oldHymnalLyrics,
        newHymnalNumber: newHymnalNumber.present
            ? newHymnalNumber.value
            : this.newHymnalNumber,
        oldHymnalNumber: oldHymnalNumber.present
            ? oldHymnalNumber.value
            : this.oldHymnalNumber,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isFavorite: isFavorite ?? this.isFavorite,
      );
  Hymn copyWithCompanion(HymnsCompanion data) {
    return Hymn(
      hymnId: data.hymnId.present ? data.hymnId.value : this.hymnId,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      version: data.version.present ? data.version.value : this.version,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      lyrics: data.lyrics.present ? data.lyrics.value : this.lyrics,
      category: data.category.present ? data.category.value : this.category,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      sheetMusic:
          data.sheetMusic.present ? data.sheetMusic.value : this.sheetMusic,
      artist: data.artist.present ? data.artist.value : this.artist,
      song: data.song.present ? data.song.value : this.song,
      newHymnalTitle: data.newHymnalTitle.present
          ? data.newHymnalTitle.value
          : this.newHymnalTitle,
      oldHymnalTitle: data.oldHymnalTitle.present
          ? data.oldHymnalTitle.value
          : this.oldHymnalTitle,
      newHymnalLyrics: data.newHymnalLyrics.present
          ? data.newHymnalLyrics.value
          : this.newHymnalLyrics,
      englishTitleOld: data.englishTitleOld.present
          ? data.englishTitleOld.value
          : this.englishTitleOld,
      oldHymnalLyrics: data.oldHymnalLyrics.present
          ? data.oldHymnalLyrics.value
          : this.oldHymnalLyrics,
      newHymnalNumber: data.newHymnalNumber.present
          ? data.newHymnalNumber.value
          : this.newHymnalNumber,
      oldHymnalNumber: data.oldHymnalNumber.present
          ? data.oldHymnalNumber.value
          : this.oldHymnalNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Hymn(')
          ..write('hymnId: $hymnId, ')
          ..write('languageCode: $languageCode, ')
          ..write('version: $version, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('lyrics: $lyrics, ')
          ..write('category: $category, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('sheetMusic: $sheetMusic, ')
          ..write('artist: $artist, ')
          ..write('song: $song, ')
          ..write('newHymnalTitle: $newHymnalTitle, ')
          ..write('oldHymnalTitle: $oldHymnalTitle, ')
          ..write('newHymnalLyrics: $newHymnalLyrics, ')
          ..write('englishTitleOld: $englishTitleOld, ')
          ..write('oldHymnalLyrics: $oldHymnalLyrics, ')
          ..write('newHymnalNumber: $newHymnalNumber, ')
          ..write('oldHymnalNumber: $oldHymnalNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        hymnId,
        languageCode,
        version,
        number,
        title,
        lyrics,
        category,
        audioUrl,
        sheetMusic,
        artist,
        song,
        newHymnalTitle,
        oldHymnalTitle,
        newHymnalLyrics,
        englishTitleOld,
        oldHymnalLyrics,
        newHymnalNumber,
        oldHymnalNumber,
        createdAt,
        updatedAt,
        isFavorite
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Hymn &&
          other.hymnId == this.hymnId &&
          other.languageCode == this.languageCode &&
          other.version == this.version &&
          other.number == this.number &&
          other.title == this.title &&
          other.lyrics == this.lyrics &&
          other.category == this.category &&
          other.audioUrl == this.audioUrl &&
          other.sheetMusic == this.sheetMusic &&
          other.artist == this.artist &&
          other.song == this.song &&
          other.newHymnalTitle == this.newHymnalTitle &&
          other.oldHymnalTitle == this.oldHymnalTitle &&
          other.newHymnalLyrics == this.newHymnalLyrics &&
          other.englishTitleOld == this.englishTitleOld &&
          other.oldHymnalLyrics == this.oldHymnalLyrics &&
          other.newHymnalNumber == this.newHymnalNumber &&
          other.oldHymnalNumber == this.oldHymnalNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isFavorite == this.isFavorite);
}

class HymnsCompanion extends UpdateCompanion<Hymn> {
  final Value<String> hymnId;
  final Value<String> languageCode;
  final Value<String> version;
  final Value<int?> number;
  final Value<String?> title;
  final Value<String?> lyrics;
  final Value<String?> category;
  final Value<String?> audioUrl;
  final Value<String?> sheetMusic;
  final Value<String?> artist;
  final Value<String?> song;
  final Value<String?> newHymnalTitle;
  final Value<String?> oldHymnalTitle;
  final Value<String?> newHymnalLyrics;
  final Value<String?> englishTitleOld;
  final Value<String?> oldHymnalLyrics;
  final Value<int?> newHymnalNumber;
  final Value<int?> oldHymnalNumber;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<bool> isFavorite;
  final Value<int> rowid;
  const HymnsCompanion({
    this.hymnId = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.version = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.category = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.sheetMusic = const Value.absent(),
    this.artist = const Value.absent(),
    this.song = const Value.absent(),
    this.newHymnalTitle = const Value.absent(),
    this.oldHymnalTitle = const Value.absent(),
    this.newHymnalLyrics = const Value.absent(),
    this.englishTitleOld = const Value.absent(),
    this.oldHymnalLyrics = const Value.absent(),
    this.newHymnalNumber = const Value.absent(),
    this.oldHymnalNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HymnsCompanion.insert({
    required String hymnId,
    required String languageCode,
    required String version,
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.lyrics = const Value.absent(),
    this.category = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.sheetMusic = const Value.absent(),
    this.artist = const Value.absent(),
    this.song = const Value.absent(),
    this.newHymnalTitle = const Value.absent(),
    this.oldHymnalTitle = const Value.absent(),
    this.newHymnalLyrics = const Value.absent(),
    this.englishTitleOld = const Value.absent(),
    this.oldHymnalLyrics = const Value.absent(),
    this.newHymnalNumber = const Value.absent(),
    this.oldHymnalNumber = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.isFavorite = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : hymnId = Value(hymnId),
        languageCode = Value(languageCode),
        version = Value(version),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Hymn> custom({
    Expression<String>? hymnId,
    Expression<String>? languageCode,
    Expression<String>? version,
    Expression<int>? number,
    Expression<String>? title,
    Expression<String>? lyrics,
    Expression<String>? category,
    Expression<String>? audioUrl,
    Expression<String>? sheetMusic,
    Expression<String>? artist,
    Expression<String>? song,
    Expression<String>? newHymnalTitle,
    Expression<String>? oldHymnalTitle,
    Expression<String>? newHymnalLyrics,
    Expression<String>? englishTitleOld,
    Expression<String>? oldHymnalLyrics,
    Expression<int>? newHymnalNumber,
    Expression<int>? oldHymnalNumber,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isFavorite,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hymnId != null) 'id': hymnId,
      if (languageCode != null) 'language_code': languageCode,
      if (version != null) 'version': version,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (lyrics != null) 'lyrics': lyrics,
      if (category != null) 'category': category,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (sheetMusic != null) 'sheet_music': sheetMusic,
      if (artist != null) 'artist': artist,
      if (song != null) 'song': song,
      if (newHymnalTitle != null) 'new_hymnal_title': newHymnalTitle,
      if (oldHymnalTitle != null) 'old_hymnal_title': oldHymnalTitle,
      if (newHymnalLyrics != null) 'new_hymnal_lyrics': newHymnalLyrics,
      if (englishTitleOld != null) 'english_title_old': englishTitleOld,
      if (oldHymnalLyrics != null) 'old_hymnal_lyrics': oldHymnalLyrics,
      if (newHymnalNumber != null) 'new_hymnal_number': newHymnalNumber,
      if (oldHymnalNumber != null) 'old_hymnal_number': oldHymnalNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HymnsCompanion copyWith(
      {Value<String>? hymnId,
      Value<String>? languageCode,
      Value<String>? version,
      Value<int?>? number,
      Value<String?>? title,
      Value<String?>? lyrics,
      Value<String?>? category,
      Value<String?>? audioUrl,
      Value<String?>? sheetMusic,
      Value<String?>? artist,
      Value<String?>? song,
      Value<String?>? newHymnalTitle,
      Value<String?>? oldHymnalTitle,
      Value<String?>? newHymnalLyrics,
      Value<String?>? englishTitleOld,
      Value<String?>? oldHymnalLyrics,
      Value<int?>? newHymnalNumber,
      Value<int?>? oldHymnalNumber,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<bool>? isFavorite,
      Value<int>? rowid}) {
    return HymnsCompanion(
      hymnId: hymnId ?? this.hymnId,
      languageCode: languageCode ?? this.languageCode,
      version: version ?? this.version,
      number: number ?? this.number,
      title: title ?? this.title,
      lyrics: lyrics ?? this.lyrics,
      category: category ?? this.category,
      audioUrl: audioUrl ?? this.audioUrl,
      sheetMusic: sheetMusic ?? this.sheetMusic,
      artist: artist ?? this.artist,
      song: song ?? this.song,
      newHymnalTitle: newHymnalTitle ?? this.newHymnalTitle,
      oldHymnalTitle: oldHymnalTitle ?? this.oldHymnalTitle,
      newHymnalLyrics: newHymnalLyrics ?? this.newHymnalLyrics,
      englishTitleOld: englishTitleOld ?? this.englishTitleOld,
      oldHymnalLyrics: oldHymnalLyrics ?? this.oldHymnalLyrics,
      newHymnalNumber: newHymnalNumber ?? this.newHymnalNumber,
      oldHymnalNumber: oldHymnalNumber ?? this.oldHymnalNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hymnId.present) {
      map['id'] = Variable<String>(hymnId.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lyrics.present) {
      map['lyrics'] = Variable<String>(lyrics.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (sheetMusic.present) {
      map['sheet_music'] = Variable<String>(sheetMusic.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (song.present) {
      map['song'] = Variable<String>(song.value);
    }
    if (newHymnalTitle.present) {
      map['new_hymnal_title'] = Variable<String>(newHymnalTitle.value);
    }
    if (oldHymnalTitle.present) {
      map['old_hymnal_title'] = Variable<String>(oldHymnalTitle.value);
    }
    if (newHymnalLyrics.present) {
      map['new_hymnal_lyrics'] = Variable<String>(newHymnalLyrics.value);
    }
    if (englishTitleOld.present) {
      map['english_title_old'] = Variable<String>(englishTitleOld.value);
    }
    if (oldHymnalLyrics.present) {
      map['old_hymnal_lyrics'] = Variable<String>(oldHymnalLyrics.value);
    }
    if (newHymnalNumber.present) {
      map['new_hymnal_number'] = Variable<int>(newHymnalNumber.value);
    }
    if (oldHymnalNumber.present) {
      map['old_hymnal_number'] = Variable<int>(oldHymnalNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HymnsCompanion(')
          ..write('hymnId: $hymnId, ')
          ..write('languageCode: $languageCode, ')
          ..write('version: $version, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('lyrics: $lyrics, ')
          ..write('category: $category, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('sheetMusic: $sheetMusic, ')
          ..write('artist: $artist, ')
          ..write('song: $song, ')
          ..write('newHymnalTitle: $newHymnalTitle, ')
          ..write('oldHymnalTitle: $oldHymnalTitle, ')
          ..write('newHymnalLyrics: $newHymnalLyrics, ')
          ..write('englishTitleOld: $englishTitleOld, ')
          ..write('oldHymnalLyrics: $oldHymnalLyrics, ')
          ..write('newHymnalNumber: $newHymnalNumber, ')
          ..write('oldHymnalNumber: $oldHymnalNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HymnsTable hymns = $HymnsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [hymns];
}

typedef $$HymnsTableCreateCompanionBuilder = HymnsCompanion Function({
  required String hymnId,
  required String languageCode,
  required String version,
  Value<int?> number,
  Value<String?> title,
  Value<String?> lyrics,
  Value<String?> category,
  Value<String?> audioUrl,
  Value<String?> sheetMusic,
  Value<String?> artist,
  Value<String?> song,
  Value<String?> newHymnalTitle,
  Value<String?> oldHymnalTitle,
  Value<String?> newHymnalLyrics,
  Value<String?> englishTitleOld,
  Value<String?> oldHymnalLyrics,
  Value<int?> newHymnalNumber,
  Value<int?> oldHymnalNumber,
  required int createdAt,
  required int updatedAt,
  Value<bool> isFavorite,
  Value<int> rowid,
});
typedef $$HymnsTableUpdateCompanionBuilder = HymnsCompanion Function({
  Value<String> hymnId,
  Value<String> languageCode,
  Value<String> version,
  Value<int?> number,
  Value<String?> title,
  Value<String?> lyrics,
  Value<String?> category,
  Value<String?> audioUrl,
  Value<String?> sheetMusic,
  Value<String?> artist,
  Value<String?> song,
  Value<String?> newHymnalTitle,
  Value<String?> oldHymnalTitle,
  Value<String?> newHymnalLyrics,
  Value<String?> englishTitleOld,
  Value<String?> oldHymnalLyrics,
  Value<int?> newHymnalNumber,
  Value<int?> oldHymnalNumber,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<bool> isFavorite,
  Value<int> rowid,
});

class $$HymnsTableFilterComposer extends Composer<_$AppDatabase, $HymnsTable> {
  $$HymnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hymnId => $composableBuilder(
      column: $table.hymnId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get languageCode => $composableBuilder(
      column: $table.languageCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sheetMusic => $composableBuilder(
      column: $table.sheetMusic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get song => $composableBuilder(
      column: $table.song, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newHymnalTitle => $composableBuilder(
      column: $table.newHymnalTitle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oldHymnalTitle => $composableBuilder(
      column: $table.oldHymnalTitle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newHymnalLyrics => $composableBuilder(
      column: $table.newHymnalLyrics,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get englishTitleOld => $composableBuilder(
      column: $table.englishTitleOld,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oldHymnalLyrics => $composableBuilder(
      column: $table.oldHymnalLyrics,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newHymnalNumber => $composableBuilder(
      column: $table.newHymnalNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get oldHymnalNumber => $composableBuilder(
      column: $table.oldHymnalNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));
}

class $$HymnsTableOrderingComposer
    extends Composer<_$AppDatabase, $HymnsTable> {
  $$HymnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hymnId => $composableBuilder(
      column: $table.hymnId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get languageCode => $composableBuilder(
      column: $table.languageCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lyrics => $composableBuilder(
      column: $table.lyrics, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sheetMusic => $composableBuilder(
      column: $table.sheetMusic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artist => $composableBuilder(
      column: $table.artist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get song => $composableBuilder(
      column: $table.song, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newHymnalTitle => $composableBuilder(
      column: $table.newHymnalTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oldHymnalTitle => $composableBuilder(
      column: $table.oldHymnalTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newHymnalLyrics => $composableBuilder(
      column: $table.newHymnalLyrics,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get englishTitleOld => $composableBuilder(
      column: $table.englishTitleOld,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oldHymnalLyrics => $composableBuilder(
      column: $table.oldHymnalLyrics,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newHymnalNumber => $composableBuilder(
      column: $table.newHymnalNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get oldHymnalNumber => $composableBuilder(
      column: $table.oldHymnalNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));
}

class $$HymnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HymnsTable> {
  $$HymnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hymnId =>
      $composableBuilder(column: $table.hymnId, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
      column: $table.languageCode, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get lyrics =>
      $composableBuilder(column: $table.lyrics, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get sheetMusic => $composableBuilder(
      column: $table.sheetMusic, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get song =>
      $composableBuilder(column: $table.song, builder: (column) => column);

  GeneratedColumn<String> get newHymnalTitle => $composableBuilder(
      column: $table.newHymnalTitle, builder: (column) => column);

  GeneratedColumn<String> get oldHymnalTitle => $composableBuilder(
      column: $table.oldHymnalTitle, builder: (column) => column);

  GeneratedColumn<String> get newHymnalLyrics => $composableBuilder(
      column: $table.newHymnalLyrics, builder: (column) => column);

  GeneratedColumn<String> get englishTitleOld => $composableBuilder(
      column: $table.englishTitleOld, builder: (column) => column);

  GeneratedColumn<String> get oldHymnalLyrics => $composableBuilder(
      column: $table.oldHymnalLyrics, builder: (column) => column);

  GeneratedColumn<int> get newHymnalNumber => $composableBuilder(
      column: $table.newHymnalNumber, builder: (column) => column);

  GeneratedColumn<int> get oldHymnalNumber => $composableBuilder(
      column: $table.oldHymnalNumber, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);
}

class $$HymnsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HymnsTable,
    Hymn,
    $$HymnsTableFilterComposer,
    $$HymnsTableOrderingComposer,
    $$HymnsTableAnnotationComposer,
    $$HymnsTableCreateCompanionBuilder,
    $$HymnsTableUpdateCompanionBuilder,
    (Hymn, BaseReferences<_$AppDatabase, $HymnsTable, Hymn>),
    Hymn,
    PrefetchHooks Function()> {
  $$HymnsTableTableManager(_$AppDatabase db, $HymnsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HymnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HymnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HymnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> hymnId = const Value.absent(),
            Value<String> languageCode = const Value.absent(),
            Value<String> version = const Value.absent(),
            Value<int?> number = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String?> sheetMusic = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> song = const Value.absent(),
            Value<String?> newHymnalTitle = const Value.absent(),
            Value<String?> oldHymnalTitle = const Value.absent(),
            Value<String?> newHymnalLyrics = const Value.absent(),
            Value<String?> englishTitleOld = const Value.absent(),
            Value<String?> oldHymnalLyrics = const Value.absent(),
            Value<int?> newHymnalNumber = const Value.absent(),
            Value<int?> oldHymnalNumber = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HymnsCompanion(
            hymnId: hymnId,
            languageCode: languageCode,
            version: version,
            number: number,
            title: title,
            lyrics: lyrics,
            category: category,
            audioUrl: audioUrl,
            sheetMusic: sheetMusic,
            artist: artist,
            song: song,
            newHymnalTitle: newHymnalTitle,
            oldHymnalTitle: oldHymnalTitle,
            newHymnalLyrics: newHymnalLyrics,
            englishTitleOld: englishTitleOld,
            oldHymnalLyrics: oldHymnalLyrics,
            newHymnalNumber: newHymnalNumber,
            oldHymnalNumber: oldHymnalNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String hymnId,
            required String languageCode,
            required String version,
            Value<int?> number = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> lyrics = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String?> sheetMusic = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> song = const Value.absent(),
            Value<String?> newHymnalTitle = const Value.absent(),
            Value<String?> oldHymnalTitle = const Value.absent(),
            Value<String?> newHymnalLyrics = const Value.absent(),
            Value<String?> englishTitleOld = const Value.absent(),
            Value<String?> oldHymnalLyrics = const Value.absent(),
            Value<int?> newHymnalNumber = const Value.absent(),
            Value<int?> oldHymnalNumber = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<bool> isFavorite = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HymnsCompanion.insert(
            hymnId: hymnId,
            languageCode: languageCode,
            version: version,
            number: number,
            title: title,
            lyrics: lyrics,
            category: category,
            audioUrl: audioUrl,
            sheetMusic: sheetMusic,
            artist: artist,
            song: song,
            newHymnalTitle: newHymnalTitle,
            oldHymnalTitle: oldHymnalTitle,
            newHymnalLyrics: newHymnalLyrics,
            englishTitleOld: englishTitleOld,
            oldHymnalLyrics: oldHymnalLyrics,
            newHymnalNumber: newHymnalNumber,
            oldHymnalNumber: oldHymnalNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HymnsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HymnsTable,
    Hymn,
    $$HymnsTableFilterComposer,
    $$HymnsTableOrderingComposer,
    $$HymnsTableAnnotationComposer,
    $$HymnsTableCreateCompanionBuilder,
    $$HymnsTableUpdateCompanionBuilder,
    (Hymn, BaseReferences<_$AppDatabase, $HymnsTable, Hymn>),
    Hymn,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HymnsTableTableManager get hymns =>
      $$HymnsTableTableManager(_db, _db.hymns);
}
