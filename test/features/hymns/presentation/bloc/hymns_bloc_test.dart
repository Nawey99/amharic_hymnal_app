import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/data/repositories/settings_repository_impl.dart';
import 'package:amharic_hymnal_app/core/error/exceptions.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/data/repositories/hymn_repository_impl.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';

import '../../../../helpers/fakes.dart';

/// A data source whose answer waits until [release] is called, so tests can
/// dispatch a second event while the first is still loading.
class GatedHymnLocalDataSource extends FakeHymnLocalDataSource {
  GatedHymnLocalDataSource(super.content);

  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<List<HymnModel>> getHymns(String languageCode, String version) async {
    requestedVersions.add(version);
    await _gate.future;
    return content[version] ?? const [];
  }
}

const _audio = HymnAudioInfo(
  file: HymnMediaFile(url: 'https://api.example.test/a/2', sizeBytes: 10),
  isSynthesized: true,
);
const _page = HymnSheetPage(
  file: HymnMediaFile(url: 'https://api.example.test/p/2'),
  pageNumber: 1,
  borrowedFromVersionCode: 'am-sda-2004',
);

List<HymnModel> _book2004() => [
      ...sampleHymns(count: 3),
      const HymnModel(
        id: 'am-sda-2004-0004',
        number: 4,
        title: 'ፍቅር ነው',
        lyrics: 'እግዚአብሔር ፍቅር ነው',
        audioUrl: 'https://api.example.test/a/2',
        audioInfo: _audio,
        sheetMusic: ['https://api.example.test/p/2'],
        sheetPages: [_page],
      ),
    ];

List<HymnModel> _book1975() =>
    sampleHymns(count: 2, prefix: 'am-sda-1975').map((hymn) {
      return HymnModel(
        id: hymn.id,
        number: hymn.number,
        title: '1975 ${hymn.title}',
        lyrics: hymn.lyrics,
      );
    }).toList();

