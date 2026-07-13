import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

typedef HymnOpenCallback = void Function(Hymn hymn);

class HymnTabSession {
  Hymn? _hymn;
  String? _sourceDestination;
  String? _version;

  Hymn? get hymn => _hymn;
  String? get sourceDestination => _sourceDestination;
  String? get version => _version;

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
  }

  void updateHymn(Hymn hymn) {
    if (_hymn == null) return;
    _hymn = hymn;
  }

  void clear() {
    _hymn = null;
    _sourceDestination = null;
    _version = null;
  }
}
