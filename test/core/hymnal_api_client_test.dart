import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:amharic_hymnal_app/core/services/app_update_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_client.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';

final _uri = Uri.parse('https://api.example.test/api/v1/hymn-versions');

void main() {
  group('HymnalApiClient', () {
    test('sends the stored ETag and reuses the body on 304', () async {
      final seen = <String?>[];
      final api = HymnalApiClient(
        client: MockClient((request) async {
          seen.add(request.headers['If-None-Match']);
          return seen.length == 1
              ? http.Response('{"success":true,"data":[1]}', 200,
                  headers: {'etag': '"v1"'})
              : http.Response('', 304);
        }),
      );

      final first = await api.get(_uri,
          timeout: const Duration(seconds: 1), conditional: true);
      final second = await api.get(_uri,
          timeout: const Duration(seconds: 1), conditional: true);

      expect(seen, [null, '"v1"']);
      expect(second.statusCode, 200);
      expect(second.body, first.body);
    });

    test('waits out a rate limit instead of retrying at once', () async {
      var now = DateTime.utc(2026, 9, 21, 12);
      var calls = 0;
      final api = HymnalApiClient(
        clock: () => now,
        client: MockClient((_) async {
          calls++;
          return http.Response(
            '{"success":false,"error":{"code":"RATE_LIMIT_EXCEEDED","message":"x"}}',
            429,
            headers: {'ratelimit': '"60-in-1min"; r=0; t=30'},
          );
        }),
      );

      await api.get(_uri, timeout: const Duration(seconds: 1));
      await expectLater(
        api.get(_uri, timeout: const Duration(seconds: 1)),
        throwsA(isA<HymnalApiException>()
            .having((e) => e.code, 'code', 'RATE_LIMIT_EXCEEDED')),
      );
      expect(calls, 1);

      now = now.add(const Duration(seconds: 31));
      await api.get(_uri, timeout: const Duration(seconds: 1));
      expect(calls, 2);
    });

    test('reads the wait from RateLimit or Retry-After, capped', () {
      expect(
        HymnalApiClient.retryDelay(
            http.Response('', 429, headers: {'ratelimit': '"x"; r=0; t=12'})),
        const Duration(seconds: 12),
      );
      expect(
        HymnalApiClient.retryDelay(
            http.Response('', 503, headers: {'retry-after': '5'})),
        const Duration(seconds: 5),
      );
      expect(
        HymnalApiClient.retryDelay(
            http.Response('', 503, headers: {'retry-after': '99999'})),
        HymnalApiClient.maxBackoff,
      );
      expect(HymnalApiClient.retryDelay(http.Response('', 429)), isNull);
    });
  });

  group('AppUpdateService', () {
    AppUpdateService serviceWith(String? minimum, String current) =>
        AppUpdateService(
          baseUrl: 'https://api.example.test/api/v1',
          currentVersion: () async => current,
          client: MockClient((request) async {
            expect(request.url.path, '/api/v1/manifest');
            final value = minimum == null ? 'null' : '"$minimum"';
            return http.Response(
              '{"success":true,"data":{"release":{"minimumAppVersion":$value}}}',
              200,
            );
          }),
        );

    test('asks for an update only when this build is older', () async {
      expect(await serviceWith('1.4.0', '1.3.9').requiredVersion('am-sda-2004'),
          '1.4.0');
      expect(await serviceWith('1.4.0', '1.4.0').requiredVersion('am-sda-2004'),
          isNull);
      expect(await serviceWith(null, '0.0.1').requiredVersion('am-sda-2004'),
          isNull);
    });

    test('compares dotted versions numerically', () {
      expect(
          AppUpdateService.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(AppUpdateService.compareVersions('1.0', '1.0.0'), 0);
      expect(AppUpdateService.compareVersions('1.0.0+7', '1.0.1'), lessThan(0));
    });
  });
}
