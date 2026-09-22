import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/search_state_controller.dart';

void main() {
  late SearchStateController controller;
  late List<String> emitted;

  void run(void Function(FakeAsync async) body) {
    fakeAsync((async) {
      controller = SearchStateController();
      emitted = [];
      controller.queryStream.listen(emitted.add);
      body(async);
      controller.dispose();
      async.flushMicrotasks();
    });
  }

  test('emits a query only after 350 ms without typing', () {
    run((async) {
      controller.updateQuery('ጌ');
      async.elapse(const Duration(milliseconds: 349));
      expect(emitted, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(emitted, ['ጌ']);
    });
  });

  test('typing restarts the wait and only the last text is searched', () {
    run((async) {
      controller.updateQuery('ጌ');
      async.elapse(const Duration(milliseconds: 200));
      controller.updateQuery('ጌታ');
      async.elapse(const Duration(milliseconds: 200));
      controller.updateQuery('ጌታ ሆይ');
      async.elapse(const Duration(milliseconds: 349));
      expect(emitted, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(emitted, ['ጌታ ሆይ']);
      expect(controller.currentQuery, 'ጌታ ሆይ');
    });
  });

  test('clearing the text emits at once and cancels a pending search', () {
    run((async) {
      controller.updateQuery('ፍቅር');
      async.elapse(const Duration(milliseconds: 100));
      controller.updateQuery('');
      async.flushMicrotasks();
      expect(emitted, ['']);
      expect(controller.currentQuery, '');

      async.elapse(const Duration(seconds: 1));
      expect(emitted, ['']);
    });
  });

  test('clear() emits at once and cancels a pending search', () {
    run((async) {
      controller.updateQuery('ፍቅር');
      controller.clear();
      async.flushMicrotasks();
      expect(emitted, ['']);

      async.elapse(const Duration(seconds: 1));
      expect(emitted, ['']);
    });
  });

  test('separate pauses emit each query', () {
    run((async) {
      controller.updateQuery('ሰላም');
      async.elapse(const Duration(milliseconds: 400));
      controller.updateQuery('ሰላም ለ');
      async.elapse(const Duration(milliseconds: 400));
      expect(emitted, ['ሰላም', 'ሰላም ለ']);
    });
  });

  test('dispose cancels a pending search', () {
    fakeAsync((async) {
      final controller = SearchStateController();
      final emitted = <String>[];
      controller.queryStream.listen(emitted.add);
      controller.updateQuery('ጌታ');
      controller.dispose();
      async.elapse(const Duration(seconds: 1));
      expect(emitted, isEmpty);
    });
  });
}
