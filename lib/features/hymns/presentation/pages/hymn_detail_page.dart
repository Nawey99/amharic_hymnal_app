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
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';
import 'package:amharic_hymnal_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_media_controls.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class HymnDetailPage extends StatefulWidget {
  final Hymn? hymn;
  final int? hymnNumber;
  final String sourceDestination;
  final ValueChanged<String>? onDestinationSelected;
  final ValueChanged<Hymn>? onHymnChanged;

  const HymnDetailPage({
    super.key,
    this.hymn,
    this.hymnNumber,
    this.sourceDestination = 'number',
    this.onDestinationSelected,
    this.onHymnChanged,
  });

  @override
  State<HymnDetailPage> createState() => _HymnDetailPageState();
}

class _HymnDetailPageState extends State<HymnDetailPage> {
  static const double _mediaCondenseOffset = 24;

  double _horizontalDragStart = 0.0;
  bool _isHorizontalDrag = false;
  Future<Hymn?>? _numberLookupFuture;
  bool _isLoadingAdjacentHymn = false;
  int? _displayedHymnNumber;
  double? _lyricsPreviewFontSize;
  double _pinchStartFontSize = AppConstants.defaultFontSize;
  final Map<int, Offset> _activeLyricsPointers = {};
  List<int>? _lyricsPinchPointerIds;
  double _lyricsPinchStartDistance = 0;
  bool _isLyricsPinching = false;
  final Map<int, bool> _favoriteOverrides = {};
  final ScrollController _lyricsScrollController = ScrollController();
  bool _isMediaCondensed = false;

  @override
  void initState() {
    super.initState();
    _lyricsScrollController.addListener(_handleLyricsScroll);
    if (widget.hymnNumber != null && widget.hymn == null) {
      _numberLookupFuture = _loadHymnByNumber(widget.hymnNumber!);
    }
    // Track hymn view in history
    _trackHymnView();
  }

  @override
  void dispose() {
    _lyricsScrollController.removeListener(_handleLyricsScroll);
    _lyricsScrollController.dispose();
    super.dispose();
  }

  void _handleLyricsScroll() {
    if (!_lyricsScrollController.hasClients) return;

    final position = _lyricsScrollController.position;
    final shouldCondense =
        position.maxScrollExtent > 0 && position.pixels > _mediaCondenseOffset;
    if (shouldCondense == _isMediaCondensed || !mounted) return;

    setState(() => _isMediaCondensed = shouldCondense);
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
        if (_isLyricsPinching) return;
        _horizontalDragStart = details.globalPosition.dx;
        _isHorizontalDrag = false;
      },
      onHorizontalDragUpdate: (details) {
        if (_isLyricsPinching) {
          _isHorizontalDrag = false;
          return;
        }
        // Check if this is a primarily horizontal drag (not diagonal)
        final deltaX = details.globalPosition.dx - _horizontalDragStart;
        final deltaY = details.delta.dy.abs();

        // If horizontal movement is much greater than vertical, it's a swipe
        if (deltaX.abs() > 20 && deltaX.abs() > deltaY * 2) {
          _isHorizontalDrag = true;
        }
      },
      onHorizontalDragEnd: (details) {
        if (!_isLyricsPinching &&
            _isHorizontalDrag &&
            details.primaryVelocity != null) {
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
            extendBody: true,
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
    final selectedIndex = items.indexWhere(
      (item) => item.id == widget.sourceDestination,
    );
    return AppBottomNavigationBar(
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      destinations: items
          .map(
            (item) => AppNavigationDestination(
              id: item.id,
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
            ),
          )
          .toList(growable: false),
      onDestinationSelected: (index) {
        final item = items[index];
        final onDestinationSelected = widget.onDestinationSelected;
        if (onDestinationSelected != null) {
          onDestinationSelected(item.id);
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainNavigationPage(
              initialDestination: item.id,
            ),
          ),
          (route) => false,
        );
      },
    );
  }

