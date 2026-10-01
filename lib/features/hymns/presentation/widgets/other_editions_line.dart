import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// "1961: 165 · 2004: 132" for a hymn from the hymnal API, and on a second
/// line any hymns marked similar. The icon says which is which, and the
/// full wording is read aloud and shown on a long press, so the note stays
/// one short line above the lyrics. Shows nothing for bundled hymns, when
/// offline, or when there is nothing to list.
class OtherEditionsLine extends StatefulWidget {
  final Hymn hymn;
  final SongEditionsService? service;

  const OtherEditionsLine({super.key, required this.hymn, this.service});

  @override
  State<OtherEditionsLine> createState() => _OtherEditionsLineState();
}

class _OtherEditionsLineState extends State<OtherEditionsLine> {
  Future<SongEditionLinks>? _links;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant OtherEditionsLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hymn.id != widget.hymn.id) _load();
  }

  void _load() {
    final id = widget.hymn.id;
    // Only API songs (`am-sda-2004-0132`) have other editions to look up.
    _links = id != null && id.startsWith('am-') && !widget.hymn.isBundled
        ? (widget.service ?? SongEditionsService.instance)
            .links(id)
            .catchError((Object _) => const SongEditionLinks())
        : null;
  }

  static HymnalVersion? _edition(String code) {
    final id = HymnalVersions.fromApiCode(code);
    return id == null ? null : HymnalVersions.byId(id);
  }

  /// "1961: 165 · 2004: 132".
  static String _numbers(BuildContext context, List<OtherEdition> editions) {
    final locale = AppLocalizations.of(context)?.locale;
    return editions
        .map((edition) =>
            '${_edition(edition.versionCode)?.briefLabelFor(locale) ?? edition.versionCode}'
            ': ${edition.number}')
        .join(' · ');
  }

  /// The same, spelled out for a screen reader and a long press.
  static String _spokenNumbers(
    BuildContext context,
    List<OtherEdition> editions,
  ) {
    final l = AppLocalizations.of(context);
    return editions
        .map((edition) =>
            '${_edition(edition.versionCode)?.labelFor(l?.locale) ?? edition.versionCode}'
            '${l?.editionNumber(edition.number) ?? ' ቁጥር ${edition.number}'}')
        .join(l?.listSeparator ?? '፣ ');
  }

  @override
  Widget build(BuildContext context) {
    final links = _links;
    final l = AppLocalizations.of(context);
    if (links == null) return const SizedBox.shrink();

    return FutureBuilder<SongEditionLinks>(
      future: links,
      builder: (context, snapshot) {
        final same = snapshot.data?.same ?? const <OtherEdition>[];
        final similar = snapshot.data?.similar ?? const <OtherEdition>[];
        if (same.isEmpty && similar.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (same.isNotEmpty)
                _line(
                  icon: Icons.menu_book_outlined,
                  text: _numbers(context, same),
                  spoken:
                      l?.otherEditionsSpoken(_spokenNumbers(context, same)) ??
                          'በሌሎች መጻሕፍት፦ ${_spokenNumbers(context, same)}',
                  key: const ValueKey('other-editions-line'),
                ),
              // Related but different hymns (another translation, other
              // verses, a different tune): listed for reference only.
              if (similar.isNotEmpty)
                _line(
                  icon: Icons.compare_arrows,
                  text: _numbers(context, similar),
                  spoken:
                      l?.similarHymnsSpoken(_spokenNumbers(context, similar)) ??
                          'ተመሳሳይ መዝሙሮች፦ ${_spokenNumbers(context, similar)}',
                  key: const ValueKey('similar-editions-line'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _line({
    required IconData icon,
    required String text,
    required String spoken,
    required Key key,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        label: spoken,
        excludeSemantics: true,
        child: Tooltip(
          message: spoken,
          excludeFromSemantics: true,
          child: Row(
            children: [
              Icon(icon, size: 15, color: context.appColors.secondaryText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  key: key,
                  // One line, so a book with several links never pushes the
                  // lyrics down.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
