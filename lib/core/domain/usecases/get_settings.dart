// lib/core/domain/usecases/get_settings.dart
import 'package:dartz/dartz.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/usecases/usecase.dart';
import 'package:amharic_hymnal_app/core/error/failures.dart';

/// Use case to get app settings
/// This encapsulates the business logic for retrieving settings
class GetSettings implements UseCase<SettingsData, NoParams> {
  final SettingsRepository repository;

  GetSettings(this.repository);

  @override
  Future<Either<Failure, SettingsData>> call(NoParams params) async {
    final settingsData = SettingsData(
      languageCode: repository.getSelectedLanguage(),
      version: repository.getSelectedVersion(),
      sortType: repository.getSortType(),
      fontSize: repository.getFontSize(),
      keepScreenOn: repository.getKeepScreenOn(),
      backgroundImageEnabled: repository.getBackgroundImageEnabled(),
      favoriteHymns: repository.getFavoriteHymns(),
      isOnboardingCompleted: repository.isOnboardingCompleted(),
    );
    return Right(settingsData);
  }
}

/// Data class representing all app settings
class SettingsData {
  final String languageCode;
  final String version;
  final String sortType;
  final double fontSize;
  final bool keepScreenOn;
  final bool backgroundImageEnabled;
  final List<int> favoriteHymns;
  final bool isOnboardingCompleted;

  SettingsData({
    required this.languageCode,
    required this.version,
    required this.sortType,
    required this.fontSize,
    required this.keepScreenOn,
    required this.backgroundImageEnabled,
    required this.favoriteHymns,
    required this.isOnboardingCompleted,
  });
}
