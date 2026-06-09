// lib/features/hymns/presentation/pages/categories_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/core/utils/category_image_loader.dart';
import 'package:amharic_hymnal_app/core/utils/category_ranges.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/category_hymns_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: BlocBuilder<HymnsBloc, HymnsState>(
            builder: (context, state) {
              final title = (state is HymnsLoaded && state.version == 'hagerigna') 
                  ? 'Authors' 
                  : 'Categories';
              return Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontFamily: 'NotoSansEthiopic',
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: BlocBuilder<HymnsBloc, HymnsState>(
            builder: (context, state) {
              if (state is HymnsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
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
                if (state.version == 'hymnal') {
                  // Use exact category ranges for hymnal
                  final categories = CategoryRanges.allCategories;
                  
                  if (categories.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.category_outlined,
                      title: 'No categories found',
                    );
                  }
                  
                  // Add bottom padding to prevent content from going under navigation bar
                  final bottomPadding = NavBarConstants.getBottomPadding(context);
                  
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid: 1 column for small screens (< 400px), 2 columns for larger screens
                      // Prevents overflow on smallest mobile devices (320px minimum)
                      final screenWidth = MediaQuery.of(context).size.width;
                      final crossAxisCount = screenWidth < 400 ? 1 : 2;
                      final cardWidth = crossAxisCount == 1 
                          ? screenWidth - 32 // Full width minus padding for single column
                          : (screenWidth - 32 - 12) / 2; // 50% width minus spacing for two columns
                      
                      return Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
                        child: GridView.builder(
                          controller: _scrollController,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final range = CategoryRanges.getRange(category);
                            return SizedBox(
                              width: cardWidth,
                              child: _buildCategoryCard(context, category, range, state.languageCode, state.version),
                            );
                          },
                        ),
                      );
                    },
                  );
                } else if (state.version == 'hagerigna') {
                  // Show authors for Hagerigna mode
                  final authors = _extractAuthors(state.hymns);
                  
                  if (authors.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.person_outline,
                      title: 'No authors found',
                    );
                  }
                  
                  // Sort authors alphabetically
                  authors.sort();
                  
                  // Add bottom padding to prevent content from going under navigation bar
                  final bottomPadding = NavBarConstants.getBottomPadding(context);
                  
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid: 1 column for small screens (< 400px), 2 columns for larger screens
                      // Prevents overflow on smallest mobile devices (320px minimum)
                      final screenWidth = MediaQuery.of(context).size.width;
                      final crossAxisCount = screenWidth < 400 ? 1 : 2;
                      final cardWidth = crossAxisCount == 1 
                          ? screenWidth - 32 // Full width minus padding for single column
                          : (screenWidth - 32 - 12) / 2; // 50% width minus spacing for two columns
                      
                      return Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
                        child: GridView.builder(
                          controller: _scrollController,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: authors.length,
                          itemBuilder: (context, index) {
                            final author = authors[index];
                            return SizedBox(
                              width: cardWidth,
                              child: _buildAuthorCard(context, author, state.languageCode, state.version),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              }
              
              // For other versions, show empty state
              return const EmptyStateWidget(
                icon: Icons.category_outlined,
                title: 'Categories only available for SDA Hymnal',
              );
            },
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

  Widget _buildCategoryCard(BuildContext context, String category, List<int>? range, String languageCode, String version) {
    final imageProvider = CategoryImageLoader.getCategoryImage(category);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (range != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryHymnsPage(
                  category: category,
                  fromNumber: range[0],
                  toNumber: range[1],
                  languageCode: languageCode,
                  version: version,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Category image as background
                if (imageProvider != null)
                  Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to solid color if image fails
                      return Container(
                        color: AppColors.surface,
                      );
                    },
                  )
                else
                  Container(
                    color: AppColors.surface,
                  ),
                // Gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                // Glass blur effect - reduced intensity for subtle effect
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                  child: Container(
                    color: AppColors.surface.withValues(alpha: 0.15),
                  ),
                ),
                // Category title text (ONLY - no numbers) - CENTERED
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansEthiopic',
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorCard(BuildContext context, String author, String languageCode, String version) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryHymnsPage(
                category: author,
                fromNumber: 0, // Not used for author filtering
                toNumber: 0, // Not used for author filtering
                languageCode: languageCode,
                version: version,
                author: author, // Pass author for filtering
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          child: GlassContainer(
            borderRadius: 16.0,
            blurSigma: 12.0,
            opacity: 0.25,
            padding: const EdgeInsets.all(16),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Author icon (no image needed for authors)
              const Icon(
                Icons.person,
                size: 48,
                color: AppColors.accentGreen,
              ),
              const SizedBox(height: 12),
              // Author name
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  author,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansEthiopic',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

