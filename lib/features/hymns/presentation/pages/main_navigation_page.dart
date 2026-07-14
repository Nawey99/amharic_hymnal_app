import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';
import 'package:amharic_hymnal_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_open_callback.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/categories_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/favorites_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/index_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/number_search_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/settings_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

typedef HymnDetailBuilder = Widget Function(
  Hymn hymn,
  String sourceDestination,
  ValueChanged<String> onDestinationSelected,
  ValueChanged<Hymn> onHymnChanged,
);

class MainNavigationPage extends StatefulWidget {
  final bool loadInitialData;
  final bool usePlaceholderPagesForTesting;
  final String initialDestination;
  final Hymn? initialActiveHymn;
  final String? initialActiveDestination;
  final HymnDetailBuilder? hymnDetailBuilder;

  const MainNavigationPage({
    super.key,
    this.loadInitialData = true,
    @visibleForTesting this.usePlaceholderPagesForTesting = false,
    this.initialDestination = 'number',
    @visibleForTesting this.initialActiveHymn,
    @visibleForTesting this.initialActiveDestination,
    @visibleForTesting this.hymnDetailBuilder,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  _NavDestination _selectedDestination = _NavDestination.number;
  final HymnTabSession _hymnSession = HymnTabSession();
  final Map<_NavDestination, GlobalKey<NavigatorState>> _tabNavigatorKeys = {
    for (final destination in _NavDestination.values)
      destination: GlobalKey<NavigatorState>(),
  };
  bool _isHymnDetailOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedDestination = _NavDestination.fromId(widget.initialDestination);
    final initialActiveHymn = widget.initialActiveHymn;
    if (initialActiveHymn != null) {
      final source = _NavDestination.fromId(
        widget.initialActiveDestination ?? widget.initialDestination,
      );
      _hymnSession.open(
        hymn: initialActiveHymn,
        sourceDestination: source.id,
        version: sl<SettingsRepository>().getSelectedVersion(),
      );
    }
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
    final state = context.read<HymnsBloc>().state;
    final items = _navItemsForState(state);
    if (index < 0 || index >= items.length) return;
    final destination = items[index].destination;
    final activeHymn = _hymnSession.hymn;
    final ownsActiveHymn = activeHymn != null &&
        _hymnSession.owns(destination.id) &&
        destination != _NavDestination.settings;
    final activeHymnIsCurrent = ownsActiveHymn &&
        _hymnSession.isCurrentFor(destination.id, _currentVersion());

    if (destination == _selectedDestination && !ownsActiveHymn) {
      final navigator = _tabNavigatorKeys[destination]?.currentState;
      if (navigator?.canPop() ?? false) {
        navigator!.popUntil((route) => route.isFirst);
      }
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    if (destination != _selectedDestination || !activeHymnIsCurrent) {
      setState(() {
        _selectedDestination = destination;
        if (ownsActiveHymn && !activeHymnIsCurrent) {
          _clearActiveHymnState();
        }
      });
      _loadDataForDestination(destination);
    }

    if (activeHymnIsCurrent) {
      _pushHymnDetail(activeHymn, destination);
    }
  }

  String _currentVersion() {
    final state = context.read<HymnsBloc>().state;
    if (state is HymnsLoaded) return state.version;
    return sl<SettingsRepository>().getSelectedVersion();
  }

  void _openHymnFrom(_NavDestination source, Hymn hymn) {
    if (_isHymnDetailOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final version = _currentVersion();
    setState(() {
      _selectedDestination = source;
      _hymnSession.open(
        hymn: hymn,
        sourceDestination: source.id,
        version: version,
      );
    });
    _pushHymnDetail(hymn, source);
  }

  Future<void> _pushHymnDetail(
    Hymn hymn,
    _NavDestination source,
  ) async {
    if (!mounted || _isHymnDetailOpen) return;

    setState(() => _isHymnDetailOpen = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              widget.hymnDetailBuilder?.call(
                hymn,
                source.id,
                _handleDetailDestinationSelected,
                _handleActiveHymnChanged,
              ) ??
              HymnDetailPage(
                hymn: hymn,
                sourceDestination: source.id,
                onDestinationSelected: _handleDetailDestinationSelected,
                onHymnChanged: _handleActiveHymnChanged,
              ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isHymnDetailOpen = false);
      }
    }
  }

  void _handleDetailDestinationSelected(String destinationId) {
    if (!mounted) return;

    final destination = _NavDestination.fromId(destinationId);
    final closesOwningTab = _hymnSession.owns(destination.id);
    final shellRoute = ModalRoute.of(context);

    setState(() {
      _selectedDestination = destination;
      if (closesOwningTab) {
        _clearActiveHymnState();
      }
    });
    _loadDataForDestination(destination);

    final navigator = Navigator.of(context);
    if (shellRoute == null) {
      if (navigator.canPop()) navigator.pop();
      return;
    }
    navigator.popUntil((route) => identical(route, shellRoute));
  }

  void _handleActiveHymnChanged(Hymn hymn) {
    if (!mounted || _hymnSession.hymn?.id == hymn.id) return;
    setState(() => _hymnSession.updateHymn(hymn));
  }

  void _clearActiveHymnState() {
    _hymnSession.clear();
  }

  void _loadDataForDestination(_NavDestination destination) {
    if (widget.usePlaceholderPagesForTesting ||
        destination == _NavDestination.category ||
        destination == _NavDestination.settings) {
      return;
    }

    final settingsRepository = sl<SettingsRepository>();
    final state = context.read<HymnsBloc>().state;
    final languageCode = state is HymnsLoaded
        ? state.languageCode
        : settingsRepository.getSelectedLanguage();
    final version = state is HymnsLoaded
        ? state.version
        : settingsRepository.getSelectedVersion();
    final sortType = destination == _NavDestination.number
        ? 'number'
        : settingsRepository.getSortType();

    context.read<HymnsBloc>().add(
          LoadHymns(languageCode, version, sortType),
        );
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
        final selectedIndex = items.indexWhere(
          (item) => item.destination == _selectedDestination,
        );
        final effectiveSelectedIndex = selectedIndex < 0
            ? items.indexWhere(
                (item) => item.destination == _NavDestination.number,
              )
            : selectedIndex;
        if (selectedIndex < 0 && items.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedDestination = items[
                        effectiveSelectedIndex < 0 ? 0 : effectiveSelectedIndex]
                    .destination;
              });
            }
          });
        }

        final activePage = IndexedStack(
          index: effectiveSelectedIndex < 0 ? 0 : effectiveSelectedIndex,
          children: items.map((item) {
            final isActive = item.destination == _selectedDestination;
            return TickerMode(
              enabled: isActive,
              child: FocusScope(
                canRequestFocus: isActive,
                child: _buildTabNavigator(item, isActive),
              ),
            );
          }).toList(growable: false),
        );
        final useSideNavigation = ResponsiveLayout.useSideNavigation(context);

        return Scaffold(
          extendBody: !useSideNavigation,
          resizeToAvoidBottomInset: false,
          body: useSideNavigation
              ? Row(
                  children: [
                    _buildLandscapeNavigationRail(
                      items,
                      effectiveSelectedIndex < 0 ? 0 : effectiveSelectedIndex,
                    ),
                    Expanded(child: activePage),
                  ],
                )
              : activePage,
          bottomNavigationBar: useSideNavigation
              ? null
              : _buildBottomNavigationBar(
                  items,
                  effectiveSelectedIndex < 0 ? 0 : effectiveSelectedIndex,
                ),
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
      if (showCategory)
        _NavItem(
          destination: _NavDestination.category,
          page: _pageFor(
            CategoriesPage(
              onOpenHymn: (hymn) =>
                  _openHymnFrom(_NavDestination.category, hymn),
            ),
          ),
          icon: Icons.category_outlined,
          selectedIcon: Icons.category_rounded,
          label: 'ምድብ',
        ),
      _NavItem(
        destination: _NavDestination.hymnIndex,
        page: _pageFor(
          IndexPage(
            onOpenHymn: (hymn) =>
                _openHymnFrom(_NavDestination.hymnIndex, hymn),
          ),
        ),
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt_rounded,
        label: 'ማውጫ',
      ),
      _NavItem(
        destination: _NavDestination.number,
        page: _pageFor(
          NumberSearchPage(
            onOpenHymn: (hymn) => _openHymnFrom(_NavDestination.number, hymn),
          ),
        ),
        icon: Icons.numbers_rounded,
        selectedIcon: Icons.numbers_rounded,
        label: 'ቁጥር',
      ),
      _NavItem(
        destination: _NavDestination.favorites,
        page: _pageFor(
          FavoritesPage(
            onOpenHymn: (hymn) =>
                _openHymnFrom(_NavDestination.favorites, hymn),
          ),
        ),
        icon: Icons.favorite_outline_rounded,
        selectedIcon: Icons.favorite_rounded,
        label: 'ተወዳጅ',
      ),
      _NavItem(
        destination: _NavDestination.settings,
        page: _pageFor(const SettingsPage()),
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: 'ቅንብር',
      ),
    ];
  }

  Widget _pageFor(Widget page) {
    if (widget.usePlaceholderPagesForTesting) {
      return const SizedBox.shrink();
    }
    return page;
  }

  Widget _buildTabNavigator(_NavItem item, bool isActive) {
    final navigatorKey = _tabNavigatorKeys[item.destination]!;
    return NavigatorPopHandler<Object?>(
      enabled: isActive,
      onPopWithResult: (_) => navigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: RouteSettings(name: '/${item.destination.id}'),
          builder: (_) => item.page,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(List<_NavItem> items, int selectedIndex) {
    return AppBottomNavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: _onItemTapped,
      destinations: items
          .map(
            (item) => AppNavigationDestination(
              id: item.destination.id,
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildLandscapeNavigationRail(
    List<_NavItem> items,
    int selectedIndex,
  ) {
    return DecoratedBox(
      key: const ValueKey('landscape-navigation-rail'),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground.withValues(alpha: 0.97),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.14),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        minimum: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: 70,
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == selectedIndex;
              return Expanded(
                child: Tooltip(
                  message: item.label,
                  excludeFromSemantics: true,
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    excludeSemantics: true,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey(
                          'landscape-nav-${item.destination.id}',
                        ),
                        onTap: () => _onItemTapped(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: selected
                                    ? AppColors.accentGreen
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                selected ? item.selectedIcon : item.icon,
                                color: selected
                                    ? AppColors.accentGreen
                                    : AppColors.secondaryText,
                                size: selected ? 25 : 22,
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.accentGreen
                                        : AppColors.primaryText,
                                    fontSize: 10,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    fontFamily: 'NotoSansEthiopic',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

enum _NavDestination {
  category,
  hymnIndex,
  number,
  favorites,
  settings;

  String get id => switch (this) {
        _NavDestination.category => 'category',
        _NavDestination.hymnIndex => 'index',
        _NavDestination.number => 'number',
        _NavDestination.favorites => 'favorites',
        _NavDestination.settings => 'settings',
      };

  static _NavDestination fromId(String id) {
    return switch (id) {
      'category' => _NavDestination.category,
      'index' => _NavDestination.hymnIndex,
      'favorites' => _NavDestination.favorites,
      'settings' => _NavDestination.settings,
      _ => _NavDestination.number,
    };
  }
}

class _NavItem {
  final _NavDestination destination;
  final Widget page;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.destination,
    required this.page,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
