import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/categories_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/favorites_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/index_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/number_search_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/settings_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          NumberSearchPage(),
          IndexPage(),
          CategoriesPage(),
          FavoritesPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.primaryBackground.withValues(alpha: 0.96),
        indicatorColor: AppColors.accentGreen.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.accentGreen : AppColors.secondaryText,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'NotoSansEthiopic',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accentGreen : AppColors.secondaryText,
            size: 22,
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
          selectedIndex: _selectedIndex,
          height: 72,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: 'Number',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Index',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
