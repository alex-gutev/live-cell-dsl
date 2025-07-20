import 'package:live_cells_core/live_cells_core.dart';

import '../builder/index.dart';
import 'builtins.dart';
import 'evaluator.dart';
import 'thunk.dart';

/// Signature of function defined by a cell.
///
/// [arguments] is a list of [Thunks]s holding values of the function arguments.
typedef CellFunc = Function(List<Thunk> arguments);

/// Signature of the make cell reference function.
///
/// This function should return an [Evaluator] that references the value of the
/// given [cell].
typedef MakeRef = Evaluator Function(CellSpec cell);

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
  ValueCell get(CellId id) => _context.getCell(id);
  
  /// Get the [MutableCell] identified by [id].
  /// 
  /// An exception is thrown if [id] does not identify a variable cell.
  MutableCell getVar(CellId id) => _mutable[id]!;

  // Private

  /// The global cell context
  final _context = GlobalContext();

  /// Maps identifiers to [MutableCell] objects.
  final _mutable = <CellId, MutableCell>{};

  /// Maps function specifications to actual [Evaluator]s that return the functions.
  final _functions = <FunctionSpec, Evaluator>{};
  
  /// Function for creating a reference to a cell.
  /// 
  /// If this is not null, it is called to create a reference to a cell.
  MakeRef? _ref;
  
  /// Build a [ValueCell] for a given [spec].
  ///
  /// This does not create a [ValueCell] for specs representing foldable or
  /// external cells.
  void _compileCell(CellSpec spec) {
    if (spec is! ValueCellSpec && !spec.foldable() && !spec.isExternal()) {
      _makeCell(spec.id, spec.definition);
    }
  }

  /// Build a [ValueCell] for the cell identified by [id] and defined by [definition].
  ValueCell _makeCell(CellId id, ValueSpec definition) => _context.addCell(id, () {
    switch (definition) {
      case Stub():
        // TODO: Proper exception type
        throw UnimplementedError();

      case Constant(:final value):
        return ValueCell.value(value);

      case Variable():
        return _mutable[id] = MutableCell(null);

      case DeferredSpec():
        return _makeCell(id, definition.build());

      default:
        final visitor = _ArgumentCellVisitor(this);
        definition.accept(visitor);

        final evaluator = _makeEvaluator(definition);

        return ComputeCell(
          arguments: visitor.arguments,
          compute: () => evaluator.eval(_context),
        ).store();
    }
  });

  /// Create an [Evaluator] for the computation represented by [spec].
  Evaluator _makeEvaluator(ValueSpec spec) => switch (spec) {
    // TODO: Proper exception type
    Stub() => throw UnimplementedError(),
    Variable() => throw UnimplementedError(),

    Constant(:final value) => Evaluator.constant(value),
    CellRef(get: final cell) => _makeRef(cell),

    ApplySpec(
        :final operator,
        :final operands
    ) => Evaluator.apply(
        operator: _makeEvaluator(operator),
        operands: operands.map(_makeEvaluator).toList()
    ),

    DeferredSpec() => _makeEvaluator(spec.build()),
    FunctionSpec() => _makeFunctionEvaluator(spec),
  };

  /// Create an [Evaluator] that returns the value of the cell represented by [spec].
  ///
  /// If [_ref] is not null it is called, otherwise an evaluator that references
  /// the value of the cell is returned.
  Evaluator _makeRef(CellSpec spec) {
    if (spec.isExternal()) {
      return Evaluator.constant(_externalFunc(spec.id));
    }

    if (_ref != null) {
      return _ref!(spec);
    }

    return _cellValue(spec);
  }

  /// Create an [Evaluator] that references the value of the cell represented by [spec].
  Evaluator _cellValue(CellSpec spec) {
    if (spec is ValueCellSpec || spec.foldable()) {
      return _makeEvaluator(spec.definition);
    }

    return Evaluator.ref(spec.id);
  }

  /// Create an [Evaluator] that returns the function represented by [spec].
  ///
  /// This method caches the [Evaluator] for a given in [_functions]. Subsequent
  /// calls to this method, simply return the cached evaluator, rather than
  /// creating a new evaluator.
  Evaluator _makeFunctionEvaluator(FunctionSpec spec) => _functions.putIfAbsent(spec, () {
    Evaluator makeRef(CellSpec cell) {
      if (spec.referencedCells.contains(cell) || cell.isArgument()) {
        return Evaluator.ref(cell.id);
      }

      // TODO: Add memoization
      return _makeEvaluator(cell.definition);
    }

    final result =
      _withMakeRef(makeRef, () => _makeEvaluator(spec.definition));

    final external = Map.fromEntries(spec.referencedCells.map((spec) => MapEntry(
      spec.id,
      _makeRef(spec)
    )));

    return Evaluator.function(
        name: spec.name,
        arguments: spec.arguments,
        external: external,
        definition: result
    );
  });

  /// Call [fn] with [_ref] set to [ref].
  T _withMakeRef<T>(MakeRef ref, T Function() fn) {
    final prev = _ref;

    try {
      _ref = ref;
      return fn();
    }
    finally {
      _ref = prev;
    }
  }

  /// Retrieve the external function identified by [name].
  CellFunc? _externalFunc(CellId name) {
    final spec = Builtins.fns[name];

    if (spec == null) {
      throw ArgumentError('Undefined external cell $name.');
    }

    return (List<Thunk> args) {
      checkArity(
          name: name,
          arity: spec.arity,
          arguments: args
      );

      return Function.apply(spec.fn, args);
    };
  }
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
          interpreter._makeCell(
              cell.id, 
              cell.definition
          )
      );
    }
  }
}