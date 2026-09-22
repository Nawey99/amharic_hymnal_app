import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A scripted hymnal API for tests.
///
/// Register handlers by path suffix (`/hymn-versions/am-sda-2004`, `/sync`,
/// ...). Unmatched requests answer `404 ROUTE_NOT_FOUND`, like the server.
/// Every request is recorded, and [online] = false makes every request fail
/// as it would with no connection.
class FakeHymnalApi {
  FakeHymnalApi({this.baseUrl = 'https://api.example.test/api/v1'});

  final String baseUrl;
  bool online = true;
  final List<http.Request> requests = [];
  final List<({String suffix, http.Response Function(http.Request) handle})>
      _routes = [];

  /// Answers requests whose path ends with [pathSuffix]. Later registrations
  /// win, so a test can override a default.
  void on(String pathSuffix, http.Response Function(http.Request) handle) {
    _routes.insert(0, (suffix: pathSuffix, handle: handle));
  }

  /// Answers [pathSuffix] with `{ success: true, data: [data] }`.
  void ok(String pathSuffix, Object? data, {Map<String, String>? headers}) =>
      on(pathSuffix, (_) => success(data, headers: headers));

  /// Answers [pathSuffix] with an API error envelope.
  void fail(String pathSuffix, int status, String code,
          {Map<String, String>? headers}) =>
      on(pathSuffix, (_) => error(status, code, headers: headers));

  late final MockClient client = MockClient((request) async {
    if (!online) throw http.ClientException('offline', request.url);
    requests.add(request);
    for (final route in _routes) {
      if (request.url.path.endsWith(route.suffix)) return route.handle(request);
    }
    return error(404, 'ROUTE_NOT_FOUND');
  });

  List<http.Request> requestsTo(String pathSuffix) => requests
      .where((request) => request.url.path.endsWith(pathSuffix))
      .toList();

  static http.Response success(Object? data, {Map<String, String>? headers}) =>
      http.Response.bytes(
        utf8.encode(jsonEncode({'success': true, 'data': data})),
        200,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          ...?headers
        },
      );

  static http.Response error(int status, String code,
          {Map<String, String>? headers}) =>
      http.Response(
        jsonEncode({
          'success': false,
          'error': {'code': code, 'message': code},
        }),
        status,
        headers: {'content-type': 'application/json', ...?headers},
      );
}