void main() {
  late FakeHymnLocalDataSource source;
  late SettingsRepositoryImpl settings;

  HymnsBloc buildBloc([FakeHymnLocalDataSource? dataSource]) {
    final repository = HymnRepositoryImpl(dataSource ?? source);
    return HymnsBloc(
      getHymns: GetHymns(repository),
      searchHymns: SearchHymns(repository),
      getHymnByNumber: GetHymnByNumber(repository),
      settingsRepository: settings,
    );
  }

  List<int> numbersOf(HymnsState state) =>
      (state as HymnsLoaded).hymns.map((hymn) => hymn.displayNumber).toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'selected_language': 'am',
      'selected_version': 'sda_new',
      'sort_type': 'number',
    });
    await SettingsService.init();
    settings = SettingsRepositoryImpl();
    source = FakeHymnLocalDataSource({
      'sda_new': _book2004(),
      'sda_old': _book1975(),
    });
  });

  group('LoadHymns', () {
    blocTest<HymnsBloc, HymnsState>(
      'loads the edition sorted as asked',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadHymns('am', 'sda_new', 'number')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsLoaded>()
            .having((s) => s.version, 'version', 'sda_new')
            .having((s) => s.sortType, 'sortType', 'number')
            .having(numbersOf, 'numbers', [1, 2, 3, 4]),
      ],
    );

    blocTest<HymnsBloc, HymnsState>(
      'does nothing when the same edition and sort are already loaded',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(LoadHymns('am', 'sda_new', 'number'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(LoadHymns('am', 'sda_new', 'number'));
      },
      expect: () => [isA<HymnsLoading>(), isA<HymnsLoaded>()],
      verify: (_) => expect(source.requestedVersions, ['sda_new']),
    );

    blocTest<HymnsBloc, HymnsState>(
      'ignores a duplicate request while the first is still loading',
      build: () => buildBloc(source = GatedHymnLocalDataSource(source.content)),
      act: (bloc) async {
        bloc.add(LoadHymns('am', 'sda_new', 'number'));
        bloc.add(LoadHymns('am', 'sda_new', 'number'));
        await Future<void>.delayed(Duration.zero);
        (source as GatedHymnLocalDataSource).release();
      },
      expect: () => [isA<HymnsLoading>(), isA<HymnsLoaded>()],
      verify: (_) => expect(source.requestedVersions, ['sda_new']),
    );

    blocTest<HymnsBloc, HymnsState>(
      'a forced refresh reloads without a spinner',
      build: buildBloc,
      seed: () => HymnsLoaded(_book2004(), 'number'),
      act: (bloc) =>
          bloc.add(LoadHymns('am', 'sda_new', 'number', forceRefresh: true)),
      expect: () => [isA<HymnsLoaded>()],
      verify: (_) => expect(source.requestedVersions, ['sda_new']),
    );

    blocTest<HymnsBloc, HymnsState>(
      'a failed forced refresh keeps the hymns already shown',
      build: () {
        source.error = Exception('offline');
        return buildBloc();
      },
      seed: () => HymnsLoaded(_book2004(), 'number'),
      act: (bloc) =>
          bloc.add(LoadHymns('am', 'sda_new', 'number', forceRefresh: true)),
      expect: () => const <HymnsState>[],
    );

    blocTest<HymnsBloc, HymnsState>(
      'a failed first load shows an error instead of loading forever',
      build: () {
        source.error = Exception('corrupt bundle');
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHymns('am', 'sda_new', 'number')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsError>().having((s) => s.message, 'message',
            'Hymns could not be loaded. Please try again.'),
      ],
    );

    blocTest<HymnsBloc, HymnsState>(
      'an online-only edition asks for a connection',
      build: () {
        source.error = DatabaseNotFoundException('No offline database');
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHymns('am', 'sda_1960', 'number')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsError>().having(
          (s) => s.message,
          'message',
          'This hymnal needs an internet connection to load. '
              'Please connect and try again.',
        ),
      ],
    );

    blocTest<HymnsBloc, HymnsState>(
      'can load again after a failure',
      build: buildBloc,
      act: (bloc) async {
        source.error = Exception('offline');
        bloc.add(LoadHymns('am', 'sda_new', 'number'));
        await Future<void>.delayed(Duration.zero);
        source.error = null;
        bloc.add(LoadHymns('am', 'sda_new', 'number'));
      },
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsError>(),
        isA<HymnsLoading>(),
        isA<HymnsLoaded>(),
      ],
    );
  });

  group('SearchHymnsEvent', () {
    blocTest<HymnsBloc, HymnsState>(
      'finds hymns and keeps the search order',
      build: buildBloc,
      act: (bloc) => bloc.add(SearchHymnsEvent('am', 'sda_new', 'ፍቅር')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsLoaded>()
            .having((s) => s.sortType, 'sortType', 'search')
            .having(numbersOf, 'numbers', [4]),
      ],
    );

    blocTest<HymnsBloc, HymnsState>(
      'an empty query reloads the edition with the saved sort',
      build: () {
        SettingsService.setSortType('name');
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchHymnsEvent('am', 'sda_new', '')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsLoaded>().having((s) => s.sortType, 'sortType', 'name'),
      ],
    );

    blocTest<HymnsBloc, HymnsState>(
      'a failed search says so',
      build: () {
        source.error = Exception('offline');
        return buildBloc();
      },
      act: (bloc) => bloc.add(SearchHymnsEvent('am', 'sda_new', 'ፍቅር')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsError>()
            .having((s) => s.message, 'message', 'Failed to search hymns.'),
      ],
    );
  });

  group('ChangeLanguage', () {
    blocTest<HymnsBloc, HymnsState>(
      'saves the language and version, then loads that edition',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeLanguage('am', 'sda_old', 'number')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsLoaded>()
            .having((s) => s.version, 'version', 'sda_old')
            .having(numbersOf, 'numbers', [1, 2]),
      ],
      verify: (_) {
        expect(settings.getSelectedLanguage(), 'am');
        expect(settings.getSelectedVersion(), 'sda_old');
      },
    );

    blocTest<HymnsBloc, HymnsState>(
      'a failure shows an error',
      build: () {
        source.error = Exception('offline');
        return buildBloc();
      },
      act: (bloc) => bloc.add(ChangeLanguage('am', 'sda_old', 'number')),
      expect: () => [isA<HymnsLoading>(), isA<HymnsError>()],
    );
  });

  group('ChangeVersion', () {
    blocTest<HymnsBloc, HymnsState>(
      'saves the version and loads that edition',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeVersion('am', 'sda_old', 'number')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsLoaded>()
            .having((s) => s.version, 'version', 'sda_old')
            .having((s) => s.hymns.first.title, 'first title', '1975 መዝሙር 1'),
      ],
      verify: (_) => expect(settings.getSelectedVersion(), 'sda_old'),
    );

    blocTest<HymnsBloc, HymnsState>(
      'an online-only edition asks for a connection',
      build: () {
        source.error = DatabaseNotFoundException('No offline database');
        return buildBloc();
      },
      act: (bloc) => bloc.add(ChangeVersion('am', 'sda_1960', 'number')),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsError>().having(
            (s) => s.message, 'message', contains('internet connection')),
      ],
      verify: (_) => expect(settings.getSelectedVersion(), 'sda_1960'),
    );
  });

  group('ChangeSort', () {
    blocTest<HymnsBloc, HymnsState>(
      'saves the sort and re-sorts the loaded hymns',
      build: buildBloc,
      seed: () => HymnsLoaded(_book2004(), 'number'),
      act: (bloc) => bloc.add(ChangeSort('am', 'sda_new', 'name')),
      expect: () => [
        isA<HymnsLoaded>().having((s) => s.sortType, 'sortType', 'name'),
      ],
      verify: (_) {
        expect(settings.getSortType(), 'name');
        expect(source.requestedVersions, isEmpty);
      },
    );

    blocTest<HymnsBloc, HymnsState>(
      'does nothing when the sort is unchanged',
      build: buildBloc,
      seed: () => HymnsLoaded(_book2004(), 'number'),
      act: (bloc) => bloc.add(ChangeSort('am', 'sda_new', 'number')),
      expect: () => const <HymnsState>[],
    );

    blocTest<HymnsBloc, HymnsState>(
      'does nothing before hymns are loaded',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeSort('am', 'sda_new', 'name')),
      expect: () => const <HymnsState>[],
    );
  });

  group('ToggleFavorite', () {
    blocTest<HymnsBloc, HymnsState>(
      'marks only that hymn and keeps its media details',
      build: buildBloc,
      seed: () => HymnsLoaded(_book2004(), 'number'),
      act: (bloc) => bloc.add(ToggleFavorite(4)),
      expect: () => [
        isA<HymnsLoaded>().having(
          (s) => [for (final h in s.hymns) h.isFavorite],
          'favorites',
          [false, false, false, true],
        ).having(
          (s) => s.hymns.last,
          'hymn 4',
          isA<Hymn>()
              .having((h) => h.audioInfo, 'audioInfo', _audio)
              .having((h) => h.sheetPages, 'sheetPages', [_page]).having(
                  (h) => h.id, 'id', 'am-sda-2004-0004'),
        ),
      ],
      verify: (_) => expect(settings.isFavorite(4), isTrue),
    );

    blocTest<HymnsBloc, HymnsState>(
      'toggling twice unmarks it',
      build: buildBloc,
      seed: () => HymnsLoaded(_book2004(), 'number'),
      act: (bloc) async {
        bloc.add(ToggleFavorite(2));
        await Future<void>.delayed(Duration.zero);
        bloc.add(ToggleFavorite(2));
      },
      skip: 1,
      expect: () => [
        isA<HymnsLoaded>().having(
            (s) => s.hymns.any((h) => h.isFavorite), 'any favorite', isFalse),
      ],
      verify: (_) => expect(settings.isFavorite(2), isFalse),
    );

    test('favorites are kept per edition', () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(ToggleFavorite(1));
      await Future<void>.delayed(Duration.zero);
      expect(settings.isFavorite(1, version: 'sda_new'), isTrue);

      await settings.setSelectedVersion('sda_old');
      expect(settings.isFavorite(1), isFalse);
      bloc.add(ToggleFavorite(1));
      await Future<void>.delayed(Duration.zero);

      expect(settings.isFavorite(1, version: 'sda_old'), isTrue);
      expect(settings.isFavorite(1, version: 'sda_new'), isTrue);
    });

    blocTest<HymnsBloc, HymnsState>(
      'is saved even before hymns are loaded',
      build: buildBloc,
      act: (bloc) => bloc.add(ToggleFavorite(3)),
      expect: () => const <HymnsState>[],
      verify: (_) => expect(settings.isFavorite(3), isTrue),
    );
  });

  group('GetHymnByNumberEvent', () {
    blocTest<HymnsBloc, HymnsState>(
      'finds the hymn by its number',
      build: buildBloc,
      act: (bloc) => bloc.add(GetHymnByNumberEvent('am', 'sda_new', 3)),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsLoaded>()
            .having((s) => s.sortType, 'sortType', 'number')
            .having(numbersOf, 'numbers', [3]),
      ],
    );

    blocTest<HymnsBloc, HymnsState>(
      'says when the number is not in the edition',
      build: buildBloc,
      act: (bloc) => bloc.add(GetHymnByNumberEvent('am', 'sda_new', 99)),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsError>()
            .having((s) => s.message, 'message', 'Hymn #99 not found.'),
      ],
    );

    blocTest<HymnsBloc, HymnsState>(
      'says not found when the edition cannot load',
      build: () {
        source.error = Exception('offline');
        return buildBloc();
      },
      act: (bloc) => bloc.add(GetHymnByNumberEvent('am', 'sda_new', 1)),
      expect: () => [
        isA<HymnsLoading>(),
        isA<HymnsError>()
            .having((s) => s.message, 'message', 'Hymn #1 not found.'),
      ],
    );
  });
}
