import 'package:live_cell/util/equality.dart';
import 'package:live_cells_core/live_cells_core.dart';

part 'expression_visitor.dart';
part 'declarations.g.dart';

/// Base class representing a parsed expression
sealed class Expression {
  const Expression();

  /// Visit this expression with [visitor].
  R accept<R>(ExpressionVisitor<R> visitor);
}

/// Expression representing a reference to a named cell
@DataClass()
class NamedCell extends Expression {
  /// The name of the cell
  final String name;

  const NamedCell(this.name);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) =>
      visitor.visitNamedCell(this);

  @override
  bool operator ==(Object other) =>
      _$NamedCellEquals(this, other);

  @override
  int get hashCode => _$NamedCellHashCode(this);
}

/// Expression representing a literal constant value
@DataClass()
class Constant<T> extends Expression {
  /// The constant value
  final T value;

  const Constant(this.value);

  @override
  R accept<R>(ExpressionVisitor<R> visitor) =>
      visitor.visitConstant<T>(this);

  @override
  bool operator ==(Object other) =>
      _$ConstantEquals(this, other);

  @override
  int get hashCode => _$ConstantHashCode(this);
}

/// Expression representing an [operator] applied to one or more arguments
@DataClass()
class Operation extends Expression {
  /// The expression operator
  final Expression operator;

  /// List of arguments on which [operator] is applied
  @listField
  final List<Expression> args;

  const Operation({
    required this.operator,
    required this.args
  });

  @override
  R accept<R>(ExpressionVisitor<R> visitor) =>
      visitor.visitOperation(this);

  @override
  bool operator ==(Object other) =>
      _$OperationEquals(this, other);

  @override
  int get hashCode => _$OperationHashCode(this);
}

/// A block of multiple [expressions]
@DataClass()
class Block extends Expression {
  /// List of expressions in the block
  @listField
  final List<Expression> expressions;

  const Block({
    required this.expressions
  });

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    // TODO: implement accept
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      _$ExpressionListEquals(this, other);

  @override
  int get hashCode => _$ExpressionListHashCode(this);
}