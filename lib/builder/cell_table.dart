import 'cell_spec.dart';

/// Table containing cells defined in a given module/scope
class CellTable {
  /// The parent scope in which this table is contained
  final CellTable? parent;

  /// Get all cells defined in this table
  Iterable<CellSpec> get cells => _cells.values;

  CellTable({
    this.parent
  });

  /// Lookup a cell specification by identifier
  ///
  /// If the cell is not found in this table, the [parent] table is
  /// searched. If the cell is not found in the parent table (or its ancestor
  /// tables), [null] is returned.
  CellSpec? lookup(CellId id) =>
      _cells[id] ?? parent?.lookup(id);

  /// Lookup a cell specification by identifier
  ///
  /// If the cell is not found in this table, the [parent] table is
  /// searched. If the cell is not found in the parent table (or its ancestor
  /// tables), a [CellNotFound] exception is thrown.
  CellSpec get(CellId id) {
    final spec = lookup(id);

    if (spec == null) {
      throw CellNotFound(id);
    }

    return spec;
  }

  /// Add/replace a cell specification to the table
  void add(CellSpec spec) {
    if (spec.id is! ValueCellId) {
      _cells[spec.id] = spec;
    }
  }

  /// Get the value of an [attribute] applying to the cell identified by [id]
  dynamic getAttribute(CellId id, String attribute) =>
      _meta[(id, attribute)];

  /// Set the value of an [attribute] applying to the cell identified by [id]
  void setAttribute({
    required CellId id,
    required String attribute,
    required value
  }) {
    _meta[(id, attribute)] = value;
  }

  // Private

  /// Map of cells indexed by cell specifications identifiers
  final _cells = <CellId, CellSpec>{};

  /// Map storing attributes applying to cells
  final _meta = <(CellId, String), dynamic>{};
}

/// Exception indicating that a referenced cell was not found.
class CellNotFound implements Exception {
  /// ID that was referenced
  final CellId id;

  CellNotFound(this.id);
}