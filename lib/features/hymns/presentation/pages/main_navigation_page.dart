import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/categories_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/favorites_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/index_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/number_search_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/settings_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class MainNavigationPage extends StatefulWidget {
  final bool loadInitialData;
  final bool usePlaceholderPagesForTesting;

  const MainNavigationPage({
    super.key,
    this.loadInitialData = true,
    @visibleForTesting this.usePlaceholderPagesForTesting = false,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    if (widget.loadInitialData) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    try {
      final settingsRepository = sl<SettingsRepository>();
      final languageCode = settingsRepository.getSelectedLanguage();
      final version = settingsRepository.getSelectedVersion();
      final sortType = settingsRepository.getSortType();
      if (mounted) {
        context.read<HymnsBloc>().add(
              LoadHymns(languageCode, version, sortType),
            );
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HymnsBloc, HymnsState>(
      buildWhen: (previous, current) {
        if (previous is HymnsLoaded && current is HymnsLoaded) {
          return previous.version != current.version;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        final items = _navItemsForState(state);
        final selectedIndex = _selectedIndex.clamp(0, items.length - 1);
        if (selectedIndex != _selectedIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedIndex = selectedIndex);
          });
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: IndexedStack(
            index: selectedIndex,
            children: items.map((item) => item.page).toList(growable: false),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(items, selectedIndex),
        );
      },
    );
  }

  List<_NavItem> _navItemsForState(HymnsState state) {
    final version = state is HymnsLoaded
        ? state.version
        : sl<SettingsRepository>().getSelectedVersion();
    final showCategory = HymnalVersions.hasCategories(version);

    return [
      _NavItem(
        page: _pageFor(const IndexPage()),
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt_rounded,
        label: 'Index',
      ),
      _NavItem(
        page: _pageFor(const FavoritesPage()),
        icon: Icons.favorite_outline_rounded,
        selectedIcon: Icons.favorite_rounded,
        label: 'Favourite',
      ),
      _NavItem(
        page: _pageFor(const NumberSearchPage()),
        icon: Icons.numbers_rounded,
        selectedIcon: Icons.pin_rounded,
        label: 'Number',
      ),
      if (showCategory)
        _NavItem(
          page: _pageFor(const CategoriesPage()),
          icon: Icons.category_outlined,
          selectedIcon: Icons.category_rounded,
          label: 'Category',
        ),
      _NavItem(
        page: _pageFor(const SettingsPage()),
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: 'Setting',
      ),
    ];
  }

  Widget _pageFor(Widget page) {
    if (widget.usePlaceholderPagesForTesting) {
      return const SizedBox.shrink();
    }
    return page;
  }

  Widget _buildBottomNavigationBar(List<_NavItem> items, int selectedIndex) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final compactLabels =
        textScale > 1.25 || MediaQuery.sizeOf(context).width < 375;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.96),
        indicatorColor: AppColors.accentGreen.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.primaryText : AppColors.secondaryText,
            fontSize: compactLabels ? 10 : 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontFamily: 'NotoSansEthiopic',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accentGreen : AppColors.secondaryText,
            size: selected ? 24 : 21,
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
          selectedIndex: selectedIndex,
          height: compactLabels ? 66 : 70,
          labelBehavior: compactLabels
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: _onItemTapped,
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
}

class _NavItem {
  final Widget page;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.page,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
