import 'exceptions.dart';
import '../builder/index.dart';

/// Check that the correct number of arguments were given to a function.
///
/// If [arguments] contains fewer or more elements than [arity], an exception is
/// thrown, with [name] used to refer to the cell, defining the function, in
/// the error message.
void checkArity({
  required CellId name,
  required int arity,
  required List arguments
}) {
  if (arguments.length != arity) {
    throw ArityError(
        name: name,
        expected: arity,
        got: arguments.length
    );
  }
}
