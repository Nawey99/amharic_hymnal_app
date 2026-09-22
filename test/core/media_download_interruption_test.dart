import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';

/// Streams [chunks], then fails with [error] if given, like a connection
/// that drops part-way.
class _DroppingClient extends http.BaseClient {
  _DroppingClient(this.chunks, {this.error, this.contentLength});

  final List<List<int>> chunks;
  final Object? error;
  final int? contentLength;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final controller = StreamController<List<int>>();
    Future(() async {
      for (final chunk in chunks) {
        controller.add(chunk);
      }
      if (error != null) controller.addError(error!);
      await controller.close();
    });
    return http.StreamedResponse(controller.stream, 200,
        contentLength: contentLength);
  }
}

void main() {
  late Directory root;
  final bytes = List<int>.generate(4000, (i) => i % 251);
  final checksum = sha256.convert(bytes).toString();
  final uri = Uri.parse('https://api.example.test/api/v1/songs/x/audio/file');

  setUp(() async {
    root = await Directory.systemTemp.createTemp('media_interrupt');
  });
  tearDown(() => root.delete(recursive: true));

  Future<List<String>> filesLeft() async {
    final directory = Directory('${root.path}/media_cache/${MediaType.audio}');
    if (!await directory.exists()) return const [];
    return [
      for (final entity in directory.listSync()) entity.uri.pathSegments.last,
    ];
  }

  LocalMediaCacheService cacheWith(http.Client client) =>
      LocalMediaCacheService(
          client: client, directoryProvider: () async => root);

  test('a connection dropped part-way leaves no file and no .part', () async {
    final cache = cacheWith(_DroppingClient(
      [bytes.sublist(0, 1000), bytes.sublist(1000, 2000)],
      error: const SocketException('Connection reset by peer'),
      contentLength: bytes.length,
    ));
    final source = MediaSource(uri,
        checksumSha256: checksum,
        sizeBytes: bytes.length,
        contentType: 'audio/mp4');

    await expectLater(cache.download(source, MediaType.audio),
        throwsA(isA<SocketException>()));

    expect(await filesLeft(), isEmpty);
    expect(await cache.cachedPath(source, MediaType.audio), isNull);
  });

  test('a response that ends early is rejected, not cached', () async {
    final cache = cacheWith(_DroppingClient(
      [bytes.sublist(0, 1500)],
      contentLength: bytes.length,
    ));
    final source = MediaSource(uri, checksumSha256: checksum);

    await expectLater(cache.download(source, MediaType.audio),
        throwsA(isA<FileSystemException>()));
    expect(await filesLeft(), isEmpty);
  });

  test('retrying after an interruption downloads a verified copy', () async {
    final source = MediaSource(uri,
        checksumSha256: checksum,
        sizeBytes: bytes.length,
        contentType: 'audio/mp4');
    await expectLater(
      cacheWith(_DroppingClient([bytes.sublist(0, 10)],
              error: const SocketException('reset')))
          .download(source, MediaType.audio),
      throwsA(isA<SocketException>()),
    );

    final file = await cacheWith(
            _DroppingClient([bytes.sublist(0, 2000), bytes.sublist(2000)]))
        .download(source, MediaType.audio);

    expect(await File(file.path).readAsBytes(), bytes);
    expect(await filesLeft(), ['$checksum.m4a']);
  });

  test('a cached file of the wrong size is discarded, not played', () async {
    final source = MediaSource(uri,
        checksumSha256: checksum,
        sizeBytes: bytes.length,
        contentType: 'audio/mp4');
    final directory = Directory('${root.path}/media_cache/${MediaType.audio}');
    await directory.create(recursive: true);
    await File('${directory.path}/$checksum.m4a')
        .writeAsBytes(bytes.sublist(0, 5));

    expect(
        await cacheWith(_DroppingClient(const []))
            .cachedPath(source, MediaType.audio),
        isNull);
    expect(await filesLeft(), isEmpty);
  });
}
