import 'dart:collection';

import 'attributes.dart';
import 'exceptions.dart';
import 'cell_spec.dart';
import 'cell_table.dart';
import 'modules.dart';
import 'special_operators.dart';
import '../lexer/index.dart';
import '../parser/index.dart';

part 'functions.dart';

/// Builds cell specifications from parsed cell [AstNode]s
class CellBuilder {
  /// Specification of the module being built
  /// 
  /// The identifiers of cells created by this builder, are contained
  /// in this module. Similarly, all cells declared in this module are added
  /// to the module's exports.
  final ModuleSpec module;

  /// The scope in which the cells are built
  final CellTable scope;

  /// Load module function.
  /// 
  /// This function is called when an `import` declaration is processed.
  final LoadModule? loadModule;

  /// Create a [CellBuilder] that builds cells in a given [scope].
  /// 
  /// If [scope] is null, a new scope is created.
  /// 
  /// If [module] is null, a new [ModuleSpec] with a [null] path is created.
  CellBuilder({
    CellTable? scope,
    ModuleSpec? module,
    this.loadModule
  }) : scope = scope ?? CellTable(),
        module = module ?? ModuleSpec(null);

  /// Build the cell specifications from the given [declarations].
  Future<void> build(Stream<AstNode> declarations) async {
    await processSource(declarations);
    finalize();
  }

  // TODO: Ensure that top-level special operators do not appear nested in other nodes
  // TODO: Ensure that functions cannot be declared with the same name as a special operator

  /// Process all declarations in the source file.
  /// 
  /// This method does not run any post-processing steps
  Future<void> processSource(Stream<AstNode> declarations) async {
    /// Import language core
    module.importAll(kCoreModule);

    await for (final declaration in declarations) {
      await processTopLevel(declaration);
    }
  }

  /// Process a top level declaration.
  Future<void> processTopLevel(AstNode node) async {
    switch (node) {
      case Application(
        operator: Name(:final name),
        :final operands
      ) when Operators.isTopLevelOperator(module.namedId(name)):

        try {
          await Operators.processTopLevel(
              id: module.namedId(name),
              builder: this,
              operands: operands
          );
        }
        on Exception catch (error) {
          if (error is BuildError) {
            rethrow;
          }

          throw BuildError(
              location: node.location,
              error: error
          );
        }

      default:
        buildExpression(node);
    }
  }

  /// Build a cell specification from a single [expression].
  ///
  /// The built cell is added to the [scope] of this builder.
  CellSpec buildExpression(AstNode expression) {
    try {
      final spec = _buildCell(expression);

      if (scope.lookup(spec.id) == null) {
        scope.add(spec);
        _addExportedId(spec.id);
      }

      return spec;
    }
    on Exception catch (error) {
      throw BuildError(
          location: expression.location,
          error: error
      );
    }
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
            id: module.namedId(name),
            scope: scope,
            definition: const Stub()
        ),

    Value() =>
        expression.accept(_ConstantCellVisitor()),

    // TODO: Match proper definition operator
    Application(
      operator: Name(name: '='),
      :final operands,
    ) => _addCell(_buildDefinition(
        operands: operands,
    )),

    // TODO: Match proper var keyword
    Application(
      operator: Name(name: 'var'),
      :final operands,
    ) => _addVarCell(
      operands: operands,
    ),

    Application(
      operator: Name(name: 'external'),
      :final operands,
    ) => _markExternalCell(
      args: operands,
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
      throw EmptyBlockError();
    }

    return cell;
  }

  // Definitions

  /// Build a cell specification from a definition declaration.
  ///
  /// [operands] is the list of operands given to the definition operator.
  CellSpec _buildDefinition({
    required List<AstNode> operands,
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

    _ => throw MalformedDefinitionError()
  };

  /// Process a `var` declaration
  CellSpec _addVarCell({
    required List<AstNode> operands,
  }) => switch (operands) {
    [
      Name(
          :final name,
      )
    ] => _makeVarCell(
        name: name,
    ),

    _ => throw MalformedVarDeclarationError()
  };

  CellSpec _makeVarCell({
    required String name,
  }) {
    final id = module.namedId(name);
    final existing = scope.lookup(id);

    if (existing != null && existing.scope == scope) {
      switch (existing.definition) {
        case Stub():
          break;

        case Variable():
          return existing;

        default:
          throw IncompatibleVarDeclarationError();
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
      id: module.namedId(name),
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
          module: module,
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
      Name(:final name) => module.namedId(name),

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
      id: module.namedId(name),
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
        );
      }
    }

    scope.add(spec);
    _addExportedId(spec.id);

    return spec;
  }

  /// Add a cell [id] to the current [module]s exported identifiers.
  void _addExportedId(CellId id) {
    if (id case NamedCellId(
      module: final moduleName
    ) when moduleName == module.path) {
      module.exports.add(id);
    }
  }

  // External Cells

  /// Mark a cell as externally defined.
  ///
  /// [args] is the list of arguments provided to the external declaration.
  CellSpec _markExternalCell({
    required List<AstNode> args,
  }) => switch (args) {
    [
      Name(
        :final name,
      )
    ] => _addExternalCell(
      name: name,
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

    [...] => throw MalformedExternalDeclarationError(),
  };

  /// Add a named external cell
  CellSpec _addExternalCell({
    required String name,
  }) {
    final id = module.namedId(name);
    final existing = scope.lookup(id);

    if (existing != null && existing.scope == scope) {
      if (existing.definition is! Stub) {
        throw MultipleDefinitionError(
            id: id,
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
    final id = module.namedId(name);
    final existing = scope.lookup(id);

    if (existing != null && existing.scope == scope) {
      if (existing.definition is! Stub) {
        throw MultipleDefinitionError(
            id: id,
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