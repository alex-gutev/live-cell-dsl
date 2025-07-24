import '../builder/index.dart';
import 'builtins.dart';
import 'evaluator.dart';
import 'exceptions.dart';

/// Compiles [ValueSpec]s to [Evaluator] objects.
class RuntimeCompiler {
  /// Get the runtime cell identifier for a given cell [spec].
  ///
  /// Once an identifier is generated for a given [spec], future calls to this
  /// function will return the same identifier.
  RuntimeCellId idForCell(CellSpec spec) =>
      _cellIds.putIfAbsent(spec, () => RuntimeCellId(
        id: _idCounter++,
        label: spec.id
      ));

  /// Create an [Evaluator] for a given value [spec].
  Evaluator makeEvaluator(ValueSpec spec) => switch (spec) {
    // TODO: Proper exception type
    Stub() => throw UnimplementedError(),
    Variable() => throw UnimplementedError(),

    Constant(:final value) => Evaluator.constant(value),
    CellRef(get: final cell) => makeRef(cell),

    ApplySpec(
        :final operator,
        :final operands
    ) => Evaluator.apply(
        operator: makeEvaluator(operator),
        operands: operands.map(makeEvaluator).toList()
    ),

    DeferredSpec() => makeEvaluator(spec.build()),
    FunctionSpec() => makeFunctionEvaluator(spec),
  };

  /// Create an evaluator that references a cell
  Evaluator makeRef(CellSpec spec) {
    if (spec.isExternal()) {
      return refExternalCell(spec.id);
    }

    if (spec is ValueCellSpec || spec.foldable()) {
      return makeEvaluator(spec.definition);
    }

    return Evaluator.ref(idForCell(spec));
  }

  /// Create an evaluator for the function defined by [spec].
  ///
  /// **NOTE**: This method creates a deferred evaluator to prevent an
  /// infinite loop if there is a recursive call to the function.
  Evaluator makeFunctionEvaluator(FunctionSpec spec) =>
      _DeferredFunctionEvaluator(
          compiler: this,
          spec: spec
      );

  /// Create an evaluator that references an externally defined cell.
  Evaluator refExternalCell(CellId id) {
    final spec = Builtins.fns[id];

    if (spec == null) {
      throw MissingExternalCellError(id);
    }

    return spec.evaluator;
  }

  // Private

  /// Next cell identifier index
  var _idCounter = 0;

  /// Maps cell specifications to their runtime cell identifiers
  final _cellIds = <CellSpec, RuntimeCellId>{};

  /// Maps function specifications to their [Evaluators].
  final _functions = <FunctionSpec, Evaluator>{};
}

/// Creates an [Evaluator] for the definition of a function.
///
/// This class compiles the definition of a function in a new lexical environment
/// that is situated within the lexical environment of [parent]. All cells
/// local to the function are created in the new environment rather than in
/// [parent]. However, the runtime cell identifier counter is shared with
/// [parent].
class FunctionRuntimeCompiler extends RuntimeCompiler {
  /// The compiler for the environment in which the function is defined
  final RuntimeCompiler parent;

  /// The function specification
  final FunctionSpec functionSpec;

  FunctionRuntimeCompiler({
    required this.parent,
    required this.functionSpec
  });

  /// Create an [Evaluator] that returns a function.
  Evaluator makeFunction() {
    final argumentIds = <RuntimeCellId>[];

    for (final arg in functionSpec.arguments) {
      final cell = functionSpec.scope.get(arg);
      assert(cell.scope == functionSpec.scope);

      final id = idForCell(cell);
      _argumentCellIds[arg] = id;

      argumentIds.add(id);
    }

    final result = makeEvaluator(functionSpec.definition);

    return Evaluator.function(
        name: functionSpec.name,
        arguments: argumentIds,
        locals: _localCells,
        definition: result
    );
  }

  @override
  RuntimeCellId idForCell(CellSpec spec) =>
      parent.idForCell(spec);

  @override
  Evaluator makeRef(CellSpec spec) {
    if (spec.isArgument()) {
      final argId = idForCell(spec);
      _argumentCellIds[spec.id] = argId;

      return Evaluator.ref(argId);
    }
    else if (spec.scope == functionSpec.scope) {
      final id = idForCell(spec);

      _localCells.putIfAbsent(id, () => makeEvaluator(spec.definition));
      return Evaluator.ref(id);
    }

    return parent.makeRef(spec);
  }

  // Private

  /// Map from argument cell identifiers to their runtime cell identifiers
  final _argumentCellIds = <CellId, RuntimeCellId>{};

  /// Map holding the [Evaluator]s for local cells indexed by runtime identifier.
  final _localCells = <RuntimeCellId, Evaluator>{};
}

/// An [Evaluator] that builds a function when it is first called
class _DeferredFunctionEvaluator extends Evaluator {
  /// The compiler to use when building the function
  final RuntimeCompiler compiler;

  /// The function specification to build
  final FunctionSpec spec;

  _DeferredFunctionEvaluator({
    required this.compiler,
    required this.spec
  });

  @override
  eval(RuntimeContext context) => _build().eval(context);

  /// Build the function
  Evaluator _build() =>
      compiler._functions.putIfAbsent(spec, () {
        final compiler = FunctionRuntimeCompiler(
            parent: this.compiler,
            functionSpec: spec
        );

        return compiler.makeFunction();
      });
}