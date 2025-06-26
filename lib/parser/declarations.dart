part 'expression_visitor.dart';

/// Base class representing a parsed expression
sealed class Expression {
  const Expression();

  /// Visit this expression with [visitor].
  R accept<R>(ExpressionVisitor<R> visitor);
}

/// Expression representing a reference to a named cell
class NamedCell extends Expression {
  /// The name of the cell
  final String name;

  const NamedCell(this.name);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) =>
      visitor.visitNamedCell(this);
}

/// Expression representing a literal constant value
class Constant<T> extends Expression {
  /// The constant value
  final T value;

  const Constant(this.value);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) =>
      visitor.visitConstant<T>(this);
}

/// Expression representing an [operator] applied to one or more arguments
class Operation extends Expression {
  /// The expression operator
  final Expression operator;

  /// List of arguments on which [operator] is applied
  final List<Expression> args;

  const Operation({
    required this.operator,
    required this.args
  });

  @override
  R accept<R>(ExpressionVisitor<R> visitor) =>
      visitor.visitOperation(this);
}