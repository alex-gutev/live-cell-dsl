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

  /// The name of the Dart function to generate
  final String name;

  /// The function specification
  final FunctionSpec functionSpec;

  FunctionCompiler({
    required this.name,
    required this.parent,
    required this.functionSpec
  });

  /// Generate a [Method] that implements the function.
  Method makeMethod() {
    var i = 0;
    
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

  @override
  Expression compileRef(CellSpec spec) {
    if (spec.isArgument()) {
      return refer(cellVar(spec));
    }
    else if (spec.scope == functionSpec.scope) {
      final name = cellVar(spec);

      if (_builtCells.add(spec)) {
        final def = compile(spec.definition);
        _statements.add(_varDeclaration(name, def));
      }

      return refer(name);
    }
    
    return parent.compileRef(spec);
  }

  @override
  String compileFunction(FunctionSpec spec) {
    final added = functions.containsKey(spec);
    final name = super.compileFunction(spec);

    if (!added && functions.containsKey(spec)) {
      _statements.add(functions[spec]!.closure.code);
    }

    return name;
  }

  @override
  Map<CellSpec, int> get cellIds => parent.cellIds;

  @override
  Map<FunctionSpec, int> get functionIds => parent.functionIds;

  @override
  String cellVar(CellSpec spec) => spec.scope == functionSpec.scope
      ? 'cell${cellId(spec)}'
      : parent.cellVar(spec);

  @override
  String functionName(FunctionSpec spec) => spec.scope.parent == functionSpec.scope
      ? 'fn${functionId(spec)}'
      : parent.functionName(spec);

  // Private

  /// Set of cells for which a definition has been generated
  final _builtCells = <CellSpec>{};

  /// List of statements comprising the function body
  final _statements = <Code>[];

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