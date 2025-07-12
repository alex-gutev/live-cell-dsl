part of 'cell_builder.dart';

/// A deferred [ValueSpec] defining a function.
class DeferredFunctionDefinition extends DeferredSpec {
  /// List of argument cell identifiers
  final List<CellId> arguments;

  /// The function's scope
  final CellTable scope;

  /// The module containing the function definition
  final ModuleSpec module;

  /// The parsed expression defining the function
  final AstNode definition;

  DeferredFunctionDefinition({
    required this.arguments,
    required this.scope,
    required this.module,
    required this.definition
  });

  @override
  ValueSpec build() {
    if (_builtDefinition == null) {
      final builder = CellBuilder(
        scope: scope,

        // TODO: Consider adding aliases for all cells defined in [module]
        module: ModuleSpec(module.path,
          aliases: UnmodifiableMapView(module.aliases)
        )
      );

      final valueCell = builder.buildExpression(definition);
      builder.finalize();

      _builtDefinition = FunctionSpec(
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
  FunctionSpec? _builtDefinition;
}