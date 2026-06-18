import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/pages/donate_page.dart';

void main() {
  testWidgets('PayPal donation shows coming soon dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DonatePage()));

    await tester.tap(find.text('PayPal'));
    await tester.pumpAndSettle();

    expect(find.text('PayPal donations are coming soon.'), findsOneWidget);
  });

  testWidgets('National Bank page exposes copyable fields', (tester) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(const MaterialApp(home: DonatePage()));

    await tester.tap(find.text('National Bank'));
    await tester.pumpAndSettle();

    expect(find.text('National Bank'), findsWidgets);
    expect(
      find.textContaining('Bank transfer details are prepared'),
      findsOneWidget,
    );
    expect(find.byTooltip('Copy'), findsWidgets);

    await tester.tap(find.byTooltip('Copy').first);
    await tester.pumpAndSettle();

    expect(copiedText, 'National Bank of Ethiopia');
    expect(find.text('Bank copied'), findsOneWidget);
  });
}
