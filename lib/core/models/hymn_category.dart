// lib/core/models/hymn_category.dart

/// Model representing a hymn category with its hymn number range
///
/// Each category contains:
/// - Unique identifier
/// - Amharic name
/// - Start and end hymn numbers (inclusive)
///
/// Used for programmatic category assignment and validation
class HymnCategory {
  final String id;
  final String nameAmharic;
  final int startNumber;
  final int endNumber;

  const HymnCategory({
    required this.id,
    required this.nameAmharic,
    required this.startNumber,
    required this.endNumber,
  })  : assert(startNumber > 0, 'Start number must be positive'),
        assert(endNumber >= startNumber, 'End number must be >= start number');

  /// Get list of all hymn numbers in this category
  List<int> get hymnNumbers {
    return List.generate(
      endNumber - startNumber + 1,
      (i) => startNumber + i,
    );
  }

  /// Check if a hymn number belongs to this category
  bool contains(int hymnNumber) {
    return hymnNumber >= startNumber && hymnNumber <= endNumber;
  }

  /// Get the total number of hymns in this category
  int get count => endNumber - startNumber + 1;

  @override
  String toString() => '$nameAmharic ($startNumber-$endNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HymnCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nameAmharic == other.nameAmharic &&
          startNumber == other.startNumber &&
          endNumber == other.endNumber;

  @override
  int get hashCode =>
      id.hashCode ^
      nameAmharic.hashCode ^
      startNumber.hashCode ^
      endNumber.hashCode;
}
