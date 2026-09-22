import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';

void main() {
  // Tests are built without WUDASE_CONTENT_API_URL, like store builds, so
  // only the default is testable here. The override's validation runs only
  // with a dart-define and is covered by CI's release builds.
  test('without an override the app uses the production API', () {
    expect(ContentApiConfig.baseUrl, ContentApiConfig.productionBaseUrl);
  });

  test('the production API is HTTPS and includes the version prefix', () {
    final uri = Uri.parse(ContentApiConfig.productionBaseUrl);

    expect(uri.scheme, 'https');
    expect(uri.hasAuthority, isTrue);
    expect(uri.path, '/api/v1');
  });

  test('the base URL has no trailing slash, so paths join cleanly', () {
    expect(ContentApiConfig.baseUrl.endsWith('/'), isFalse);
    expect(Uri.parse('${ContentApiConfig.baseUrl}/hymn-versions').path,
        '/api/v1/hymn-versions');
  });
}
