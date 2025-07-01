import 'package:live_cells_core/live_cells_core.dart';

part 'token_visitor.dart';
part 'tokens.g.dart';

/// Base token class
sealed class Token {
  /// The line at which the token starts
  final int line;

  /// The column at which the token starts
  final int column;

  const Token({
    this.line = 0,
    this.column = 0
  });

  /// Visit this token with [visitor].
  R accept<R>(TokenVisitor<R> visitor);

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// An identifier
@DataClass()
class IdToken extends Token {
  /// The name of the identifier
  final String name;

  const IdToken({
    required this.name,
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitId(this);

  @override
  bool operator ==(Object other) => _$IdTokenEquals(this, other);

  @override
  int get hashCode => _$IdTokenHashCode(this);

  @override
  String toString() => 'ID($name)';
}

/// A literal constant value of type [T]
@DataClass()
class Literal<T> extends Token {
  /// The parsed literal value
  final T value;

  const Literal({
    required this.value,
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitLiteral<T>(this);

  // TODO: Consider calling super == which compares type
  @override
  bool operator ==(Object other) => _$LiteralEquals(this, other);

  @override
  int get hashCode => _$LiteralHashCode(this);

  @override
  String toString() => 'Literal($value)';
}

/// A declaration terminator
@DataClass()
class Terminator extends Token {
  /// Is this a soft terminator?
  ///
  /// If true it indicates that this terminator was added implicitly by the
  /// lexer. Otherwise it indicates that this terminator was explicitly
  /// written in the source.
  final bool soft;

  const Terminator({
    required this.soft,
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitTerminator(this);

  @override
  bool operator ==(Object other) => _$TerminatorEquals(this, other);

  @override
  int get hashCode => _$TerminatorHashCode(this);

  @override
  String toString() => 'Terminator(soft: $soft)';
}

/// Argument separator ','
class Separator extends Token {
  const Separator({
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitSeparator(this);
}

/// Represents the end of the input
class EndOfInput extends Token {
  const EndOfInput({
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitEndOfInput(this);
}

/// Opening parenthesis '('
class ParenOpen extends Token {
  const ParenOpen({
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitParenOpen(this);
}

/// Closing parenthesis ')'
class ParenClose extends Token {
  const ParenClose({
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitParenClose(this);
}

/// Opening brace '{'
class BraceOpen extends Token {
  const BraceOpen({
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitBraceOpen(this);
}

/// Closing brace '}'
class BraceClose extends Token {
  const BraceClose({
    super.line,
    super.column
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitBraceClose(this);
}