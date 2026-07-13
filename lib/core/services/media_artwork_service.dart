import 'package:amharic_hymnal_app/core/services/media_artwork_stub.dart'
    if (dart.library.io) 'package:amharic_hymnal_app/core/services/media_artwork_io.dart';

class MediaArtworkService {
  MediaArtworkService._();

  static final MediaArtworkService instance = MediaArtworkService._();
  static const String _artworkAsset = 'assets/images/media_artwork.png';

  Future<Uri?>? _artworkUri;

  Future<Uri?> getArtworkUri() {
    return _artworkUri ??= cacheMediaArtwork(_artworkAsset);
  }
}
