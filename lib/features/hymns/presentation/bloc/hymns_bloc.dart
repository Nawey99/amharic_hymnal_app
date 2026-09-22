// lib/features/hymns/presentation/bloc/hymns_bloc.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:intl/intl.dart';

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
      return HymnsError(
          'This hymnal needs an internet connection to load. Please connect and try again.');
    }
    return HymnsError('Hymns could not be loaded. Please try again.');
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
    if (!event.forceRefresh || currentState is! HymnsLoaded) {
      emit(HymnsLoading());
    }
    final result = await getHymns(GetHymnsParams(
      languageCode: event.languageCode,
      version: event.version,
    ));
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

    emit(HymnsLoading());
    final result = await searchHymns(
      usecases.SearchHymnsParams(
        languageCode: event.languageCode,
        version: event.version,
        query: event.query,
      ),
    );
    result.fold(
      (failure) => emit(HymnsError('Failed to search hymns.')),
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
    emit(HymnsLoading());
    await settingsRepository.setSelectedLanguage(event.languageCode);
    await settingsRepository.setSelectedVersion(event.version);
    final result = await getHymns(GetHymnsParams(
      languageCode: event.languageCode,
      version: event.version,
    ));
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
    emit(HymnsLoading());
    await settingsRepository.setSelectedVersion(event.version);
    final result = await getHymns(GetHymnsParams(
      languageCode: event.languageCode,
      version: event.version,
    ));
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
      emit(HymnsLoaded(
        currentState.hymns,
        event.sortType,
        languageCode: currentState.languageCode,
        version: currentState.version,
        favoritesRevision: currentState.favoritesRevision,
      ));
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<HymnsState> emit) async {
    try {
      // Favorites live in SharedPreferences, per edition.
      await settingsRepository.toggleFavorite(event.hymnNumber);
      final newFavoriteStatus = settingsRepository.isFavorite(event.hymnNumber);

      if (state is HymnsLoaded) {
        final currentState = state as HymnsLoaded;

        // Update the specific hymn's favorite status in the existing list
        final updatedHymns = currentState.hymns.map((hymn) {
          if (hymn.displayNumber == event.hymnNumber) {
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
    emit(HymnsLoading());
    final result = await getHymnByNumber(GetHymnByNumberParams(
      languageCode: event.languageCode,
      version: event.version,
      number: event.number,
    ));
    result.fold(
      (failure) => emit(HymnsError('Hymn #${event.number} not found.')),
      (hymn) {
        if (hymn != null) {
          emit(HymnsLoaded(
            [hymn],
            'number',
            languageCode: event.languageCode,
            version: event.version,
          ));
        } else {
          emit(HymnsError('Hymn #${event.number} not found.'));
        }
      },
    );
  }
}
