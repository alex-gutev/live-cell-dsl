import 'package:code_builder/code_builder.dart';

import '../../builder/index.dart';
import '../../interpreter/builtins.dart';
import '../../interpreter/exceptions.dart';

part 'function_compiler.dart';

/// Compiles [ValueSpec] to Dart [Expression]s.
class DartCompiler {
  /// Create an [Expression] that implements [spec].
  Expression compile(ValueSpec spec) => switch (spec) {
    // TODO: Proper exception type
    Stub() => throw UnimplementedError(),
    Variable() => throw UnimplementedError(),

    Constant(:final value) => literal(value),
    CellRef(get: final cell) => compileRef(cell),

    // TODO: Check to make sure operator is a function
    ApplySpec(
      :final operator,
      :final operands
    ) => compile(operator)
        .call([literalList(operands.map(_makeThunk))]),

    FunctionSpec() => refer(compileFunction(spec)),
  };

  /// Create an [Expression] that references the value of a cell
  Expression compileRef(CellSpec spec) {
    if (spec.isExternal()) {
      return refExternalCell(spec);
    }

    if (spec is ValueCellSpec || spec.foldable()) {
      return compile(spec.definition);
    }

    return refer(cellVar(spec)).property('value');
  }

  /// Compile the function specified by [spec].
  ///
  /// A [Method] that implements the function is generated and saved in
  /// [functions]. The [name] of the [Method] is returned.
  ///
  /// **NOTE**: Only one method is generated per [spec].
  String compileFunction(FunctionSpec spec) {
    if (!functionIds.containsKey(spec)) {
      final name = functionName(spec);

      if (!functions.containsKey(spec)) {
        final compiler = FunctionCompiler(
            name: name,
            parent: this,
            functionSpec: spec
        );

        functions[spec] = compiler.makeMethod();
      }

      return name;
    }

    return functionName(spec);
  }

  /// Get the integer identifier for a given cell [spec].
  ///
  /// Once an identifier is generated for a given [spec], future calls to this
  /// function will return the same identifier.
  int cellId(CellSpec spec) =>
      cellIds.putIfAbsent(spec, () => cellIds.length);

  /// Get the integer identifier for a given function [spec].
  ///
  /// Once an identifier is generated for a given [spec], future calls to this
  /// function will return the same identifier.
  int functionId(FunctionSpec spec) =>
      functionIds.putIfAbsent(spec, () => functionIds.length);

  /// Get the name of the variable holding the cell specified by [spec].
  String cellVar(CellSpec spec) =>
      '_cell${cellId(spec)}';

  /// Get the name of the function implementing the given function [spec].
  String functionName(FunctionSpec spec) =>
      '_fn${functionId(spec)}';


  /// External references

  /// Create an [Expression] that references an externally defined [cell].
  Expression refExternalCell(CellSpec cell) {
    final spec = Builtins.fns[cell.id];
    final fn = cell.definition;

    if (spec == null || fn is! FunctionSpec) {
      throw MissingExternalCellError(cell.id);
    }

    final name = functionName(fn);

    final argList = List.generate(spec.arity, (i) => refer('args')
        .index(literal(i)));

    functions.putIfAbsent(fn, () => Method((b) => b
        ..name = name
        ..requiredParameters.addAll([
          Parameter((b) => b..name = 'args')
        ])
        ..body = Block((b) {
          b.statements.add(
            refer(spec.functionName)
                .call(argList)
                .returned
                .statement
          );
        })
    ));

    return refer(name);
  }

  // For subclasses only

  /// Maps cell specifications to their integer identifiers
  final cellIds = <CellSpec, int>{};

  /// Maps function specifications to their integer identifiers
  final functionIds = <FunctionSpec, int>{};

  /// Map of [Method]s implementing [FunctionSpec]s.
  final functions = <FunctionSpec, Method>{};

  /// Create an expression that wraps the value specified by [spec] in a thunk.
  Expression _makeThunk(ValueSpec spec) {
    final fn = Method((b) => b..lambda = true
        ..body = compile(spec).code
    );

    return refer('Thunk')
        .call([fn.closure]);
  }
}