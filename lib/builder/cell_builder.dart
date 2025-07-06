import 'exceptions.dart';
import 'cell_spec.dart';
import 'cell_table.dart';
import '../parser/index.dart';

part 'functions.dart';

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
      :final args,
      :final line,
      :final column
    ) => _addCell(_buildDefinition(
        operands: args,
        line: line,
        column: column
    )),

    // TODO: Match proper var keyword
    Operation(
      operator: NamedCell(name: 'var'),
      :final args,
      :final line,
      :final column
    ) => _addVarCell(
      operands: args,
      line: line,
      column: column
    ),

    Operation(:final operator, :final args) =>
        _buildAppliedCell(
            operator: operator,
            operands: args
        ),

    Block() => _buildBlock(expression),
  };

  /// Build a cell representing the application of an [operator] to one or more [operands].
  CellSpec _buildAppliedCell({
    required Expression operator,
    required List<Expression> operands
  }) {
    final operatorCell = buildExpression(operator);
    final operandCells = operands.map(buildExpression);

    return CellSpec(
        scope: scope,

        id: AppliedCellId(
            operator: operatorCell.id,
            operands: operandCells.map((c) => c.id).toList()
        ),

        definition: CellApplication(
            operator: _refCell(buildExpression(operator)),
            operands: operandCells.map(_refCell).toList()
        ),
    );
  }

  CellSpec _buildBlock(Block block) {
    CellSpec? cell;

    for (final expression in block.expressions) {
      cell = buildExpression(expression);
    }

    if (cell == null) {
      throw EmptyBlockError(
          line: block.line,
          column: block.column
      );
    }

    return cell;
  }

  // Definitions

  /// Build a cell specification from a definition declaration.
  ///
  /// [operands] is the list of operands given to the definition operator.
  CellSpec _buildDefinition({
    required List<Expression> operands,
    required int line,
    required int column
  }) => switch (operands) {
    [NamedCell(:final name), final definition] =>
        _buildCellDefinition(
            name: name,
            definition: definition
        ),

    [
      Operation(
        operator: NamedCell(:final name),
        args: final arguments,
      ),
      final definition
    ] => _buildFunctionDefinition(
        name: name,
        arguments: arguments,
        definition: definition
    ),

    _ => throw MalformedDefinitionError(
        line: line,
        column: column
    )
  };

  /// Process a `var` declaration
  CellSpec _addVarCell({
    required List<Expression> operands,
    required int line,
    required int column
  }) => switch (operands) {
    [
      NamedCell(
          :final name,
          :final line,
          :final column
      )
    ] => _makeVarCell(
        name: name,
        line: line,
        column: column
    ),

    _ => throw MalformedVarDeclarationError(
      line: line,
      column: column
    )
  };

  CellSpec _makeVarCell({
    required String name,
    required int line,
    required int column
  }) {
    final id = NamedCellId(name);

    final existing = scope.lookup(id);

    if (existing != null && existing.scope == scope) {
      switch (existing.definition) {
        case StubExpression():
          break;

        case VariableValue():
          return existing;

        default:
          throw IncompatibleVarDeclarationError(
              line: line,
              column: column
          );
      }
    }

    return _addCell(
        CellSpec(
            id: id,
            definition: const VariableValue(),
            scope: scope
        )
    );
  }

  /// Build a specification for a cell identified by [name] and defined by [definition]
  CellSpec _buildCellDefinition({
    required String name,
    required Expression definition,
  }) => CellSpec(
      id: NamedCellId(name),
      scope: scope,
      definition: _refCell(buildExpression(definition)),

      line: definition.line,
      column: definition.column
  );

  /// Build a specification for a function cell identified by [name].
  ///
  /// [arguments] is the argument list, and [definition] is the declared
  /// function definition.
  CellSpec _buildFunctionDefinition({
    required String name,
    required List<Expression> arguments,
    required Expression definition,
  }) {
    final scope = CellTable(parent: this.scope);

    final argCells = arguments.map((arg) => switch(arg) {
      NamedCell(:final name) => NamedCellId(name),

      _ => throw MalformedFunctionArgumentListError(
        line: arg.line,
        column: arg.column
      )
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
      scope: this.scope,

      line: definition.line,
      column: definition.column,

      definition: DeferredFunctionDefinition(
          arguments: argCells,
          scope: scope,
          definition: definition
      ),
    );
  }

  /// Add a cell to the current [scope].
  CellSpec _addCell(CellSpec spec) {
    final existing = scope.lookup(spec.id);

    if (existing != null && existing.scope == scope) {
      if (existing.definition is! StubExpression) {
        throw MultipleDefinitionError(
            id: spec.id,
            line: spec.line ?? 0,
            column: spec.column ?? 0
        );
      }
    }

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