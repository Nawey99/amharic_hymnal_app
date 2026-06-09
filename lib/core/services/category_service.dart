// lib/core/services/category_service.dart
import 'package:amharic_hymnal_app/core/models/hymn_category.dart';
import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Service for managing hymn categories
/// 
/// Provides programmatic access to the 31-category system.
/// Validates category assignments and provides category queries.
class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal() {
    _validateCategories();
  }

  /// Validate categories on initialization
  void _validateCategories() {
    final errors = HymnCategories.validate();
    if (errors.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('❌ Category validation errors:');
        for (final error in errors) {
          debugPrint('   - $error');
        }
      }
      throw Exception('Category validation failed: ${errors.join(", ")}');
    }
    
    if (kDebugMode) {
      debugPrint('✅ All 31 categories validated successfully');
      debugPrint('   Total hymns covered: ${HymnCategories.getAllCoveredNumbers().length}');
    }
  }

  /// Get category for a specific hymn number
  HymnCategory? getCategoryByNumber(int hymnNumber) {
    return HymnCategories.getCategoryByNumber(hymnNumber);
  }

  /// Get category by ID
  HymnCategory? getCategoryById(String id) {
    return HymnCategories.getCategoryById(id);
  }

  /// Get category by Amharic name
  HymnCategory? getCategoryByName(String nameAmharic) {
    return HymnCategories.getCategoryByName(nameAmharic);
  }

  /// Get all categories
  List<HymnCategory> getAllCategories() {
    return List.from(HymnCategories.all);
  }

  /// Get all hymn numbers in a category
  List<int> getHymnNumbersInCategory(String categoryId) {
    final category = getCategoryById(categoryId);
    return category?.hymnNumbers ?? [];
  }

  /// Get category name for a hymn number
  String? getCategoryName(int hymnNumber) {
    final category = getCategoryByNumber(hymnNumber);
    return category?.nameAmharic;
  }

  /// Check if a hymn number belongs to a specific category
  bool hymnBelongsToCategory(int hymnNumber, String categoryId) {
    final category = getCategoryById(categoryId);
    return category?.contains(hymnNumber) ?? false;
  }

  /// Get all hymn numbers covered by the category system
  Set<int> getAllCoveredNumbers() {
    return HymnCategories.getAllCoveredNumbers();
  }
}






