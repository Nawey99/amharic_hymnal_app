// lib/features/hymns/presentation/pages/index_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/search_state_controller.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/amharic_utils.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/core/widgets/search_text_field.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/alphabet_scroll_bar.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> with WidgetsBindingObserver {
  static const double _estimatedHymnItemExtent = 96.0;
  static const double _listVerticalPadding = 8.0;

  final SearchStateController _searchController = SearchStateController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _listViewportKey = GlobalKey();
  final Map<String, GlobalKey> _hymnItemKeys = {};
  bool _isSearchVisible = false;
  StreamSubscription<String>? _searchSubscription;
  String _currentSectionLetter =
      ''; // Track current section letter for dynamic updates
  String _sortTypeBeforeSearch = 'number';
  // Local search query tracking for page independence
  // Used to determine if page should reload full list when becoming visible
  String _localSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Add scroll listener to update section indicator dynamically
    _scrollController.addListener(_updateSectionIndicator);
    _searchSubscription = _searchController.queryStream.listen((query) {
      if (!mounted) return;
      _handleSearchQuery(query);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchSubscription?.cancel();
    _scrollController.removeListener(_updateSectionIndicator);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When page becomes visible, reload full list if no local search
    // This ensures search independence between pages
    final isVisible = ModalRoute.of(context)?.isCurrent ?? false;
    if (isVisible && _localSearchQuery.isEmpty) {
      // Clear any search state from other pages by reloading full list
      final currentState = context.read<HymnsBloc>().state;
      if (currentState is HymnsLoaded) {
        // Only reload if current state is from a search without a local query.
        // This prevents unnecessary reloads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _localSearchQuery.isEmpty) {
            context.read<HymnsBloc>().add(
                  LoadHymns(
                    currentState.languageCode,
                    currentState.version,
                    currentState.sortType == 'search'
                        ? _sortTypeBeforeSearch
                        : currentState.sortType,
                  ),
                );
          }
        });
      }
    }
  }

  /// Update section indicator based on current scroll position
  void _updateSectionIndicator() {
    if (!_scrollController.hasClients) return;

    final state = context.read<HymnsBloc>().state;
    if (state is! HymnsLoaded ||
        state.sortType != 'name' ||
        state.hymns.isEmpty) {
      return;
    }

    final hymnsToDisplay = _hymnsForDisplay(state.hymns, state.sortType);
    if (hymnsToDisplay.isEmpty) return;

    final topmostIndex = _topVisibleHymnIndex(hymnsToDisplay);
    if (topmostIndex == null) return;

    final topmostHymn = hymnsToDisplay[topmostIndex];
    final topmostTitle = _titleForIndexing(topmostHymn);
    final topmostLetter = _getFirstLetter(topmostTitle);

    if (topmostLetter != _currentSectionLetter) {
      setState(() {
        _currentSectionLetter = topmostLetter;
      });
    }
  }

  // Get primary Amharic letter (first character of the family)
  String _getFirstLetter(String text) {
    return AmharicUtils.getPrimaryLetter(text);
  }

  Map<String, int> _buildAlphabetIndex(List<Hymn> hymns) {
    final Map<String, int> index = {};
    for (int i = 0; i < hymns.length; i++) {
      final title = _titleForIndexing(hymns[i]);
      final firstLetter = _getFirstLetter(title);
      if (!index.containsKey(firstLetter)) {
        index[firstLetter] = i;
      }
    }
    return index;
  }

  void _scrollToLetter(String letter) {
    final state = context.read<HymnsBloc>().state;
    if (state is! HymnsLoaded) return;

    // Only scroll when sorted by name
    if (state.sortType != 'name') return;

    final hymnsToDisplay = _hymnsForDisplay(state.hymns, state.sortType);
    final index = _buildAlphabetIndex(hymnsToDisplay);
    final position = index[letter];
    if (position != null && _scrollController.hasClients) {
      setState(() {
        _currentSectionLetter = letter;
      });

      // Calculate an approximate scroll position. Rows have dynamic height to
      // avoid overflow when text scale or window size changes.
      const itemHeight = _estimatedHymnItemExtent;
      const listPadding = _listVerticalPadding;
      final scrollPosition = (position * itemHeight) + listPadding;

      // Ensure we don't scroll beyond the list
      if (_scrollController.position.maxScrollExtent > 0) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetPosition = scrollPosition.clamp(0.0, maxScroll);

        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        Future.delayed(const Duration(milliseconds: 340), () {
          if (!mounted || position >= hymnsToDisplay.length) return;
          _alignHymnWithViewportTop(hymnsToDisplay[position]);
        });
      }
    }
  }

  int? _topVisibleHymnIndex(List<Hymn> hymns) {
    final viewportContext = _listViewportKey.currentContext;
    final viewportBox = viewportContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.hasSize) {
      return _estimatedTopVisibleIndex(hymns.length);
    }

    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportBox.size.height;
    int? bestIndex;
    double? bestTop;

    for (var index = 0; index < hymns.length; index++) {
      final itemContext = _keyForHymn(hymns[index]).currentContext;
      final itemBox = itemContext?.findRenderObject() as RenderBox?;
      if (itemBox == null || !itemBox.hasSize) continue;

      final itemTop = itemBox.localToGlobal(Offset.zero).dy;
      final itemBottom = itemTop + itemBox.size.height;
      if (itemBottom <= viewportTop || itemTop >= viewportBottom) continue;

      if (bestTop == null || itemTop < bestTop) {
        bestTop = itemTop;
        bestIndex = index;
      }
    }

    return bestIndex ?? _estimatedTopVisibleIndex(hymns.length);
  }

  int? _estimatedTopVisibleIndex(int hymnCount) {
    if (hymnCount == 0 || !_scrollController.hasClients) return null;
    final estimated = ((_scrollController.offset - _listVerticalPadding) /
            _estimatedHymnItemExtent)
        .floor();
    return estimated.clamp(0, hymnCount - 1).toInt();
  }

  void _alignHymnWithViewportTop(Hymn hymn) {
    if (!_scrollController.hasClients) return;

    final viewportContext = _listViewportKey.currentContext;
    final viewportBox = viewportContext?.findRenderObject() as RenderBox?;
    final itemContext = _keyForHymn(hymn).currentContext;
    final itemBox = itemContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null ||
        itemBox == null ||
        !viewportBox.hasSize ||
        !itemBox.hasSize) {
      return;
    }

    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final itemTop = itemBox.localToGlobal(Offset.zero).dy;
    final target = (_scrollController.offset + itemTop - viewportTop)
        .clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        )
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
  }

  GlobalKey _keyForHymn(Hymn hymn) {
    return _hymnItemKeys.putIfAbsent(_hymnKey(hymn), GlobalKey.new);
  }

  String _hymnKey(Hymn hymn) {
    return hymn.id ?? '${hymn.displayNumber}_${hymn.displayTitle}';
  }

  String _titleForIndexing(Hymn hymn) {
    return hymn.displayTitle.isNotEmpty
        ? hymn.displayTitle
        : 'መዝሙር ${hymn.displayNumber}';
  }

  @override
  Widget build(BuildContext context) {
    // Optimize: Only listen to background image changes when enabled
    final bgService = BackgroundImageService();
    if (bgService.isEnabled) {
      return ListenableBuilder(
        listenable: bgService,
        builder: (context, _) => _buildPageContent(context),
      );
    }
    // Skip ListenableBuilder when background is disabled for better performance
    return _buildPageContent(context);
  }

  Widget _buildPageContent(BuildContext context) {
    final bgService = BackgroundImageService();
    return Container(
      decoration: _buildBackgroundDecoration(bgService),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            _buildSectionIndicator(),
            _buildHymnList(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(BackgroundImageService bgService) {
    return BoxDecoration(
      image: bgService.isEnabled
          ? DecorationImage(
              image: _getBackgroundImage(),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.8),
                BlendMode.darken,
              ),
            )
          : null,
      color: bgService.isEnabled ? null : AppColors.primaryBackground,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: GlassContainer(
        borderRadius: 16.0,
        blurSigma: 12.0,
        opacity: 0.15,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'መዝሙር ማውጫ',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansEthiopic',
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isSearchVisible ? Icons.close : Icons.search,
                color: AppColors.primaryText,
              ),
              onPressed: () => _toggleSearch(context),
            ),
            IconButton(
              icon: const Icon(Icons.sort, color: AppColors.primaryText),
              onPressed: () => _showSortDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSearch(BuildContext context) {
    final willShowSearch = !_isSearchVisible;
    setState(() {
      _isSearchVisible = willShowSearch;
      if (!willShowSearch) {
        _searchFocusNode.unfocus();
      } else {
        Future.delayed(
          const Duration(milliseconds: 100),
          () => _searchFocusNode.requestFocus(),
        );
      }
    });
    if (willShowSearch && _searchController.currentQuery.isNotEmpty) {
      _handleSearchQuery(_searchController.currentQuery);
    }
  }

  void _reloadHymns(BuildContext context) {
    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded) {
      final sortType =
          state.sortType == 'search' ? _sortTypeBeforeSearch : state.sortType;
      context.read<HymnsBloc>().add(
            LoadHymns(state.languageCode, state.version, sortType),
          );
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _isSearchVisible
          ? _buildSearchField(context)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return SearchTextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'መዝሙር ይፈልጉ...',
      autofocus: true,
      onClear: () => _reloadHymns(context),
    );
  }

  void _handleSearchQuery(String value) {
    setState(() {
      _localSearchQuery = value;
    });

    // If empty, reload immediately
    if (value.isEmpty) {
      _reloadHymns(context);
      return;
    }

    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded && mounted) {
      if (state.sortType != 'search') {
        _sortTypeBeforeSearch = state.sortType;
      }
      context.read<HymnsBloc>().add(
            SearchHymnsEvent(state.languageCode, state.version, value),
          );
    }
  }

  Widget _buildSectionIndicator() {
    return BlocBuilder<HymnsBloc, HymnsState>(
      builder: (context, state) {
        if (state is HymnsLoaded &&
            state.sortType == 'name' &&
            state.hymns.isNotEmpty) {
          // Use current section letter if available, otherwise use first hymn's letter
          final firstHymnTitle = state.hymns.first.displayTitle.isNotEmpty
              ? state.hymns.first.displayTitle
              : 'መዝሙር ${state.hymns.first.displayNumber}';
          final displayLetter = _currentSectionLetter.isNotEmpty
              ? _currentSectionLetter
              : _getFirstLetter(firstHymnTitle);

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                displayLetter,
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansEthiopic',
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHymnList() {
    return Expanded(
      child: Stack(
        key: _listViewportKey,
        children: [
          _buildHymnListView(),
          _buildAlphabetScrollBar(),
          _buildNumberJumpRail(),
        ],
      ),
    );
  }

  Widget _buildHymnListView() {
    return BlocBuilder<HymnsBloc, HymnsState>(
      buildWhen: (previous, current) {
        // Only rebuild when state type changes or hymns list changes
        if (previous.runtimeType != current.runtimeType) return true;
        if (previous is HymnsLoaded && current is HymnsLoaded) {
          return previous.hymns.length != current.hymns.length ||
              previous.sortType != current.sortType ||
              previous.version != current.version;
        }
        return true;
      },
      builder: (context, state) {
        if (state is HymnsLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          );
        }
        if (state is HymnsError) {
          return ErrorStateWidget(
            message: state.message,
          );
        }
        if (state is HymnsLoaded) {
          if (state.hymns.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.music_note,
              title: AppLocalizations.of(context)?.noHymnsFound ??
                  'No hymns found',
            );
          }
          return _buildHymnListItems(state.hymns);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildHymnListItems(List<Hymn> hymns) {
    final state = context.read<HymnsBloc>().state;
    final hasAlphabetScrollBar =
        state is HymnsLoaded && state.sortType == 'name';
    final hasNumberRail = state is HymnsLoaded && state.sortType == 'number';
    final sortType = state is HymnsLoaded ? state.sortType : null;
    final hymnsToDisplay = _hymnsForDisplay(hymns, sortType);

    // Step 5: Add empty state handling
    if (hymnsToDisplay.isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ No hymns to display - showing empty state');
      }
      return EmptyStateWidget(
        icon: Icons.music_note,
        title: AppLocalizations.of(context)?.noHymnsFound ?? 'No hymns found',
        message: state is HymnsLoaded && state.sortType == 'name'
            ? 'በስም ለማደራጀት መዝሙር አልተገኘም'
            : null,
      );
    }

    // Step 3: Fix ListView Rendering - Ensure proper constraints and visibility
    // Conditionally apply right padding only when sorted by name (for alphabet scrollbar)
    final rightPadding = (hasAlphabetScrollBar || hasNumberRail) ? 54.0 : 16.0;

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: false, // Explicitly set to false for proper rendering
      // Add right padding only when sorted by name to prevent overlap with alphabet scrollbar
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        rightPadding,
        NavBarConstants.getBottomPadding(context),
      ),
      itemCount: hymnsToDisplay.length,
      // Performance: Cache items for smoother scrolling
      cacheExtent: 250.0,
      itemBuilder: (context, index) {
        if (index >= hymnsToDisplay.length) {
          if (kDebugMode) {
            debugPrint(
                '❌ Index out of bounds: $index >= ${hymnsToDisplay.length}');
          }
          return const SizedBox.shrink();
        }
        final hymn = hymnsToDisplay[index];

        // Wrap in RepaintBoundary for performance optimization
        return RepaintBoundary(
          key: _keyForHymn(hymn),
          child: HymnListItem(
            hymn: hymn,
            onTap: () => _navigateToHymnDetail(context, hymn),
            sortType: state is HymnsLoaded
                ? state.sortType
                : null, // Pass sort type for height adjustment
          ),
        );
      },
    );
  }

  void _navigateToHymnDetail(BuildContext context, Hymn hymn) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HymnDetailPage(hymn: hymn)),
    );
  }

  Widget _buildAlphabetScrollBar() {
    return BlocBuilder<HymnsBloc, HymnsState>(
      builder: (context, state) {
        if (state is HymnsLoaded && state.sortType == 'name') {
          final hymnsToDisplay = _hymnsForDisplay(
            state.hymns,
            state.sortType,
          );
          final letters = _buildAlphabetIndex(hymnsToDisplay).keys.toList();
          if (letters.isEmpty) return const SizedBox();
          return AlphabetScrollBar(
            letters: letters,
            onLetterSelected: _scrollToLetter,
            bottomPadding: NavBarConstants.getBottomPadding(context),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildNumberJumpRail() {
    return BlocBuilder<HymnsBloc, HymnsState>(
      builder: (context, state) {
        if (state is! HymnsLoaded || state.sortType != 'number') {
          return const SizedBox.shrink();
        }
        final hymnsToDisplay = _hymnsForDisplay(state.hymns, state.sortType);
        if (hymnsToDisplay.length < 80) return const SizedBox.shrink();

        const jumpPoints = [
          (1, '1'),
          (50, '50'),
          (100, '100'),
          (150, '150'),
          (200, '200'),
          (250, '250'),
          (300, '300'),
        ];
        final bottomPadding = NavBarConstants.getBottomPadding(context);
        return Positioned(
          right: 14,
          top: 8,
          bottom: bottomPadding,
          child: SafeArea(
            left: false,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: jumpPoints
                        .map(
                          (point) => InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => _scrollToNearestNumber(
                              point.$1,
                              hymnsToDisplay,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 5,
                              ),
                              child: Text(
                                point.$2,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'NotoSansEthiopic',
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _scrollToNearestNumber(int number, List<Hymn> hymns) {
    if (!_scrollController.hasClients || hymns.isEmpty) return;
    var targetIndex = hymns.indexWhere((hymn) => hymn.displayNumber >= number);
    if (targetIndex < 0) targetIndex = hymns.length - 1;
    final scrollPosition =
        (targetIndex * _estimatedHymnItemExtent) + _listVerticalPadding;
    final target = scrollPosition
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _showSortDialog(BuildContext context) {
    final currentState = context.read<HymnsBloc>().state;
    if (currentState is! HymnsLoaded) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'አደራደር',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: _buildSortOptions(currentState),
      ),
    );
  }

  Widget _buildSortOptions(HymnsLoaded state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSortOption(
          'በቁጥር',
          'number',
          state.sortType,
          () => _applySort(state, 'number'),
        ),
        _buildSortOption(
          'በስም',
          'name',
          state.sortType,
          () => _applySort(state, 'name'),
        ),
      ],
    );
  }

  Widget _buildSortOption(
    String title,
    String value,
    String currentValue,
    VoidCallback onSelected,
  ) {
    final isSelected = currentValue == value;
    IconData icon;

    // Choose appropriate icon for each sort type
    switch (value) {
      case 'name':
        icon = Icons.sort_by_alpha;
        break;
      case 'number':
        icon = Icons.numbers;
        break;
      case 'category':
        icon = Icons.category;
        break;
      default:
        icon = Icons.sort;
    }

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGreen.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accentGreen.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppColors.accentGreen : AppColors.secondaryText,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accentGreen
                      : AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.accentGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _applySort(HymnsLoaded state, String sortType) {
    setState(() {
      _currentSectionLetter = '';
      _sortTypeBeforeSearch = sortType;
    });
    context.read<HymnsBloc>().add(
          ChangeSort(state.languageCode, state.version, sortType),
        );
    Navigator.pop(context);
  }

  ImageProvider _getBackgroundImage() {
    return const AssetImage('assets/images/background.jpg');
  }

  List<Hymn> _hymnsForDisplay(List<Hymn> hymns, String? sortType) {
    final validHymns = hymns.where((hymn) {
      final hasNumber = hymn.displayNumber > 0;
      if (sortType == 'name') {
        final hasValidTitle = hymn.displayTitle.trim().isNotEmpty;
        return hasNumber || hasValidTitle;
      }

      final hasTitle = hymn.displayTitle.isNotEmpty;
      final hasLyrics = hymn.displayLyrics.isNotEmpty;
      return hasNumber || hasTitle || hasLyrics;
    }).toList();

    if (kDebugMode && validHymns.length != hymns.length) {
      debugPrint(
        '📊 Filtered ${hymns.length - validHymns.length} empty hymns from list',
      );
    }

    return validHymns.isEmpty && hymns.isNotEmpty ? hymns : validHymns;
  }
}
