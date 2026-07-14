// lib/features/hymns/presentation/pages/index_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/search_state_controller.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/index_section_utils.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/core/widgets/main_page_title_bar.dart';
import 'package:amharic_hymnal_app/core/widgets/search_text_field.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_open_callback.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/alphabet_scroll_bar.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';

class IndexPage extends StatefulWidget {
  final HymnOpenCallback? onOpenHymn;

  const IndexPage({super.key, this.onOpenHymn});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  static const double _estimatedHymnItemExtent = 96.0;
  static const double _listVerticalPadding = 8.0;
  static const double _alphabetRailBottomPadding = 8.0;
  static const int _maxSectionJumpRefinements = 4;

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
  int _sectionJumpGeneration = 0;
  bool _isSectionJumpInProgress = false;
  double _lastMeasuredHymnItemExtent = _estimatedHymnItemExtent;
  @override
  void initState() {
    super.initState();
    // Add scroll listener to update section indicator dynamically
    _scrollController.addListener(_updateSectionIndicator);
    _searchSubscription = _searchController.queryStream.listen((query) {
      if (!mounted) return;
      _handleSearchQuery(query);
    });
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    _scrollController.removeListener(_updateSectionIndicator);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Update section indicator based on current scroll position
  void _updateSectionIndicator() {
    if (!_scrollController.hasClients || _isSectionJumpInProgress) return;

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
    return amharicSectionForText(text);
  }

  Map<String, int> _buildAlphabetIndex(List<Hymn> hymns) {
    return buildSectionIndex<Hymn>(
      hymns,
      _titleForIndexing,
      amharicSectionForText,
    );
  }

  void _scrollToLetter(String letter) {
    final state = context.read<HymnsBloc>().state;
    if (state is! HymnsLoaded) return;

    // Only scroll when sorted by name
    if (state.sortType != 'name') return;

    final hymnsToDisplay = _hymnsForDisplay(state.hymns, state.sortType);
    final index = _buildAlphabetIndex(hymnsToDisplay);
    final position = nearestSectionIndex(
      letter,
      amharicFidelIndexOrder,
      index,
    );
    if (position != null && _scrollController.hasClients) {
      final jumpGeneration = ++_sectionJumpGeneration;
      _isSectionJumpInProgress = true;
      setState(() {
        _currentSectionLetter = letter;
      });

      // Jump immediately while the user scrubs across letters. Rendered rows
      // are measured because their responsive height is not a fixed 96 pixels.
      final itemHeight = _measuredHymnItemExtent(hymnsToDisplay);
      final scrollPosition = (position * itemHeight) + _listVerticalPadding;

      // Ensure we don't scroll beyond the list
      if (_scrollController.position.maxScrollExtent > 0) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetPosition = scrollPosition.clamp(0.0, maxScroll);

        _scrollController.jumpTo(targetPosition);
        _scheduleSectionJumpRefinement(
          hymns: hymnsToDisplay,
          targetIndex: position,
          targetLetter: letter,
          jumpGeneration: jumpGeneration,
        );
      } else {
        _isSectionJumpInProgress = false;
      }
    }
  }

  void _scheduleSectionJumpRefinement({
    required List<Hymn> hymns,
    required int targetIndex,
    required String targetLetter,
    required int jumpGeneration,
    int attempt = 0,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          jumpGeneration != _sectionJumpGeneration ||
          targetIndex >= hymns.length ||
          !_scrollController.hasClients) {
        return;
      }

      if (_alignHymnWithViewportTop(hymns[targetIndex])) {
        _finishSectionJump(jumpGeneration, targetLetter);
        return;
      }

      final visibleIndex = _topVisibleHymnIndex(hymns);
      if (visibleIndex != null &&
          visibleIndex != targetIndex &&
          attempt < _maxSectionJumpRefinements) {
        final itemHeight = _measuredHymnItemExtent(hymns);
        final target = (_scrollController.offset +
                ((targetIndex - visibleIndex) * itemHeight))
            .clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            )
            .toDouble();
        if ((_scrollController.offset - target).abs() >= 1) {
          _scrollController.jumpTo(target);
        }
        _scheduleSectionJumpRefinement(
          hymns: hymns,
          targetIndex: targetIndex,
          targetLetter: targetLetter,
          jumpGeneration: jumpGeneration,
          attempt: attempt + 1,
        );
        return;
      }

