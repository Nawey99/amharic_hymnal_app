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
    final title = 'መዝሙር ${widget.hymn.displayNumber} ኖታ';
    final subtitle = widget.hymn.displayTitle.isNotEmpty
        ? widget.hymn.displayTitle
        : 'ርዕስ የለም';

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontFamily: 'NotoSansEthiopic',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SheetMusicViewer(
                        sheetMusicFiles: widget.sheetMusicFiles,
                        hymnNumber: widget.hymn.displayNumber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
