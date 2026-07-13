import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';

void main() {
  test('search sort type preserves ranked repository order', () {
    final state = HymnsLoaded(
      const [
        Hymn(id: 'exact', number: 1, title: 'አምላካችን'),
        Hymn(id: 'partial', number: 11, title: 'አምላካችን ኃይላችን ነው'),
        Hymn(id: 'lyrics', number: 93, title: 'ሰቅዬት ሳለሁ በፈተና ጊዜ'),
      ],
      'search',
    );

    expect(
      state.hymns.map((hymn) => hymn.displayNumber),
      [1, 11, 93],
    );
  });

  test('name sort still sorts alphabetically', () {
    final state = HymnsLoaded(
      const [
        Hymn(id: 'b', number: 2, title: 'Beta'),
        Hymn(id: 'a', number: 1, title: 'Alpha'),
      ],
      'name',
    );

    expect(
      state.hymns.map((hymn) => hymn.displayNumber),
      [1, 2],
    );
  });
}