      _finishSectionJump(jumpGeneration, targetLetter);
    });
  }

  void _finishSectionJump(int jumpGeneration, String targetLetter) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || jumpGeneration != _sectionJumpGeneration) return;
      _isSectionJumpInProgress = false;
      if (_currentSectionLetter != targetLetter) {
        setState(() {
          _currentSectionLetter = targetLetter;
        });
      }
    });
  }

  double _measuredHymnItemExtent(List<Hymn> hymns) {
    final renderedHeights = <double>[];
    for (final hymn in hymns) {
      final itemBox =
          _keyForHymn(hymn).currentContext?.findRenderObject() as RenderBox?;
      if (itemBox != null && itemBox.hasSize && itemBox.size.height > 0) {
        renderedHeights.add(itemBox.size.height);
      }
    }
    if (renderedHeights.isEmpty) return _lastMeasuredHymnItemExtent;

    renderedHeights.sort();
    final middle = renderedHeights.length ~/ 2;
    final median = renderedHeights.length.isOdd
        ? renderedHeights[middle]
        : (renderedHeights[middle - 1] + renderedHeights[middle]) / 2;
    _lastMeasuredHymnItemExtent = median;
    return median;
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
            _lastMeasuredHymnItemExtent)
        .floor();
    return estimated.clamp(0, hymnCount - 1).toInt();
  }

  bool _alignHymnWithViewportTop(Hymn hymn) {
    if (!_scrollController.hasClients) return false;

    final viewportContext = _listViewportKey.currentContext;
    final viewportBox = viewportContext?.findRenderObject() as RenderBox?;
    final itemContext = _keyForHymn(hymn).currentContext;
    final itemBox = itemContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null ||
        itemBox == null ||
        !viewportBox.hasSize ||
        !itemBox.hasSize) {
      return false;
    }

    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final itemTop = itemBox.localToGlobal(Offset.zero).dy;
    final target = (_scrollController.offset + itemTop - viewportTop)
        .clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        )
        .toDouble();
    if ((_scrollController.offset - target).abs() >= 1) {
      _scrollController.jumpTo(target);
    }
    return true;
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
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) => _buildPageContent(context),
    );
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
    return MainPageTitleBar(
      title: 'መዝሙር ማውጫ',
      actions: [
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
    );
  }

  void _toggleSearch(BuildContext context) {
    final willShowSearch = !_isSearchVisible;
    setState(() {
      _isSearchVisible = willShowSearch;
      if (!willShowSearch) {
        _searchFocusNode.unfocus();
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
      autofocus: false,
      onClear: () => _reloadHymns(context),
    );
  }

  void _handleSearchQuery(String value) {
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
                key: const ValueKey('index-section-indicator'),
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
      child: BlocBuilder<HymnsBloc, HymnsState>(
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          if (previous is HymnsLoaded && current is HymnsLoaded) {
            return previous.hymns.length != current.hymns.length ||
                previous.sortType != current.sortType ||
                previous.version != current.version;
          }
          return true;
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final labels = _alphabetLabelsForState(state);
              final useHorizontalAlphabetRail = labels.isNotEmpty &&
                  IndexedFastScroller.shouldUseHorizontalLayout(
                    labelCount: labels.length,
                    availableHeight: constraints.maxHeight,
                    bottomPadding: _alphabetRailBottomPadding,
                  );

              return Stack(
                key: _listViewportKey,
                children: [
                  _buildHymnListView(
                    state,
                    useHorizontalAlphabetRail: useHorizontalAlphabetRail,
                    viewportHeight: constraints.maxHeight,
                  ),
                  if (labels.isNotEmpty)
                    AlphabetScrollBar(
                      availableLabels: labels,
                      activeLabel: labels.contains(_currentSectionLetter)
                          ? _currentSectionLetter
                          : labels.first,
                      onLetterSelected: _scrollToLetter,
                      bottomPadding: _alphabetRailBottomPadding,
                      useHorizontalLayout: useHorizontalAlphabetRail,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<String> _alphabetLabelsForState(HymnsState state) {
    if (state is! HymnsLoaded || state.sortType != 'name') return const [];

    final hymnsToDisplay = _hymnsForDisplay(state.hymns, state.sortType);
    final availableLabels = _buildAlphabetIndex(hymnsToDisplay).keys.toList();
    return AlphabetScrollBar.visibleLetters(availableLabels);
  }

  Widget _buildHymnListView(
    HymnsState state, {
    required bool useHorizontalAlphabetRail,
    required double viewportHeight,
  }) {
    if (state is HymnsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
        ),
      );
    }
    if (state is HymnsError) {
      return ErrorStateWidget(message: state.message);
    }
    if (state is! HymnsLoaded) return const SizedBox();
    if (state.hymns.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.music_note,
        title: AppLocalizations.of(context)?.noHymnsFound ?? 'No hymns found',
      );
    }

    return _buildHymnListItems(
      state,
      useHorizontalAlphabetRail: useHorizontalAlphabetRail,
      viewportHeight: viewportHeight,
    );
  }

  Widget _buildHymnListItems(
    HymnsLoaded state, {
    required bool useHorizontalAlphabetRail,
    required double viewportHeight,
  }) {
    final hasAlphabetScrollBar =
        state.sortType == 'name' && state.hymns.isNotEmpty;
    final hasNumberScrollbar = state.sortType == 'number';
    final hymnsToDisplay = _hymnsForDisplay(state.hymns, state.sortType);

    // Step 5: Add empty state handling
    if (hymnsToDisplay.isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ No hymns to display - showing empty state');
      }
      return EmptyStateWidget(
        icon: Icons.music_note,
        title: AppLocalizations.of(context)?.noHymnsFound ?? 'No hymns found',
        message: state.sortType == 'name' ? 'በስም ለማደራጀት መዝሙር አልተገኘም' : null,
      );
    }

    final rightPadding =
        hasAlphabetScrollBar && !useHorizontalAlphabetRail ? 54.0 : 16.0;
    final standardBottomPadding = NavBarConstants.getBottomPadding(context);
    // Let even the final alphabet section align with the viewport top.
    final sectionAlignmentBottomPadding = hasAlphabetScrollBar
        ? (viewportHeight - _lastMeasuredHymnItemExtent)
            .clamp(0.0, double.infinity)
            .toDouble()
        : 0.0;
    final bottomPadding = sectionAlignmentBottomPadding > standardBottomPadding
        ? sectionAlignmentBottomPadding
        : standardBottomPadding;

    final listView = ListView.builder(
      controller: _scrollController,
      shrinkWrap: false, // Explicitly set to false for proper rendering
      // Add right padding only when sorted by name to prevent overlap with alphabet scrollbar
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        rightPadding,
        bottomPadding,
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
            sortType: state.sortType,
          ),
        );
      },
    );

    if (!hasNumberScrollbar) return listView;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: false,
      interactive: true,
      thickness: 4,
      radius: const Radius.circular(999),
      child: listView,
    );
  }

  void _navigateToHymnDetail(BuildContext context, Hymn hymn) {
    final onOpenHymn = widget.onOpenHymn;
    if (onOpenHymn != null) {
      onOpenHymn(hymn);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HymnDetailPage(hymn: hymn)),
    );
  }

  Future<void> _showSortDialog(BuildContext context) async {
    final currentState = context.read<HymnsBloc>().state;
    if (currentState is! HymnsLoaded) return;

    final effectiveSortType = currentState.sortType == 'search'
        ? _sortTypeBeforeSearch
        : currentState.sortType;
    final selectedSortType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'አደራደር',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: _buildSortOptions(effectiveSortType),
      ),
    );

    if (!mounted ||
        !context.mounted ||
        selectedSortType == null ||
        selectedSortType == effectiveSortType) {
      return;
    }

    final latestState = context.read<HymnsBloc>().state;
    if (latestState is! HymnsLoaded) return;
    _applySort(latestState, selectedSortType);
  }

  Widget _buildSortOptions(String currentSortType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSortOption(
          'በቁጥር',
          'number',
          currentSortType,
        ),
        _buildSortOption(
          'በስም',
          'name',
          currentSortType,
        ),
      ],
    );
  }

  Widget _buildSortOption(
    String title,
    String value,
    String currentValue,
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
      onTap: () => Navigator.of(context).pop(value),
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
