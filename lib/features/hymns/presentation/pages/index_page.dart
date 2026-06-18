// lib/features/hymns/presentation/pages/index_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/amharic_transliteration_service.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/amharic_utils.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/alphabet_scroll_bar.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;
  Timer? _searchDebounceTimer;
  String _currentSectionLetter =
      ''; // Track current section letter for dynamic updates
  // Local search query tracking for page independence
  // Used to determine if page should reload full list when becoming visible
  String _localSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Add scroll listener to update section indicator dynamically
    _scrollController.addListener(_updateSectionIndicator);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounceTimer?.cancel();
    _scrollController.removeListener(_updateSectionIndicator);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Close search if empty when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isSearchVisible && _searchController.text.isEmpty) {
        setState(() {
          _isSearchVisible = false;
          _searchFocusNode.unfocus();
        });
      }
    }
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
        // Only reload if current state is from a search (indicated by sortType 'name' without local query)
        // This prevents unnecessary reloads
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _localSearchQuery.isEmpty) {
            context.read<HymnsBloc>().add(
                  LoadHymns(currentState.languageCode, currentState.version,
                      currentState.sortType),
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

    // Get item height based on sort type (96px when sorted by name, variable otherwise)
    final useItemExtent = state.sortType == 'name';
    final itemHeight = useItemExtent ? 96.0 : 68.0;
    final listPadding = 8.0;
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Calculate visible range: from top of viewport to bottom
    final topVisiblePosition = scrollOffset;
    final bottomVisiblePosition = scrollOffset + viewportHeight;

    // Find all visible hymn indices
    final visibleIndices = <int>[];
    for (int i = 0; i < state.hymns.length; i++) {
      final itemTop = listPadding + (i * itemHeight);
      final itemBottom = itemTop + itemHeight;

      // Item is visible if any part of it is within the viewport
      if (itemBottom >= topVisiblePosition &&
          itemTop <= bottomVisiblePosition) {
        visibleIndices.add(i);
      }
    }

    if (visibleIndices.isEmpty) return;

    // Group visible hymns by their primary letter family
    final visibleHymnsByLetter = <String, List<int>>{};
    for (final index in visibleIndices) {
      if (index >= 0 && index < state.hymns.length) {
        final hymn = state.hymns[index];
        final title = hymn.displayTitle.isNotEmpty
            ? hymn.displayTitle
            : 'መዝሙር ${hymn.displayNumber}';
        final letter = _getFirstLetter(title);
        visibleHymnsByLetter.putIfAbsent(letter, () => []).add(index);
      }
    }

    if (visibleHymnsByLetter.isEmpty) return;

    // CORRECT BEHAVIOR: Update header only when ALL items of current family scroll out of view
    // NOT when the next family enters the screen

    // Check if current section letter family still has any visible items
    final currentFamilyStillVisible = _currentSectionLetter.isNotEmpty &&
        visibleHymnsByLetter.containsKey(_currentSectionLetter);

    // If current family still has visible items, keep the current letter
    if (currentFamilyStillVisible) {
      return; // Don't update - current family is still visible
    }

    // Current family has completely scrolled out - update to the letter of the topmost visible item
    final topmostIndex = visibleIndices.first;
    final topmostHymn = state.hymns[topmostIndex];
    final topmostTitle = topmostHymn.displayTitle.isNotEmpty
        ? topmostHymn.displayTitle
        : 'መዝሙር ${topmostHymn.displayNumber}';
    final topmostLetter = _getFirstLetter(topmostTitle);

    // Update to the new letter family only if it's different
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
      // Get title for indexing - use displayTitle or fallback to number
      final title = hymns[i].displayTitle.isNotEmpty
          ? hymns[i].displayTitle
          : 'መዝሙር ${hymns[i].displayNumber}';
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

    final index = _buildAlphabetIndex(state.hymns);
    final position = index[letter];
    if (position != null && _scrollController.hasClients) {
      // Calculate approximate scroll position
      // HymnListItem: 40px container + 20px padding (10px top + 10px bottom) + 8px margin = ~68px
      // ListView padding: 8px vertical
      const itemHeight = 68.0;
      const listPadding = 8.0;
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
      }
    }
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
                child: Text(
                  'Adventist Hymnal',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansEthiopic',
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
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _localSearchQuery = '';
        _searchFocusNode.unfocus();
        _reloadHymns(context);
      } else {
        Future.delayed(
          const Duration(milliseconds: 100),
          () => _searchFocusNode.requestFocus(),
        );
      }
    });
  }

  void _reloadHymns(BuildContext context) {
    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded) {
      context.read<HymnsBloc>().add(
            LoadHymns(state.languageCode, state.version, state.sortType),
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
    final settingsRepository = sl<SettingsRepository>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: GlassContainer(
          borderRadius: 20.0,
          blurSigma: 18.0,
          opacity: 0.25,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            inputFormatters: [AmharicTransliterationFormatter()],
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: settingsRepository.getFontSize(),
              fontFamily: 'NotoSansEthiopic',
            ),
            decoration: InputDecoration(
              hintText: 'Search hymns...',
              hintStyle: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 14,
                fontFamily: 'NotoSansEthiopic',
              ),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.primaryText),
              suffixIcon: _buildClearButton(context),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            onChanged: (value) => _handleSearchChange(context, value),
          ),
        ),
      ),
    );
  }

  Widget? _buildClearButton(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (_, value, __) {
        return value.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.primaryText),
                onPressed: () {
                  _searchController.clear();
                  _reloadHymns(context);
                },
              )
            : const SizedBox.shrink();
      },
    );
  }

  void _handleSearchChange(BuildContext context, String value) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Store local search query
    setState(() {
      _localSearchQuery = value;
    });

    // If empty, reload immediately
    if (value.isEmpty) {
      _reloadHymns(context);
      return;
    }

    // Debounce search - wait 300ms before executing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      final state = context.read<HymnsBloc>().state;
      if (state is HymnsLoaded && mounted) {
        context.read<HymnsBloc>().add(
              SearchHymnsEvent(state.languageCode, state.version, value),
            );
      }
    });
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
        children: [
          _buildHymnListView(),
          _buildAlphabetScrollBar(),
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
    // Use itemExtent for more accurate scroll position calculation when sorted by name
    final state = context.read<HymnsBloc>().state;
    final useItemExtent = state is HymnsLoaded && state.sortType == 'name';

    // Step 2: Fix Filtering Logic - Ensure filtering doesn't exclude all hymns when sorted by name
    // When sorted by name, only filter out hymns with no number (titles might be empty but that's OK)
    // When sorted by number or category, use the standard filter
    final validHymns = hymns.where((hymn) {
      final hasNumber = hymn.displayNumber > 0;

      // If sorted by name, only require a number (titles will be shown even if empty, with fallback)
      if (state is HymnsLoaded && state.sortType == 'name') {
        // Keep hymns that have a valid number OR a valid title
        // This filters out "ghost" hymns that have neither
        final hasValidTitle = hymn.displayTitle.trim().isNotEmpty;
        if (!hasNumber && !hasValidTitle) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ Filtering out empty hymn when sorted by name: id=${hymn.id}');
          }
          return false;
        }
        return true;
      }

      // For other sort types, use the standard filter
      final hasTitle = hymn.displayTitle.isNotEmpty;
      final hasLyrics = hymn.displayLyrics.isNotEmpty;

      // Keep hymn if it has at least a number or some content
      if (!hasNumber && !hasTitle && !hasLyrics) {
        if (kDebugMode) {
          debugPrint('⚠️ Filtering out empty hymn: id=${hymn.id}');
        }
        return false;
      }
      return true;
    }).toList();

    if (kDebugMode && validHymns.length != hymns.length) {
      debugPrint(
          '📊 Filtered ${hymns.length - validHymns.length} empty hymns from list');
    }

    // Step 5: Add Safety Checks and Fallbacks
    // If validHymns is empty but hymns is not, show all hymns as fallback
    final hymnsToDisplay =
        validHymns.isEmpty && hymns.isNotEmpty ? hymns : validHymns;

    // Step 5: Add empty state handling
    if (hymnsToDisplay.isEmpty) {
      if (kDebugMode) {
        debugPrint('❌ No hymns to display - showing empty state');
      }
      return EmptyStateWidget(
        icon: Icons.music_note,
        title: AppLocalizations.of(context)?.noHymnsFound ?? 'No hymns found',
        message: state is HymnsLoaded && state.sortType == 'name'
            ? 'No hymns available for sorting by name'
            : null,
      );
    }

    // Step 3: Fix ListView Rendering - Ensure proper constraints and visibility
    // Conditionally apply right padding only when sorted by name (for alphabet scrollbar)
    final rightPadding =
        useItemExtent ? 48.0 : 16.0; // 48px only when sorted by name

    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: false, // Explicitly set to false for proper rendering
      // Add right padding only when sorted by name to prevent overlap with alphabet scrollbar
      padding: EdgeInsets.fromLTRB(16, 8, rightPadding, 8),
      itemCount: hymnsToDisplay.length,
      // Performance: Cache items for smoother scrolling
      cacheExtent: 250.0,
      // Use fixed item extent for accurate scrolling when sorted by name
      // Fixed extent must include the two-line list item plus card margin.
      itemExtent: useItemExtent ? 104.0 : null,
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
          child: HymnListItem(
            key: ValueKey('hymn_${hymn.id}_${hymn.displayNumber}'),
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
          final letters = _buildAlphabetIndex(state.hymns).keys.toList()
            ..sort();
          return AlphabetScrollBar(
            letters: letters,
            onLetterSelected: _scrollToLetter,
          );
        }
        return const SizedBox();
      },
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
          'Sort By',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: _buildSortOptions(currentState),
      ),
    );
  }

  Widget _buildSortOptions(HymnsLoaded state) {
    final isHagerigna = state.version == 'hagerigna';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSortOption(
          'Name',
          'name',
          state.sortType,
          () => _applySort(state, 'name'),
        ),
        if (!isHagerigna)
          _buildSortOption(
            'Number',
            'number',
            state.sortType,
            () => _applySort(state, 'number'),
          ),
        if (state.version == 'hymnal')
          _buildSortOption(
            'Category',
            'category',
            state.sortType,
            () => _applySort(state, 'category'),
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
    context.read<HymnsBloc>().add(
          ChangeSort(state.languageCode, state.version, sortType),
        );
    Navigator.pop(context);
  }

  ImageProvider _getBackgroundImage() {
    return const AssetImage('assets/images/background.jpg');
  }
}
