// lib/features/hymns/presentation/widgets/sheet_music_viewer.dart
import 'dart:io';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, listEquals;
import 'package:flutter/material.dart';

/// Widget for displaying sheet music images with zoom and pagination support
/// Supports 0, 1, or 2 sheet music files per hymn
class SheetMusicViewer extends StatefulWidget {
  final List<String> sheetMusicFiles;
  final int hymnNumber;

  const SheetMusicViewer({
    super.key,
    required this.sheetMusicFiles,
    required this.hymnNumber,
  });

  @override
  State<SheetMusicViewer> createState() => _SheetMusicViewerState();
}

class _SheetMusicViewerState extends State<SheetMusicViewer> {
  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;
  static const double _zoomThreshold = 1.01;
  static const double _sheetMusicAspectRatio = 2 / 3;

  final PageController _pageController = PageController();
  final List<TransformationController> _transformationControllers = [];
  final List<bool> _pageIsZoomed = [];
  int _currentPage = 0;
  Offset? _doubleTapPosition;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.sheetMusicFiles.length; i++) {
      _addPageController();
    }
  }

  @override
  void didUpdateWidget(covariant SheetMusicViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.sheetMusicFiles, widget.sheetMusicFiles)) {
      for (final controller in _transformationControllers) {
        controller.dispose();
      }
      _transformationControllers.clear();
      _pageIsZoomed.clear();
      for (int i = 0; i < widget.sheetMusicFiles.length; i++) {
        _addPageController();
      }
      _currentPage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  void _addPageController() {
    _transformationControllers.add(TransformationController());
    _pageIsZoomed.add(false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Get asset path for sheet music image
  String _getAssetPath(String fileName) {
    if (fileName.startsWith('/') ||
        RegExp(r'^[A-Za-z]:\\').hasMatch(fileName)) {
      return fileName;
    }
    // Remove any path separators and clean the filename
    final cleanFileName = fileName.replaceAll('\\', '/').split('/').last;
    // Construct asset path: files are directly in assets/sheet_music/
    // File names are like "01.jpg", "08L.jpg", "08R.jpg", etc.
    // If fileName already contains path, use it directly, otherwise prepend assets/sheet_music/
    if (cleanFileName.startsWith('assets/')) {
      return cleanFileName;
    }
    return 'assets/sheet_music/$cleanFileName';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sheetMusicFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        // Page indicator
        if (widget.sheetMusicFiles.length > 1) ...[
          _buildPageIndicator(),
          const SizedBox(height: 12),
        ],
        // Sheet music viewer
        _buildSheetMusicViewer(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 48,
              color: AppColors.secondaryText,
            ),
            SizedBox(height: 12),
            Text(
              'ኖታ አልተገኘም',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.sheetMusicFiles.length,
        (index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? AppColors.accentGreen
                  : AppColors.secondaryText.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetMusicViewer() {
    final currentPageIsZoomed = _pageIsZoomed.isNotEmpty &&
        _currentPage < _pageIsZoomed.length &&
        _pageIsZoomed[_currentPage];

    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        physics: widget.sheetMusicFiles.length == 1 || currentPageIsZoomed
            ? const NeverScrollableScrollPhysics()
            : null,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: widget.sheetMusicFiles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildSheetMusicPage(index),
          );
        },
      ),
    );
  }

  Widget _buildSheetMusicPage(int index) {
    final fileName = widget.sheetMusicFiles[index];
    final assetPath = _getAssetPath(fileName);
    final controller = _transformationControllers[index];

    return Center(
      child: AspectRatio(
        aspectRatio: _sheetMusicAspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ColoredBox(
            color: Colors.white,
            child: GestureDetector(
              onDoubleTapDown: (details) {
                _doubleTapPosition = details.localPosition;
              },
              onDoubleTap: () => _togglePageZoom(
                index,
                _doubleTapPosition,
              ),
              child: InteractiveViewer(
                transformationController: controller,
                alignment: Alignment.center,
                minScale: _minScale,
                maxScale: _maxScale,
                panEnabled: _pageIsZoomed[index],
                boundaryMargin: EdgeInsets.zero,
                constrained: true,
                clipBehavior: Clip.hardEdge,
                onInteractionUpdate: (_) => _syncZoomState(index),
                onInteractionEnd: (_) {
                  final currentScale = controller.value.getMaxScaleOnAxis();
                  if (currentScale <= _zoomThreshold) {
                    controller.value = Matrix4.identity();
                    _setPageZoomed(index, false);
                  } else {
                    _setPageZoomed(index, true);
                  }
                },
                child: RepaintBoundary(
                  child: _buildSheetMusicImage(assetPath),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _syncZoomState(int index) {
    if (index >= _transformationControllers.length) return;
    final scale = _transformationControllers[index].value.getMaxScaleOnAxis();
    _setPageZoomed(index, scale > _zoomThreshold);
  }

  void _setPageZoomed(int index, bool isZoomed) {
    if (!mounted ||
        index >= _pageIsZoomed.length ||
        _pageIsZoomed[index] == isZoomed) {
      return;
    }
    setState(() {
      _pageIsZoomed[index] = isZoomed;
    });
  }

  void _togglePageZoom(int index, Offset? focalPoint) {
    final controller = _transformationControllers[index];
    final currentScale = controller.value.getMaxScaleOnAxis();
    final shouldReset = currentScale > _zoomThreshold;
    if (shouldReset) {
      controller.value = Matrix4.identity();
    } else {
      final focal = focalPoint ?? Offset.zero;
      controller.value = Matrix4.identity()
        ..translate(focal.dx, focal.dy)
        ..scale(2.0)
        ..translate(-focal.dx, -focal.dy);
    }
    _setPageZoomed(index, !shouldReset);
    _doubleTapPosition = null;
  }

  Widget _buildSheetMusicImage(String assetPath) {
    // Debug: Log asset path for troubleshooting
    if (kDebugMode) {
      debugPrint('🎵 Loading sheet music from: $assetPath');
    }

    // Get screen size for cache dimensions (optimize for low-memory devices)
    // Use MediaQuery to get screen width, cache at 2x for retina displays
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cache dimensions: use screen width * 2 for retina, but cap at reasonable size
        final screenWidth = MediaQuery.of(context).size.width;
        final cacheWidth = (screenWidth * 2)
            .round()
            .clamp(400, 1200); // Cap between 400-1200px
        final cacheHeight = (cacheWidth * 1.5)
            .round(); // Assume 2:3 aspect ratio for sheet music

        return SizedBox.expand(
          child: _buildImage(assetPath, cacheWidth, cacheHeight),
        );
      },
    );
  }

  Widget _buildImage(String assetPath, int cacheWidth, int cacheHeight) {
    final isLocalFile = assetPath.startsWith('/') ||
        RegExp(r'^[A-Za-z]:\\').hasMatch(assetPath);
    if (isLocalFile) {
      return Image.file(
        File(assetPath),
        fit: BoxFit.contain,
        alignment: Alignment.center,
        gaplessPlayback: true,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ Failed to load cached sheet music: $assetPath');
            debugPrint('   Error: $error');
          }
          return _buildErrorWithRetry(context, assetPath);
        },
      );
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('❌ Failed to load sheet music: $assetPath');
          debugPrint('   Error: $error');
        }
        return _buildErrorWithRetry(context, assetPath);
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
          ),
        );
      },
    );
  }

  /// Build error widget with retry logic for alternative file extensions
  Widget _buildErrorWithRetry(BuildContext context, String assetPath) {
    // Try alternative extensions if original failed
    final basePath = assetPath.split('.').first;
    final extensions = ['jpg', 'jpeg', 'png', 'pdf'];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            'የኖታ ምስል አልተገኘም\n$assetPath',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontFamily: 'NotoSansEthiopic',
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Text(
              'Tried: ${extensions.map((e) => '$basePath.$e').join(', ')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
