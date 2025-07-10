import 'attributes.dart';
import 'exceptions.dart';
import 'cell_spec.dart';
import 'cell_table.dart';
import '../lexer/index.dart';
import '../parser/index.dart';

part 'functions.dart';

/// Builds cell specifications from parsed cell [AstNode]s
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
  Future<void> build(Stream<AstNode> declarations) async {
    await for (final declaration in declarations) {
      buildExpression(declaration);
    }

    finalize();
  }

  /// Build a cell specification from a single [expression].
  ///
  /// The built cell is added to the [scope] of this builder.
  CellSpec buildExpression(AstNode expression) {
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
      if (spec.definition case final DeferredSpec deferred) {
        deferred.build();
      }
    }
  }

  // Private

  /// Build a cell from a given [expression].
  CellSpec _buildCell(AstNode expression) => switch (expression) {
    Name(:final name) =>
        CellSpec(
            id: NamedCellId(name),
            scope: scope,
            definition: const Stub()
        ),

    Value() =>
        expression.accept(_ConstantCellVisitor()),

    // TODO: Match proper definition operator
    Application(
      operator: Name(name: '='),
      :final operands,
      :final location,
    ) => _addCell(_buildDefinition(
        operands: operands,
        location: location,
    )),

    // TODO: Match proper var keyword
    Application(
      operator: Name(name: 'var'),
      :final operands,
      :final location,
    ) => _addVarCell(
      operands: operands,
      location: location,
    ),

    Application(
      operator: Name(name: 'external'),
      :final operands,
      :final location,
    ) => _markExternalCell(
      args: operands,
      location: location,
    ),

    Application(:final operator, :final operands) =>
        _buildAppliedCell(
            operator: operator,
            operands: operands
        ),

    Block() => _buildBlock(expression),
  };

  /// Build a cell representing the application of an [operator] to one or more [operands].
  CellSpec _buildAppliedCell({
    required AstNode operator,
    required List<AstNode> operands
  }) {
    final operatorCell = buildExpression(operator);
    final operandCells = operands.map(buildExpression);

    final id = AppliedCellId(
        operator: operatorCell.id,
        operands: operandCells.map((c) => c.id).toList()
    );

    final existing = scope.lookup(id);

    if (existing?.scope == scope &&
        existing?.definition is! Stub) {
      return existing!;
    }

    final spec = CellSpec(
        id: id,
        scope: scope,
        defined: true,

        definition: ApplySpec(
            operator: _refCell(buildExpression(operator)),
            operands: operandCells.map(_refCell).toList()
        ),
    );

    if (operandCells.any((o) => o.scope == scope)) {
      _addCell(spec);
    }

    return spec;
  }

  CellSpec _buildBlock(Block block) {
    CellSpec? cell;

    for (final expression in block.expressions) {
      cell = buildExpression(expression);
    }

    if (cell == null) {
      throw EmptyBlockError(
        location: block.location,
      );
    }

    return cell;
  }

  // Definitions

  /// Build a cell specification from a definition declaration.
  ///
  /// [operands] is the list of operands given to the definition operator.
  CellSpec _buildDefinition({
    required List<AstNode> operands,
    required Location location,
  }) => switch (operands) {
    [Name(:final name), final definition] =>
        _buildCellDefinition(
            name: name,
            definition: definition
        ),

    [
      Application(
        operator: Name(:final name),
        operands: final arguments,
      ),
      final definition
    ] => _buildFunctionDefinition(
        name: name,
        arguments: arguments,
        definition: definition
    ),

    _ => throw MalformedDefinitionError(
      location: location,
    )
  };

  /// Process a `var` declaration
  CellSpec _addVarCell({
    required List<AstNode> operands,
    required Location location,
  }) => switch (operands) {
    [
      Name(
          :final name,
          :final location,
      )
    ] => _makeVarCell(
        name: name,
        location: location,
    ),

    _ => throw MalformedVarDeclarationError(
      location: location,
    )
  };

  CellSpec _makeVarCell({
    required String name,
    required Location location,
  }) {
    final id = NamedCellId(name);

    final existing = scope.lookup(id);

    if (existing != null && existing.scope == scope) {
      switch (existing.definition) {
        case Stub():
          break;

        case Variable():
          return existing;

        default:
          throw IncompatibleVarDeclarationError(
            location: location,
          );
      }
    }

    return _addCell(
        CellSpec(
            id: id,
            definition: const Variable(),
            defined: true,
            scope: scope
        )
    );
  }

  /// Build a specification for a cell identified by [name] and defined by [definition]
  CellSpec _buildCellDefinition({
    required String name,
    required AstNode definition,
  }) => CellSpec(
      id: NamedCellId(name),
      scope: scope,
      defined: true,
      definition: _refCell(buildExpression(definition)),
      location: definition.location,
  );

  /// Build a specification for a function cell identified by [name].
  ///
  /// [arguments] is the argument list, and [definition] is the declared
  /// function definition.
  CellSpec _buildFunctionDefinition({
    required String name,
    required List<AstNode> arguments,
    required AstNode definition,
  }) {
    final scope = CellTable(parent: this.scope);

    return _makeFunctionCell(
      name: name,
      arguments: arguments,
      scope: scope,
      location: definition.location,

      definition: (arguments) => DeferredFunctionDefinition(
          arguments: arguments,
          scope: scope,
          definition: definition
      ),
    );
  }

  /// Create a function cell.
  ///
  /// [definition] is called, on the argument list parsed from
  /// [arguments], to build the definition of the cell.
  CellSpec _makeFunctionCell({
    required String name,
    required List<AstNode> arguments,
    required CellTable scope,
    required ValueSpec Function(List<CellId> args) definition,
    required Location location,
  }) {
    final argCells = arguments.map((arg) => switch(arg) {
      Name(:final name) => NamedCellId(name),

      _ => throw MalformedFunctionArgumentListError(
        location: arg.location,
      )
    }).toList();

    for (final arg in argCells) {
      scope.add(
          CellSpec(
              id: arg,
              scope: scope,
              defined: true,
              definition: Stub()
          )..setAttribute(Attributes.argument, true)
      );
    }

    return CellSpec(
      id: NamedCellId(name),
      scope: this.scope,

      defined: true,
      location: location,

      definition: definition(argCells),
    );
  }

  /// Add a cell to the current [scope].
  CellSpec _addCell(CellSpec spec) {
    final existing = scope.lookup(spec.id);

    if (existing != null && existing.scope == scope) {
      if (existing.definition is! Stub || existing.defined) {
        throw MultipleDefinitionError(
            id: spec.id,
            location: spec.location ?? Location.blank(),
        );
      }
    }

    scope.add(spec);
    return spec;
  }

  // External Cells

  /// Mark a cell as externally defined.
  ///
  /// [args] is the list of arguments provided to the external declaration.
  CellSpec _markExternalCell({
    required List<AstNode> args,
    required Location location
  }) => switch (args) {
    [
      Name(
        :final name,
        :final location,
      )
    ] => _addExternalCell(
      name: name,
      location: location,
    ),

    [
      Application(
        operator: Name(:final name),
        :final operands,
        :final location,
      )
    ] => _addExternalFunction(
      name: name,
      arguments: operands,
      location: location,
    ),

    [...] => throw MalformedExternalDeclarationError(
      location: location,
    ),
  };

  /// Add a named external cell
  CellSpec _addExternalCell({
    required String name,
    required Location location,
  }) {
    final id = NamedCellId(name);
    final existing = scope.lookup(id);

    if (existing != null && existing.scope == scope) {
      if (existing.definition is! Stub) {
        throw MultipleDefinitionError(
            id: id,
            location: location,
        );
      }

      if (existing.isExternal()) {
        return existing;
      }
    }

    return _addCell(
      CellSpec(
          id: id,
          defined: true,
          definition: const Stub(),
          scope: scope
      )
    )..setAttribute(Attributes.external, true);
  }

  /// A a function external cell
  CellSpec _addExternalFunction({
    required String name,
    required List<AstNode> arguments,
    required Location location,
  }) {
    final id = NamedCellId(name);
    final existing = scope.lookup(id);

    if (existing != null && existing.scope == scope) {
      if (existing.definition is! Stub) {
        throw MultipleDefinitionError(
            id: id,
            location: location,
        );
      }

      if (existing.isExternal()) {
        return existing;
      }
    }

    final fnScope = CellTable(parent: scope);

    return _addCell(
        _makeFunctionCell(
            name: name,
            arguments: arguments,
            scope: fnScope,
            definition: (args) => FunctionSpec(
                arguments: args,
                scope: fnScope,
                definition: const Stub()
            ),
            location: location,
        )
    )..setAttribute(Attributes.external, true);
  }

  // Expressions

  /// Create a [CellRef] that references the cell specified by [spec]
  ValueSpec _refCell(CellSpec spec) => switch (spec) {
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

/// Converts a [Value] node to a [CellSpec].
class _ConstantCellVisitor extends ConstantVisitor<CellSpec> {
  @override
  CellSpec visitValue<T>(Value<T> expression) =>
      ValueCellSpec.forValue(expression.value);
}