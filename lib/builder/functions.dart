import 'cell_builder.dart';
import '../parser/declarations.dart';

import 'cell_spec.dart';
import 'cell_table.dart';

/// Specification for a function defining a cell
class FunctionSpec extends CellSpec {
  /// Identifiers of the cells holding the function arguments
  final List<CellId> arguments;

  /// The function local scope
  final CellTable scope;
  
  const FunctionSpec({
    required super.id, 
    required super.definition,
    required this.arguments,
    required this.scope
  });
}

/// A deferred expression defining a function.
class DeferredFunctionDefinition extends DeferredExpression {
  /// The function's scope
  final CellTable scope;

  /// The parsed expression defining the function
  final Expression definition;

  DeferredFunctionDefinition({
    required this.scope,
    required this.definition
  });

  @override
  CellExpression build() {
    if (_builtDefinition == null) {
      final builder = CellBuilder(
        scope: scope
      );

      final valueCell = builder.buildDeclaration(definition);

      // TODO: Consider referencing the cell instead
      _builtDefinition = valueCell.definition;
    }

    return _builtDefinition!;
  }

  /// The built cell definition
  CellExpression? _builtDefinition;
}