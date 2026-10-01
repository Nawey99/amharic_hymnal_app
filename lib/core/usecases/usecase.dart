// lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:amharic_hymnal_app/core/error/failures.dart';

/// Base use case interface following Clean Architecture principles
///
/// All use cases should extend this class to ensure consistent error handling
/// using the Either pattern from dartz.
///
/// [T] The return type of the use case
/// [Params] The parameters required by the use case
abstract class UseCase<T, Params> {
  /// Execute the use case with the given parameters
  ///
  /// Returns Either with:
  /// - Left(Failure) if the operation fails
  /// - Right(T) if the operation succeeds
  Future<Either<Failure, T>> call(Params params);
}

/// Empty parameters class for use cases that don't require parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
