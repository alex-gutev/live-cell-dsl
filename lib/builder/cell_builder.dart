import 'functions.dart';
import 'cell_spec.dart';
import 'cell_table.dart';
import '../parser/index.dart';

/// Builds cell specifications from parsed cell [Expression]s
class CellBuilder {
  /// The table holding all cells defined in the global scope
  final CellTable globalTable;

  CellBuilder({
    CellTable? scope
  }) : globalTable = scope ?? CellTable();

  /// Build the cell specifications from the given [declarations].
  Future<void> build(Stream<Expression> declarations) async {
    await for (final declaration in declarations) {
      buildDeclaration(declaration);
    }
  }

  /// Build a cell specification from a single [expression]
  CellSpec buildDeclaration(Expression expression) {
    final spec = _buildCell(expression);
    globalTable.add(spec);

    return spec;
  }

  // Private

  /// Build a cell from a given [declaration].
  CellSpec _buildCell(Expression declaration) {
    switch (declaration) {
      case NamedCell(:final name):
        return CellSpec(
            id: NamedCellId(name),
            definition: const StubExpression()
        );

      case Constant():
        return declaration.accept(_ConstantCellVisitor());

      // TODO: Match proper definition operator
      case Operation(
        operator: NamedCell(name: '='),
        :final args
      ):
        return _buildDefinition(args);

      case Operation(:final operator, :final args):
        return CellSpec(
            id: _idForExpression(declaration),

            definition: CellApplication(
                operator: _refCell(buildDeclaration(operator)),

                operands: args.map(buildDeclaration)
                    .map(_refCell)
                    .toList()
            )
        );
    }
  }

  // Definitions

  /// Build a cell specification from a definition declaration.
  ///
  /// [operands] is the list of operands given to the definition operator.
  CellSpec _buildDefinition(List<Expression> operands) => switch (operands) {
    [NamedCell(:final name), final definition] =>
        _buildCellDefinition(
            name: name,
            definition: definition
        ),

    [
      Operation(
        operator: NamedCell(:final name),
        args: final arguments
      ),
      final definition
    ] => _buildFunctionDefinition(
        name: name,
        arguments: arguments,
        definition: definition
    ),

    _ => throw Exception('Definition Parse Error')
  };

  /// Build a specification for a cell identified by [name] and defined by [definition]
  CellSpec _buildCellDefinition({
    required String name,
    required Expression definition
  }) => CellSpec(
      id: NamedCellId(name),
      definition: _refCell(buildDeclaration(definition))
  );

  /// Build a specification for a function cell identified by [name].
  ///
  /// [arguments] is the argument list, and [definition] is the declared
  /// function definition.
  CellSpec _buildFunctionDefinition({
    required String name,
    required List<Expression> arguments,
    required Expression definition
  }) {
    final scope = CellTable(parent: globalTable);

    final argCells = arguments.map((arg) => switch(arg) {
      NamedCell(:final name) => NamedCellId(name),
      // TODO: Proper exception type
      _ => throw Exception('Function definition parse error')
    }).toList();

    for (final arg in argCells) {
      scope.add(
          CellSpec(
              id: arg,
              definition: StubExpression()
          )
      );
    }

    return FunctionSpec(
      id: NamedCellId(name),
      arguments: argCells,
      scope: scope,

      definition: DeferredFunctionDefinition(
          scope: scope,
          definition: definition
      ),
    );
  }

  // Expressions

  /// Create a [CellRef] for reference the cell specified by [spec]
  CellExpression _refCell(CellSpec spec) => switch (spec) {
    ValueCellSpec(:final definition) => definition,

    _ => _NamedCellRef(
        table: globalTable,
        id: spec.id
    )
  };

  /// Get the identifier for the cell represented by [expression].
  CellId _idForExpression(Expression expression) => switch (expression) {
    NamedCell(:final name) => NamedCellId(name),

    Constant(:final value) => ValueCellId(value),

    Operation(:final operator, :final args) =>
        AppliedCellId(
            operator: _idForExpression(operator),
            operands: args.map(_idForExpression).toList()
        ),
  };
}

/// A reference to a cell within a given cell [table].
class _NamedCellRef extends CellRef {
  /// Table in which the cell is referenced
  final CellTable table;

  /// ID of the referenced cell
  final CellId id;

  const _NamedCellRef({
    required this.table,
    required this.id
  });

  @override
  CellSpec get get => table.get(id);
}

/// Converts a [Constant] expression to a [CellSpec].
class _ConstantCellVisitor extends ConstantVisitor<CellSpec> {
  @override
  CellSpec visitConstant<T>(Constant<T> expression) =>
      ValueCellSpec.forValue(expression.value);
}