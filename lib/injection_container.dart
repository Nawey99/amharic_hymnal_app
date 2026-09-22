// lib/injection_container.dart
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';

import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/data/repositories/settings_repository_impl.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/repositories/hymn_repository_impl.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart'
    as usecases;
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns_by_category.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';

final sl = GetIt.instance;

void registerAudioHandler(AudioHandler handler) {
  if (!sl.isRegistered<AudioHandler>()) {
    sl.registerSingleton<AudioHandler>(handler);
  }
}

Future<void> initDependencies() async {
  await SettingsService.init();

  // Initialize BackgroundImageService with current setting
  BackgroundImageService()
      .initialize(SettingsService.getBackgroundImageEnabled());

  // Initialize FontSizeService with current setting (clamped to valid range)
  FontSizeService().initialize(SettingsService.getFontSize());

  // Data sources
  // Register data source by its abstract contract so it can be mocked in tests
  if (!sl.isRegistered<HymnLocalDataSource>()) {
    sl.registerLazySingleton<HymnLocalDataSource>(() => LocalDataSource());
  }
  if (!sl.isRegistered<HymnalVersionService>()) {
    sl.registerLazySingleton<HymnalVersionService>(HymnalVersionService.new);
  }

  // Repositories
  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl());
  }
  if (!sl.isRegistered<HymnRepository>()) {
    sl.registerLazySingleton<HymnRepository>(() => HymnRepositoryImpl(sl()));
  }

  // Use cases
  if (!sl.isRegistered<GetHymns>()) {
    sl.registerLazySingleton<GetHymns>(() => GetHymns(sl()));
  }
  if (!sl.isRegistered<GetHymnByNumber>()) {
    sl.registerLazySingleton<GetHymnByNumber>(() => GetHymnByNumber(sl()));
  }
  if (!sl.isRegistered<usecases.SearchHymns>()) {
    sl.registerLazySingleton<usecases.SearchHymns>(
        () => usecases.SearchHymns(sl()));
  }
  if (!sl.isRegistered<GetHymnsByCategory>()) {
    sl.registerLazySingleton<GetHymnsByCategory>(
        () => GetHymnsByCategory(sl()));
  }

  // BLoC
  if (!sl.isRegistered<HymnsBloc>()) {
    sl.registerFactory<HymnsBloc>(() => HymnsBloc(
          getHymns: sl(),
          searchHymns: sl<usecases.SearchHymns>(),
          getHymnByNumber: sl(),
          settingsRepository: sl(),
        ));
  }
}
