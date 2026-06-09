// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hymn_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HymnModel _$HymnModelFromJson(Map<String, dynamic> json) => HymnModel(
      id: json['id'] as String?,
      number: (json['number'] as num?)?.toInt(),
      title: json['title'] as String?,
      lyrics: json['lyrics'] as String?,
      category: json['category'] as String?,
      audioUrl: json['audio'] as String?,
      sheetMusic: (json['sheet_music'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      artist: json['artist'] as String?,
      song: json['song'] as String?,
      newHymnalTitle: json['newHymnalTitle'] as String?,
      oldHymnalTitle: json['oldHymnalTitle'] as String?,
      newHymnalLyrics: json['newHymnalLyrics'] as String?,
      englishTitleOld: json['englishTitleOld'] as String?,
      oldHymnalLyrics: json['oldHymnalLyrics'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );

Map<String, dynamic> _$HymnModelToJson(HymnModel instance) => <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.number case final value?) 'number': value,
      if (instance.title case final value?) 'title': value,
      if (instance.lyrics case final value?) 'lyrics': value,
      if (instance.category case final value?) 'category': value,
      if (instance.artist case final value?) 'artist': value,
      if (instance.song case final value?) 'song': value,
      if (instance.newHymnalTitle case final value?) 'newHymnalTitle': value,
      if (instance.oldHymnalTitle case final value?) 'oldHymnalTitle': value,
      if (instance.newHymnalLyrics case final value?) 'newHymnalLyrics': value,
      if (instance.englishTitleOld case final value?) 'englishTitleOld': value,
      if (instance.oldHymnalLyrics case final value?) 'oldHymnalLyrics': value,
      'isFavorite': instance.isFavorite,
      if (instance.audioUrl case final value?) 'audio': value,
      if (instance.sheetMusic case final value?) 'sheet_music': value,
    };
