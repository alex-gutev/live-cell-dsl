part of 'evaluator.dart';

/// Provides a context for referencing the values of cells
abstract class RuntimeContext {
  /// Reference the value of the cell identified by [id].
  dynamic refCell(CellId id);
}

/// Context containing globally defined cells
class GlobalContext extends RuntimeContext {
  /// Map from cell identifiers to the corresponding [ValueCell]s.
  final cells = <CellId, ValueCell>{};

  @override
  refCell(CellId id) => getCell(id).value;

  /// Check whether the context has a cell identified by [id].
  bool hasCell(CellId id) => cells.containsKey(id);

  /// Get the cell identified by [id].
  ValueCell getCell(CellId id) => cells[id]!;

  /// Add a cell to the context.
  ///
  /// If the context does not have a cell identified by [id], [makeCell] is
  /// called to create the [ValueCell] which is then added to the context. The
  /// newly added or existing cell is returned.
  ValueCell addCell(CellId id, ValueCell Function() makeCell) =>
      cells.putIfAbsent(id, makeCell);
}

/// Context for referencing cells defined within a function
class FunctionContext extends RuntimeContext {
  /// The context in which the function is defined.
  final RuntimeContext parent;

  /// Map of [Thunk]s for the function's argument cells.
  final Map<CellId, Thunk> arguments;

  /// Map of [Thunk]s for the cells referenced by the function.
  final Map<CellId, Thunk> closure;

  /// Map of [Evaluator] for cells local to the function.
  final Map<CellId, Evaluator> locals;

  FunctionContext({
    required this.parent,
    required this.arguments,
    required this.closure,
    required this.locals
  });

  @override
  refCell(CellId id) => _values.putIfAbsent(id, () {
    final local = locals[id];

    if (local != null) {
      return local.eval(this);
    }

    final arg = arguments[id] ?? closure[id];

    return arg != null
        ? arg()
        : parent.refCell(id);
  });

  /// Map of cached cell values
  final _values = <CellId, dynamic>{};
}