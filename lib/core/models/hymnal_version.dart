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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HymnalVersion &&
          id == other.id &&
          label == other.label &&
          shortLabel == other.shortLabel &&
          isSda == other.isSda &&
          hasCategories == other.hasCategories &&
          fallbackDatabaseVersion == other.fallbackDatabaseVersion;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        shortLabel,
        isSda,
        hasCategories,
        fallbackDatabaseVersion,
      );
}

class HymnalVersions {
  // These IDs are persisted (favorites, history, settings) and sent to the
  // content API, so they keep their original values even where the edition
  // year differs: sda_new is the 2004 book, sda_old the 1975 book and
  // sda_1960 the 1961 book.
  static const String sdaNew = 'sda_new';
  static const String sdaOld = 'sda_old';
  static const String sda1961 = 'sda_1960';
  static const String hagerigna = 'hagerigna';
  static const String legacyHymnal = 'hymnal';

  static const HymnalVersion hymnal2004 = HymnalVersion(
    id: sdaNew,
    label: 'የ2004 ውዳሴ መዝሙር',
    shortLabel: '2004 ውዳሴ',
    isSda: true,
    hasCategories: true,
    fallbackDatabaseVersion: legacyHymnal,
  );

  static const HymnalVersion hymnal1975 = HymnalVersion(
    id: sdaOld,
    label: 'የ1975 ውዳሴ መዝሙር',
    shortLabel: '1975 ውዳሴ',
    isSda: true,
    hasCategories: true,
    fallbackDatabaseVersion: legacyHymnal,
  );

  static const HymnalVersion hymnal1961 = HymnalVersion(
    id: sda1961,
    label: 'የ1961 ውዳሴ መዝሙር',
    shortLabel: '1961 ውዳሴ',
    isSda: true,
    hasCategories: true,
    fallbackDatabaseVersion: sda1961,
  );

  static const HymnalVersion hagerignaSongs = HymnalVersion(
    id: hagerigna,
    label: 'የሀገርኛ መዝሙር',
    shortLabel: 'ሀገርኛ',
    isSda: false,
    hasCategories: false,
    fallbackDatabaseVersion: hagerigna,
  );

  static const List<HymnalVersion> all = [
    hymnal2004,
    hymnal1975,
    hymnal1961,
    hagerignaSongs,
  ];

  static final RegExp _versionIdPattern = RegExp(r'^[a-z0-9_]{2,64}$');

  static String normalizeId(String version) {
    final candidate = version.trim().toLowerCase();
    if (candidate == legacyHymnal || candidate.isEmpty) return sdaNew;
    if (_versionIdPattern.hasMatch(candidate)) return candidate;
    return sdaNew;
  }

  static String fallbackDatabaseVersion(String version) {
    return byId(version).fallbackDatabaseVersion;
  }

  static HymnalVersion byId(String version) {
    final normalized = normalizeId(version);
    for (final item in all) {
      if (item.id == normalized) return item;
    }

    final isSdaEdition = normalized.startsWith('sda_');
    return HymnalVersion(
      id: normalized,
      label: normalized,
      shortLabel: normalized,
      isSda: isSdaEdition,
      hasCategories: isSdaEdition,
      fallbackDatabaseVersion: normalized,
    );
  }

  /// Edition codes used by the hymnal API for the editions whose local IDs
  /// predate it. Other editions follow the generic `am-<id with hyphens>`
  /// rule, e.g. `sda_2019` <-> `am-sda-2019`.
  static const Map<String, String> _apiCodes = {
    sdaNew: 'am-sda-2004',
    sdaOld: 'am-sda-1975',
    sda1961: 'am-sda-1961',
    hagerigna: 'am-hagerigna',
  };

  static final RegExp _apiLanguagePrefix = RegExp(r'^[a-z]{2,3}-');

  /// The API edition code for a local version ID.
  static String apiCode(String version, {String languageCode = 'am'}) {
    final id = normalizeId(version);
    return _apiCodes[id] ?? '$languageCode-${id.replaceAll('_', '-')}';
  }

  /// The local version ID for an API edition code, or null if the code
  /// cannot be represented as a local ID.
  static String? fromApiCode(String code) {
    final candidate = code.trim().toLowerCase();
    for (final entry in _apiCodes.entries) {
      if (entry.value == candidate) return entry.key;
    }
    final id =
        candidate.replaceFirst(_apiLanguagePrefix, '').replaceAll('-', '_');
    return _versionIdPattern.hasMatch(id) ? id : null;
  }

  static bool isSda(String version) => byId(version).isSda;

  static bool hasCategories(String version) => byId(version).hasCategories;

  static String displayLabel(String version) => byId(version).label;
}
