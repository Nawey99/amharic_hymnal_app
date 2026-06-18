import 'package:flutter/foundation.dart';

@immutable
class HymnalVersion {
  final String id;
  final String label;
  final String shortLabel;
  final bool isSda;
  final bool hasCategories;
  final String fallbackDatabaseVersion;

  const HymnalVersion({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.isSda,
    required this.hasCategories,
    required this.fallbackDatabaseVersion,
  });
}

class HymnalVersions {
  static const String sdaNew = 'sda_new';
  static const String sdaOld = 'sda_old';
  static const String hagerigna = 'hagerigna';
  static const String legacyHymnal = 'hymnal';

  static const HymnalVersion newHymnal = HymnalVersion(
    id: sdaNew,
    label: 'New SDA Hymnal',
    shortLabel: 'New Hymnal',
    isSda: true,
    hasCategories: true,
    fallbackDatabaseVersion: legacyHymnal,
  );

  static const HymnalVersion oldHymnal = HymnalVersion(
    id: sdaOld,
    label: 'Old SDA Hymnal',
    shortLabel: 'Old Hymnal',
    isSda: true,
    hasCategories: true,
    fallbackDatabaseVersion: legacyHymnal,
  );

  static const HymnalVersion hagerignaSongs = HymnalVersion(
    id: hagerigna,
    label: 'Hagerigna',
    shortLabel: 'Hagerigna',
    isSda: false,
    hasCategories: false,
    fallbackDatabaseVersion: hagerigna,
  );

  static const List<HymnalVersion> all = [
    newHymnal,
    oldHymnal,
    hagerignaSongs,
  ];

  static String normalizeId(String version) {
    if (version == legacyHymnal) return sdaNew;
    if (all.any((item) => item.id == version)) return version;
    return sdaNew;
  }

  static String fallbackDatabaseVersion(String version) {
    return byId(version).fallbackDatabaseVersion;
  }

  static HymnalVersion byId(String version) {
    final normalized = normalizeId(version);
    return all.firstWhere(
      (item) => item.id == normalized,
      orElse: () => newHymnal,
    );
  }

  static bool isSda(String version) => byId(version).isSda;

  static bool hasCategories(String version) => byId(version).hasCategories;

  static String displayLabel(String version) => byId(version).label;
}
