// lib/features/hymns/presentation/pages/number_search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/search_state_controller.dart';
import 'package:amharic_hymnal_app/core/widgets/search_text_field.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/history_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class NumberSearchPage extends StatefulWidget {
  const NumberSearchPage({super.key});

  @override
  State<NumberSearchPage> createState() => _NumberSearchPageState();
}

class _NumberSearchPageState extends State<NumberSearchPage>
    with WidgetsBindingObserver {
  final TextEditingController _numberController = TextEditingController();
  final SearchStateController _searchController = SearchStateController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;
  StreamSubscription<String>? _searchSubscription;
  // Local search query tracking for page independence
  // Used to determine if page should reload full list when becoming visible
  String _localSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen to SearchStateController stream and dispatch to BLoC
    _searchSubscription = _searchController.queryStream.listen((query) {
      if (!mounted) return;
      _handleSearchQuery(query);
    });
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
        _searchController.currentQuery.isEmpty) {
      setState(() {
        _isSearchVisible = false;
        _searchFocusNode.unfocus();
      });
    }

    // When page becomes visible, reload full list if no local search
    // This ensures search independence between pages
    // Number page always uses 'number' sortType to maintain its own context
    if (isVisible && _localSearchQuery.isEmpty) {
      // Clear any search state from other pages by reloading full list with Number page's sortType
      final currentState = context.read<HymnsBloc>().state;
      if (currentState is HymnsLoaded) {
        // Always reload with 'number' sortType for Number page (its default)
        // This ensures Index page searches don't affect Number page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _localSearchQuery.isEmpty) {
            context.read<HymnsBloc>().add(
                  LoadHymns(currentState.languageCode, currentState.version,
                      'number'), // Number page always uses 'number' sortType
                );
          }
        });
      }
    }

    _wasVisible = isVisible; // Update visibility state
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Close search if empty when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isSearchVisible && _searchController.currentQuery.isEmpty) {
        setState(() {
          _isSearchVisible = false;
          _searchFocusNode.unfocus();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchSubscription?.cancel();
    _numberController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _numberFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchQuery(String query) {
    // Store local search query
    setState(() {
      _localSearchQuery = query;
    });

    // If empty, reload immediately with Number page's sortType
    if (query.isEmpty) {
      final state = context.read<HymnsBloc>().state;
      if (state is HymnsLoaded) {
        context.read<HymnsBloc>().add(
              LoadHymns(state.languageCode, state.version,
                  'number'), // Number page always uses 'number'
            );
      }
      return;
    }

    // Dispatch search event to BLoC (debounce handled by SearchStateController)
    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded && mounted) {
      context.read<HymnsBloc>().add(
            SearchHymnsEvent(state.languageCode, state.version, query),
          );
    }
  }

  void _openHymn() {
    final numberText = _numberController.text.trim();
    if (numberText.isEmpty) return;

    final number = int.tryParse(numberText);
    if (number == null || number <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.pleaseEnterValidNumber ??
              'Please enter a valid hymn number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to hymn detail page with number
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HymnDetailPage(hymnNumber: number),
      ),
    );
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
            _buildSearchBar(),
            _buildMainContent(context),
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
                Colors.black.withValues(alpha: 0.7),
                BlendMode.darken,
              ),
            )
          : null,
      color: bgService.isEnabled ? null : AppColors.primaryBackground,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // History icon button at top left
          IconButton(
            icon: const Icon(
              Icons.history,
              color: AppColors.primaryText,
            ),
            onPressed: () => _openHistory(context),
            tooltip: 'History',
          ),
          const Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Adventist Hymnal',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansEthiopic',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: AppColors.primaryText,
            ),
            onPressed: () => _toggleSearch(),
          ),
        ],
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryPage(),
      ),
    );
  }

  void _toggleSearch() {
    final willShowSearch = !_isSearchVisible;
    setState(() {
      _isSearchVisible = willShowSearch;
      if (!_isSearchVisible) {
        _searchFocusNode.unfocus();
      }
    });
    if (willShowSearch && _searchController.currentQuery.isNotEmpty) {
      _handleSearchQuery(_searchController.currentQuery);
    }
  }

  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isSearchVisible ? _buildSearchField() : const SizedBox.shrink(),
    );
  }

  Widget _buildSearchField() {
    return SearchTextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Search hymns by name...',
      autofocus: true,
      onClear: () {
        final state = context.read<HymnsBloc>().state;
        if (state is HymnsLoaded) {
          context.read<HymnsBloc>().add(
                LoadHymns(state.languageCode, state.version, 'number'),
              );
        }
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Expanded(
      child: _isSearchVisible && _searchController.currentQuery.isNotEmpty
          ? _buildSearchResults(context)
          : _buildNumberInput(context),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return BlocBuilder<HymnsBloc, HymnsState>(
      builder: (context, state) {
        if (state is HymnsLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          );
        }
        if (state is HymnsError) {
          return _buildErrorMessage(state.message);
        }
        if (state is HymnsLoaded) {
          if (state.hymns.isEmpty) {
            return _buildEmptyMessage('No hymns found');
          }
          return _buildSearchResultsList(state.hymns);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorMessage(String message) {
    final settingsRepository = sl<SettingsRepository>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassContainer(
          borderRadius: 16.0,
          blurSigma: 12.0,
          opacity: 0.15,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.accentGreen,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: settingsRepository.getFontSize(),
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

  Widget _buildEmptyMessage(String message) {
    final settingsRepository = sl<SettingsRepository>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassContainer(
          borderRadius: 16.0,
          blurSigma: 12.0,
          opacity: 0.15,
          padding: const EdgeInsets.all(24.0),
          child: Text(
            message,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: settingsRepository.getFontSize(),
              fontFamily: 'NotoSansEthiopic',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(List<dynamic> hymns) {
    // Add bottom padding to prevent content from going under navigation bar
    final bottomPadding = NavBarConstants.getBottomPadding(context);

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: hymns.length,
      itemBuilder: (context, index) {
        final hymn = hymns[index];
        return HymnListItem(
          key: ValueKey('search_${hymn.id}_${hymn.displayNumber}'),
          hymn: hymn,
          onTap: () => _navigateToHymnDetail(context, hymn),
        );
      },
    );
  }

  void _navigateToHymnDetail(BuildContext context, dynamic hymn) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HymnDetailPage(hymn: hymn)),
    );
  }

  Widget _buildNumberInput(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberInputField(),
            const SizedBox(height: 24),
            _buildOpenButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInputField() {
    final settingsRepository = sl<SettingsRepository>();
    return GlassContainer(
      borderRadius: 16.0,
      blurSigma: 12.0,
      opacity: 0.15,
      child: TextField(
        controller: _numberController,
        focusNode: _numberFocusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: settingsRepository.getFontSize() * 1.2,
          fontFamily: 'NotoSansEthiopic',
        ),
        decoration: InputDecoration(
          hintText: '....',
          hintStyle: TextStyle(
            color: AppColors.tertiaryText,
            fontSize: settingsRepository.getFontSize() * 1.2,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '#',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: settingsRepository.getFontSize() * 1.2,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onSubmitted: (_) => _openHymn(),
      ),
    );
  }

  Widget _buildOpenButton() {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        onPressed: _openHymn,
        padding: const EdgeInsets.symmetric(vertical: 18),
        borderRadius: 16.0,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined,
                size: 24, color: AppColors.primaryText),
            SizedBox(width: 12),
            Text(
              'OPEN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansEthiopic',
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getBackgroundImage() {
    // Use a placeholder or actual background image
    // For now, return a placeholder
    return const AssetImage('assets/images/background.jpg');
  }
}
