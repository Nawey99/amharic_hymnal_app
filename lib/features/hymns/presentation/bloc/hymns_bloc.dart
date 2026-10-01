// lib/features/hymns/presentation/bloc/hymns_bloc.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart'
    as usecases;
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/error/failures.dart';

part 'hymns_event.dart';
part 'hymns_state.dart';

/// BLoC for managing hymn-related state and business logic
///
/// Handles:
/// - Loading hymns by language/version
/// - Searching hymns
/// - Changing language/version/sort type
/// - Toggling favorites
/// - Getting hymns by number
///
/// Uses dependency injection for use cases and settings repository.
/// All state changes are emitted through the BLoC pattern.
class HymnsBloc extends Bloc<HymnsEvent, HymnsState> {
  final GetHymns getHymns;
  final usecases.SearchHymns searchHymns;
  final GetHymnByNumber getHymnByNumber;
  final SettingsRepository settingsRepository;

  String? _activeLoadKey;

  /// Bumped by every request that replaces the hymns on screen. Events run
  /// concurrently, so a slow answer (an edition's first sync) can arrive
  /// after a newer one; it is dropped instead of overwriting it.
  int _generation = 0;

  /// Whether a request started at [generation] has been overtaken.
  bool _isStale(int generation) => generation != _generation || isClosed;

  HymnsBloc({
    required this.getHymns,
    required this.searchHymns,
    required this.getHymnByNumber,
    required this.settingsRepository,
  }) : super(HymnsInitial()) {
    on<LoadHymns>(_onLoadHymns);
    on<SearchHymnsEvent>(_onSearchHymns);
    on<ChangeLanguage>(_onChangeLanguage);
    on<ChangeVersion>(_onChangeVersion);
    on<ChangeSort>(_onChangeSort);
    on<ToggleFavorite>(_onToggleFavorite);
    on<GetHymnByNumberEvent>(_onGetHymnByNumber);
  }

  /// Handle failure and return appropriate error state
  HymnsState _handleFailure(Failure failure) {
    if (failure is NetworkFailure) {
      return HymnsError(HymnsErrorKind.needsConnection);
    }
    if (failure is EditionUnavailableFailure) {
      return HymnsError(HymnsErrorKind.editionUnavailable);
    }
    return HymnsError(HymnsErrorKind.loadFailed);
  }

  @override
  Future<void> close() {
    _activeLoadKey = null;
    return super.close();
  }

  Future<void> _onLoadHymns(LoadHymns event, Emitter<HymnsState> emit) async {
    final loadKey = '${event.languageCode}|${event.version}|${event.sortType}';
    final currentState = state;
    if (!event.forceRefresh &&
        currentState is HymnsLoaded &&
        currentState.languageCode == event.languageCode &&
        currentState.version == event.version &&
        currentState.sortType == event.sortType) {
      return;
    }
    if (_activeLoadKey == loadKey) {
      return;
    }

    _activeLoadKey = loadKey;
    final generation = ++_generation;
    if (!event.forceRefresh || currentState is! HymnsLoaded) {
      emit(HymnsLoading());
    }
    final result = await getHymns(GetHymnsParams(
      languageCode: event.languageCode,
      version: event.version,
    ));
    if (_isStale(generation)) {
      if (_activeLoadKey == loadKey) _activeLoadKey = null;
      return;
    }
    result.fold(
      (failure) {
        if (event.forceRefresh && currentState is HymnsLoaded) {
          if (kDebugMode) {
            debugPrint('Content refresh failed; keeping loaded hymns.');
          }
          return;
        }
        emit(_handleFailure(failure));
      },
      (hymns) {
        emit(HymnsLoaded(
          hymns,
          event.sortType,
          languageCode: event.languageCode,
          version: event.version,
        ));
      },
    );
    if (_activeLoadKey == loadKey) {
      _activeLoadKey = null;
    }
  }

  Future<void> _onSearchHymns(
      SearchHymnsEvent event, Emitter<HymnsState> emit) async {
    if (event.query.isEmpty) {
      add(LoadHymns(
        event.languageCode,
        event.version,
        settingsRepository.getSortType(),
      ));
      return;
    }

    final generation = ++_generation;
    // Results replace the list in place. A spinner here would flash across
    // every tab on every keystroke, since they all read this state.
    if (state is! HymnsLoaded) emit(HymnsLoading());
    final result = await searchHymns(
      usecases.SearchHymnsParams(
        languageCode: event.languageCode,
        version: event.version,
        query: event.query,
      ),
    );
    if (_isStale(generation)) return;
    result.fold(
      (failure) => emit(HymnsError(HymnsErrorKind.searchFailed)),
      (hymns) {
        emit(HymnsLoaded(
          hymns,
          'search',
          languageCode: event.languageCode,
          version: event.version,
        ));
      },
    );
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event, Emitter<HymnsState> emit) async {
    final generation = ++_generation;
    emit(HymnsLoading());
    await settingsRepository.setSelectedLanguage(event.languageCode);
    await settingsRepository.setSelectedVersion(event.version);
    final result = await getHymns(GetHymnsParams(
      languageCode: event.languageCode,
      version: event.version,
    ));
    if (_isStale(generation)) return;
    result.fold(
      (failure) => emit(_handleFailure(failure)),
      (hymns) {
        emit(HymnsLoaded(
          hymns,
          event.sortType,
          languageCode: event.languageCode,
          version: event.version,
        ));
      },
    );
  }

