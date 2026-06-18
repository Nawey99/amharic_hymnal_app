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
import 'package:amharic_hymnal_app/core/database/database_helper.dart';
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
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  StreamSubscription<bool>? _dbReadySubscription;

  // Track pending queries that failed due to database not being ready
  // Using a single map to track all pending queries by type
  final Map<Type, HymnsEvent> _pendingQueries = {};

  // Debounce timer for search events
  Timer? _searchDebounceTimer;

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

    // Listen for database readiness and retry pending queries
    _dbReadySubscription = _dbHelper.readyStream.listen((isReady) {
      if (isReady) {
        _retryPendingQueries();
      }
    });
  }

  /// Retry all pending queries when database becomes ready
  void _retryPendingQueries() {
    final pendingEvents = List<HymnsEvent>.from(_pendingQueries.values);
    _pendingQueries.clear();

    for (final event in pendingEvents) {
      if (kDebugMode) {
        debugPrint('🔄 Retrying pending ${event.runtimeType}');
      }
      add(event);
    }
  }

  /// Store a pending query
  void _storePendingQuery(HymnsEvent event) {
    _pendingQueries[event.runtimeType] = event;
    if (kDebugMode) {
      debugPrint('⏳ Stored pending query: ${event.runtimeType}');
    }
  }

  /// Clear a pending query
  void _clearPendingQuery(Type eventType) {
    _pendingQueries.remove(eventType);
  }

  /// Handle failure and return appropriate error state
  HymnsState _handleFailure(Failure failure) {
    if (failure is CacheFailure) {
      return HymnsError(
          'No cached data available. Please ensure data migration completed.');
    }
    return HymnsError('An error occurred. Please try again.');
  }

  @override
  Future<void> close() {
    _dbReadySubscription?.cancel();
    _searchDebounceTimer?.cancel();
    _pendingQueries.clear();
    return super.close();
  }

  Future<void> _onLoadHymns(LoadHymns event, Emitter<HymnsState> emit) async {
    emit(HymnsLoading());
    final result = await getHymns(GetHymnsParams(
      languageCode: event.languageCode,
      version: event.version,
    ));
    result.fold(
      (failure) {
        // If database is not ready and we got CacheFailure, store as pending query
        if (failure is CacheFailure && !_dbHelper.isReady) {
          _storePendingQuery(event);
          // Keep loading state instead of showing error
          emit(HymnsLoading());
        } else {
          // Database is ready but query failed - show error
          emit(_handleFailure(failure));
        }
      },
      (hymns) {
        // Clear pending query on success
        _clearPendingQuery(LoadHymns);
        emit(HymnsLoaded(
          hymns,
          event.sortType,
          languageCode: event.languageCode,
          version: event.version,
        ));
      },
    );
  }

  Future<void> _onSearchHymns(
      SearchHymnsEvent event, Emitter<HymnsState> emit) async {
    if (event.query.isEmpty) {
      add(LoadHymns(event.languageCode, event.version, 'name'));
      return;
    }

    // Cancel previous debounce timer
    _searchDebounceTimer?.cancel();

    // Debounce search queries (300ms delay)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      emit(HymnsLoading());
      final result = await searchHymns(
        usecases.SearchHymnsParams(
          languageCode: event.languageCode,
          version: event.version,
          query: event.query,
        ),
      );
      result.fold(
        (failure) {
          // If database is not ready and we got CacheFailure, store as pending query
          if (failure is CacheFailure && !_dbHelper.isReady) {
            _storePendingQuery(event);
            // Keep loading state instead of showing error
            emit(HymnsLoading());
          } else {
            // Database is ready but query failed - show error
            if (failure is CacheFailure) {
              emit(HymnsError('No cached data available for search.'));
            } else {
              emit(HymnsError('Failed to search hymns.'));
            }
          }
        },
        (hymns) {
          // Clear pending query on success
          _clearPendingQuery(SearchHymnsEvent);
          emit(HymnsLoaded(
            hymns,
            'name',
            languageCode: event.languageCode,
            version: event.version,
          ));
        },
      );
    });
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
      (failure) {
        // If database is not ready and we got CacheFailure, store as pending query
        if (failure is CacheFailure && !_dbHelper.isReady) {
          _storePendingQuery(event);
          // Keep loading state instead of showing error
          emit(HymnsLoading());
        } else {
          // Database is ready but query failed - show error
          emit(_handleFailure(failure));
        }
      },
      (hymns) {
        // Clear pending query on success
        _clearPendingQuery(ChangeLanguage);
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
      (failure) {
        // If database is not ready and we got CacheFailure, store as pending query
        if (failure is CacheFailure && !_dbHelper.isReady) {
          _storePendingQuery(event);
          // Keep loading state instead of showing error
          emit(HymnsLoading());
        } else {
          // Database is ready but query failed - show error
          emit(_handleFailure(failure));
        }
      },
      (hymns) {
        // Clear pending query on success
        _clearPendingQuery(ChangeVersion);
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
      await settingsRepository.setSortType(event.sortType);
      emit(HymnsLoaded(
        currentState.hymns,
        event.sortType,
        languageCode: currentState.languageCode,
        version: currentState.version,
      ));
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<HymnsState> emit) async {
    try {
      final languageCode = settingsRepository.getSelectedLanguage();
      final version = settingsRepository.getSelectedVersion();

      // OPTIMISTIC UPDATE: Update SharedPreferences first for instant UI feedback
      await settingsRepository.toggleFavorite(event.hymnNumber);
      final newFavoriteStatus = settingsRepository.isFavorite(event.hymnNumber);

      // Emit state update IMMEDIATELY after SharedPreferences update (before database)
      // This provides instant UI feedback without waiting for database operations
      if (state is HymnsLoaded) {
        final currentState = state as HymnsLoaded;

        // Update the specific hymn's favorite status in the existing list
        final updatedHymns = currentState.hymns.map((hymn) {
          if (hymn.displayNumber == event.hymnNumber) {
            // Create updated hymn with toggled favorite status
            return Hymn(
              id: hymn.id,
              number: hymn.number,
              title: hymn.title,
              lyrics: hymn.lyrics,
              category: hymn.category,
              audioUrl: hymn.audioUrl,
              sheetMusic: hymn.sheetMusic,
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

        // Emit updated state IMMEDIATELY - provides instant UI feedback
        emit(HymnsLoaded(
          updatedHymns,
          currentState.sortType,
          languageCode: currentState.languageCode,
          version: currentState.version,
        ));
      }

      // Update database in background (non-blocking, non-critical)
      // If this fails, SharedPreferences is still the source of truth
      final dbHelper = DatabaseHelper.instance;
      if (dbHelper.isReady) {
        // Run database update asynchronously without blocking UI
        dbHelper
            .toggleFavorite(languageCode, version, event.hymnNumber)
            .catchError((e) {
          if (kDebugMode) {
            debugPrint('⚠️ Database favorite toggle failed (non-critical): $e');
          }
          // Don't rollback - SharedPreferences is the source of truth
        });
      } else {
        if (kDebugMode) {
          debugPrint(
              'ℹ️ Database not ready, favorite saved to SharedPreferences only');
        }
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
      (failure) {
        // If database is not ready and we got CacheFailure, store as pending query
        if (failure is CacheFailure && !_dbHelper.isReady) {
          _storePendingQuery(event);
          // Keep loading state instead of showing error
          emit(HymnsLoading());
        } else {
          // Database is ready but query failed - show error
          emit(HymnsError('Hymn #${event.number} not found.'));
        }
      },
      (hymn) {
        // Clear pending query on success
        _clearPendingQuery(GetHymnByNumberEvent);
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
