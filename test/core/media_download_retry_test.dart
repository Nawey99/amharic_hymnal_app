import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/error/network_failure.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';

void main() {
  late Directory root;
  final bytes = List<int>.generate(4000, (i) => i % 251);
  final checksum = sha256.convert(bytes).toString();
  final uri = Uri.parse('https://api.example.test/api/v1/songs/x/audio/file');
  final source = MediaSource(
    uri,
    checksumSha256: checksum,
    sizeBytes: bytes.length,
    contentType: 'audio/mp4',
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('media_retry');
  });
  tearDown(() => root.delete(recursive: true));

  /// Fails the first [failures] requests the way a phone with a signal but
  /// no working data does, then answers with the file.
  (LocalMediaCacheService, int Function()) cacheFailing(
    int failures, {
    Object Function()? error,
  }) {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      if (requests <= failures) {
        throw error?.call() ??
            const SocketException('Connection reset by peer');
      }
      return http.Response.bytes(bytes, 200);
    });
    return (
      LocalMediaCacheService(
        client: client,
        directoryProvider: () async => root,
        retryDelay: Duration.zero,
      ),
      () => requests,
    );
  }

  test('a connection that drops once is tried again and the file arrives',
      () async {
    final (cache, requests) = cacheFailing(1);

    final file = await cache.download(source, MediaType.audio);

    expect(requests(), 2);
    expect(await File(file.path).readAsBytes(), bytes);
  });

  test('with no internet it gives up after one retry and leaves nothing',
      () async {
    final (cache, requests) = cacheFailing(5);

    await expectLater(
      cache.download(source, MediaType.audio),
      throwsA(predicate(isNetworkFailure)),
    );

    expect(requests(), 2);
    expect(await cache.cachedPath(source, MediaType.audio), isNull);
  });

  test('a server that answers with an error is not tried again', () async {
    var requests = 0;
    final cache = LocalMediaCacheService(
      client: MockClient((request) async {
        requests++;
        return http.Response('', 404);
      }),
      directoryProvider: () async => root,
      retryDelay: Duration.zero,
    );

    await expectLater(
      cache.download(source, MediaType.audio),
      throwsA(isA<HttpException>()),
    );
    expect(requests, 1);
  });

  test('what counts as a network failure', () {
    expect(isNetworkFailure(const SocketException('reset')), isTrue);
    expect(isNetworkFailure(http.ClientException('closed')), isTrue);
    expect(isNetworkFailure(const HttpException('HTTP 500')), isFalse);
    expect(isNetworkFailure(StateError('no audio')), isFalse);
  });
}
