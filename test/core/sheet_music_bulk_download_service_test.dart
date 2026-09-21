import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/sheet_music_bulk_download_service.dart';

class FakeMediaCache implements MediaCache {
  final Set<String> stored = {};
  final Set<String> failing = {};

  @override
  Future<String?> cachedPath(MediaSource source, String mediaType) async =>
      stored.contains(source.checksumSha256) ? '/cache/x' : null;

  @override
  Future<CachedMediaFile> download(
    MediaSource source,
    String mediaType, {
    void Function(int received, int? total)? onProgress,
  }) async {
    if (failing.contains(source.checksumSha256)) {
      throw MediaIntegrityException(source.uri, 'bad');
    }
    stored.add(source.checksumSha256!);
    return const CachedMediaFile(path: '/cache/x', bytes: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _page(String checksum, {int size = 100}) => {
      'downloadUrl': 'https://api.example.test/p/$checksum',
      'checksumSha256': checksum,
      'sizeBytes': size,
      'contentType': 'image/webp',
    };

void main() {
  final a = 'a' * 64, b = 'b' * 64, c = 'c' * 64;
  late FakeMediaCache cache;

  SheetMusicBulkDownloadService serviceWith(List<Map<String, dynamic>> pages) =>
      SheetMusicBulkDownloadService(
        baseUrl: 'https://api.example.test/api/v1',
        cache: cache,
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/downloads/sheet-music/pages');
          expect(request.url.queryParameters['version'], 'am-sda-2004');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'pageCount': pages.length, 'pages': pages},
            }),
            200,
          );
        }),
      );

  setUp(() => cache = FakeMediaCache());

  test('plans only missing files and counts a shared sheet once', () async {
    cache.stored.add(a);
    final service = serviceWith([
      _page(a),
      _page(b, size: 300),
      _page(b, size: 300), // one sheet printing two hymns
      _page(c, size: 200),
    ]);

    final plan = await service.plan('am-sda-2004');

    expect(plan.pageCount, 4);
    expect(plan.missing.map((s) => s.checksumSha256), [b, c]);
    expect(plan.missingBytes, 500);
  });

  test('a failed page is skipped, not fatal', () async {
    cache.failing.add(b);
    final service = serviceWith([_page(a), _page(b), _page(c)]);
    final plan = await service.plan('am-sda-2004');
    final progress = <int>[];

    final result = await service.download(
      plan,
      onProgress: (done, total) => progress.add(done),
    );

    expect(result.downloaded, 2);
    expect(result.failed, 1);
    expect(result.cancelled, isFalse);
    expect(progress.last, 3);
    expect(cache.stored, {a, c});
  });

  test('stops when cancelled', () async {
    final service = serviceWith([_page(a), _page(b), _page(c)]);
    final plan = await service.plan('am-sda-2004');

    final result = await service.download(plan, isCancelled: () => true);

    expect(result.cancelled, isTrue);
    expect(result.downloaded, 0);
    expect(cache.stored, isEmpty);
  });
}
