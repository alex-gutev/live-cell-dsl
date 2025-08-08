part of 'dart_compiler.dart';

/// Compiles the body of a function.
///
/// This class compiles the definition of a function in a new lexical environment
/// that is situated within the lexical environment of [parent]. All cells
/// local to the function are created in the new environment rather than in
/// [parent]. However, the cell and function identifier map is shared with
/// [parent].
class FunctionCompiler extends DartCompiler {
  /// Name of the variable holding the function argument list
  static const argsVar = 'args';

  /// The compiler for the environment in which the function is defined
  final DartCompiler parent;

  /// The function specification
  final FunctionSpec functionSpec;

  FunctionCompiler({
    required this.parent,
    required this.functionSpec
  });

  /// Create a [FunctionGenerator] for this function
  FunctionGenerator makeGenerator() {
    final closure = _getClosure();

    if (closure.isNotEmpty) {
      return _makeClass(
          name: '_F${functionId(functionSpec)}',
          closure: closure
      );
    }
    else {
      final name = functionName(functionSpec);

      return GlobalFunction(
          name: name,
          build: () => _makeMethod(name)
      );
    }
  }

  @override
  Expression compileRef(CellSpec spec) {
    if (spec.scope == functionSpec.scope) {
      final name = cellVar(spec);

      if (!spec.isArgument()) {
        if (spec.foldable() && spec.definition is FunctionSpec) {
          return compile(spec.definition);
        }

        if (_builtCells.add(spec)) {
          final def = compile(spec.definition);
          _statements.add(_varDeclaration(name, def));
        }
      }

      return refer(name);
    }
    else if (_closureFields!.containsKey(spec)) {
      return refer(_closureFields![spec]!).call([]);
    }

    return parent.compileRef(spec);
  }

  @override
  Map<CellSpec, int> get cellIds => parent.cellIds;

  @override
  Map<FunctionSpec, int> get functionIds => parent.functionIds;

  @override
  Map<FunctionSpec, FunctionGenerator> get functions => parent.functions;

  @override
  String cellVar(CellSpec spec) => spec.scope == functionSpec.scope
      ? 'c${cellId(spec)}'
      : parent.cellVar(spec);

  // Private

  /// Set of cells for which a definition has been generated
  final _builtCells = <CellSpec>{};

  /// List of statements comprising the function body
  final _statements = <Code>[];

  /// Map of the expressions referencing the function's closure indexed by variable name.
  Map<String, Expression>? _closure;

  /// Map of the names of the fields holding the closure cell values
  Map<CellSpec, String>? _closureFields;

  /// Get the [Expression]s referencing the function's closure.
  ///
  /// The returned map contains [Expression]s that reference the values of the
  /// cells in the closure. These are used when calling the constructor of the
  /// generated class. The [Expression]s are indexed by the names of the fields
  /// through which the values of the cells in the closure can be referenced
  /// within the class's call method.
  ///
  /// The returned map does not include functions or global cells.
  Map<String, Expression> _getClosure() {
    if (_closure == null) {
      final closure = Set<CellSpec>.from(functionSpec.closure);
      final visited = <CellSpec>{};

      while (true) {
        closure.removeWhere((e) => e.isGlobal);
        final fns = closure.where((e) => e.definition is FunctionSpec).toList();

        if (fns.isEmpty) {
          break;
        }

        for (final cell in fns) {
          final fn = cell.definition as FunctionSpec;

          visited.add(cell);
          closure.remove(cell);

          closure.addAll(
              fn.closure.where((e) => !visited.contains(e))
          );
        }
      }

      _closure = Map.fromEntries(
          closure.map((e) => MapEntry(
              cellVar(e),
              makeThunk(parent.compileRef(e))
          ))
      );

      _closureFields = Map.fromEntries(
        closure.map((e) => MapEntry(e, cellVar(e)))
      );
    }

    return _closure!;
  }

  /// Create a function generator that generates a class using a given [closure].
  FunctionGenerator _makeClass({
    required String name,
    required Map<String, Expression> closure
  }) =>
      NestedFunction(
          name: name,
          closure: closure,
          build: () => Class((b) {
            b.name = name;
            b.constructors.add(_makeClassConstructor());
            b.methods.add(_makeMethod('call'));

            for (final field in _closure!.keys) {
              b.fields.add(
                  Field((b) => b
                    ..name = field
                    ..type = refer('dynamic')
                    ..modifier = FieldModifier.final$
                  )
              );
            }
          })
      );

  /// Generate the constructor of a class function.
  Constructor _makeClassConstructor() => Constructor((b) => b
    ..constant = true
    ..optionalParameters.addAll(
      _closure!.keys.map((name) => Parameter((b) => b
        ..name = name
        ..named = true
        ..required = true
        ..toThis = true
      ))
    )
  );

  /// Generate the [Method] implementing the actual function
  ///
  /// [name] is the name of the generated [Method].
  Method _makeMethod(String name) {
    var i = 0;

    _statements.add(
        DartCompiler.makeArityCheck(
          name: functionSpec.name,
          arity: functionSpec.arguments.length,
          argsVar: argsVar
        )
    );

    for (final arg in functionSpec.arguments) {
      final cell = functionSpec.scope.get(arg);
      assert(cell.scope == functionSpec.scope);

      final name = cellVar(cell);

      final def = refer(argsVar)
          .index(literal(i++))
          .call([]);

      _statements.add(_varDeclaration(name, def));
    }

    final result = compile(functionSpec.definition);

    return Method((b) => b
      ..name = name
      ..requiredParameters.addAll([
        Parameter((b) => b..name = argsVar)
      ])
      ..body = _makeBody(result)
    );
  }

  /// Generate the [Block] forming the body of the function.
  Block _makeBody(Expression result) => Block((b) => b
    ..statements.addAll(_statements)
    ..statements.add(result.returned.statement)
  );

  /// Generate a local variable statement.
  Code _varDeclaration(String name, Expression expression) =>
      declareFinal(name, late: true)
          .assign(expression)
          .statement;
}