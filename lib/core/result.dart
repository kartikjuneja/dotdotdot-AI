/// Discriminated success / failure wrapper without exceptions for control flow.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  Object? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final error) => error,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Object error, StackTrace? stackTrace) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error, :final stackTrace) => onFailure(error, stackTrace),
    };
  }

  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Success(transform(value)),
      Failure(:final error, :final stackTrace) =>
        Failure(error, stackTrace: stackTrace),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error, {this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;
}
