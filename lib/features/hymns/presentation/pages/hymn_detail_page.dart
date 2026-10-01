// lib/features/hymns/presentation/pages/hymn_detail_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:amharic_hymnal_app/core/widgets/app_background.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/features/settings/presentation/pages/report_bug_page.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';
import 'package:amharic_hymnal_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_media_controls.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/other_editions_line.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

/// A drag counts as a swipe between hymns only when it runs at least
/// [swipeMinDistance] sideways and at least twice as far sideways as up or
/// down. Scrolling the lyrics drifts sideways well under this.
const double swipeMinDistance = 48;
const double swipeAxisRatio = 2;

/// Whether a drag of [moved] is a swipe between hymns rather than a scroll
/// of the lyrics.
bool isHymnSwipe(Offset moved) =>
    moved.dx.abs() >= swipeMinDistance &&
    moved.dx.abs() >= moved.dy.abs() * swipeAxisRatio;

class HymnDetailPage extends StatefulWidget {
  final Hymn? hymn;
  final int? hymnNumber;
  final String sourceDestination;
  final ValueChanged<String>? onDestinationSelected;
  final ValueChanged<Hymn>? onHymnChanged;

  /// Called when this page is closed by the back arrow or the system back
  /// gesture. Moving to the next or previous hymn replaces the page instead,
  /// and does not call it.
  final VoidCallback? onClosed;

  const HymnDetailPage({
    super.key,
    this.hymn,
    this.hymnNumber,
    this.sourceDestination = 'number',
    this.onDestinationSelected,
    this.onHymnChanged,
    this.onClosed,
  });

  @override
  State<HymnDetailPage> createState() => _HymnDetailPageState();
}

class _HymnDetailPageState extends State<HymnDetailPage> {
  static const double _mediaCondenseOffset = 24;

  Offset _dragStart = Offset.zero;
  bool _isHorizontalDrag = false;

