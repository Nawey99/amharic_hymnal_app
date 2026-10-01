// lib/features/hymns/presentation/pages/favorites_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/widgets/app_background.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymns_error_text.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/core/widgets/main_page_title_bar.dart';
import 'package:amharic_hymnal_app/core/widgets/search_bar.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_open_callback.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class FavoritesPage extends StatefulWidget {
  final HymnOpenCallback? onOpenHymn;

  const FavoritesPage({super.key, this.onOpenHymn});

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
        return Container(
          decoration: appBackgroundDecoration(context),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchBar(),
                Expanded(
                  child: BlocBuilder<HymnsBloc, HymnsState>(
                    buildWhen: (previous, current) {
                      return previous != current;
                    },
                    builder: (context, state) {
                      final settingsRepository = sl<SettingsRepository>();
                      final version = state is HymnsLoaded
                          ? state.version
                          : settingsRepository.getSelectedVersion();
                      // Fresh from storage for instant updates: this book's
                      // favourites, whose song IDs begin with its code.
                      final prefix = '${HymnalVersions.apiCode(version)}-';
                      final favorites = settingsRepository
                          .getFavoriteSongIds()
                          .where((id) => id.startsWith(prefix))
                          .toList();

                      // Handle errors
                      if (state is HymnsError) {
                        return ErrorStateWidget(
                          message: hymnsErrorText(context, state),
                        );
                      }

                      // Only show loading on initial load (HymnsInitial or HymnsLoading)
                      // NOT when toggling favorites (which keeps HymnsLoaded state)
                      if (state is HymnsInitial ||
                          (state is HymnsLoading && favorites.isEmpty)) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                context.appColors.accent),
                          ),
                        );
                      }

                      // If we have favorites but state isn't loaded yet, show them optimistically
                      if (state is! HymnsLoaded && favorites.isNotEmpty) {
                        // Show favorites from SharedPreferences even if state isn't loaded
                        // This prevents flickering during favorite removal
                        return _buildFavoritesList(
                            context, favorites, [], version);
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
                          context, favorites, state.hymns, version);
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
    return MainPageTitleBar(
      title: AppLocalizations.of(context)?.favoritesTitle ?? 'ተወዳጆች',
      actions: [
        IconButton(
          // Also the TalkBack/VoiceOver label.
          tooltip: _isSearchVisible
              ? AppLocalizations.of(context)?.closeSearch ?? 'ፍለጋ ዝጋ'
              : AppLocalizations.of(context)?.search ?? 'ፈልግ',
          icon: Icon(
            _isSearchVisible ? Icons.close : Icons.search,
            color: context.appColors.primaryText,
          ),
          onPressed: () => _toggleSearch(),
        ),
      ],
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
      hintText: AppLocalizations.of(context)?.searchFavoritesHint ??
          'ተወዳጅ መዝሙሮችን ይፈልጉ...',
      autofocus: false,
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
    List<String> favorites,
    List<Hymn> allHymns,
    String version,
  ) {
    // Optimistic UI: Filter favorites based on SharedPreferences (source of truth)
    // This ensures instant removal without waiting for database or state updates
    var favoriteHymns = allHymns.where((hymn) {
      // Use SharedPreferences as the source of truth for instant updates
      return favorites.contains(hymn.songIdIn(version));
    }).toList();

    // Apply search filter if search is active
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      favoriteHymns = favoriteHymns.where((hymn) {
        final title = hymn.displayTitle.toLowerCase();
        final englishTitle = hymn.englishTitleOld?.toLowerCase() ?? '';
        final lyrics = hymn.displayLyrics.toLowerCase();
        final number = hymn.displayNumber.toString();
        final newNumber = hymn.newHymnalNumber?.toString() ?? '';
        final oldNumber = hymn.oldHymnalNumber?.toString() ?? '';
        return title.contains(query) ||
            englishTitle.contains(query) ||
            lyrics.contains(query) ||
            number == query ||
            newNumber == query ||
            oldNumber == query;
      }).toList();
    }

    if (favorites.isEmpty) {
      return _buildKeyboardAwareEmptyState(
        child: EmptyStateWidget(
          icon: Icons.favorite_border,
          title: AppLocalizations.of(context)?.noFavoritesYet ??
              'No favorites yet',
          message: AppLocalizations.of(context)?.addToFavoritesHint ??
              'Tap the heart icon on any hymn to add it to favorites',
        ),
      );
    }

    if (favoriteHymns.isEmpty) {
      return _buildKeyboardAwareEmptyState(
        child: EmptyStateWidget(
          icon: Icons.favorite_border,
          title: AppLocalizations.of(context)?.noFavoritesFound ??
              'No favorites found',
        ),
      );
    }

    // Add bottom padding to prevent content from going under navigation bar
    // The last item's own gap already counts towards it.
    final bottomPadding = NavBarConstants.getBottomPadding(context) -
        HymnListItem.bottomGap(context);

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
              final onOpenHymn = widget.onOpenHymn;
              if (onOpenHymn != null) {
                onOpenHymn(hymn);
                return;
              }
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

  Widget _buildKeyboardAwareEmptyState({required Widget child}) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final lift =
        isKeyboardVisible ? (keyboardHeight * 0.2).clamp(48.0, 84.0) : 0.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(end: lift),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -value),
          child: child,
        );
      },
      child: Align(
        alignment:
            isKeyboardVisible ? const Alignment(0, 0.18) : Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.52,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: NavBarConstants.getBottomPadding(context),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
