part 'token_visitor.dart';

/// Base token class
sealed class Token {
  const Token();

  /// Visit this token with [visitor].
  R accept<R>(TokenVisitor<R> visitor);
}

/// An identifier
class IdToken extends Token {
  /// The name of the identifier
  final String name;

  const IdToken({
    required this.name
  });

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitId(this);
}

/// A literal constant value of type [T]
class Literal<T> extends Token {
  /// The parsed literal value
  final T value;

  const Literal({required this.value});

  @override
  R accept<R>(TokenVisitor<R> visitor) =>
      visitor.visitLiteral<T>(this);
}

/// A declaration terminator
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