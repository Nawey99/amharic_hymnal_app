import 'package:equatable/equatable.dart';

/// One downloadable file described by the hymnal API.
class HymnMediaFile extends Equatable {
  /// The API route for the file. It redirects to short-lived storage, so it is
  /// safe to keep; the redirect target is not.
  final String url;
  final String? checksumSha256;
  final int? sizeBytes;
  final String? contentType;
  final String? fileName;

  const HymnMediaFile({
    required this.url,
    this.checksumSha256,
    this.sizeBytes,
    this.contentType,
    this.fileName,
  });

  @override
  List<Object?> get props =>
      [url, checksumSha256, sizeBytes, contentType, fileName];
}

/// A hymn's audio track.
class HymnAudioInfo extends Equatable {
  final HymnMediaFile file;

  /// True for a tune rendered from MIDI rather than a recorded performance.
  final bool isSynthesized;

  /// Credit text to show as-is. It is for people and may change, so never
  /// branch on it.
  final String? attribution;

  const HymnAudioInfo({
    required this.file,
    this.isSynthesized = false,
    this.attribution,
  });

  @override
  List<Object?> get props => [file, isSynthesized, attribution];
}

/// One page of a hymn's sheet music.
class HymnSheetPage extends Equatable {
  final HymnMediaFile file;
  final int pageNumber;

  /// The API code of the edition whose scan this is, or null when the page is
  /// this edition's own. A borrowed page prints the other book's hymn number.
  final String? borrowedFromVersionCode;

  const HymnSheetPage({
    required this.file,
    required this.pageNumber,
    this.borrowedFromVersionCode,
  });

  @override
  List<Object?> get props => [file, pageNumber, borrowedFromVersionCode];
}
