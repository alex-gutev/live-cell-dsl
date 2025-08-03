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
      
      _localCells[name] = refer(argsVar)
          .index(literal(i++))
          .call([]);
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
      
      _localCells.putIfAbsent(name, () => compile(spec.definition));
      return refer(name);
    }
    
    return parent.compileRef(spec);
  }

  @override
  String compileFunction(FunctionSpec spec) {
    if (spec.scope == functionSpec.scope) {
      return super.compileFunction(spec);
    }

    return parent.compileFunction(spec);
  }

  @override
  Map<CellSpec, int> get cellIds => parent.cellIds;

  @override
  Map<FunctionSpec, int> get functionIds => parent.functionIds;

  @override
  Map<FunctionSpec, Method> get functions => parent.functions;

  // Private

  /// Map of cells local to the function indexed by variable name
  final _localCells = <String, Expression>{};

  /// Generate the [Block] forming the body of the function.
  Block _makeBody(Expression result) => Block((b) {
    // TODO: Add Arity Check

    for (final entry in functions.entries) {
      if (entry.key.scope == functionSpec.scope) {
        b.statements.add(entry.value.closure.statement);
      }
    }

    for (final entry in _localCells.entries) {
      b.statements.add(
          declareFinal(entry.key, late: true)
              .assign(entry.value).statement
      );
    }

    b.statements.add(result.returned.statement);
  });
}