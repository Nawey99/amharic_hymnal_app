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
import 'package:amharic_hymnal_app/core/widgets/main_page_title_bar.dart';
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

class _NumberSearchPageState extends State<NumberSearchPage> {
  final TextEditingController _numberController = TextEditingController();
  final SearchStateController _searchController = SearchStateController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _numberFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;
  String? _numberErrorMessage;
  StreamSubscription<String>? _searchSubscription;
  @override
  void initState() {
    super.initState();
    // Listen to SearchStateController stream and dispatch to BLoC
    _searchSubscription = _searchController.queryStream.listen((query) {
      if (!mounted) return;
      _handleSearchQuery(query);
    });
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    _numberController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _numberFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchQuery(String query) {
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
    if (numberText.isEmpty) {
      _showInvalidNumberMessage('እባክዎ የመዝሙር ቁጥር ያስገቡ።');
      return;
    }

    final number = int.tryParse(numberText);
    if (number == null || number <= 0) {
      _showInvalidNumberMessage(
        AppLocalizations.of(context)?.pleaseEnterValidNumber ??
            'እባክዎ ትክክለኛ ቁጥር ያስገቡ።',
      );
      return;
    }

    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded && state.hymns.isNotEmpty) {
      final numbers = state.hymns
          .map((hymn) => hymn.displayNumber)
          .where((value) => value > 0)
          .toList()
        ..sort();
      final min = numbers.first;
      final max = numbers.last;
      final exists = numbers.contains(number);
      if (number < min || number > max || !exists) {
        _showInvalidNumberMessage(
          'ይህ ቁጥር በአሁኑ መዝሙር ስብስብ ውስጥ የለም። እባክዎ ከ$min እስከ $max ያለ ቁጥር ያስገቡ።',
        );
        return;
      }
    }

    // Navigate to hymn detail page with number
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HymnDetailPage(hymnNumber: number),
      ),
    );
  }

  void _showInvalidNumberMessage(String message) {
    setState(() => _numberErrorMessage = message);
  }

  void _clearNumberError() {
    if (_numberErrorMessage == null) return;
    setState(() => _numberErrorMessage = null);
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
    return MainPageTitleBar(
      title: 'ውዳሴ',
      leading: _buildHistoryButton(context),
      actions: [
        IconButton(
          icon: Icon(
            _isSearchVisible ? Icons.close : Icons.search,
            color: AppColors.primaryText,
          ),
          onPressed: () => _toggleSearch(),
        ),
      ],
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return Tooltip(
      message: 'ታሪክ',
      child: InkWell(
        onTap: () => _openHistory(context),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                color: AppColors.accentGreen,
                size: 19,
              ),
              SizedBox(width: 5),
              Text(
                'ታሪክ',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'NotoSansEthiopic',
                ),
              ),
            ],
          ),
        ),
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
    if (willShowSearch) {
      _numberFocusNode.unfocus();
    }
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
      hintText: 'በርዕስ መዝሙር ይፈልጉ...',
      autofocus: false,
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
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumberInputField(),
            _buildNumberErrorMessage(),
            const SizedBox(height: 16),
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
      border: Border.all(
        color: _numberErrorMessage == null
            ? AppColors.accentGreen.withValues(alpha: 0.45)
            : Colors.red,
        width: 1.5,
      ),
      child: TextField(
        controller: _numberController,
        focusNode: _numberFocusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => _clearNumberError(),
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: settingsRepository.getFontSize() * 1.08,
          fontFamily: 'NotoSansEthiopic',
        ),
        decoration: InputDecoration(
          hintText: '....',
          hintStyle: TextStyle(
            color: AppColors.tertiaryText,
            fontSize: settingsRepository.getFontSize() * 1.08,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Text(
              '#',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: settingsRepository.getFontSize() * 1.08,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        onSubmitted: (_) => _openHymn(),
      ),
    );
  }

  Widget _buildNumberErrorMessage() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: _numberErrorMessage == null
          ? const SizedBox(height: 16)
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _numberErrorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSansEthiopic',
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  Widget _buildOpenButton() {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        onPressed: _openHymn,
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: 16.0,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined,
                size: 24, color: AppColors.primaryText),
            SizedBox(width: 12),
            Text(
              'ክፈት',
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
