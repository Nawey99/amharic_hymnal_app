import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/core/widgets/main_page_title_bar.dart';
import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';
import 'package:amharic_hymnal_app/core/models/hymn_category.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/utils/category_icon_mapper.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_open_callback.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/category_hymns_page.dart';

class CategoriesPage extends StatefulWidget {
  final HymnOpenCallback? onOpenHymn;

  const CategoriesPage({super.key, this.onOpenHymn});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) {
        final bgService = BackgroundImageService();
        return _buildPage(context, bgService);
      },
    );
  }

  Widget _buildPage(BuildContext context, BackgroundImageService bgService) {
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const MainPageTitleBar(title: 'ምድቦች'),
              Expanded(
                child: BlocBuilder<HymnsBloc, HymnsState>(
                  builder: (context, state) {
                    if (state is HymnsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentGreen),
                        ),
                      );
                    }

                    if (state is HymnsError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            state.message,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 16,
                              fontFamily: 'NotoSansEthiopic',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (state is HymnsLoaded) {
                      if (HymnalVersions.hasCategories(state.version)) {
                        // Use exact category ranges for hymnal
                        final categories = _categoriesWithSongs(state.hymns);

                        if (categories.isEmpty) {
                          return const EmptyStateWidget(
                            icon: Icons.category_outlined,
                            title: 'ምድቦች አልተገኙም',
                          );
                        }

                        // Add bottom padding to prevent content from going under navigation bar
                        final bottomPadding =
                            NavBarConstants.getBottomPadding(context);

                        return ListView.separated(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            compactLandscape ? 4 : 8,
                            16,
                            bottomPadding,
                          ),
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => SizedBox(
                            height: compactLandscape ? 6 : 10,
                          ),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return _buildCategoryListItem(
                              context,
                              category.nameAmharic,
                              category.startNumber,
                              category.endNumber,
                              state.languageCode,
                              state.version,
                              bgService.isEnabled,
                            );
                          },
                        );
                      } else if (state.version == HymnalVersions.hagerigna) {
                        // Show authors for Hagerigna mode
                        final authors = _extractAuthors(state.hymns);

                        if (authors.isEmpty) {
                          return const EmptyStateWidget(
                            icon: Icons.person_outline,
                            title: 'ደራሲዎች አልተገኙም',
                          );
                        }

                        // Sort authors alphabetically
                        authors.sort();

                        // Add bottom padding to prevent content from going under navigation bar
                        final bottomPadding =
                            NavBarConstants.getBottomPadding(context);

                        return ListView.separated(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            compactLandscape ? 4 : 8,
                            16,
                            bottomPadding,
                          ),
                          itemCount: authors.length,
                          separatorBuilder: (_, __) => SizedBox(
                            height: compactLandscape ? 6 : 10,
                          ),
                          itemBuilder: (context, index) {
                            final author = authors[index];
                            return _buildAuthorListItem(
                              context,
                              author,
                              state.languageCode,
                              state.version,
                              bgService.isEnabled,
                            );
                          },
                        );
                      }
                    }

                    // For other versions, show empty state
                    return const EmptyStateWidget(
                      icon: Icons.category_outlined,
                      title: 'ምድቦች ለአድቬንቲስት መዝሙር ብቻ ይገኛሉ',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Extract unique authors from hymns (for Hagerigna mode)
  List<String> _extractAuthors(List<dynamic> hymns) {
    final authors = <String>{};
    for (final hymn in hymns) {
      if (hymn.artist != null && hymn.artist!.isNotEmpty) {
        authors.add(hymn.artist!);
      }
    }
    return authors.toList();
  }

  List<HymnCategory> _categoriesWithSongs(List<Hymn> hymns) {
    final availableNumbers = hymns
        .map((hymn) => hymn.displayNumber)
        .where((number) => number > 0)
        .toSet();

    return HymnCategories.all.where((category) {
      for (var number = category.startNumber;
          number <= category.endNumber;
          number++) {
        if (availableNumbers.contains(number)) return true;
      }
      return false;
    }).toList(growable: false);
  }

  Widget _buildCategoryListItem(
    BuildContext context,
    String category,
    int startNumber,
    int endNumber,
    String languageCode,
    String version,
    bool backgroundImageEnabled,
  ) {
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryHymnsPage(
                category: category,
                fromNumber: startNumber,
                toNumber: endNumber,
                languageCode: languageCode,
                version: version,
                onOpenHymn: widget.onOpenHymn,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: GlassContainer(
          borderRadius: 12.0,
          blurSigma: 12.0,
          opacity: backgroundImageEnabled ? 0.22 : 0.62,
          color: AppColors.surface,
          border: Border.all(
            color: backgroundImageEnabled
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.accentGreen.withValues(alpha: 0.16),
            width: 1.2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compactLandscape ? 10 : 12,
            vertical: compactLandscape ? 6 : 10,
          ),
          child: Row(
            children: [
              _buildCategoryThumbnail(category, compactLandscape),
              SizedBox(width: compactLandscape ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: compactLandscape ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansEthiopic',
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.secondaryText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryThumbnail(String category, bool compactLandscape) {
    return Container(
      width: compactLandscape ? 44 : 58,
      height: compactLandscape ? 44 : 58,
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.34),
        ),
      ),
      child: Icon(
        CategoryIconMapper.iconFor(category),
        color: AppColors.accentGreen,
        size: compactLandscape ? 24 : 28,
      ),
    );
  }

  Widget _buildAuthorListItem(
    BuildContext context,
    String author,
    String languageCode,
    String version,
    bool backgroundImageEnabled,
  ) {
    final compactLandscape = ResponsiveLayout.isCompactLandscape(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryHymnsPage(
                category: author,
                fromNumber: 0,
                toNumber: 0,
                languageCode: languageCode,
                version: version,
                author: author,
                onOpenHymn: widget.onOpenHymn,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: GlassContainer(
          borderRadius: 12.0,
          blurSigma: 12.0,
          opacity: backgroundImageEnabled ? 0.22 : 0.62,
          color: AppColors.surface,
          border: Border.all(
            color: backgroundImageEnabled
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.accentGreen.withValues(alpha: 0.16),
            width: 1.2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compactLandscape ? 10 : 12,
            vertical: compactLandscape ? 6 : 10,
          ),
          child: Row(
            children: [
              Container(
                width: compactLandscape ? 44 : 58,
                height: compactLandscape ? 44 : 58,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.accentGreen,
                  size: compactLandscape ? 24 : 28,
                ),
              ),
              SizedBox(width: compactLandscape ? 10 : 12),
              Expanded(
                child: Text(
                  author,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: compactLandscape ? 16 : 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansEthiopic',
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.secondaryText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
