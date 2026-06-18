import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/secure_screen_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/sheet_music_viewer.dart';

class SheetMusicViewerPage extends StatefulWidget {
  final Hymn hymn;
  final List<String> sheetMusicFiles;

  const SheetMusicViewerPage({
    super.key,
    required this.hymn,
    required this.sheetMusicFiles,
  });

  @override
  State<SheetMusicViewerPage> createState() => _SheetMusicViewerPageState();
}

class _SheetMusicViewerPageState extends State<SheetMusicViewerPage> {
  @override
  void initState() {
    super.initState();
    SecureScreenService.setProtected(widget.sheetMusicFiles.isNotEmpty);
  }

  @override
  void didUpdateWidget(covariant SheetMusicViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sheetMusicFiles.length != widget.sheetMusicFiles.length) {
      SecureScreenService.setProtected(widget.sheetMusicFiles.isNotEmpty);
    }
  }

  @override
  void dispose() {
    SecureScreenService.setProtected(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.hymn.displayTitle.isNotEmpty
        ? widget.hymn.displayTitle
        : 'መዝሙር ${widget.hymn.displayNumber}';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'NotoSansEthiopic'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontFamily: 'NotoSansEthiopic',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SheetMusicViewer(
              sheetMusicFiles: widget.sheetMusicFiles,
              hymnNumber: widget.hymn.displayNumber,
            ),
          ],
        ),
      ),
    );
  }
}
