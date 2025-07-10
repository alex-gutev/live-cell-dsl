import '../builder/cell_table.dart';

/// Interface for an operation in the compilation pipeline
abstract interface class Operation {
  /// Run the operation on the given [scope].
  ///
  /// After this method is called, the [Operation] object will
  /// no longer be used.
  void run(CellTable scope);
}

/// A compilation pipeline consisting of multiple [operations].
class Pipeline {
  /// List of operations to run
  final operations = <Operation>[];

  /// Add an [operation] to the pipeline.
  Pipeline add(Operation operation) {
    operations.add(operation);
    return this;
  }

  /// Run all operations in the pipeline on a given [scope].
  void run(CellTable scope) {
    for (final operation in operations) {
      operation.run(scope);
    }
  }
}