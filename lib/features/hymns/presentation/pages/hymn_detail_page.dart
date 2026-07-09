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
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
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
  Future<Hymn?>? _numberLookupFuture;
  bool _isLoadingAdjacentHymn = false;
  int? _displayedHymnNumber;
  double _lyricsZoomScale = AppConstants.defaultZoomScale;
  double _scaleStartZoom = AppConstants.defaultZoomScale;
  final Map<int, bool> _favoriteOverrides = {};
  final SheetMusicRepository _sheetMusicRepository = SheetMusicRepository();
  final DownloadRepository _downloadRepository = DownloadRepository();

  @override
  void initState() {
    super.initState();
    if (widget.hymnNumber != null && widget.hymn == null) {
      _numberLookupFuture = _loadHymnByNumber(widget.hymnNumber!);
    }
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
    if (widget.hymnNumber != null && widget.hymn == null) {
      return _buildNumberLookupView(widget.hymnNumber!);
    }

    if (widget.hymn != null) {
      return BlocListener<HymnsBloc, HymnsState>(
        listener: (context, state) {
          if (state is HymnsLoaded) {
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

    return const Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
        ),
      ),
    );
  }

  Widget _buildNumberLookupView(int hymnNumber) {
    return FutureBuilder<Hymn?>(
      future: _numberLookupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
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

        final hymn = snapshot.data;
        if (hymn == null) {
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
                      'Hymn #$hymnNumber not found.',
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

        return _buildDetailView(context, hymn);
      },
    );
  }

  Future<Hymn?> _loadHymnByNumber(int number) async {
    final settingsRepository = sl<SettingsRepository>();
    final languageCode = settingsRepository.getSelectedLanguage();
    final version = settingsRepository.getSelectedVersion();
    final result = await sl<GetHymnByNumber>()(
      GetHymnByNumberParams(
        languageCode: languageCode,
        version: version,
        number: number,
      ),
    );
    return result.fold((_) => null, (hymn) => hymn);
  }

  Widget _buildDetailView(BuildContext context, Hymn hymn) {
    _syncDisplayedHymn(hymn);
    final settingsRepository = sl<SettingsRepository>();
    final isFavorite = _favoriteOverrides[hymn.displayNumber] ??
        settingsRepository.isFavorite(hymn.displayNumber);
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
          _handleSwipe(details, hymn.displayNumber);
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
            resizeToAvoidBottomInset: false,
            bottomNavigationBar: _buildLyricsBottomNavigation(version),
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

  Widget _buildLyricsBottomNavigation(String version) {
    final showCategory = HymnalVersions.hasCategories(version);
    final items = <_LyricsNavItem>[
      if (showCategory)
        const _LyricsNavItem(
          id: 'category',
          icon: Icons.category_outlined,
          selectedIcon: Icons.category_rounded,
          label: 'ምድብ',
        ),
      const _LyricsNavItem(
        id: 'index',
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt_rounded,
        label: 'ማውጫ',
      ),
      const _LyricsNavItem(
        id: 'number',
        icon: Icons.numbers_rounded,
        selectedIcon: Icons.numbers_rounded,
        label: 'ቁጥር',
      ),
      const _LyricsNavItem(
        id: 'favorites',
        icon: Icons.favorite_outline_rounded,
        selectedIcon: Icons.favorite_rounded,
        label: 'ተወዳጅ',
      ),
      const _LyricsNavItem(
        id: 'settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: 'ቅንብር',
      ),
    ];
    final selectedIndex = items.indexWhere((item) => item.id == 'number');
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final compactLabels =
        textScale > 1.25 || MediaQuery.sizeOf(context).width < 375;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.96),
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.accentGreen : AppColors.primaryText,
            fontSize: selected
                ? (compactLabels ? 11 : 12)
                : (compactLabels ? 10 : 11),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontFamily: 'NotoSansEthiopic',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accentGreen : AppColors.primaryText,
            size: selected ? 28 : 24,
          );
        }),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          height: compactLabels ? 66 : 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            final item = items[index];
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => MainNavigationPage(
                  initialDestination: item.id,
                ),
              ),
              (route) => false,
            );
          },
          destinations: items
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  void _syncDisplayedHymn(Hymn hymn) {
    if (_displayedHymnNumber == hymn.displayNumber) return;
    _displayedHymnNumber = hymn.displayNumber;
    _lyricsZoomScale = AppConstants.defaultZoomScale;
    _scaleStartZoom = AppConstants.defaultZoomScale;
  }

  String _getVersion() {
    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded) return state.version;
    final settingsRepository = sl<SettingsRepository>();
    return settingsRepository.getSelectedVersion();
  }

  Future<void> _handleSwipe(DragEndDetails details, int currentNumber) {
    if (details.primaryVelocity == null || !mounted || _isLoadingAdjacentHymn) {
      return Future.value();
    }

    final nextNumber = switch (details.primaryVelocity!) {
      < 0 => currentNumber + 1,
      > 0 when currentNumber > 1 => currentNumber - 1,
      _ => null,
    };
    if (nextNumber == null) return Future.value();

    _isLoadingAdjacentHymn = true;
    return _loadHymnByNumber(nextNumber).then((hymn) {
      if (!mounted) return;
      if (hymn == null) {
        _showComingSoonMessage('መዝሙር #$nextNumber አልተገኘም');
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HymnDetailPage(hymn: hymn),
        ),
      );
    }).whenComplete(() {
      _isLoadingAdjacentHymn = false;
    });
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
        if (!hymn.isHagerigna)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
      englishTitle: hymn.displayEnglishTitle,
      version: _getVersion(),
    );
  }

  Widget _buildMediaControls(Hymn hymn) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMusicButton = FutureBuilder<List<String>>(
          future: _sheetMusicRepository.getFilesForHymn(hymn),
          builder: (context, snapshot) {
            final hasSheetMusic = snapshot.data?.isNotEmpty ?? false;
            return _SheetMusicPreviewBox(
              enabled: hasSheetMusic,
              onTap: hasSheetMusic ? () => _openSheetMusic(hymn) : null,
            );
          },
        );

        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAudioSection(hymn),
              sheetMusicButton,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildAudioSection(hymn)),
            const SizedBox(width: 10),
            sheetMusicButton,
          ],
        );
      },
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

class _LyricsNavItem {
  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _LyricsNavItem({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

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
