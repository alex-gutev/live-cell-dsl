import 'package:live_cells_core/live_cells_core.dart';

part 'token_visitor.dart';
part 'tokens.g.dart';

/// Base token class
sealed class Token {
  const Token();

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
    required this.name
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

  const Literal({required this.value});

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
    required this.soft
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
  const Separator();

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitSeparator(this);
}

/// Represents the end of the input
class EndOfInput extends Token {
  const EndOfInput();

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitEndOfInput(this);
}

/// Opening parenthesis '('
class ParenOpen extends Token {
  const ParenOpen();

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitParenOpen(this);
}

/// Closing parenthesis ')'
class ParenClose extends Token {
  const ParenClose();

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitParenClose(this);
}

/// Opening brace '{'
class BraceOpen extends Token {
  const BraceOpen();

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitBraceOpen(this);
}

/// Closing brace '}'
class BraceClose extends Token {
  const BraceClose();

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitBraceClose(this);
}