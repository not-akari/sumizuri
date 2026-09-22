// A simple Ok or Err result type used instead of exceptions across the app.
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) => switch (this) {
    Ok<T, E>(:final value) => ok(value),
    Err<T, E>(:final error) => err(error),
  };

  T? get valueOrNull => switch (this) {
    Ok<T, E>(:final value) => value,
    Err() => null,
  };

  E? get errorOrNull => switch (this) {
    Ok() => null,
    Err<T, E>(:final error) => error,
  };
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;
}
