import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// "Also in: 2004 ውዳሴ #132 · 1961 ውዳሴ #165" for a hymn from the hymnal API,
/// and on a second line any hymns marked similar. Shows nothing for bundled
/// hymns, when offline, or when there is nothing to list.
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
    _links = id != null && id.startsWith('am-')
        ? (widget.service ?? SongEditionsService.instance)
            .links(id)
            .catchError((Object _) => const SongEditionLinks())
        : null;
  }

  static String _editionLabel(String code) {
    final id = HymnalVersions.fromApiCode(code);
    return id == null ? code : HymnalVersions.byId(id).shortLabel;
  }

  static String _numbers(List<OtherEdition> editions) => editions
      .map((edition) =>
          '${_editionLabel(edition.versionCode)} ቁ. ${edition.number}')
      .join(' · ');

  @override
  Widget build(BuildContext context) {
    final links = _links;
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
                  text: 'በሌሎች መጻሕፍት፦ ${_numbers(same)}',
                  key: const ValueKey('other-editions-line'),
                ),
              // Related but different hymns (another translation, other
              // verses, a different tune): listed for reference only.
              if (similar.isNotEmpty)
                _line(
                  icon: Icons.compare_arrows,
                  text: 'ተመሳሳይ መዝሙሮች፦ ${_numbers(similar)}',
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
    required Key key,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.secondaryText),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              key: key,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontFamily: 'NotoSansEthiopic',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
