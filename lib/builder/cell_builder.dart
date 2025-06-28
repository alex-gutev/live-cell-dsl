import 'functions.dart';
import 'cell_spec.dart';
import 'cell_table.dart';
import '../parser/index.dart';

/// Builds cell specifications from parsed cell [Expression]s
class CellBuilder {
  /// The scope in which the cells are built
  final CellTable scope;

  /// Create a [CellBuilder] that builds cells in a given [scope].
  /// 
  /// If [scope] is null, a new scope is created.
  CellBuilder({
    CellTable? scope
  }) : scope = scope ?? CellTable();

  /// Build the cell specifications from the given [declarations].
  Future<void> build(Stream<Expression> declarations) async {
    await for (final declaration in declarations) {
      buildExpression(declaration);
    }

    finalize();
  }

  /// Build a cell specification from a single [expression].
  ///
  /// The built cell is added to the [scope] of this builder.
  CellSpec buildExpression(Expression expression) {
    final spec = _buildCell(expression);
    if (scope.lookup(spec.id) == null) {
      scope.add(spec);
    }

    return spec;
  }

  /// Build all deferred definitions
  void finalize() {
    for (final spec in scope.cells) {
      // TODO: Walk through definition and build nested deferred expressions
      if (spec.definition case final DeferredExpression deferred) {
        deferred.build();
      }
    }
  }

  // Private

  /// Build a cell from a given [expression].
  CellSpec _buildCell(Expression expression) => switch (expression) {
    NamedCell(:final name) =>
        CellSpec(
            id: NamedCellId(name),
            scope: scope,
            definition: const StubExpression()
        ),

    Constant() =>
        expression.accept(_ConstantCellVisitor()),

    // TODO: Match proper definition operator
    Operation(
      operator: NamedCell(name: '='),
      :final args
    ) => _addCell(_buildDefinition(args)),

    Operation(:final operator, :final args) =>
        CellSpec(
            id: _idForExpression(expression),
            scope: scope,

            definition: CellApplication(
                operator: _refCell(buildExpression(operator)),

                operands: args.map(buildExpression)
                    .map(_refCell)
                    .toList()
            )
        )
  };

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
      scope: scope,
      definition: _refCell(buildExpression(definition))
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
    final scope = CellTable(parent: this.scope);

    final argCells = arguments.map((arg) => switch(arg) {
      NamedCell(:final name) => NamedCellId(name),
      // TODO: Proper exception type
      _ => throw Exception('Function definition parse error')
    }).toList();

    for (final arg in argCells) {
      scope.add(
          CellSpec(
              id: arg,
              scope: scope,
              definition: StubExpression()
          )
      );
    }

    return CellSpec(
      id: NamedCellId(name),
      scope: scope,

      definition: DeferredFunctionDefinition(
          arguments: argCells,
          scope: scope,
          definition: definition
      ),
    );
  }

  /// Add a cell to the current [scope].
  CellSpec _addCell(CellSpec spec) {
    scope.add(spec);
    return spec;
  }

  // Expressions

  /// Create a [CellRef] for reference the cell specified by [spec]
  CellExpression _refCell(CellSpec spec) => switch (spec) {
    ValueCellSpec(:final definition) => definition,

    _ => _NamedCellRef(
        table: scope,
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