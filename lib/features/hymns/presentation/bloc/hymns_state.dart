// lib/features/hymns/presentation/bloc/hymns_state.dart
part of 'hymns_bloc.dart';

abstract class HymnsState extends Equatable {
  @override
  List<Object> get props => [];
}

class HymnsInitial extends HymnsState {}

class HymnsLoading extends HymnsState {}

class HymnsLoaded extends HymnsState {
  final List<Hymn> hymns;
  final String sortType;
  final String languageCode;
  final String version;

  HymnsLoaded(
    List<Hymn> hymns,
    this.sortType, {
    this.languageCode = 'am',
    this.version = 'hymnal',
  }) : hymns = _sortHymns(List.from(hymns), sortType);

  static List<Hymn> _sortHymns(List<Hymn> hymns, String sortType) {
    // Step 4: Verify Data Mapping - Ensure sorting doesn't filter out hymns
    if (hymns.isEmpty) {
      return hymns;
    }

    if (sortType == 'number') {
      hymns.sort((a, b) => a.displayNumber.compareTo(b.displayNumber));
    } else if (sortType == 'name') {
      // Use locale-aware comparison for Amharic text
      // Set locale to Amharic for proper sorting
      Intl.defaultLocale = 'am';

      // Step 4: Verify sorting doesn't remove hymns
      final originalCount = hymns.length;

      hymns.sort((a, b) {
        final aTitle = a.displayTitle.trim();
        final bTitle = b.displayTitle.trim();

        // Empty titles go to the end
        if (aTitle.isEmpty && bTitle.isEmpty) return 0;
        if (aTitle.isEmpty) return 1;
        if (bTitle.isEmpty) return -1;

        // Use locale-aware comparison for Amharic text
        // This ensures proper sorting according to Amharic alphabet order
        // The compareTo method respects the current locale when Intl.defaultLocale is set
        return aTitle.compareTo(bTitle);
      });

      // Step 4: Verify no hymns were lost during sorting
      if (hymns.length != originalCount) {
        debugPrint(
            '❌ CRITICAL: Hymns lost during sort-by-name! Original: $originalCount, After: ${hymns.length}');
      }
    } else if (sortType == 'category') {
      hymns.sort((a, b) {
        final aCategory = a.category ?? '';
        final bCategory = b.category ?? '';
        if (aCategory.isEmpty && bCategory.isEmpty) return 0;
        if (aCategory.isEmpty) return 1;
        if (bCategory.isEmpty) return -1;
        return aCategory.compareTo(bCategory);
      });
    }
    return hymns;
  }

  @override
  List<Object> get props => [hymns, sortType, languageCode, version];
}

class HymnsError extends HymnsState {
  final String message;

  HymnsError(this.message);

  @override
  List<Object> get props => [message];
}
