// lib/features/hymns/presentation/widgets/sheet_music_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:amharic_hymnal_app/core/services/secure_screen_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/widgets/glass_container.dart';

/// Widget for displaying sheet music images with zoom and pagination support
/// Supports 0, 1, or 2 sheet music files per hymn
/// For 2 files: Labels them as "2L" (left) and "2R" (right)
/// For 1 file: Shows file number
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
  final PageController _pageController = PageController();
  final List<TransformationController> _transformationControllers = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Initialize transformation controllers for each sheet music page
    for (int i = 0; i < widget.sheetMusicFiles.length; i++) {
      _transformationControllers.add(TransformationController());
    }
    SecureScreenService.setProtected(widget.sheetMusicFiles.isNotEmpty);
  }

  @override
  void didUpdateWidget(covariant SheetMusicViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sheetMusicFiles.length != widget.sheetMusicFiles.length) {
      while (
          _transformationControllers.length < widget.sheetMusicFiles.length) {
        _transformationControllers.add(TransformationController());
      }
      while (
          _transformationControllers.length > widget.sheetMusicFiles.length) {
        _transformationControllers.removeLast().dispose();
      }
      SecureScreenService.setProtected(widget.sheetMusicFiles.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformationControllers) {
      controller.dispose();
    }
    SecureScreenService.setProtected(false);
    super.dispose();
  }

  /// Get asset path for sheet music image
  String _getAssetPath(String fileName) {
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

  /// Get label for sheet music file
  String _getFileLabel(int index) {
    if (widget.sheetMusicFiles.length == 2) {
      // Two files: Label as "2L" and "2R"
      return index == 0 ? '2L' : '2R';
    } else {
      // One file: Show file number
      return '${index + 1}';
    }
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
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
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
    final label = _getFileLabel(index);
    final controller = _transformationControllers[index];

    return GlassCard(
      borderRadius: 12.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File label
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  'ገጽ $label',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansEthiopic',
                  ),
                ),
              ],
            ),
          ),
          // Sheet music image with zoom
          // Use 2.0 max scale for sheet music (per requirements), 0.8 min scale
          Expanded(
            child: GestureDetector(
              onDoubleTap: () => _togglePageZoom(controller),
              child: InteractiveViewer(
                transformationController: controller,
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(100),
                constrained: true,
                onInteractionEnd: (_) {
                  final currentScale = controller.value.getMaxScaleOnAxis();
                  if (currentScale < 1.0) {
                    controller.value = Matrix4.identity();
                  } else if (currentScale > 4.0) {
                    controller.value = Matrix4.identity()..scale(4.0);
                  }
                },
                child: RepaintBoundary(
                  child: _buildSheetMusicImage(assetPath),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _togglePageZoom(TransformationController controller) {
    final currentScale = controller.value.getMaxScaleOnAxis();
    controller.value = currentScale > 1.01
        ? Matrix4.identity()
        : (Matrix4.identity()..scale(2.0));
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

        return Container(
          decoration: BoxDecoration(
            // EXPLICIT: Use theme-aware background for sheet music image container
            // White background is appropriate for sheet music images for readability
            color: Colors.white, // Keep white for sheet music contrast
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            // Optimize memory usage for low-tier devices
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (context, error, stackTrace) {
              // Debug: Log error details
              if (kDebugMode) {
                debugPrint('❌ Failed to load sheet music: $assetPath');
                debugPrint('   Error: $error');
              }
              // Fallback if image not found - try alternative extensions
              return _buildErrorWithRetry(context, assetPath);
            },
            // Image.asset doesn't support loadingBuilder, use frameBuilder instead
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                ),
              );
            },
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
