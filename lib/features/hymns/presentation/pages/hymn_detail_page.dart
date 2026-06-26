// lib/features/hymns/presentation/pages/hymn_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/sheet_music_viewer_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/audio_section_widget.dart';
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
  double _horizontalDragStart = 0.0;
  bool _isHorizontalDrag = false;
  bool _isExpectingNewHymn =
      false; // Track if we're expecting a new hymn from swipe
  int? _displayedHymnNumber;
  double _lyricsZoomScale = AppConstants.defaultZoomScale;
  double _scaleStartZoom = AppConstants.defaultZoomScale;
  final Map<int, bool> _favoriteOverrides = {};
  final SheetMusicRepository _sheetMusicRepository = SheetMusicRepository();
  final DownloadRepository _downloadRepository = DownloadRepository();

  @override
  void initState() {
    super.initState();
    // Track hymn view in history
    _trackHymnView();
  }

  void _trackHymnView() async {
    // Initialize history service if needed
    await HistoryService.init();

    // Track the hymn if we have a hymn or hymn number
    if (widget.hymn != null) {
      await HistoryService.addToHistory(
        widget.hymn!.displayNumber,
        version: _getVersion(),
      );
    } else if (widget.hymnNumber != null) {
      await HistoryService.addToHistory(
        widget.hymnNumber!,
        version: _getVersion(),
      );
    }
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
    _syncDisplayedHymn(hymn);
    final settingsRepository = sl<SettingsRepository>();
    final isFavorite = _favoriteOverrides[hymn.displayNumber] ??
        settingsRepository.isFavorite(hymn.displayNumber);
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

  void _syncDisplayedHymn(Hymn hymn) {
    if (_displayedHymnNumber == hymn.displayNumber) return;
    _displayedHymnNumber = hymn.displayNumber;
    _lyricsZoomScale = AppConstants.defaultZoomScale;
    _scaleStartZoom = AppConstants.defaultZoomScale;
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
    final compactActions = MediaQuery.sizeOf(context).width < 380;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        '- ${hymn.displayNumber} -',
        style: const TextStyle(
          fontFamily: 'NotoSansEthiopic',
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
      actions: _buildAppBarActions(hymn, isFavorite, compactActions),
    );
  }

  List<Widget> _buildAppBarActions(
    Hymn hymn,
    bool isFavorite,
    bool compactActions,
  ) {
    if (compactActions) {
      return [
        _buildFavoriteButton(hymn, isFavorite),
        _buildOverflowMenuButton(hymn),
      ];
    }

    return [
      _buildFavoriteButton(hymn, isFavorite),
      _buildShareButton(hymn),
    ];
  }

  Widget _buildOverflowMenuButton(Hymn hymn) {
    return PopupMenuButton<_HymnAction>(
      icon: const Icon(Icons.more_vert, color: AppColors.primaryText),
      tooltip: 'ተጨማሪ',
      color: AppColors.surface,
      onSelected: (action) {
        switch (action) {
          case _HymnAction.share:
            _shareHymn(hymn);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _HymnAction.share,
          child: ListTile(
            leading: Icon(Icons.share, color: AppColors.primaryText),
            title: Text(
              'አጋራ',
              style: TextStyle(color: AppColors.primaryText),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSheetMusic(Hymn hymn) async {
    var files = await _sheetMusicRepository.getFilesForHymn(hymn);
    if (!mounted) return;

    final remoteSources = files
        .where(
            (file) => file.startsWith('http://') || file.startsWith('https://'))
        .map(Uri.parse)
        .toList();
    if (remoteSources.isNotEmpty) {
      final cached = await _sheetMusicRepository.cachedFilesForSources(
        remoteSources,
      );
      if (!mounted) return;
      if (cached.isNotEmpty) {
        files = cached;
      } else {
        final downloaded = await _confirmAndDownloadSheetMusic(
          hymn,
          remoteSources,
        );
        if (!mounted) return;
        if (downloaded.isEmpty) return;
        files = downloaded;
      }
    }

    if (files.isEmpty) {
      _showComingSoonMessage('ለዚህ መዝሙር ኖታ አልተገኘም');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SheetMusicViewerPage(
          hymn: hymn,
          sheetMusicFiles: files,
        ),
      ),
    );
  }

  Future<List<String>> _confirmAndDownloadSheetMusic(
    Hymn hymn,
    List<Uri> sources,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'ኖታ ይውረድ?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: const Text(
          'ይህ ኖታ በመሣሪያዎ ላይ አልተቀመጠም። አሁን ካወረዱት በኋላ ከመስመር ውጭም መክፈት ይችላሉ።',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ይቅር'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('አውርድ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return const [];
    if (!mounted) return const [];

    var progress = 0.0;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'ኖታ በማውረድ ላይ',
              style: TextStyle(color: AppColors.primaryText),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress == 0 ? null : progress,
                  color: AppColors.accentGreen,
                ),
                const SizedBox(height: 12),
                const Text(
                  'እባክዎ ይጠብቁ...',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          );
        },
      ),
    );

    final downloaded = <String>[];
    try {
      for (final source in sources) {
        final file = await _downloadRepository.requestDownload(
          mediaType: 'sheet_music',
          hymnNumber: hymn.displayNumber,
          source: source,
          onProgress: (received, total) {
            if (total == null || total <= 0) return;
            progress = (received / total).clamp(0.0, 1.0);
          },
        );
        downloaded.add(file.path);
      }
    } catch (_) {
      if (mounted) {
        _showComingSoonMessage('ኖታውን ማውረድ አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።');
      }
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
    return downloaded;
  }

  Widget _buildFavoriteButton(Hymn hymn, bool isFavorite) {
    // Simple favorite button - no loading indicator, just instant toggle
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? AppColors.accentGreen : AppColors.primaryText,
      ),
      tooltip: isFavorite ? 'ከተወዳጅ አስወግድ' : 'ወደ ተወዳጅ ጨምር',
      onPressed: () {
        setState(() {
          _favoriteOverrides[hymn.displayNumber] = !isFavorite;
        });
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
        tooltip: 'አጋራ',
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _buildTitleSection(hymn, fontSize),
        ),
        if (!hymn.isHagerigna)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _buildMediaControls(hymn),
          ),
        Expanded(
          child: _buildLyricsViewport(hymn, fontSize),
        ),
      ],
    );
  }

  Widget _buildLyricsViewport(Hymn hymn, double fontSize) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        if (details.pointerCount >= 2) {
          _scaleStartZoom = _lyricsZoomScale;
        }
      },
      onScaleUpdate: (details) {
        if (details.pointerCount < 2) return;
        final nextScale = (_scaleStartZoom * details.scale).clamp(
          AppConstants.minZoomScale,
          AppConstants.maxZoomScale,
        );
        if ((nextScale - _lyricsZoomScale).abs() < 0.005) return;
        setState(() {
          _lyricsZoomScale = nextScale;
        });
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: _buildLyricsSection(hymn, fontSize),
      ),
    );
  }

  Widget _buildTitleSection(Hymn hymn, double fontSize) {
    return GlassContainer(
      borderRadius: 12.0,
      blurSigma: 12.0,
      opacity: 0.25,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '- ${hymn.displayNumber} -',
            style: TextStyle(
              color: AppColors.accentGreen,
              fontSize: (fontSize * 0.95).clamp(16.0, 24.0),
              fontWeight: FontWeight.w800,
              fontFamily: 'NotoSansEthiopic',
            ),
          ),
          const SizedBox(height: 6),
          _buildTitleText(hymn.displayTitle, fontSize),
        ],
      ),
    );
  }

  Widget _buildTitleText(String title, double fontSize) {
    return Text(
      title.isNotEmpty ? title : 'ርዕስ የለም',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
    // Reduced padding for more compact lyrics card
    // Keep horizontal padding consistent, reduce vertical padding
    final padding = fontSize > 24
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
        : (fontSize < 16
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10));
    final effectiveFontSize = (fontSize * _lyricsZoomScale).clamp(
      AppConstants.minFontSize * AppConstants.minZoomScale,
      AppConstants.maxFontSize * AppConstants.maxZoomScale,
    );

    return GlassContainer(
      borderRadius: 12.0,
      blurSigma: 12.0,
      opacity: 0.25,
      padding: padding,
      child: SelectableText(
        hymn.displayLyrics.isNotEmpty ? hymn.displayLyrics : 'ግጥም አልተገኘም',
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: effectiveFontSize,
          height: AppTheme.getLineHeight(effectiveFontSize),
          fontFamily: 'NotoSansEthiopic',
          letterSpacing: AppTheme.getLetterSpacing(effectiveFontSize),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.parent,
      ),
    );
  }

  Widget _buildAudioSection(Hymn hymn) {
    return AudioSectionWidget(
      hymnNumber: hymn.displayNumber,
      hymnTitle: hymn.displayTitle.isNotEmpty
          ? hymn.displayTitle
          : 'መዝሙር ${hymn.displayNumber}',
    );
  }

  Widget _buildMediaControls(Hymn hymn) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildAudioSection(hymn)),
        const SizedBox(width: 10),
        FutureBuilder<List<String>>(
          future: _sheetMusicRepository.getFilesForHymn(hymn),
          builder: (context, snapshot) {
            final hasSheetMusic = snapshot.data?.isNotEmpty ?? false;
            return _SheetMusicPreviewBox(
              enabled: hasSheetMusic,
              onTap: hasSheetMusic ? () => _openSheetMusic(hymn) : null,
            );
          },
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
            content: Text('በማጋራት ላይ ስህተት ተፈጥሯል: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

enum _HymnAction { share }

class _SheetMusicPreviewBox extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _SheetMusicPreviewBox({
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ኖታ ክፈት',
      button: enabled,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: GlassContainer(
          width: 72,
          borderRadius: 12,
          blurSigma: 12,
          opacity: enabled ? 0.25 : 0.12,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_music_outlined,
                color:
                    enabled ? AppColors.accentGreen : AppColors.secondaryText,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                enabled ? 'ኖታ' : 'የለም',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      enabled ? AppColors.primaryText : AppColors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSansEthiopic',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