  void _syncDisplayedHymn(Hymn hymn) {
    if (_displayedHymnNumber == hymn.displayNumber) return;
    _displayedHymnNumber = hymn.displayNumber;
    _lyricsPreviewFontSize = null;
    _pinchStartFontSize = FontSizeService().getFontSize();
    _activeLyricsPointers.clear();
    _lyricsPinchPointerIds = null;
    _lyricsPinchStartDistance = 0;
    _isLyricsPinching = false;
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
      widget.onHymnChanged?.call(hymn);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HymnDetailPage(
            hymn: hymn,
            sourceDestination: widget.sourceDestination,
            onDestinationSelected: widget.onDestinationSelected,
            onHymnChanged: widget.onHymnChanged,
          ),
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
            child: HymnMediaControls(
              hymn: hymn,
              version: _getVersion(),
              condensed: _isMediaCondensed,
            ),
          ),
        Expanded(
          child: _buildLyricsViewport(hymn, fontSize),
        ),
      ],
    );
  }

  Widget _buildLyricsViewport(Hymn hymn, double fontSize) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handleLyricsPointerDown,
      onPointerMove: _handleLyricsPointerMove,
      onPointerUp: _handleLyricsPointerEnd,
      onPointerCancel: _handleLyricsPointerEnd,
      child: SingleChildScrollView(
        controller: _lyricsScrollController,
        physics:
            _isLyricsPinching ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: _buildLyricsSection(hymn, fontSize),
      ),
    );
  }

  void _handleLyricsPointerDown(PointerDownEvent event) {
    _activeLyricsPointers[event.pointer] = event.localPosition;
    if (_lyricsPinchPointerIds != null || _activeLyricsPointers.length < 2) {
      return;
    }

    final pointerIds = _activeLyricsPointers.keys.take(2).toList();
    final firstPosition = _activeLyricsPointers[pointerIds.first]!;
    final secondPosition = _activeLyricsPointers[pointerIds.last]!;
    final startDistance = (firstPosition - secondPosition).distance;
    if (startDistance <= 0) return;

    _lyricsPinchPointerIds = pointerIds;
    _lyricsPinchStartDistance = startDistance;
    _pinchStartFontSize =
        _lyricsPreviewFontSize ?? FontSizeService().getFontSize();
    _isHorizontalDrag = false;
    if (!_isLyricsPinching && mounted) {
      setState(() => _isLyricsPinching = true);
    }
  }

  void _handleLyricsPointerMove(PointerMoveEvent event) {
    if (!_activeLyricsPointers.containsKey(event.pointer)) return;
    _activeLyricsPointers[event.pointer] = event.localPosition;

    final pointerIds = _lyricsPinchPointerIds;
    if (pointerIds == null || !pointerIds.contains(event.pointer)) return;
    final firstPosition = _activeLyricsPointers[pointerIds.first];
    final secondPosition = _activeLyricsPointers[pointerIds.last];
    if (firstPosition == null || secondPosition == null) return;

    final distance = (firstPosition - secondPosition).distance;
    final scaleDelta = distance / _lyricsPinchStartDistance;
    final nextFontSize = (_pinchStartFontSize * scaleDelta).clamp(
      AppConstants.minFontSize,
      AppConstants.maxFontSize,
    );
    final currentFontSize =
        _lyricsPreviewFontSize ?? FontSizeService().getFontSize();
    if ((nextFontSize - currentFontSize).abs() < 0.005) return;
    setState(() => _lyricsPreviewFontSize = nextFontSize);
  }

  void _handleLyricsPointerEnd(PointerEvent event) {
    _activeLyricsPointers.remove(event.pointer);
    if (_lyricsPinchPointerIds?.contains(event.pointer) ?? false) {
      _lyricsPinchPointerIds = null;
    }
    if (!_isLyricsPinching || _activeLyricsPointers.isNotEmpty) return;

    final previewFontSize = _lyricsPreviewFontSize;
    setState(() => _isLyricsPinching = false);
    if (previewFontSize != null) {
      unawaited(_persistLyricsFontSize(previewFontSize));
    }
  }

  Future<void> _persistLyricsFontSize(double fontSize) async {
    await FontSizeService().setFontSize(fontSize);
    if (!mounted || _isLyricsPinching) return;

    final previewFontSize = _lyricsPreviewFontSize;
    if (previewFontSize == null || (previewFontSize - fontSize).abs() > 0.005) {
      return;
    }
    setState(() => _lyricsPreviewFontSize = null);
  }

  Widget _buildLyricsSection(Hymn hymn, double fontSize) {
    final effectiveFontSize = (_lyricsPreviewFontSize ?? fontSize).clamp(
      AppConstants.minFontSize,
      AppConstants.maxFontSize,
    );
    // Reduced padding for more compact lyrics card
    // Keep horizontal padding consistent, reduce vertical padding
    final padding = effectiveFontSize > 24
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
        : (effectiveFontSize < 16
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10));

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
