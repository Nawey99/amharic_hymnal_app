import 'package:flutter/foundation.dart';

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

typedef HymnOpenCallback = void Function(Hymn hymn);

/// The hymn a tab currently has open, and the last one the reader opened
/// anywhere.
///
/// The two are not the same thing. Closing a hymn with back ends the
/// first: its tab goes back to its list. The second outlives it, because
/// a reader who has just read 78 and turns to the index expects to find
/// themselves at 78 rather than at the beginning of the book.
class HymnTabSession extends ChangeNotifier {
  Hymn? _hymn;
  String? _sourceDestination;
  String? _version;

  Hymn? _lastOpened;
  String? _lastOpenedVersion;

  Hymn? get hymn => _hymn;
  String? get sourceDestination => _sourceDestination;
  String? get version => _version;

  /// The last hymn opened from any tab, whether or not it is still open.
  Hymn? get lastOpened => _lastOpened;

  /// The edition [lastOpened] belongs to; another book's numbering says
  /// nothing about this one.
  String? get lastOpenedVersion => _lastOpenedVersion;

  bool owns(String destination) {
    return _hymn != null && _sourceDestination == destination;
  }

  bool isCurrentFor(String destination, String version) {
    return owns(destination) && _version == version;
  }

  void open({
    required Hymn hymn,
    required String sourceDestination,
    required String version,
  }) {
    _hymn = hymn;
    _sourceDestination = sourceDestination;
    _version = version;
    _rememberLastOpened(hymn, version);
    notifyListeners();
  }

  void updateHymn(Hymn hymn) {
    if (_hymn == null || _hymn == hymn) return;
    _hymn = hymn;
    final version = _version;
    if (version != null) _rememberLastOpened(hymn, version);
    notifyListeners();
  }

  bool reconcileWith(Iterable<Hymn> hymns, String version) {
    // A hymn remembered from another book cannot be pointed at in this
    // one, and its number would mean something else.
    if (_lastOpenedVersion != null && _lastOpenedVersion != version) {
      _lastOpened = null;
      _lastOpenedVersion = null;
      notifyListeners();
    }

    final activeHymn = _hymn;
    if (activeHymn == null || _version != version) return false;

    Hymn? refreshedHymn;
    for (final hymn in hymns) {
      final matchesId = activeHymn.id != null && hymn.id == activeHymn.id;
      final matchesNumber = activeHymn.id == null &&
          hymn.id == null &&
          hymn.number == activeHymn.number;
      if (matchesId || matchesNumber) {
        refreshedHymn = hymn;
        break;
      }
    }

    if (refreshedHymn == null) {
      clear();
      return true;
    }
    if (refreshedHymn == activeHymn) return false;

    _hymn = refreshedHymn;
    _rememberLastOpened(refreshedHymn, version);
    notifyListeners();
    return true;
  }

  /// Ends the open hymn. What was last read is kept.
  void clear() {
    if (_hymn == null && _sourceDestination == null && _version == null) {
      return;
    }
    _hymn = null;
    _sourceDestination = null;
    _version = null;
    notifyListeners();
  }

  void _rememberLastOpened(Hymn hymn, String version) {
    _lastOpened = hymn;
    _lastOpenedVersion = version;
  }
}
