// lib/features/hymns/presentation/pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/widgets/app_background.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';
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
        return Container(
          decoration: appBackgroundDecoration(context),
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
                  color: context.appColors.primaryText,
                  onPressed: () => _showClearHistoryDialog(context),
                  tooltip: AppLocalizations.of(context)?.historyClear ??
                      AppLocalizations.of(context)?.historyClear ??
                      'ታሪክን አጽዳ',
                ),
              ],
            ),
            body: SafeArea(
              child: BlocBuilder<HymnsBloc, HymnsState>(
                builder: (context, state) {
                  final history = HistoryService.getHistoryEntries();

                  if (state is HymnsLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            context.appColors.accent),
                      ),
                    );
                  }

                  if (state is HymnsError) {
                    return ErrorStateWidget(
                      message: state.message,
                    );
                  }

                  if (state is! HymnsLoaded) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            context.appColors.accent),
                      ),
                    );
                  }

                  if (history.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.history,
                      title: AppLocalizations.of(context)?.historyEmptyTitle ??
                          'እስካሁን ታሪክ የለም',
                      message:
                          AppLocalizations.of(context)?.historyEmptyMessage ??
                              'የከፈቷቸው መዝሙሮች እዚህ ይታያሉ',
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
                    return EmptyStateWidget(
                      icon: Icons.history,
                      title:
                          AppLocalizations.of(context)?.historyEmptyForBook ??
                              'በዚህ የመዝሙር ስብስብ ውስጥ ታሪክ የለም',
                      message:
                          AppLocalizations.of(context)?.historyEmptyMessage ??
                              'የከፈቷቸው መዝሙሮች እዚህ ይታያሉ',
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      NavBarConstants.getBottomPadding(context) -
                          HymnListItem.bottomGap(context),
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
                          child: Icon(
                            Icons.delete_outline,
                            color: context.appColors.primaryText,
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
        backgroundColor: context.appColors.surface,
        title: Text(
          AppLocalizations.of(context)?.historyClear ?? 'ታሪክን አጽዳ',
          style: TextStyle(color: context.appColors.primaryText),
        ),
        content: Text(
          AppLocalizations.of(context)?.historyClearConfirm ??
              'የተከፈቱ መዝሙሮች ታሪክ በሙሉ ይጥፋ?',
          style: TextStyle(color: context.appColors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)?.actionCancel ?? 'ይቅር',
              style: TextStyle(color: context.appColors.primaryText),
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
            child: Text(
              AppLocalizations.of(context)?.actionClear ?? 'አጽዳ',
              style: TextStyle(color: context.appColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
