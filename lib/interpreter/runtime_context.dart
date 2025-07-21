part of 'evaluator.dart';

/// Identifies a cell at runtime.
///
/// Cells are identified by an integer [id], which must be unique per cell.
/// [label] is only used to map the runtime cell identifier to a source cell
/// identifier.
class RuntimeCellId {
  /// The integer identifier of the cell
  final int id;

  /// The identifier of the cell as specified in source.
  ///
  /// This is only used to map [id] to a source cell identifier for debugging
  /// purposes.
  final CellId? label;

  RuntimeCellId({
    required this.id,
    this.label
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RuntimeCellId &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Provides a context for referencing the values of cells
abstract class RuntimeContext {
  /// Reference the value of the cell identified by [id].
  dynamic refCell(RuntimeCellId id);
}

/// Context containing globally defined cells
class GlobalContext extends RuntimeContext {
  /// Maps cell identifiers to [ValueCell]s.
  final cells = <RuntimeCellId, ValueCell>{};

  @override
  refCell(RuntimeCellId id) => getCell(id).value;

  /// Check whether the context has a cell identified by [id].
  bool hasCell(RuntimeCellId id) => cells.containsKey(id);

  /// Get the cell identified by [id].
  ValueCell getCell(RuntimeCellId id) => cells[id]!;

  /// Add a cell to the context.
  ///
  /// If the context does not have a cell identified by [id], [makeCell] is
  /// called to create the [ValueCell] which is then added to the context. The
  /// newly added or existing cell is returned.
  ValueCell addCell(RuntimeCellId id, ValueCell Function() makeCell) =>
      cells.putIfAbsent(id, makeCell);
}

/// Context for referencing cells defined within a function
class FunctionContext extends RuntimeContext {
  /// The context in which the function is called.
  final RuntimeContext parent;

  /// Map of [Evaluator]s for ths function arguments
  final Map<RuntimeCellId, Evaluator> arguments;

  /// Map of [Evaluator]s for the cells local to the function.
  final Map<RuntimeCellId, Evaluator> locals;

  FunctionContext({
    required this.parent,
    required this.arguments,
    required this.locals
  });

  @override
  refCell(RuntimeCellId id) => _values.putIfAbsent(id, () {
    return arguments[id]?.eval(this) ??
        locals[id]?.eval(this) ??
        parent.refCell(id);
  });

  /// Map of cached cell values
  final _values = <RuntimeCellId, dynamic>{};
}