// lib/features/hymns/presentation/pages/category_hymns_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';

class CategoryHymnsPage extends StatefulWidget {
  final String category;
  final int fromNumber;
  final int toNumber;
  final String languageCode;
  final String version;
  final String? author; // For Hagerigna mode: filter by author

  const CategoryHymnsPage({
    super.key,
    required this.category,
    required this.fromNumber,
    required this.toNumber,
    required this.languageCode,
    required this.version,
    this.author,
  });

  @override
  State<CategoryHymnsPage> createState() => _CategoryHymnsPageState();
}

class _CategoryHymnsPageState extends State<CategoryHymnsPage> {
  String _sortType = 'number'; // Default sort: by number (for Hagerigna mode)

  @override
  void initState() {
    super.initState();
    // Load all hymns - we'll filter by number range or author
    context.read<HymnsBloc>().add(
          LoadHymns(
            widget.languageCode,
            widget.version,
            'number', // Sort by number for category pages
          ),
        );
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
          title: Text(
            widget.author != null ? 'ደራሲ፦ ${widget.author}' : widget.category,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontFamily: 'NotoSansEthiopic',
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: widget.author != null
              ? [
                  // Sort control for Hagerigna mode only
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.sort,
                      color: AppColors.primaryText,
                    ),
                    onSelected: (value) {
                      if (value == _sortType) return;
                      setState(() {
                        _sortType = value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'number',
                        child: Row(
                          children: [
                            Icon(
                              _sortType == 'number'
                                  ? Icons.check
                                  : Icons.check_box_outline_blank,
                              size: 20,
                              color: _sortType == 'number'
                                  ? AppColors.accentGreen
                                  : AppColors.secondaryText,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'በቁጥር',
                              style: TextStyle(
                                fontFamily: 'NotoSansEthiopic',
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'name',
                        child: Row(
                          children: [
                            Icon(
                              _sortType == 'name'
                                  ? Icons.check
                                  : Icons.check_box_outline_blank,
                              size: 20,
                              color: _sortType == 'name'
                                  ? AppColors.accentGreen
                                  : AppColors.secondaryText,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'በስም',
                              style: TextStyle(
                                fontFamily: 'NotoSansEthiopic',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: BlocBuilder<HymnsBloc, HymnsState>(
            builder: (context, state) {
              if (state is HymnsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
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
                // Filter hymns by number range (hymnal) or author (hagerigna)
                final categoryHymns = state.hymns.where((hymn) {
                  if (widget.author != null) {
                    // Hagerigna mode: filter by author
                    return hymn.artist != null && hymn.artist == widget.author;
                  } else {
                    // Hymnal mode: filter by number range
                    final hymnNumber = hymn.displayNumber;
                    return hymnNumber >= widget.fromNumber &&
                        hymnNumber <= widget.toNumber;
                  }
                }).toList();

                // Sort: by number for hymnal, by selected sort type for hagerigna
                if (widget.author != null) {
                  // Hagerigna mode: use selected sort type (default: number)
                  if (_sortType == 'name') {
                    categoryHymns.sort(
                        (a, b) => a.displayTitle.compareTo(b.displayTitle));
                  } else {
                    // Default: sort by number
                    categoryHymns.sort(
                        (a, b) => a.displayNumber.compareTo(b.displayNumber));
                  }
                } else {
                  // Hymnal mode: always sort by number
                  categoryHymns.sort(
                      (a, b) => a.displayNumber.compareTo(b.displayNumber));
                }

                if (categoryHymns.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.music_note,
                    title: widget.author != null
                        ? 'ለዚህ ደራሲ መዝሙር አልተገኘም'
                        : 'በዚህ ምድብ መዝሙር አልተገኘም',
                  );
                }

                // Add bottom padding to prevent content from going under navigation bar
                final bottomPadding = NavBarConstants.getBottomPadding(context);

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
                  itemCount: categoryHymns.length,
                  itemBuilder: (context, index) {
                    final hymn = categoryHymns[index];
                    return RepaintBoundary(
                      child: HymnListItem(
                        key: ValueKey(
                            'category_${hymn.id}_${hymn.displayNumber}'),
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

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
