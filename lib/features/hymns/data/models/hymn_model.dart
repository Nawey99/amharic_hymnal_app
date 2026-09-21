// lib/features/hymns/data/models/hymn_model.dart
import 'package:json_annotation/json_annotation.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';

part 'hymn_model.g.dart';

@JsonSerializable(
  createToJson: true,
  includeIfNull: false,
  explicitToJson: true,
)
class HymnModel extends Hymn {
  @JsonKey(name: 'audio')
  @override
  // ignore: overridden_fields
  final String? audioUrl;

  @JsonKey(name: 'sheet_music')
  @override
  // ignore: overridden_fields
  final List<String>? sheetMusic;

  // API file details are mapped by the hymnal API data source, never read
  // from or written to legacy JSON.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  // ignore: overridden_fields
  final HymnAudioInfo? audioInfo;

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  // ignore: overridden_fields
  final List<HymnSheetPage>? sheetPages;

  @JsonKey(name: 'new_hymnal_number')
  @override
  // ignore: overridden_fields
  final int? newHymnalNumber;

  @JsonKey(name: 'old_hymnal_number')
  @override
  // ignore: overridden_fields
  final int? oldHymnalNumber;

  const HymnModel({
    super.id,
    super.number,
    super.title,
    super.lyrics,
    super.category,
    this.audioUrl,
    this.sheetMusic,
    this.audioInfo,
    this.sheetPages,
    // Hagerigna fields
    super.artist,
    super.song,
    // SDA fields
    super.newHymnalTitle,
    super.oldHymnalTitle,
    super.newHymnalLyrics,
    super.englishTitleOld,
    super.oldHymnalLyrics,
    this.newHymnalNumber,
    this.oldHymnalNumber,
    super.isFavorite,
  }) : super(
          audioUrl: audioUrl,
          sheetMusic: sheetMusic,
          audioInfo: audioInfo,
          sheetPages: sheetPages,
          newHymnalNumber: newHymnalNumber,
          oldHymnalNumber: oldHymnalNumber,
        );

  factory HymnModel.fromJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['audio'] ??= normalized['audio_url'];
    normalized['newHymnalTitle'] ??= normalized['new_hymnal_title'];
    normalized['oldHymnalTitle'] ??= normalized['old_hymnal_title'];
    normalized['newHymnalLyrics'] ??= normalized['new_hymnal_lyrics'];
    normalized['oldHymnalLyrics'] ??= normalized['old_hymnal_lyrics'];
    normalized['englishTitleOld'] ??= normalized['english_title_old'];
    normalized['isFavorite'] ??= normalized['is_favorite'];
    return _$HymnModelFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$HymnModelToJson(this);
}
