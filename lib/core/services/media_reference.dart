/// Identifies where a playable or viewable media file comes from.
enum MediaReferenceKind {
  remote,
  localFile,
}

/// A validated media reference supplied by content metadata or the local cache.
///
/// Relative paths and Flutter asset paths are intentionally rejected. Bundled
/// hymn media has been retired, so media must now be either an explicit HTTP(S)
/// URL from the content backend or an absolute path to a downloaded file.
class MediaReference {
  final Uri uri;
  final MediaReferenceKind kind;

  const MediaReference._({
    required this.uri,
    required this.kind,
  });

  bool get isRemote => kind == MediaReferenceKind.remote;

  bool get isLocalFile => kind == MediaReferenceKind.localFile;

  String get value => isRemote ? uri.toString() : localPath;

  String get localPath {
    if (!isLocalFile) {
      throw StateError('Remote media does not have a local file path.');
    }
    return uri.toFilePath(windows: _looksLikeWindowsFileUri(uri));
  }

  /// Parses a backend URL or an absolute downloaded-file path.
  static MediaReference? tryParse(String? rawValue) {
    final value = rawValue?.trim();
    if (value == null || value.isEmpty) return null;

    if (_isWindowsAbsolutePath(value)) {
      return MediaReference._(
        uri: Uri.file(value, windows: true),
        kind: MediaReferenceKind.localFile,
      );
    }

    if (value.startsWith('/')) {
      return MediaReference._(
        uri: Uri.file(value, windows: false),
        kind: MediaReferenceKind.localFile,
      );
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (_isRemoteUri(uri)) {
      return MediaReference._(
        uri: uri,
        kind: MediaReferenceKind.remote,
      );
    }

    if (uri.scheme == 'file' && uri.path.isNotEmpty) {
      return MediaReference._(
        uri: uri,
        kind: MediaReferenceKind.localFile,
      );
    }

    return null;
  }

  static bool isDownloadableUri(Uri uri) => _isRemoteUri(uri);

  static bool _isRemoteUri(Uri uri) {
    return (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
  }

  static bool _isWindowsAbsolutePath(String value) {
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value) ||
        value.startsWith(r'\\');
  }

  static bool _looksLikeWindowsFileUri(Uri uri) {
    return RegExp(r'^/[A-Za-z]:/').hasMatch(uri.path) || uri.host.isNotEmpty;
  }
}
