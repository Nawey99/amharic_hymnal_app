import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:amharic_hymnal_app/core/config/content_api_config.dart';

class CachedMediaFile {
  final String path;
  final int bytes;

  const CachedMediaFile({
    required this.path,
    required this.bytes,
  });
}

class LocalMediaCacheService {
  static final LocalMediaCacheService instance = LocalMediaCacheService._();
  LocalMediaCacheService._();

  Future<String?> cachedPath(Uri source, String mediaType) async {
    if (kIsWeb) return null;
    final file = await _fileFor(source, mediaType);
    return file.existsSync() ? file.path : null;
  }

  Future<CachedMediaFile> download(
    Uri source,
    String mediaType, {
    void Function(int received, int? total)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Web media cache is not configured yet.');
    }

    final request = http.Request('GET', source);
    final response = await request.send().timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'HTTP ${response.statusCode}',
        uri: source,
      );
    }

    final file = await _fileFor(source, mediaType);
    await file.parent.create(recursive: true);
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        onProgress?.call(received, response.contentLength);
      }
    } finally {
      await sink.close();
    }

    return CachedMediaFile(path: file.path, bytes: received);
  }

  Future<File> _fileFor(Uri source, String mediaType) async {
    final dir = await getApplicationSupportDirectory();
    final cleanType = mediaType.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final sourceName = path.basename(source.path);
    final fileName = sourceName.contains('.')
        ? sourceName
        : '${source.toString().hashCode.abs()}';
    return File(path.join(dir.path, 'media_cache', cleanType, fileName));
  }
}

class RemoteSheetMusicDataSource {
  final String? baseUrl;

  const RemoteSheetMusicDataSource({this.baseUrl});

  Future<List<Uri>> resolve(int hymnNumber) async {
    final root = baseUrl ?? ContentApiConfig.baseUrl;
    if (root.isEmpty) return const [];
    final normalized =
        root.endsWith('/') ? root.substring(0, root.length - 1) : root;
    return [
      Uri.parse('$normalized/sheet_music/$hymnNumber.webp'),
      Uri.parse('$normalized/sheet_music/${hymnNumber}_L.webp'),
      Uri.parse('$normalized/sheet_music/${hymnNumber}_R.webp'),
    ];
  }
}

class RemoteAudioDataSource {
  final String? baseUrl;

  const RemoteAudioDataSource({this.baseUrl});

  Future<Uri?> resolve(int hymnNumber) async {
    final root = baseUrl ?? ContentApiConfig.baseUrl;
    if (root.isEmpty) return null;
    final normalized =
        root.endsWith('/') ? root.substring(0, root.length - 1) : root;
    return Uri.parse('$normalized/audio/$hymnNumber.mp3');
  }
}
