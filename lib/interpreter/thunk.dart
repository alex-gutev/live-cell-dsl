/// Container for a lazily evaluated value.
///
/// This containers manages the computation of a value. The contained value
/// is retrieved using [call]. The value is only computed the first time the
/// [call] method is called. Subsequents calls, return the cached computed
/// value.
class Thunk<T> {
  /// Function that computes the value
  final T Function() compute;

  Thunk(this.compute);

  /// Get the contained value.
  ///
  /// When this method is called for the first time, [compute] is called to
  /// compute the value, which is then cached and returned. On subsequent calls,
  /// the cached value is returned.
  T call() {
    if (!_hasValue) {
      _value = compute();
      _hasValue = true;
    }

    return _value;
  }

  /// Get the contained value while ensuring it is of type [U].
  ///
  /// If the contained value is not of type [U], a [TypeError] exception is
  /// thrown.
  U get<U>() => switch (call()) {
    final U value => value,
    _ => throw TypeError()
  };

  /// The computed value
  late T _value;

  /// Has the value been computed?
  var _hasValue = false;
}
