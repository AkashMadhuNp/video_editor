import 'package:equatable/equatable.dart';

abstract class Either<L, R> extends Equatable {
  const Either();

  T fold<T>(T Function(L left) fnL, T Function(R right) fnR);

  @override
  List<Object?> get props => [];
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnL(value);

  @override
  List<Object?> get props => [value];
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L left) fnL, T Function(R right) fnR) => fnR(value);

  @override
  List<Object?> get props => [value];
}

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class PickVideoFailure extends Failure {
  const PickVideoFailure(super.message);
}

class ExportVideoFailure extends Failure {
  const ExportVideoFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
