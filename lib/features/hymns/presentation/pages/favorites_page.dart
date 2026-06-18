// lib/features/hymns/presentation/pages/favorites_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/core/widgets/search_bar.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSearchVisible = false;
  Timer? _searchDebounceTimer;
  String _searchQuery = ''; // Local search query for independence

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load hymns when page is opened
    final settingsRepository = sl<SettingsRepository>();
    final languageCode = settingsRepository.getSelectedLanguage();
    final version = settingsRepository.getSelectedVersion();
    final sortType = settingsRepository.getSortType();
    context.read<HymnsBloc>().add(LoadHymns(languageCode, version, sortType));

    _searchController.addListener(_handleSearchChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_handleSearchChange);
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

  bool _wasVisible = false; // Track previous visibility state

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Track page visibility for auto-close search functionality
    final isVisible = ModalRoute.of(context)?.isCurrent ?? false;

    // Auto-close search when leaving page AND search is empty
    if (_wasVisible &&
        !isVisible &&
        _isSearchVisible &&
        _searchController.text.isEmpty) {
      setState(() {
        _isSearchVisible = false;
        _searchFocusNode.unfocus();
      });
    }

    // When page becomes visible, reload full list if no local search
    // This ensures search independence between pages
    if (isVisible && _searchQuery.isEmpty) {
      // Clear any search state from other pages by reloading full list
      final currentState = context.read<HymnsBloc>().state;
      if (currentState is HymnsLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _searchQuery.isEmpty) {
            context.read<HymnsBloc>().add(
                  LoadHymns(currentState.languageCode, currentState.version,
                      currentState.sortType),
                );
          }
        });
      }
    }

    _wasVisible = isVisible; // Update visibility state
  }

  void _handleSearchChange() {
    _searchDebounceTimer?.cancel();

    final value = _searchController.text;
    setState(() {
      _searchQuery = value;
    });

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

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchFocusNode.unfocus();
        _reloadHymns();
      } else {
        Future.delayed(
          const Duration(milliseconds: 100),
          () {
            if (mounted) {
              _searchFocusNode.requestFocus();
            }
          },
        );
      }
    });
  }

  void _reloadHymns() {
    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded) {
      context.read<HymnsBloc>().add(
            LoadHymns(state.languageCode, state.version, state.sortType),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) {
        final bgService = BackgroundImageService();
        return Container(
          decoration: BoxDecoration(
            image: bgService.isEnabled
                ? DecorationImage(
                    image: const AssetImage('assets/images/background.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.8),
                      BlendMode.darken,
                    ),
                  )
                : null,
            color: bgService.isEnabled ? null : AppColors.primaryBackground,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchBar(),
                Expanded(
                  child: BlocBuilder<HymnsBloc, HymnsState>(
                    buildWhen: (previous, current) {
                      // Only rebuild when:
                      // 1. State type changes (e.g., Loading -> Loaded)
                      // 2. Hymns list changes (favorites added/removed)
                      // 3. Error occurs
                      if (previous.runtimeType != current.runtimeType) {
                        return true;
                      }
                      if (previous is HymnsLoaded && current is HymnsLoaded) {
                        // Rebuild if hymns list changed (favorite toggle)
                        return previous.hymns.length != current.hymns.length ||
                            previous.hymns.any((h) => !current.hymns.any((ch) =>
                                ch.id == h.id &&
                                ch.isFavorite == h.isFavorite));
                      }
                      return true;
                    },
                    builder: (context, state) {
                      final settingsRepository = sl<SettingsRepository>();
                      // Get fresh favorites list to ensure instant updates
                      final favorites = settingsRepository.getFavoriteHymns();

                      // Handle errors
                      if (state is HymnsError) {
                        return ErrorStateWidget(
                          message: state.message,
                        );
                      }

                      // Only show loading on initial load (HymnsInitial or HymnsLoading)
                      // NOT when toggling favorites (which keeps HymnsLoaded state)
                      if (state is HymnsInitial ||
                          (state is HymnsLoading && favorites.isEmpty)) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accentGreen),
                          ),
                        );
                      }

                      // If we have favorites but state isn't loaded yet, show them optimistically
                      if (state is! HymnsLoaded && favorites.isNotEmpty) {
                        // Show favorites from SharedPreferences even if state isn't loaded
                        // This prevents flickering during favorite removal
                        return _buildFavoritesList(context, favorites, []);
                      }

                      // State is loaded - show favorites
                      if (state is! HymnsLoaded) {
                        return EmptyStateWidget(
                          icon: Icons.favorite_border,
                          title: AppLocalizations.of(context)?.noFavoritesYet ??
                              'No favorites yet',
                          message: AppLocalizations.of(context)
                                  ?.addToFavoritesHint ??
                              'Tap the heart icon on any hymn to add it to favorites',
                        );
                      }

                      return _buildFavoritesList(
                          context, favorites, state.hymns);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Favorites',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansEthiopic',
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: AppColors.primaryText,
            ),
            onPressed: () => _toggleSearch(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _isSearchVisible ? _buildSearchField() : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchField() {
    return AppSearchBar(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Search favorites...',
      autofocus: true,
      onChanged: (value) {
        _handleSearchChange();
      },
      onClear: () {
        _reloadHymns();
      },
    );
  }

  /// Build favorites list with optimistic UI updates
  /// Uses SharedPreferences as source of truth for instant updates
  Widget _buildFavoritesList(
    BuildContext context,
    List<int> favorites,
    List<Hymn> allHymns,
  ) {
    // Optimistic UI: Filter favorites based on SharedPreferences (source of truth)
    // This ensures instant removal without waiting for database or state updates
    var favoriteHymns = allHymns.where((hymn) {
      // Use SharedPreferences as the source of truth for instant updates
      return favorites.contains(hymn.displayNumber);
    }).toList();

    // Apply search filter if search is active
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      favoriteHymns = favoriteHymns.where((hymn) {
        final title = hymn.displayTitle.toLowerCase();
        final lyrics = hymn.displayLyrics.toLowerCase();
        return title.contains(query) || lyrics.contains(query);
      }).toList();
    }

    if (favorites.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.favorite_border,
        title:
            AppLocalizations.of(context)?.noFavoritesYet ?? 'No favorites yet',
        message: AppLocalizations.of(context)?.addToFavoritesHint ??
            'Tap the heart icon on any hymn to add it to favorites',
      );
    }

    if (favoriteHymns.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.favorite_border,
        title: AppLocalizations.of(context)?.noFavoritesFound ??
            'No favorites found',
      );
    }

    // Add bottom padding to prevent content from going under navigation bar
    final bottomPadding = NavBarConstants.getBottomPadding(context);

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: favoriteHymns.length,
      itemBuilder: (context, index) {
        final hymn = favoriteHymns[index];
        // Wrap in RepaintBoundary for performance optimization
        return RepaintBoundary(
          child: HymnListItem(
            key: ValueKey('favorite_${hymn.id}_${hymn.displayNumber}'),
            hymn: hymn,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HymnDetailPage(hymn: hymn),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
