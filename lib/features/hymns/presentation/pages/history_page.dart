// lib/features/hymns/presentation/pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/core/widgets/empty_state_widget.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_open_callback.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' show sl;

class HistoryPage extends StatefulWidget {
  final HymnOpenCallback? onOpenHymn;

  const HistoryPage({super.key, this.onOpenHymn});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    // Load hymns when page is opened
    final settingsRepository = sl<SettingsRepository>();
    final languageCode = settingsRepository.getSelectedLanguage();
    final version = settingsRepository.getSelectedVersion();
    final sortType = settingsRepository.getSortType();
    context.read<HymnsBloc>().add(LoadHymns(languageCode, version, sortType));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundImageService(),
      builder: (context, _) {
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
                AppLocalizations.of(context)?.history ?? 'History',
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.primaryText,
                  onPressed: () => _showClearHistoryDialog(context),
                  tooltip: 'ታሪክን አጽዳ',
                ),
              ],
            ),
            body: SafeArea(
              child: BlocBuilder<HymnsBloc, HymnsState>(
                builder: (context, state) {
                  final history = HistoryService.getHistoryEntries();

                  if (state is HymnsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentGreen),
                      ),
                    );
                  }

                  if (state is HymnsError) {
                    return ErrorStateWidget(
                      message: state.message,
                    );
                  }

                  if (state is! HymnsLoaded) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accentGreen),
                      ),
                    );
                  }

                  if (history.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.history,
                      title: 'እስካሁን ታሪክ የለም',
                      message: 'መዝሙር ሲከፍቱ እዚህ ይታያል',
                    );
                  }

                  // Get hymns from history (in order of most recent first)
                  final historyHymns = <(Hymn, HistoryEntry)>[];
                  for (final entry in history) {
                    if (entry.version != state.version) continue;
                    try {
                      final hymn = state.hymns.firstWhere(
                        (h) => h.displayNumber == entry.hymnNumber,
                      );
                      historyHymns.add((hymn, entry));
                    } catch (e) {
                      // Hymn not found in current list, skip it
                      continue;
                    }
                  }

                  if (historyHymns.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.history,
                      title: 'በዚህ መዝሙር ስብስብ ታሪክ የለም',
                      message: 'መዝሙር ከከፈቱ በኋላ እዚህ ይታያል',
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      NavBarConstants.getBottomPadding(context),
                    ),
                    itemCount: historyHymns.length,
                    itemBuilder: (context, index) {
                      final (hymn, entry) = historyHymns[index];
                      return Dismissible(
                        key: ValueKey(
                          'history_${entry.version}_${hymn.id}_${hymn.displayNumber}',
                        ),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: AppColors.primaryText,
                          ),
                        ),
                        onDismissed: (_) async {
                          await HistoryService.removeFromHistory(
                            entry.hymnNumber,
                            version: entry.version,
                          );
                          if (mounted) setState(() {});
                        },
                        child: HymnListItem(
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
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'ታሪክን አጽዳ',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: const Text(
          'የተከፈቱ መዝሙሮች ታሪክ በሙሉ ይጠፋ?',
          style: TextStyle(color: AppColors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ይቅር',
              style: TextStyle(color: AppColors.primaryText),
            ),
          ),
          TextButton(
            onPressed: () async {
              await HistoryService.clearHistory();
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {}); // Refresh the page
              }
            },
            child: const Text(
              'አጽዳ',
              style: TextStyle(color: AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );
  }
}
