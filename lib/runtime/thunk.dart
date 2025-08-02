/// Interface for retrieving the value of an argument.
abstract interface class Argument {
  /// Retrieve the value of the argument and check its type.
  ///
  /// The value of the argument is computed if necessary and checked that it
  /// is of type [U]. If it is not of type [U] a [TypeError] is thrown.
  U get<U>();
}

/// A lazily computed argument.
///
/// The value of the argument is only computed once, by [compute], when it is
/// is referenced.
class Thunk<T> implements Argument {
  /// Value computation function
  final T Function() compute;

  Thunk(this.compute);

  /// Retrieve the value of the argument.
  ///
  /// When this method is called for the first time, [compute] is called to
  /// compute the value of the argument. The value returned by [compute] is
  /// saved so that future calls to this method return the saved value.
  T call() {
    if (!_computed) {
      _value = compute();
      _computed = true;
    }

    return _value;
  }

  @override
  U get<U>() => switch (call()) {
    final U value => value,
    // TODO: Exception type with more details
    _ => throw TypeError()
  };

  // Private

  /// Has the value been computed?
  var _computed = false;

  /// The computed value
  late T _value;
}