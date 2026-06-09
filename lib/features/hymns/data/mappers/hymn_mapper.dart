// lib/features/hymns/data/mappers/hymn_mapper.dart
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// Mapper to convert between data models and domain entities
/// This ensures proper separation between data and domain layers
class HymnMapper {
  /// Convert HymnModel (data layer) to Hymn (domain entity)
  static Hymn toDomain(HymnModel model) {
    return Hymn(
      id: model.id,
      number: model.number,
      title: model.title,
      lyrics: model.lyrics,
      category: model.category,
      audioUrl: model.audioUrl,
      sheetMusic: model.sheetMusic,
      artist: model.artist,
      song: model.song,
      newHymnalTitle: model.newHymnalTitle,
      oldHymnalTitle: model.oldHymnalTitle,
      newHymnalLyrics: model.newHymnalLyrics,
      englishTitleOld: model.englishTitleOld,
      oldHymnalLyrics: model.oldHymnalLyrics,
      isFavorite: model.isFavorite,
    );
  }

  /// Convert list of HymnModel to list of Hymn
  static List<Hymn> toDomainList(List<HymnModel> models) {
    return models.map((model) => toDomain(model)).toList();
  }

  /// Convert Hymn (domain entity) to HymnModel (data layer)
  /// Note: This is typically not needed as we read from data, not write domain to data
  static HymnModel fromDomain(Hymn hymn) {
    return HymnModel(
      id: hymn.id,
      number: hymn.number,
      title: hymn.title,
      lyrics: hymn.lyrics,
      category: hymn.category,
      audioUrl: hymn.audioUrl,
      sheetMusic: hymn.sheetMusic,
      artist: hymn.artist,
      song: hymn.song,
      newHymnalTitle: hymn.newHymnalTitle,
      oldHymnalTitle: hymn.oldHymnalTitle,
      newHymnalLyrics: hymn.newHymnalLyrics,
      englishTitleOld: hymn.englishTitleOld,
      oldHymnalLyrics: hymn.oldHymnalLyrics,
      isFavorite: hymn.isFavorite,
    );
  }
}
