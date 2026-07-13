import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/main.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

void main() {
  testWidgets('MyApp renders without the template counter',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'onboarding_completed': false,
      'selected_language': 'am',
      'selected_version': 'hymnal',
      'sort_type': 'number',
    });
    await di.initDependencies(startDatabase: false);

    await tester.pumpWidget(const MyApp(loadInitialHymns: false));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
