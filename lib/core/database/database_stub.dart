// lib/core/database/database_stub.dart
// Stub file for platforms that don't match native or web
import 'package:drift/drift.dart';

LazyDatabase openConnection() {
  throw UnsupportedError('Platform not supported');
}
