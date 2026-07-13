import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
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
    final hymnTitle = _sheetMusicTitle(widget.hymn);
    final title = hymnTitle.isEmpty
        ? '${widget.hymn.displayNumber}'
        : '${widget.hymn.displayNumber} $hymnTitle';

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
                      Colors.black.withValues(alpha: 0.78),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'ዝጋ',
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.primaryText,
                            size: 28,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontFamily: 'NotoSansEthiopic',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: SheetMusicViewer(
                        sheetMusicFiles: widget.sheetMusicFiles,
                        hymnNumber: widget.hymn.displayNumber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _sheetMusicTitle(Hymn hymn) {
    final storedTitle = hymn.displayTitle.trim();
    final lyrics = hymn.displayLyrics.trim();
    final firstLyricsLine =
        lyrics.isEmpty ? '' : lyrics.split('\n').first.trim();

    if (firstLyricsLine.length > storedTitle.length &&
        firstLyricsLine.startsWith(storedTitle)) {
      return firstLyricsLine;
    }
    return storedTitle.isNotEmpty ? storedTitle : firstLyricsLine;
  }
}
