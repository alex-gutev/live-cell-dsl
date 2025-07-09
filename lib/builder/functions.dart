part of 'cell_builder.dart';

/// A deferred [ValueSpec] defining a function.
class DeferredFunctionDefinition extends DeferredSpec {
  /// List of argument cell identifiers
  final List<CellId> arguments;

  /// The function's scope
  final CellTable scope;

  /// The parsed expression defining the function
  final AstNode definition;

  DeferredFunctionDefinition({
    required this.arguments,
    required this.scope,
    required this.definition
  });

  @override
  ValueSpec build() {
    if (_builtDefinition == null) {
      final builder = CellBuilder(
        scope: scope
      );

      final valueCell = builder.buildExpression(definition);
      builder.finalize();

      _builtDefinition = FunctionExpression(
          arguments: arguments,
          scope: scope,
          definition: _NamedCellRef(
              table: scope,
              id: valueCell.id
          )
      );
    }

    return _builtDefinition!;
  }

  /// The built cell definition
  FunctionExpression? _builtDefinition;
}