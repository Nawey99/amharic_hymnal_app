// lib/core/utils/nav_bar_constants.dart
import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/utils/responsive_layout.dart';

/// Navigation bar layout constants
///
/// These constants define the exact dimensions of the floating navigation bar
/// to ensure consistent bottom padding across all scrollable pages.
class NavBarConstants {
  static const double surfaceHeight = 68.0;
  static const double compactSurfaceHeight = 56.0;
  static const double raisedExtent = 16.0;
  static const double compactRaisedExtent = 8.0;

  /// Full portrait height, including the raised number action.
  static const double navBarHeight = surfaceHeight + raisedExtent;

  static const double navBarBottomMargin = 8.0;

  /// Total space needed from bottom of screen to account for nav bar
  /// This is: navBarHeight + navBarBottomMargin
  static const double navBarTotalSpace = navBarHeight + navBarBottomMargin;

  /// Additional padding to ensure content doesn't sit right at the edge
  static const double contentPadding = 16.0;

  /// Total bottom padding needed for scrollable content
  /// Side-navigation layouts only need the safe area and content inset.
  static double getBottomPadding(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    if (ResponsiveLayout.useSideNavigation(context)) {
      return safeAreaBottom + contentPadding;
    }
    return safeAreaBottom + navBarTotalSpace + contentPadding;
  }
}
