import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_open_callback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opening a hymn from another tab replaces the previous active hymn', () {
    const numberHymn = Hymn(
      id: 'number-hymn',
      number: 1,
      title: 'Number hymn',
      lyrics: 'Number lyrics',
    );
    const categoryHymn = Hymn(
      id: 'category-hymn',
      number: 2,
      title: 'Category hymn',
      lyrics: 'Category lyrics',
    );
    final session = HymnTabSession();

    session.open(
      hymn: numberHymn,
      sourceDestination: 'number',
      version: 'sda_new',
    );
    session.open(
      hymn: categoryHymn,
      sourceDestination: 'category',
      version: 'sda_new',
    );

    expect(session.hymn, categoryHymn);
    expect(session.owns('category'), isTrue);
    expect(session.owns('number'), isFalse);
  });

  test('adjacent hymn updates preserve the owning tab and version', () {
    const firstHymn = Hymn(
      id: 'first-hymn',
      number: 10,
      title: 'First hymn',
      lyrics: 'First lyrics',
    );
    const nextHymn = Hymn(
      id: 'next-hymn',
      number: 11,
      title: 'Next hymn',
      lyrics: 'Next lyrics',
    );
    final session = HymnTabSession()
      ..open(
        hymn: firstHymn,
        sourceDestination: 'favorites',
        version: 'sda_old',
      )
      ..updateHymn(nextHymn);

    expect(session.hymn, nextHymn);
    expect(session.sourceDestination, 'favorites');
    expect(session.version, 'sda_old');
  });

  test('content refresh replaces the remembered hymn without losing its tab',
      () {
    const original = Hymn(
      id: 'shared-work',
      number: 1,
      title: 'Original title',
      lyrics: 'Original lyrics',
    );
    const edited = Hymn(
      id: 'shared-work',
      number: 1,
      title: 'Edited title',
      lyrics: 'Edited lyrics',
    );
    final session = HymnTabSession()
      ..open(
        hymn: original,
        sourceDestination: 'index',
        version: 'sda_new',
      );

    expect(session.reconcileWith(const [edited], 'sda_new'), isTrue);
    expect(session.hymn, edited);
    expect(session.sourceDestination, 'index');
    expect(session.version, 'sda_new');
    expect(session.reconcileWith(const [edited], 'sda_new'), isFalse);
  });

  test('content refresh forgets a song removed from the selected hymnal', () {
    const removed = Hymn(id: 'removed-work', number: 8);
    final session = HymnTabSession()
      ..open(
        hymn: removed,
        sourceDestination: 'category',
        version: 'sda_old',
      );

    expect(session.reconcileWith(const [], 'sda_old'), isTrue);
    expect(session.hymn, isNull);
    expect(session.sourceDestination, isNull);
    expect(session.version, isNull);
  });
}
