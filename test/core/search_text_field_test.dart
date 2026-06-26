import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/services/search_state_controller.dart';
import 'package:amharic_hymnal_app/core/widgets/search_text_field.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

void main() {
  testWidgets('search focus and text survive unrelated rebuilds',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_language': 'am',
      'selected_version': 'sda_new',
      'sort_type': 'number',
    });
    await di.initDependencies(startDatabase: false);

    final controller = SearchStateController();
    final focusNode = FocusNode();
    var rebuildFlag = false;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () => setState(() => rebuildFlag = !rebuildFlag),
                    child: Text('$rebuildFlag'),
                  ),
                  SearchTextField(
                    controller: controller,
                    focusNode: focusNode,
                    hintText: 'ፈልግ',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'አምላካችን');
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byType(TextButton));
    await tester.pump(const Duration(milliseconds: 400));

    expect(focusNode.hasFocus, isTrue);
    expect(find.text('አምላካችን'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
