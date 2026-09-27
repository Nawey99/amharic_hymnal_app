import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';

/// The page's backdrop: the photograph when the reader has it switched on,
/// otherwise the palette's plain background.
///
/// The photograph is pushed away from the text either way, but in opposite
/// directions: darkened almost to black behind a dark palette, washed out
/// to a pale haze behind a light one. Both leave the picture as a texture
/// rather than something competing with the hymn.
BoxDecoration appBackgroundDecoration(BuildContext context) {
  final colors = context.appColors;
  final showPhoto = BackgroundImageService().isEnabled;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    image: showPhoto
        ? DecorationImage(
            image: const AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              colors.scrim,
              isDark ? BlendMode.darken : BlendMode.lighten,
            ),
          )
        : null,
    color: showPhoto ? null : colors.primaryBackground,
  );
}
