// lib/features/hymns/presentation/pages/hymn_detail_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/sheet_music_viewer.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class HymnDetailPage extends StatefulWidget {
  final Hymn? hymn;
  final int? hymnNumber;

  const HymnDetailPage({
    super.key,
    this.hymn,
    this.hymnNumber,
  });

  @override
  State<HymnDetailPage> createState() => _HymnDetailPageState();
}

class _HymnDetailPageState extends State<HymnDetailPage> {
  TransformationController? _transformationController;
  double _initialFontSize = 18.0;
  double _initialScale = 1.0;
  double _horizontalDragStart = 0.0;
  bool _isHorizontalDrag = false;
  bool _isExpectingNewHymn =
      false; // Track if we're expecting a new hymn from swipe

  @override
  void initState() {
    super.initState();
    // Initialize font size from service
    final fontSizeService = FontSizeService();
    _initialFontSize = fontSizeService.getFontSize();
    _transformationController = TransformationController();
    _transformationController?.addListener(_onTransformationChanged);

    // Track hymn view in history
    _trackHymnView();
  }

  void _trackHymnView() async {
    // Initialize history service if needed
    await HistoryService.init();

    // Track the hymn if we have a hymn or hymn number
    if (widget.hymn != null) {
      await HistoryService.addToHistory(widget.hymn!.displayNumber);
    } else if (widget.hymnNumber != null) {
      await HistoryService.addToHistory(widget.hymnNumber!);
    }
  }

  void _onTransformationChanged() {
    if (_transformationController == null || !mounted) return;
    // Debounce font size updates to improve smoothness during zoom
    // Only update font size on interaction end, not during continuous zoom
    // This improves smoothness by avoiding constant state updates during pinch gestures
    // The font size will be updated in _handleZoomInteraction() when the interaction ends
    // DO NOT call setState here to prevent MouseTracker assertion errors
  }

