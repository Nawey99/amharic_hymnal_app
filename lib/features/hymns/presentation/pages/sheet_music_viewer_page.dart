import 'dart:async';

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

class _SheetMusicViewerPageState extends State<SheetMusicViewerPage>
    with WidgetsBindingObserver {
  final Object _screenProtectionOwner = Object();

  StreamSubscription<SecureScreenEvent>? _secureScreenSubscription;
  bool _screenProtectionActive = false;
  bool _isCaptureActive = false;
  bool _isBackgrounded = false;

  bool get _isPrivacyOverlayVisible =>
      SecureScreenService.usesPrivacyOverlay &&
      (_isCaptureActive || _isBackgrounded);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.sheetMusicFiles.isNotEmpty) {
      _startScreenProtection();
    }
  }

  @override
  void didUpdateWidget(covariant SheetMusicViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasProtected = oldWidget.sheetMusicFiles.isNotEmpty;
    final shouldProtect = widget.sheetMusicFiles.isNotEmpty;
    if (wasProtected == shouldProtect) return;

    if (shouldProtect) {
      _startScreenProtection();
    } else {
      _stopScreenProtection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScreenProtection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!SecureScreenService.usesPrivacyOverlay || !_screenProtectionActive) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_resumeFromBackground());
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (!_isBackgrounded && mounted) {
          setState(() {
            _isBackgrounded = true;
          });
        }
        return;
    }
  }

  void _startScreenProtection() {
    if (_screenProtectionActive) return;
    _screenProtectionActive = true;

    if (SecureScreenService.usesPrivacyOverlay) {
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      _isBackgrounded =
          lifecycleState != null && lifecycleState != AppLifecycleState.resumed;
      _secureScreenSubscription =
          SecureScreenService.events.listen(_handleSecureScreenEvent);
    }

    unawaited(
      SecureScreenService.acquire(_screenProtectionOwner).then((captured) {
        if (!mounted || !_screenProtectionActive) return;
        if (_isCaptureActive != captured) {
          setState(() {
            _isCaptureActive = captured;
          });
        }
      }),
    );
  }

  void _stopScreenProtection() {
    if (!_screenProtectionActive) return;
    _screenProtectionActive = false;

    final subscription = _secureScreenSubscription;
    _secureScreenSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    unawaited(SecureScreenService.release(_screenProtectionOwner));
    _isCaptureActive = false;
    _isBackgrounded = false;
  }

  void _handleSecureScreenEvent(SecureScreenEvent event) {
    if (!mounted || !_screenProtectionActive) return;

    switch (event.type) {
      case SecureScreenEventType.captureChanged:
        final captured = event.isCaptured ?? false;
        if (_isCaptureActive != captured) {
          setState(() {
            _isCaptureActive = captured;
          });
        }
        return;
      case SecureScreenEventType.screenshotTaken:
        _showScreenshotWarning();
        return;
    }
  }

  Future<void> _resumeFromBackground() async {
    final captured = await SecureScreenService.refreshCaptureState();
    if (!mounted || !_screenProtectionActive) return;

    setState(() {
      _isCaptureActive = captured;
      _isBackgrounded = false;
    });
  }

  void _showScreenshotWarning() {
    if (!mounted || !_screenProtectionActive) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      _presentScreenshotWarning(messenger);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_screenProtectionActive) return;
      final deferredMessenger = ScaffoldMessenger.maybeOf(context);
      if (deferredMessenger != null) {
        _presentScreenshotWarning(deferredMessenger);
      }
    });
  }

  void _presentScreenshotWarning(ScaffoldMessengerState messenger) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Screenshots of sheet music are not permitted.',
            style: TextStyle(color: AppColors.primaryText),
          ),
          backgroundColor: Color(0xFFB3261E),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SheetMusicViewer(
                            sheetMusicFiles: widget.sheetMusicFiles,
                            hymnNumber: widget.hymn.displayNumber,
                          ),
                          if (_isPrivacyOverlayVisible)
                            const Positioned.fill(
                              child: AbsorbPointer(
                                child: ColoredBox(
                                  color: Colors.black,
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        'Screen capture is not allowed for this content.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
