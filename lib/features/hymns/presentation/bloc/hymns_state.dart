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

  /// Changes on every favourite toggle. Favourites are kept in settings, not
  /// on the hymns, so without it removing one could emit a state equal to the
  /// last and pages listing favourites would not rebuild.
  final int favoritesRevision;

  HymnsLoaded(
    List<Hymn> hymns,
    this.sortType, {
    this.languageCode = 'am',
    this.version = 'sda_new',
    this.favoritesRevision = 0,
  }) : hymns = _sortHymns(List.from(hymns), sortType);

  static List<Hymn> _sortHymns(List<Hymn> hymns, String sortType) {
    // Step 4: Verify Data Mapping - Ensure sorting doesn't filter out hymns
    if (hymns.isEmpty) {
      return hymns;
    }

    if (sortType == 'search') {
      return hymns;
    } else if (sortType == 'number') {
      hymns.sort((a, b) => a.displayNumber.compareTo(b.displayNumber));
    } else if (sortType == 'name') {
      // Code-point order is Fidel order for the base letters, which is what
      // the index groups by. (This used to set Intl.defaultLocale here, which
      // String.compareTo ignores and which changed formatting app-wide.)

      // Step 4: Verify sorting doesn't remove hymns
      final originalCount = hymns.length;

      hymns.sort((a, b) {
        final aTitle = a.displayTitle.trim();
        final bTitle = b.displayTitle.trim();

        // Empty titles go to the end
        if (aTitle.isEmpty && bTitle.isEmpty) return 0;
        if (aTitle.isEmpty) return 1;
        if (bTitle.isEmpty) return -1;

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
  List<Object> get props =>
      [hymns, sortType, languageCode, version, favoritesRevision];
}

/// Why hymns could not be shown. Screens word it in the reader's language
/// (`hymnsErrorText`); the bloc only says which case it is.
enum HymnsErrorKind {
  /// The edition could not be read, from the network or the device.
  loadFailed,

  /// The edition has never been downloaded and there is no connection.
  needsConnection,

  /// The edition has been withdrawn from the hymnal API.
  editionUnavailable,

  /// A search could not be completed.
  searchFailed,

  /// The edition has no hymn with this number.
  notFound,

  /// Looking up a hymn by number failed for another reason.
  lookupFailed,
}

class HymnsError extends HymnsState {
  final HymnsErrorKind kind;

  /// The hymn number, for [HymnsErrorKind.notFound] and
  /// [HymnsErrorKind.lookupFailed].
  final int? number;

  HymnsError(this.kind, {this.number});

  /// English, for logs and tests only. What the reader sees comes from
  /// `hymnsErrorText`.
  String get message => switch (kind) {
        HymnsErrorKind.loadFailed =>
          'Hymns could not be loaded. Please try again.',
        HymnsErrorKind.needsConnection =>
          'This hymnal needs an internet connection to load. '
              'Please connect and try again.',
        HymnsErrorKind.editionUnavailable =>
          'This hymnal is no longer available.',
        HymnsErrorKind.searchFailed => 'Failed to search hymns.',
        HymnsErrorKind.notFound => 'Hymn #$number not found.',
        HymnsErrorKind.lookupFailed => 'Hymn #$number could not be opened.',
      };

  @override
  List<Object> get props => [kind, number ?? 0];
}