  @override
  void dispose() {
    _transformationController?.removeListener(_onTransformationChanged);
    _transformationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If only hymnNumber is provided, load it
    if (widget.hymnNumber != null && widget.hymn == null) {
      final settingsRepository = sl<SettingsRepository>();
      final languageCode = settingsRepository.getSelectedLanguage();
      final version = settingsRepository.getSelectedVersion();
      _isExpectingNewHymn = true; // Set flag when loading hymn by number
      context
          .read<HymnsBloc>()
          .add(GetHymnByNumberEvent(languageCode, version, widget.hymnNumber!));
    }

    if (widget.hymn != null) {
      // Debug: Check if hymn has data
      if (widget.hymn!.displayTitle.isEmpty &&
          widget.hymn!.displayLyrics.isEmpty) {
        // Hymn data might be incomplete, try to reload
        final settingsRepository = sl<SettingsRepository>();
        final languageCode = settingsRepository.getSelectedLanguage();
        final version = settingsRepository.getSelectedVersion();
        _isExpectingNewHymn = true; // Set flag when reloading hymn data
        context.read<HymnsBloc>().add(
              GetHymnByNumberEvent(
                  languageCode, version, widget.hymn!.displayNumber),
            );
      }

      return BlocListener<HymnsBloc, HymnsState>(
        listener: (context, state) {
          // Handle navigation when hymn is loaded after swipe
          // Only navigate if we're expecting a new hymn (from swipe gesture)
          // and the hymn number is actually different
          if (state is HymnsLoaded &&
              state.hymns.isNotEmpty &&
              widget.hymn != null &&
              _isExpectingNewHymn) {
            final newHymn = state.hymns.first;
            // Only navigate if it's a different hymn
            if (newHymn.displayNumber != widget.hymn!.displayNumber) {
              _isExpectingNewHymn = false; // Reset flag
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => HymnDetailPage(hymn: newHymn),
                ),
              );
            } else {
              _isExpectingNewHymn = false; // Reset flag if same hymn
            }
          } else if (state is HymnsLoaded && !_isExpectingNewHymn) {
            // State changed but we're not expecting a new hymn (e.g., favorite toggle)
            // Just update the UI, don't navigate
            if (mounted) {
              setState(() {});
            }
          }
        },
        child: BlocBuilder<HymnsBloc, HymnsState>(
          builder: (context, state) {
            // If hymn was reloaded and we have updated data, use it
            if (state is HymnsLoaded &&
                state.hymns.isNotEmpty &&
                state.hymns.first.displayNumber == widget.hymn!.displayNumber) {
              return _buildDetailView(context, state.hymns.first);
            }
            // Otherwise use the passed hymn
            return _buildDetailView(context, widget.hymn!);
          },
        ),
      );
    }

    // If only hymnNumber is provided, fetch from BLoC state
    return BlocBuilder<HymnsBloc, HymnsState>(
      builder: (context, state) {
        if (state is HymnsLoading) {
          return const Scaffold(
            backgroundColor: AppColors.primaryBackground,
            body: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
              ),
            ),
          );
        }

        if (state is HymnsError) {
          return Scaffold(
            backgroundColor: AppColors.primaryBackground,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontFamily: 'NotoSansEthiopic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is HymnsLoaded && state.hymns.isNotEmpty) {
          final hymn = state.hymns.first;
          return _buildDetailView(context, hymn);
        }

        return const Scaffold(
          backgroundColor: AppColors.primaryBackground,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailView(BuildContext context, Hymn hymn) {
    final settingsRepository = sl<SettingsRepository>();
    // Check favorite status from both database and SharedPreferences
    final isFavoriteFromPrefs =
        settingsRepository.isFavorite(hymn.displayNumber);
    final isFavoriteFromDb = hymn.isFavorite;
    final isFavorite = isFavoriteFromPrefs || isFavoriteFromDb;
    final languageCode = _getLanguageCode();
    final version = _getVersion();

    return GestureDetector(
      onHorizontalDragStart: (details) {
        _horizontalDragStart = details.globalPosition.dx;
        _isHorizontalDrag = false;
      },
      onHorizontalDragUpdate: (details) {
        // Check if this is a primarily horizontal drag (not diagonal)
        final deltaX = details.globalPosition.dx - _horizontalDragStart;
        final deltaY = details.delta.dy.abs();

        // If horizontal movement is much greater than vertical, it's a swipe
        if (deltaX.abs() > 20 && deltaX.abs() > deltaY * 2) {
          _isHorizontalDrag = true;
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isHorizontalDrag && details.primaryVelocity != null) {
          _handleSwipe(details, hymn.displayNumber, languageCode, version);
        }
        _isHorizontalDrag = false;
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          _buildBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(hymn, isFavorite),
            body: BlocListener<HymnsBloc, HymnsState>(
              listener: (context, state) {
                // Update UI when favorite status changes
                if (mounted) {
                  setState(() {});
                }
              },
              child: ListenableBuilder(
                listenable: FontSizeService(),
                builder: (context, _) {
                  // Get font size reactively - updates in real-time
                  final fontSize = FontSizeService().getFontSize();
                  return _buildBody(hymn, fontSize);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageCode() {
    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded) return state.languageCode;
    final settingsRepository = sl<SettingsRepository>();
    return settingsRepository.getSelectedLanguage();
  }

  String _getVersion() {
    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded) return state.version;
    final settingsRepository = sl<SettingsRepository>();
    return settingsRepository.getSelectedVersion();
  }

  void _handleSwipe(DragEndDetails details, int currentNumber,
      String languageCode, String version) {
    if (details.primaryVelocity == null || !mounted) return;

    // Set flag to indicate we're expecting a new hymn from swipe
    _isExpectingNewHymn = true;

    if (!mounted) return; // Double-check after setting flag

    if (details.primaryVelocity! < 0) {
      // Swipe left - next hymn
      context
          .read<HymnsBloc>()
          .add(GetHymnByNumberEvent(languageCode, version, currentNumber + 1));
    } else if (details.primaryVelocity! > 0 && currentNumber > 1) {
      // Swipe right - previous hymn
      context
          .read<HymnsBloc>()
          .add(GetHymnByNumberEvent(languageCode, version, currentNumber - 1));
    }
  }

  Widget _buildBackground() {
    // Cache the background image to prevent flickering
    return Positioned.fill(
      child: ListenableBuilder(
        listenable: BackgroundImageService(),
        builder: (context, _) {
          final bgService = BackgroundImageService();
          // Use RepaintBoundary to isolate background rendering and prevent flickering
          return RepaintBoundary(
            child: Container(
            decoration: BoxDecoration(
              image: bgService.isEnabled
                  ? DecorationImage(
                        // Use AssetImage directly - Flutter caches assets automatically
                      image: const AssetImage('assets/images/background.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.8),
                        BlendMode.darken,
                      ),
                        // Prevent image from reloading on rebuild
                        repeat: ImageRepeat.noRepeat,
                    )
                  : null,
              color: bgService.isEnabled ? null : AppColors.primaryBackground,
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Hymn hymn, bool isFavorite) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'መዝሙር ${hymn.displayNumber}',
        style: const TextStyle(
          fontFamily: 'NotoSansEthiopic',
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
      actions: _buildAppBarActions(hymn, isFavorite),
    );
  }

  List<Widget> _buildAppBarActions(Hymn hymn, bool isFavorite) {
    return [
      if (!hymn.isHagerigna) _buildSheetMusicButton(),
      if (!hymn.isHagerigna) _buildAudioButton(),
      _buildFavoriteButton(hymn, isFavorite),
      _buildShareButton(hymn),
    ];
  }

  Widget _buildSheetMusicButton() {
    // Ensure minimum 48x48 tap target for accessibility
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
      icon: const Icon(Icons.music_note, color: AppColors.primaryText),
      tooltip: 'Sheet Music',
      onPressed: () =>
          _showComingSoonMessage('Sheet music feature coming soon'),
      ),
    );
  }

  Widget _buildAudioButton() {
    // Ensure minimum 48x48 tap target for accessibility
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon:
            const Icon(Icons.play_circle_outline, color: AppColors.primaryText),
      tooltip: 'Audio Player',
      onPressed: () =>
          _showComingSoonMessage('Audio player feature coming soon'),
      ),
    );
  }

  Widget _buildFavoriteButton(Hymn hymn, bool isFavorite) {
    // Simple favorite button - no loading indicator, just instant toggle
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? AppColors.accentGreen : AppColors.primaryText,
      ),
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      onPressed: () {
        // Dispatch the toggle event - UI updates instantly via BLoC
        context.read<HymnsBloc>().add(ToggleFavorite(hymn.displayNumber));
      },
    );
  }

  Widget _buildShareButton(Hymn hymn) {
    // Ensure minimum 48x48 tap target for accessibility
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
      icon: const Icon(Icons.share, color: AppColors.primaryText),
      tooltip: 'Share',
      onPressed: () => _shareHymn(hymn),
      ),
    );
  }

  void _showComingSoonMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildBody(Hymn hymn, double fontSize) {
    // Use CustomScrollView to avoid nested scroll conflicts
    // InteractiveViewer handles its own scrolling when zoomed
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
          _buildTitleSection(hymn, fontSize),
              const SizedBox(height: 8),
          _buildLyricsSection(hymn, fontSize),
              const SizedBox(height: 12),
          if (!hymn.isHagerigna) ...[
            _buildSheetMusicSection(context, hymn),
            const SizedBox(height: 16),
            _buildAudioSection(context, hymn),
          ],
            ]),
          ),
        ),
        ],
    );
  }

  Widget _buildTitleSection(Hymn hymn, double fontSize) {
    return GlassContainer(
      borderRadius: 12.0,
      blurSigma: 12.0,
      opacity: 0.25,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildNumberBadge(hymn.displayNumber, fontSize),
          const SizedBox(width: 12),
          Expanded(child: _buildTitleText(hymn.displayTitle, fontSize)),
        ],
      ),
    );
  }

  Widget _buildNumberBadge(int number, double fontSize) {
    // Responsive badge size based on font size
    final badgeSize = fontSize * 2.5 < 48 ? 48.0 : fontSize * 2.5;
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentGreen.withValues(alpha: 0.4),
            AppColors.accentGreen.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: AppColors.accentGreen,
            fontSize: fontSize * 0.9,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansEthiopic',
          ),
        ),
      ),
    );
  }

  Widget _buildTitleText(String title, double fontSize) {
    return Text(
      title.isNotEmpty ? title : 'No title',
      style: TextStyle(
        color: AppColors.primaryText,
        fontSize: fontSize * 1.3,
        fontWeight: FontWeight.bold,
        fontFamily: 'NotoSansEthiopic',
        height: 1.3,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsSection(Hymn hymn, double fontSize) {
    // Ensure transformation controller is initialized
    if (_transformationController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
        ),
      );
    }

    // Reduced padding for more compact lyrics card
    // Keep horizontal padding consistent, reduce vertical padding
    final padding = fontSize > 24
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
        : (fontSize < 16
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10));

    return GlassContainer(
      borderRadius: 12.0,
      blurSigma: 12.0,
      opacity: 0.25,
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use proper constraints from parent
          final maxWidth = constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width -
                  32; // Fallback to screen width minus padding

          return ValueListenableBuilder<Matrix4>(
            valueListenable: _transformationController!,
            builder: (context, value, child) {
              // Check if currently zoomed in
              final currentScale = value.getMaxScaleOnAxis();
              final isZoomed = currentScale >
                  1.01; // Small threshold to account for floating point

              // Removed RepaintBoundary from InteractiveViewer to prevent layout exceptions
              // Keep InteractiveViewer properly constrained
              // Calculate min/max scale based on zoom scale constants (0.8x-2.0x font scale)
              final minScale = AppConstants.minZoomScale;
              final maxScale = AppConstants.maxZoomScale;

              return InteractiveViewer(
        transformationController: _transformationController,
                minScale: minScale,
                maxScale: maxScale,
        onInteractionEnd: (_) => _handleZoomInteraction(),
                // Only allow panning when zoomed in - this prevents horizontal swipes from being captured
                // when not zoomed, allowing navigation swipes to work
                panEnabled: isZoomed,
                // Reduced boundary margin to reasonable value to prevent layout issues
                boundaryMargin: const EdgeInsets.all(100),
                // Use proper constraints instead of false
                constrained: true,
                // Use Clip.none to prevent text from being clipped at edges
                clipBehavior: Clip.none,
                // Enable smooth scaling
                scaleEnabled: true,
                // Enable panning when zoomed
                panAxis: PanAxis.free,
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: maxWidth,
                    maxWidth: maxWidth,
                    // Allow vertical expansion for text
                    minHeight: 0,
                  ),
                  child: child!,
                ),
              );
            },
            child: SelectableText(
              hymn.displayLyrics.isNotEmpty
                  ? hymn.displayLyrics
                  : 'No lyrics available',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: fontSize,
                // Use theme scale system for responsive line height and letter spacing
                height: AppTheme.getLineHeight(fontSize),
            fontFamily: 'NotoSansEthiopic',
                letterSpacing: AppTheme.getLetterSpacing(fontSize),
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.start,
              // Ensure text can expand fully
              textWidthBasis: TextWidthBasis.longestLine,
          ),
          );
        },
      ),
    );
  }

  void _handleZoomInteraction() {
    final controller = _transformationController;
    if (controller == null || !mounted) return;

    // Use post-frame callback to defer state updates and prevent MouseTracker assertion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controllerRef = _transformationController;
      if (controllerRef == null) return;

    // Update initial scale and font size when interaction ends
      final currentScale = controllerRef.value.getMaxScaleOnAxis();
      final fontSizeService = FontSizeService();

      // Update font size based on zoom level (only when zoom ends for smoothness)
      // Map InteractiveViewer scale (0.8x-1.6x) to font size multiplier
      // FontSizeService.setFontSize() will clamp to 12-30 range automatically
      if ((currentScale - _initialScale).abs() > 0.01 &&
          _initialScale > 0 &&
          _initialScale >= AppConstants.minZoomScale) {
        // Scale ratio represents the change in zoom (e.g., 1.0 -> 1.5 means 1.5x zoom)
        final scaleRatio = currentScale / _initialScale;
        // Calculate new font size based on scale ratio
        final newFontSize = _initialFontSize * scaleRatio;

        // Clamp to valid font size range before setting
        final clampedFontSize = newFontSize.clamp(
            AppConstants.minFontSize, AppConstants.maxFontSize);

        // Defer font size update to next microtask to prevent synchronous layout during pointer events
        Future.microtask(() async {
          if (!mounted) return;
          // Update font size service which will clamp and notify listeners
          await fontSizeService.setFontSize(clampedFontSize);
          // Update local state to the clamped value that will be set
          if (mounted) {
            setState(() {
              _initialFontSize = clampedFontSize;
            });
          }
        });
      }

      // Update scale reference for next interaction
      // Ensure scale is within valid bounds
      _initialScale = currentScale.clamp(
          AppConstants.minZoomScale, AppConstants.maxZoomScale);
      // Sync local state with service (getFontSize() already clamps)
      if (mounted) {
        setState(() {
          _initialFontSize = fontSizeService
              .getFontSize()
              .clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
        });
      }
    });
  }

  Widget _buildSheetMusicSection(BuildContext context, Hymn hymn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: [
        const Divider(color: AppColors.divider),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.music_note,
              color: AppColors.accentGreen,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.sheetMusic ?? 'Sheet Music',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sheet music viewer with zoom and pagination support
        SheetMusicViewer(
          sheetMusicFiles: hymn.sheetMusic ?? [],
          hymnNumber: hymn.displayNumber,
        ),
      ],
    );
  }

  Widget _buildAudioSection(BuildContext context, Hymn hymn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: [
        const Divider(color: AppColors.divider),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: AppColors.accentGreen,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.audioPlayer ?? 'Audio Player',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Glass card placeholder for audio player
        GlassCard(
          borderRadius: 12.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.play_circle_outline,
                    color: AppColors.primaryText,
                    size: 48,
                  ),
                  onPressed: () {
                    // Future: Audio playback functionality via API
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)
                                ?.audioPlayerComingSoon ??
                            'Audio player feature coming soon'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Prevent overflow
                    children: [
                      Text(
                        'መዝሙር ${hymn.displayNumber} ድምፅ',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (hymn.audioUrl?.isNotEmpty ?? false)
                            ? 'Audio: ${hymn.audioUrl} (API integration coming soon)'
                            : 'Tap to play (API integration coming soon)',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _shareHymn(Hymn hymn) async {
    final text = '${hymn.displayTitle}\n\n${hymn.displayLyrics}';
    try {
      await Share.share(text);
    } catch (e) {
      if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
            content: Text('Error sharing: $e'),
        duration: const Duration(seconds: 2),
      ),
    );
      }
    }
  }
}
