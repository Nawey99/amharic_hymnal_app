import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/data/repositories/settings_repository_impl.dart';
import 'package:amharic_hymnal_app/core/error/exceptions.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/data/repositories/hymn_repository_impl.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';

import '../../../../helpers/fakes.dart';

/// Answers each edition only when the test says so, the way a first sync of
/// one edition can take seconds while another is already on the phone.
class _HeldSource extends FakeHymnLocalDataSource {
  _HeldSource(super.content);

  final Map<String, Completer<void>> held = {};

  void hold(String version) => held[version] = Completer<void>();
  void release(String version) => held.remove(version)?.complete();

  @override
  Future<List<HymnModel>> getHymns(String languageCode, String version) async {
    await held[version]?.future;
    return super.getHymns(languageCode, version);
  }
}

void main() {
  late _HeldSource source;
  late SettingsRepositoryImpl settings;

  HymnsBloc build() {
    final repository = HymnRepositoryImpl(source);
    return HymnsBloc(
      getHymns: GetHymns(repository),
      searchHymns: SearchHymns(repository),
      getHymnByNumber: GetHymnByNumber(repository),
      settingsRepository: settings,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({'selected_version': 'sda_new'});
    await SettingsService.init();
    settings = SettingsRepositoryImpl();
    source = _HeldSource({
      'sda_new': sampleHymns(count: 3),
      'sda_1960': sampleHymns(count: 2, prefix: 'am-sda-1961'),
    });
  });

  group('a slow answer never overwrites a newer one', () {
    test('switching editions twice shows the second', () async {
      final bloc = build();
      addTearDown(bloc.close);

      source.hold('sda_1960');
      bloc.add(ChangeVersion('am', 'sda_1960', 'number'));
      await pumpEventQueue();
      bloc.add(ChangeVersion('am', 'sda_new', 'number'));
      await pumpEventQueue();
      expect((bloc.state as HymnsLoaded).version, 'sda_new');

      // The first switch's sync finally finishes.
      source.release('sda_1960');
      await pumpEventQueue();

      expect(settings.getSelectedVersion(), 'sda_new');
      final state = bloc.state as HymnsLoaded;
      expect(state.version, 'sda_new');
      expect(state.hymns, hasLength(3));
    });

    test('a load overtaken by an edition switch is dropped', () async {
      final bloc = build();
      addTearDown(bloc.close);

      source.hold('sda_1960');
      bloc.add(LoadHymns('am', 'sda_1960', 'number'));
      await pumpEventQueue();
      bloc.add(ChangeVersion('am', 'sda_new', 'number'));
      await pumpEventQueue();
      source.release('sda_1960');
      await pumpEventQueue();

      expect((bloc.state as HymnsLoaded).version, 'sda_new');
    });

    test('search results that arrive after leaving the search are dropped',
        () async {
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(LoadHymns('am', 'sda_new', 'number'));
      await pumpEventQueue();

      source.hold('sda_new');
      bloc.add(SearchHymnsEvent('am', 'sda_new', 'መዝሙር 2'));
      await pumpEventQueue();
      // The reader leaves; the tab asks for the whole book again. Then both
      // answers arrive, the search's first.
      bloc.add(LoadHymns('am', 'sda_new', 'name', forceRefresh: true));
      await pumpEventQueue();
      source.release('sda_new');
      await pumpEventQueue();

      expect((bloc.state as HymnsLoaded).sortType, 'name');
    });

    test('a search does not blank every tab with a spinner', () async {
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(LoadHymns('am', 'sda_new', 'number'));
      await pumpEventQueue();

      final states = <HymnsState>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);
      bloc.add(SearchHymnsEvent('am', 'sda_new', 'መዝሙር 2'));
      await pumpEventQueue();

      expect(states.whereType<HymnsLoading>(), isEmpty);
      expect((bloc.state as HymnsLoaded).sortType, 'search');
    });
  });

  group('favourites go to the edition the hymn came from', () {
    test('even when another edition is selected', () async {
      final bloc = build();
      addTearDown(bloc.close);
      bloc.add(LoadHymns('am', 'sda_1960', 'number'));
      await pumpEventQueue();
      expect(settings.getSelectedVersion(), 'sda_new');

      // The hymn page sends the song ID of the hymn on screen.
      final hymn = (bloc.state as HymnsLoaded).hymns[1];
      bloc.add(ToggleFavorite(hymn.songIdIn('sda_1960')));
      await pumpEventQueue();

      expect(settings.getFavoriteSongIds(), ['am-sda-1961-0002']);
      expect(settings.isFavoriteSong('am-sda-2004-0002'), isFalse);
      expect((bloc.state as HymnsLoaded).hymns[1].isFavorite, isTrue);
    });
  });

  group('errors say which case they are', () {
    test('a withdrawn edition', () async {
      source.error = EditionUnavailableException('am-sda-1961');
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(LoadHymns('am', 'sda_1960', 'number'));
      await pumpEventQueue();

      expect(
          (bloc.state as HymnsError).kind, HymnsErrorKind.editionUnavailable);
    });

    test('a number the book does not have', () async {
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(GetHymnByNumberEvent('am', 'sda_new', 99));
      await pumpEventQueue();

      final state = bloc.state as HymnsError;
      expect(state.kind, HymnsErrorKind.notFound);
      expect(state.number, 99);
    });

    test('a lookup that fails for another reason is not "not found"', () async {
      source.error = StateError('disk unreadable');
      final bloc = build();
      addTearDown(bloc.close);

      bloc.add(GetHymnByNumberEvent('am', 'sda_new', 1));
      await pumpEventQueue();

      expect((bloc.state as HymnsError).kind, HymnsErrorKind.lookupFailed);
    });
  });
}
