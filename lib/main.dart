// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'package:amharic_hymnal_app/core/services/screen_service.dart';
import 'package:amharic_hymnal_app/core/services/sheet_music_discovery_service.dart';
import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amharic_hymnal_app/core/widgets/error_widget.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/onboarding_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart'
    show initDependencies, sl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style first (only for mobile)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Run app with error handling
  runApp(const AppInitializer());
}

/// Widget to handle app initialization with error handling
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize dependencies (includes Drift database initialization)
      // Drift works on all platforms including web (uses IndexedDB on web)
      await initDependencies();

      // Initialize global audio service (without API config - can be set later)
      try {
        await GlobalAudioService().initialize();
        if (kDebugMode) {
          debugPrint('✅ GlobalAudioService initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ GlobalAudioService initialization failed: $e');
        }
        // Continue without audio service
      }

      // Initialize screen service (keep screen on)
      await ScreenService.initialize();

      // Initialize sheet music discovery service (scans assets)
      SheetMusicDiscoveryService().initialize().catchError((e) {
        if (kDebugMode) {
          debugPrint('Warning: Sheet music discovery failed: $e');
        }
      });

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error initializing app: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      // Try to initialize at least SettingsRepository if database fails
      try {
        // SettingsRepository is initialized in initDependencies, but if that failed,
        // we can't continue - the error is already set
        if (mounted) {
          setState(() {
            _isInitializing = false;
            // Don't set error - allow app to continue with limited functionality
          });
        }
        return;
      } catch (e2) {
        // If even SettingsService fails, show error
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _hasError = true;
            _errorMessage = 'መተግበሪያውን ማስጀመር አልተቻለም: ${e2.toString()}';
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: _buildInitializerChild(),
    );
  }

  Widget _buildInitializerChild() {
    if (_isInitializing) {
      return MaterialApp(
        key: const ValueKey('splash'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: AppColors.primaryBackground,
        ),
      );
    }

    if (_hasError) {
      return MaterialApp(
        key: const ValueKey('error'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: AppErrorWidget(
          message: _errorMessage ?? 'መተግበሪያውን ማስጀመር አልተቻለም',
          onRetry: () {
            setState(() {
              _isInitializing = true;
              _hasError = false;
              _errorMessage = null;
            });
            _initializeApp();
          },
        ),
      );
    }

    return const MyApp(key: ValueKey('app'));
  }
}

class MyApp extends StatelessWidget {
  final bool loadInitialHymns;

  const MyApp({
    super.key,
    this.loadInitialHymns = true,
  });

  // Determine which page to show on startup
  Widget _getInitialPage(SettingsRepository settingsRepository) {
    // Check if onboarding has been completed
    final isCompleted = settingsRepository.isOnboardingCompleted();
    if (isCompleted) {
      return const MainNavigationPage();
    } else {
      return const OnboardingPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsRepository = sl<SettingsRepository>();
    final languageCode = settingsRepository.getSelectedLanguage();
    final version = settingsRepository.getSelectedVersion();
    final sortType = settingsRepository.getSortType();

    return BlocProvider<HymnsBloc>(
      create: (context) {
        final bloc = sl<HymnsBloc>();
        // Load hymns asynchronously to avoid blocking UI
        if (loadInitialHymns) {
          Future.microtask(() {
            bloc.add(LoadHymns(languageCode, version, sortType));
          });
        }
        return bloc;
      },
      child: MaterialApp(
        title: 'ውዳሴ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: Locale(languageCode),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _getInitialPage(settingsRepository),
        builder: (context, child) {
          // Support system font scaling (1.0x to 2.0x) for accessibility
          // Clamp to reasonable range to prevent UI overflow
          final textScaler = MediaQuery.of(context).textScaler;
          final clampedScaler = TextScaler.linear(
            textScaler.scale(1.0).clamp(1.0, 2.0),
          );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
            child: child!,
          );
        },
      ),
    );
  }
}
