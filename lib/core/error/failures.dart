import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
///
/// Following Clean Architecture, failures are represented as objects
/// rather than exceptions. This allows for better error handling and
/// type safety in use cases.
abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

/// Failure representing server/network related errors
class ServerFailure extends Failure {
  final String? message;

  const ServerFailure([this.message]);

  @override
  List<Object> get props => message != null ? [message!] : [];
}

/// Failure representing cache/database related errors
class CacheFailure extends Failure {
  final String? message;

  const CacheFailure([this.message]);

  @override
  List<Object> get props => message != null ? [message!] : [];
}

/// Failure representing network/connectivity related errors
class NetworkFailure extends Failure {
  final String? message;

  const NetworkFailure([this.message]);

  @override
  List<Object> get props => message != null ? [message!] : [];
}

/// Failure representing sync operation errors
class SyncFailure extends Failure {
  final String? message;

  const SyncFailure([this.message]);

  @override
  List<Object> get props => message != null ? [message!] : [];
}

/// The hymn asked for does not exist in the edition. Not an error in the
/// app or the network: the number is simply not in the book.
class NotFoundFailure extends Failure {
  final int? number;

  const NotFoundFailure([this.number]);

  @override
  List<Object> get props => number != null ? [number!] : [];
}

/// The edition has been withdrawn from the hymnal API, so it can no longer
/// be shown even from a stored copy.
class EditionUnavailableFailure extends Failure {
  const EditionUnavailableFailure();
}
