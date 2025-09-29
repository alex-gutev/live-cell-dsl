import 'package:live_cells_core/live_cells_internals.dart';

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

/// Schedule [fn] to be called after the current cell update cycle.
///
/// If this function is called outside of a cell update cycle, [fn] is called
/// immediately.
void runPostUpdate(void Function() fn) {
  if (CellUpdateManager.isUpdating) {
    CellUpdateManager.addPostUpdateCallback(fn);
  }
  else {
    fn();
  }
}