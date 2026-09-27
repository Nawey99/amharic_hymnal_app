// lib/features/hymns/presentation/pages/category_hymns_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/widgets/app_background.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_open_callback.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';

class CategoryHymnsPage extends StatefulWidget {
  /// The category's name as the edition's hymns carry it, or the author's
  /// name when [author] is set.
  final String category;
  final String languageCode;
  final String version;
  final String? author; // For Hagerigna mode: filter by author
  final HymnOpenCallback? onOpenHymn;

  const CategoryHymnsPage({
    super.key,
    required this.category,
    required this.languageCode,
    required this.version,
    this.author,
    this.onOpenHymn,
  });

  @override
  State<CategoryHymnsPage> createState() => _CategoryHymnsPageState();
}

class _CategoryHymnsPageState extends State<CategoryHymnsPage> {
  String _sortType = 'number'; // Default sort: by number (for Hagerigna mode)

  @override
  void initState() {
    super.initState();
    // Load all hymns - we'll filter by category or author
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
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) {
        final bgService = BackgroundImageService();
        return _buildPage(context, bgService);
      },
    );
  }

  Widget _buildPage(BuildContext context, BackgroundImageService bgService) {
    return Container(
      decoration: appBackgroundDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.author ?? widget.category,
            style: TextStyle(
              color: context.appColors.primaryText,
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
                    icon: Icon(
                      Icons.sort,
                      color: context.appColors.primaryText,
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
                                  ? context.appColors.accent
                                  : context.appColors.secondaryText,
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
                                  ? context.appColors.accent
                                  : context.appColors.secondaryText,
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
                return Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(context.appColors.accent),
                  ),
                );
              }

              if (state is HymnsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: context.appColors.primaryText,
                        fontSize: 16,
                        fontFamily: 'NotoSansEthiopic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (state is HymnsLoaded) {
                // Filter hymns by category (hymnal) or author (hagerigna)
                final categoryHymns = state.hymns.where((hymn) {
                  if (widget.author != null) {
                    // Hagerigna mode: filter by author
                    return hymn.artist != null && hymn.artist == widget.author;
                  } else {
                    // Hymnal mode: the edition's own category, not a
                    // number range -- each book groups its hymns differently.
                    return hymn.category?.trim() == widget.category;
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
                        ? 'ለዚህ ዘማሪ መዝሙር አልተገኘም'
                        : 'በዚህ ምድብ መዝሙር አልተገኘም',
                  );
                }

                // Add bottom padding to prevent content from going under navigation bar
                // The last item's own gap already counts towards it.
                final bottomPadding =
                    NavBarConstants.getBottomPadding(context) -
                        HymnListItem.bottomGap(context);

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

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
