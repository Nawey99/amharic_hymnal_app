// lib/core/utils/category_image_loader.dart
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';

/// Maps category names (Amharic) to image file names
/// Category images are stored in assets/category/
class CategoryImageLoader {
  /// Mapping of category names to image file names (without extension)
  /// The image files are in webp format: assets/category/{filename}.webp
  static const Map<String, String> _categoryImageMap = {
    'ምስጋና': 'praise',
    'ስግደት': 'worship',
    'መነቃቃት': 'revival',
    'ንሥሐ': 'repentance',
    'ጸሎት': 'prayer',
    'የክርስቲያን ኑሮ': 'christian',
    'ራስን ቀድሶ መስጠት': 'consecration',
    'ሥራ': 'work',
    'ሕዝብ': 'people',
    'ታማኝነት': 'trust',
    'ተስፋ': 'hope',
    'ደስታ': 'happiness',
    'ሰላም': 'peace',
    'ፍቅር': 'love',
    'መድህን': 'salvation',
    'መስቀል': 'cross',
    'ሰንበት': 'sabbath',
    'የእግዚአብሔር ቃል': 'god_word',
    'የክርስቲያን ተጋድሎ': 'warfare',
    'ፍርድ': 'judgment',
    'ዳግም ምፅአት': 'secondcoming',
    'የሰማይ ቤት': 'heavenly_home',
    'ወጣቶች': 'young_people',
    'ተፈጥሮ': 'nature',
    'የልጆች መዝሙር': 'children',
    'ጋብቻ': 'wedding', // Note: May need to map to existing image or use placeholder
    'ልደት': 'christmas',
    'መታመን': 'trust', // Reuse trust image
    'ቁርባን': 'consecration', // Reuse consecration image
    'ትንሣኤ': 'resurrection',
    'መሰናበቻ': 'farewell',
  };

  /// Get image provider for a category
  /// Returns AssetImage if found, otherwise returns placeholder icon
  static ImageProvider? getCategoryImage(String categoryName) {
    final imageName = _categoryImageMap[categoryName];
    if (imageName != null) {
      return AssetImage('assets/category/$imageName.webp');
    }
    return null;
  }

  /// Build category image widget with fallback
  /// Returns Image widget if image exists, otherwise returns Icon placeholder
  static Widget buildCategoryImage(String categoryName, {double size = 48}) {
    final imageProvider = getCategoryImage(categoryName);
    
    if (imageProvider != null) {
      return Image(
        image: imageProvider,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // If image fails to load, show placeholder icon
          return Icon(
            Icons.category,
            size: size,
            color: AppColors.accentGreen,
          );
        },
      );
    }
    
    // No image mapping found, use placeholder icon
    return Icon(
      Icons.category,
      size: size,
      color: AppColors.accentGreen,
    );
  }
}

