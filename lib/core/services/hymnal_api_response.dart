import 'dart:convert';

import 'package:http/http.dart' as http;

/// An error answered by the hymnal API. Branch on [code], which is stable;
/// [message] is for logs only.
class HymnalApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const HymnalApiException(this.statusCode, this.code, this.message);

  @override
  String toString() => 'HymnalApiException($statusCode $code): $message';
}

/// Returns `data` from a `{ success, data }` response, or throws
/// [HymnalApiException] for `{ success: false, error }` and non-200 answers.
Object? decodeHymnalApiData(http.Response response) {
  final Object? body;
  try {
    body = jsonDecode(utf8.decode(response.bodyBytes));
  } on FormatException {
    throw HymnalApiException(
      response.statusCode,
      'INVALID_RESPONSE',
      'Response was not JSON.',
    );
  }

  if (body is! Map<String, dynamic>) {
    throw HymnalApiException(
      response.statusCode,
      'INVALID_RESPONSE',
      'Response was not a JSON object.',
    );
  }

  if (response.statusCode != 200 || body['success'] != true) {
    final error = body['error'];
    throw HymnalApiException(
      response.statusCode,
      error is Map ? '${error['code'] ?? 'UNKNOWN'}' : 'UNKNOWN',
      error is Map ? '${error['message'] ?? ''}' : '',
    );
  }

  return body['data'];
}
