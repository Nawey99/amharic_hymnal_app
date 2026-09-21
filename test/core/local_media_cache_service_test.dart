import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as path;

import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';

void main() {
  late Directory root;
  final bytes = utf8.encode('sheet page bytes');
  final checksum = sha256.convert(bytes).toString();
  final pageUri = Uri.parse(
    'https://api.example.test/api/v1/songs/am-sda-2004-0001/sheet-music/pages/1/file',
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('media_cache_test');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  LocalMediaCacheService cacheWith(MockClient client) => LocalMediaCacheService(
      client: client, directoryProvider: () async => root);

  test('stores a verified download under its checksum with an extension',
      () async {
    final cache =
        cacheWith(MockClient((_) async => http.Response.bytes(bytes, 200)));
    final source = MediaSource(
      pageUri,
      checksumSha256: checksum,
      sizeBytes: bytes.length,
      fileName: '01.webp',
      contentType: 'image/webp',
    );

    final file = await cache.download(source, MediaType.sheetMusic);

    expect(path.basename(file.path), '$checksum.webp');
    expect(await File(file.path).readAsBytes(), bytes);
    expect(await cache.cachedPath(source, MediaType.sheetMusic), file.path);
  });

  test('derives the extension from the content type when the URL has none',
      () async {
    final cache =
        cacheWith(MockClient((_) async => http.Response.bytes(bytes, 200)));
    final source = MediaSource(
      Uri.parse('https://api.example.test/api/v1/songs/x/audio/file'),
      checksumSha256: checksum,
      contentType: 'audio/mp4',
    );

    final file = await cache.download(source, MediaType.audio);

    expect(path.extension(file.path), '.m4a');
  });

  test('rejects bytes that do not match the checksum and keeps nothing',
      () async {
    final cache = cacheWith(
      MockClient(
          (_) async => http.Response.bytes(utf8.encode('tampered'), 200)),
    );
    final source = MediaSource(pageUri, checksumSha256: checksum);

    await expectLater(
      cache.download(source, MediaType.sheetMusic),
      throwsA(isA<MediaIntegrityException>()),
    );
    expect(await cache.cachedPath(source, MediaType.sheetMusic), isNull);
    final directory =
        Directory(path.join(root.path, 'media_cache', 'sheet_music'));
    expect(await directory.list().toList(), isEmpty);
  });

  test('rejects a download whose size differs from the promised size',
      () async {
    final cache =
        cacheWith(MockClient((_) async => http.Response.bytes(bytes, 200)));
    final source = MediaSource(pageUri, sizeBytes: bytes.length + 1);

    await expectLater(
      cache.download(source, MediaType.sheetMusic),
      throwsA(isA<MediaIntegrityException>()),
    );
  });

  test('a file shared by two hymns is downloaded once', () async {
    var requests = 0;
    final cache = cacheWith(MockClient((_) async {
      requests++;
      return http.Response.bytes(bytes, 200);
    }));
    final first = MediaSource(pageUri, checksumSha256: checksum);
    final second = MediaSource(
      Uri.parse(
        'https://api.example.test/api/v1/songs/am-sda-1975-0001/sheet-music/pages/1/file',
      ),
      checksumSha256: checksum,
    );

    final a = await cache.download(first, MediaType.sheetMusic);
    expect(await cache.cachedPath(second, MediaType.sheetMusic), a.path);
    final b = await cache.download(second, MediaType.sheetMusic);

    expect(b.path, a.path);
    expect(requests, 1);
  });

  test('ignores a malformed checksum and falls back to the URL key', () {
    final source = MediaSource(pageUri, checksumSha256: 'not-a-sha');
    expect(source.checksumSha256, isNull);
    expect(source.isVerifiable, isFalse);
  });

  test('retainOnly deletes unreferenced checksum files only', () async {
    final cache = LocalMediaCacheService(directoryProvider: () async => root);
    final directory = Directory(path.join(root.path, 'media_cache', 'audio'));
    await directory.create(recursive: true);
    final kept = File(path.join(directory.path, '${'a' * 64}.m4a'));
    final stale = File(path.join(directory.path, '${'b' * 64}.m4a'));
    final urlKeyed = File(path.join(directory.path, '0123abcd-file'));
    for (final file in [kept, stale, urlKeyed]) {
      await file.writeAsString('x');
    }

    await cache.retainOnly({'a' * 64}, [MediaType.audio, MediaType.sheetMusic]);

    expect(await kept.exists(), isTrue);
    expect(await stale.exists(), isFalse);
    expect(await urlKeyed.exists(), isTrue);
  });
}
