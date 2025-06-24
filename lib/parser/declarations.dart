/// Base class representing a parsed expression
sealed class Expression {
  const Expression();
}

/// Expression representing a reference to a named cell
class NamedCell extends Expression {
  /// The name of the cell
  final String name;

  const NamedCell(this.name);
}

/// Expression representing a literal constant value
class Constant<T> extends Expression {
  /// The constant value
  final T value;

  const Constant(this.value);
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
}