// lib/features/hymns/data/datasources/hymn_local_data_source.dart

import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';

/// Abstract interface for Hymn data source to decouple DB implementation
/// from business logic and allow easier testing.
abstract class HymnLocalDataSource {
  /// Returns a list of [HymnModel] for the given language and version.
  Future<List<HymnModel>> getHymns(String languageCode, String version);
}
