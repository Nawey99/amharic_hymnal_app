import 'package:flutter/material.dart';

abstract final class ResponsiveLayout {
  static bool useSideNavigation(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 600 && size.width > size.height;
  }

  static bool isCompactLandscape(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height && size.height < 600;
  }
}
