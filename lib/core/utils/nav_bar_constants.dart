// lib/core/utils/nav_bar_constants.dart
import 'package:flutter/material.dart';

/// Navigation bar layout constants
/// 
/// These constants define the exact dimensions of the floating navigation bar
/// to ensure consistent bottom padding across all scrollable pages.
class NavBarConstants {
  /// Height of the navigation bar container (from FloatingNavigationBar)
  static const double navBarHeight = 64.0;
  
  /// Bottom margin of the navigation bar (from Positioned bottom: 16)
  static const double navBarBottomMargin = 16.0;
  
  /// Total space needed from bottom of screen to account for nav bar
  /// This is: navBarHeight + navBarBottomMargin
  static const double navBarTotalSpace = navBarHeight + navBarBottomMargin;
  
  /// Additional padding to ensure content doesn't sit right at the edge
  static const double contentPadding = 16.0;
  
  /// Total bottom padding needed for scrollable content
  /// Formula: safeAreaBottom + navBarTotalSpace + contentPadding
  static double getBottomPadding(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    return safeAreaBottom + navBarTotalSpace + contentPadding;
  }
}

