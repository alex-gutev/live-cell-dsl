part of 'cell_builder.dart';

/// A deferred expression defining a function.
class DeferredFunctionDefinition extends DeferredExpression {
  /// List of argument cell identifiers
  final List<CellId> arguments;

  /// The function's scope
  final CellTable scope;

  /// The parsed expression defining the function
  final Expression definition;

  DeferredFunctionDefinition({
    required this.arguments,
    required this.scope,
    required this.definition
  });

  @override
  CellExpression build() {
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