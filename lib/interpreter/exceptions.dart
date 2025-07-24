import 'package:live_cell/builder/cell_spec.dart';

/// Thrown when attempting to call something which is not a function
class InvalidOperatorError extends TypeError {
  /// The thing being called
  final dynamic thing;

  InvalidOperatorError(this.thing);

  @override
  String toString() =>
      'Expression operator (${thing.runtimeType}) is not a function.';
}

/// Thrown when a function is called with an incorrect number of arguments
class ArityError extends Error {
  /// The name of the function
  final CellId name;

  /// Expected number of arguments
  final int expected;

  /// Number of arguments given
  final int got;

  ArityError({
    required this.name,
    required this.expected,
    required this.got
  });

  @override
  String toString() => '$name expected $expected arguments '
      'but was given $got.';
}