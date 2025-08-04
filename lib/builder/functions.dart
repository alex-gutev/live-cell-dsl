part of 'cell_builder.dart';

/// A [FunctionSpec] that is built only when the [definition] is referenced.
class DeferredFunctionSpec extends FunctionSpec {
  /// The module containing the function definition
  final ModuleSpec module;

  /// The raw expression making up the body of the function
  final AstNode expression;

  @override
  ValueSpec get definition => _buildDefinition();

  @override
  CellTable get scope {
    _buildDefinition();
    return super.scope;
  }

  DeferredFunctionSpec({
    required super.name,
    required super.arguments,
    required super.scope,
    required this.module,
    required this.expression
  });

  /// The spec defining the result of the function
  ValueSpec? _builtDefinition;

  ValueSpec _buildDefinition() {
    if (_builtDefinition == null) {
      final builder = CellBuilder(
          scope: super.scope,
          operatorTable: OperatorTable([]),

          // TODO: Consider adding aliases for all cells defined in [module]
          module: ModuleSpec(module.path,
              aliases: UnmodifiableMapView(module.aliases)
          )
      );

      final valueCell = builder.buildExpression(expression);

      _builtDefinition = _NamedCellRef(
          table: super.scope,
          id: valueCell.id
      );
    }

    return _builtDefinition!;
  }
}

/// Represents an externally defined function
class ExternalFunctionSpec extends FunctionSpec {
  @override
  ValueSpec get definition => const Stub();

  ExternalFunctionSpec({
    required super.name,
    required super.arguments,
    required super.scope
  });
}