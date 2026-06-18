// lib/core/widgets/content_blur_overlay.dart
import 'dart:ui';
import 'package:flutter/material.dart';

/// Subtle blur overlay for content that falls below the navigation bar
///
/// Applies a very light blur to content that is positioned below the vertical
/// midpoint of the navigation bar. This creates a subtle depth effect without
/// being distracting.
///
/// The blur is independent of the navigation bar's glass blur and remains
/// stable during scrolling.
class ContentBlurOverlay extends StatelessWidget {
  final Widget child;
  final double navBarHeight;
  final double navBarBottom;
  final double blurSigma;

  const ContentBlurOverlay({
    super.key,
    required this.child,
    required this.navBarHeight,
    required this.navBarBottom,
    this.blurSigma = 2.5, // Subtle blur, not distracting
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final navBarMidpoint = screenHeight - navBarBottom - (navBarHeight / 2);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Original content
            child,
            // Blur overlay for content below nav bar midpoint
            Positioned(
              left: 0,
              right: 0,
              top: navBarMidpoint,
              bottom: 0,
              child: RepaintBoundary(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Scroll-aware blur overlay that applies blur based on scroll position
///
/// Uses a ScrollController to detect when content scrolls below the nav bar
/// and applies blur only to that content.
class ScrollAwareBlurOverlay extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final double navBarHeight;
  final double navBarBottom;
  final double blurSigma;

  const ScrollAwareBlurOverlay({
    super.key,
    required this.child,
    required this.scrollController,
    required this.navBarHeight,
    required this.navBarBottom,
    this.blurSigma = 2.5,
  });

  @override
  State<ScrollAwareBlurOverlay> createState() => _ScrollAwareBlurOverlayState();
}

class _ScrollAwareBlurOverlayState extends State<ScrollAwareBlurOverlay> {
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final newOffset = widget.scrollController.offset;
    if ((newOffset - _scrollOffset).abs() > 1.0) {
      // Only update if scroll changed significantly to avoid excessive rebuilds
      setState(() {
        _scrollOffset = newOffset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final navBarMidpoint =
            screenHeight - widget.navBarBottom - (widget.navBarHeight / 2);

        // Calculate if content is below nav bar midpoint
        final contentBottom = _scrollOffset + screenHeight;
        final shouldBlur = contentBottom > navBarMidpoint;

        if (!shouldBlur) {
          return widget.child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Original content
            widget.child,
            // Blur overlay - only for content below nav bar
            Positioned(
              left: 0,
              right: 0,
              top: navBarMidpoint - _scrollOffset,
              bottom: 0,
              child: RepaintBoundary(
                child: CompositedTransformTarget(
                  link: LayerLink(),
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.blurSigma,
                        sigmaY: widget.blurSigma,
                      ),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
