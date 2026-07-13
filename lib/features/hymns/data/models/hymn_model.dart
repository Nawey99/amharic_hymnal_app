// lib/features/hymns/data/models/hymn_model.dart
import 'package:json_annotation/json_annotation.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

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
          newHymnalNumber: newHymnalNumber,
          oldHymnalNumber: oldHymnalNumber,
        );

  factory HymnModel.fromJson(Map<String, dynamic> json) =>
      _$HymnModelFromJson(json);

  Map<String, dynamic> toJson() => _$HymnModelToJson(this);
}
