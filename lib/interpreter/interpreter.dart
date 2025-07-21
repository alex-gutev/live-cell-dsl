import 'package:live_cells_core/live_cells_core.dart';

import '../builder/index.dart';
import 'evaluator.dart';
import 'runtime_compiler.dart';

/// Builds [ValueCell]s from source code loaded at run time.
/// 
/// This class provides functionality for building [ValueCell] objects, that
/// can be observed from watch functions and widgets.
class Interpreter {
  /// The scope containing the cells to build
  final CellTable scope;

  Interpreter(this.scope);

  /// Build [ValueCell]s from the specifications in [scope].
  void compile() {
    for (final spec in scope.cells) {
      _compileCell(spec);
    }
  }

  /// Get the [ValueCell] identified by [id].
  /// 
  /// **NOTE**: [ValueCell]s are not generated for foldable cells. An exception
  /// is thrown if [id] identifies a foldable cell or does not identify any
  /// cell.
  ValueCell get(CellId id) => _cells[id]!;
  
  /// Get the [MutableCell] identified by [id].
  /// 
  /// An exception is thrown if [id] does not identify a variable cell.
  MutableCell getVar(CellId id) => _mutable[id]!;

  // Private

  /// The cell definition compiler
  final _compiler = RuntimeCompiler();

  /// The global cell context
  final _context = GlobalContext();

  /// Map of [ValueCell]s objects indexed by [CellId]s.
  final _cells = <CellId, ValueCell>{};

  /// Map of [MutableCell] objects indexed by [CellId]s.
  final _mutable = <CellId, MutableCell>{};

  /// Build a [ValueCell] for a given [spec].
  ///
  /// This does not create a [ValueCell] for specs representing foldable or
  /// external cells.
  void _compileCell(CellSpec spec) {
    if (spec is! ValueCellSpec && !spec.foldable() && !spec.isExternal()) {
      _cells[spec.id] = _makeCell(spec);
    }
  }

  /// Build a [ValueCell] for a given [spec].
  ValueCell _makeCell(CellSpec spec) =>
      _context.addCell(_compiler.idForCell(spec), () {
        switch (spec.definition) {
          case Stub():
            // TODO: Proper exception type
            throw UnimplementedError();

          case Constant(:final value):
            return ValueCell.value(value);

          case Variable():
            return _mutable[spec.id] = MutableCell(null);

          case DeferredSpec():
            return _makeCell(spec);

          default:
            final visitor = _ArgumentCellVisitor(this);
            spec.definition.accept(visitor);

            final evaluator = _compiler.makeEvaluator(spec.definition);

            return ComputeCell(
              arguments: visitor.arguments,
              compute: () => evaluator.eval(_context),
            ).store();
        }
      });
}

/// Determines the set of [arguments] reference by a given [ValueSpec].
class _ArgumentCellVisitor extends ValueSpecTreeVisitor {
  final Interpreter interpreter;

  /// Set of arguments referenced by the visited [ValueSpec].
  final arguments = <ValueCell>{};

  _ArgumentCellVisitor(this.interpreter);

  @override
  void visitRef(CellRef spec) {
    _addArgument(spec.get);
  }

  @override
  void visitFunction(FunctionSpec spec) {
    spec.referencedCells.forEach(_addArgument);
  }

  /// Add [cell] to the [arguments] set.
  void _addArgument(CellSpec cell) {
    if (cell is ValueCellSpec || cell.foldable()) {
      cell.definition.accept(this);
    }
    else {
      arguments.add(
          interpreter._makeCell(cell)
      );
    }
  }
}