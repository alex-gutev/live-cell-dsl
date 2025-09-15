import 'package:live_cells_core/live_cells_core.dart';

import '../lexer/index.dart';
import '../util/equality.dart';

part 'ast_visitor.dart';
part 'ast.g.dart';

/// Base class representing a node in the abstract syntax tree
sealed class AstNode {
  /// The location of the node in the source
  final Location location;

  const AstNode({
    required this.location,
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
    super.location = const Location.blank()
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitName(this);

  @override
  bool operator ==(Object other) =>
      _$NameEquals(this, other);

  @override
  int get hashCode => _$NameHashCode(this);

  @override
  String toString() => name;
}

/// Represents a literal value
@DataClass()
class Value<T> extends AstNode {
  /// The value
  final T value;

  const Value(this.value, {
    super.location = const Location.blank()
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitValue<T>(this);

  @override
  bool operator ==(Object other) =>
      _$ValueEquals(this, other);

  @override
  int get hashCode => _$ValueHashCode(this);

  @override
  String toString() => 'Value<$value>';
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
    super.location = const Location.blank()
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitApplication(this);

  @override
  bool operator ==(Object other) =>
      _$ApplicationEquals(this, other);

  @override
  int get hashCode => _$ApplicationHashCode(this);

  @override
  String toString() => '$operator(${operands.join(',')})';
}

/// Represents a block of one or more [expressions]
@DataClass()
class Block extends AstNode {
  /// List of expressions in the block
  @listField
  final List<AstNode> expressions;

  const Block({
    required this.expressions,
    super.location = const Location.blank()
  });

  @override
  R accept<R>(AstVisitor<R> visitor) =>
      visitor.visitBlock(this);

  @override
  bool operator ==(Object other) =>
      _$BlockEquals(this, other);

  @override
  int get hashCode => _$BlockHashCode(this);

  @override
  String toString() => '{${expressions.join(';')}}';
}