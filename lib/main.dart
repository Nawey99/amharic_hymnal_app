// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'package:amharic_hymnal_app/core/services/frame_stats_probe.dart';
import 'package:amharic_hymnal_app/core/services/screen_service.dart';
import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/services/bug_report_queue_service.dart';
import 'package:amharic_hymnal_app/core/services/crash_reporting.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/app_text_scope.dart';
import 'package:amharic_hymnal_app/core/services/language_service.dart';
import 'package:amharic_hymnal_app/core/services/theme_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_fonts.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amharic_hymnal_app/core/widgets/error_widget.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/onboarding_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart'
    show initDependencies, registerAudioHandler, sl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final audioHandler = await GlobalAudioService().initialize();
    if (audioHandler != null) registerAudioHandler(audioHandler);
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('Background audio initialization failed: $error');
    }
    unawaited(CrashReporting.recordError(error, stackTrace));
  }

  // Set system UI overlay style first (only for mobile)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  // Beta builds with a Sentry DSN report crashes; other builds run as-is.
  FrameStatsProbe.start();
  await CrashReporting.run(() => runApp(const AppInitializer()));
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
      await initDependencies();

      unawaited(BugReportQueueService.instance.flushPendingReports());

      // Initialize screen service (keep screen on)
      await ScreenService.initialize();

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
      unawaited(CrashReporting.recordError(e, stackTrace));

      // Continue with limited functionality if a non-critical step failed
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
    const forceOnboarding = bool.fromEnvironment('WUDASE_FORCE_ONBOARDING');
    if (forceOnboarding) {
      return const OnboardingPage();
    }

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
      child: ListenableBuilder(
        listenable: Listenable.merge([ThemeService(), LanguageService()]),
        builder: (context, _) => _buildApp(settingsRepository),
      ),
    );
  }

  /// Rebuilt whenever the chosen look or language changes, so the palette,
  /// the light/dark setting and the words reach every screen at once.
  Widget _buildApp(SettingsRepository settingsRepository) {
    final theme = ThemeService();
    return MaterialApp(
      title: 'ውዳሴ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forPalette(theme.palette, Brightness.light),
      darkTheme: AppTheme.forPalette(theme.palette, Brightness.dark),
      themeMode: theme.themeMode,
      locale: LanguageService().locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _getInitialPage(settingsRepository),
      // The face follows the language the interface ends up in, which is
      // only known here: "follow the phone" resolves below Localizations,
      // not at the point the themes above are handed over.
      builder: (context, child) {
        final base = Theme.of(context);
        final locale = Localizations.localeOf(context);
        return Theme(
          data: AppFonts.isEnglish(locale)
              ? AppTheme.forPalette(
                  theme.palette,
                  base.brightness,
                  uiLocale: locale,
                )
              : base,
          child: AppTextScope(child: child!),
        );
      },
    );
  }
}