  Future<void> _onChangeVersion(
      ChangeVersion event, Emitter<HymnsState> emit) async {
    final generation = ++_generation;
    emit(HymnsLoading());
    await settingsRepository.setSelectedVersion(event.version);
    final result = await getHymns(GetHymnsParams(
      languageCode: event.languageCode,
      version: event.version,
    ));
    if (_isStale(generation)) return;
    result.fold(
      (failure) => emit(_handleFailure(failure)),
      (hymns) {
        emit(HymnsLoaded(
          hymns,
          event.sortType,
          languageCode: event.languageCode,
          version: event.version,
        ));
      },
    );
  }

  Future<void> _onChangeSort(ChangeSort event, Emitter<HymnsState> emit) async {
    if (state is HymnsLoaded) {
      final currentState = state as HymnsLoaded;
      if (currentState.sortType == event.sortType) {
        return;
      }

      await settingsRepository.setSortType(event.sortType);
      // Another request may have replaced the list while the sort was saved.
      final latest = state;
      if (latest is! HymnsLoaded) return;
      emit(HymnsLoaded(
        latest.hymns,
        event.sortType,
        languageCode: latest.languageCode,
        version: latest.version,
        favoritesRevision: latest.favoritesRevision,
      ));
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<HymnsState> emit) async {
    try {
      // Favourites live in SharedPreferences by song ID, which already names
      // the edition the hymn belongs to.
      await settingsRepository.toggleFavoriteSong(event.songId);
      final newFavoriteStatus = settingsRepository.isFavoriteSong(event.songId);

      final currentState = state;
      if (currentState is HymnsLoaded) {
        // Update the specific hymn's favorite status in the existing list
        final updatedHymns = currentState.hymns.map((hymn) {
          if (hymn.songIdIn(currentState.version) == event.songId) {
            return Hymn(
              id: hymn.id,
              number: hymn.number,
              title: hymn.title,
              lyrics: hymn.lyrics,
              category: hymn.category,
              audioUrl: hymn.audioUrl,
              sheetMusic: hymn.sheetMusic,
              audioInfo: hymn.audioInfo,
              sheetPages: hymn.sheetPages,
              artist: hymn.artist,
              song: hymn.song,
              newHymnalTitle: hymn.newHymnalTitle,
              oldHymnalTitle: hymn.oldHymnalTitle,
              newHymnalLyrics: hymn.newHymnalLyrics,
              englishTitleOld: hymn.englishTitleOld,
              oldHymnalLyrics: hymn.oldHymnalLyrics,
              newHymnalNumber: hymn.newHymnalNumber,
              oldHymnalNumber: hymn.oldHymnalNumber,
              isFavorite: newFavoriteStatus,
              isBundled: hymn.isBundled,
            );
          }
          return hymn;
        }).toList();

        emit(HymnsLoaded(
          updatedHymns,
          currentState.sortType,
          languageCode: currentState.languageCode,
          version: currentState.version,
          favoritesRevision: currentState.favoritesRevision + 1,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle favorite: $e');
      }
      // Don't emit error, just log it - favorite toggle should be resilient
    }
  }

  Future<void> _onGetHymnByNumber(
      GetHymnByNumberEvent event, Emitter<HymnsState> emit) async {
    final generation = ++_generation;
    emit(HymnsLoading());
    final result = await getHymnByNumber(GetHymnByNumberParams(
      languageCode: event.languageCode,
      version: event.version,
      number: event.number,
    ));
    if (_isStale(generation)) return;
    result.fold(
      (failure) => emit(HymnsError(
        failure is NotFoundFailure
            ? HymnsErrorKind.notFound
            : HymnsErrorKind.lookupFailed,
        number: event.number,
      )),
      (hymn) {
        if (hymn != null) {
          emit(HymnsLoaded(
            [hymn],
            'number',
            languageCode: event.languageCode,
            version: event.version,
          ));
        } else {
          emit(HymnsError(HymnsErrorKind.notFound, number: event.number));
        }
      },
    );
  }
}
