import 'package:live_cell/util/equality.dart';
import 'package:live_cells_core/live_cells_core.dart';

part 'ast_visitor.dart';
part 'ast.g.dart';

/// Base class representing a node in the abstract syntax tree
sealed class AstNode {
  /// The line in the source where the node is located
  final int line;

  /// The column in the source where the node is located
  final int column;

  const AstNode({
    required this.line,
    required this.column
  });

  /// Visit this expression with [visitor].
  R accept<R>(AstVisitor<R> visitor);
}

/// Expression representing a reference to a named cell
@DataClass()
class NamedCell extends AstNode {
  /// The name of the cell
  final String name;

  const NamedCell(this.name, {
    super.line = 0,
    super.column = 0
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitNamedCell(this);

  @override
  bool operator ==(Object other) =>
      _$NamedCellEquals(this, other);

  @override
  int get hashCode => _$NamedCellHashCode(this);
}

/// Expression representing a literal constant value
@DataClass()
class Constant<T> extends AstNode {
  /// The constant value
  final T value;

  const Constant(this.value, {
    super.line = 0,
    super.column = 0
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitConstant<T>(this);

  @override
  bool operator ==(Object other) =>
      _$ConstantEquals(this, other);

  @override
  int get hashCode => _$ConstantHashCode(this);
}

/// Expression representing an [operator] applied to one or more arguments
@DataClass()
class Operation extends AstNode {
  /// The expression operator
  final AstNode operator;

  /// List of arguments on which [operator] is applied
  @listField
  final List<AstNode> args;

  const Operation({
    required this.operator,
    required this.args,
    super.line = 0,
    super.column = 0
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitOperation(this);

  @override
  bool operator ==(Object other) =>
      _$OperationEquals(this, other);

  @override
  int get hashCode => _$OperationHashCode(this);
}

/// A block of multiple [expressions]
@DataClass()
class Block extends AstNode {
  /// List of expressions in the block
  @listField
  final List<AstNode> expressions;

  const Block({
    required this.expressions,
    super.line = 0,
    super.column = 0
  });

  @override
  R accept<R>(AstVisitor<R> visitor) {
    // TODO: implement accept
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) =>
      _$BlockEquals(this, other);

  @override
  int get hashCode => _$BlockHashCode(this);
}