import 'cell_spec.dart';
import 'effect_spec.dart';
import 'modules.dart';

/// Table containing cells defined in a given module/scope
class CellTable {
  /// The parent scope in which this table is contained
  final CellTable? parent;

  /// Get all cells defined in this table
  Iterable<CellSpec> get cells => _cells.values;

  /// Get all effects defined in this table
  Iterable<EffectSpec> get effects => _effects.values;

  /// Is this the global scope?
  ///
  /// **NOTE**: A scope is global if [parent] is null.
  bool get isGlobal => parent == null;

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

  /// Lookup a side effect specification by identifier
  ///
  /// If the effect is not found in this table, the [parent] table is
  /// searched. If the effect is not found in the parent table (or its ancestor
  /// tables), [null] is returned.
  EffectSpec? lookupEffect(int id) =>
    _effects[id] ?? parent?.lookupEffect(id);

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

  /// Lookup a side effect specification by identifier
  ///
  /// If the effect is not found in this table, the [parent] table is
  /// searched. If the effect is not found in the parent table (or its ancestor
  /// tables), an exception is thrown.
  EffectSpec getEffect(int id) {
    /// TODO: Handle not found errors
    return lookupEffect(id)!;
  }

  /// Add/replace a cell specification to the table
  void add(CellSpec spec) {
    if (spec.id is! ValueCellId) {
      _cells[spec.id] = spec;
    }
  }

  /// Add a new effect to the table.
  ///
  /// The function [create], which is passed a generated effect ID, is called
  /// to create the effect.
  EffectSpec addEffect(EffectSpec Function(int) create) {
    final id = _effects.length;
    return _effects[id] = create(id);
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

  // Modules

  /// Get the spec of a module identified by [name].
  ///
  /// If there is no module identified by [name] or it has not been built
  /// yet, [null] is returned.
  ModuleSpec? getModuleSpec(String name) => _modules[name];

  /// Add a module [spec].
  void addModuleSpec(ModuleSpec spec) {
    if (spec.path != null) {
      _modules[spec.path!] = spec;
    }
  }
  
  // Private

  /// Map of cells indexed by cell specifications identifiers
  final _cells = <CellId, CellSpec>{};

  /// Map of effect specifications indexed by identifiers
  final _effects = <int, EffectSpec>{};

  /// Map storing attributes applying to cells
  final _meta = <(CellId, String), dynamic>{};

  /// Map from module names to module specs.
  final _modules = <String, ModuleSpec>{};
}

/// Exception indicating that a referenced cell was not found.
class CellNotFound implements Exception {
  /// ID that was referenced
  final CellId id;

  CellNotFound(this.id);
}