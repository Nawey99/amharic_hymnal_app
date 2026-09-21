import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// "Also in: 2004 ውዳሴ #132 · 1961 ውዳሴ #165" for a hymn from the hymnal API.
/// Shows nothing for bundled hymns, when offline, or when the hymn is in no
/// other edition.
class OtherEditionsLine extends StatefulWidget {
  final Hymn hymn;
  final SongEditionsService? service;

  const OtherEditionsLine({super.key, required this.hymn, this.service});

  @override
  State<OtherEditionsLine> createState() => _OtherEditionsLineState();
}

class _OtherEditionsLineState extends State<OtherEditionsLine> {
  Future<List<OtherEdition>>? _editions;

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
    _editions = id != null && id.startsWith('am-')
        ? (widget.service ?? SongEditionsService.instance)
            .otherEditions(id)
            .catchError((Object _) => const <OtherEdition>[])
        : null;
  }

  static String _editionLabel(String code) {
    final id = HymnalVersions.fromApiCode(code);
    return id == null ? code : HymnalVersions.byId(id).shortLabel;
  }

  @override
  Widget build(BuildContext context) {
    final editions = _editions;
    if (editions == null) return const SizedBox.shrink();

    return FutureBuilder<List<OtherEdition>>(
      future: editions,
      builder: (context, snapshot) {
        final others = snapshot.data ?? const <OtherEdition>[];
        if (others.isEmpty) return const SizedBox.shrink();
        final text = others
            .map((edition) =>
                '${_editionLabel(edition.versionCode)} ቁ. ${edition.number}')
            .join(' · ');
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 15,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'በሌሎች መጻሕፍት፦ $text',
                  key: const ValueKey('other-editions-line'),
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
      },
    );
  }
}
