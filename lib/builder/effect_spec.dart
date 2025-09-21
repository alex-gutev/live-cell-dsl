import 'cell_spec.dart';
import 'cell_table.dart';
import '../lexer/index.dart';

part 'statement_visitor.dart';

/// Represents a side effect
class EffectSpec {
  /// Effect identifier
  final int id;

  /// List of statements making up the effect.
  final List<StatementSpec> statements;

  /// The location in the source where the effect is declared.
  final Location? location;

  /// The scope in which the effect is contained
  final CellTable scope;

  /// Is this a global effect?
  bool get isGlobal => scope.isGlobal;

  /// Set of argument cells referenced by the effect.
  Set<CellSpec> get arguments {
    if (_arguments == null) {
      _arguments = {};

      for (final statement in statements) {
        statement.accept(
          _EffectArgumentsVisitor(_arguments!)
        );
      }
    }

    return _arguments!;
  }

  EffectSpec({
    required this.id,
    required this.statements,
    required this.location,
    required this.scope
  });

  // Private

  Set<CellSpec>? _arguments;
}

/// Base class representing a statement in an effect.
sealed class StatementSpec {
  /// The expression that computes the value of this statement.
  ValueSpec get expression;

  const StatementSpec();

  /// Visit this statement spec with [visitor].
  R accept<R>(StatementVisitor<R> visitor);
}

/// An cell value assignment statement
class AssignStatement extends StatementSpec {
  /// The cell, of which, the value is being assigned
  final CellRef cell;

  /// The value being assigned to the cell.
  ///
  /// This may be another statement, such as an assignment.
  final StatementSpec value;

  @override
  ValueSpec get expression => value.expression;

  const AssignStatement({
    required this.cell,
    required this.value
  });

  @override
  R accept<R>(StatementVisitor<R> visitor) =>
      visitor.visitAssign(this);
}

/// A group of statements
class BlockStatement extends StatementSpec {
  /// List of statements in the group
  final List<StatementSpec> statements;

  @override
  ValueSpec get expression => statements.last.expression;

  const BlockStatement({
    required this.statements
  });

  @override
  R accept<R>(StatementVisitor<R> visitor) =>
      visitor.visitBlock(this);
}

/// A statement that wraps a [ValueSpec].
class ExpressionStatement extends StatementSpec {
  @override
  final ValueSpec expression;

  const ExpressionStatement({required this.expression});

  @override
  R accept<R>(StatementVisitor<R> visitor) =>
      visitor.visitExpression(this);
}

// Private

/// Visitor for determining the argument cells of a statement.
class _EffectArgumentsVisitor extends StatementTreeVisitor {
  /// Set of argument cells
  final Set<CellSpec> arguments;

  _EffectArgumentsVisitor(this.arguments);

  @override
  void visitExpression(ExpressionStatement statement) {
    final visitor = _ExpressionArgumentsVisitor(arguments);
    statement.expression.accept(visitor);
  }
}

/// Visitor for determining the argument cells of an expression.
class _ExpressionArgumentsVisitor extends ValueSpecTreeVisitor {
  /// Set of argument cells
  final Set<CellSpec> arguments;

  _ExpressionArgumentsVisitor(this.arguments);

  @override
  void visitRef(CellRef spec) {
    arguments.add(spec.get);
  }

  @override
  void visitFunction(FunctionSpec spec) {
    arguments.addAll(spec.closure);
  }
}
