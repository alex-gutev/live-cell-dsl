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

/// Represents a reference by a named identifier
@DataClass()
class Name extends AstNode {
  /// The identifier
  final String name;

  const Name(this.name, {
    super.line = 0,
    super.column = 0
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitName(this);

  @override
  bool operator ==(Object other) =>
      _$NameEquals(this, other);

  @override
  int get hashCode => _$NameHashCode(this);
}

/// Represents a literal value
@DataClass()
class Value<T> extends AstNode {
  /// The value
  final T value;

  const Value(this.value, {
    super.line = 0,
    super.column = 0
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitValue<T>(this);

  @override
  bool operator ==(Object other) =>
      _$ValueEquals(this, other);

  @override
  int get hashCode => _$ValueHashCode(this);
}

/// Represents the application of an [operator] to one or more [operands].
@DataClass()
class Application extends AstNode {
  /// The application operator
  final AstNode operator;

  /// List of operands on which [operator] is applied
  @listField
  final List<AstNode> operands;

  const Application({
    required this.operator,
    required this.operands,
    super.line = 0,
    super.column = 0
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitApplication(this);

  @override
  bool operator ==(Object other) =>
      _$ApplicationEquals(this, other);

  @override
  int get hashCode => _$ApplicationHashCode(this);
}

/// Represents a block of one or more [expressions]
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
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitBlock(this);

  @override
  bool operator ==(Object other) =>
      _$BlockEquals(this, other);

  @override
  int get hashCode => _$BlockHashCode(this);
}