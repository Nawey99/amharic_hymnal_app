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
}