  /// The flick a swipe between hymns must be released with; the sideways
  /// drift at the end of a scroll is far slower.
  static const double _swipeMinVelocity = 300;
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
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onClosed?.call();
      },
      child: _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    if (widget.hymnNumber != null && widget.hymn == null) {
      return _buildNumberLookupView(widget.hymnNumber!);
    }

    if (widget.hymn != null) {
      return BlocListener<HymnsBloc, HymnsState>(
        listener: (context, state) {
          if (state is HymnsLoaded) {
            final updatedHymn = _updatedHymn(state, widget.hymn!);
            if (updatedHymn != null && updatedHymn != widget.hymn) {
              widget.onHymnChanged?.call(updatedHymn);
            }
          }
        },
        child: BlocBuilder<HymnsBloc, HymnsState>(
          builder: (context, state) {
            if (state is HymnsLoaded) {
              final updatedHymn = _updatedHymn(state, widget.hymn!);
              if (updatedHymn != null) {
                return _buildDetailView(context, updatedHymn);
              }
            }
            return _buildDetailView(context, widget.hymn!);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appColors.primaryBackground,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(context.appColors.accent),
        ),
      ),
    );
  }

  Hymn? _updatedHymn(HymnsLoaded state, Hymn current) {
    for (final hymn in state.hymns) {
      if (current.id != null && hymn.id == current.id) return hymn;
    }
    for (final hymn in state.hymns) {
      if (hymn.displayNumber == current.displayNumber) return hymn;
    }
    return null;
  }

  Widget _buildNumberLookupView(int hymnNumber) {
    return FutureBuilder<Hymn?>(
      future: _numberLookupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: context.appColors.primaryBackground,
            body: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(context.appColors.accent),
              ),
            ),
          );
        }

        final hymn = snapshot.data;
        if (hymn == null) {
          return Scaffold(
            backgroundColor: context.appColors.primaryBackground,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: context.appColors.secondaryText,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hymn #$hymnNumber not found.',
                      style: TextStyle(
                        color: context.appColors.primaryText,
                        fontSize: 16,
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
        _dragStart = details.globalPosition;
        _isHorizontalDrag = false;
      },
      onHorizontalDragUpdate: (details) {
        if (_isLyricsPinching) {
          _isHorizontalDrag = false;
          return;
        }
        // Both measured over the whole drag: a slow scroll drifts sideways
        // a little on every frame, which used to read as a swipe.
        final moved = details.globalPosition - _dragStart;
        _isHorizontalDrag = isHymnSwipe(moved);
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity;
        if (!_isLyricsPinching &&
            _isHorizontalDrag &&
            velocity != null &&
            velocity.abs() >= _swipeMinVelocity) {
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
        label: 'ቅንብሮች',
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
        _showComingSoonMessage('መዝሙር ቁጥር $nextNumber አልተገኘም');
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
            onClosed: widget.onClosed,
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
          // Use RepaintBoundary to isolate background rendering and
          // prevent flickering
          return RepaintBoundary(
            child: Container(decoration: appBackgroundDecoration(context)),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: context.appColors.primaryText,
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
      _buildReportButton(hymn),
    ];
  }

  Widget _buildOverflowMenuButton(Hymn hymn) {
    return PopupMenuButton<_HymnAction>(
      icon: Icon(Icons.more_vert, color: context.appColors.primaryText),
      tooltip: 'ተጨማሪ',
      color: context.appColors.surface,
      onSelected: (action) {
        switch (action) {
          case _HymnAction.share:
            _shareHymn(hymn);
          case _HymnAction.report:
            _reportProblem(hymn);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _HymnAction.share,
          child: ListTile(
            leading: Icon(Icons.share, color: context.appColors.primaryText),
            title: Text(
              'አጋራ',
              style: TextStyle(color: context.appColors.primaryText),
            ),
          ),
        ),
        PopupMenuItem(
          value: _HymnAction.report,
          child: ListTile(
            leading:
                Icon(Icons.flag_outlined, color: context.appColors.primaryText),
            title: Text(
              'የስህተት ጥቆማ',
              style: TextStyle(color: context.appColors.primaryText),
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
        color: isFavorite
            ? context.appColors.accent
            : context.appColors.primaryText,
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
        icon: Icon(Icons.share, color: context.appColors.primaryText),
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
        OtherEditionsLine(hymn: hymn),
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
      // The builder's context is inside the Scaffold's body, which is where
      // the floating bar's height is reported; the page's own context is
      // above it and would report nothing.
      child: Builder(
        builder: (bodyContext) => SingleChildScrollView(
          controller: _lyricsScrollController,
          // Always scrollable, so a short hymn's lyrics still take an upward
          // drag instead of leaving it to the swipe between hymns.
          physics: _isLyricsPinching
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          // The lyrics scroll behind the bar, so the last line needs the
          // bar's height to clear it at any text size.
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.paddingOf(bodyContext).bottom,
          ),
          child: _buildLyricsSection(hymn, fontSize),
        ),
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
      opacity: context.appColors.glassOpacityOverPhoto,
      padding: padding,
      // The size below is already the reader's own choice, seeded from the
      // system's text size on a fresh install, so the system scale is not
      // applied to it a second time.
      child: SelectableText(
        hymn.displayLyrics.isNotEmpty ? hymn.displayLyrics : 'ግጥም አልተገኘም',
        textScaler: TextScaler.noScaling,
        style: AppTheme.lyricsTextStyle(
          color: context.appColors.primaryText,
          fontSize: effectiveFontSize,
        ),
        textAlign: TextAlign.start,
        textWidthBasis: TextWidthBasis.parent,
      ),
    );
  }

  Widget _buildReportButton(Hymn hymn) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(Icons.flag_outlined, color: context.appColors.primaryText),
        tooltip: 'የስህተት ጥቆማ',
        onPressed: () => _reportProblem(hymn),
      ),
    );
  }

  /// Opens the report screen with this hymn attached, so a wrong word or
  /// page reaches the admin with the hymn already identified.
  void _reportProblem(Hymn hymn) {
    // Over the whole app: the floating navigation bar would otherwise cover
    // the form's send button.
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ReportBugPage(hymn: hymn)),
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
            content: Text('በማጋራት ላይ ስህተት ተከስቷል: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

enum _HymnAction { share, report }

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
